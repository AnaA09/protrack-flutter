import '../models/instrument.dart';
import 'api_service.dart';

class InstrumentService {
  final ApiService _apiService;

  InstrumentService(this._apiService);

  Future<List<Instrument>> getAllInstruments() async {
    final response = await _apiService.get('/instruments');
    return (response['Items'] as List)
        .map((item) => Instrument.fromJson(item))
        .toList();
  }

  Future<Instrument> getInstrument(String instrumentId) async {
    final response = await _apiService.get('/instruments/$instrumentId');
    return Instrument.fromJson(response);
  }

  Future<Instrument> createInstrument(Instrument instrument) async {
    final response =
        await _apiService.post('/instruments', instrument.toJson());
    return Instrument.fromJson(response);
  }

  Future<Instrument> updateInstrument(
      String instrumentId, Instrument instrument) async {
    final response = await _apiService.put(
        '/instruments/$instrumentId', instrument.toJson());
    return Instrument.fromJson(response);
  }

  Future<void> deleteInstrument(String instrumentId) async {
    await _apiService.delete('/instruments/$instrumentId');
  }

  Future<List<Instrument>> searchInstrumentsByName(String name) async {
    final response = await _apiService.get('/instruments/search/$name');
    return (response as List).map((item) => Instrument.fromJson(item)).toList();
  }
}
