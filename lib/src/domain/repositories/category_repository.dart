import '../models/category.dart';

abstract class CategoryRepository {
  Future<List<Category>> all();
}
