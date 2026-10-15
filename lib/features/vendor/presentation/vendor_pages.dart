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
                  color: const Color(0xFFA5A6B0),
                  borderRadius: BorderRadius.circular(5),
                ),
                child: const Icon(Icons.add, size: 42, color: Colors.white),
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
    text: widget.service?.price.toStringAsFixed(0),
  );
  late final description = TextEditingController(
    text: widget.service?.description,
  );
  @override
  void dispose() {
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
        children: [
          Text(
            widget.service == null ? 'Add Service' : 'Edit Service',
            style: const TextStyle(fontSize: 19),
          ),
          const SizedBox(height: 20),
          PhotoPicker(
            bytes: view.get<Uint8List?>('photo', widget.service?.bytes),
            label: 'Change Service Picture',
            image: widget.service?.image ?? 'hair',
            showExisting: widget.service != null,
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: title,
            validator: requiredField,
            decoration: const InputDecoration(hintText: 'Enter Service Name'),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: duration,
            keyboardType: TextInputType.number,
            validator: (v) => (int.tryParse(v ?? '') ?? 0) <= 0
                ? 'Enter a valid duration'
                : null,
            decoration: const InputDecoration(
              hintText: 'Enter Service Duration (minutes)',
            ),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: price,
            keyboardType: TextInputType.number,
            validator: (v) {
              final p = double.tryParse(v ?? '');
              return p == null || !p.isFinite || p <= 0
                  ? 'Enter a valid price'
                  : null;
            },
            decoration: const InputDecoration(hintText: 'Enter Price'),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: description,
            decoration: const InputDecoration(hintText: 'Service Description'),
            maxLines: 2,
          ),
          const SizedBox(height: 22),
          AppButton(
            'Save',
            onTap: () {
              if (!form.currentState!.validate()) return;
              context.read<AppBloc>().add(
                SaveService(
                  SalonService(
                    id:
                        widget.service?.id ??
                        DateTime.now().microsecondsSinceEpoch.toString(),
                    name: title.text.trim(),
                    price: double.parse(price.text),
                    duration: int.parse(duration.text),
                    description: description.text.trim(),
                    image: widget.service?.image ?? 'hair',
                    bytes: view.get<Uint8List?>('photo', widget.service?.bytes),
                  ),
                ),
              );
              Navigator.pop(context);
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
      final bloc = context.watch<AppBloc>();
      final dates = view.get<List<String>>('dates', bloc.state.dates);
      final slots = view.get<List<String>>('slots', bloc.state.slots);
      Future<void> editDate([String? old]) async {
        final result = await modal<String>(
          context,
          AvailabilityDateDialog(date: old),
        );
        if (result == null || !context.mounted) return;
        change(
          context,
          'dates',
          {
            ...dates.where((d) => d != old),
            if (result != 'delete') result,
          }.toList()..sort(),
        );
      }

      Future<void> editSlot([String? old]) async {
        final result = await modal<String>(
          context,
          AvailabilityTimeDialog(time: old),
        );
        if (result == null || !context.mounted) return;
        change(
          context,
          'slots',
          {
            ...slots.where((s) => s != old),
            if (result != 'delete') result,
          }.toList(),
        );
      }

      return Screen(
        title: 'Edit Available Dates',
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            const SizedBox(height: 16),
            Text(
              dates.isEmpty
                  ? 'Available Dates'
                  : dateLabel(dates.first)
                        .substring(dateLabel(dates.first).indexOf(' ') + 1),
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 24),
            const Row(
              children: [
                Expanded(
                  child: Text(
                    'Available Dates',
                    style: TextStyle(color: Palette.muted, fontSize: 11),
                  ),
                ),
                Text('Tap to edit', style: TextStyle(fontSize: 11)),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: dates.map((date) {
                final d = DateTime.parse(date);
                return InkWell(
                  onTap: () => editDate(date),
                  child: Container(
                    width: 44,
                    height: 54,
                    decoration: BoxDecoration(
                      color: date == dates.first
                          ? Palette.orchid
                          : Palette.muted,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '${d.day}',
                          style: const TextStyle(color: Colors.white),
                        ),
                        Text(
                          const [
                            'Mon',
                            'Tue',
                            'Wed',
                            'Thu',
                            'Fri',
                            'Sat',
                            'Sun',
                          ][d.weekday - 1],
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: editDate,
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Add new available date'),
              ),
            ),
            const SizedBox(height: 22),
            const Row(
              children: [
                Expanded(
                  child: Text(
                    'Available Time Slots',
                    style: TextStyle(color: Palette.muted, fontSize: 11),
                  ),
                ),
                Text('Tap to edit', style: TextStyle(fontSize: 11)),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: slots
                  .map(
                    (time) => ActionChip(
                      label: Text(
                        time,
                        style: const TextStyle(
                          fontSize: 10,
                          color: Colors.white,
                        ),
                      ),
                      backgroundColor: Palette.muted,
                      side: BorderSide.none,
                      onPressed: () => editSlot(time),
                    ),
                  )
                  .toList(),
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () async {
                  final selected = await modal<List<String>>(
                    context,
                    SlotSelectionDialog(selected: slots),
                  );
                  if (selected != null && context.mounted) {
                    change(context, 'slots', selected);
                  }
                },
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Add new time slot'),
              ),
            ),
            const SizedBox(height: 26),
            AppButton(
              'Save',
              onTap: () {
                bloc.add(SaveAvailability(dates, slots));
                Navigator.pop(context);
              },
            ),
            const SizedBox(height: 12),
            const Text(
              'Session availability applies to every selected date.',
              style: TextStyle(color: Palette.muted, fontSize: 10),
            ),
          ],
        ),
      );
    },
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
        onTap: () {
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
          onTap: () {
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
                selectedColor: Palette.lavender,
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

class UploadPage extends StatelessWidget {
  const UploadPage({super.key});
  @override
  Widget build(BuildContext context) => LocalView(
    builder: (context, view) {
      final state = context.watch<AppBloc>().state;
      return Screen(
        title: 'Upload Picture',
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            const SizedBox(height: 15),
            PhotoPicker(
              bytes: view.get<Uint8List?>('photo', null),
              label: 'Edit Picture',
            ),
            const SizedBox(height: 25),
            const Text(
              'Select Album',
              style: TextStyle(color: Palette.muted, fontSize: 12),
            ),
            const SizedBox(height: 14),
            ...state.albums.map(
              (a) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Surface(
                  onTap: () => change(context, 'album', a),
                  child: Row(
                    children: [
                      Icon(
                        view.get('album', '') == a
                            ? Icons.check_circle
                            : Icons.photo_library_outlined,
                        color: Palette.purple,
                        size: 22,
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Text(a, style: const TextStyle(fontSize: 12)),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () => modal(context, const AlbumDialog()),
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Add new album'),
              ),
            ),
            const SizedBox(height: 32),
            AppButton(
              'Upload',
              onTap:
                  view.get<Uint8List?>('photo', null) == null ||
                      view.get('album', '').isEmpty
                  ? null
                  : () {
                      context.read<AppBloc>().add(
                        AddPhoto(
                          GalleryItem(
                            view.get('album', ''),
                            'barber',
                            view.get<Uint8List?>('photo', null),
                          ),
                        ),
                      );
                      Navigator.pop(context);
                    },
            ),
          ],
        ),
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
          onTap: () {
            if (!form.currentState!.validate()) return;
            context.read<AppBloc>().add(AddAlbum(controller.text.trim()));
            Navigator.pop(context);
          },
        ),
      ],
    ),
  );
}

class CustomStylesPage extends StatelessWidget {
  const CustomStylesPage({super.key});
  @override
  Widget build(BuildContext context) => Screen(
    title: 'Custom Styles',
    subtitle: 'All of your uploaded styles are here',
    child: ListView(
      padding: const EdgeInsets.symmetric(horizontal: 22),
      children: [
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: () => modal(context, const StyleDialog()),
            child: const Text('Create Style'),
          ),
        ),
        ...context.watch<AppBloc>().state.styles.map(
          (s) => Padding(
            padding: const EdgeInsets.only(bottom: 13),
            child: Surface(
              child: Row(
                children: [
                  Photo(
                    s.image,
                    bytes: s.bytes,
                    height: 46,
                    width: 46,
                    radius: 7,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          s.name,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          s.description,
                          style: const TextStyle(
                            fontSize: 10,
                            color: Palette.muted,
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
      ],
    ),
  );
}

class StyleDialog extends StatefulWidget {
  const StyleDialog({super.key});
  @override
  State<StyleDialog> createState() => _StyleDialogState();
}

class _StyleDialogState extends State<StyleDialog> {
  final name = TextEditingController(), description = TextEditingController();
  final form = GlobalKey<FormState>();
  @override
  void dispose() {
    name.dispose();
    description.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => LocalView(
    builder: (context, view) => Form(
      key: form,
      child: Column(
        children: [
          const Text('Create Style', style: TextStyle(fontSize: 20)),
          const SizedBox(height: 22),
          PhotoPicker(
            bytes: view.get<Uint8List?>('photo', null),
            label: 'Select Style Picture',
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: name,
            validator: requiredField,
            decoration: const InputDecoration(hintText: 'Enter Style Name'),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: description,
            validator: requiredField,
            decoration: const InputDecoration(hintText: 'Enter Description'),
            maxLines: 2,
          ),
          const SizedBox(height: 22),
          AppButton(
            'Create Style',
            onTap: () {
              if (!form.currentState!.validate()) return;
              if (view.get<Uint8List?>('photo', null) == null) {
                toast(context, 'Select a style picture first.');
                return;
              }
              context.read<AppBloc>().add(
                AddStyle(
                  StyleItem(
                    name.text.trim(),
                    description.text.trim(),
                    'hair',
                    view.get<Uint8List?>('photo', null),
                  ),
                ),
              );
              Navigator.pop(context);
            },
          ),
        ],
      ),
    ),
  );
}
