/*
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class MenuListItem extends StatelessWidget {
  final String title;
  final IconData icon;
  final VoidCallback onTap;

  const MenuListItem({
    super.key,
    required this.title,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(15),
      elevation: 2,
      shadowColor: Colors.grey.withOpacity(0.1),
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          onTap();
        },
        borderRadius: BorderRadius.circular(15),
        splashColor: const Color(0xFF6C63FF).withOpacity(0.1),
        highlightColor: const Color(0xFF6C63FF).withOpacity(0.05),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF6C63FF).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: const Color(0xFF6C63FF), size: 28),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ),
              const Icon(Icons.arrow_forward_ios_rounded, color: Colors.grey, size: 18),
            ],
          ),
        ),
      ),
    );
  }
}
*/
 /*
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class MenuListItem extends StatefulWidget {
  final String title;
  final IconData icon;
  final VoidCallback onTap;

  const MenuListItem({
  super.key,
  required this.title,
  required this.icon,
  required this.onTap,
});

// Enhanced icon builder with custom illustrations
Widget _buildEnhancedIcon(IconData icon, bool isPressed, bool isSmallScreen) {
  final iconColor = isPressed ? Colors.white : const Color(0xFF6C63FF);
  final iconSize = isSmallScreen ? 24.0 : 28.0;

  // Custom illustrations based on icon type
  if (icon == Icons.add_card_outlined) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Background card shape
        Container(
          width: iconSize + 8,
          height: iconSize + 2,
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.2),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: iconColor.withOpacity(0.3), width: 1),
          ),
        ),
        // Plus icon
        Icon(
          Icons.add_rounded,
          color: iconColor,
          size: iconSize * 0.7,
        ),
        // Decorative corner
        Positioned(
          top: -2,
          right: -2,
          child: Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.4),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ),
      ],
    );
  } else if (icon == Icons.list_alt_rounded) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Document background
        Container(
          width: iconSize + 4,
          height: iconSize + 6,
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(3),
            border: Border.all(color: iconColor.withOpacity(0.3), width: 1),
          ),
        ),
        // List lines
        Column(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (index) => Container(
            width: iconSize * 0.6,
            height: 2,
            margin: const EdgeInsets.symmetric(vertical: 1.5),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.6),
              borderRadius: BorderRadius.circular(1),
            ),
          )),
        ),
        // Checkmark
        Positioned(
          top: 2,
          right: 2,
          child: Icon(
            Icons.check_circle,
            color: iconColor.withOpacity(0.5),
            size: iconSize * 0.3,
          ),
        ),
      ],
    );
  }

  // Default enhanced icon
  return Stack(
    alignment: Alignment.center,
    children: [
      // Background circle
      Container(
        width: iconSize + 6,
        height: iconSize + 6,
        decoration: BoxDecoration(
          color: iconColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular((iconSize + 6) / 2),
        ),
      ),
      // Main icon
      Icon(
        icon,
        color: iconColor,
        size: iconSize,
      ),
    ],
  );
}

@override
State<MenuListItem> createState() => _MenuListItemState();
}

class _MenuListItemState extends State<MenuListItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotationAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _rotationAnimation = Tween<double>(
      begin: 0.0,
      end: 0.1,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    setState(() {
      _isPressed = true;
    });
    _animationController.forward();
  }

  void _handleTapUp(TapUpDetails details) {
    setState(() {
      _isPressed = false;
    });
    _animationController.reverse();
  }

  void _handleTapCancel() {
    setState(() {
      _isPressed = false;
    });
    _animationController.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 360;

    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 4),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                colors: [
                  Colors.white,
                  Colors.grey.shade50,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: _isPressed
                      ? const Color(0xFF6C63FF).withOpacity(0.2)
                      : Colors.grey.withOpacity(0.1),
                  spreadRadius: _isPressed ? 2 : 0,
                  blurRadius: _isPressed ? 15 : 10,
                  offset: _isPressed ? const Offset(0, 2) : const Offset(0, 5),
                ),
              ],
              border: Border.all(
                color: _isPressed
                    ? const Color(0xFF6C63FF).withOpacity(0.3)
                    : Colors.transparent,
                width: 1.5,
              ),
            ),
            child: Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(20),
              child: InkWell(
                onTap: () {
                  HapticFeedback.lightImpact();
                  widget.onTap();
                },
                onTapDown: _handleTapDown,
                onTapUp: _handleTapUp,
                onTapCancel: _handleTapCancel,
                borderRadius: BorderRadius.circular(20),
                splashColor: const Color(0xFF6C63FF).withOpacity(0.1),
                highlightColor: const Color(0xFF6C63FF).withOpacity(0.05),
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: isSmallScreen ? 16 : 20,
                    vertical: isSmallScreen ? 16 : 20,
                  ),
                  child: Row(
                    children: [
                      // Icon container with animation
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: EdgeInsets.all(isSmallScreen ? 8 : 10),
                        decoration: BoxDecoration(
                          gradient: _isPressed
                              ? LinearGradient(
                            colors: [
                              const Color(0xFF6C63FF),
                              const Color(0xFF5A52D5),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          )
                              : LinearGradient(
                            colors: [
                              const Color(0xFF6C63FF).withOpacity(0.1),
                              const Color(0xFF6C63FF).withOpacity(0.05),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(15),
                          boxShadow: _isPressed
                              ? [
                            BoxShadow(
                              color: const Color(0xFF6C63FF).withOpacity(0.3),
                              spreadRadius: 1,
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ]
                              : [],
                        ),
                        child: Transform.rotate(
                          angle: _rotationAnimation.value,
                          child: Icon(
                            widget.icon,
                            color: _isPressed ? Colors.white : const Color(0xFF6C63FF),
                            size: isSmallScreen ? 24 : 28,
                          ),
                        ),
                      ),

                      SizedBox(width: isSmallScreen ? 16 : 20),

                      // Title
                      Expanded(
                        child: AnimatedDefaultTextStyle(
                          duration: const Duration(milliseconds: 200),
                          style: TextStyle(
                            fontSize: isSmallScreen ? 15 : 17,
                            fontWeight: _isPressed ? FontWeight.w700 : FontWeight.w600,
                            color: _isPressed ? const Color(0xFF6C63FF) : Colors.black87,
                          ),
                          child: Text(
                            widget.title,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),

                      // Arrow icon with animation
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        transform: Matrix4.translationValues(
                          _isPressed ? 4 : 0,
                          0,
                          0,
                        ),
                        child: Icon(
                          Icons.arrow_forward_ios_rounded,
                          color: _isPressed ? const Color(0xFF6C63FF) : Colors.grey,
                          size: isSmallScreen ? 16 : 18,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

  */



















