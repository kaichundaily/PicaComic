import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:pica_comic/base.dart';
import 'package:pica_comic/foundation/app.dart';
import 'package:pica_comic/pages/accounts_page.dart';
import 'package:pica_comic/pages/history_page.dart';
import 'package:pica_comic/pages/image_favorites.dart';
import 'package:pica_comic/pages/main_page.dart';
import 'package:pica_comic/pages/pre_search_page.dart';
import 'package:pica_comic/pages/settings/settings_page.dart';
import 'package:pica_comic/tools/translations.dart';
import 'package:pica_comic/pages/download_page.dart';
import 'package:pica_comic/pages/downloading_page.dart';
import 'package:window_manager/window_manager.dart';
import 'components.dart';

const _kTitleBarHeight = 36.0;

class WindowFrameController extends StateController {
  bool useDarkTheme = false;

  bool isHideWindowFrame = false;

  void setDarkTheme() {
    useDarkTheme = true;
    update();
  }

  void resetTheme() {
    useDarkTheme = false;
    update();
  }

  VoidCallback openSideBar = () {};

  void hideWindowFrame() {
    isHideWindowFrame = true;
    update();
  }

  void showWindowFrame() {
    isHideWindowFrame = false;
    update();
  }
}

class WindowFrame extends StatelessWidget {
  const WindowFrame(this.child, {super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    StateController.putIfNotExists<WindowFrameController>(
        WindowFrameController());
    if (App.isMobile) return child;
    return StateBuilder<WindowFrameController>(builder: (controller) {
      if (controller.isHideWindowFrame) return child;

      var body = Stack(
        children: [
          Positioned.fill(
              child: MediaQuery(
            data: MediaQuery.of(context).copyWith(
                padding: const EdgeInsets.only(top: _kTitleBarHeight)),
            child: child,
          )),
          const _SideBar(),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Material(
              color: Colors.transparent,
              child: Theme(
                data: Theme.of(context).copyWith(
                  brightness: controller.useDarkTheme ? Brightness.dark : null,
                ),
                child: Builder(builder: (context) {
                  return SizedBox(
                    height: _kTitleBarHeight,
                    child: Row(
                      children: [
                        if (!App.isMacOS)
                          buildMenuButton(controller, context)
                              .toAlign(Alignment.centerLeft)
                        else
                          const DragToMoveArea(
                            child: SizedBox(
                              height: double.infinity,
                              width: 16,
                            ),
                          ).paddingRight(52),
                        Expanded(
                          child: DragToMoveArea(
                            child: Text(
                              'Pica Comic',
                              style: TextStyle(
                                fontSize: 13,
                                color: (controller.useDarkTheme ||
                                    context.brightness == Brightness.dark)
                                    ? Colors.white
                                    : Colors.black,
                              ),
                            ).toAlign(Alignment.centerLeft).paddingLeft(4),
                          ),
                        ),
                        if (!App.isMacOS)
                          const WindowButtons()
                        else
                          buildMenuButton(controller, context)
                              .toAlign(Alignment.centerRight),
                      ],
                    ),
                  );
                }),
              ),
            ),
          )
        ],
      );

      if(App.isLinux) {
        return VirtualWindowFrame(child: body);
      } else {
        return body;
      }
    });
  }

  Widget buildMenuButton(
      WindowFrameController controller, BuildContext context) {
    return InkWell(
        onTap: () {
          controller.openSideBar();
        },
        child: SizedBox(
          width: 42,
          height: double.infinity,
          child: Center(
            child: CustomPaint(
              size: const Size(18, 20),
              painter: _MenuPainter(
                  color: (controller.useDarkTheme ||
                          Theme.of(context).brightness == Brightness.dark)
                      ? Colors.white
                      : Colors.black),
            ),
          ),
        ));
  }
}

class _MenuPainter extends CustomPainter {
  final Color color;

