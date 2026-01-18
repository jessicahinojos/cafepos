import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../widgets/custom_icon_widget.dart';

/// PIN Pad Widget for quick staff authentication
/// Implements 3x4 numeric keypad with haptic feedback
/// Displays secure PIN dots with progress indication
class PinPadWidget extends StatefulWidget {
  final Function(String) onPinComplete;
  final bool isLoading;

  const PinPadWidget({
    super.key,
    required this.onPinComplete,
    this.isLoading = false,
  });

  @override
  State<PinPadWidget> createState() => _PinPadWidgetState();
}

class _PinPadWidgetState extends State<PinPadWidget> {
  String _pin = '';
  static const int _pinLength = 4;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        _buildPinDots(theme),
        SizedBox(height: 4.h),
        _buildNumericKeypad(theme),
        SizedBox(height: 2.h),
        _buildForgotPin(theme),
      ],
    );
  }

  Widget _buildPinDots(ThemeData theme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(_pinLength, (index) {
        final isFilled = index < _pin.length;
        return Container(
          margin: EdgeInsets.symmetric(horizontal: 2.w),
          width: 4.w,
          height: 4.w,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isFilled
                ? theme.colorScheme.primary
                : theme.colorScheme.outline,
          ),
        );
      }),
    );
  }

  Widget _buildNumericKeypad(ThemeData theme) {
    final numbers = [
      '1',
      '2',
      '3',
      '4',
      '5',
      '6',
      '7',
      '8',
      '9',
      '',
      '0',
      'backspace',
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 1.2,
        crossAxisSpacing: 2.w,
        mainAxisSpacing: 2.h,
      ),
      itemCount: numbers.length,
      itemBuilder: (context, index) {
        final value = numbers[index];
        if (value.isEmpty) return const SizedBox.shrink();

        return _buildKeypadButton(value, theme);
      },
    );
  }

  Widget _buildKeypadButton(String value, ThemeData theme) {
    final isBackspace = value == 'backspace';
    final isDisabled = widget.isLoading;

    return GestureDetector(
      onTap: isDisabled
          ? null
          : () {
              HapticFeedback.lightImpact();
              _handleKeypadInput(value);
            },
      child: Container(
        decoration: BoxDecoration(
          color: isBackspace
              ? theme.colorScheme.surface
              : theme.colorScheme.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isBackspace
                ? theme.colorScheme.outline
                : theme.colorScheme.primary.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Center(
          child: isBackspace
              ? CustomIconWidget(
                  iconName: 'backspace',
                  size: 24,
                  color: theme.colorScheme.onSurfaceVariant,
                )
              : Text(
                  value,
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.primary,
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildForgotPin(ThemeData theme) {
    return TextButton(
      onPressed: widget.isLoading
          ? null
          : () {
              HapticFeedback.lightImpact();
              _showForgotPinDialog();
            },
      child: Text(
        '¿Olvidó su PIN?',
        style: theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.primary,
        ),
      ),
    );
  }

  void _handleKeypadInput(String value) {
    if (value == 'backspace') {
      if (_pin.isNotEmpty) {
        setState(() {
          _pin = _pin.substring(0, _pin.length - 1);
        });
      }
    } else {
      if (_pin.length < _pinLength) {
        setState(() {
          _pin += value;
        });

        if (_pin.length == _pinLength) {
          widget.onPinComplete(_pin);
        }
      }
    }
  }

  void _showForgotPinDialog() {
    showDialog(
      context: context,
      builder: (context) {
        final theme = Theme.of(context);
        return AlertDialog(
          title: Text('Recuperar PIN', style: theme.textTheme.titleLarge),
          content: Text(
            'Contacte al administrador del sistema para recuperar su PIN de acceso.',
            style: theme.textTheme.bodyMedium,
          ),
          actions: [
            TextButton(
              onPressed: () {
                HapticFeedback.lightImpact();
                Navigator.of(context).pop();
              },
              child: Text(
                'Entendido',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: theme.colorScheme.primary,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
