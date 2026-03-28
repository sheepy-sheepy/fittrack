enum RegistrationStatus {
  emailNotVerified,    // 0 - не подтверждена почта
  onboardingNotCompleted, // 1 - не пройден onboarding
  fullyRegistered;     // 2 - полностью зарегистрирован
  
  static RegistrationStatus fromInt(int value) {
    switch (value) {
      case 0:
        return RegistrationStatus.emailNotVerified;
      case 1:
        return RegistrationStatus.onboardingNotCompleted;
      case 2:
        return RegistrationStatus.fullyRegistered;
      default:
        return RegistrationStatus.emailNotVerified;
    }
  }
  
  int toInt() {
    switch (this) {
      case RegistrationStatus.emailNotVerified:
        return 0;
      case RegistrationStatus.onboardingNotCompleted:
        return 1;
      case RegistrationStatus.fullyRegistered:
        return 2;
    }
  }
}