  _MenuPainter({this.color = Colors.black});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = getPaint(color);
    final path = Path()
      ..moveTo(0, size.height / 4)
      ..lineTo(size.width, size.height / 4)
      ..moveTo(0, size.height / 4 * 2)
      ..lineTo(size.width, size.height / 4 * 2)
      ..moveTo(0, size.height / 4 * 3)
      ..lineTo(size.width, size.height / 4 * 3);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _SideBar extends StatefulWidget {
  const _SideBar();

  @override
  State<_SideBar> createState() => __SideBarState();
}

class __SideBarState extends State<_SideBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  void run() {
    if (_controller.isAnimating) return;
    if (_controller.isCompleted) {
      _controller.reverse();
    } else {
      _controller.forward();
    }
  }

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 160), value: 0);
    var controller = StateController.find<WindowFrameController>();
    controller.openSideBar = run;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
        animation: CurvedAnimation(
            parent: _controller, curve: Curves.fastEaseInToSlowEaseOut),
        builder: (context, child) {
          var value = _controller.value;
          return Stack(
            children: [
              Positioned.fill(
                  child: GestureDetector(
                onTap: run,
                child: Container(
                  width: double.infinity,
                  height: double.infinity,
                  color:
                      value == 0 ? null : Colors.black.withOpacity(0.2 * value),
                ),
              )),
              Positioned(
                left: !App.isMacOS ? (1 - _controller.value) * (-300) : null,
                right: App.isMacOS ? (_controller.value - 1) * 300 : null,
                top: 0,
                bottom: 0,
                child: Material(
                  color: Theme.of(context).colorScheme.surface,
                  surfaceTintColor: Theme.of(context).colorScheme.surfaceTint,
                  elevation: 2,
                  borderRadius: const BorderRadius.only(
                    topRight: Radius.circular(8),
                    bottomRight: Radius.circular(8),
                  ),
                  child: SizedBox(
                    width: 300,
                    height: double.infinity,
                    child: const SingleChildScrollView(
                      child: _SideBarBody(),
                    ).paddingTop(_kTitleBarHeight),
                  ),
                ),
              )
            ],
          );
        });
  }
}

class _SideBarBody extends StatelessWidget {
  const _SideBarBody();

  void toPage(Widget Function() builder) {
    var context = App.mainNavigatorKey!.currentContext!;
    MainPage.of(context).to(builder, preventDuplicate: true);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 8),
        buildItem(
            icon: Icons.person_outline,
            title: '账号管理'.tl,
            onTap: () {
              StateController.find<WindowFrameController>().openSideBar();
              showPopUpWidget(App.globalContext!, const AccountsPage());
            }),
        buildItem(
            icon: Icons.history,
            title: '历史记录'.tl,
            onTap: () {
              StateController.find<WindowFrameController>().openSideBar();
              toPage(() => const HistoryPage());
            }),
        buildItem(
            icon: Icons.download_outlined,
            title: '已下载'.tl,
            onTap: () {
              StateController.find<WindowFrameController>().openSideBar();
              toPage(() => const DownloadPage());
            }),
        buildItem(
            icon: Icons.downloading,
            title: '下载管理器'.tl,
            onTap: () {
              StateController.find<WindowFrameController>().openSideBar();
              showPopUpWidget(App.globalContext!, const DownloadingPage());
            }),
        buildItem(
            icon: Icons.image_outlined,
            title: '图片收藏'.tl,
            onTap: () {
              StateController.find<WindowFrameController>().openSideBar();
              toPage(() => const ImageFavoritesPage());
            }),
        const Divider().paddingHorizontal(8),
        buildItem(
            icon: Icons.search,
            title: '搜索'.tl,
            onTap: () {
              StateController.find<WindowFrameController>().openSideBar();
              toPage(() => PreSearchPage());
            }),
        buildItem(
            icon: Icons.settings,
            title: '设置'.tl,
            onTap: () {
              StateController.find<WindowFrameController>().openSideBar();
              SettingsPage.open();
            }),
      ],
    );
  }

  Widget buildItem(
      {required IconData icon,
      required String title,
      required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        child: Row(
          children: [
            Icon(icon, size: 20),
            const SizedBox(width: 16),
            Text(title, style: const TextStyle(fontSize: 14)),
          ],
        ),
      ),
    ).paddingHorizontal(8);
  }
}

