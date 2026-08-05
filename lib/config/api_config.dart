class ApiConfig {
  ApiConfig._();

  // TODO: switch to the deployed Render URL once the backend is deployed
  // (see backend/README.md — same pattern as Insta Flow's ApiService.baseUrl).
  //
  // 10.0.2.2 only works on the Android *emulator* (it's an alias for the
  // host machine's localhost) — it does NOT work on a real phone. For a
  // physical device, the phone and this PC must be on the same Wi-Fi, the
  // backend must actually be running (`npm start` in backend/), and Windows
  // Firewall must allow inbound connections on this port. This IP is this
  // PC's current Wi-Fi LAN address — it will change if the PC reconnects to
  // a different network or gets a new DHCP lease.
  static const String baseUrl = 'http://192.168.1.7:10000';
}
