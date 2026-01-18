import 'package:flutter/material.dart';

class StudioAppBar extends StatelessWidget {
  const StudioAppBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      decoration: const BoxDecoration(
        color: Color(0xFF1E1E1E), // Matches main bg
        border: Border(bottom: BorderSide(color: Color(0xFF333333))),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          // Logo / Home
          const Icon(
            Icons.grid_view_rounded,
            color: Colors.blueAccent,
            size: 20,
          ),
          const SizedBox(width: 16),

          // Menu Items
          _buildMenuItem('File'),
          _buildMenuItem('Edit'),
          _buildMenuItem('View'),
          _buildMenuItem('Insert'),

          const Spacer(),

          // Project Title (Centered-ish)
          const Text(
            'Untitled Project',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),

          const Spacer(),

          // Actions
          _buildActionButton(Icons.play_arrow_rounded, Colors.greenAccent),
          const SizedBox(width: 12),
          _buildActionButton(Icons.share_outlined, Colors.white70),
          const SizedBox(width: 8),
          const CircleAvatar(
            radius: 12,
            backgroundColor: Colors.blueGrey,
            child: Text(
              'K',
              style: TextStyle(fontSize: 10, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem(String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white70,
          fontSize: 12,
          fontWeight: FontWeight.normal,
        ),
      ),
    );
  }

  Widget _buildActionButton(IconData icon, Color color) {
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(4),
        color: Colors.white.withAlpha(13),
      ),
      child: Icon(icon, size: 16, color: color),
    );
  }
}
