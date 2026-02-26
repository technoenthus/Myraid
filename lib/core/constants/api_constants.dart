class ApiConstants {
  static const String baseUrl = 'https://dummyjson.com';

  // Auth
  static const String login = '/auth/login';
  static const String currentUser = '/auth/me';

  // Todos
  static const String addTodo = '/todos/add';
  static String userTodos(int userId) => '/todos/user/$userId';
  static String todoById(int id) => '/todos/$id';

  // Pagination
  static const int pageLimit = 10;

  // Timeouts (ms)
  static const int connectTimeout = 10000;
  static const int receiveTimeout = 15000;
}
