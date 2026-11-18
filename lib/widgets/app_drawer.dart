import 'package:flutter/material.dart';
import '../models/ai_config.dart';

class AppDrawer extends StatelessWidget {
  final AIModelOption selectedModel;
  final String selectedGrade;
  final String selectedSubject;
  final Function(AIModelOption) onModelChanged;
  final Function(String) onGradeChanged;
  final Function(String) onSubjectChanged;
  final VoidCallback onNewChat;

  const AppDrawer({
    super.key,
    required this.selectedModel,
    required this.selectedGrade,
    required this.selectedSubject,
    required this.onModelChanged,
    required this.onGradeChanged,
    required this.onSubjectChanged,
    required this.onNewChat,
  });

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: const Color(0xFF131314),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF4285F4), Color(0xFF9B72CB)],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.school_rounded,
                        color: Colors.white, size: 22),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'School Page AI',
                    style: TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),

            // New Chat Button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: ElevatedButton.icon(
                onPressed: () {
                  onNewChat();
                  Navigator.pop(context);
                },
                icon: const Icon(Icons.add_rounded, color: Colors.white),
                label: const Text(
                  'አዲስ ውይይት (New Chat)',
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.w600),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF282A2C),
                  minimumSize: const Size(double.infinity, 46),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                    side: const BorderSide(color: Colors.white10),
                  ),
                ),
              ),
            ),

            const Divider(color: Colors.white12, height: 24),

            // Scrollable Settings
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                children: [
                  const Padding(
                    padding: EdgeInsets.only(left: 4, bottom: 8),
                    child: Text(
                      '1. AI ሞዴል ይምረጡ (Select Model)',
                      style: TextStyle(
                        color: Color(0xFF8AB4F8),
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  ...AppConfigs.models.map((model) {
                    final isSelected = model.id == selectedModel.id;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? const Color(0xFF8AB4F8).withOpacity(0.15)
                            : const Color(0xFF1E1F22),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isSelected
                              ? const Color(0xFF8AB4F8)
                              : Colors.white10,
                        ),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 4),
                        title: Text(
                          model.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            '${model.subtitle} • ${model.sizeLabel}',
                            style: TextStyle(
                              color: Colors.grey.shade400,
                              fontSize: 11.5,
                            ),
                          ),
                        ),
                        trailing: isSelected
                            ? const Icon(Icons.check_circle_rounded,
                                color: Color(0xFF8AB4F8))
                            : const Icon(Icons.radio_button_unchecked,
                                color: Colors.white24),
                        onTap: () {
                          onModelChanged(model);
                          Navigator.pop(context);
                        },
                      ),
                    );
                  }),

                  const SizedBox(height: 16),
                  const Padding(
                    padding: EdgeInsets.only(left: 4, bottom: 8),
                    child: Text(
                      '2. ክፍል ይምረጡ (Select Grade)',
                      style: TextStyle(
                        color: Color(0xFF8AB4F8),
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: AppConfigs.grades.map((grade) {
                      final isSelected = grade == selectedGrade;
                      return ChoiceChip(
                        label: Text(grade),
                        selected: isSelected,
                        onSelected: (_) => onGradeChanged(grade),
                        selectedColor: const Color(0xFF8AB4F8),
                        backgroundColor: const Color(0xFF1E1F22),
                        side: BorderSide(
                          color: isSelected
                              ? const Color(0xFF8AB4F8)
                              : Colors.white12,
                        ),
                        labelStyle: TextStyle(
                          color: isSelected ? Colors.black : Colors.white70,
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.normal,
                          fontSize: 12.5,
                        ),
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 20),
                  const Padding(
                    padding: EdgeInsets.only(left: 4, bottom: 6),
                    child: Text(
                      '3. የትምህርት ዓይነት (Select Subject)',
                      style: TextStyle(
                        color: Color(0xFF8AB4F8),
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  ...AppConfigs.subjects.map((subject) {
                    final isSelected = subject == selectedSubject;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 4),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? Colors.white.withOpacity(0.08)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: ListTile(
                        dense: true,
                        visualDensity: VisualDensity.compact,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                        leading: Icon(
                          Icons.menu_book_rounded,
                          size: 18,
                          color: isSelected
                              ? const Color(0xFF8AB4F8)
                              : Colors.grey.shade500,
                        ),
                        title: Text(
                          subject,
                          style: TextStyle(
                            color: isSelected
                                ? const Color(0xFF8AB4F8)
                                : Colors.white70,
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.normal,
                            fontSize: 14,
                          ),
                        ),
                        trailing: isSelected
                            ? const Icon(Icons.check,
                                size: 16, color: Color(0xFF8AB4F8))
                            : null,
                        onTap: () {
                          onSubjectChanged(subject);
                          Navigator.pop(context);
 },
),
);
}),
const SizedBox(height: 16),
],
),
),
],
),
),
);
}
}
