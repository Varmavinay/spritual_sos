import 'package:flutter/material.dart';

import '../app_scope.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/reminder_sheet.dart';

/// The user's name, a few numbers and settings.
class ProfileTab extends StatefulWidget {
  const ProfileTab({super.key, required this.onOpenSaved, required this.onOpenReceived});

  final VoidCallback onOpenSaved;
  final VoidCallback onOpenReceived;

  @override
  State<ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<ProfileTab> {
  final _nameController = TextEditingController();
  final _nameFocus = FocusNode();
  bool _editing = false;

  void _startEditing() {
    _nameController.text = AppScope.of(context).library.userName;
    setState(() => _editing = true);
    _nameFocus.requestFocus();
  }

  void _finishEditing() {
    if (!_editing) return;
    AppScope.of(context).library.setUserName(_nameController.text);
    setState(() => _editing = false);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _nameFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scope = AppScope.of(context);
    final library = scope.library;
    final c = SosColors.of(context);

    return ListenableBuilder(
      listenable: Listenable.merge([library, scope.notifications]),
      builder: (context, _) {
        final name = library.userName;
        final identity = [
          Center(child: Avatar(name: _editing ? _nameController.text : name, size: 96)),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: _editing ? _nameField(c) : _nameLabel(c, name),
            ),
          ),
          const SizedBox(height: 28),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                _Stat(
                  value: library.saved.length,
                  label: 'Saved',
                  onTap: widget.onOpenSaved,
                ),
                const SizedBox(width: 12),
                _Stat(
                  value: library.history.length,
                  label: 'Received',
                  onTap: widget.onOpenReceived,
                ),
                const SizedBox(width: 12),
                _Stat(value: library.reflectionCount, label: 'Reflections'),
              ],
            ),
          ),
        ];
        final sections = [
            _Section(
              title: 'Settings',
              children: [
                _Row(
                  icon: scope.notifications.enabled
                      ? Icons.notifications_active_rounded
                      : Icons.notifications_none_rounded,
                  title: 'Daily message',
                  value: scope.notifications.enabled
                      ? reminderSummary(context, scope.notifications)
                      : 'Off',
                  onTap: () => showReminderSheet(context),
                ),
                _Row(
                  icon: Icons.favorite_border_rounded,
                  title: 'Saved messages',
                  value: '${library.saved.length}',
                  onTap: widget.onOpenSaved,
                ),
              ],
            ),
            const SizedBox(height: 24),
            _Section(
              title: 'About',
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
                  child: Text(
                    'Small words. A little more light.\n\n'
                    '60 messages from the Bible, the Bhagavad Gita and the '
                    'Quran. Your name, saved messages and reflections are '
                    'kept on this device only.',
                    style: TextStyle(fontSize: 14.5, color: c.muted, height: 1.5),
                  ),
                ),
              ],
            ),
        ];

        if (!isDesktop(context)) {
          return ListView(
            padding: const EdgeInsets.only(bottom: 32),
            children: [
              const SosHeader(title: 'Profile'),
              const SizedBox(height: 18),
              ...identity,
              const SizedBox(height: 30),
              ...sections,
            ],
          );
        }
        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(40, 48, 40, 48),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: desktopWidth),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('YOUR SPACE', style: eyebrow(c.muted, fontSize: 11.5)),
                  const SizedBox(height: 10),
                  Text('Profile', style: serif(fontSize: 44, color: c.ink, height: 1.1)),
                  const SizedBox(height: 14),
                  const AccentRule(width: 34),
                  const SizedBox(height: 36),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 4,
                        child: PaperCard(
                          padding: const EdgeInsets.symmetric(vertical: 36),
                          child: Column(children: identity),
                        ),
                      ),
                      const SizedBox(width: 36),
                      Expanded(flex: 6, child: Column(children: sections)),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _nameLabel(SosColors c, String name) {
    return Column(
      key: const ValueKey('label'),
      children: [
        InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: _startEditing,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Text(
                    name.isEmpty ? 'Add your name' : name,
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                    style: serif(
                        fontSize: 30, color: name.isEmpty ? c.muted : c.ink),
                  ),
                ),
                const SizedBox(width: 8),
                Icon(Icons.edit_outlined, size: 20, color: c.accent,
                    semanticLabel: 'Edit name'),
              ],
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text('Tap to edit your name',
            style: TextStyle(fontSize: 13, color: c.muted)),
      ],
    );
  }

  Widget _nameField(SosColors c) {
    return Row(
      key: const ValueKey('field'),
      children: [
        Expanded(
          child: TextField(
            controller: _nameController,
            focusNode: _nameFocus,
            maxLength: 30,
            textAlign: TextAlign.center,
            textCapitalization: TextCapitalization.words,
            textInputAction: TextInputAction.done,
            style: serif(fontSize: 24, color: c.ink),
            decoration: const InputDecoration(
              hintText: 'Your name',
              counterText: '',
            ),
            onChanged: (_) => setState(() {}),
            onSubmitted: (_) => _finishEditing(),
            onTapOutside: (_) => _finishEditing(),
          ),
        ),
        const SizedBox(width: 8),
        IconButton.filled(
          tooltip: 'Save name',
          onPressed: _finishEditing,
          style: IconButton.styleFrom(
              backgroundColor: c.accent, foregroundColor: c.onAccent),
          icon: const Icon(Icons.check_rounded),
        ),
      ],
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.value, required this.label, this.onTap});

  final int value;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = SosColors.of(context);
    return Expanded(
      child: PaperCard(
        onTap: onTap,
        radius: 18,
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        child: Column(
          children: [
            Text('$value', style: serif(fontSize: 30, color: c.accent, height: 1)),
            const SizedBox(height: 6),
            Text(label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 13, color: c.muted)),
          ],
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final c = SosColors.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 10),
            child: Text(title.toUpperCase(), style: eyebrow(c.muted)),
          ),
          PaperCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                for (var i = 0; i < children.length; i++) ...[
                  if (i > 0) Divider(indent: 18, endIndent: 18, color: c.line),
                  children[i],
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({
    required this.icon,
    required this.title,
    required this.value,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = SosColors.of(context);
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 16, 12, 16),
        child: Row(
          children: [
            Icon(icon, color: c.accent),
            const SizedBox(width: 14),
            Text(title, style: TextStyle(fontSize: 16, color: c.ink)),
            const SizedBox(width: 12),
            Expanded(
              child: Text(value,
                  textAlign: TextAlign.end,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 14, color: c.muted)),
            ),
            Icon(Icons.chevron_right_rounded, color: c.muted),
          ],
        ),
      ),
    );
  }
}
