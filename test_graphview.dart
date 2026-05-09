import 'package:graphview/graphview.dart';
void main() {
  var config = BuchheimWalkerConfiguration();
  config.orientation = BuchheimWalkerConfiguration.ORIENTATION_TOP_BOTTOM;
  config.siblingSeparation = 100;
  config.levelSeparation = 150;
  config.subtreeSeparation = 150;
  var renderer = ArrowEdgeRenderer();
  var algo = BuchheimWalkerAlgorithm(config, renderer);
}