class WindowButtons extends StatefulWidget {
  const WindowButtons({super.key});

  @override
  State<WindowButtons> createState() => _WindowButtonsState();
}

class _WindowButtonsState extends State<WindowButtons> with WindowListener {
  bool isMaximized = false;

  @override
  void initState() {
    windowManager.addListener(this);
    windowManager.isMaximized().then((value) {
      if (value) {
        setState(() {
          isMaximized = true;
        });
      }
    });
    super.initState();
  }

  @override
  void dispose() {
    windowManager.removeListener(this);
    super.dispose();
  }

  @override
  void onWindowMaximize() {
    setState(() {
      isMaximized = true;
    });
    super.onWindowMaximize();
  }

  @override
  void onWindowUnmaximize() {
    setState(() {
      isMaximized = false;
    });
    super.onWindowUnmaximize();
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final color = dark ? Colors.white : Colors.black;
    final hoverColor = dark ? Colors.white30 : Colors.black12;

    return SizedBox(
      width: 138,
      height: _kTitleBarHeight,
      child: Row(
        children: [
          WindowButton(
            icon: MinimizeIcon(color: color),
            hoverColor: hoverColor,
            onPressed: () async {
              bool isMinimized = await windowManager.isMinimized();
              if (isMinimized) {
                windowManager.restore();
              } else {
                windowManager.minimize();
              }
            },
          ),
          if (isMaximized)
            WindowButton(
              icon: RestoreIcon(
                color: color,
              ),
              hoverColor: hoverColor,
              onPressed: () {
                windowManager.unmaximize();
              },
            )
          else
            WindowButton(
              icon: MaximizeIcon(
                color: color,
              ),
              hoverColor: hoverColor,
              onPressed: () {
                windowManager.maximize();
              },
            ),
          WindowButton(
            icon: CloseIcon(
              color: color,
            ),
            hoverIcon: CloseIcon(
              color: !dark ? Colors.white : Colors.black,
            ),
            hoverColor: Colors.red,
            onPressed: () {
              if (appdata.implicitData[2] == '0') {
                showDialog(
                    context: App.navigatorKey.currentContext!,
                    builder: (context) {
                      bool isCheck = false;
                      return AlertDialog(
                        title: Text('是否退出程序？'.tl),
                        content: StatefulBuilder(builder: (context, setState) {
                          return Row(
                            children: [
                              Checkbox(
                                value: isCheck,
                                onChanged: (value) {
                                  setState(() {
                                    isCheck = value!;
                                  });
                                },
                              ),
                              Text('不再提示'.tl),
                            ],
                          );
                        }),
                        actions: [
                          TextButton(
                            onPressed: () {
                              Navigator.of(context).pop();
                            },
                            child: Text('否'.tl),
                          ),
                          TextButton(
                            onPressed: () {
                              if (isCheck) {
                                appdata.implicitData[2] = '1';
                                appdata.writeImplicitData();
                              }
                              windowManager.close();
                            },
                            child: Text('是'.tl),
                          ),
                        ],
                      );
                    });
              } else {
                windowManager.close();
              }
            },
          )
        ],
      ),
    );
  }
}

class WindowButton extends StatefulWidget {
  const WindowButton(
      {required this.icon,
      required this.onPressed,
      required this.hoverColor,
      this.hoverIcon,
      super.key});

  final Widget icon;

  final void Function() onPressed;

  final Color hoverColor;

  final Widget? hoverIcon;

  @override
  State<WindowButton> createState() => _WindowButtonState();
}

