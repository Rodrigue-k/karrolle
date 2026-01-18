import 'package:flutter/material.dart';
import 'package:karrolle/bridge/native_api.dart';

class StudioLeftPanel extends StatelessWidget {
  const StudioLeftPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 260,
      decoration: const BoxDecoration(
        color: Color(0xFF1E1E1E),
        border: Border(right: BorderSide(color: Color(0xFF333333))),
      ),
      child: Column(
        children: [
          // Basic tool toggles
          Container(
            height: 40,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildToolIcon(Icons.mouse_rounded, isActive: true),
                _buildToolIcon(Icons.text_fields),
                _buildToolIcon(
                  Icons.crop_square,
                  onTap: () {
                    // TEST: Create Red Rectangle via C++ Engine
                    NativeApi.addRect(
                      200,
                      150,
                      300,
                      200,
                      0xFFFF0000,
                    ); // ARGB Red
                  },
                ),
                _buildToolIcon(Icons.image_outlined),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFF333333)),

          // Layers / Pages List
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(8),
              children: [
                _buildSectionTitle('LAYERS'),
                const SizedBox(height: 8),
                _buildLayerItem(
                  Icons.text_fields,
                  'Headline',
                  isSelected: true,
                ),
                _buildLayerItem(Icons.crop_square_rounded, 'Background Box'),
                _buildLayerItem(Icons.image, 'Hero Image'),

                const SizedBox(height: 24),
                _buildSectionTitle('PAGES'),
                const SizedBox(height: 8),
                _buildPageItem(1, 'Introduction'),
                _buildPageItem(2, 'Features'),
                _buildPageItem(3, 'Pricing'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToolIcon(
    IconData icon, {
    bool isActive = false,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Container(
        width: 32,
        height: 32,
        decoration: isActive
            ? BoxDecoration(
                color: Colors.blueAccent.withAlpha(51),
                borderRadius: BorderRadius.circular(4),
              )
            : null,
        child: Icon(
          icon,
          size: 16,
          color: isActive ? Colors.blueAccent : Colors.white60,
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.bold,
        color: Colors.white38,
        letterSpacing: 1,
      ),
    );
  }

  Widget _buildLayerItem(
    IconData icon,
    String label, {
    bool isSelected = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 2),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: isSelected ? const Color(0xFF37373D) : Colors.transparent,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.visibility_outlined,
            size: 14,
            color: Colors.white30,
          ),
          const SizedBox(width: 8),
          Icon(icon, size: 14, color: Colors.blueAccent),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(fontSize: 12, color: Colors.white70),
          ),
        ],
      ),
    );
  }

  Widget _buildPageItem(int index, String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 20,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.white24),
              borderRadius: BorderRadius.circular(2),
            ),
            child: Text(
              '$index',
              style: const TextStyle(fontSize: 9, color: Colors.white54),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            label,
            style: const TextStyle(fontSize: 12, color: Colors.white70),
          ),
        ],
      ),
    );
  }
}
