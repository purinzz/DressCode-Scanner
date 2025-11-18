import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'dart:typed_data';

class GoogleDriveService {
  static final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [drive.DriveApi.driveScope],
  );

  // ✅ Specific folder ID for dress code violations
  static const String folderId = '1N_LlrzTw0epTco3j-WSdiN7M3eOwHnKi';

  /// Sign in to Google and return authenticated user
  static Future<GoogleSignInAccount?> signIn() async {
    try {
      return await _googleSignIn.signIn();
    } catch (e) {
      print('Error signing in: $e');
      return null;
    }
  }

  /// Get the currently signed-in user
  static Future<GoogleSignInAccount?> getCurrentUser() async {
    return await _googleSignIn.signInSilently();
  }

  /// ✅ Get list of image files from a specific Google Drive folder
  static Future<List<GoogleDriveFile>> getImageFiles() async {
    try {
      print('🚀 Starting Google Drive image fetch...');
      print('📂 Target Folder ID: $folderId');

      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        print('❌ User not signed in');
        return [];
      }

      print('✅ Signed in as: ${googleUser.email}');

      final authHeaders = await googleUser.authHeaders;
      print('🔐 Auth headers received');

      final authenticateClient = _createAuthenticatedClient(authHeaders);
      final driveApi = drive.DriveApi(authenticateClient);
      print('🔗 Drive API initialized');

      // Use a query (q) to fetch image files that are direct children of the folder
      final q = "'${folderId}' in parents and trashed = false and (mimeType = 'image/png' or mimeType = 'image/jpeg' or mimeType = 'image/webp')";

      final List<drive.File> allFiles = [];
      String? pageToken;
      int pageCount = 0;

      do {
        pageCount++;
        print('📄 Fetching page $pageCount with query: $q');

        final fileList = await driveApi.files.list(
          q: q,
          spaces: 'drive',
          pageSize: 100,
          pageToken: pageToken,
          orderBy: 'modifiedTime desc',
          includeItemsFromAllDrives: true,
          supportsAllDrives: true,
        );

        final files = fileList.files;
        if (files == null || files.isEmpty) {
          print('⚠️ No files in this page');
          break;
        }

        print('📋 Page $pageCount has ${files.length} files');

        allFiles.addAll(files);

        pageToken = fileList.nextPageToken;
      } while (pageToken != null);

      print('📁 Total files in folder: ${allFiles.length}');

      // Map to GoogleDriveFile results
      return allFiles
          .map((file) => GoogleDriveFile(
                id: file.id ?? '',
                name: file.name ?? 'Unknown',
                mimeType: file.mimeType ?? '',
              ))
          .toList();
    } catch (e) {
      print('❌ Error getting files: $e');
      print('💥 Stack trace: ${StackTrace.current}');
      return [];
    }
  }

  /// ✅ Alternative method: Open Google Drive folder in browser
  static Future<void> openDriveFolderInBrowser() async {
    final Uri url = Uri.parse('https://drive.google.com/drive/folders/$folderId');
    try {
      // Try the preferred external application mode first
      final launched = await launchUrl(url, mode: LaunchMode.externalApplication);
      if (!launched) {
        print('openDriveFolderInBrowser: externalApplication failed, trying platformDefault');
        final fallback = await launchUrl(url, mode: LaunchMode.platformDefault);
        if (!fallback) {
          print('openDriveFolderInBrowser: platformDefault also failed for $url');
        }
      }
    } catch (e) {
      print('Error launching URL: $e');
    }
  }

  /// Debug helper: return the first visible files (name and id) for the signed-in user
  static Future<List<String>> debugListFiles() async {
    try {
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return ['Not signed in'];

      final authHeaders = await googleUser.authHeaders;
      final authenticateClient = _createAuthenticatedClient(authHeaders);
      final driveApi = drive.DriveApi(authenticateClient);

      final fileList = await driveApi.files.list(
        pageSize: 50,
        orderBy: 'modifiedTime desc',
        includeItemsFromAllDrives: true,
        supportsAllDrives: true,
      );

      final results = <String>[];
      results.add('Signed in as: ${googleUser.email}');
      for (var file in fileList.files ?? []) {
        results.add('${file.name} (ID: ${file.id}, mimeType: ${file.mimeType})');
      }
      if (results.length == 1) results.add('No files visible to this account');
      return results;
    } catch (e) {
      print('debugListFiles error: $e');
      return ['Error: $e'];
    }
  }

  /// Get accessible URL for a Google Drive image
  static String getImageUrl(String fileId) {
    return 'https://drive.google.com/uc?export=view&id=$fileId';
  }

  /// Get downloadable URL for a Google Drive image
  static String getDownloadUrl(String fileId) {
    return 'https://drive.google.com/uc?export=download&id=$fileId';
  }

  /// ✅ Debug method: List first 10 files visible to the user
  static Future<void> debugListFirstFiles() async {
    try {
      print('\n🐛 DEBUG: Listing first 10 files accessible to user...');
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        print('❌ User not signed in');
        return;
      }

      final authHeaders = await googleUser.authHeaders;
      final authenticateClient = _createAuthenticatedClient(authHeaders);
      final driveApi = drive.DriveApi(authenticateClient);

      final fileList = await driveApi.files.list(
        pageSize: 10,
        orderBy: 'modifiedTime desc',
      );

      print('📋 Files visible to ${googleUser.email}:');
      for (var file in fileList.files ?? []) {
        print('  📄 ${file.name} (ID: ${file.id})');
      }
    } catch (e) {
      print('❌ Debug error: $e');
    }
  }

  /// Sign out from Google
  static Future<void> signOut() async {
    await _googleSignIn.signOut();
  }

  /// Create authenticated HTTP client
  static http.Client _createAuthenticatedClient(Map<String, String> authHeaders) {
    return _AuthorizedClient(http.Client(), authHeaders);
  }

  /// Download file bytes for a given Drive file id (requires signed-in user)
  static Future<Uint8List?> downloadFileBytes(String fileId) async {
    try {
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null;
      final authHeaders = await googleUser.authHeaders;
      final authenticateClient = _createAuthenticatedClient(authHeaders);
      final driveApi = drive.DriveApi(authenticateClient);

      final media = await driveApi.files.get(
        fileId,
        downloadOptions: drive.DownloadOptions.fullMedia,
      );

      final stream = (media as drive.Media).stream;
      final List<int> data = [];
      await for (final chunk in stream) {
        data.addAll(chunk);
      }
      return Uint8List.fromList(data);
    } catch (e) {
      print('Error downloading file $fileId: $e');
      return null;
    }
  }
}

/// Custom HTTP client that automatically adds authorization headers
class _AuthorizedClient extends http.BaseClient {
  final http.Client _inner;
  final Map<String, String> _authHeaders;

  _AuthorizedClient(this._inner, this._authHeaders);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    request.headers.addAll(_authHeaders);
    return _inner.send(request);
  }
}

/// Model class for Google Drive files
class GoogleDriveFile {
  final String id;
  final String name;
  final String mimeType;

  GoogleDriveFile({
    required this.id,
    required this.name,
    required this.mimeType,
  });

  String get imageUrl => GoogleDriveService.getImageUrl(id);
}
