import 'package:flutter/material.dart';

import '../core/tokens.dart';
import '../data/mock_data.dart';
import '../widgets/primitives.dart';
import '../widgets/sheets.dart';

/// The public surface and the way in.
///
/// First launch lands on the institute directory — anyone can browse brochures
/// without an account. Asking for a callback is the gate: name, mobile, OTP,
/// and the lead goes to the system admin who owns that institute. Once a device
/// has signed in once, later launches skip the directory and open at login.
class EntryFlow extends StatefulWidget {
  const EntryFlow({super.key});

  @override
  State<EntryFlow> createState() => _EntryFlowState();
}

enum _Step { directory, callback, login, picker }

class _EntryFlowState extends State<EntryFlow> {
  _Step _step = _Step.directory;

  void _go(_Step s) => setState(() => _step = s);

  @override
  Widget build(BuildContext context) => switch (_step) {
        _Step.directory => _directory(),
        _Step.callback => _callback(),
        _Step.login => _login(),
        _Step.picker => _picker(),
      };

  // ------------------------------------------------------------ directory --
  Widget _directory() {
    final c = context.c;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FeatureCard(
          padding: const EdgeInsets.fromLTRB(22, 30, 22, 34),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('KALYAN · DOMBIVLI · THANE',
                  style: AppType.label(Colors.white.withOpacity(0.62))),
              const SizedBox(height: 10),
              Text('Find a class that fits your child.',
                  style: AppType.display(30,
                      weight: FontWeight.w600, color: Colors.white, height: 1.08)),
              const SizedBox(height: 11),
              Text(
                  'Browse brochures from institutes near you. No account until you ask for a callback.',
                  style: AppType.body(13.5,
                      color: Colors.white.withOpacity(0.68), height: 1.55)),
              const SizedBox(height: 18),
              BigButton('I have an account',
                  bg: Colors.white,
                  fg: c.accent,
                  onPressed: () => _go(_Step.login)),
            ],
          ),
        ),
        const SectionLabel('4 institutes nearby'),
        for (final i in Mock.institutes)
          Padding(
            padding: const EdgeInsets.only(bottom: 11),
            child: Panel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      AvatarBadge(i.name, size: 42),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(i.name,
                                style: AppType.body(15,
                                    weight: FontWeight.w600, color: c.text)),
                            Text('${i.city} · ${i.batches} batches',
                                style: AppType.body(11.5, color: c.text2)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      AppButton('Brochure',
                          small: true,
                          onPressed: () =>
                              showToast(context, 'Opens the ${i.name} brochure')),
                      const SizedBox(width: 7),
                      AppButton('Request callback',
                          kind: BtnKind.primary,
                          small: true,
                          onPressed: () => _go(_Step.callback)),
                    ],
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  // ------------------------------------------------------------- callback --
  Widget _callback() {
    final c = context.c;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppButton('← Back', small: true, onPressed: () => _go(_Step.directory)),
        const SizedBox(height: 22),
        Text('Where should they reach you?',
            style: AppType.display(26, weight: FontWeight.w600, color: c.text)),
        const SizedBox(height: 8),
        Text(
            'One code to confirm your number, then the institute gets the request.',
            style: AppType.body(13.5, color: c.text2, height: 1.55)),
        const SizedBox(height: 22),
        _labelled(context, 'Name', const TextField(
          decoration: InputDecoration(hintText: 'Your name'),
        )),
        _labelled(context, 'Mobile', const TextField(
          keyboardType: TextInputType.phone,
          decoration: InputDecoration(hintText: '+91'),
        )),
        Text('Code', style: AppType.body(11.5, weight: FontWeight.w600, color: c.text2)),
        const SizedBox(height: 6),
        const _OtpBoxes(),
        const SizedBox(height: 7),
        Text('Auto-reads the SMS on Android · auto-advances as you type',
            style: AppType.body(11, color: c.text3)),
        const SizedBox(height: 20),
        BigButton('Confirm and send',
            kind: BtnKind.primary,
            onPressed: () {
              showToast(context, "Sent — they'll call within a day");
              _go(_Step.directory);
            }),
      ],
    );
  }

  // ---------------------------------------------------------------- login --
  Widget _login() {
    final c = context.c;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('SUNRISE ACADEMY', style: AppType.label(c.accent)),
        const SizedBox(height: 10),
        Text('Sign in',
            style: AppType.display(30, weight: FontWeight.w600, color: c.text)),
        const SizedBox(height: 8),
        Text('One account, whichever role you hold.',
            style: AppType.body(13.5, color: c.text2)),
        const SizedBox(height: 22),
        BigButton('Continue with face unlock',
            leading: Text('☉', style: AppType.body(18, color: c.text)),
            onPressed: () => _go(_Step.picker)),
        const SizedBox(height: 14),
        Center(child: Text('or', style: AppType.body(11.5, color: c.text3))),
        const SizedBox(height: 14),
        Segmented(
            options: const ['Password', 'Mobile OTP'],
            index: 0,
            onChanged: (_) => showToast(context, 'Switches to OTP entry')),
        const SizedBox(height: 18),
        _labelled(context, 'Email or username', const TextField(
          decoration: InputDecoration(hintText: 'you@email.com'),
        )),
        _labelled(context, 'Password', const TextField(
          obscureText: true,
          decoration: InputDecoration(hintText: '••••••••'),
        )),
        BigButton('Sign in',
            kind: BtnKind.primary, onPressed: () => _go(_Step.picker)),
        const SizedBox(height: 11),
        BigButton('Continue with Google', onPressed: () => _go(_Step.picker)),
        const SizedBox(height: 22),
        Row(
          children: [
            Expanded(
                child: AppButton('Book a demo',
                    expand: true, onPressed: () => _go(_Step.callback))),
            const SizedBox(width: 7),
            Expanded(
                child: AppButton('Browse institutes',
                    expand: true, onPressed: () => _go(_Step.directory))),
          ],
        ),
      ],
    );
  }

  // --------------------------------------------------------------- picker --
  /// Shown only when an account holds more than one membership — a teacher who
  /// is also a parent at the same institute, say. Single-role users never see it.
  Widget _picker() {
    final c = context.c;
    const memberships = [
      ('Teacher', 'Sunrise Academy', '3 batches · 18 hrs this week', AvatarTone.accent),
      ('Parent', 'Sunrise Academy', 'Aarav Kulkarni, Std XII', AvatarTone.hot),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('How are you signing in?',
            style: AppType.display(28, weight: FontWeight.w600, color: c.text)),
        const SizedBox(height: 8),
        Text(
            'Your account holds two roles. Switch any time from the top bar.',
            style: AppType.body(13.5, color: c.text2, height: 1.55)),
        const SizedBox(height: 22),
        for (final m in memberships)
          Padding(
            padding: const EdgeInsets.only(bottom: 11),
            child: Panel(
              onTap: () => showToast(
                  context, 'Pick ${m.$1} from the top bar to see that dashboard'),
              child: Row(
                children: [
                  AvatarBadge(m.$1, size: 44, tone: m.$4, glyph: m.$1[0]),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(m.$1,
                            style: AppType.body(16,
                                weight: FontWeight.w600, color: c.text)),
                        const SizedBox(height: 2),
                        Text(m.$2, style: AppType.body(12, color: c.text2)),
                        const SizedBox(height: 3),
                        Text(m.$3, style: AppType.body(11.5, color: c.text3)),
                      ],
                    ),
                  ),
                  Text('›', style: AppType.body(20, color: c.text3)),
                ],
              ),
            ),
          ),
        const SizedBox(height: 6),
        BigButton('Sign out', onPressed: () => _go(_Step.login)),
      ],
    );
  }

  Widget _labelled(BuildContext context, String label, Widget field) {
    final c = context.c;
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: AppType.body(11.5, weight: FontWeight.w600, color: c.text2)),
          const SizedBox(height: 6),
          field,
        ],
      ),
    );
  }
}

/// Six boxes that advance themselves as you type. On Android this is where the
/// SMS retriever API hooks in so the code never has to be typed at all.
class _OtpBoxes extends StatefulWidget {
  const _OtpBoxes();

  @override
  State<_OtpBoxes> createState() => _OtpBoxesState();
}

class _OtpBoxesState extends State<_OtpBoxes> {
  final _nodes = List.generate(6, (_) => FocusNode());

  @override
  void dispose() {
    for (final n in _nodes) {
      n.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Row(
      children: [
        for (var i = 0; i < 6; i++) ...[
          if (i > 0) const SizedBox(width: 7),
          Expanded(
            child: TextField(
              focusNode: _nodes[i],
              maxLength: 1,
              textAlign: TextAlign.center,
              keyboardType: TextInputType.number,
              style: AppType.mono(16, color: c.text),
              decoration: const InputDecoration(
                counterText: '',
                contentPadding: EdgeInsets.symmetric(vertical: 14),
              ),
              onChanged: (v) {
                if (v.isNotEmpty && i < 5) {
                  FocusScope.of(context).requestFocus(_nodes[i + 1]);
                }
              },
            ),
          ),
        ],
      ],
    );
  }
}
