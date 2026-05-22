class UserSession {
  static String name = '';
  static String email = '';

  static void login({required String name, required String email}) {
    UserSession.name = name;
    UserSession.email = email;
  }

  static void logout() {
    name = '';
    email = '';
  }
}
