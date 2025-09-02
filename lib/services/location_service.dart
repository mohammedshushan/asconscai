import 'package:geocoding/geocoding.dart';

class LocationService {
  Future<String> getAddressFromCoordinates(double latitude, double longitude) async {
    try {
      // تحديد اللغة للعناوين لتكون بالعربية
      List<Placemark> placemarks = await placemarkFromCoordinates(latitude, longitude);

      if (placemarks.isNotEmpty) {
        final Placemark place = placemarks[0];
        // بناء العنوان بشكل تفصيلي ومقروء
        return "${place.street ?? ''}, ${place.subLocality ?? ''}, ${place.locality ?? ''}, ${place.administrativeArea ?? ''}";
      } else {
        return "الموقع غير متوفر حالياً";
      }
    } catch (e) {
      // في حالة حدوث خطأ، يتم إرجاع رسالة واضحة
      return "لا يمكن تحديد الموقع";
    }
  }
}