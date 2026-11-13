import 'package:hive_ce/hive.dart';
import 'package:note_keeper/app/services/database_service.dart';

class BaseRepository<T> {
  late Box<T> db;

  late IDatabaseService databaseService;

  Future<void> openDatabase(TypeAdapter<T> adapter, String table) async {

    db = await databaseService.open<T>(
      table: table,
      adapter: adapter,
    );
  }
}