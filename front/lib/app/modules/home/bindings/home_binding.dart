import 'package:get/get.dart';
import '../controllers/home_controller.dart';
import '../../posts/controllers/posts_controller.dart';
import '../../subscription/controllers/subscription_controller.dart';

class HomeBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<HomeController>(() => HomeController());
    Get.lazyPut<PostsController>(() => PostsController(boardId: 'all'));
    Get.lazyPut<SubscriptionController>(() => SubscriptionController());
  }
}
