import 'package:device_preview/device_preview.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:gooey_fab/gooey_fab.dart';

void main() {
  runApp(
    DevicePreview(
      enabled: !kReleaseMode,
      builder: (_) => const ExampleApp(),
    ),
  );
}

class ExampleApp extends StatelessWidget {
  const ExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      locale: DevicePreview.locale(context),
      builder: DevicePreview.appBuilder,
      debugShowCheckedModeBanner: false,
      title: 'GooeyFab Example',
      theme: ThemeData.dark(useMaterial3: true).copyWith(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.cyanAccent,
          brightness: Brightness.dark,
        ),
      ),
      home: const HomeScreen(),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// HOME SCREEN
// Uses GooeyFabScaffold with 3 items → all 3 transition types
// ─────────────────────────────────────────────────────────────────────────────

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return GooeyFabScaffold(
      fabColor: Colors.cyanAccent,
      fabIconColor: Colors.black,
      blobEffect: BlobEffect.arc,
      gooiness: 40,
      initialPosition: const Offset(16, 16),
      appBar: AppBar(
        title: const Text('GooeyFab'),
        backgroundColor: Colors.white.withValues(alpha: 0.05),
        elevation: 2,
      ),
      items: [
        // ── 1. Bottom sheet ─────────────────────────────────────────────
        GooeyFabItem(
          icon: CupertinoIcons.square_stack_3d_down_right_fill,
          label: 'Open sheet',
          onTap: (ctx) => GooeyTransitions.showSheet(
            ctx,
            builder: (_) => const _ExampleSheet(),
          ),
        ),

        // ── 2. Modal dialog ─────────────────────────────────────────────
        GooeyFabItem(
          icon: CupertinoIcons.bell_circle_fill,
          label: 'Open modal',
          onTap: (ctx) => GooeyTransitions.showModal(
            ctx,
            builder: (_) => const _ExampleModal(),
          ),
        ),

        // ── 3. Full-screen ink flood ─────────────────────────────────────
        GooeyFabItem(
          icon: CupertinoIcons.viewfinder,
          iconColor: Colors.black,
          label: 'Open screen',
          onTap: (ctx) => GooeyTransitions.showScreen(
            ctx,
            builder: (_) => const _ExampleFullScreen(),
          ),
        ),
      ],
      body: const _HomeBody(),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// HOME BODY
// ─────────────────────────────────────────────────────────────────────────────

class _HomeBody extends StatelessWidget {
  const _HomeBody();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.grey.shade900, Colors.black],
        ),
      ),
      child: const SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.water_drop_rounded,
                  size: 64, color: Colors.cyanAccent),
              SizedBox(height: 24),
              Text(
                'GooeyFab',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: -0.8,
                ),
              ),
              SizedBox(height: 12),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 48),
                child: Text(
                  'A draggable FAB with liquid morphing transitions.\n'
                  'Drag it anywhere. Tap to open the blob cluster.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 14, color: Colors.white38, height: 1.7),
                ),
              ),
              SizedBox(height: 40),
              _FeaturePill(
                icon: Icons.layers_rounded,
                label: 'Blob 1',
                detail: 'sweat-drop → bottom sheet',
              ),
              SizedBox(height: 8),
              _FeaturePill(
                icon: Icons.notifications_rounded,
                label: 'Blob 2',
                detail: 'peel → elastic modal',
              ),
              SizedBox(height: 8),
              _FeaturePill(
                icon: Icons.open_in_full_rounded,
                label: 'Blob 3',
                detail: 'ink flood → full screen',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FeaturePill extends StatelessWidget {
  final IconData icon;
  final String label;
  final String detail;
  const _FeaturePill(
      {required this.icon, required this.label, required this.detail});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: Colors.cyanAccent),
          const SizedBox(width: 8),
          Text(
            '$label  ',
            style: const TextStyle(
                fontSize: 13,
                color: Colors.white70,
                fontWeight: FontWeight.w600),
          ),
          Text(
            detail,
            style: const TextStyle(fontSize: 13, color: Colors.white38),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// EXAMPLE SHEET CONTENT
// This is YOUR widget — any widget works here.
// ─────────────────────────────────────────────────────────────────────────────

class _ExampleSheet extends StatelessWidget {
  const _ExampleSheet();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Drag handle
        Container(
          margin: const EdgeInsets.only(top: 14, bottom: 8),
          width: 40,
          height: 4,
          decoration: BoxDecoration(
            color: Colors.white24,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 16, 16),
          child: Row(
            children: [
              const Text('Quick actions',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Colors.white)),
              const Spacer(),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close, size: 20, color: Colors.white38),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            physics: const BouncingScrollPhysics(),
            children: [
              _SheetTile(Icons.home_rounded, 'Home dashboard', () {}),
              _SheetTile(Icons.analytics_rounded, 'Analytics', () {}),
              _SheetTile(Icons.settings_rounded, 'Settings', () {}),
              _SheetTile(Icons.logout_rounded, 'Sign out', () {}, danger: true),
            ],
          ),
        ),
      ],
    );
  }
}

class _SheetTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool danger;
  const _SheetTile(this.icon, this.label, this.onTap, {this.danger = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: ListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        tileColor: Colors.white.withValues(alpha: 0.04),
        leading:
            Icon(icon, color: danger ? Colors.redAccent : Colors.cyanAccent),
        title: Text(label, style: const TextStyle(color: Colors.white70)),
        trailing:
            const Icon(Icons.chevron_right, size: 18, color: Colors.white24),
        onTap: onTap,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// EXAMPLE MODAL CONTENT
// ─────────────────────────────────────────────────────────────────────────────

class _ExampleModal extends StatelessWidget {
  const _ExampleModal();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF1C1C1E),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(28),
        side: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
      ),
      title: const Row(children: [
        Icon(Icons.notifications_rounded, color: Colors.cyanAccent, size: 22),
        SizedBox(width: 10),
        Text('Gooey modal',
            style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 17)),
      ]),
      content: const Text(
        'This is your widget. Pass any content here — a form, a confirmation, whatever you need.',
        style: TextStyle(color: Colors.white54, height: 1.55),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          style: TextButton.styleFrom(foregroundColor: Colors.white38),
          child: const Text('Dismiss'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
              backgroundColor: Colors.cyanAccent,
              foregroundColor: Colors.black),
          onPressed: () => Navigator.pop(context),
          child: const Text('Got it'),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// EXAMPLE FULL-SCREEN DESTINATION
// ─────────────────────────────────────────────────────────────────────────────

class _ExampleFullScreen extends StatelessWidget {
  const _ExampleFullScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('New screen'),
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.open_in_full_rounded,
                size: 56, color: Colors.cyanAccent),
            SizedBox(height: 24),
            Text(
              'Your screen here',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 12),
            Text(
              'The ink-flood transition originated\nfrom the FAB\'s exact position.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white38, height: 1.6),
            ),
          ],
        ),
      ),
    );
  }
}
