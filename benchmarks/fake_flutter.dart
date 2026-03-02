// Minimal stand-in types to make benchmark widgets analyzable in a pure
// Dart package without depending on the real Flutter SDK. These are just
// structural placeholders so the agent can scan realistic-looking code.

class BuildContext {}

class Widget {
  const Widget();
}

class StatelessWidget extends Widget {
  const StatelessWidget();
}

class StatefulWidget extends Widget {
  const StatefulWidget();
}

class State<T extends StatefulWidget> {
  void initState() {}
  void dispose() {}
  Widget build(BuildContext context) => Widget();
  void setState(void Function() fn) => fn();
}

class Column extends Widget {
  final List<Widget> children;
  const Column({required this.children});
}

class SizedBox extends Widget {
  const SizedBox.shrink();
}

