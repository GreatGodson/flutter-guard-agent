import 'fake_flutter.dart';

class BadSetStateAfterAwait extends State<StatefulWidget> {
  Future<void> load() async {
    await Future<void>.delayed(const Duration(milliseconds: 10));
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }
}
