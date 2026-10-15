import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../application/app_bloc.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/shared.dart';

class StylePreviewPage extends StatelessWidget {
  const StylePreviewPage({super.key});
  @override
  Widget build(BuildContext context) => LocalView(
    builder: (context, view) {
      final styles = context.watch<AppBloc>().state.styles;
      final selected = view.get('selected', -1);
      final style = selected < 0 ? null : styles[selected];
      return Scaffold(
        backgroundColor: Palette.ink,
        body: Stack(
          fit: StackFit.expand,
          children: [
            AnimatedSwitcher(
              duration: MediaQuery.disableAnimationsOf(context)
                  ? Duration.zero
                  : const Duration(milliseconds: 400),
              child: SizedBox.expand(
                key: ValueKey(selected),
                child: Photo(
                  style?.image ?? 'woman',
                  bytes: style?.bytes,
                  radius: 0,
                ),
              ),
            ),
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.center,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: .72),
                    ],
                  ),
                ),
              ),
            ),
            SafeArea(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: Colors.white,
                          radius: 18,
                          child: IconButton(
                            padding: EdgeInsets.zero,
                            icon: const Icon(Icons.close, size: 20),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 7,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black38,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text(
                            'STYLE PREVIEW',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              letterSpacing: 1.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  Text(
                    style?.name ?? 'Find your next look',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Inspiration gallery · live camera / AR not connected',
                    style: TextStyle(color: Colors.white70, fontSize: 10),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    height: 82,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 22),
                      itemCount: styles.length + 1,
                      separatorBuilder: (_, _) => const SizedBox(width: 13),
                      itemBuilder: (_, index) {
                        final i = index - 1;
                        return GestureDetector(
                          onTap: () => change(context, 'selected', i),
                          child: AnimatedContainer(
                            duration: MediaQuery.disableAnimationsOf(context)
                                ? Duration.zero
                                : const Duration(milliseconds: 220),
                            width: selected == i ? 72 : 54,
                            padding: const EdgeInsets.all(3),
                            margin: EdgeInsets.symmetric(
                              vertical: selected == i ? 4 : 12,
                            ),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: selected == i
                                  ? Palette.lavender
                                  : Colors.white70,
                              border: Border.all(
                                color: selected == i
                                    ? Palette.orchid
                                    : Colors.white,
                                width: 2,
                              ),
                            ),
                            child: i == -1
                                ? const Icon(
                                    Icons.face_retouching_natural,
                                    color: Palette.purple,
                                  )
                                : Photo(
                                    styles[i].image,
                                    bytes: styles[i].bytes,
                                    radius: 60,
                                  ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ],
        ),
      );
    },
  );
}
