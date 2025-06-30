import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseProvider extends GetxService {
  final SupabaseClient client = Supabase.instance.client;

  Future<SupabaseProvider> init() async {
    return this;
  }
}
