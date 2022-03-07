// ignore_for_file: avoid_print

import 'package:bloc/bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite/sqlite_api.dart';
import 'package:to_do_app/modules/archived_tasks/ArchivedTasksScreen.dart';
import 'package:to_do_app/modules/done_tasks/DoneTasksScreen.dart';
import 'package:to_do_app/modules/new_tasks/NewTasksScreen.dart';
import 'package:to_do_app/shared/cubit/states.dart';

class AppCubit extends Cubit<AppStates> {
  AppCubit() : super(AppInitialState());

  static AppCubit get(context) => BlocProvider.of(context);

  int currentIndex = 0;

  List<Widget> screens = const [
    NewTasksScreen(),
    DoneTasksScreen(),
    ArchivedTasksScreen()
  ];

  List<String> titles = const ['NewTasks', 'DoneTasks', 'ArchivedTasks'];

  void changeBottomNav(int index) {
    currentIndex = index;
    emit(AppChangeBottomNavState());
  }

  List<Map> newTasks = [];
  List<Map> doneTasks = [];
  List<Map> archivedTasks = [];

  late Database database;

  void createDatabase() {
    openDatabase(
      'Todo.db',
      version: 1,
      onCreate: (database, version) {
        print('database created');
        database.execute(
                'CREATE TABLE tasks (id INTEGER PRIMARY KEY, title TEXT, date TEXT, time TEXT, status TEXT)'
        ).then((value) {
          print('tables created');
        }).catchError((error) {
          print('error when creating tables : ${error.toString()}');
        });
      },
      onOpen: (database) {
        getFromDatabase(database);
        print('database opened');
      },
    ).then((value) {
      database = value;
      emit(AppCreateDatabaseState());
    });
  }

  insertToDatabase({
    required String title,
    required String time,
    required String date,
  }) async {
    await database.transaction((txn) async {
      txn.rawInsert('INSERT INTO tasks (title, date, time, status) VALUES ("$title", "$date", "$time", "new")',
      ).then((value) {
        print('$value inserted successfully');
        emit(AppInsertDatabaseState());

        getFromDatabase(database);

      }).catchError((error) {
        print('error when inserting new row : ${error.toString()}');
      });
    });
  }

  void getFromDatabase(database) {

    newTasks = [];
    doneTasks = [];
    archivedTasks = [];

    emit(AppGetDatabaseLoadingState());

    database.rawQuery('SELECT * FROM tasks').then((value) {

      value.forEach((element){
        if(element['status'] == 'new'){
          newTasks.add(element);
        }
        else if(element['status'] == 'done'){
          doneTasks.add(element);
        }
        else if(element['status'] == 'archive'){
          archivedTasks.add(element);
        }

      });
      print(value);
      emit(AppGetDatabaseState());
    });
  }

  void updateDatabase({
  required String status,
  required int id,
})async{
    await database.rawUpdate(
        'UPDATE tasks SET status = ? WHERE id = ?',
        [status , id]).then((value) => {
          getFromDatabase(database),
          emit(AppUpdateDatabaseState())
    });
  }

  void deleteDatabase({
    required int id,
  })async{
    await database.rawDelete('DELETE FROM tasks WHERE id = ?', [id])
        .then((value) => {
      getFromDatabase(database),
      emit(AppDeleteDatabaseState())
    });
  }

  bool check = false;

  IconData fabIcon = Icons.edit;

  void changeBottomSheet({
    required bool ch,
    required IconData icon,
  }) {
    check = ch;
    fabIcon = icon;
    emit(AppChangeBottomSheetState());
  }
}
