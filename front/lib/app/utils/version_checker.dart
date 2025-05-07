import 'package:package_info_plus/package_info_plus.dart';
import 'package:http/http.dart' as http;

/// 깃허브의 최신 버전과 현재 앱 버전을 비교하여
/// 현재 버전이 최신 버전보다 구형이면 true, 같거나 높으면 false를 반환
class VersionChecker {
  /// 깃허브의 pubspec.yaml 파일 URL
  static const String _pubspecUrl =
      'https://github.com/kjm0202/gachon-noti/blob/supabase/front/pubspec.yaml';

  /// 최신 버전과 현재 버전을 비교하여 업데이트 필요 여부 확인
  static Future<bool> needsUpdate() async {
    try {
      // 현재 앱 버전 가져오기
      final currentVersion = await _getCurrentVersion();

      // 깃허브의 최신 버전 가져오기
      final latestVersion = await _getLatestVersion();

      print('현재 버전: $currentVersion, 최신 버전: $latestVersion');

      // 버전 비교
      return _isVersionLower(currentVersion, latestVersion);
    } catch (e) {
      print('버전 확인 중 오류 발생: $e');
      return false; // 오류 발생 시 업데이트 필요 없음으로 처리
    }
  }

  /// 현재 앱의 버전 정보 가져오기
  static Future<String> _getCurrentVersion() async {
    final PackageInfo packageInfo = await PackageInfo.fromPlatform();
    return packageInfo.version; // x.y.z 형식
  }

  /// 깃허브에서 최신 버전 정보 가져오기
  static Future<String> _getLatestVersion() async {
    final response = await http.get(Uri.parse(_pubspecUrl));

    if (response.statusCode == 200) {
      final yamlContent = response.body;

      // version: x.y.z+n 형식에서 버전 추출
      final RegExp versionRegExp = RegExp(r'version:\s*([\d\.]+)\+\d+');
      final match = versionRegExp.firstMatch(yamlContent);

      if (match != null && match.groupCount >= 1) {
        return match.group(1) ?? '0.0.0'; // x.y.z 부분 반환
      }

      throw Exception('pubspec.yaml에서 버전 정보를 찾을 수 없습니다.');
    } else {
      throw Exception(
        'GitHub에서 데이터를 가져오는 데 실패했습니다. 상태 코드: ${response.statusCode}',
      );
    }
  }

  /// 버전 A가 버전 B보다 낮은지 확인
  /// 버전 형식: x.y.z
  static bool _isVersionLower(String versionA, String versionB) {
    final List<int> componentsA = versionA.split('.').map(int.parse).toList();
    final List<int> componentsB = versionB.split('.').map(int.parse).toList();

    // 메이저 버전 비교
    if (componentsA[0] < componentsB[0]) return true;
    if (componentsA[0] > componentsB[0]) return false;

    // 마이너 버전 비교
    if (componentsA[1] < componentsB[1]) return true;
    if (componentsA[1] > componentsB[1]) return false;

    // 패치 버전 비교
    return componentsA[2] < componentsB[2];
  }
}
