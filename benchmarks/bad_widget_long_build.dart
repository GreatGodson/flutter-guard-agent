import 'fake_flutter.dart';

class BadLongBuild extends StatelessWidget {
  const BadLongBuild();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Intentionally long, expanded list of children to trigger the
        // long_build_method rule by increasing the line count.
        const SizedBox.shrink(),
        const SizedBox.shrink(),
        const SizedBox.shrink(),
        const SizedBox.shrink(),
        const SizedBox.shrink(),
        const SizedBox.shrink(),
        const SizedBox.shrink(),
        const SizedBox.shrink(),
        const SizedBox.shrink(),
        const SizedBox.shrink(),
        const SizedBox.shrink(),
        const SizedBox.shrink(),
        const SizedBox.shrink(),
        const SizedBox.shrink(),
        const SizedBox.shrink(),
        const SizedBox.shrink(),
        const SizedBox.shrink(),
        const SizedBox.shrink(),
        const SizedBox.shrink(),
        const SizedBox.shrink(),
        const SizedBox.shrink(),
        const SizedBox.shrink(),
        const SizedBox.shrink(),
        const SizedBox.shrink(),
        const SizedBox.shrink(),
        const SizedBox.shrink(),
        const SizedBox.shrink(),
        const SizedBox.shrink(),
        const SizedBox.shrink(),
        const SizedBox.shrink(),
        const SizedBox.shrink(),
        const SizedBox.shrink(),
        const SizedBox.shrink(),
        const SizedBox.shrink(),
        const SizedBox.shrink(),
        const SizedBox.shrink(),
        const SizedBox.shrink(),
        const SizedBox.shrink(),
        const SizedBox.shrink(),
        const SizedBox.shrink(),
        const SizedBox.shrink(),
        const SizedBox.shrink(),
        const SizedBox.shrink(),
        const SizedBox.shrink(),
        const SizedBox.shrink(),
        const SizedBox.shrink(),
        const SizedBox.shrink(),
        const SizedBox.shrink(),
        const SizedBox.shrink(),
        const SizedBox.shrink(),
        const SizedBox.shrink(),
        const SizedBox.shrink(),
        const SizedBox.shrink(),
        const SizedBox.shrink(),
        const SizedBox.shrink(),
        const SizedBox.shrink(),
        const SizedBox.shrink(),
        const SizedBox.shrink(),
      ],
    );
  }
}
