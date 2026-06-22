import 'package:flutter_test/flutter_test.dart';
import '../helpers/test_db.dart';

void main() {
  test('onCreate seeds two categories with a default', () async {
    final db = makeTestDb();
    addTearDown(db.close);

    final cats = await db.select(db.categories).get();
    expect(cats, hasLength(2));
    expect(cats.where((c) => c.isDefault), hasLength(1));
    expect(cats.map((c) => c.name), containsAll(['Mine', 'Not mine']));
  });
}
