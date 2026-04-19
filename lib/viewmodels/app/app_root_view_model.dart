import '../../services/auth_service.dart';
import '../base_view_model.dart';

class AppRootViewModel extends BaseViewModel {
  final AuthService authService;

  AppRootViewModel({AuthService? authService})
      : authService = authService ?? AuthService();
}
