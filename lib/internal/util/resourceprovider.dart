class HttpProvider {
  static String makeFileUrl(String baseUrl, String dir, String name) {
    return "$baseUrl/filedown/$dir/$name";
  }
}
