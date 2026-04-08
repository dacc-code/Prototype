class Detection {
  final String label;
  final double confidence;
  final double x;
  final double y;
  final double width;
  final double height;
  final String? imageBase64;

  Detection({
    required this.label,
    required this.confidence,
    required this.x,
    required this.y,
    required this.width,
    required this.height,
    this.imageBase64,
  });

  Map<String, dynamic> toMap() {
    return {
      'label': label,
      'confidence': confidence,
      'x': x,
      'y': y,
      'width': width,
      'height': height,
    };
  }

  Map<String, dynamic> toApiPayload() {
    return {
      'label': label,
      'label_name': _getLabelName(label),
      'confidence': confidence,
      'dispositivo_id': 'app-movil',
    };
  }

  static String _getLabelName(String label) {
    final names = {
      '0': 'Dieback-Gall',
      '1': 'Lumnitzera-Littorea',
      '2': 'Lumnitzera-Littorea-Flower',
      '3': 'Rhizophora-Apiculata',
      '4': 'Rhizophora-Apiculata-Propagule',
      '5': 'Scyphiphora-Hydrophyllacea',
      '6': 'Scyphiphora-Hydrophyllacea-Flower',
      '7': 'Sonneratia-Alba',
      '8': 'Sonneratia-Alba-Flower',
      '9': 'Black Spots',
      '10': 'Brown Spots',
      '11': 'White Spots',
    };
    return names[label] ?? label;
  }
}

class DiseaseInfo {
  final String id;
  final String name;
  final String description;
  final String action;
  final String severity;

  const DiseaseInfo({
    required this.id,
    required this.name,
    required this.description,
    required this.action,
    required this.severity,
  });

  static const Map<String, DiseaseInfo> diseases = {
    'Dieback-Gall': DiseaseInfo(
      id: '0',
      name: 'Dieback-Gall',
      description: 'Enfermedad que causa muerte regresiva y agallas en ramas de mangle',
      action: 'Podar ramas afectadas y aplicar tratamiento antifúngico',
      severity: 'alta',
    ),
    'Lumnitzera-Littorea': DiseaseInfo(
      id: '1',
      name: 'Lumnitzera Littorea',
      description: 'Especie de mangle Laguncularia racemosa - saludable',
      action: 'Monitoreo regular',
      severity: 'ninguna',
    ),
    'Lumnitzera-Littorea-Flower': DiseaseInfo(
      id: '2',
      name: 'Lumnitzera Littorea en Floración',
      description: 'Mangle en período de floración - saludable',
      action: 'Conservar el área de crecimiento',
      severity: 'ninguna',
    ),
    'Rhizophora-Apiculata': DiseaseInfo(
      id: '3',
      name: 'Rhizophora Apiculata',
      description: 'Especie de mangle rojo - saludable',
      action: 'Monitoreo regular',
      severity: 'ninguna',
    ),
    'Rhizophora-Apiculata-Propagule': DiseaseInfo(
      id: '4',
      name: 'Rhizophora Apiculata Propágulo',
      description: 'Mangle rojo en etapa de propagación - saludable',
      action: 'Proteger la zona de reproducción',
      severity: 'ninguna',
    ),
    'Scyphiphora-Hydrophyllacea': DiseaseInfo(
      id: '5',
      name: 'Scyphiphora Hydrophyllacea',
      description: 'Especie de mangle - saludable',
      action: 'Monitoreo regular',
      severity: 'ninguna',
    ),
    'Scyphiphora-Hydrophyllacea-Flower': DiseaseInfo(
      id: '6',
      name: 'Scyphiphora Hydrophyllacea Flor',
      description: 'Mangle en floración - saludable',
      action: 'Conservar el área',
      severity: 'ninguna',
    ),
    'Sonneratia-Alba': DiseaseInfo(
      id: '7',
      name: 'Sonneratia Alba',
      description: 'Especie de mangle blanco - saludable',
      action: 'Monitoreo regular',
      severity: 'ninguna',
    ),
    'Sonneratia-Alba-Flower': DiseaseInfo(
      id: '8',
      name: 'Sonneratia Alba Floración',
      description: 'Mangle blanco en floración - saludable',
      action: 'Proteger zona de floración',
      severity: 'ninguna',
    ),
    'Black Spots': DiseaseInfo(
      id: '9',
      name: 'Manchas Negras',
      description: 'Infección fúngica que causa manchas negras en hojas de mangle',
      action: 'Aplicar fungicida y mejorar circulación de aire',
      severity: 'media',
    ),
    'Brown Spots': DiseaseInfo(
      id: '10',
      name: 'Manchas Marrones',
      description: 'Enfermedad que causa manchas marrones en las hojas',
      action: 'Retirar hojas afectadas y aplicar tratamiento antifúngico',
      severity: 'media',
    ),
    'White Spots': DiseaseInfo(
      id: '11',
      name: 'Manchas Blancas',
      description: 'Infección bacterial o fungal que causa manchas blancas',
      action: 'Aplicar tratamiento antibacterial y monitorear',
      severity: 'media',
    ),
  };

  static DiseaseInfo getInfo(String label) {
    return diseases[label] ?? DiseaseInfo(
      id: label,
      name: label,
      description: 'Información no disponible',
      action: 'Consultar con experto',
      severity: 'desconocida',
    );
  }
}
