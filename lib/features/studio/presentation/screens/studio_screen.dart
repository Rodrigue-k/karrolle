import 'package:flutter/material.dart';
import 'package:karrolle/features/engine/presentation/engine_view.dart';
import 'package:karrolle/features/studio/presentation/widgets/studio_app_bar.dart';
import 'package:karrolle/features/studio/presentation/widgets/studio_left_panel.dart';
import 'package:karrolle/features/studio/presentation/widgets/studio_properties_panel.dart';

class StudioScreen extends StatelessWidget {
  const StudioScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E1E1E), // VS Code / Dark Modern bg
      body: Column(
        children: [
          // 1. Top Bar (Professional Menu & Actions)
          const StudioAppBar(),

          // 2. Main Workspace Area
          Expanded(
            child: Row(
              children: [
                // Left Panel (Tools, Layers, Assets)
                const StudioLeftPanel(),

                // Canvas Area (Infinite scrollable area usually, centered for now)
                Expanded(
                  child: Container(
                    color: const Color(
                      0xFF252526,
                    ), // Slightly lighter for canvas background
                    child: Center(
                      // Concept: The EngineView is the "Paper" on the desk
                      child: Container(
                        decoration: BoxDecoration(
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withAlpha(128),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        // Fixed aspect ratio container for the engine view
                        child: const AspectRatio(
                          aspectRatio: 16 / 9,
                          child: EngineView(),
                        ),
                      ),
                    ),
                  ),
                ),

                // Right Panel (Properties, Inspector)
                const StudioPropertiesPanel(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
