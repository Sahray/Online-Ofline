//modelo de las imagenes que se subiran a firebase
class Images {
  int id;
  String datoUnicRepor;
  String imagen;
  int tienda;

  Images(
      {required this.id,
      required this.datoUnicRepor,
      required this.imagen,
      required this.tienda});

  Map<String, dynamic> toMap() {
    return {
      'id_img': id,
      'dato_unico_rep': datoUnicRepor,
      'imagen': imagen,
      'id_tienda': tienda,
    };
  }

  factory Images.fromMap(Map<String, dynamic> map) {
    return Images(
      id: map['id_img'] ?? "",
      datoUnicRepor: map['dato_unico_rep'] ?? "",
      imagen: map['imagen'] ?? "",
      tienda: map['tienda'] ?? "",
    );
  }
}
