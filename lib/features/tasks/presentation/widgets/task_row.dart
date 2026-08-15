import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../data/models/task_model.dart';
import '../../domain/models/task_enums.dart';

class TaskRow extends StatelessWidget {
  const TaskRow({
    super.key,
    required this.task,
    required this.selected,
    required this.onSelect,
    required this.onToggle,
    required this.onOpen,
    this.projectName,
    this.progress,
  });

  final TaskModel task;
  final bool selected;
  final VoidCallback onSelect;
  final VoidCallback onToggle;
  final VoidCallback onOpen;
  final String? projectName;
  final double? progress;

  Color get _accent {
    switch (task.eisenhower) {
      case Eisenhower.doNow:
        return AppColors.danger;
      case Eisenhower.schedule:
        return AppColors.tasks;
      case Eisenhower.delegate:
        return AppColors.warning;
      case Eisenhower.eliminate:
        return AppColors.muted;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? _accent.withValues(alpha: 0.08) : Colors.transparent,
      child: InkWell(
        onTap: onSelect,
        onDoubleTap: onOpen,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          child: Row(
            children: [
              IconButton(
                tooltip: task.isCompleted ? 'החזר לפעיל' : 'סמן כהושלם',
                onPressed: onToggle,
                icon: Icon(
                  task.isCompleted
                      ? Icons.check_circle
                      : task.isOverdue
                          ? Icons.warning_amber_rounded
                          : Icons.check_circle_outline,
                  color: task.isCompleted
                      ? AppColors.expenses
                      : task.isOverdue
                          ? AppColors.danger
                          : AppColors.muted,
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      task.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        decoration: task.isCompleted
                            ? TextDecoration.lineThrough
                            : null,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      [
                        task.eisenhower.shortLabel,
                        task.status.labelHe,
                        if (task.isOverdue) 'באיחור',
                        if (task.isDueToday) 'היום',
                        if (task.contextTags.isNotEmpty)
                          task.contextTags.join(' '),
                        if (projectName != null) '#$projectName',
                        '${task.estimatedMinutes}ד',
                      ].join(' · '),
                      style: TextStyle(
                        color: task.isOverdue ? AppColors.danger : AppColors.muted,
                        fontSize: 12,
                      ),
                    ),
                    if (progress != null) ...[
                      const SizedBox(height: 4),
                      LinearProgressIndicator(value: progress, minHeight: 4),
                    ],
                  ],
                ),
              ),
              IconButton(
                tooltip: 'עריכה',
                onPressed: onOpen,
                icon: const Icon(Icons.more_horiz),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