class _WindowButtonState extends State<WindowButton> {
  bool isHovering = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (event) => setState(() {
        isHovering = true;
      }),
      onExit: (event) => setState(() {
        isHovering = false;
      }),
      child: GestureDetector(
        onTap: widget.onPressed,
        child: Container(
          width: 46,
          height: double.infinity,
          decoration:
              BoxDecoration(color: isHovering ? widget.hoverColor : null),
          child: isHovering ? widget.hoverIcon ?? widget.icon : widget.icon,
        ),
      ),
    );
  }
}

/// Close
class CloseIcon extends StatelessWidget {
  final Color color;

  const CloseIcon({super.key, required this.color});

  @override
  Widget build(BuildContext context) => _AlignedPaint(_ClosePainter(color));
}

class _ClosePainter extends _IconPainter {
  _ClosePainter(super.color);

  @override
  void paint(Canvas canvas, Size size) {
    Paint p = getPaint(color, true);
    canvas.drawLine(const Offset(0, 0), Offset(size.width, size.height), p);
    canvas.drawLine(Offset(0, size.height), Offset(size.width, 0), p);
  }
}

/// Maximize
class MaximizeIcon extends StatelessWidget {
  final Color color;

  const MaximizeIcon({super.key, required this.color});

  @override
  Widget build(BuildContext context) => _AlignedPaint(_MaximizePainter(color));
}

class _MaximizePainter extends _IconPainter {
  _MaximizePainter(super.color);

  @override
  void paint(Canvas canvas, Size size) {
    Paint p = getPaint(color);
    canvas.drawRect(Rect.fromLTRB(0, 0, size.width - 1, size.height - 1), p);
  }
}

/// Restore
class RestoreIcon extends StatelessWidget {
  final Color color;

  const RestoreIcon({
    super.key,
    required this.color,
  });

  @override
  Widget build(BuildContext context) => _AlignedPaint(_RestorePainter(color));
}

class _RestorePainter extends _IconPainter {
  _RestorePainter(super.color);

  @override
  void paint(Canvas canvas, Size size) {
    Paint p = getPaint(color);
    canvas.drawRect(Rect.fromLTRB(0, 2, size.width - 2, size.height), p);
    canvas.drawLine(const Offset(2, 2), const Offset(2, 0), p);
    canvas.drawLine(const Offset(2, 0), Offset(size.width, 0), p);
    canvas.drawLine(
        Offset(size.width, 0), Offset(size.width, size.height - 2), p);
    canvas.drawLine(Offset(size.width, size.height - 2),
        Offset(size.width - 2, size.height - 2), p);
  }
}

/// Minimize
class MinimizeIcon extends StatelessWidget {
  final Color color;

  const MinimizeIcon({super.key, required this.color});

  @override
  Widget build(BuildContext context) => _AlignedPaint(_MinimizePainter(color));
}

class _MinimizePainter extends _IconPainter {
  _MinimizePainter(super.color);

  @override
  void paint(Canvas canvas, Size size) {
    Paint p = getPaint(color);
    canvas.drawLine(
        Offset(0, size.height / 2), Offset(size.width, size.height / 2), p);
  }
}

/// Helpers
abstract class _IconPainter extends CustomPainter {
  _IconPainter(this.color);

  final Color color;

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _AlignedPaint extends StatelessWidget {
  const _AlignedPaint(this.painter);

  final CustomPainter painter;

  @override
  Widget build(BuildContext context) {
    return Align(
        alignment: Alignment.center,
        child: CustomPaint(size: const Size(10, 10), painter: painter));
  }
}

Paint getPaint(Color color, [bool isAntiAlias = false]) => Paint()
  ..color = color
  ..style = PaintingStyle.stroke
  ..isAntiAlias = isAntiAlias
  ..strokeWidth = 1;

class WindowPlacement {
  final Rect rect;

  final bool isMaximized;

  const WindowPlacement(this.rect, this.isMaximized);

  Future<void> applyToWindow() async {
    await windowManager.setBounds(rect);

    if (!validate(rect)) {
      await windowManager.center();
    }

    if (isMaximized) {
      await windowManager.maximize();
    }
  }

