import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService extends GetxService {
  final SupabaseClient client = Supabase.instance.client;

  Future<SupabaseService> init() async {
    return this;
  }
}
