import 'dart:convert';
import 'package:http/http.dart' as http;

void main() async {
  final ibgeCode = '2403608';
  final url = Uri.parse(
      'https://servicodados.ibge.gov.br/api/v3/malhas/municipios/$ibgeCode?formato=application/vnd.geo+json');
  
  print('Fetching $url...');
  final response = await http.get(url);

  if (response.statusCode == 200) {
    print('Response OK. Body length: ${response.body.length}');
    final data = json.decode(response.body);
    print('Type: ${data['type']}');

    if (data['type'] == 'FeatureCollection') {
      for (var feature in data['features']) {
        parseFeature(feature);
      }
    } else if (data['type'] == 'Feature') {
      parseFeature(data);
    }
  } else {
    print('Error: ${response.statusCode}');
  }
}

void parseFeature(Map<String, dynamic> feature) {
  final geometry = feature['geometry'];
  if (geometry == null) {
    print('Geometry is null');
    return;
  }
  print('Geometry Type: ${geometry['type']}');

  if (geometry['type'] == 'Polygon') {
    processPolygon(geometry['coordinates']);
  } else if (geometry['type'] == 'MultiPolygon') {
    for (var polygonCoords in geometry['coordinates']) {
      processPolygon(polygonCoords);
    }
  }
}

void processPolygon(List<dynamic> coordinates) {
  if (coordinates.isEmpty) {
    print('Coordinates empty');
    return;
  }
  
  print('Processing Polygon ring 0. Length: ${coordinates[0].length}');
  // GeoJSON Polygon coordinates: [ [ [lon, lat], [lon, lat], ... ], [hole] ]
  // We only take the first ring (outer boundary)
  
  var firstPoint = coordinates[0][0];
  print('First point (Raw GeoJSON [Lon, Lat]): $firstPoint');
  
  double lat = firstPoint[1].toDouble();
  double lng = firstPoint[0].toDouble();
  
  print('Converted to LatLng: Lat: $lat, Lng: $lng');
}