  Future<void> writeToFile() async {
    var file = File("${App.dataPath}/window_placement");
    await file.writeAsString(jsonEncode({
      'width': rect.width,
      'height': rect.height,
      'x': rect.topLeft.dx,
      'y': rect.topLeft.dy,
      'isMaximized': isMaximized
    }));
  }

  static Future<WindowPlacement> loadFromFile() async {
    try {
      var file = File("${App.dataPath}/window_placement");
      if (!file.existsSync()) {
        return defaultPlacement;
      }
      var json = jsonDecode(await file.readAsString());
      var rect =
          Rect.fromLTWH(json['x'], json['y'], json['width'], json['height']);
      return WindowPlacement(rect, json['isMaximized']);
    } catch (e) {
      return defaultPlacement;
    }
  }

  static Future<WindowPlacement> get current async {
    var rect = await windowManager.getBounds();
    var isMaximized = await windowManager.isMaximized();
    return WindowPlacement(rect, isMaximized);
  }

  static const defaultPlacement =
      WindowPlacement(Rect.fromLTWH(10, 10, 900, 600), false);

  static WindowPlacement cache = defaultPlacement;

  static Timer? timer;

  static void loop() async {
    timer ??= Timer.periodic(const Duration(milliseconds: 100), (timer) async {
      var placement = await WindowPlacement.current;
      if (!validate(placement.rect)) {
        return;
      }
      if (placement.rect != cache.rect ||
          placement.isMaximized != cache.isMaximized) {
        cache = placement;
        await placement.writeToFile();
      }
    });
  }

  static bool validate(Rect rect) {
    return rect.topLeft.dx >= 0 && rect.topLeft.dy >= 0;
  }
}

class VirtualWindowFrame extends StatefulWidget {
  const VirtualWindowFrame({
    super.key,
    required this.child,
  });

  /// The [child] contained by the VirtualWindowFrame.
  final Widget child;

  @override
  State<StatefulWidget> createState() => _VirtualWindowFrameState();
}

class _VirtualWindowFrameState extends State<VirtualWindowFrame>
    with WindowListener {
  bool _isFocused = true;
  bool _isMaximized = false;
  bool _isFullScreen = false;

  @override
  void initState() {
    windowManager.addListener(this);
    super.initState();
  }

  @override
  void dispose() {
    windowManager.removeListener(this);
    super.dispose();
  }

  Widget _buildVirtualWindowFrame(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.transparent,
        border: Border.all(
          color: Theme.of(context).dividerColor,
          width: (_isMaximized || _isFullScreen) ? 0 : 1,
        ),
        boxShadow: <BoxShadow>[
          if (!_isMaximized && !_isFullScreen)
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              offset: Offset(0.0, _isFocused ? 4 : 2),
              blurRadius: 6,
            )],
      ),
      child: widget.child,
    );
  }

  @override
  Widget build(BuildContext context) {
    return DragToResizeArea(
        enableResizeEdges: (_isMaximized || _isFullScreen) ? [] : null,
        child: _buildVirtualWindowFrame(context),
      );
  }

  @override
  void onWindowFocus() {
    setState(() {
      _isFocused = true;
    });
  }

  @override
  void onWindowBlur() {
    setState(() {
      _isFocused = false;
    });
  }

  @override
  void onWindowMaximize() {
    setState(() {
      _isMaximized = true;
    });
  }

  @override
  void onWindowUnmaximize() {
    setState(() {
      _isMaximized = false;
    });
  }

  @override
  void onWindowEnterFullScreen() {
    setState(() {
      _isFullScreen = true;
    });
  }

  @override
  void onWindowLeaveFullScreen() {
    setState(() {
      _isFullScreen = false;
    });
  }
}

// ignore: non_constant_identifier_names
TransitionBuilder VirtualWindowFrameInit() {
  return (_, Widget? child) {
    return VirtualWindowFrame(
      child: child!,
    );
  };
}
