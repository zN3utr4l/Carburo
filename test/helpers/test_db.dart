import 'package:drift/native.dart';
import 'package:tanko/src/data/database/database.dart';

AppDatabase makeTestDb() => AppDatabase.forTesting(NativeDatabase.memory());
