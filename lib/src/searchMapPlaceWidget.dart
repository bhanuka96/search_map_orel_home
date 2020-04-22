part of search_map_place;

class SearchMapPlaceWidget extends StatefulWidget {
  SearchMapPlaceWidget({
    @required this.apiKey,
    @required this.textEditingController,
    this.placeholder = 'Search',
    this.icon = Icons.search,
    this.hasClearButton = true,
    this.clearIcon = Icons.clear,
    this.iconColor = Colors.blue,
    this.onSelected,
    this.onSearch,
    this.language = 'en',
    this.location,
    this.radius,
    this.strictBounds = false,
    this.placeType,
    this.darkMode = false,
    this.key,
  })  : assert((location == null && radius == null) || (location != null && radius != null)),
        super(key: key);

  final Key key;

  final String apiKey;

  final String placeholder;

  final void Function(Place place) onSelected;

  final void Function(Place place) onSearch;


  final String language;

  final LatLng location;

  final int radius;

  final bool strictBounds;

  final PlaceType placeType;

  final IconData icon;

  final bool hasClearButton;

  final IconData clearIcon;

  final Color iconColor;

  final bool darkMode;
  
  final TextEditingController textEditingController;

  @override
  _SearchMapPlaceWidgetState createState() => _SearchMapPlaceWidgetState();
}

class _SearchMapPlaceWidgetState extends State<SearchMapPlaceWidget> with TickerProviderStateMixin {
//  TextEditingController widget.textEditingController = TextEditingController();
  AnimationController _animationController;
  // SearchContainer height.
  Animation _containerHeight;
  // Place options opacity.
  Animation _listOpacity;

  List<dynamic> _placePredictions = [];
  bool _isEditing = false;
  Geocoding geocode;

  String _tempInput = "";
  String _currentInput = "";

  FocusNode _fn = FocusNode();

  CrossFadeState _crossFadeState;

  @override
  void initState() {
    geocode = Geocoding(apiKey: widget.apiKey, language: widget.language);
    _animationController = AnimationController(vsync: this, duration: Duration(milliseconds: 500));
    _containerHeight = Tween<double>(begin: 55, end: 364).animate(
      CurvedAnimation(
        curve: Interval(0.0, 0.5, curve: Curves.easeInOut),
        parent: _animationController,
      ),
    );
    _listOpacity = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(
      CurvedAnimation(
        curve: Interval(0.5, 1.0, curve: Curves.easeInOut),
        parent: _animationController,
      ),
    );

    widget.textEditingController.addListener(_autocompletePlace);
    customListener();

    if (widget.hasClearButton) {
      _fn.addListener(() async {
        if (_fn.hasFocus)
          setState(() => _crossFadeState = CrossFadeState.showSecond);
        else
          setState(() => _crossFadeState = CrossFadeState.showFirst);
      });
      _crossFadeState = CrossFadeState.showFirst;
    }

    super.initState();
  }

  @override
  Widget build(BuildContext context) => Container(
        width: MediaQuery.of(context).size.width * 0.9,
        child: _searchContainer(
          child: _searchInput(context),
        ),
      );

