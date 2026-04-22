import 'package:flutter/foundation.dart';

enum UiStatus {
  idle,
  loading,
  success,
  error,
}

class BaseViewModel extends ChangeNotifier {
  bool _isLoading = false;
  String? _errorMessage;
  String? _uiMessage;
  UiStatus _status = UiStatus.idle;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String? get uiMessage => _uiMessage;
  UiStatus get status => _status;
  bool get isIdle => _status == UiStatus.idle;
  bool get isSuccess => _status == UiStatus.success;
  bool get isError => _status == UiStatus.error;

  @protected
  void setStatus(UiStatus value, {bool shouldNotify = true}) {
    if (_status == value) {
      return;
    }
    _status = value;
    if (shouldNotify) {
      notifyListeners();
    }
  }

  @protected
  void setLoading(bool value) {
    if (_isLoading == value) {
      return;
    }
    _isLoading = value;
    if (value) {
      setStatus(UiStatus.loading, shouldNotify: false);
    } else if (_status == UiStatus.loading) {
      setStatus(UiStatus.idle, shouldNotify: false);
    }
    notifyListeners();
  }

  @protected
  void setError(String? message) {
    if (_errorMessage == message) {
      return;
    }
    _errorMessage = message;
    if (message != null && message.isNotEmpty) {
      setStatus(UiStatus.error, shouldNotify: false);
    }
    notifyListeners();
  }

  @protected
  void setUiMessage(String? message) {
    if (_uiMessage == message) {
      return;
    }
    _uiMessage = message;
    notifyListeners();
  }

  @protected
  void setSuccess([String? message]) {
    if (message != null) {
      _uiMessage = message;
    }
    _errorMessage = null;
    _isLoading = false;
    _status = UiStatus.success;
    notifyListeners();
  }

  @protected
  void setFailure(String message) {
    _errorMessage = message;
    _uiMessage = message;
    _isLoading = false;
    _status = UiStatus.error;
    notifyListeners();
  }

  void setIdle() {
    if (_status == UiStatus.idle && !_isLoading) {
      return;
    }
    _isLoading = false;
    _status = UiStatus.idle;
    notifyListeners();
  }

  void clearUiMessage() {
    _uiMessage = null;
  }

  void startLoading() {
    setLoading(true);
  }

  void stopLoading() {
    setLoading(false);
  }

  void clearError() {
    setError(null);
  }
}
