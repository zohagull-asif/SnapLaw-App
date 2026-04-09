class PasswordValidator {
  // Password requirements
  static const int minLength = 8;
  static const int maxLength = 128;

  /// Validates password strength
  /// Returns null if valid, otherwise returns error message
  static String? validate(String password) {
    if (password.isEmpty) {
      return 'Password is required';
    }

    if (password.length < minLength) {
      return 'Password must be at least $minLength characters';
    }

    if (password.length > maxLength) {
      return 'Password must be less than $maxLength characters';
    }

    if (!hasUppercase(password)) {
      return 'Password must contain at least one uppercase letter';
    }

    if (!hasLowercase(password)) {
      return 'Password must contain at least one lowercase letter';
    }

    if (!hasDigit(password)) {
      return 'Password must contain at least one number';
    }

    if (!hasSpecialChar(password)) {
      return 'Password must contain at least one special character (!@#\$%^&*(),.?":{}|<>)';
    }

    return null; // Password is valid
  }

  /// Check if password has at least one uppercase letter
  static bool hasUppercase(String password) {
    return password.contains(RegExp(r'[A-Z]'));
  }

  /// Check if password has at least one lowercase letter
  static bool hasLowercase(String password) {
    return password.contains(RegExp(r'[a-z]'));
  }

  /// Check if password has at least one digit
  static bool hasDigit(String password) {
    return password.contains(RegExp(r'[0-9]'));
  }

  /// Check if password has at least one special character
  static bool hasSpecialChar(String password) {
    return password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'));
  }

  /// Get password strength (0-4)
  /// 0 = Very Weak, 1 = Weak, 2 = Fair, 3 = Good, 4 = Strong
  static int getStrength(String password) {
    if (password.isEmpty) return 0;

    int strength = 0;

    // Length check
    if (password.length >= minLength) strength++;
    if (password.length >= 12) strength++;

    // Character variety checks
    if (hasUppercase(password) && hasLowercase(password)) strength++;
    if (hasDigit(password)) strength++;
    if (hasSpecialChar(password)) strength++;

    // Cap at 4
    return strength > 4 ? 4 : strength;
  }

  /// Get password strength label
  static String getStrengthLabel(int strength) {
    switch (strength) {
      case 0:
        return 'Very Weak';
      case 1:
        return 'Weak';
      case 2:
        return 'Fair';
      case 3:
        return 'Good';
      case 4:
        return 'Strong';
      default:
        return 'Very Weak';
    }
  }

  /// Get list of requirements with their status
  static Map<String, bool> getRequirements(String password) {
    return {
      'At least $minLength characters': password.length >= minLength,
      'One uppercase letter': hasUppercase(password),
      'One lowercase letter': hasLowercase(password),
      'One number': hasDigit(password),
      'One special character': hasSpecialChar(password),
    };
  }

  /// Validate password confirmation
  static String? validateConfirmPassword(String password, String confirmPassword) {
    if (confirmPassword.isEmpty) {
      return 'Please confirm your password';
    }

    if (password != confirmPassword) {
      return 'Passwords do not match';
    }

    return null;
  }
}
