import 'dart:math';

import 'package:flutter/widgets.dart';
import 'package:verdant/data/care_schedule.dart';
import 'package:verdant/data/storage.dart';
import 'package:verdant/models/plant_details.dart';
import 'package:verdant/l10n/i18n.dart';

/// A plant in the user's collection.
class OwnedPlant {
  OwnedPlant({
    required this.id,
    required String name,
    required String room,
    required this.species,
    required this.imagePath,
    required this.addedOn,
  }) : _name = I18n.sourceIn(name, _speciesNames),
       _room = I18n.sourceIn(room, _roomNames);

  static const _speciesNames = {
    'Monstera',
    'Rubber Plant',
    'Golden Pothos',
    'Peace Lily',
  };
  static const _roomNames = {
    'Living room',
    'Bedroom',
    'Kitchen',
    'Study',
    'Bathroom',
    'Balcony',
  };

  final String id;
  String _name;
  String _room;

  /// A species' common name is translated; a name the user chose is not.
  String get name => _speciesNames.contains(_name) ? _name.tr : _name;
  set name(String value) => _name = I18n.sourceIn(value, _speciesNames);

  /// Suggested rooms are saved in English, so they follow the language.
  String get room => _roomNames.contains(_room) ? _room.tr : _room;
  set room(String value) => _room = I18n.sourceIn(value, _roomNames);

  /// Latin name, e.g. "Monstera deliciosa" (see [PlantSpecies.catalog]).
  final String species;
  final String imagePath;
  final DateTime addedOn;

  ImageProvider get image => imagePath.startsWith('http')
      ? NetworkImage(imagePath)
      : AssetImage(imagePath) as ImageProvider;

  PlantSpecies get speciesInfo => PlantSpecies.byLatinName(species);
  PlantGuide get guide => speciesInfo.guide;

  Map<String, Object?> toJson() => {
    'id': id,
    'name': _name,
    'room': _room,
    'species': species,
    'imagePath': imagePath,
    'addedOn': addedOn.toIso8601String(),
  };

  factory OwnedPlant.fromJson(Map json) => OwnedPlant(
    id: json['id'] as String,
    name: json['name'] as String,
    room: json['room'] as String,
    species: json['species'] as String,
    imagePath: json['imagePath'] as String,
    addedOn: DateTime.parse(json['addedOn'] as String),
  );
}

/// The user's plants, saved on the device.
class PlantCollection extends ChangeNotifier {
  PlantCollection() {
    _plants.addAll(_seed());
  }

  final List<OwnedPlant> _plants = [];

  List<OwnedPlant> get plants => List.unmodifiable(_plants);

  OwnedPlant? byId(String id) {
    for (final p in _plants) {
      if (p.id == id) return p;
    }
    return null;
  }

  /// Rooms in use, in the order they first appear.
  List<String> get rooms => _plants.map((p) => p.room).toSet().toList();

  OwnedPlant add({
    required String name,
    required String room,
    required PlantSpecies species,
    DateTime? now,
  }) {
    final plant = OwnedPlant(
      id: '${DateTime.now().microsecondsSinceEpoch}-${Random().nextInt(1 << 20)}',
      name: name.trim(),
      room: room.trim(),
      species: species.latinName,
      imagePath: species.imagePath,
      addedOn: now ?? DateTime.now(),
    );
    _plants.add(plant);
    _save();
    careSchedule.addDefaultPlan(plant, everyDays: species.waterEveryDays);
    return plant;
  }

  void update(OwnedPlant plant, {String? name, String? room}) {
    if (name != null && name.trim().isNotEmpty) plant.name = name.trim();
    if (room != null && room.trim().isNotEmpty) plant.room = room.trim();
    _save();
  }

  void remove(OwnedPlant plant) {
    _plants.removeWhere((p) => p.id == plant.id);
    _save();
    careSchedule.removePlant(plant.id);
  }

  void restore() {
    final json = Storage.read(StorageKeys.plants);
    if (json is! List) return;
    _plants
      ..clear()
      ..addAll(json.whereType<Map>().map(OwnedPlant.fromJson));
    notifyListeners();
  }

  void reset() {
    _plants
      ..clear()
      ..addAll(_seed());
    notifyListeners();
  }

  void _save() {
    Storage.write(StorageKeys.plants, _plants.map((p) => p.toJson()).toList());
    notifyListeners();
  }

  static List<OwnedPlant> _seed() => [
    OwnedPlant(
      id: 'monstera',
      name: 'Monstera',
      room: 'Living room',
      species: PlantSpecies.monstera.latinName,
      imagePath: PlantSpecies.monstera.imagePath,
      addedOn: DateTime(2026, 5, 16),
    ),
    OwnedPlant(
      id: 'rubber-plant',
      name: 'Rubber Plant',
      room: 'Bedroom',
      species: PlantSpecies.rubberPlant.latinName,
      imagePath: PlantSpecies.rubberPlant.imagePath,
      addedOn: DateTime(2026, 3, 2),
    ),
    OwnedPlant(
      id: 'golden-pothos',
      name: 'Golden Pothos',
      room: 'Kitchen',
      species: PlantSpecies.goldenPothos.latinName,
      imagePath: PlantSpecies.goldenPothos.imagePath,
      addedOn: DateTime(2026, 7, 21),
    ),
    OwnedPlant(
      id: 'peace-lily',
      name: 'Peace Lily',
      room: 'Study',
      species: PlantSpecies.peaceLily.latinName,
      imagePath: PlantSpecies.peaceLily.imagePath,
      addedOn: DateTime(2026, 9, 8),
    ),
  ];
}

/// The user's plant collection shared by every page.
final plantCollection = PlantCollection();

/// Shortcut for the current list of plants.
List<OwnedPlant> get ownedPlants => plantCollection.plants;
