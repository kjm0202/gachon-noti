import 'package:get/get.dart';
import '../modules/posts/controllers/posts_controller.dart';
import '../modules/subscription/controllers/subscription_controller.dart';
import '../data/providers/auth_provider.dart';
import '../data/providers/supabase_provider.dart';
import '../modules/home/controllers/home_controller.dart';
import '../modules/login/controllers/login_controller.dart';

class InitialBinding extends Bindings {
  @override
  void dependencies() {
    // 서비스 프로바이더들은 이미 main.dart에서 초기화되었습니다
    // 필요한 컨트롤러들 등록
    Get.lazyPut<HomeController>(() => HomeController(), fenix: true);
    Get.lazyPut<LoginController>(() => LoginController(), fenix: true);
    Get.lazyPut<PostsController>(() => PostsController(boardId: 'all'),
        fenix: true);
    Get.lazyPut<SubscriptionController>(() => SubscriptionController(),
        fenix: true);
  }
}
