import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// WhatsApp brand green.
const whatsAppBrandColor = Color(0xFF25D366);

/// WhatsApp dark teal (call actions).
const whatsAppTealColor = Color(0xFF128C7E);

/// Chat bubble — WhatsApp message.
class WhatsAppMessageIcon extends StatelessWidget {
  const WhatsAppMessageIcon({
    this.size = 24,
    super.key,
  });

  static const assetPath = 'assets/images/whatsapp_message.svg';

  final double size;

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      assetPath,
      width: size,
      height: size,
      colorFilter: const ColorFilter.mode(
        whatsAppBrandColor,
        BlendMode.srcIn,
      ),
    );
  }
}

/// Outbound phone — WhatsApp call (shape + color differ from message bubble).
class WhatsAppCallIcon extends StatelessWidget {
  const WhatsAppCallIcon({
    this.size = 24,
    super.key,
  });

  static const assetPath = 'assets/images/whatsapp_call.svg';

  final double size;

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      assetPath,
      width: size,
      height: size,
      colorFilter: const ColorFilter.mode(
        whatsAppTealColor,
        BlendMode.srcIn,
      ),
    );
  }
}

/// Legacy alias — profile form prefix still uses full brand logo.
class WhatsAppIcon extends StatelessWidget {
  const WhatsAppIcon({
    this.size = 24,
    super.key,
  });

  static const assetPath = 'assets/images/whatsapp.svg';

  final double size;

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      assetPath,
      width: size,
      height: size,
    );
  }
}
