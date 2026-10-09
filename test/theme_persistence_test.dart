import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:project_sla_task_tracker/core/theme/theme_controller.dart';
import 'package:project_sla_task_tracker/services/storage_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues({});

  setUpAll(StorageService.instance.init);

  test('saved appearance preference is restored by load', () async {
    final controller = ThemeController.instance;
    await controller.load();
    expect(controller.value, ThemeMode.system);

    await controller.setMode(ThemeMode.dark);
    expect(controller.value, ThemeMode.dark);

    await controller.load();
    expect(controller.value, ThemeMode.dark);

    await controller.setMode(ThemeMode.system);
  });
}
