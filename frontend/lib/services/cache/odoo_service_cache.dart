import 'package:mobaitec_decision_making/models/OdooSIGModel.dart';

class OdooSIGCacheService {
  static final OdooSIGCacheService _instance = OdooSIGCacheService._internal();
  factory OdooSIGCacheService() => _instance;
  OdooSIGCacheService._internal();

  List<OdooSIGCompte> _comptes = [];
  List<OdooSIGCompte> get comptes => _comptes;
  void setComptes(List<OdooSIGCompte> comptes) {
    _comptes = comptes;
  }

  bool get isEmpty => _comptes.isEmpty;

  void clear() {
    _comptes = [];
  }
}
