// Renders the README's images from the real widgets, so they can be redone
// whenever the package changes:
//
//   flutter test --update-goldens test/screenshots_test.dart
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:indicator_tab_bar/indicator_tab_bar.dart';

/// `flutter test` draws text in the placeholder Ahem font unless real fonts
/// are registered, so load the ones these widgets are actually drawn with.
Future<void> _loadFonts() async {
  final String? flutterRoot = Platform.environment['FLUTTER_ROOT'];
  if (flutterRoot == null) return;
  final String fonts = '$flutterRoot/bin/cache/artifacts/material_fonts';

  Future<void> load(String family, String path) async {
    final File file = File(path);
    if (!file.existsSync()) return;
    await (FontLoader(family)..addFont(
          file.readAsBytes().then((Uint8List b) => ByteData.view(b.buffer)),
        ))
        .load();
  }

  await load('Roboto', '$fonts/Roboto-Regular.ttf');
  await load('MaterialIcons', '$fonts/MaterialIcons-Regular.otf');
}

const List<String> _labels = <String>['Spot', 'Futures & derivatives', 'Earn'];

/// A `TabBar` with [indicator] under its selected tab, on [brightness].
Widget _bar(LineTabIndicator indicator, Brightness brightness, String caption) {
  final ThemeData theme = ThemeData(
    colorSchemeSeed: const Color(0xFF2F6BFF),
    brightness: brightness,
  );

  return Theme(
    data: theme,
    child: ColoredBox(
      color: theme.colorScheme.surface,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(
              caption,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                // The loaded font, by name — a bare `TextStyle` would fall
                // back to the test placeholder face.
                fontFamily: 'Roboto',
                fontSize: 12,
                height: 1.3,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            DefaultTabController(
              length: _labels.length,
              child: TabBar(
                isScrollable: true,
                tabAlignment: TabAlignment.start,
                dividerColor: theme.colorScheme.outlineVariant,
                indicatorSize: TabBarIndicatorSize.label,
                indicator: indicator.copyWith(color: theme.colorScheme.primary),
                labelColor: theme.colorScheme.onSurface,
                unselectedLabelColor: theme.colorScheme.onSurfaceVariant,
                tabs: <Widget>[
                  for (final String label in _labels) Tab(text: label),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

Future<void> _shoot(
  WidgetTester tester,
  Widget child,
  Size size,
  String path,
) async {
  // `physicalSize` is in device pixels, so it is the logical size scaled up.
  tester.view
    ..physicalSize = size * 2.0
    ..devicePixelRatio = 2.0;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      // A `Material` ancestor, so text is not drawn with the debug underline.
      home: Material(
        type: MaterialType.transparency,
        child: Align(alignment: Alignment.topLeft, child: child),
      ),
    ),
  );
  await tester.pumpAndSettle();

  await expectLater(find.byType(MaterialApp), matchesGoldenFile(path));
}

void main() {
  setUpAll(_loadFonts);

  testWidgets('the indicator, light and dark', (WidgetTester tester) async {
    await _shoot(
      tester,
      const Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          _Row(brightness: Brightness.light),
          _Row(brightness: Brightness.dark),
        ],
      ),
      const Size(720, 600),
      '../../screenshots/indicator.png',
    );
  });

  testWidgets('the sliver switcher mid-fade', (WidgetTester tester) async {
    tester.view
      ..physicalSize = const Size(720, 640) * 2.0
      ..devicePixelRatio = 2.0;
    addTearDown(tester.view.reset);

    Widget build(int page) => MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(colorSchemeSeed: const Color(0xFF2F6BFF)),
      home: Scaffold(
        body: CustomScrollView(
          slivers: <Widget>[
            const SliverAppBar(title: Text('History'), pinned: true),
            SliverAnimatedSwitcher(
              duration: const Duration(milliseconds: 400),
              child: SliverList.list(
                key: ValueKey<int>(page),
                children: <Widget>[
                  for (int i = 0; i < 6; i++)
                    ListTile(
                      leading: const Icon(Icons.receipt_long_outlined),
                      title: Text('Page $page — row ${i + 1}'),
                      subtitle: const Text('Faded in as a sliver, in place.'),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );

    await tester.pumpWidget(build(0));
    await tester.pumpWidget(build(1));
    await tester.pump();
    // Half way through the fade, where the incoming sliver is still ghosted.
    await tester.pump(const Duration(milliseconds: 200));

    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('../../screenshots/sliver_switcher.png'),
    );
  });
}

/// One brightness, with the same indicator at four shapes.
class _Row extends StatelessWidget {
  const _Row({required this.brightness});

  final Brightness brightness;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        _bar(
          const LineTabIndicator(
            color: Color(0xFF000000),
            indicatorWidth: 20,
            strokeWidth: 3,
            radius: 4,
          ),
          brightness,
          'indicatorWidth: 20, strokeWidth: 3, radius: 4',
        ),
        _bar(
          const LineTabIndicator(color: Color(0xFF000000), indicatorWidth: 20),
          brightness,
          'indicatorWidth: 20, strokeWidth: 3, radius: 0 — square ends',
        ),
        _bar(
          const LineTabIndicator(
            color: Color(0xFF000000),
            indicatorWidth: 56,
            strokeWidth: 6,
            radius: 3,
          ),
          brightness,
          'indicatorWidth: 56, strokeWidth: 6, radius: 3 — a wider pill',
        ),
      ],
    );
  }
}
