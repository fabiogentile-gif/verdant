import 'package:flutter/material.dart';
import 'package:verdant/models/plant_details.dart';
import 'package:verdant/widgets/components/plant_card.dart';

class OwnedPlant {
  const OwnedPlant({
    required this.name,
    required this.room,
    required this.species,
    required this.image,
    required this.status,
    required this.statusLabel,
    required this.scheduleLabel,
    this.details,
  });

  final String name;
  final String room;
  final String species;
  final ImageProvider image;
  final PlantStatus status;
  final String statusLabel;
  final String scheduleLabel;
  final PlantDetails? details;
}

const ownedPlants = [
  OwnedPlant(
    name: 'Monstera',
    room: 'Living room',
    species: 'Monstera deliciosa',
    image: AssetImage('assets/images/owned/monstera_deliciosa.png'),
    status: PlantStatus.needsCare,
    statusLabel: 'Needs water',
    scheduleLabel: 'Water today · 9:00 AM',
    details: monsteraDetails,
  ),
  OwnedPlant(
    name: 'Rubber Plant',
    room: 'Bedroom',
    species: 'Ficus elastica',
    image: AssetImage('assets/images/owned/rubber_plant.png'),
    status: PlantStatus.healthy,
    statusLabel: 'Healthy',
    scheduleLabel: 'Next watering · Sun, Nov 8',
  ),
  OwnedPlant(
    name: 'Golden Pothos',
    room: 'Kitchen',
    species: 'Epipremnum aureum',
    image: AssetImage('assets/images/owned/golden_pothos.png'),
    status: PlantStatus.healthy,
    statusLabel: 'Healthy',
    scheduleLabel: 'Next watering · Mon, Nov 9',
  ),
  OwnedPlant(
    name: 'Peace Lily',
    room: 'Study',
    species: 'Spathiphyllum',
    image: AssetImage('assets/images/owned/peace_lily.png'),
    status: PlantStatus.healthy,
    statusLabel: 'Healthy',
    scheduleLabel: 'Next watering · Sat, Nov 7',
  ),
];