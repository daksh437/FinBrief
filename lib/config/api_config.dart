class ApiConfig {
  ApiConfig._();

  /// Deployed backend (Render, Singapore region).
  ///
  /// Note the free instance sleeps after ~15 minutes of inactivity, so the
  /// first request after an idle period can take 30-50s to come back — which
  /// is why ApiService allows a generous timeout.
  static const String baseUrl = 'https://finbrief-backend.onrender.com';

  /// Local backend for development. Swap [baseUrl] to this when running
  /// `npm start` in backend/ — 10.0.2.2 is the emulator's alias for the host
  /// machine, while a physical phone needs this PC's Wi-Fi LAN address and an
  /// inbound firewall rule for the port.
  static const String localBaseUrl = 'http://192.168.1.7:10000';
}
