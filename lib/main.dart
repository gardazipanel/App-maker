import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:installed_apps/installed_apps.dart';
import 'package:installed_apps/app_info.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:file_picker/file_picker.dart';

void main() => runApp(const CloneMakerApp());

class CloneMakerApp extends StatelessWidget {
  const CloneMakerApp({super.key});
  @override
  Widget build(BuildContext c) => MaterialApp(
        title: 'Clone Maker',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(colorSchemeSeed: Colors.indigo, useMaterial3: true),
        darkTheme: ThemeData(
            colorSchemeSeed: Colors.indigo,
            brightness: Brightness.dark,
            useMaterial3: true),
        home: const Home(),
      );
}

const kFeatures = [
  'Bottom navigation bar', 'Search', 'Profile', 'Settings', 'Dark mode',
  'Notifications', 'Login/Signup', 'Onboarding', 'Offline mode', 'Themes',
  'App lock', 'Share', 'Favorites', 'Multi-language'
];

class Home extends StatefulWidget {
  const Home({super.key});
  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  int tab = 0;
  AppInfo? app;
  String platform = 'Flutter';
  final extras = <String>{'Bottom navigation bar', 'Search', 'Settings', 'Dark mode'};
  final notes = TextEditingController();

  String get prompt => '''
Build a complete, production-ready $platform mobile app inspired by "${app?.name ?? '[APP]'}" (package: ${app?.packageName ?? '-'}, v${app?.versionName ?? '-'}).

GOAL: Same type of experience, similar layout and navigation flow, but with ORIGINAL name, logo, colors and assets (do not copy trademarks or protected assets).

1. ANALYSIS: List every main screen of this kind of app, the user flow between them, and the core features.
2. UI: Same style of layout, bottom navigation/tab structure, app bar, cards, lists, spacing, Material 3, smooth animations, light + dark theme.
3. FEATURES TO INCLUDE: ${extras.join(', ')}.
4. EXTRA REQUESTS: ${notes.text.isEmpty ? 'None' : notes.text}
5. ARCHITECTURE: clean folders (screens, widgets, models, services), state management, local storage, error + loading states, runtime permission handling.
6. OUTPUT: full project files with code, setup steps, and release APK build command.
Write every file completely, no placeholders.''';

  Future<void> pickApp() async {
    showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(child: CircularProgressIndicator()));
    final apps = await InstalledApps.getInstalledApps(true, true);
    apps.sort((a, b) => (a.name).toLowerCase().compareTo(b.name.toLowerCase()));
    if (!mounted) return;
    Navigator.pop(context);
    final picked = await showModalBottomSheet<AppInfo>(
        context: context,
        isScrollControlled: true,
        builder: (_) => AppPicker(apps: apps));
    if (picked != null) setState(() => app = picked);
  }

  @override
  Widget build(BuildContext c) {
    final pages = [clonePage(), promptPage(), const ApkPage(), const PermPage()];
    return Scaffold(
      appBar: AppBar(title: const Text('Clone Maker')),
      body: pages[tab],
      bottomNavigationBar: NavigationBar(
        selectedIndex: tab,
        onDestinationSelected: (i) => setState(() => tab = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.copy_all), label: 'Clone'),
          NavigationDestination(icon: Icon(Icons.auto_awesome), label: 'Prompt'),
          NavigationDestination(icon: Icon(Icons.android), label: 'APK'),
          NavigationDestination(icon: Icon(Icons.security), label: 'Permissions'),
        ],
      ),
    );
  }

  Widget clonePage() => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(children: [
          if (app != null)
            Card(
              child: ListTile(
                leading: app!.icon != null
                    ? Image.memory(app!.icon!, width: 48)
                    : const Icon(Icons.apps),
                title: Text(app!.name),
                subtitle: Text('${app!.packageName}\nv${app!.versionName}'),
                isThreeLine: true,
              ),
            ),
          const SizedBox(height: 12),
          FilledButton.icon(
              onPressed: pickApp,
              icon: const Icon(Icons.touch_app),
              label: Text(app == null ? 'Select App' : 'Change App')),
          const SizedBox(height: 8),
          if (app != null)
            FilledButton.tonalIcon(
                onPressed: () => setState(() => tab = 1),
                icon: const Icon(Icons.arrow_forward),
                label: const Text('Next: Generate Prompt')),
        ]),
      );

  Widget promptPage() => ListView(padding: const EdgeInsets.all(16), children: [
        SegmentedButton<String>(
          segments: const [
            ButtonSegment(value: 'Flutter', label: Text('Flutter')),
            ButtonSegment(value: 'Kotlin', label: Text('Kotlin')),
            ButtonSegment(value: 'React Native', label: Text('RN')),
          ],
          selected: {platform},
          onSelectionChanged: (s) => setState(() => platform = s.first),
        ),
        const SizedBox(height: 12),
        Wrap(spacing: 6, children: [
          for (final f in kFeatures)
            FilterChip(
                label: Text(f),
                selected: extras.contains(f),
                onSelected: (v) =>
                    setState(() => v ? extras.add(f) : extras.remove(f))),
        ]),
        const SizedBox(height: 12),
        TextField(
            controller: notes,
            onChanged: (_) => setState(() {}),
            maxLines: 3,
            decoration: const InputDecoration(
                labelText: 'Apne extra features / changes',
                border: OutlineInputBorder())),
        const SizedBox(height: 12),
        Card(
            child: Padding(
                padding: const EdgeInsets.all(12), child: SelectableText(prompt))),
        FilledButton.icon(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: prompt));
              ScaffoldMessenger.of(context)
                  .showSnackBar(const SnackBar(content: Text('Prompt copy ho gaya')));
            },
            icon: const Icon(Icons.copy),
            label: const Text('Copy Prompt')),
      ]);
}

