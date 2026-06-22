import '../../domain/models/category.dart';
import '../../domain/repositories/category_repository.dart';
import '../database/database.dart';
import '../database/mappers.dart';

class CategoryRepositoryImpl implements CategoryRepository {
  CategoryRepositoryImpl(this._db);
  final AppDatabase _db;

  @override
  Future<List<Category>> all() async {
    final rows = await _db.select(_db.categories).get();
    return rows.map((r) => r.toDomain()).toList();
  }
}
