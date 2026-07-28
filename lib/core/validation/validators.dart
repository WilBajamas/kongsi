const minPasswordLength = 8;

final _emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

bool isValidEmail(String? value) => _emailPattern.hasMatch(value?.trim() ?? '');

bool isValidPassword(String? value, {int minLength = minPasswordLength}) =>
    (value ?? '').length >= minLength;