class AppPicker extends StatefulWidget {
  final List<AppInfo> apps;
  const AppPicker({super.key, required this.apps});
  @override
  State<AppPicker> createState() => _AppPickerState();
}

class _AppPickerState extends State<AppPicker> {
  String q = '';
  @override
  Widget build(BuildContext c) {
    final list = widget.apps
        .where((a) => a.name.toLowerCase().contains(q.toLowerCase()))
        .toList();
    return SizedBox(
      height: MediaQuery.of(c).size.height * .85,
      child: Column(children: [
        Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
                onChanged: (v) => setState(() => q = v),
                decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.search),
                    hintText: 'Search app',
                    border: OutlineInputBorder()))),
        Expanded(
            child: ListView.builder(
                itemCount: list.length,
                itemBuilder: (_, i) => ListTile(
                      leading: list[i].icon != null
                          ? Image.memory(list[i].icon!, width: 40)
                          : const Icon(Icons.apps),
                      title: Text(list[i].name),
                      subtitle: Text(list[i].packageName),
                      onTap: () => Navigator.pop(c, list[i]),
                    ))),
      ]),
    );
  }
}

class ApkPage extends StatefulWidget {
  const ApkPage({super.key});
  @override
  State<ApkPage> createState() => _ApkPageState();
}

class _ApkPageState extends State<ApkPage> {
  PlatformFile? file;
  static const wf = r'''name: Build APK
on:
  workflow_dispatch:
  push:
    branches: [main]
jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-java@v4
        with:
          distribution: temurin
          java-version: '17'
      - uses: subosito/flutter-action@v2
        with:
          channel: stable
      - name: Create Android project
        run: |
          flutter create --platforms=android --project-name clone_maker build_app
          cp lib/main.dart build_app/lib/main.dart
          cp pubspec.yaml build_app/pubspec.yaml
          sed -i 's|<application|<uses-permission android:name="android.permission.QUERY_ALL_PACKAGES"/><uses-permission android:name="android.permission.REQUEST_INSTALL_PACKAGES"/><uses-permission android:name="android.permission.POST_NOTIFICATIONS"/><uses-permission android:name="android.permission.CAMERA"/><uses-permission android:name="android.permission.RECORD_AUDIO"/><uses-permission android:name="android.permission.ACCESS_FINE_LOCATION"/><application|' build_app/android/app/src/main/AndroidManifest.xml
      - name: Build
        working-directory: build_app
        run: |
          flutter pub get
          flutter build apk --release
      - uses: actions/upload-artifact@v4
        with:
          name: clone-maker-apk
          path: build_app/build/app/outputs/flutter-apk/app-release.apk''';

  @override
  Widget build(BuildContext c) => ListView(padding: const EdgeInsets.all(16), children: [
        const Text(
            'Phone par direct APK compile nahi hota (Gradle + SDK chahiye). '
            'Project zip select karo, phir GitHub Actions workflow se free APK banao.'),
        const SizedBox(height: 12),
        FilledButton.icon(
            onPressed: () async {
              final r = await FilePicker.platform
                  .pickFiles(type: FileType.custom, allowedExtensions: ['zip']);
              if (r != null) setState(() => file = r.files.first);
            },
            icon: const Icon(Icons.folder_zip),
            label: const Text('Select Project ZIP')),
        if (file != null)
          ListTile(
              leading: const Icon(Icons.check_circle, color: Colors.green),
              title: Text(file!.name),
              subtitle: Text('${(file!.size / 1024).toStringAsFixed(1)} KB')),
        const SizedBox(height: 12),
        const Text('Steps (sirf phone se):\n1. github.com par repo banao\n'
            '2. lib/main.dart aur pubspec.yaml file banao\n'
            '3. .github/workflows/build.yml mein ye workflow paste karo\n'
            '4. Actions tab > Build APK > Run workflow\n'
            '5. 5-8 min baad Artifacts se APK download karo'),
        const SizedBox(height: 8),
        Card(child: Padding(padding: const EdgeInsets.all(12), child: SelectableText(wf))),
        FilledButton.tonalIcon(
            onPressed: () => Clipboard.setData(const ClipboardData(text: wf)),
            icon: const Icon(Icons.copy),
            label: const Text('Copy Workflow')),
      ]);
}

class PermPage extends StatefulWidget {
  const PermPage({super.key});
  @override
  State<PermPage> createState() => _PermPageState();
}

class _PermPageState extends State<PermPage> {
  final perms = {
    'Storage': Permission.storage,
    'Notifications': Permission.notification,
    'Camera': Permission.camera,
    'Microphone': Permission.microphone,
    'Location': Permission.location,
    'Install packages': Permission.requestInstallPackages,
  };
  final status = <String, PermissionStatus>{};

  @override
  void initState() {
    super.initState();
    refresh();
  }

  Future<void> refresh() async {
    for (final e in perms.entries) {
      status[e.key] = await e.value.status;
    }
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext c) => ListView(children: [
        for (final e in perms.entries)
          ListTile(
            title: Text(e.key),
            subtitle: Text(status[e.key]?.name ?? '...'),
            trailing: status[e.key]?.isGranted == true
                ? const Icon(Icons.check_circle, color: Colors.green)
                : TextButton(
                    onPressed: () async {
                      await e.value.request();
                      refresh();
                    },
                    child: const Text('Allow')),
          ),
        ListTile(
            leading: const Icon(Icons.settings),
            title: const Text('App Settings kholo'),
            onTap: openAppSettings),
      ]);
}
