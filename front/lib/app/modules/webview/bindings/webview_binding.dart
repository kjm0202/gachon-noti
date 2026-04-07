import 'package:get/get.dart';
import '../controllers/webview_controller.dart';

class WebviewBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<WebViewController2>(() => WebViewController2());
  }
}
