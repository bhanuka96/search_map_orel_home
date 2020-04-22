part of search_map_place;

class Geolocation {
  Geolocation(this._coordinates, this._bounds);
  bool foundLocality = false;
  Geolocation.fromJSON(geolocationJSON) {
    this._coordinates = geolocationJSON["results"][0]["geometry"]["location"];
    this._bounds = geolocationJSON["results"][0]["geometry"]["viewport"];
    this.fullJSON = geolocationJSON["results"][0];

    geolocationJSON['results'].forEach((value){
      value['address_components'].forEach((address){
        address['types'].forEach((type){
          if(type == 'locality'){
            this.cityComponent = address;
            foundLocality = true;
          }else{
            if(type == 'administrative_area_level_3' && !foundLocality){
              this.cityComponent = address;
            }
          }
        });
      });
    });
  }

  var _coordinates;

  var _bounds;

  var fullJSON;

  var cityComponent;

  get coordinates {
    try {
      return LatLng(_coordinates["lat"], _coordinates["lng"]);
    } catch (e) {
      print(
          "You appear to not have the `google_maps_flutter` package installed. In this case, this method will return an object with the latitude and longitude");
      return _coordinates;
    }
  }

  get bounds {
    try {
      return LatLngBounds(
        southwest:
            LatLng(_bounds["southwest"]["lat"], _bounds["southwest"]["lng"]),
        northeast:
            LatLng(_bounds["northeast"]["lat"], _bounds["northeast"]["lng"]),
      );
    } catch (e) {
      print(
          "You appear to not have the `google_maps_flutter` package installed. In this case, this method will return an object with southwest and northeast bounds");
      return _bounds;
    }
  }
}
