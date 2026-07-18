import 'package:flutter/material.dart';

class PreferencesScreen extends StatefulWidget {
  const PreferencesScreen({super.key});

  @override
  State<PreferencesScreen> createState() => _PreferencesScreenState();
}

class _PreferencesScreenState extends State<PreferencesScreen> {
  bool _hwAcceleration = true;
  bool _fastSeek = true;
  bool _autoPlayNext = false;
  bool _hoverPreview = true;
  bool _tooltipEnabled = true;
  double _fontSize = 14.0;
  String _activeColor = 'Neon Green';

  final List<String> _colorOptions = [
    'Neon Green',
    'Cyan Blue',
    'Crimson Red',
    'Purple',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF050505),
      appBar: AppBar(
        backgroundColor: const Color(0xFF050505),
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'PREFERENCES',
          style: TextStyle(
            color: Color(0xFF00E676),
            letterSpacing: 2.0,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader('PLAYBACK ENGINE'),
            _buildSwitchTile(
              title: 'Hardware Acceleration',
              subtitle: 'Use GPU decoding for smoother playback',
              value: _hwAcceleration,
              onChanged: (val) => setState(() => _hwAcceleration = val),
            ),
            _buildSwitchTile(
              title: 'Fast Seek Mode',
              subtitle: 'Enable quick jumping during video timeline changes',
              value: _fastSeek,
              onChanged: (val) => setState(() => _fastSeek = val),
            ),
            const SizedBox(height: 32),
            _buildSectionHeader('BEHAVIOR'),
            _buildSwitchTile(
              title: 'Auto-Play Next Module',
              subtitle: 'Automatically start the next video when finished',
              value: _autoPlayNext,
              onChanged: (val) => setState(() => _autoPlayNext = val),
            ),
            _buildSwitchTile(
              title: 'Taskbar Preview',
              subtitle: 'Show video preview frames when hovering on taskbar',
              value: _hoverPreview,
              onChanged: (val) => setState(() => _hoverPreview = val),
            ),
            const SizedBox(height: 32),
            _buildSectionHeader('INTERFACE & VISUALS'),
            _buildSwitchTile(
              title: 'Long Title Tooltips',
              subtitle: 'Show full title on mouse hover for truncated texts',
              value: _tooltipEnabled,
              onChanged: (val) => setState(() => _tooltipEnabled = val),
            ),
            const SizedBox(height: 16),
            _buildSliderTile(),
            const SizedBox(height: 16),
            _buildDropdownTile(),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0, left: 4),
      child: Text(
        title,
        style: const TextStyle(
          color: Colors.white38,
          fontSize: 12,
          fontWeight: FontWeight.w800,
          letterSpacing: 2.0,
        ),
      ),
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF0A0A0A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF141414), width: 2),
      ),
      child: SwitchListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        activeThumbColor: const Color(0xFF00E676),
        activeTrackColor: const Color(0xFF00E676).withValues(alpha: 0.2),
        inactiveThumbColor: Colors.white54,
        inactiveTrackColor: const Color(0xFF141414),
        title: Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4.0),
          child: Text(
            subtitle,
            style: const TextStyle(color: Colors.white38, fontSize: 12),
          ),
        ),
        value: value,
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildSliderTile() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF0A0A0A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF141414), width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Player Font Size',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '${_fontSize.toInt()} px',
                style: const TextStyle(
                  color: Color(0xFF00E676),
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SliderTheme(
            data: SliderThemeData(
              activeTrackColor: const Color(0xFF00E676),
              inactiveTrackColor: const Color(0xFF141414),
              thumbColor: Colors.white,
              overlayColor: const Color(0xFF00E676).withValues(alpha: 0.1),
              trackHeight: 4,
            ),
            child: Slider(
              value: _fontSize,
              min: 10.0,
              max: 24.0,
              divisions: 14,
              onChanged: (val) => setState(() => _fontSize = val),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdownTile() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF0A0A0A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF141414), width: 2),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Seekbar Theme Color',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'Select primary accent color',
                style: TextStyle(color: Colors.white38, fontSize: 12),
              ),
            ],
          ),
          DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _activeColor,
              dropdownColor: const Color(0xFF141414),
              icon: const Icon(
                Icons.arrow_drop_down_rounded,
                color: Color(0xFF00E676),
              ),
              style: const TextStyle(
                color: Color(0xFF00E676),
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
              items: _colorOptions.map((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
              onChanged: (val) {
                if (val != null) {
                  setState(() => _activeColor = val);
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}
