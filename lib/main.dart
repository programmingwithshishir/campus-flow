import 'package:flutter/material.dart';

import 'app.dart';
import 'features/routines/services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService.instance.initialize();
  runApp(const TaskFlowApp());
}
