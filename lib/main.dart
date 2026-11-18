import 'package:flutter/material.dart';
import 'package:shorebird_code_push/shorebird_code_push.dart';
import 'screens/chat_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const SchoolPageAIApp());
}

class SchoolPageAIApp extends StatelessWidget {
  const SchoolPageAIApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'School Page AI',
      theme: ThemeData.dark(useMaterial3: true).copyWith(
        scaffoldBackgroundColor: const Color(0xFF131314),
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blueAccent,
          brightness: Brightness.dark,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF131314),
          foregroundColor: Colors.white,
          elevation: 0,
        ),
      ),
      home: const ChatScreen(),
    );
  }
}

/// በAppBar ወይም በDrawer ውስጥ የሚቀመጥ ራሱን የቻለ የUpdate ቁልፍ (OTA Patch Checker)
class AppUpdateButton extends StatefulWidget {
  const AppUpdateButton({super.key});

  @override
  State<AppUpdateButton> createState() => _AppUpdateButtonState();
}

class _AppUpdateButtonState extends State<AppUpdateButton> {
  final ShorebirdUpdater _updater = ShorebirdUpdater();
  bool _isChecking = false;

  Future<void> _checkForUpdates() async {
    if (_isChecking) return;

    // Shorebird በRelease APK ላይ ብቻ ስለሚሰራ መገኘቱን ያረጋግጣል
    if (!_updater.isAvailable) {
      _showSnackBar('Update የሚሰራው በShorebird Release APK ላይ ብቻ ነው።');
      return;
    }

    setState(() => _isChecking = true);
    _showSnackBar('አዲስ ማሻሻያ በመፈለግ ላይ (Checking for updates)...');

    try {
      final status = await _updater.checkForUpdate();

      if (status == UpdateStatus.outdated) {
        _showSnackBar('አዲስ Update ተገኝቷል! በመጫን ላይ...');
        await _updater.update();
        if (mounted) {
          _showRestartDialog();
        }
      } else if (status == UpdateStatus.restartRequired) {
        if (mounted) {
          _showRestartDialog();
        }
      } else {
        _showSnackBar('School Page AI አዲስ ነው (Up to date!) ✅');
      }
    } catch (e) {
      _showSnackBar('Update መፈለግ አልተቻለም: ኢንተርኔትዎን ያረጋግጡ');
    } finally {
      if (mounted) {
        setState(() => _isChecking = false);
      }
    }
  }

  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showRestartDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1F22),
        title: const Row(
          children: [
            Icon(Icons.system_update_alt, color: Colors.blueAccent),
            SizedBox(width: 10),
            Text('Update ተጭኗል!', style: TextStyle(color: Colors.white)),
          ],
        ),
        content: const Text(
          'አዲሱ የSchool Page AI ማሻሻያ በተሳካ ሁኔታ ወርዷል። አዲሱን ለውጥ ለማየት አፑን ሙሉ በሙሉ ዘግተው እንደገና ይክፈቱት።',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent),
            onPressed: () => Navigator.pop(context),
            child: const Text('እሺ (OK)', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: 'Check for App Update',
      onPressed: _isChecking ? null : _checkForUpdates,
      icon: _isChecking
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.blueAccent,
              ),
            )
          : const Icon(Icons.system_update_rounded, color: Colors.blueAccent),
    );
  }
}
