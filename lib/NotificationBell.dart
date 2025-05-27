import 'package:flutter/material.dart';

class NotificationBell extends StatelessWidget {
  final int notificationCount;

  const NotificationBell({Key? key, required this.notificationCount}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 50,
      height: 50,
      
      child: Stack(
        clipBehavior: Clip.none, // Allow badge to overflow
        children: [
          Icon(
            Icons.notifications,
            size: 48,
            color: Colors.deepOrange, // Orange bell
          ),
          if (notificationCount > 0)
            Positioned(
              left: 25,
              bottom: 3,
              child: Container(
                height: 25,
                width: 25,
                alignment: Alignment.center,
                child: Text(
                  '$notificationCount',
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.orange,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                padding: EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                
              ),
            ),
        ],
      ),
    );
  }
}
