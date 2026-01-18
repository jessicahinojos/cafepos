import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Custom App Bar for Restaurant POS Application
/// Implements clean professional appearance with contextual actions
/// Supports role-based visibility and offline status indicators
class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final Widget? leading;
  final bool showBackButton;
  final VoidCallback? onBackPressed;
  final bool centerTitle;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final double elevation;
  final PreferredSizeWidget? bottom;
  final bool showOfflineIndicator;
  final bool isOffline;

  const CustomAppBar({
    super.key,
    required this.title,
    this.actions,
    this.leading,
    this.showBackButton = false,
    this.onBackPressed,
    this.centerTitle = false,
    this.backgroundColor,
    this.foregroundColor,
    this.elevation = 0,
    this.bottom,
    this.showOfflineIndicator = true,
    this.isOffline = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final effectiveBackgroundColor = backgroundColor ?? colorScheme.surface;
    final effectiveForegroundColor =
        foregroundColor ??
        (theme.brightness == Brightness.light
            ? const Color(0xFF0F172A)
            : const Color(0xFFF8FAFC));

    return AppBar(
      title: Column(
        crossAxisAlignment: centerTitle
            ? CrossAxisAlignment.center
            : CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            title,
            style: theme.textTheme.titleLarge?.copyWith(
              color: effectiveForegroundColor,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.15,
            ),
          ),
          if (showOfflineIndicator && isOffline)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.cloud_off,
                    size: 12,
                    color: theme.brightness == Brightness.light
                        ? const Color(0xFFD97706)
                        : const Color(0xFFF59E0B),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Offline Mode',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.brightness == Brightness.light
                          ? const Color(0xFFD97706)
                          : const Color(0xFFF59E0B),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
      centerTitle: centerTitle,
      backgroundColor: effectiveBackgroundColor,
      foregroundColor: effectiveForegroundColor,
      elevation: elevation,
      leading:
          leading ??
          (showBackButton
              ? IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    if (onBackPressed != null) {
                      onBackPressed!();
                    } else {
                      Navigator.of(context).pop();
                    }
                  },
                  tooltip: 'Back',
                  iconSize: 24,
                )
              : null),
      actions: actions?.map((action) {
        if (action is IconButton) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: action,
          );
        }
        return action;
      }).toList(),
      bottom: bottom,
      systemOverlayStyle: theme.brightness == Brightness.light
          ? SystemUiOverlayStyle.dark
          : SystemUiOverlayStyle.light,
    );
  }

  @override
  Size get preferredSize =>
      Size.fromHeight(kToolbarHeight + (bottom?.preferredSize.height ?? 0));
}

/// Custom App Bar with Search functionality
/// Provides integrated search field for product and customer lookup
class CustomSearchAppBar extends StatefulWidget implements PreferredSizeWidget {
  final String title;
  final String searchHint;
  final ValueChanged<String>? onSearchChanged;
  final VoidCallback? onSearchSubmitted;
  final TextEditingController? searchController;
  final List<Widget>? actions;
  final bool showBackButton;
  final VoidCallback? onBackPressed;

  const CustomSearchAppBar({
    super.key,
    required this.title,
    this.searchHint = 'Search...',
    this.onSearchChanged,
    this.onSearchSubmitted,
    this.searchController,
    this.actions,
    this.showBackButton = false,
    this.onBackPressed,
  });

  @override
  State<CustomSearchAppBar> createState() => _CustomSearchAppBarState();

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight + 60);
}

class _CustomSearchAppBarState extends State<CustomSearchAppBar> {
  late TextEditingController _controller;
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _controller = widget.searchController ?? TextEditingController();
  }

  @override
  void dispose() {
    if (widget.searchController == null) {
      _controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return AppBar(
      title: Text(
        widget.title,
        style: theme.textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w600,
          letterSpacing: 0.15,
        ),
      ),
      backgroundColor: colorScheme.surface,
      elevation: 0,
      leading: widget.showBackButton
          ? IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () {
                HapticFeedback.lightImpact();
                if (widget.onBackPressed != null) {
                  widget.onBackPressed!();
                } else {
                  Navigator.of(context).pop();
                }
              },
              tooltip: 'Back',
            )
          : null,
      actions: widget.actions,
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(60),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: TextField(
            controller: _controller,
            onChanged: (value) {
              setState(() {
                _isSearching = value.isNotEmpty;
              });
              widget.onSearchChanged?.call(value);
            },
            onSubmitted: (_) {
              HapticFeedback.lightImpact();
              widget.onSearchSubmitted?.call();
            },
            decoration: InputDecoration(
              hintText: widget.searchHint,
              prefixIcon: Icon(
                Icons.search,
                color: theme.brightness == Brightness.light
                    ? const Color(0xFF64748B)
                    : const Color(0xFF94A3B8),
              ),
              suffixIcon: _isSearching
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        HapticFeedback.lightImpact();
                        _controller.clear();
                        setState(() {
                          _isSearching = false;
                        });
                        widget.onSearchChanged?.call('');
                      },
                      tooltip: 'Clear search',
                    )
                  : null,
              filled: true,
              fillColor: theme.brightness == Brightness.light
                  ? const Color(0xFFF8FAFC)
                  : const Color(0xFF1E293B),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: theme.brightness == Brightness.light
                      ? const Color(0xFFE2E8F0)
                      : const Color(0xFF334155),
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: theme.brightness == Brightness.light
                      ? const Color(0xFFE2E8F0)
                      : const Color(0xFF334155),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: colorScheme.primary, width: 2),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
