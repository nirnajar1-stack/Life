import 'package:flutter/material.dart';

import '../modules/app_module.dart';
import '../modules/app_modules.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  int _columnsForWidth(double width) {
    if (width >= 1200) return 4;
    if (width >= 800) return 3;
    if (width >= 500) return 2;
    return 2;
  }

  void _openModule(BuildContext context, AppModule module) {
    if (!module.enabled) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${module.title} — בקרוב')),
      );
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute(builder: module.builder),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Life App'),
          centerTitle: false,
        ),
        body: LayoutBuilder(
          builder: (context, constraints) {
            final int columns = _columnsForWidth(constraints.maxWidth);
            return GridView.count(
              padding: const EdgeInsets.all(16),
              crossAxisCount: columns,
              crossAxisSpacing: 14,
              mainAxisSpacing: 14,
              childAspectRatio: 1.1,
              children: appModules
                  .map((module) => _ModuleTile(
                        module: module,
                        onTap: () => _openModule(context, module),
                      ))
                  .toList(),
            );
          },
        ),
      ),
    );
  }
}

class _ModuleTile extends StatelessWidget {
  const _ModuleTile({required this.module, required this.onTap});

  final AppModule module;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: module.color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(module.icon, size: 30, color: module.color),
              ),
              const SizedBox(height: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          module.title,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      if (!module.enabled)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade300,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Text('בקרוב',
                              style: TextStyle(fontSize: 11)),
                        ),
                    ],
                  ),
                  if (module.subtitle != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      module.subtitle!,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
