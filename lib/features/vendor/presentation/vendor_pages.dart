import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';

import '../../../application/app_bloc.dart';
import '../../../domain/models.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/shared.dart';

Future<void> pickPhoto(BuildContext context) async {
  try {
    final file = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 1400,
      imageQuality: 85,
    );
    if (file == null) return;
    final bytes = await file.readAsBytes();
    if (context.mounted) change(context, 'photo', bytes);
  } catch (_) {
    if (context.mounted) {
      toast(
        context,
        'Photo library is unavailable. Please try on a supported device.',
      );
    }
  }
}

class PhotoPicker extends StatelessWidget {
  const PhotoPicker({
    super.key,
    this.bytes,
    this.image = 'barber',
    this.label = 'Select picture',
    this.showExisting = false,
  });
  final Uint8List? bytes;
  final String image, label;
  final bool showExisting;
  @override
  Widget build(BuildContext context) => Column(
    children: [
      GestureDetector(
        onTap: () => pickPhoto(context),
        child: bytes == null && !showExisting
            ? Container(
                height: 76,
                width: 76,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  Icons.add_photo_alternate_outlined,
                  size: 32,
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                ),
              )
            : Photo(image, bytes: bytes, width: 76, height: 76, radius: 6),
      ),
      TextButton(
        onPressed: () => pickPhoto(context),
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            decoration: TextDecoration.underline,
          ),
        ),
      ),
    ],
  );
}

class ServiceEditor extends StatefulWidget {
  const ServiceEditor({super.key, this.service});
  final SalonService? service;
  @override
  State<ServiceEditor> createState() => _ServiceEditorState();
}

class _ServiceEditorState extends State<ServiceEditor> {
  final form = GlobalKey<FormState>();
  late final title = TextEditingController(text: widget.service?.name);
  late final duration = TextEditingController(
    text: widget.service?.duration.toString(),
  );
  late final price = TextEditingController(
    text: widget.service?.price.toString(),
  );
  late final description = TextEditingController(
    text: widget.service?.description,
  );
  late String selectedCategory;
  bool categoryManuallySelected = false;

  @override
  void initState() {
    super.initState();
    if (widget.service != null) {
      selectedCategory = widget.service!.category;
      categoryManuallySelected = true;
    } else {
      selectedCategory = StandardCategories.haircut;
      title.addListener(_onTitleChanged);
    }
  }

  void _onTitleChanged() {
    if (!categoryManuallySelected && title.text.trim().isNotEmpty) {
      final inferred = inferServiceCategory(title.text.trim());
      if (inferred != selectedCategory) {
        setState(() => selectedCategory = inferred);
      }
    }
  }

