import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

import '../models/quote.dart';
import '../theme.dart';

/// Screens at least this wide get the full desktop website; narrower ones
/// get the phone layout.
const desktopBreakpoint = 960.0;

/// Content width of the desktop website.
const desktopWidth = 1160.0;

bool isDesktop(BuildContext context) =>
    MediaQuery.sizeOf(context).width >= desktopBreakpoint;

/// Top bar used by the tabs: an optional button on each side and a serif
/// title, with an optional spaced subtitle underneath.
class SosHeader extends StatelessWidget {
  const SosHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.leading,
    this.trailing,
  });

  final String title;
  final String? subtitle;
  final Widget? leading;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final c = SosColors.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 4),
      child: Column(
        children: [
          SizedBox(
            height: 52,
            child: Row(
              children: [
                SizedBox(width: 52, child: leading),
                Expanded(
                  child: Semantics(
                    header: true,
                    child: Text(
                      title,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: serif(fontSize: 30, color: c.ink, height: 1.1),
                    ),
                  ),
                ),
                SizedBox(width: 52, child: trailing),
              ],
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 2),
            Text(subtitle!.toUpperCase(), style: eyebrow(c.muted, fontSize: 10)),
          ],
        ],
      ),
    );
  }
}

/// The short terracotta rule used between title and text.
class AccentRule extends StatelessWidget {
  const AccentRule({super.key, this.width = 30});

  final double width;

  @override
  Widget build(BuildContext context) => Container(
        width: width,
        height: 1.6,
        color: SosColors.of(context).accent,
      );
}

/// A raised paper card.
class PaperCard extends StatelessWidget {
  const PaperCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.color,
    this.onTap,
    this.radius = 22,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color? color;
  final VoidCallback? onTap;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final c = SosColors.of(context);
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(radius),
      side: BorderSide(color: c.line.withValues(alpha: 0.6)),
    );
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        boxShadow: [
          BoxShadow(color: c.shadow, blurRadius: 28, offset: const Offset(0, 10)),
        ],
      ),
      child: Material(
        color: color ?? c.card,
        shape: shape,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}

/// Round avatar with the user's initial, or a person icon without a name.
class Avatar extends StatelessWidget {
  const Avatar({super.key, required this.name, this.size = 40});

  final String name;
  final double size;

  @override
  Widget build(BuildContext context) {
    final c = SosColors.of(context);
    final initial = name.trim().isEmpty ? null : name.trim().characters.first;
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(shape: BoxShape.circle, color: c.blush),
      child: initial == null
          ? Icon(Icons.person_rounded, size: size * 0.6, color: c.ink)
          : Text(initial.toUpperCase(),
              style: serif(fontSize: size * 0.48, color: c.accent, height: 1)),
    );
  }
}

/// Outlined pill button with an icon, as used for Save and Share.
class PillButton extends StatelessWidget {
  const PillButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onPressed,
    this.iconColor,
  });

  final Widget icon;
  final String label;
  final VoidCallback? onPressed;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) => OutlinedButton.icon(
        onPressed: onPressed,
        icon: IconTheme.merge(
          data: IconThemeData(size: 22, color: iconColor),
          child: icon,
        ),
        label: Text(label),
      );
}

void showSnack(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));
}

/// Opens the share sheet for [quote]; copies it instead where sharing is not
/// available. [origin] anchors the iPad popover.
Future<void> shareQuote(BuildContext origin, Quote quote) async {
  final box = origin.findRenderObject() as RenderBox?;
  try {
    await SharePlus.instance.share(ShareParams(
      text: quote.shareText,
      subject: 'From ${quote.source.withArticle}',
      sharePositionOrigin:
          box == null ? null : box.localToGlobal(Offset.zero) & box.size,
    ));
  } catch (_) {
    await Clipboard.setData(ClipboardData(text: quote.shareText));
    if (origin.mounted) showSnack(origin, 'Copied to clipboard');
  }
}

/// "Today, 7:00 AM", "Yesterday, 7:00 AM" or "Mon 12 Oct, 7:00 AM".
String friendlyDateTime(BuildContext context, DateTime at) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final day = DateTime(at.year, at.month, at.day);
  final time = TimeOfDay.fromDateTime(at).format(context);
  final diff = today.difference(day).inDays;
  if (diff == 0) return 'Today, $time';
  if (diff == 1) return 'Yesterday, $time';
  const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  const months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];
  final year = at.year == now.year ? '' : ' ${at.year}';
  return '${weekdays[at.weekday - 1]} ${at.day} ${months[at.month - 1]}$year, $time';
}
