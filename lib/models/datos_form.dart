import 'dart:convert';

class Datos {
  String nomDep;
  String claveUbi;
  String nomUbi;
  String claveProb;
  String nomProb;
  String otroProb;
  String nomMat;
  String cantMat;
  String nomObr;
  String otroObr;
  String cantObr;

  Datos({
    required this.nomDep,
    required this.claveUbi,
    required this.nomUbi,
    required this.claveProb,
    required this.nomProb,
    required this.otroProb,
    required this.nomMat,
    required this.cantMat,
    required this.nomObr,
    required this.otroObr,
    required this.cantObr,
  });

  factory Datos.fromJson(String str) => Datos.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory Datos.fromMap(Map<String, dynamic> json) => Datos(
        nomDep: json["nom_dep"],
        claveUbi: json["clave_ubi"],
        nomUbi: json["nom_ubi"],
        claveProb: json["clave_prob"],
        nomProb: json["nom_prob"],
        otroProb: json["otro_prob"],
        nomMat: json["nom_mat"],
        cantMat: json["cant_mat"],
        nomObr: json["nom_obr"],
        otroObr: json["otro_obr"],
        cantObr: json["cant_obr"],
      );

  Map<String, dynamic> toMap() => {
        "nomDep": nomDep,
        "claveUbi": claveUbi,
        "nomUbi": nomUbi,
        "claveProb": claveProb,
        "nomProb": nomProb,
        "otroProb": otroProb,
        "nomMat": nomMat,
        "cantMat": cantMat,
        "nomObr": nomObr,
        "otroObr": otroObr,
        "cantObr": cantObr,
      };
}
