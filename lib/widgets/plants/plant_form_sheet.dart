import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:verdant/data/care_schedule.dart';
import 'package:verdant/data/owned_plants.dart';
import 'package:verdant/models/plant_details.dart';
import 'package:verdant/widgets/components/filter_chip.dart';

/// Adds a plant (when [plant] is null) or edits its name and room.
/// Resolves to the saved plant, or null when dismissed.
Future<OwnedPlant?> showPlantFormSheet(
  BuildContext context, {
  OwnedPlant? plant,
}) {
  return showModalBottomSheet<OwnedPlant>(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Theme.of(context).scaffoldBackgroundColor,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (_) => _PlantFormSheet(plant: plant),
  );
}

class _PlantFormSheet extends StatefulWidget {
  const _PlantFormSheet({this.plant});

  final OwnedPlant? plant;

  @override
  State<_PlantFormSheet> createState() => _PlantFormSheetState();
}

class _PlantFormSheetState extends State<_PlantFormSheet> {
  static const _suggestedRooms = [
    'Living room',
    'Bedroom',
    'Kitchen',
    'Study',
    'Bathroom',
    'Balcony',
  ];

  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _room;
  PlantSpecies _species = PlantSpecies.monstera;
  bool _nameEdited = false;

  bool get _isEdit => widget.plant != null;

  @override
  void initState() {
    super.initState();
    final p = widget.plant;
    _name = TextEditingController(text: p?.name ?? _species.commonName);
    _room = TextEditingController(text: p?.room ?? '');
  }

  @override
  void dispose() {
    _name.dispose();
    _room.dispose();
    super.dispose();
  }

  void _pickSpecies(PlantSpecies species) {
    setState(() {
      _species = species;
      if (!_nameEdited) {
        _name.text = species == PlantSpecies.other ? '' : species.commonName;
      }
    });
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    final OwnedPlant saved;
    if (_isEdit) {
      saved = widget.plant!;
      plantCollection.update(saved, name: _name.text, room: _room.text);
    } else {
      saved = plantCollection.add(
        name: _name.text,
        room: _room.text,
        species: _species,
      );
    }
    final messenger = ScaffoldMessenger.of(context);
    Navigator.of(context).pop(saved);
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          _isEdit
              ? '${saved.name} updated.'
              : '${saved.name} joined your collection. First watering '
                    '${formatDue(careSchedule.firstFrom(DateTime.now(), plantId: saved.id)!.due).toLowerCase()}.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final rooms = {...plantCollection.rooms, ..._suggestedRooms}.toList();

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: scheme.outlineVariant,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                _isEdit ? 'Edit your plant' : 'Welcome a new plant',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontSize: 23,
                  letterSpacing: -0.5,
                  color: scheme.onSurface,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                _isEdit ? 'Give it a new name or move it to another room.' : 'We’ll set up a watering reminder that suits its species.',
                style: theme.textTheme.bodySmall?.copyWith(
                  fontSize: 12,
                  height: 1.5,
                  color: scheme.onSurfaceVariant,
                ),
              ),
              if (!_isEdit) ...[
                const SizedBox(height: 20),
                _Label('Which plant is it?'),
                const SizedBox(height: 10),
                SizedBox(
                  height: 132,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: PlantSpecies.catalog.length + 1,
                    separatorBuilder: (_, _) => const SizedBox(width: 10),
                    itemBuilder: (context, i) {
                      final s = i < PlantSpecies.catalog.length
                          ? PlantSpecies.catalog[i]
                          : PlantSpecies.other;
                      return _SpeciesOption(
                        species: s,
                        selected: s == _species,
                        onTap: () => _pickSpecies(s),
                      );
                    },
                  ),
                ),
              ],
              const SizedBox(height: 20),
              _Label('Name'),
              const SizedBox(height: 9),
              TextFormField(
                controller: _name,
                textCapitalization: TextCapitalization.words,
                onChanged: (_) => _nameEdited = true,
                decoration: _decoration(context, 'e.g. Monstera'),
                validator: (v) =>
                    (v ?? '').trim().isEmpty ? 'Give your plant a name.' : null,
              ),
              const SizedBox(height: 16),
              _Label('Room'),
              const SizedBox(height: 9),
              TextFormField(
                controller: _room,
                textCapitalization: TextCapitalization.sentences,
                decoration: _decoration(context, 'e.g. Living room'),
                validator: (v) =>
                    (v ?? '').trim().isEmpty ? 'Where does it live?' : null,
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final r in rooms)
                    AppFilterChip(
                      label: r,
                      selected: _room.text.trim() == r,
                      onTap: () => setState(() => _room.text = r),
                    ),
                ],
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: _save,
                icon: Icon(
                  _isEdit ? LucideIcons.check : LucideIcons.plus,
                  size: 18,
                ),
                label: Text(
                  _isEdit ? 'Save changes' : 'Add to my plants',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: scheme.primary,
                  foregroundColor: scheme.surfaceContainerLow,
                  minimumSize: const Size.fromHeight(52),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static InputDecoration _decoration(BuildContext context, String hint) {
    final scheme = Theme.of(context).colorScheme;
    OutlineInputBorder border(Color c) => OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: c),
    );
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(fontSize: 13, color: scheme.onSurfaceVariant),
      filled: true,
      fillColor: scheme.surface,
      isDense: true,
      contentPadding: const EdgeInsets.all(15),
      border: border(scheme.outlineVariant),
      enabledBorder: border(scheme.outlineVariant),
      focusedBorder: border(scheme.primary),
      errorBorder: border(scheme.error),
      focusedErrorBorder: border(scheme.error),
    );
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Text(
      text,
      style: theme.textTheme.labelMedium?.copyWith(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: theme.colorScheme.onSurface,
      ),
    );
  }
}

class _SpeciesOption extends StatelessWidget {
  const _SpeciesOption({
    required this.species,
    required this.selected,
    required this.onTap,
  });

  final PlantSpecies species;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Semantics(
      button: true,
      selected: selected,
      label: species.commonName,
      child: GestureDetector(
        onTap: onTap,
        child: SizedBox(
          width: 92,
          child: Column(
            children: [
              Container(
                width: 92,
                height: 96,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: selected ? scheme.primary : Colors.transparent,
                    width: 2,
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.asset(species.imagePath, fit: BoxFit.cover),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                species.commonName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelSmall?.copyWith(
                  fontSize: 11,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                  color: selected ? scheme.onSurface : scheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
