import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:grocery_delivery_boy/common/models/api_response_model.dart';
import 'package:grocery_delivery_boy/common/reposotories/tracker_repo.dart';

class TrackerProvider extends ChangeNotifier {
  final TrackerRepo? trackerRepo;
  TrackerProvider({required this.trackerRepo});

  // Location tracking state
  Position? _lastPosition;
  StreamSubscription<Position>? _positionStream;
  bool get isPositionStreamActive => _positionStream != null;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  int? _currentId;
  int? get currentId => _currentId;


  void startListenCurrentLocation() {
    if (_positionStream == null) {

      _positionStream = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          distanceFilter: 10,
          accuracy: LocationAccuracy.high,
        ),
      ).listen((Position position) async {
        if (_lastPosition != null) {
          double distance = Geolocator.distanceBetween(
            _lastPosition!.latitude,
            _lastPosition!.longitude,
            position.latitude,
            position.longitude,
          );
          if (distance > 10) {

            ApiResponseModel apiResponse = await trackerRepo!.addTrack(lat: position.latitude, long: position.longitude);

            if (kDebugMode) {
              print("=================Location update status on server =============== ${apiResponse.response?.statusCode}");
            }

          }
        }
        _lastPosition = position; // Update last known position

      });

      if (kDebugMode) {
        print("================Location tracking started.=====================");
      }
    }
  }


  void stopListening() {
    _positionStream?.cancel();
    _positionStream = null;
    if (kDebugMode) {
      print("=====================Location tracking stopped.=============================");
    }
  }

  Future<Position> getUserCurrentLocation() async {
    _isLoading = true;
    notifyListeners();

    final Position position = await Geolocator.getCurrentPosition(
      locationSettings: LocationSettings(accuracy: LocationAccuracy.high),
    );

    _isLoading = false;
    notifyListeners();

    return position;
  }

  void onChangeCurrentId(int index)  {
    _currentId = index;
    notifyListeners();
  }
}
