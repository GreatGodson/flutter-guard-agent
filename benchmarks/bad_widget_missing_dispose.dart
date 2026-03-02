import 'fake_flutter.dart';

class BadWidgetMissingDispose extends StatefulWidget {
  const BadWidgetMissingDispose();

  @override
  State<BadWidgetMissingDispose> createState() => _BadWidgetMissingDisposeState();
}

class _BadWidgetMissingDisposeState extends State<BadWidgetMissingDispose> {
  @override
  void initState() {
    super.initState();
    // Imagine we start a timer or subscription here and forget to cancel it.
  }

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }
}
