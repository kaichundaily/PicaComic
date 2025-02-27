import 'package:flutter/material.dart';

/// copied from flutter source
class _SliderDefaultsM3 extends SliderThemeData {
  _SliderDefaultsM3(this.context)
      : super(trackHeight: 4.0);

  final BuildContext context;
  late final ColorScheme _colors = Theme.of(context).colorScheme;

  @override
  Color? get activeTrackColor => _colors.primary;

  @override
  Color? get inactiveTrackColor => _colors.surfaceVariant;

  @override
  Color? get secondaryActiveTrackColor => _colors.primary.withOpacity(0.54);

  @override
  Color? get disabledActiveTrackColor => _colors.onSurface.withOpacity(0.38);

  @override
  Color? get disabledInactiveTrackColor => _colors.onSurface.withOpacity(0.12);

  @override
  Color? get disabledSecondaryActiveTrackColor => _colors.onSurface.withOpacity(0.12);

  @override
  Color? get activeTickMarkColor => _colors.onPrimary.withOpacity(0.38);

  @override
  Color? get inactiveTickMarkColor => _colors.onSurfaceVariant.withOpacity(0.38);

  @override
  Color? get disabledActiveTickMarkColor => _colors.onSurface.withOpacity(0.38);

  @override
  Color? get disabledInactiveTickMarkColor => _colors.onSurface.withOpacity(0.38);

  @override
  Color? get thumbColor => _colors.primary;

  @override
  Color? get disabledThumbColor => Color.alphaBlend(_colors.onSurface.withOpacity(0.38), _colors.surface);

  @override
  Color? get overlayColor => MaterialStateColor.resolveWith((Set<MaterialState> states) {
    if (states.contains(MaterialState.hovered)) {
      return _colors.primary.withOpacity(0.08);
    }
    if (states.contains(MaterialState.focused)) {
      return _colors.primary.withOpacity(0.12);
    }
    if (states.contains(MaterialState.dragged)) {
      return _colors.primary.withOpacity(0.12);
    }

    return Colors.transparent;
  });

  @override
  TextStyle? get valueIndicatorTextStyle => Theme.of(context).textTheme.labelMedium!.copyWith(
    color: _colors.onPrimary,
  );

  @override
  SliderComponentShape? get valueIndicatorShape => const DropSliderValueIndicatorShape();
}

class CustomSlider extends StatefulWidget {
  const CustomSlider({required this.min, required this.max, required this.value, required this.divisions, required this.onChanged, this.reversed = false, super.key});

  final double min;

  final double max;

  final double value;

  final int divisions;

  final void Function(double) onChanged;

  final bool reversed;

  @override
  State<CustomSlider> createState() => _CustomSliderState();
}

class _CustomSliderState extends State<CustomSlider> {
  late double value;

  @override
  void initState() {
    super.initState();
    value = widget.value;
  }

  @override
  void didUpdateWidget(CustomSlider oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value != oldWidget.value) {
      setState(() {
        value = widget.value;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final theme = _SliderDefaultsM3(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 12),
      child: LayoutBuilder(
        builder: (context, constrains) => MouseRegion(
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTapDown: (details){
              var dx = details.localPosition.dx;
              if(widget.reversed){
                dx = constrains.maxWidth - dx;
              }
              var gap = constrains.maxWidth / widget.divisions;
              var gapValue = (widget.max - widget.min)  / widget.divisions;
              widget.onChanged.call((dx / gap).round() * gapValue + widget.min);
            },
            onVerticalDragUpdate: (details){
              var dx = details.localPosition.dx;
              if(dx > constrains.maxWidth || dx < 0)  return;
              if(widget.reversed){
                dx = constrains.maxWidth - dx;
              }
              var gap = constrains.maxWidth / widget.divisions;
              var gapValue = (widget.max - widget.min)  / widget.divisions;
              widget.onChanged.call((dx / gap).round() * gapValue + widget.min);
            },
            child: SizedBox(
              height: 24,
              child: Center(
                child: SizedBox(
                  height: 24,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Positioned.fill(
                        child: Center(
                          child: Container(
                            width: double.infinity,
                            height: 6,
                            decoration: BoxDecoration(
                                color: theme.inactiveTrackColor,
                                borderRadius: const BorderRadius.all(Radius.circular(10))
                            ),
                          ),
                        ),
                      ),
                      if(constrains.maxWidth / widget.divisions > 10)
                        Positioned.fill(
                          child: Row(
                            children: (){
                              var res = <Widget>[];
                              for(int i = 0; i<widget.divisions-1; i++){
                                res.add(const Spacer());
                                res.add(Container(
                                  width: 4,
                                  height: 4,
                                  decoration: BoxDecoration(
                                    color: colorScheme.surface.withRed(10),
                                    shape: BoxShape.circle,
                                  ),
                                ));
                              }
                              res.add(const Spacer());
                              return res;
                            }.call(),
                          ),
                        ),
                      Positioned(
                        top: 0,
                        bottom: 0,
                        left: widget.reversed ? null : 0,
                        right: widget.reversed ? 0 : null,
                        child: Center(
                          child: Container(
                            width: constrains.maxWidth * ((value - widget.min) / (widget.max - widget.min)),
                            height: 8,
                            decoration: BoxDecoration(
                                color: theme.activeTrackColor,
                                borderRadius: const BorderRadius.all(Radius.circular(10))
                            ),
                          ),
                        )
                      ),
                      Positioned(
                        left: widget.reversed ? null : constrains.maxWidth * ((value - widget.min) / (widget.max - widget.min))-12,
                        right: !widget.reversed ? null : constrains.maxWidth * ((value - widget.min) / (widget.max - widget.min))-12,
                        child: Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: theme.secondaryActiveTrackColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                      Positioned(
                        top: 0,
                        bottom: 0,
                        left: widget.reversed ? null : constrains.maxWidth * ((value - widget.min) / (widget.max - widget.min))-11,
                        right: !widget.reversed ? null : constrains.maxWidth * ((value - widget.min) / (widget.max - widget.min))-11,
                        child: Center(
                          child: Container(
                            width: 22,
                            height: 22,
                            decoration: BoxDecoration(
                              color: theme.activeTrackColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                      )
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
