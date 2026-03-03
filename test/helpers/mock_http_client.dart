import 'package:http/http.dart' as http;
import 'package:mockito/annotations.dart';

/// Mock annotation for http.Client
/// Run: flutter pub run build_runner build
@GenerateMocks([http.Client])
void main() {}
