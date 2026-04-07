import 'package:get/get.dart';
import 'package:webview_flutter/webview_flutter.dart';

class WebViewController2 extends GetxController {
  late final WebViewController webViewController;
  final RxBool isLoading = true.obs;
  final RxString title = ''.obs;
  late final String url;

  @override
  void onInit() {
    super.onInit();
    url = Get.arguments as String;

    webViewController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) {
            isLoading.value = true;
          },
          onPageFinished: (_) {
            isLoading.value = false;
            webViewController.getTitle().then((t) {
              if (t != null && t.isNotEmpty) {
                title.value = t;
              }
            });
          },
          onWebResourceError: (error) {
            isLoading.value = false;
            print('웹뷰 오류: ${error.description}');
          },
        ),
      )
      ..loadRequest(Uri.parse(url));
  }
}
