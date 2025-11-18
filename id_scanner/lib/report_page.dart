import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

class ReportPage extends StatefulWidget {
  final String studentInfo;
  final DateTime scanDate;

  const ReportPage({
    super.key,
    required this.studentInfo,
    required this.scanDate,
  });

  @override
  State<ReportPage> createState() => _ReportPageState();
}

class _ReportPageState extends State<ReportPage> {
  bool _exposedKnees = false;
  bool _exposedNavel = false;
  bool _exposedShoulders = false;
  bool _otherViolation = false;
  final TextEditingController _otherTextController = TextEditingController();

  // User name controller
  final TextEditingController _nameController = TextEditingController();

  // Google Drive image variables
  final TextEditingController _driveImageLinkController = TextEditingController();
  Uint8List? _pickedImageBytes;
  String? _pickedImageName;

  final String backendUrl = "http://172.20.10.10:8000/submit_report/";

  Future<void> _openGoogleDriveFolder() async {
    try {
      const String driveLink = 'https://drive.google.com/drive/u/8/folders/1N_LlrzTw0epTco3j-WSdiN7M3eOwHnKi';
      final Uri url = Uri.parse(driveLink);

      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('📂 Open Google Drive, copy image link, then paste here.'),
            duration: Duration(seconds: 4),
          ),
        );
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open Google Drive')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Future<void> submitReport() async {
    // Validate name field
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter your name")),
      );
      return;
    }

    List<String> selectedViolations = [];
    if (_exposedShoulders) selectedViolations.add("Exposed Shoulders");
    if (_exposedKnees) selectedViolations.add("Exposed Knees");
    if (_exposedNavel) selectedViolations.add("Exposed Navel");
    if (_otherViolation && _otherTextController.text.trim().isNotEmpty) {
      selectedViolations.add(_otherTextController.text.trim());
    }

    if (selectedViolations.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select at least one violation")),
      );
      return;
    }

    final payload = <String, dynamic>{
      "student_info": widget.studentInfo,
      "scan_date": widget.scanDate.toIso8601String(),
      "violations": selectedViolations,
      "reporter_name": _nameController.text.trim(),
    };

    // ✅ Google Drive link
    if (_driveImageLinkController.text.trim().isNotEmpty) {
      payload.addAll({
        "image_source": "drive_link",
        "image_path": _driveImageLinkController.text.trim(), // <-- FIX
      });
    }

    // ✅ Local file as base64
    if (_pickedImageBytes != null) {
      payload.addAll({
        "image_source": "local",
        "image_name": _pickedImageName ?? 'picked_image.png',
        "image_base64": base64Encode(_pickedImageBytes!),
      });
    }

    final body = jsonEncode(payload);

    print('📤 Sending payload: $body');

    try {
      final response = await http.post(
        Uri.parse(backendUrl),
        headers: {"Content-Type": "application/json"},
        body: body,
      );

      print('📥 Response: ${response.statusCode} — ${response.body}');

      if (!mounted) return;

      if (response.statusCode == 200 || response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("✅ Report submitted successfully!")),
        );
        await Future.delayed(const Duration(milliseconds: 800));
        Navigator.popUntil(context, (route) => route.isFirst);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("❌ Failed: ${response.statusCode} — ${response.body}")),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("⚠️ Network error: $e")),
      );
    }
  }

  @override
  void dispose() {
    _otherTextController.dispose();
    _nameController.dispose();
    _driveImageLinkController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final formattedDate = DateFormat('yyyy-MM-dd – kk:mm').format(widget.scanDate);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Generate Report'),
        backgroundColor: const Color.fromRGBO(26, 24, 81, 1),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text("Student Information:", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text(widget.studentInfo, style: const TextStyle(fontSize: 16), textAlign: TextAlign.center),
                const SizedBox(height: 16),
                const Text("Date & Time:", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text(formattedDate, style: const TextStyle(fontSize: 16)),
                const SizedBox(height: 20),
                const Text("Violation(s):", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                CheckboxListTile(title: const Text("Exposed Shoulders"), value: _exposedShoulders, onChanged: (val) => setState(() => _exposedShoulders = val ?? false)),
                CheckboxListTile(title: const Text("Exposed Knees"), value: _exposedKnees, onChanged: (val) => setState(() => _exposedKnees = val ?? false)),
                CheckboxListTile(title: const Text("Exposed Navel"), value: _exposedNavel, onChanged: (val) => setState(() => _exposedNavel = val ?? false)),
                CheckboxListTile(title: const Text("Others:"), value: _otherViolation, onChanged: (val) => setState(() => _otherViolation = val ?? false)),
                if (_otherViolation)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
                    child: TextField(
                      controller: _otherTextController,
                      decoration: const InputDecoration(labelText: "Specify other violation", border: OutlineInputBorder()),
                    ),
                  ),
                const SizedBox(height: 30),
                const Text("Reporter Name:", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: "Enter your name",
                    hintText: "e.g., John Doe",
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 30),
                const Text("Attach Evidence Image (Optional):", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromRGBO(26, 24, 81, 1),
                    foregroundColor: const Color.fromRGBO(252, 179, 21, 1),
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: _openGoogleDriveFolder,
                  icon: const Icon(Icons.open_in_browser, size: 24),
                  label: const Text("Open Google Drive Folder", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _driveImageLinkController,
                  decoration: InputDecoration(
                    labelText: "Paste Image Link from Google Drive",
                    hintText: "Right-click image in Drive > Get link > Copy and paste here",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Color.fromRGBO(26, 24, 81, 1), width: 2),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Color.fromRGBO(0, 173, 255, 1), width: 2.5),
                    ),
                    suffixIcon: _driveImageLinkController.text.isNotEmpty
                        ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        setState(() {
                          _driveImageLinkController.clear();
                          _pickedImageBytes = null;
                          _pickedImageName = null;
                        });
                      },
                    )
                        : null,
                  ),
                  onChanged: (value) {
                    setState(() {});
                  },
                ),
                const SizedBox(height: 12),
                if (_pickedImageBytes != null)
                  Column(
                    children: [
                      Container(
                        decoration: BoxDecoration(border: Border.all(color: const Color.fromRGBO(26, 24, 81, 1), width: 2), borderRadius: BorderRadius.circular(8)),
                        child: Column(
                          children: [
                            ClipRRect(
                              borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                              child: Image.memory(_pickedImageBytes!, height: 200, width: double.infinity, fit: BoxFit.cover, errorBuilder: (context, error, stackTrace) => const Padding(padding: EdgeInsets.all(20), child: Icon(Icons.error, size: 50))),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(8),
                              child: Column(
                                children: [
                                  Text(_pickedImageName ?? 'Selected image', maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500), textAlign: TextAlign.center),
                                  const SizedBox(height: 8),
                                  ElevatedButton.icon(
                                    onPressed: () {
                                      setState(() {
                                        _pickedImageBytes = null;
                                        _pickedImageName = null;
                                      });
                                    },
                                    icon: const Icon(Icons.delete),
                                    label: const Text("Remove Image"),
                                    style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                  ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color.fromRGBO(26, 24, 81, 1), foregroundColor: const Color.fromRGBO(252, 179, 21, 1), padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14)),
                  onPressed: submitReport,
                  child: const Text("Submit Report"),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
