import 'package:flutter/material.dart';
import 'dart:async';

class Alert {
  static final int lengthShort = 1;
  static final int lengthLong = 3;
  static final int bottom = 0;
  static final int center = 1;
  static final int top = 2;

  static void show(String msg, BuildContext context,
      {int duration = 1,
      int gravity = 0,
      Color backgroundColor = const Color(0xAA000000),
      textStyle = const TextStyle(fontSize: 15, color: Colors.white),
      double backgroundRadius = 20,
      bool rootNavigator = false,
      Border? border}) {
    ToastView.dismiss();
    ToastView.createView(msg, context, duration, gravity, backgroundColor,
        textStyle, backgroundRadius, border, rootNavigator);
  }
}

class ToastView {
  static final ToastView _singleton = new ToastView._internal();

  factory ToastView() {
    return _singleton;
  }

  ToastView._internal();

  static OverlayState? overlayState;
  static OverlayEntry? _overlayEntry;
  static bool _isVisible = false;

  static void createView(
      String msg,
      BuildContext context,
      int? duration,
      int gravity,
      Color background,
      TextStyle textStyle,
      double backgroundRadius,
      Border? border,
      bool? rootNavigator) async {
    overlayState = Overlay.of(context, rootOverlay: rootNavigator ?? false);

    _overlayEntry = new OverlayEntry(
      builder: (BuildContext context) => ToastWidget(
          duration: Duration(
              seconds: duration == null ? Alert.lengthShort : duration),
          widget: Container(
            width: MediaQuery.of(context).size.width,
            child: Container(
                alignment: Alignment.center,
                width: MediaQuery.of(context).size.width,
                child: Container(
                  decoration: BoxDecoration(
                    color: background,
                    borderRadius: BorderRadius.circular(backgroundRadius),
                    border: border,
                  ),
                  margin: EdgeInsets.symmetric(horizontal: 20),
                  padding: EdgeInsets.fromLTRB(16, 10, 16, 10),
                  child: Text(msg, softWrap: true, style: textStyle),
                )),
          ),
          gravity: gravity),
    );
    _isVisible = true;
    overlayState!.insert(_overlayEntry!);
    await new Future.delayed(
        Duration(seconds: duration == null ? Alert.lengthShort : duration));
    dismiss();
  }

  static dismiss() async {
    if (!_isVisible) {
      return;
    }
    _isVisible = false;
    _overlayEntry?.remove();
  }
}

class ToastWidget extends StatefulWidget {
  ToastWidget({
    Key? key,
    required this.widget,
    required this.gravity,
    required this.duration,
  }) : super(key: key);

  final Widget widget;
  final int gravity;
  final Duration duration;

  @override
  _ToastWidgetState createState() => _ToastWidgetState();
}

class _ToastWidgetState extends State<ToastWidget> {
  double opacity = 0;
  bool timerset = false;

  @override
  Widget build(BuildContext context) {
    if (opacity == 0) {
      Timer(
          Duration(
            milliseconds: 0,
          ), () {
        if (mounted & !timerset)
          setState(() {
            opacity = 1;
            timerset = true;
          });
      });
      Timer(Duration(milliseconds: widget.duration.inMilliseconds - 200), () {
        if (mounted)
          setState(() {
            opacity = 0;
          });
      });
    }
    return Positioned(
      top: widget.gravity == 2
          ? MediaQuery.of(context).viewInsets.top + 50
          : null,
      bottom: widget.gravity == 0
          ? MediaQuery.of(context).viewInsets.bottom + 50
          : null,
      child: AnimatedOpacity(
        opacity: opacity,
        curve: Curves.linear,
        duration: Duration(milliseconds: 200),
        child: Material(
          color: Colors.transparent,
          child: widget.widget,
        ),
      ),
    );
  }
}
