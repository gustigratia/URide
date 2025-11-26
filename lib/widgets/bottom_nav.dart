import 'package:flutter/material.dart';

class CustomBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int>? onTap;

  const CustomBottomNav({
    super.key,
    this.currentIndex = 0,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      backgroundColor: Colors.white,
      currentIndex: currentIndex,
      onTap: onTap,
      selectedItemColor: Colors.orange,
      unselectedItemColor: Colors.grey,
      type: BottomNavigationBarType.fixed,
      showSelectedLabels: false,
      showUnselectedLabels: false,
      items: [
        BottomNavigationBarItem(
          icon: Image.asset(
            "assets/icons/home.png",
            width: 26,
            height: 26,
          ),
          activeIcon: SizedBox(
            width: 62,
            height: 62,
            child: Image.asset(
              "assets/icons/home_active.png",
            ),
          ),
          label: "",
        ),

        BottomNavigationBarItem(
          icon: Image.asset(
            "assets/icons/vehicle.png",
            width: 24,
            height: 24,
          ),
          activeIcon: SizedBox(
            width: 62,
            height: 62,
            child: Image.asset(
              "assets/icons/vehicle_active.png",
            ),
          ),
          label: "",
        ),

        BottomNavigationBarItem(
          icon: Image.asset(
            "assets/icons/workshop.png",
            width: 22,
            height: 22,
          ),
          activeIcon: SizedBox(
            width: 62,
            height: 62,
            child: Image.asset(
              "assets/icons/workshop_active.png",
            ),
          ),
          label: "",
        ),

        BottomNavigationBarItem(
          icon: Image.asset(
            "assets/icons/history.png",
            width: 26,
            height: 26,
          ),
          activeIcon: SizedBox(
            width: 62,
            height: 62,
            child: Image.asset(
              "assets/icons/history_active.png",
            ),
          ),
          label: "",
        ),
      ],
    );
  }
}
