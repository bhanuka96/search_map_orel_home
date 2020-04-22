part of search_map_place;

class Place {
  Place(
    Geocoding geocode, {
    this.description,
    this.placeId,
    this.types,
  }) {
    this._geocode = geocode;
  }

  Place.fromJSON(place, Geocoding geocode) {
    try {
      this.description = place["description"];
      this.placeId = place["place_id"];
      this.types = place["types"];

      this._geocode = geocode;
      this.fullJSON = place;
    } catch (e) {
      print("The argument you passed for Place is not compatible.");
    }
  }

  String description;

  String placeId;

  List<dynamic> types;

  var fullJSON;

  Geocoding _geocode;

  Geolocation _geolocation;

  Future<Geolocation> get geolocation async {
    if (this._geolocation == null) {
      this._geolocation = await _geocode.getGeolocation(description);
      return _geolocation;
    }
    return _geolocation;
  }
}