  @override
  void dispose() {
    title.removeListener(_onTitleChanged);
    for (final c in [title, duration, price, description]) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => LocalView(
    builder: (context, view) => Form(
      key: form,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            widget.service == null ? 'Add Service' : 'Edit Service',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 6),
          const Text(
            'Set a clear name, category, price and duration for your customers.',
          ),
          const SizedBox(height: 20),
          PhotoPicker(
            bytes: view.get<Uint8List?>('photo', widget.service?.bytes),
            label: 'Choose service photo (optional)',
            image: widget.service?.image ?? 'hair',
            showExisting: widget.service != null,
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: title,
            validator: requiredField,
            textCapitalization: TextCapitalization.words,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(
              labelText: 'Service name',
              hintText: 'e.g. Skin Fade Haircut, Beard Grooming',
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'Service Category',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Palette.muted,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: StandardCategories.all.map((cat) {
              final isSelected = selectedCategory == cat.id;
              return ChoiceChip(
                avatar: Icon(
                  cat.icon,
                  size: 16,
                  color: isSelected ? Colors.white : Palette.purple,
                ),
                label: Text(cat.label),
                selected: isSelected,
                selectedColor: Palette.purple,
                labelStyle: TextStyle(
                  fontSize: 12,
                  color: isSelected ? Colors.white : null,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
                onSelected: (val) {
                  if (val) {
                    setState(() {
                      selectedCategory = cat.id;
                      categoryManuallySelected = true;
                    });
                  }
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: duration,
            keyboardType: TextInputType.number,
            validator: (v) => (int.tryParse(v ?? '') ?? 0) <= 0
                ? 'Enter a valid duration'
                : null,
            decoration: const InputDecoration(
              labelText: 'Duration',
              suffixText: 'minutes',
            ),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: price,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            validator: (v) {
              final p = double.tryParse(v ?? '');
              return p == null || !p.isFinite || p <= 0
                  ? 'Enter a valid price'
                  : null;
            },
            decoration: const InputDecoration(
              labelText: 'Price',
              prefixText: 'Rs. ',
            ),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: description,
            decoration: const InputDecoration(
              labelText: 'Description (optional)',
              hintText: 'What is included?',
              alignLabelWithHint: true,
            ),
            maxLines: 2,
          ),
          const SizedBox(height: 22),
          AppButton(
            'Save service',
            onTap: () async {
              if (!form.currentState!.validate()) return;
              if (!await saveAction(
                context,
                SaveService(
                  SalonService(
                    id:
                        widget.service?.id ??
                        DateTime.now().microsecondsSinceEpoch.toString(),
                    name: title.text.trim(),
                    category: selectedCategory,
                    price: double.parse(price.text),
                    duration: int.parse(duration.text),
                    description: description.text.trim(),
                    image: widget.service?.image ?? 'hair',
                    enabled: widget.service?.enabled ?? true,
                    bytes: view.get<Uint8List?>('photo', widget.service?.bytes),
                  ),
                ),
              )) {
                return;
              }
              if (context.mounted) Navigator.pop(context);
            },
          ),
        ],
      ),
    ),
  );
}

class AvailabilityPage extends StatelessWidget {
  const AvailabilityPage({super.key});
  @override
  Widget build(BuildContext context) => LocalView(
    builder: (context, view) {
      final state = context.watch<AppBloc>().state;
      final dark = Theme.of(context).brightness == Brightness.dark;
      final muted = dark ? const Color(0xFFB6B2D5) : const Color(0xFF686079);
      final dates = view.get<List<String>>('dates', state.dates);
      final slots = view.get<List<String>>('slots', state.slots);
      Future<void> addDate() async {
        final now = DateUtils.dateOnly(DateTime.now());
        final date = await showDatePicker(
          context: context,
          initialDate: now,
          firstDate: now,
          lastDate: DateTime(now.year + 2, 12, 31),
        );
        if (date == null || !context.mounted) return;
        change(
          context,
          'dates',
          {...dates, date.toIso8601String().substring(0, 10)}.toList()..sort(),
        );
      }

      Future<void> addTime() async {
        final time = await showTimePicker(
          context: context,
          initialTime: const TimeOfDay(hour: 9, minute: 0),
        );
        if (time == null || !context.mounted) return;
        final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
        final label =
            '${hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')} ${time.period == DayPeriod.am ? 'AM' : 'PM'}';
        change(
          context,
          'slots',
          {...slots, label}.toList()..sort(
            (a, b) => availabilityMinutes(a).compareTo(availabilityMinutes(b)),
          ),
        );
      }

      return Scaffold(
        backgroundColor: dark
            ? const Color(0xFF070916)
            : const Color(0xFFF7F4FC),
        body: DecoratedBox(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: const Alignment(1, -1),
              radius: .85,
              colors: [
                Color(dark ? 0xFF211049 : 0xFFEDE0FF),
                Color(dark ? 0xFF070916 : 0xFFF7F4FC),
              ],
            ),
          ),
          child: SafeArea(
            child: ListView(
              key: const ValueKey('availability-scroll'),
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              children: [
                SizedBox(
                  height: 58,
                  child: Stack(
                    alignment: Alignment.topCenter,
                    children: [
                      Align(
                        alignment: Alignment.topLeft,
                        child: IconButton.filledTonal(
                          tooltip: 'Back',
                          onPressed: () => Navigator.maybePop(context),
                          style: IconButton.styleFrom(
                            backgroundColor: dark
                                ? const Color(0xFF15162C)
                                : const Color(0xFFECE6F7),
                            side: BorderSide(
                              color: dark
                                  ? const Color(0xFF2D2950)
                                  : const Color(0xFFDAD0EA),
                            ),
                          ),
                          icon: const Icon(
                            Icons.chevron_left_rounded,
                            size: 30,
                          ),
                        ),
                      ),
                      Column(
                        children: [
                          const SizedBox(height: 8),
                          const Text(
                            'Availability',
                            style: TextStyle(
                              fontSize: 21,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Container(
                            width: 28,
                            height: 3,
                            decoration: BoxDecoration(
                              color: Palette.purple,
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'When can customers book?',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontSize: 21,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    const ExcludeSemantics(child: _AvailabilityArtwork()),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Choose dates and start times. The same times apply to every selected date.',
                  style: TextStyle(color: muted, fontSize: 14, height: 1.45),
                ),
                const SizedBox(height: 18),
                _AvailabilityPanel(
                  title: 'Selected dates · ${dates.length}',
                  subtitle: 'Tap to remove or add more dates',
                  icon: Icons.calendar_today_outlined,
                  action: 'Add date',
                  onAdd: addDate,
                  child: _AvailabilityChips(
                    values: dates,
                    label: dateLabel,
                    empty: 'No dates selected. Add a date to start accepting bookings.',
                    onRemove: (date) => change(
                      context,
                      'dates',
                      dates.where((d) => d != date).toList(),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                _AvailabilityPanel(
                  title: 'Start times · ${slots.length}',
                  subtitle: 'Tap to remove or add more times',
                  icon: Icons.schedule_rounded,
                  action: 'Add time',
                  onAdd: addTime,
                  child: Column(
                    children: [
                      _AvailabilityChips(
                        values: slots,
                        label: (s) => s,
                        empty: 'Add the times customers can choose for their appointment.',
                        onRemove: (slot) => change(
                          context,
                          'slots',
                          slots.where((s) => s != slot).toList(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: dark
                                ? const Color(0xFFC58AFF)
                                : const Color(0xFF7734B8),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 14,
                            ),
                            side: const BorderSide(color: Palette.purple),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: () async {
                            final selected = await modal<List<String>>(
                              context,
                              SlotSelectionDialog(selected: slots),
                            );
                            if (selected != null && context.mounted) {
                              change(
                                context,
                                'slots',
                                selected..sort(
                                  (a, b) =>
                                      availabilityMinutes(a)
                                          .compareTo(availabilityMinutes(b)),
                                ),
                              );
                            }
                          },
                          child: const Row(
                            children: [
                              Icon(Icons.schedule, size: 22),
                              SizedBox(width: 10),
                              Expanded(child: Text('Choose multiple times')),
                              Icon(Icons.chevron_right),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                _AvailabilityButton(
                  label: state.saving ? 'Saving…' : 'Save availability',
                  large: true,
                  onPressed: state.saving
                      ? null
                      : () async {
                          if (dates.isNotEmpty && slots.isEmpty) {
                            toast(
                              context,
                              'Add at least one start time for your selected dates.',
                            );
                            return;
                          }
                          if (!await saveAction(
                            context,
                            SaveAvailability(dates, slots),
                          )) {
                            return;
                          }
                          if (context.mounted) Navigator.pop(context);
                        },
                ),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    'Remove all dates to pause new bookings. Existing appointments stay scheduled.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: muted, fontSize: 12, height: 1.45),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}

class _AvailabilityArtwork extends StatelessWidget {
  const _AvailabilityArtwork();
  @override
  Widget build(BuildContext context) => SizedBox(
    width: 76,
    height: 76,
    child: Stack(
      children: [
        Transform.rotate(
          angle: .2,
          child: Container(
            margin: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF9E52EE), Color(0xFF3A197C)],
              ),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFB47AFF), width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: Palette.purple.withValues(alpha: .35),
                  blurRadius: 24,
                ),
              ],
            ),
            child: const Center(
              child: Icon(
                Icons.calendar_month_rounded,
                color: Color(0xFFD4ACFF),
                size: 42,
              ),
            ),
          ),
        ),
        Positioned(
          right: 0,
          bottom: 0,
          child: Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: const Color(0xFF39206B),
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFB47AFF), width: 3),
            ),
            child: const Icon(
              Icons.schedule,
              size: 24,
              color: Color(0xFFD4ACFF),
            ),
          ),
        ),
      ],
    ),
  );
}

class _AvailabilityPanel extends StatelessWidget {
  const _AvailabilityPanel({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.action,
    required this.onAdd,
    required this.child,
  });
  final String title, subtitle, action;
  final IconData icon;
  final VoidCallback onAdd;
  final Widget child;
  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: dark ? const Color(0xFF101224) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: dark ? const Color(0xFF292444) : const Color(0xFFE0D6ED),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final compact =
                  constraints.maxWidth < 300 ||
                  MediaQuery.textScalerOf(context).scale(1) > 1.2;
              final heading = Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: dark
                            ? [const Color(0xFF392B68), const Color(0xFF272147)]
                            : [
                                const Color(0xFFEBD9FF),
                                const Color(0xFFF2E9FF),
                              ],
                      ),
                      borderRadius: BorderRadius.circular(11),
                      border: Border.all(
                        color: dark
                            ? const Color(0xFF44346D)
                            : const Color(0xFFDCC4F5),
                      ),
                    ),
                    child: Icon(
                      icon,
                      color: dark
                          ? const Color(0xFFD7A5FF)
                          : const Color(0xFF8135BF),
                      size: 23,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          subtitle,
                          style: TextStyle(
                            fontSize: 11,
                            color: dark
                                ? const Color(0xFFB6B2D5)
                                : const Color(0xFF686079),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
              final button = _AvailabilityButton(
                label: action,
                onPressed: onAdd,
              );
              if (compact) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    heading,
                    const SizedBox(height: 10),
                    Align(alignment: Alignment.centerRight, child: button),
                  ],
                );
              }
              return Row(
                children: [
                  Expanded(child: heading),
                  const SizedBox(width: 8),
                  button,
                ],
              );
            },
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _AvailabilityChips extends StatelessWidget {
  const _AvailabilityChips({
    required this.values,
    required this.label,
    required this.onRemove,
    required this.empty,
  });
  final List<String> values;
  final String Function(String) label;
  final ValueChanged<String> onRemove;
  final String empty;
  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    if (values.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Text(empty),
      );
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns =
            constraints.maxWidth < 260 ||
                MediaQuery.textScalerOf(context).scale(1) > 1.3
            ? 1
            : 2;
        return Wrap(
          spacing: 10,
          runSpacing: 8,
          children: values
              .map(
                (value) => SizedBox(
                  width: (constraints.maxWidth - (columns - 1) * 10) / columns,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: dark
                            ? [const Color(0xFF14172D), const Color(0xFF18172F)]
                            : [
                                const Color(0xFFFAF7FF),
                                const Color(0xFFF4EEFC),
                              ],
                      ),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: dark
                            ? const Color(0xFF595087)
                            : const Color(0xFFD0BEE6),
                      ),
                    ),
                    child: Row(
                      children: [
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            label(value),
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        SizedBox(
                          width: 40,
                          height: 44,
                          child: IconButton(
                            tooltip: 'Remove ${label(value)}',
                            padding: EdgeInsets.zero,
                            icon: const Icon(Icons.close_rounded, size: 18),
                            onPressed: () => onRemove(value),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              )
              .toList(),
        );
      },
    );
  }
}

class _AvailabilityButton extends StatelessWidget {
  const _AvailabilityButton({
    required this.label,
    required this.onPressed,
    this.large = false,
  });
  final String label;
  final VoidCallback? onPressed;
  final bool large;
  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        colors: [Color(0xFFBA4DF4), Color(0xFF8826F7), Color(0xFFB84BF4)],
      ),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: const Color(0xFFCD85FF)),
      boxShadow: [
        BoxShadow(
          color: Palette.purple.withValues(alpha: .22),
          blurRadius: large ? 24 : 12,
          offset: const Offset(0, 5),
        ),
      ],
    ),
    child: TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        foregroundColor: Colors.white,
        disabledForegroundColor: Colors.white70,
        padding: EdgeInsets.symmetric(
          horizontal: large ? 18 : 10,
          vertical: large ? 17 : 10,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: Row(
        mainAxisSize: large ? MainAxisSize.max : MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (!large) ...[
            const Icon(Icons.add, size: 20),
            const SizedBox(width: 5),
          ],
          if (large) const SizedBox(width: 22),
          if (large)
            Expanded(
              child: Text(
                label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            )
          else
            Text(
              label,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
          if (large) const Icon(Icons.chevron_right, size: 22),
        ],
      ),
    ),
  );
}

class AvailabilityDateDialog extends StatefulWidget {
  const AvailabilityDateDialog({super.key, this.date});
  final String? date;
  @override
  State<AvailabilityDateDialog> createState() => _AvailabilityDateDialogState();
}

class _AvailabilityDateDialogState extends State<AvailabilityDateDialog> {
  late DateTime value = widget.date == null
      ? DateTime.now()
      : DateTime.parse(widget.date!);
  String? error;
  @override
  Widget build(BuildContext context) => Column(
    children: [
      Text(
        widget.date == null ? 'Add new Date' : 'Edit available dates',
        style: const TextStyle(fontSize: 18),
      ),
      const SizedBox(height: 18),
      Row(
        children: [
          const Expanded(
            child: Text(
              'Change to',
              style: TextStyle(color: Palette.muted, fontSize: 11),
            ),
          ),
          if (widget.date != null)
            TextButton(
              onPressed: () async {
                if (await confirm(
                      context,
                      'Are you sure you want to delete available date?',
                    ) &&
                    context.mounted) {
                  Navigator.pop(context, 'delete');
                }
              },
              child: const Text(
                'Delete this date',
                style: TextStyle(color: Palette.pink, fontSize: 10),
              ),
            ),
        ],
      ),
      Row(
        children: [
          Expanded(
            child: DropdownButtonFormField<int>(
              key: ValueKey('day-${value.year}-${value.month}-${value.day}'),
              initialValue: value.day,
              isExpanded: true,
              items: List.generate(
                DateTime(value.year, value.month + 1, 0).day,
                (i) => DropdownMenuItem(value: i + 1, child: Text('${i + 1}')),
              ),
              onChanged: (day) => setState(
                () => value = DateTime(value.year, value.month, day!),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: DropdownButtonFormField<int>(
              key: ValueKey('month-${value.year}-${value.month}'),
              initialValue: value.month,
              isExpanded: true,
              items: List.generate(
                12,
                (i) => DropdownMenuItem(value: i + 1, child: Text('${i + 1}')),
              ),
              onChanged: (month) =>
                  setState(() => value = DateTime(value.year, month!, 1)),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: DropdownButtonFormField<int>(
              initialValue: value.year,
              isExpanded: true,
              items: List.generate(
                3,
                (i) => DropdownMenuItem(
                  value: DateTime.now().year + i,
                  child: Text(
                    '${DateTime.now().year + i}',
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
              ),
              onChanged: (year) =>
                  setState(() => value = DateTime(year!, value.month, 1)),
            ),
          ),
        ],
      ),
      if (error != null)
        Padding(
          padding: const EdgeInsets.only(top: 12),
          child: Text(error!, style: const TextStyle(color: Palette.pink)),
        ),
      const SizedBox(height: 24),
      AppButton(
        widget.date == null ? 'Select' : 'Save',
        onTap: () async {
          final now = DateTime.now();
          if (value.isBefore(DateTime(now.year, now.month, now.day))) {
            setState(() => error = 'Choose today or a future date');
            return;
          }
          Navigator.pop(context, value.toIso8601String().substring(0, 10));
        },
      ),
    ],
  );
}

class AvailabilityTimeDialog extends StatefulWidget {
  const AvailabilityTimeDialog({super.key, this.time});
  final String? time;
  @override
  State<AvailabilityTimeDialog> createState() => _AvailabilityTimeDialogState();
}

class _AvailabilityTimeDialogState extends State<AvailabilityTimeDialog> {
  final form = GlobalKey<FormState>();
  late final controller = TextEditingController(
    text: widget.time?.substring(0, 5) ?? '09:00',
  );
  late String period = widget.time?.split(' ').last ?? 'AM';
  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Form(
    key: form,
    child: Column(
      children: [
        const Text('Edit Time Slot', style: TextStyle(fontSize: 18)),
        const SizedBox(height: 16),
        Row(
          children: [
            const Expanded(
              child: Text(
                'Change to',
                style: TextStyle(color: Palette.muted, fontSize: 11),
              ),
            ),
            if (widget.time != null)
              TextButton(
                onPressed: () async {
                  if (await confirm(
                        context,
                        'Are you sure you want to delete time slot?',
                      ) &&
                      context.mounted) {
                    Navigator.pop(context, 'delete');
                  }
                },
                child: const Text(
                  'Delete time slot',
                  style: TextStyle(color: Palette.pink, fontSize: 10),
                ),
              ),
          ],
        ),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: controller,
                keyboardType: TextInputType.datetime,
                decoration: const InputDecoration(hintText: 'hh:mm'),
                validator: (s) =>
                    RegExp(r'^(0[1-9]|1[0-2]):[0-5][0-9]$').hasMatch(s ?? '')
                    ? null
                    : 'Use hh:mm',
              ),
            ),
            const SizedBox(width: 10),
            SizedBox(
              width: 95,
              child: DropdownButtonFormField<String>(
                initialValue: period,
                items: ['AM', 'PM']
                    .map((p) => DropdownMenuItem(value: p, child: Text(p)))
                    .toList(),
                onChanged: (p) => period = p!,
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        AppButton(
          'Save',
          onTap: () async {
            if (form.currentState!.validate()) {
              Navigator.pop(context, '${controller.text} $period');
            }
          },
        ),
      ],
    ),
  );
}

class SlotSelectionDialog extends StatefulWidget {
  const SlotSelectionDialog({super.key, required this.selected});
  final List<String> selected;
  @override
  State<SlotSelectionDialog> createState() => _SlotSelectionDialogState();
}

class _SlotSelectionDialogState extends State<SlotSelectionDialog> {
  late final selected = {...widget.selected};
  late final options = {
    ...widget.selected,
    ...List.generate(24, (i) {
      final hour = 8 + i ~/ 2;
      return '${(hour % 12 == 0 ? 12 : hour % 12).toString().padLeft(2, '0')}:${i.isEven ? '00' : '30'} ${hour < 12 ? 'AM' : 'PM'}';
    }),
  };
  @override
  Widget build(BuildContext context) => Column(
    children: [
      const Text('Select time slots', style: TextStyle(fontSize: 18)),
      const SizedBox(height: 18),
      Wrap(
        spacing: 6,
        runSpacing: 6,
        children: options
            .map(
              (time) => FilterChip(
                label: Text(time, style: const TextStyle(fontSize: 10)),
                selected: selected.contains(time),
                showCheckmark: false,
                selectedColor: Theme.of(context).colorScheme.primaryContainer,
                onSelected: (yes) => setState(() {
                  yes ? selected.add(time) : selected.remove(time);
                }),
              ),
            )
            .toList(),
      ),
      const SizedBox(height: 20),
      AppButton('Save', onTap: () => Navigator.pop(context, selected.toList())),
    ],
  );
}

class ServicesPage extends StatelessWidget {
  const ServicesPage({super.key});
  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppBloc>().state;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final canvas = dark ? const Color(0xFF070A13) : const Color(0xFFF7F4FC);
    return Scaffold(
      backgroundColor: canvas,
      body: CustomScrollView(
        key: const ValueKey('services-scroll'),
        slivers: [
          SliverToBoxAdapter(
            child: Stack(
              children: [
                Positioned.fill(
                  child: Image.asset(
                    'assets/images/barber.jpg',
                    fit: BoxFit.cover,
                    alignment: Alignment.topRight,
                  ),
                ),
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          const Color(0x55070A13),
                          const Color(0x99070A13),
                          canvas,
                        ],
                        stops: const [0, .82, 1],
                      ),
                    ),
                  ),
                ),
                SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        IconButton.filledTonal(
                          tooltip: 'Back',
                          onPressed: () => Navigator.maybePop(context),
                          style: IconButton.styleFrom(
                            backgroundColor: const Color(0xDD1C1C34),
                            foregroundColor: Colors.white,
                            side: const BorderSide(color: Color(0xFF3B3459)),
                          ),
                          icon: const Icon(
                            Icons.chevron_left_rounded,
                            size: 30,
                          ),
                        ),
                        const SizedBox(height: 24),
                        const Text(
                          'Services',
                          style: TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Container(
                          width: 38,
                          height: 3,
                          decoration: BoxDecoration(
                            color: const Color(0xFFBC6AFF),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Add services customers can book, or tap an existing service to update its details.',
                          style: TextStyle(
                            fontSize: 14,
                            height: 1.5,
                            color: dark
                                ? const Color(0xFFBDBBD9)
                                : Colors.white,
                          ),
                        ),
                        const SizedBox(height: 22),
                        Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF9146C8), Color(0xFF5122AE)],
                            ),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFB574F1)),
                            boxShadow: [
                              BoxShadow(
                                color: Palette.purple.withValues(alpha: .18),
                                blurRadius: 20,
                              ),
                            ],
                          ),
                          child: TextButton.icon(
                            onPressed: () =>
                                modal(context, const ServiceEditor()),
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                            icon: const Icon(Icons.add, size: 24),
                            label: const Text(
                              'Add new service',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (state.services.isEmpty)
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: EmptyState(
                  'No services yet. Add your first service above.',
                  icon: Icons.content_cut,
                ),
              ),
            ),
          SliverPadding(
            padding: EdgeInsets.fromLTRB(
              20,
              0,
              20,
              MediaQuery.paddingOf(context).bottom + 24,
            ),
            sliver: SliverList.builder(
              itemCount: state.services.length,
              itemBuilder: (context, index) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _ServiceMenuCard(
                  service: state.services[index],
                  busy: state.saving,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ServiceMenuCard extends StatelessWidget {
  const _ServiceMenuCard({required this.service, required this.busy});
  final SalonService service;
  final bool busy;
  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final muted = dark ? const Color(0xFFBDBBD9) : const Color(0xFF675D78);
    final accent = dark ? const Color(0xFFBE70FA) : Palette.purple;
    void edit() => modal(context, ServiceEditor(service: service));
    final details = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                service.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color: Palette.purple.withValues(alpha: .12),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                StandardCategories.find(service.category).label,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: Palette.purple,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 7),
        Row(
          children: [
            Icon(Icons.schedule, color: accent, size: 15),
            const SizedBox(width: 7),
            Flexible(
              child: Text(
                '${service.duration} min',
                style: TextStyle(color: muted, fontSize: 12),
              ),
            ),
          ],
        ),
        const SizedBox(height: 7),
        Row(
          children: [
            Icon(Icons.sell_rounded, color: accent, size: 15),
            const SizedBox(width: 7),
            Flexible(
              child: Text(
                'Rs. ${service.price.toStringAsFixed(service.price % 1 == 0 ? 0 : 2)}',
                style: TextStyle(color: muted, fontSize: 12),
              ),
            ),
          ],
        ),
        if (!service.enabled)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text('Paused', style: TextStyle(color: muted, fontSize: 12)),
          ),
      ],
    );
    final controls = Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        SizedBox(
          width: 44,
          height: 28,
          child: FittedBox(
            fit: BoxFit.contain,
            child: Semantics(
              label: '${service.enabled ? 'Pause' : 'Enable'} ${service.name}',
              child: Switch(
                value: service.enabled,
                activeThumbColor: Colors.white,
                activeTrackColor: Palette.purple,
                onChanged: busy
                    ? null
                    : (value) => saveAction(
                        context,
                        SetServiceEnabled(service.id, value),
                      ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton.outlined(
              tooltip: 'Edit ${service.name}',
              onPressed: busy ? null : edit,
              style: IconButton.styleFrom(
                minimumSize: const Size(34, 34),
                maximumSize: const Size(34, 34),
                padding: EdgeInsets.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                backgroundColor: dark
                    ? const Color(0xFF1C1B33)
                    : const Color(0xFFF1EAF9),
                side: BorderSide(
                  color: dark
                      ? const Color(0xFF484166)
                      : const Color(0xFFD9CBE8),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              icon: const Icon(Icons.edit_outlined, size: 20),
            ),
            const SizedBox(width: 8),
            PopupMenuButton<String>(
              tooltip: 'More options for ${service.name}',
              enabled: !busy,
              child: Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: dark
                      ? const Color(0xFF1C1B33)
                      : const Color(0xFFF1EAF9),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: dark
                        ? const Color(0xFF484166)
                        : const Color(0xFFD9CBE8),
                  ),
                ),
                child: const Icon(Icons.more_vert, size: 22),
              ),
              onSelected: (action) async {
                if (action == 'edit') {
                  edit();
                  return;
                }
                if (await confirm(
                      context,
                      'Delete "${service.name}"? Existing appointments will keep their service details.',
                    ) &&
                    context.mounted) {
                  await saveAction(context, DeleteService(service.id));
                }
              },
              itemBuilder: (_) => const [
                PopupMenuItem(value: 'edit', child: Text('Edit service')),
                PopupMenuItem(value: 'delete', child: Text('Delete service')),
              ],
            ),
          ],
        ),
      ],
    );
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: dark
              ? [const Color(0xFF0B0E19), const Color(0xFF090B15)]
              : [Colors.white, const Color(0xFFFCFAFF)],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: dark ? const Color(0xFF302C4B) : const Color(0xFFE0D6ED),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compact = MediaQuery.textScalerOf(context).scale(1) > 1.3;
            final info = Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: dark
                          ? const Color(0xFF484166)
                          : const Color(0xFFD9CBE8),
                    ),
                  ),
                  padding: const EdgeInsets.all(1),
                  child: Photo(
                    service.image,
                    bytes: service.bytes,
                    width: constraints.maxWidth < 290 ? 58 : 68,
                    height: constraints.maxWidth < 290 ? 58 : 68,
                    radius: 10,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: GestureDetector(onTap: edit, child: details),
                ),
              ],
            );
            if (compact) {
              return Column(
                children: [
                  info,
                  Align(alignment: Alignment.centerRight, child: controls),
                ],
              );
            }
            return Row(
              children: [
                Expanded(child: info),
                const SizedBox(width: 6),
                controls,
              ],
            );
          },
        ),
      ),
    );
  }
}

class UploadPage extends StatelessWidget {
  const UploadPage({super.key});
  @override
  Widget build(BuildContext context) => LocalView(
    builder: (context, view) {
      final state = context.watch<AppBloc>().state;
      final dark = Theme.of(context).brightness == Brightness.dark;
      final canvas = dark ? const Color(0xFF030B10) : const Color(0xFFF7F4FC);
      final muted = dark ? const Color(0xFFB6BBD1) : const Color(0xFF686079);
      final album = view.get<String>('album', '');
      final photoColumns = MediaQuery.sizeOf(context).width < 350 ? 3 : 4;
      final photoWidth =
          (MediaQuery.sizeOf(context).width - 40 - (photoColumns - 1) * 8) /
          photoColumns;
      final photoHeight = photoWidth / .88;
      final newest = view.get<bool>('newest', true);
      final photos = state.gallery
          .where((p) => album.isEmpty || p.album == album)
          .toList();
      final gallery = newest ? photos.reversed.toList() : photos;
      Future<void> upload([String? target]) async {
        await modal(context, _PortfolioUploadDialog(album: target ?? album));
      }

      return Scaffold(
        backgroundColor: canvas,
        floatingActionButton: FloatingActionButton(
          tooltip: 'Upload photo',
          onPressed: upload,
          backgroundColor: Palette.purple,
          foregroundColor: Colors.white,
          shape: const CircleBorder(),
          child: const Icon(Icons.add_photo_alternate_outlined),
        ),
        body: CustomScrollView(
          key: const ValueKey('portfolio-scroll'),
          slivers: [
            SliverToBoxAdapter(
              child: Stack(
                children: [
                  Positioned.fill(
                    child: Image.asset(
                      'assets/images/hair.jpg',
                      fit: BoxFit.cover,
                      alignment: Alignment.centerRight,
                    ),
                  ),
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            const Color(0x99030B10),
                            const Color(0xCC030B10),
                            canvas,
                          ],
                          stops: const [0, .92, 1],
                        ),
                      ),
                    ),
                  ),
                  SafeArea(
                    bottom: false,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          IconButton.filledTonal(
                            tooltip: 'Back',
                            onPressed: () => Navigator.maybePop(context),
                            style: IconButton.styleFrom(
                              backgroundColor: const Color(0xDD101A2B),
                              foregroundColor: Colors.white,
                              side: const BorderSide(color: Color(0xFF242D44)),
                            ),
                            icon: const Icon(
                              Icons.chevron_left_rounded,
                              size: 30,
                            ),
                          ),
                          const SizedBox(height: 18),
                          const Text(
                            'Portfolio',
                            style: TextStyle(
                              fontSize: 34,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 9),
                          Container(
                            width: 32,
                            height: 3,
                            decoration: BoxDecoration(
                              color: const Color(0xFFB354F4),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          const SizedBox(height: 14),
                          const Text(
                            'Show your best work',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFFD3D6E6),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Organize your photos into albums\nand upload new work.',
                            style: TextStyle(
                              fontSize: 14,
                              height: 1.5,
                              color: dark ? muted : const Color(0xFFD3D6E6),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 14, 12),
                child: Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Albums',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () async {
                        final created = await modal<String>(
                          context,
                          const AlbumDialog(),
                        );
                        if (created != null && context.mounted) {
                          change(context, 'album', created);
                        }
                      },
                      icon: const Icon(Icons.add),
                      label: const Text('Create album'),
                    ),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: state.albums.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 16,
                      ),
                      child: Text(
                        'Create your first album to organize your work.',
                      ),
                    )
                  : SizedBox(
                      height: photoHeight,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        itemCount: state.albums.length,
                        separatorBuilder: (_, _) => const SizedBox(width: 8),
                        itemBuilder: (context, index) {
                          final name = state.albums[index];
                          final items = state.gallery
                              .where((p) => p.album == name)
                              .toList();
                          return SizedBox(
                            width: photoWidth,
                            child: Material(
                              color: dark
                                  ? const Color(0xFF0B1422)
                                  : Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: BorderSide(
                                  color: album == name
                                      ? Palette.purple
                                      : dark
                                      ? const Color(0xFF1E2940)
                                      : const Color(0xFFE0D6ED),
                                ),
                              ),
                              clipBehavior: Clip.antiAlias,
                              child: InkWell(
                                onTap: () => change(
                                  context,
                                  'album',
                                  album == name ? '' : name,
                                ),
                                child: Stack(
                                  fit: StackFit.expand,
                                  children: [
                                    if (items.isEmpty)
                                      Center(
                                        child: Icon(
                                          Icons.photo_library_outlined,
                                          size: 26,
                                          color: muted,
                                        ),
                                      )
                                    else
                                      Photo(
                                        items.last.image,
                                        bytes: items.last.bytes,
                                        radius: 0,
                                      ),
                                    Positioned(
                                      left: 0,
                                      right: 0,
                                      bottom: 0,
                                      child: Container(
                                        padding: const EdgeInsets.fromLTRB(
                                          5,
                                          12,
                                          0,
                                          5,
                                        ),
                                        decoration: const BoxDecoration(
                                          gradient: LinearGradient(
                                            begin: Alignment.topCenter,
                                            end: Alignment.bottomCenter,
                                            colors: [
                                              Colors.transparent,
                                              Color(0xEE07101D),
                                            ],
                                          ),
                                        ),
                                        child: Row(
                                          children: [
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Text(
                                                    name,
                                                    maxLines: 1,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    style: const TextStyle(
                                                      fontSize: 10,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      color: Colors.white,
                                                    ),
                                                  ),
                                                  Text(
                                                    '${items.length} photos',
                                                    maxLines: 1,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    style: const TextStyle(
                                                      fontSize: 9,
                                                      color: Color(0xFFB6BBD1),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            SizedBox(
                                              width: 24,
                                              height: 30,
                                              child: PopupMenuButton<String>(
                                                tooltip: 'Options for $name',
                                                padding: EdgeInsets.zero,
                                                icon: const Icon(
                                                  Icons.more_vert,
                                                  size: 17,
                                                  color: Colors.white,
                                                ),
                                                onSelected: (action) {
                                                  if (action == 'upload') {
                                                    upload(name);
                                                  } else {
                                                    change(
                                                      context,
                                                      'album',
                                                      name,
                                                    );
                                                  }
                                                },
                                                itemBuilder: (_) => const [
                                                  PopupMenuItem(
                                                    value: 'view',
                                                    child: Text('View album'),
                                                  ),
                                                  PopupMenuItem(
                                                    value: 'upload',
                                                    child: Text('Upload photo'),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            '${album.isEmpty ? 'All Photos' : album} · ${gallery.length}',
                            style: const TextStyle(
                              fontSize: 19,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        PopupMenuButton<bool>(
                          tooltip: 'Sort photos',
                          initialValue: newest,
                          onSelected: (value) =>
                              change(context, 'newest', value),
                          itemBuilder: (_) => const [
                            PopupMenuItem(
                              value: true,
                              child: Text('Newest first'),
                            ),
                            PopupMenuItem(
                              value: false,
                              child: Text('Oldest first'),
                            ),
                          ],
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: dark
                                  ? const Color(0xFF0C1525)
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(22),
                              border: Border.all(
                                color: dark
                                    ? const Color(0xFF202A40)
                                    : const Color(0xFFE0D6ED),
                              ),
                            ),
                            child: Row(
                              children: [
                                Text(
                                  newest ? 'Newest first' : 'Oldest first',
                                  style: const TextStyle(fontSize: 11),
                                ),
                                const SizedBox(width: 6),
                                const Icon(Icons.expand_more, size: 18),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (album.isNotEmpty)
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () => change(context, 'album', ''),
                          child: const Text('Clear filter'),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            if (gallery.isEmpty)
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: EmptyState(
                    'Your uploaded work will appear here.',
                    icon: Icons.photo_library_outlined,
                  ),
                ),
              ),
            SliverPadding(
              padding: EdgeInsets.fromLTRB(
                20,
                0,
                20,
                MediaQuery.paddingOf(context).bottom + 96,
              ),
              sliver: SliverGrid.builder(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: photoColumns,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 10,
                  childAspectRatio: .88,
                ),
                itemCount: gallery.length,
                itemBuilder: (context, index) {
                  final item = gallery[index];
                  return Semantics(
                    button: true,
                    label: 'View ${item.album} photo ${index + 1}',
                    child: GestureDetector(
                      onTap: () => modal(
                        context,
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Photo(
                              item.image,
                              bytes: item.bytes,
                              width: double.infinity,
                              height: 300,
                              fit: BoxFit.contain,
                            ),
                            const SizedBox(height: 12),
                            Text(item.album),
                          ],
                        ),
                      ),
                      child: Photo(item.image, bytes: item.bytes, radius: 9),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      );
    },
  );
}

class _PortfolioUploadDialog extends StatelessWidget {
  const _PortfolioUploadDialog({required this.album});
  final String album;
  @override
  Widget build(BuildContext context) => LocalView(
    builder: (context, view) {
      final state = context.watch<AppBloc>().state;
      final selected = view.get<String>('album', album);
      final photo = view.get<Uint8List?>('photo', null);
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Upload photo', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 20),
          PhotoPicker(
            bytes: photo,
            label: photo == null ? 'Choose photo' : 'Change photo',
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            key: ValueKey(selected),
            initialValue: state.albums.contains(selected) ? selected : null,
            isExpanded: true,
            decoration: const InputDecoration(labelText: 'Album'),
            items: state.albums
                .map(
                  (name) => DropdownMenuItem(
                    value: name,
                    child: Text(name, overflow: TextOverflow.ellipsis),
                  ),
                )
                .toList(),
            onChanged: (value) => change(context, 'album', value),
          ),
          TextButton.icon(
            onPressed: () async {
              final created = await modal<String>(context, const AlbumDialog());
              if (created != null && context.mounted) {
                change(context, 'album', created);
              }
            },
            icon: const Icon(Icons.add),
            label: const Text('Create album'),
          ),
          const SizedBox(height: 12),
          AppButton(
            'Upload',
            onTap: photo == null || !state.albums.contains(selected)
                ? null
                : () async {
                    if (!await saveAction(
                      context,
                      AddPhoto(GalleryItem(selected, 'hair', photo)),
                    )) {
                      return;
                    }
                    if (context.mounted) Navigator.pop(context);
                  },
          ),
        ],
      );
    },
  );
}

class AlbumDialog extends StatefulWidget {
  const AlbumDialog({super.key});
  @override
  State<AlbumDialog> createState() => _AlbumDialogState();
}

class _AlbumDialogState extends State<AlbumDialog> {
  final controller = TextEditingController();
  final form = GlobalKey<FormState>();
  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Form(
    key: form,
    child: Column(
      children: [
        const Text('Create Album', style: TextStyle(fontSize: 20)),
        const SizedBox(height: 24),
        TextFormField(
          controller: controller,
          validator: requiredField,
          decoration: const InputDecoration(hintText: 'Enter album name'),
        ),
        const SizedBox(height: 22),
        AppButton(
          'Create',
          onTap: () async {
            if (!form.currentState!.validate()) return;
            if (!await saveAction(context, AddAlbum(controller.text.trim()))) {
              return;
            }
            if (context.mounted) Navigator.pop(context, controller.text.trim());
          },
        ),
      ],
    ),
  );
}

class CustomStylesPage extends StatefulWidget {
  const CustomStylesPage({super.key});

  @override
  State<CustomStylesPage> createState() => _CustomStylesPageState();
}

class _CustomStylesPageState extends State<CustomStylesPage> {
  String selectedCategory = 'All';
  bool isSearching = false;
  final TextEditingController searchController = TextEditingController();

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final allStyles = context.watch<AppBloc>().state.styles;
    final query = searchController.text.trim().toLowerCase();

    final filteredStyles = allStyles.where((style) {
      final matchesCategory =
          selectedCategory == 'All' ||
          style.effectiveCategory.toLowerCase() ==
              selectedCategory.toLowerCase();
      final matchesQuery =
          query.isEmpty ||
          style.name.toLowerCase().contains(query) ||
          style.description.toLowerCase().contains(query);
      return matchesCategory && matchesQuery;
    }).toList();

    final topInset = MediaQuery.paddingOf(context).top;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final heroHeight =
        topInset +
        (MediaQuery.sizeOf(context).height * 0.27).clamp(210.0, 228.0);
    const heroBottomPadding = 16.0;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0A0612) : Palette.canvas,
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: FloatingActionButton(
        tooltip: 'Create Style',
        backgroundColor: Palette.purple,
        foregroundColor: Colors.white,
        shape: const CircleBorder(),
        onPressed: () => _openCreateStyleDialog(context),
        child: const Icon(Icons.add_rounded, size: 30),
      ),
      body: CustomScrollView(
        key: const ValueKey('custom-styles-scroll'),
        physics: const BouncingScrollPhysics(),
        slivers: [
          // The image and the hero content live in the same scroll view. This
          // makes the background move away naturally as the user browses.
          SliverToBoxAdapter(
            child: SizedBox(
              height: heroHeight,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Positioned(
                    // Keep the portrait below the iPhone status bar and notch.
                    top: topInset + 12,
                    right: 0,
                    bottom: heroBottomPadding,
                    width: MediaQuery.sizeOf(context).width * 0.62,
                    child: Image.asset(
                      'assets/images/custom_styles_hero.jpg',
                      fit: BoxFit.contain,
                      alignment: Alignment.bottomRight,
                      errorBuilder: (_, _, _) => Image.asset(
                        'assets/images/barber.jpg',
                        fit: BoxFit.contain,
                        alignment: Alignment.bottomRight,
                      ),
                    ),
                  ),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          const Color(0x12000000),
                          const Color(0x260A0612),
                          (isDark ? const Color(0xFF0A0612) : Palette.canvas)
                              .withValues(alpha: 0.76),
                          isDark ? const Color(0xFF0A0612) : Palette.canvas,
                        ],
                        stops: const [0, 0.62, 0.94, 1],
                      ),
                    ),
                  ),
                  if (!isDark)
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      height: 84,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                            colors: [
                              Palette.canvas,
                              Palette.canvas.withValues(alpha: 0.78),
                              Palette.canvas.withValues(alpha: 0.38),
                              Palette.canvas.withValues(alpha: 0.12),
                              Colors.transparent,
                            ],
                            stops: [0, 0.24, 0.5, 0.78, 1],
                          ),
                        ),
                      ),
                    ),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                        colors: [
                          const Color(0xFF0A0612)
                              .withValues(alpha: isDark ? 0.78 : 0.60),
                          const Color(0xFF0A0612)
                              .withValues(alpha: isDark ? 0.30 : 0.20),
                          Colors.transparent,
                        ],
                        stops: const [0, 0.48, 1],
                      ),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.fromLTRB(
                      20,
                      topInset + 8,
                      20,
                      heroBottomPadding,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Top App Bar with Animated Search Expansion
                        SizedBox(
                          height: 46,
                          child: AnimatedCrossFade(
                            duration: const Duration(milliseconds: 260),
                            firstCurve: Curves.easeOutCubic,
                            secondCurve: Curves.easeInCubic,
                            crossFadeState: isSearching
                                ? CrossFadeState.showSecond
                                : CrossFadeState.showFirst,
                            // Collapsed state: Search icon button on the right (no back button)
                            firstChild: SizedBox(
                              height: 46,
                              child: Align(
                                alignment: Alignment.centerRight,
                                child: _HeroIconButton(
                                  icon: Icons.search_rounded,
                                  onTap: () {
                                    setState(() {
                                      isSearching = true;
                                    });
                                  },
                                ),
                              ),
                            ),
                            // Expanded state: Full-width animated search bar with clear & close buttons
                            secondChild: Container(
                              height: 46,
                              decoration: BoxDecoration(
                                color: isDark
                                    ? const Color(0xFF1B112E)
                                    : Colors.white.withValues(alpha: 0.96),
                                borderRadius: BorderRadius.circular(24),
                                border: Border.all(
                                  color: Palette.purple.withValues(alpha: 0.75),
                                  width: 1.2,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFFA855F7)
                                        .withValues(alpha: 0.35),
                                    blurRadius: 18,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: Row(
                                children: [
                                  const SizedBox(width: 14),
                                  const Icon(
                                    Icons.search_rounded,
                                    color: Palette.purple,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: TextField(
                                      controller: searchController,
                                      autofocus: true,
                                      style: TextStyle(
                                        color: isDark
                                            ? Colors.white
                                            : Palette.ink,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                      ),
                                      onChanged: (_) => setState(() {}),
                                      decoration: InputDecoration(
                                        hintText:
                                            'Search styles by name or details…',
                                        hintStyle: TextStyle(
                                          color: isDark
                                              ? Colors.white54
                                              : Palette.muted,
                                          fontSize: 13,
                                        ),
                                        border: InputBorder.none,
                                        enabledBorder: InputBorder.none,
                                        focusedBorder: InputBorder.none,
                                        isDense: true,
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                              vertical: 12,
                                            ),
                                      ),
                                    ),
                                  ),
                                  if (searchController.text.isNotEmpty)
                                    IconButton(
                                      icon: Icon(
                                        Icons.clear_rounded,
                                        color: isDark
                                            ? Colors.white
                                            : Palette.ink,
                                        size: 18,
                                      ),
                                      splashRadius: 18,
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(
                                        minWidth: 32,
                                        minHeight: 32,
                                      ),
                                      onPressed: () => setState(
                                        () => searchController.clear(),
                                      ),
                                    ),
                                  InkWell(
                                    onTap: () {
                                      setState(() {
                                        isSearching = false;
                                        searchController.clear();
                                      });
                                    },
                                    borderRadius: BorderRadius.circular(20),
                                    child: Container(
                                      margin: const EdgeInsets.only(
                                        right: 6,
                                        left: 2,
                                      ),
                                      padding: const EdgeInsets.all(6),
                                      decoration: BoxDecoration(
                                        color: Palette.lavender,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.close_rounded,
                                        color: Palette.ink,
                                        size: 18,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const Spacer(),
                        const Text(
                          'Custom',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 30,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.6,
                            height: 1.05,
                          ),
                        ),
                        ShaderMask(
                          shaderCallback: (bounds) => const LinearGradient(
                            colors: [
                              Color(0xFFE879F9),
                              Color(0xFFC084FC),
                              Color(0xFFA855F7),
                            ],
                          ).createShader(bounds),
                          child: const Text(
                            'Styles',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 30,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.6,
                              height: 1.1,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'All of your uploaded\nstyles are here',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.78),
                            fontSize: 14,
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 88),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  child: Row(
                    children: [
                      for (final category in [
                        'All',
                        'Haircuts',
                        'Beard',
                        'Styling',
                      ]) ...[
                        _CategoryFilterChip(
                          label: category,
                          isSelected: selectedCategory == category,
                          onTap: () =>
                              setState(() => selectedCategory = category),
                        ),
                        const SizedBox(width: 10),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 22),
                if (filteredStyles.isEmpty)
                  _EmptyStylesCard(
                    searchActive:
                        isSearching && searchController.text.isNotEmpty,
                    selectedCategory: selectedCategory,
                    onReset: () {
                      setState(() {
                        selectedCategory = 'All';
                        searchController.clear();
                        isSearching = false;
                      });
                    },
                    onCreate: () => _openCreateStyleDialog(context),
                  )
                else
                  ...filteredStyles.map(
                    (style) => Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: _StyleCard(
                        style: style,
                        onTap: () => _showStyleOptions(context, style),
                        onMore: () => _showStyleOptions(context, style),
                      ),
                    ),
                  ),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  void _openCreateStyleDialog(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const StyleDialog(),
    );
  }

  void _showStyleOptions(BuildContext context, StyleItem style) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (modalCtx) => _StyleDetailsModal(style: style),
    );
  }
}

class _HeroIconButton extends StatelessWidget {
  const _HeroIconButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(24),
    child: Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withValues(alpha: 0.12),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.18),
          width: 1.2,
        ),
      ),
      child: Icon(icon, color: Colors.white, size: 23),
    ),
  );
}

class _CategoryFilterChip extends StatelessWidget {
  const _CategoryFilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: AnimatedContainer(
        duration: MediaQuery.disableAnimationsOf(context)
            ? Duration.zero
            : const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        height: 44,
        padding: EdgeInsets.symmetric(horizontal: isSelected ? 18 : 17),
        decoration: BoxDecoration(
          gradient: isSelected
              ? const LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [Color(0xFF7136CC), Color(0xFF9A4DE0)],
                )
              : null,
          color: isSelected
              ? null
              : (isDark ? const Color(0xFF19102B) : Colors.white),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF9B5BE8)
                : (isDark ? const Color(0xFF392353) : const Color(0xFFE7E1ED)),
            width: isSelected ? 1.2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Palette.purple.withValues(
                      alpha: isDark ? 0.30 : 0.20,
                    ),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isSelected) ...[
              const Icon(Icons.check_rounded, size: 16, color: Colors.white),
              const SizedBox(width: 5),
            ],
            Text(
              label,
              style: TextStyle(
                color: isSelected
                    ? Colors.white
                    : (isDark
                          ? Colors.white.withValues(alpha: 0.82)
                          : Palette.ink),
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                letterSpacing: 0.05,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Style Card (Deep dark purple container with glowing border, rounded photo,
// title with emoji, subtitle, and 3-dots more menu)
// ---------------------------------------------------------------------------
class _StyleCard extends StatelessWidget {
  const _StyleCard({
    required this.style,
    required this.onTap,
    required this.onMore,
  });

  final StyleItem style;
  final VoidCallback onTap;
  final VoidCallback onMore;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF160E27) : Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: isDark ? const Color(0xFF3B1E66) : const Color(0xFFE8E1EF),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: (isDark ? const Color(0xFF4C1D95) : Palette.ink).withValues(
              alpha: isDark ? 0.22 : 0.07,
            ),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(22),
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Photo(
                    style.image,
                    bytes: style.bytes,
                    width: 74,
                    height: 74,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        style.name,
                        style: TextStyle(
                          color: isDark ? Colors.white : Palette.ink,
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.2,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        style.description,
                        style: TextStyle(
                          color: isDark ? Colors.white60 : Palette.muted,
                          fontSize: 13,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(
                    Icons.more_vert_rounded,
                    color: isDark ? Colors.white70 : Palette.muted,
                    size: 22,
                  ),
                  onPressed: onMore,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Style Details Bottom Sheet (Preview & Delete)
// ---------------------------------------------------------------------------
class _StyleDetailsModal extends StatelessWidget {
  const _StyleDetailsModal({required this.style});
  final StyleItem style;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.fromLTRB(22, 14, 22, 28),
    decoration: BoxDecoration(
      color: Theme.of(context).brightness == Brightness.dark
          ? const Color(0xFF130924)
          : Colors.white,
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      border: const Border(
        top: BorderSide(color: Color(0xFF6B21A8), width: 1.5),
      ),
    ),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(
          child: Container(
            width: 44,
            height: 4,
            decoration: BoxDecoration(
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.white24
                  : const Color(0xFFD6D0DE),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
        const SizedBox(height: 18),
        Center(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: Photo(
              style.image,
              bytes: style.bytes,
              height: 220,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ),
        ),
        const SizedBox(height: 18),
        Row(
          children: [
            Expanded(
              child: Text(
                style.name,
                style: TextStyle(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white
                      : Palette.ink,
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                color: const Color(0xFF7C3AED).withValues(alpha: 0.25),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF9333EA)),
              ),
              child: Text(
                style.effectiveCategory,
                style: const TextStyle(
                  color: Palette.purple,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          style.description,
          style: TextStyle(
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.white70
                : Palette.muted,
            fontSize: 14,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(
              child: TextButton.icon(
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFFFF4D6D),
                  backgroundColor: const Color(0xFFFF4D6D)
                      .withValues(alpha: 0.12),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                    side: BorderSide(
                      color: const Color(0xFFFF4D6D).withValues(alpha: 0.35),
                    ),
                  ),
                ),
                icon: const Icon(Icons.delete_outline_rounded, size: 20),
                label: const Text(
                  'Delete Style',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                onPressed: () {
                  context.read<AppBloc>().add(DeleteStyle(style));
                  Navigator.pop(context);
                  toast(context, 'Style deleted');
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF7C3AED),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  'Close',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ],
    ),
  );
}

// ---------------------------------------------------------------------------
// Empty State Card
// ---------------------------------------------------------------------------
class _EmptyStylesCard extends StatelessWidget {
  const _EmptyStylesCard({
    required this.searchActive,
    required this.selectedCategory,
    required this.onReset,
    required this.onCreate,
  });

  final bool searchActive;
  final String selectedCategory;
  final VoidCallback onReset;
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 34),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF160E27) : Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: isDark ? const Color(0xFF381B61) : const Color(0xFFE8E1EF),
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: const Color(0xFF7C3AED).withValues(alpha: 0.2),
              shape: BoxShape.circle,
              border: Border.all(
                color: const Color(0xFFA855F7).withValues(alpha: 0.4),
              ),
            ),
            child: const Icon(
              Icons.auto_awesome_rounded,
              color: Palette.purple,
              size: 28,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            searchActive
                ? 'No matching styles found'
                : selectedCategory != 'All'
                ? 'No styles in "$selectedCategory"'
                : 'No custom styles yet',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isDark ? Colors.white : Palette.ink,
              fontSize: 17,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            searchActive || selectedCategory != 'All'
                ? 'Try searching with different terms or reset your filters.'
                : 'Add your signature cuts, beard styles and treatments to showcase your craftsmanship.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isDark ? Colors.white60 : Palette.muted,
              fontSize: 13,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 18),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF7C3AED),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            onPressed: searchActive || selectedCategory != 'All'
                ? onReset
                : onCreate,
            child: Text(
              searchActive || selectedCategory != 'All'
                  ? 'Reset Filters'
                  : 'Create First Style',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Professional Animated Create Style Modal Popup
// ---------------------------------------------------------------------------
class StyleDialog extends StatefulWidget {
  const StyleDialog({super.key});

  @override
  State<StyleDialog> createState() => _StyleDialogState();
}

class _StyleDialogState extends State<StyleDialog> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  String selectedCategory = 'Haircuts';
  Uint8List? customPhotoBytes;
  bool isSaving = false;
  bool isPickingImage = false;
  String? photoError;

  @override
  void dispose() {
    nameController.dispose();
    descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    if (isPickingImage || isSaving) return;
    setState(() => isPickingImage = true);
    try {
      final file = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: 1400,
        imageQuality: 85,
      );
      if (file == null) return;
      final bytes = await file.readAsBytes();
      if (!mounted) return;
      final jpeg =
          bytes.length > 3 &&
          bytes[0] == 255 &&
          bytes[1] == 216 &&
          bytes[2] == 255;
      final png =
          bytes.length > 8 &&
          bytes[0] == 137 &&
          bytes[1] == 80 &&
          bytes[2] == 78 &&
          bytes[3] == 71;
      if (bytes.length > 5 * 1024 * 1024 || (!jpeg && !png)) {
        setState(
          () => photoError = 'Choose a JPEG or PNG image smaller than 5 MB.',
        );
        return;
      }
      // Verify that the selected file is a decodable image before publishing.
      final image = await decodeImageFromList(bytes);
      image.dispose();
      if (!mounted) return;
      setState(() {
        customPhotoBytes = bytes;
        photoError = null;
      });
    } catch (_) {
      if (mounted) {
        setState(
          () => photoError =
              'Unable to open this photo. Please try another image.',
        );
      }
    } finally {
      if (mounted) setState(() => isPickingImage = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.88,
        ),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF130924) : Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          border: const Border(
            top: BorderSide(color: Color(0xFF7C3AED), width: 1.5),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag Handle
            const SizedBox(height: 12),
            Container(
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? Colors.white24 : const Color(0xFFD6D0DE),
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Title Bar
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 14, 16, 12),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF7C3AED).withValues(alpha: 0.25),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFFA855F7).withValues(alpha: 0.5),
                      ),
                    ),
                    child: const Icon(
                      Icons.content_cut_rounded,
                      color: Palette.purple,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Create New Style',
                      style: TextStyle(
                        color: isDark ? Colors.white : Palette.ink,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.close_rounded,
                      color: isDark ? Colors.white70 : Palette.muted,
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            Divider(
              color: isDark ? const Color(0xFF261545) : const Color(0xFFE8E1EF),
              height: 1,
            ),

            // Form inputs in scrollable view
            Expanded(
              child: Form(
                key: formKey,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(22, 16, 22, 24),
                  children: [
                    // Style Picture Preview & Picker
                    Text(
                      'Style Picture',
                      style: TextStyle(
                        color: isDark ? Colors.white : Palette.ink,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Main photo container
                    GestureDetector(
                      onTap: isSaving || isPickingImage ? null : _pickImage,
                      child: Container(
                        height: 160,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: const Color(0xFF7C3AED)
                                .withValues(alpha: 0.6),
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF9333EA)
                                  .withValues(alpha: 0.2),
                              blurRadius: 16,
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(19),
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              if (customPhotoBytes != null)
                                Image.memory(
                                  customPhotoBytes!,
                                  fit: BoxFit.cover,
                                )
                              else
                                Container(
                                  color: isDark
                                      ? const Color(0xFF1B112E)
                                      : const Color(0xFFF7F5FA),
                                  child: const Center(
                                    child: Icon(
                                      Icons.add_photo_alternate_outlined,
                                      size: 48,
                                      color: Palette.purple,
                                    ),
                                  ),
                                ),
                              Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      Colors.transparent,
                                      Colors.black.withValues(alpha: 0.7),
                                    ],
                                  ),
                                ),
                              ),
                              Positioned(
                                bottom: 12,
                                left: 14,
                                right: 14,
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: const BoxDecoration(
                                        color: Color(0xFF7C3AED),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.camera_alt_rounded,
                                        color: Colors.white,
                                        size: 16,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        isPickingImage
                                            ? 'Opening photo…'
                                            : customPhotoBytes == null
                                            ? 'Tap to upload from Gallery'
                                            : 'Tap to change photo',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    Text(
                      photoError ?? 'Upload your own style photo (JPEG or PNG, up to 5 MB).',
                      style: TextStyle(
                        color: photoError != null
                            ? Theme.of(context).colorScheme.error
                            : Palette.muted,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Category Selection
                    Text(
                      'Category',
                      style: TextStyle(
                        color: isDark ? Colors.white : Palette.ink,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: ['Haircuts', 'Beard', 'Styling'].map((cat) {
                        final isCat = selectedCategory == cat;
                        return InkWell(
                          onTap: () => setState(() => selectedCategory = cat),
                          borderRadius: BorderRadius.circular(20),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 7,
                            ),
                            decoration: BoxDecoration(
                              color: isCat
                                  ? const Color(0xFF7C3AED)
                                  : (isDark
                                        ? const Color(0xFF1B112E)
                                        : Colors.white),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: isCat
                                    ? const Color(0xFFC084FC)
                                    : (isDark
                                          ? const Color(0xFF381B61)
                                          : const Color(0xFFE8E1EF)),
                              ),
                            ),
                            child: Text(
                              cat,
                              style: TextStyle(
                                color: isCat
                                    ? Colors.white
                                    : (isDark ? Colors.white70 : Palette.ink),
                                fontSize: 13,
                                fontWeight: isCat
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),

                    const SizedBox(height: 20),

                    // Style Name
                    Row(
                      children: [
                        Text(
                          'Style Name',
                          style: TextStyle(
                            color: isDark ? Colors.white : Palette.ink,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const Spacer(),
                        Wrap(
                          spacing: 4,
                          children: ['✂️', '🧼', '🧔', '💈', '✨'].map((emoji) {
                            return InkWell(
                              onTap: () {
                                setState(() {
                                  nameController.text =
                                      '${nameController.text} $emoji'.trim();
                                });
                              },
                              borderRadius: BorderRadius.circular(10),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 2,
                                ),
                                child: Text(
                                  emoji,
                                  style: const TextStyle(fontSize: 16),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: nameController,
                      style: TextStyle(
                        color: isDark ? Colors.white : Palette.ink,
                        fontSize: 15,
                      ),
                      validator: (v) => v == null || v.trim().isEmpty
                          ? 'Please enter style name'
                          : null,
                      decoration: InputDecoration(
                        hintText: 'e.g. Cutting ✂️, Fade Cut',
                        hintStyle: TextStyle(
                          color: isDark ? Colors.white54 : Palette.muted,
                          fontSize: 14,
                        ),
                        prefixIcon: const Icon(
                          Icons.content_cut_rounded,
                          color: Color(0xFFC084FC),
                          size: 20,
                        ),
                        filled: true,
                        fillColor: isDark
                            ? const Color(0xFF1B112E)
                            : const Color(0xFFF7F5FA),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(
                            color: isDark
                                ? const Color(0xFF381B61)
                                : const Color(0xFFE8E1EF),
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(
                            color: isDark
                                ? const Color(0xFF381B61)
                                : const Color(0xFFE8E1EF),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(
                            color: Color(0xFFA855F7),
                            width: 1.5,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Description
                    Text(
                      'Description',
                      style: TextStyle(
                        color: isDark ? Colors.white : Palette.ink,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: descriptionController,
                      maxLines: 2,
                      style: TextStyle(
                        color: isDark ? Colors.white : Palette.ink,
                        fontSize: 14,
                      ),
                      validator: (v) => v == null || v.trim().isEmpty
                          ? 'Please enter description'
                          : null,
                      decoration: InputDecoration(
                        hintText:
                            'e.g. Smoothly, Natural texture, Wonderful 😊',
                        hintStyle: TextStyle(
                          color: isDark ? Colors.white54 : Palette.muted,
                          fontSize: 13,
                        ),
                        prefixIcon: const Icon(
                          Icons.notes_rounded,
                          color: Color(0xFFC084FC),
                          size: 20,
                        ),
                        filled: true,
                        fillColor: isDark
                            ? const Color(0xFF1B112E)
                            : const Color(0xFFF7F5FA),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(
                            color: isDark
                                ? const Color(0xFF381B61)
                                : const Color(0xFFE8E1EF),
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(
                            color: isDark
                                ? const Color(0xFF381B61)
                                : const Color(0xFFE8E1EF),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(
                            color: Color(0xFFA855F7),
                            width: 1.5,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 28),

                    // Submit Button
                    InkWell(
                      onTap: isSaving || isPickingImage ? null : _submitStyle,
                      borderRadius: BorderRadius.circular(28),
                      child: Container(
                        height: 54,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [
                              Color(0xFF6B21A8),
                              Color(0xFF9333EA),
                              Color(0xFFA855F7),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(28),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF9333EA)
                                  .withValues(alpha: 0.45),
                              blurRadius: 20,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Center(
                          child: isSaving
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text(
                                  'Publish Style',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.3,
                                  ),
                                ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submitStyle() async {
    if (isSaving || isPickingImage) return;
    final valid = formKey.currentState!.validate();
    if (customPhotoBytes == null) {
      setState(
        () => photoError = 'Please upload a style photo before publishing.',
      );
      return;
    }
    if (!valid) return;
    setState(() => isSaving = true);

    try {
      final style = StyleItem(
        nameController.text.trim(),
        descriptionController.text.trim(),
        'custom',
        customPhotoBytes,
        selectedCategory,
      );

      final success = await saveAction(context, AddStyle(style));
      if (!mounted) return;
      if (success) {
        Navigator.pop(context);
        toast(context, 'Style published successfully!');
      }
    } finally {
      if (mounted) setState(() => isSaving = false);
    }
  }
}
