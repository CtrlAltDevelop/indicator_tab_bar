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

/// Where the demo can put the bar.
enum Placement {
  bottom('bottom', Alignment.bottomCenter),
  top('top', Alignment.topCenter),
  start('start', AlignmentDirectional.bottomStart),
  end('end', AlignmentDirectional.bottomEnd);

  const Placement(this.label, this.alignment);

  final String label;
  final AlignmentGeometry alignment;
}

/// Every knob the demo exposes, as one value.
@immutable
class IndicatorConfig {
  const IndicatorConfig({
    this.indicatorWidth = 20,
    this.strokeWidth = 3,
    this.radius = 4,
    this.bottomInset = 0,
    this.placement = Placement.bottom,
    this.shaded = false,
  });

  final double indicatorWidth;
  final double strokeWidth;
  final double radius;
  final double bottomInset;
  final Placement placement;

  /// Whether to fill the bar with a gradient rather than a flat colour.
  final bool shaded;

  IndicatorConfig copyWith({
    double? indicatorWidth,
    double? strokeWidth,
    double? radius,
    double? bottomInset,
    Placement? placement,
    bool? shaded,
  }) {
    return IndicatorConfig(
      indicatorWidth: indicatorWidth ?? this.indicatorWidth,
      strokeWidth: strokeWidth ?? this.strokeWidth,
      radius: radius ?? this.radius,
      bottomInset: bottomInset ?? this.bottomInset,
      placement: placement ?? this.placement,
      shaded: shaded ?? this.shaded,
    );
  }

  /// The indicator these knobs describe.
  LineTabIndicator build(ColorScheme scheme) {
    // `insets` deflates the rect the bar is aligned in, so a bottom inset
    // lifts an underline and a top alignment is measured from the top edge.
    final EdgeInsetsGeometry insets = switch (placement) {
      Placement.top => EdgeInsets.only(top: bottomInset),
      _ => EdgeInsets.only(bottom: bottomInset),
    };

    if (shaded) {
      return LineTabIndicator.gradient(
        gradient: LinearGradient(
          colors: <Color>[scheme.primary, scheme.tertiary],
        ),
        strokeWidth: strokeWidth,
        indicatorWidth: indicatorWidth,
        radius: radius,
        alignment: placement.alignment,
        insets: insets,
      );
    }
    return LineTabIndicator(
      color: scheme.primary,
      strokeWidth: strokeWidth,
      indicatorWidth: indicatorWidth,
      radius: radius,
      alignment: placement.alignment,
      insets: insets,
    );
  }
}

class ExampleApp extends StatefulWidget {
  const ExampleApp({super.key});

  @override
  State<ExampleApp> createState() => _ExampleAppState();
}

class _ExampleAppState extends State<ExampleApp> {
  ThemeMode _mode = ThemeMode.light;
  TextDirection _direction = TextDirection.ltr;

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
      // So the directional placements can be seen flipping.
      builder: (BuildContext context, Widget? child) =>
          Directionality(textDirection: _direction, child: child!),
      home: HomePage(
        onToggleBrightness: () => setState(() {
          _mode = _mode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
        }),
        onToggleDirection: () => setState(() {
          _direction = _direction == TextDirection.ltr
              ? TextDirection.rtl
              : TextDirection.ltr;
        }),
      ),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({
    required this.onToggleBrightness,
    required this.onToggleDirection,
    super.key,
  });

  final VoidCallback onToggleBrightness;
  final VoidCallback onToggleDirection;

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
  IndicatorConfig _config = const IndicatorConfig();

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
            onPressed: widget.onToggleDirection,
            icon: const Icon(Icons.format_textdirection_r_to_l),
            tooltip: 'Toggle reading direction',
          ),
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
          indicator: _config.build(theme.colorScheme),
        ),
      ),
      // One scroll view for every tab, with only the body sliver swapped —
      // which is why the switch has to happen at the sliver level.
      body: CustomScrollView(
        slivers: <Widget>[
          SliverToBoxAdapter(
            child: _Knobs(
              config: _config,
              onChanged: (IndicatorConfig config) =>
                  setState(() => _config = config),
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

/// Live controls for every field of the indicator.
class _Knobs extends StatelessWidget {
  const _Knobs({required this.config, required this.onChanged});

  final IndicatorConfig config;
  final ValueChanged<IndicatorConfig> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          _slider(
            'indicatorWidth',
            config.indicatorWidth,
            0,
            120,
            (double v) => onChanged(config.copyWith(indicatorWidth: v)),
          ),
          _slider(
            'strokeWidth',
            config.strokeWidth,
            0,
            12,
            (double v) => onChanged(config.copyWith(strokeWidth: v)),
          ),
          _slider(
            'radius',
            config.radius,
            0,
            12,
            (double v) => onChanged(config.copyWith(radius: v)),
          ),
          _slider(
            'insets',
            config.bottomInset,
            0,
            16,
            (double v) => onChanged(config.copyWith(bottomInset: v)),
          ),
          Row(
            children: <Widget>[
              const SizedBox(width: 120, child: Text('alignment')),
              Expanded(
                child: SegmentedButton<Placement>(
                  showSelectedIcon: false,
                  segments: <ButtonSegment<Placement>>[
                    for (final Placement placement in Placement.values)
                      ButtonSegment<Placement>(
                        value: placement,
                        label: Text(placement.label),
                      ),
                  ],
                  selected: <Placement>{config.placement},
                  onSelectionChanged: (Set<Placement> selection) =>
                      onChanged(config.copyWith(placement: selection.single)),
                ),
              ),
            ],
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('gradient'),
            subtitle: const Text(
              'LineTabIndicator.gradient, primary → tertiary',
            ),
            value: config.shaded,
            onChanged: (bool value) =>
                onChanged(config.copyWith(shaded: value)),
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
