import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:note_keeper/features/home/home_scaffold.dart';

void main() {
  testWidgets('home layout uses the app theme and page actions', (
    tester,
  ) async {
    var actionPressed = false;
    const appBarColor = Colors.teal;

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(
          appBarTheme: const AppBarTheme(backgroundColor: appBarColor),
        ),
        home: HomeScaffold(
          title: const Text('Note Keeper'),
          actions: [
            IconButton(
              onPressed: () => actionPressed = true,
              icon: const Icon(Icons.add),
            ),
          ],
          body: const Text('Categories'),
        ),
      ),
    );

    expect(find.text('Note Keeper'), findsOneWidget);
    expect(find.text('Categories'), findsOneWidget);
    expect(find.byIcon(Icons.logout), findsOneWidget);
    expect(find.byType(BackButton), findsNothing);
    final appBar = tester.widget<AppBar>(find.byType(AppBar));
    expect(
      appBar.backgroundColor ??
          AppBarTheme.of(tester.element(find.byType(AppBar))).backgroundColor,
      appBarColor,
    );

    await tester.tap(find.byIcon(Icons.add));
    expect(actionPressed, isTrue);
  });

  testWidgets('groups page uses the shared layout and returns home', (
    tester,
  ) async {
    final router = GoRouter(
      initialLocation: '/groups/123',
      routes: [
        GoRoute(
          path: '/groups/:categoryId',
          builder: (context, state) => HomeScaffold(
            title: const Text('Groups'),
            onBack: () => context.go('/home'),
            body: const SizedBox.shrink(),
          ),
        ),
        GoRoute(
          path: '/home',
          builder: (context, state) => const HomeScaffold(
            title: Text('Note Keeper'),
            body: SizedBox.shrink(),
          ),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();

    expect(find.text('Groups'), findsOneWidget);
    expect(find.byIcon(Icons.logout), findsOneWidget);
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(find.text('Note Keeper'), findsOneWidget);
  });
}
