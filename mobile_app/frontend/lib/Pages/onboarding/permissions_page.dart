import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:vehnway/Widgets/glass_lite_container.dart';
import 'package:vehnway/core/constants/app_gradients.dart';

class PermissionsPage extends StatelessWidget {
  const PermissionsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.deepBlueBackground, Color(0xFF16213e), Color(0xFF0f3460)],
          ),
        ),
        child: const SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(20, 24, 20, 20),
            child: PermissionsWidget(),
          ),
        ),
      ),
    );
  }
}

class PermissionsWidget extends StatefulWidget {
  const PermissionsWidget({super.key, this.compact = false});

  final bool compact;

  @override
  State<PermissionsWidget> createState() => _PermissionsWidgetState();
}

class _PermissionsWidgetState extends State<PermissionsWidget> {
  late final List<_PermissionTileData> _permissions;

  @override
  void initState() {
    super.initState();
    _permissions = _buildPermissionList();
    _refreshStatuses();
  }

  List<_PermissionTileData> _buildPermissionList() {
    final items = <_PermissionTileData>[
      _PermissionTileData(
        title: 'Location',
        subtitle: 'Needed for live navigation and trip tracking.',
        icon: Icons.location_on_outlined,
        permission: Permission.location,
      ),
      _PermissionTileData(
        title: 'Camera',
        subtitle: 'Needed for drive analysis and camera-assisted features.',
        icon: Icons.camera_alt_outlined,
        permission: Permission.camera,
      ),
    ];
    return items;
  }

  Future<void> _refreshStatuses() async {
    for (final item in _permissions) {
      item.status = await item.permission.status;
    }

    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _requestOne(_PermissionTileData item) async {
    final status = await item.permission.request();
    item.status = status;

    if (mounted) {
      setState(() {});
      if (status.isPermanentlyDenied || status.isRestricted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('"${item.title}" is blocked. Please enable it in app settings.'),
            action: SnackBarAction(
              label: 'Open Settings',
              onPressed: openAppSettings,
            ),
          ),
        );
      }
    }
  }

  Future<void> _requestAll() async {
    for (final item in _permissions) {
      await _requestOne(item);
    }
  }

  void _continueToApp() {
    Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    final grantedCount =
        _permissions.where((p) => p.status.isGranted || p.status.isLimited).length;

    return GlassLiteContainer(
      hasBorder: false,
      backgroundColor: AppColors.background,
      height: widget.compact ? 160 : null,
      padding: widget.compact
          ? const EdgeInsets.symmetric(horizontal: 12, vertical: 10)
          : const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!widget.compact) ...[
            const Text(
              'Choose App Permissions',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              '$grantedCount of ${_permissions.length} granted',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.75),
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 14),
          ] else ...[
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Permissions',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: openAppSettings,
                  tooltip: 'Settings',
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints.tightFor(width: 24, height: 24),
                  icon: const Icon(Icons.settings_rounded, color: Colors.white70, size: 16),
                ),
              ],
            ),
            const SizedBox(height: 6),
          ],
          ListView.separated(
            itemCount: _permissions.length,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            separatorBuilder: (_, __) => const SizedBox(height: 6),
            itemBuilder: (context, index) {
              final item = _permissions[index];
              return widget.compact
                  ? _CompactPermissionTile(
                      item: item,
                      onRequest: () => _requestOne(item),
                    )
                  : _PermissionCard(
                      item: item,
                      onRequest: () => _requestOne(item),
                    );
            },
          ),
          if (!widget.compact) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: _requestAll,
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: BorderSide(color: Colors.white.withValues(alpha: 0.5)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text(
                  'Allow All Recommended',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _continueToApp,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text(
                  'Continue to App',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ),
            const SizedBox(height: 4),
            Center(
              child: TextButton(
                onPressed: openAppSettings,
                child: const Text(
                  'Manage in system settings',
                  style: TextStyle(color: Colors.white70),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _CompactPermissionTile extends StatelessWidget {
  const _CompactPermissionTile({required this.item, required this.onRequest});

  final _PermissionTileData item;
  final VoidCallback onRequest;

  @override
  Widget build(BuildContext context) {
    final Color statusColor;
    final IconData statusIcon;

    if (item.status.isGranted || item.status.isLimited) {
      statusColor = const Color(0xFF88E39A); // green
      statusIcon = Icons.check_circle_rounded;
    } else if (item.status.isPermanentlyDenied || item.status.isRestricted) {
      statusColor = const Color(0xFFFF6B6B); // red
      statusIcon = Icons.error_rounded;
    } else {
      statusColor = Colors.white.withValues(alpha: 0.3); // grey
      statusIcon = Icons.radio_button_unchecked_rounded;
    }

    return InkWell(
      onTap: onRequest,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        ),
        child: Row(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.08),
              ),
              child: Icon(item.icon, color: Colors.white, size: 16),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                item.title,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ),
            const SizedBox(width: 6),
            Icon(
              statusIcon,
              color: statusColor,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }
}

class _PermissionCard extends StatelessWidget {
  const _PermissionCard({required this.item, required this.onRequest});

  final _PermissionTileData item;
  final VoidCallback onRequest;

  @override
  Widget build(BuildContext context) {
    final statusLabel = _statusText(item.status);
    final isGranted = item.status.isGranted || item.status.isLimited;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.12),
            ),
            child: Icon(item.icon, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  item.subtitle,
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.78)),
                ),
                const SizedBox(height: 6),
                Text(
                  statusLabel,
                  style: TextStyle(
                    color: isGranted ? const Color(0xFF88E39A) : const Color(0xFFFFC67A),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          ElevatedButton(
            onPressed: onRequest,
            style: ElevatedButton.styleFrom(
              backgroundColor: isGranted ? const Color(0xFF2E7D32) : AppColors.primary,
              foregroundColor: Colors.white,
            ),
            child: Text(isGranted ? 'Granted' : 'Allow'),
          ),
        ],
      ),
    );
  }

  static String _statusText(PermissionStatus status) {
    if (status.isGranted) return 'Granted';
    if (status.isLimited) return 'Limited access';
    if (status.isPermanentlyDenied) return 'Permanently denied';
    if (status.isRestricted) return 'Restricted';
    if (status.isDenied) return 'Not granted';
    if (status.isProvisional) return 'Provisional';
    return 'Unknown';
  }
}

class _PermissionTileData {
  _PermissionTileData({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.permission,
    // ignore: unused_element_parameter
    this.status = PermissionStatus.denied,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Permission permission;
  PermissionStatus status;
}
