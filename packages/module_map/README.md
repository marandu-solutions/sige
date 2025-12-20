# Module Map

Módulo de mapas personalizável para o projeto SIGE.

## Configuração

Este módulo utiliza `google_maps_flutter`. Para funcionar corretamente, é necessário configurar a API Key do Google Maps no projeto principal (Runner).

### Android
No arquivo `android/app/src/main/AndroidManifest.xml`, adicione dentro da tag `<application>`:

```xml
<meta-data
    android:name="com.google.android.geo.API_KEY"
    android:value="SUA_API_KEY_AQUI"/>
```

### iOS
No arquivo `ios/Runner/AppDelegate.swift` (ou Objective-C), configure a API Key:

```swift
GMSServices.provideAPIKey("SUA_API_KEY_AQUI")
```

E no `Info.plist`, adicione permissões de localização se necessário:
- `NSLocationWhenInUseUsageDescription`
- `NSLocationAlwaysUsageDescription`

## Uso

### MapScreen
Uma tela completa com gerenciamento de estado via Riverpod.

```dart
import 'package:module_map/module_map.dart';

// Navegar para a tela
Navigator.push(context, MaterialPageRoute(builder: (_) => MapScreen()));
```

### CustomMapWidget
Um widget isolado para ser embutido em outras telas.

```dart
CustomMapWidget(
  points: myPointsList,
  onTap: (latLng) {
    print('Tapped at $latLng');
  },
  onPointTap: (point) {
    print('Selected: ${point.title}');
  },
)
```
