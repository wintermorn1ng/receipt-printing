import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:receipt_printing/services/ticket_service.dart';

void main() {
  late Database db;
  late TicketService ticketService;

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    db = await openDatabase(
      inMemoryDatabasePath,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE settings (
            key TEXT PRIMARY KEY,
            value TEXT
          )
        ''');
      },
    );
    ticketService = TicketService.withDatabase(db);
  });

  tearDown(() async {
    await db.close();
  });

  group('TicketService', () {
    group('getCurrentTicketNumber', () {
      test('should return 1 when no ticket number exists', () async {
        final result = await ticketService.getCurrentTicketNumber();
        expect(result, 1);
      });

      test('should return stored ticket number', () async {
        // Arrange
        await db.insert('settings', {'key': 'current_ticket_number', 'value': '128'});

        // Act
        final result = await ticketService.getCurrentTicketNumber();

        // Assert
        expect(result, 128);
      });
    });

    group('incrementTicketNumber', () {
      test('should increment from 1 to 2 when no ticket number exists', () async {
        final result = await ticketService.incrementTicketNumber();
        expect(result, 2);

        // Verify stored value
        final stored = await ticketService.getCurrentTicketNumber();
        expect(stored, 2);
      });

      test('should increment existing ticket number', () async {
        // Arrange
        await db.insert('settings', {'key': 'current_ticket_number', 'value': '100'});

        // Act
        final result = await ticketService.incrementTicketNumber();

        // Assert
        expect(result, 101);
      });
    });

    group('resetTicketNumber', () {
      test('should reset ticket number to 1', () async {
        // Arrange
        await db.insert('settings', {'key': 'current_ticket_number', 'value': '128'});

        // Act
        await ticketService.resetTicketNumber();

        // Assert
        final result = await ticketService.getCurrentTicketNumber();
        expect(result, 1);
      });

      test('should update last reset date to today', () async {
        // Act
        await ticketService.resetTicketNumber();

        // Assert
        final lastResetDate = await ticketService.getLastResetDate();
        final today = _formatDate(DateTime.now());
        expect(lastResetDate, today);
      });
    });

    group('setTicketNumber', () {
      test('should set ticket number to specified value', () async {
        await ticketService.setTicketNumber(50);
        final result = await ticketService.getCurrentTicketNumber();
        expect(result, 50);
      });

      test('should overwrite existing ticket number', () async {
        // Arrange
        await db.insert('settings', {'key': 'current_ticket_number', 'value': '100'});

        // Act
        await ticketService.setTicketNumber(200);

        // Assert
        final result = await ticketService.getCurrentTicketNumber();
        expect(result, 200);
      });

      test('should throw ArgumentError when number is less than 1', () async {
        expect(
          () => ticketService.setTicketNumber(0),
          throwsA(isA<ArgumentError>()),
        );
      });

      test('should throw ArgumentError when number is negative', () async {
        expect(
          () => ticketService.setTicketNumber(-1),
          throwsA(isA<ArgumentError>()),
        );
      });
    });

    group('checkDailyReset', () {
      test('should reset ticket number when last reset date is different', () async {
        // Arrange
        final yesterday = DateTime.now().subtract(const Duration(days: 1));
        await db.insert('settings', {'key': 'current_ticket_number', 'value': '128'});
        await db.insert('settings', {'key': 'last_reset_date', 'value': _formatDate(yesterday)});

        // Act
        await ticketService.checkDailyReset();

        // Assert
        final ticketNumber = await ticketService.getCurrentTicketNumber();
        expect(ticketNumber, 1);

        final lastResetDate = await ticketService.getLastResetDate();
        final today = _formatDate(DateTime.now());
        expect(lastResetDate, today);
      });

      test('should not reset ticket number when last reset date is today', () async {
        // Arrange
        final today = _formatDate(DateTime.now());
        await db.insert('settings', {'key': 'current_ticket_number', 'value': '128'});
        await db.insert('settings', {'key': 'last_reset_date', 'value': today});

        // Act
        await ticketService.checkDailyReset();

        // Assert
        final ticketNumber = await ticketService.getCurrentTicketNumber();
        expect(ticketNumber, 128);
      });

      test('should reset ticket number when no last reset date exists', () async {
        // Arrange
        await db.insert('settings', {'key': 'current_ticket_number', 'value': '50'});

        // Act
        await ticketService.checkDailyReset();

        // Assert
        final ticketNumber = await ticketService.getCurrentTicketNumber();
        expect(ticketNumber, 1);

        final lastResetDate = await ticketService.getLastResetDate();
        final today = _formatDate(DateTime.now());
        expect(lastResetDate, today);
      });
    });

    group('getLastResetDate', () {
      test('should return null when no last reset date exists', () async {
        final result = await ticketService.getLastResetDate();
        expect(result, isNull);
      });

      test('should return stored last reset date', () async {
        // Arrange
        await db.insert('settings', {'key': 'last_reset_date', 'value': '2024-01-15'});

        // Act
        final result = await ticketService.getLastResetDate();

        // Assert
        expect(result, '2024-01-15');
      });
    });
  });
}

/// 格式化日期为 YYYY-MM-DD
String _formatDate(DateTime dateTime) {
  final year = dateTime.year.toString().padLeft(4, '0');
  final month = dateTime.month.toString().padLeft(2, '0');
  final day = dateTime.day.toString().padLeft(2, '0');
  return '$year-$month-$day';
}