  /*
  WIDGETS
  */
  Widget _searchContainer({Widget child}) {
    return AnimatedBuilder(
        animation: _animationController,
        builder: (context, _) {
          return Container(
            height: _containerHeight.value,
            decoration: _containerDecoration(),
            child: Column(
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.only(left: 12.0, right: 12.0, top: 4),
                  child: child,
                ),
                if (_placePredictions.length > 0)
                  Opacity(
                    opacity: _listOpacity.value,
                    child: Column(
                      children: <Widget>[
                        for (var prediction in _placePredictions)
                          _placeOption(Place.fromJSON(prediction, geocode)),
                      ],
                    ),
                  ),
              ],
            ),
          );
        });
  }

  Widget _searchInput(BuildContext context) {
    return Center(
      child: Row(
        children: <Widget>[
          Icon(Icons.location_on,color: widget.iconColor),
          Container(width: 5),
          Expanded(
            child: TextField(
              decoration: _inputStyle(),
              controller: widget.textEditingController,
              onSubmitted: (_) => _selectPlace(),
              onEditingComplete: _selectPlace,
              autofocus: false,
              focusNode: _fn,
              style: TextStyle(
                fontSize: MediaQuery.of(context).size.width * 0.04,
                color: widget.darkMode ? Colors.grey[100] : Colors.grey[850],
              ),
            ),
          ),
          Container(width: 15),
          if (widget.hasClearButton)
            GestureDetector(
              onTap: () {
                if (_crossFadeState == CrossFadeState.showSecond) widget.textEditingController.clear();
              },
              // child: Icon(_inputIcon, color: this.widget.iconColor),
              child: AnimatedCrossFade(
                crossFadeState: _crossFadeState,
                duration: Duration(milliseconds: 300),
                firstChild: Icon(widget.icon, color: widget.iconColor),
                secondChild: Icon(Icons.clear, color: widget.iconColor),
              ),
            ),
          if (!widget.hasClearButton) Icon(widget.icon, color: widget.iconColor)
        ],
      ),
    );
  }

  Widget _placeOption(Place prediction) {
    String place = prediction.description;

    return MaterialButton(
      padding: EdgeInsets.symmetric(horizontal: 5, vertical: 3),
      onPressed: () => _selectPlace(prediction: prediction),
      child: ListTile(
        title: Text(
          place.length < 45 ? "$place" : "${place.replaceRange(45, place.length, "")} ...",
          style: TextStyle(
            fontSize: MediaQuery.of(context).size.width * 0.04,
            color: widget.darkMode ? Colors.grey[100] : Colors.grey[850],
          ),
          maxLines: 1,
        ),
        contentPadding: EdgeInsets.symmetric(
          horizontal: 10,
          vertical: 0,
        ),
      ),
    );
  }

  /*
  STYLING
  */
  InputDecoration _inputStyle() {
    return InputDecoration(
      hintText: this.widget.placeholder,
      border: InputBorder.none,
      contentPadding: EdgeInsets.symmetric(horizontal: 0.0, vertical: 0.0),
      hintStyle: TextStyle(
        color: widget.darkMode ? Colors.grey[100] : Colors.grey[850],
      ),
    );
  }

  BoxDecoration _containerDecoration() {
    return BoxDecoration(
      color: widget.darkMode ? Colors.grey[800] : Colors.white,
      borderRadius: BorderRadius.all(Radius.circular(6.0)),
      boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 20, spreadRadius: 10)],
    );
  }


  void _autocompletePlace() async {
    if (_fn.hasFocus) {
      setState(() {
        _currentInput = widget.textEditingController.text;
        _isEditing = true;
      });

      widget.textEditingController.removeListener(_autocompletePlace);

      if (_currentInput.length == 0) {
        if (!_containerHeight.isDismissed) _closeSearch();
        widget.textEditingController.addListener(_autocompletePlace);
        return;
      }

      if (_currentInput == _tempInput) {
        final predictions = await _makeRequest(_currentInput);
        await _animationController.animateTo(0.5);
        setState(() => _placePredictions = predictions);
        await _animationController.forward();

        widget.textEditingController.addListener(_autocompletePlace);
        return;
      }

      Future.delayed(Duration(milliseconds: 500), () {
        widget.textEditingController.addListener(_autocompletePlace);
        if (_isEditing == true) _autocompletePlace();
      });
    }
  }

  Future<dynamic> _makeRequest(input) async {
    String url =
        "https://maps.googleapis.com/maps/api/place/autocomplete/json?input=$input&key=${widget.apiKey}&language=${widget.language}";
    if (widget.location != null && widget.radius != null) {
      url += "&location=${widget.location.latitude},${widget.location.longitude}&radius=${widget.radius}";
      if (widget.strictBounds) {
        url += "&strictbounds";
      }
      if (widget.placeType != null) {
        url += "&types=${widget.placeType.apiString}";
      }
    }

    final response = await http.get(url);
    final json = JSON.jsonDecode(response.body);

    if (json["error_message"] != null) {
      var error = json["error_message"];
      if (error == "This API project is not authorized to use this API.")
        error += " Make sure the Places API is activated on your Google Cloud Platform";
      throw Exception(error);
    } else {
      final predictions = json["predictions"];
      return predictions;
    }
  }

  /// Will be called when a user selects one of the Place options
  void _selectPlace({Place prediction}) async {
    if (prediction != null) {
      widget.textEditingController.value = TextEditingValue(
        text: prediction.description,
        selection: TextSelection.collapsed(
          offset: prediction.description.length,
        ),
      );
    } else {
      await Future.delayed(Duration(milliseconds: 500));
    }

    // Makes animation
    _closeSearch();

    // Calls the `onSelected` callback
    if (prediction is Place) widget.onSelected(prediction);
  }

  void _closeSearch() async {
    if (!_animationController.isDismissed) await _animationController.animateTo(0.5);
    _fn.unfocus();
    setState(() {
      _placePredictions = [];
      _isEditing = false;
    });
    _animationController.reverse();
    widget.textEditingController.addListener(_autocompletePlace);
  }

  void customListener() {
    Future.delayed(Duration(milliseconds: 500), () {
      if(!mounted) return;
      setState(() => _tempInput = widget.textEditingController.text);
      customListener();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    widget.textEditingController.dispose();
    _fn.dispose();
    super.dispose();
  }
}
