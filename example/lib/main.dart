import 'package:flutter/material.dart';
import 'package:indicator_tab_bar/indicator_tab_bar.dart';

void main() => runApp(const ExampleApp());

/// The three tabs, each with a body of its own.
enum Section {
  spot('Spot'),
  futures('Futures & derivatives'),
  earn('Earn');

  const Section(this.label);

  final String label;
}

class ExampleApp extends StatefulWidget {
  const ExampleApp({super.key});

  @override
  State<ExampleApp> createState() => _ExampleAppState();
}

class _ExampleAppState extends State<ExampleApp> {
  ThemeMode _mode = ThemeMode.light;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'indicator_tab_bar',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: const Color(0xFF2F6BFF),
        brightness: Brightness.light,
      ),
      darkTheme: ThemeData(
        colorSchemeSeed: const Color(0xFF2F6BFF),
        brightness: Brightness.dark,
      ),
      themeMode: _mode,
      home: HomePage(
        onToggleBrightness: () => setState(() {
          _mode = _mode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
        }),
      ),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({required this.onToggleBrightness, super.key});

  final VoidCallback onToggleBrightness;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  late final TabController _tabs = TabController(
    length: Section.values.length,
    vsync: this,
  )..addListener(_onTabChanged);

  Section _section = Section.spot;

  // The indicator's knobs, live, so the shape can be dialled in on screen.
  double _indicatorWidth = 20;
  double _strokeWidth = 3;
  double _radius = 4;

  void _onTabChanged() {
    // Fires twice per swipe — on the drag and again on the settle.
    final Section next = Section.values[_tabs.index];
    if (next != _section) setState(() => _section = next);
  }

  @override
  void dispose() {
    _tabs
      ..removeListener(_onTabChanged)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('indicator_tab_bar'),
        actions: <Widget>[
          IconButton(
            onPressed: widget.onToggleBrightness,
            icon: Icon(
              theme.brightness == Brightness.light
                  ? Icons.dark_mode_outlined
                  : Icons.light_mode_outlined,
            ),
            tooltip: 'Toggle brightness',
          ),
        ],
        bottom: TabBar(
          controller: _tabs,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          // Labels of very different lengths, to show that the bar under each
          // one stays the same width regardless.
          tabs: <Widget>[
            for (final Section section in Section.values)
              Tab(text: section.label),
          ],
          indicatorSize: TabBarIndicatorSize.label,
          indicator: LineTabIndicator(
            color: theme.colorScheme.primary,
            strokeWidth: _strokeWidth,
            indicatorWidth: _indicatorWidth,
            radius: _radius,
          ),
        ),
      ),
      // One scroll view for every tab, with only the body sliver swapped —
      // which is why the switch has to happen at the sliver level.
      body: CustomScrollView(
        slivers: <Widget>[
          SliverToBoxAdapter(
            child: _Knobs(
              indicatorWidth: _indicatorWidth,
              strokeWidth: _strokeWidth,
              radius: _radius,
              onChanged: (double width, double stroke, double radius) =>
                  setState(() {
                    _indicatorWidth = width;
                    _strokeWidth = stroke;
                    _radius = radius;
                  }),
            ),
          ),
          SliverAnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            switchInCurve: Curves.easeOut,
            // The key is what marks this as a different sliver; without it the
            // list would be updated in place and nothing would fade.
            child: _SectionRows(
              key: ValueKey<Section>(_section),
              section: _section,
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
        ],
      ),
    );
  }
}

/// The rows one section shows, as a sliver.
class _SectionRows extends StatelessWidget {
  const _SectionRows({required this.section, super.key});

  final Section section;

  @override
  Widget build(BuildContext context) {
    final Color color = switch (section) {
      Section.spot => Colors.teal,
      Section.futures => Colors.deepOrange,
      Section.earn => Colors.purple,
    };

    return SliverList.builder(
      itemCount: 12,
      itemBuilder: (BuildContext context, int index) => ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.15),
          child: Text('${index + 1}', style: TextStyle(color: color)),
        ),
        title: Text('${section.label} row ${index + 1}'),
        subtitle: const Text('Swapped as a sliver, faded in place.'),
      ),
    );
  }
}

/// Sliders for the indicator's three metrics.
class _Knobs extends StatelessWidget {
  const _Knobs({
    required this.indicatorWidth,
    required this.strokeWidth,
    required this.radius,
    required this.onChanged,
  });

  final double indicatorWidth;
  final double strokeWidth;
  final double radius;
  final void Function(double width, double stroke, double radius) onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          _slider(
            'indicatorWidth',
            indicatorWidth,
            0,
            120,
            (double v) => onChanged(v, strokeWidth, radius),
          ),
          _slider(
            'strokeWidth',
            strokeWidth,
            0,
            12,
            (double v) => onChanged(indicatorWidth, v, radius),
          ),
          _slider(
            'radius',
            radius,
            0,
            12,
            (double v) => onChanged(indicatorWidth, strokeWidth, v),
          ),
        ],
      ),
    );
  }

  Widget _slider(
    String label,
    double value,
    double min,
    double max,
    ValueChanged<double> onSliderChanged,
  ) {
    return Row(
      children: <Widget>[
        SizedBox(width: 120, child: Text(label)),
        Expanded(
          child: Slider(
            value: value,
            min: min,
            max: max,
            onChanged: onSliderChanged,
          ),
        ),
        SizedBox(
          width: 40,
          child: Text(value.toStringAsFixed(0), textAlign: TextAlign.end),
        ),
      ],
    );
  }
}
