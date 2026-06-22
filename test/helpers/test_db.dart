import 'package:drift/native.dart';
import 'package:carburo/src/data/database/database.dart';

AppDatabase makeTestDb() => AppDatabase.forTesting(NativeDatabase.memory());