import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class MenuListItem extends StatefulWidget {
  final String title;
  final String subtitle; // إضافة وصف إضافي
  final IconData icon;
  final VoidCallback onTap;
  final int index; // لإضافة تأخير في الأنيميشن

  const MenuListItem({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
    required this.index,
  });

  @override
  State<MenuListItem> createState() => _MenuListItemState();
}

class _MenuListItemState extends State<MenuListItem> with TickerProviderStateMixin {
  late AnimationController _pressController;
  late AnimationController _entryController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _pressController = AnimationController(vsync: this, duration: const Duration(milliseconds: 150));
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.97).animate(
      CurvedAnimation(parent: _pressController, curve: Curves.easeInOut),
    );

    _entryController = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    // تأخير الأنيميشن بناءً على الـ index
    final start = (widget.index * 100) / 1000;
    _slideAnimation = Tween<double>(begin: 50.0, end: 0.0).animate(
      CurvedAnimation(parent: _entryController, curve: Interval(start, 1.0, curve: Curves.easeOutCubic)),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _entryController, curve: Interval(start, 1.0, curve: Curves.easeOut)),
    );
    _entryController.forward();
  }

  @override
  void dispose() {
    _pressController.dispose();
    _entryController.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    _pressController.forward();
  }

  void _onTapUp(TapUpDetails details) {
    _pressController.reverse();
    widget.onTap();
  }

  void _onTapCancel() {
    _pressController.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _entryController,
      builder: (context, child) {
        return FadeTransition(
          opacity: _fadeAnimation,
          child: Transform.translate(
            offset: Offset(0, _slideAnimation.value),
            child: child,
          ),
        );
      },
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: GestureDetector(
          onTapDown: _onTapDown,
          onTapUp: _onTapUp,
          onTapCancel: _onTapCancel,
          child: Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.08),
                  blurRadius: 20,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF6C63FF), Color(0xFF8B5CF6)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF6C63FF).withOpacity(0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      )
                    ],
                  ),
                  child: Icon(widget.icon, color: Colors.white, size: 28),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.title,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF333333),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.subtitle,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.arrow_forward_ios_rounded, color: Colors.grey, size: 18),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}