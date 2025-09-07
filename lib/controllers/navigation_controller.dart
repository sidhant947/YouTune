import 'package:get/get.dart';

class NavigationController extends GetxController {
  // A reactive variable to track the visibility of the search screen.
  var isSearchVisible = false.obs;

  void showSearch() {
    isSearchVisible.value = true;
  }

  void showHome() {
    isSearchVisible.value = false;
  }
}
