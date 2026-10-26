abstract final class AppStrings {
  static const splashName = 'MyoGrip AI';
  static const splashTagline = 'Adaptive prosthetic control';
  static const splashSemantics =
      'MyoGrip AI, adaptive prosthetic control, loading';
  static const onboardingDonePreferenceKey = 'onboarding_done';
  static const onboardingStep1Title = 'Put on the prosthetic arm';
  static const onboardingStep1Body =
      'Slide your arm into the socket and fasten the straps comfortably.';
  static const onboardingStep1Illustration =
      'Illustration: sliding the arm into the socket';
  static const onboardingSkip = 'Skip';
  static const onboardingSkipSemantics = 'Skip onboarding';
  static const onboardingBack = 'Back';
  static const onboardingNext = 'Next';
  static const onboardingNextSemantics = 'Next onboarding step';
  static const onboardingStep2Title = 'Position the armband';
  static const onboardingStep2Body =
      'Slide the MindRove armband onto the forearm, just below the elbow. Tighten until it feels snug and comfortable.';
  static const onboardingStep2Illustration =
      'Illustration: tightening the MindRove armband just below the elbow';
  static const onboardingStep2Tip1 = 'Sensors against clean, dry skin';
  static const onboardingStep2Tip2 = 'Just below the elbow';
  static const onboardingStep2Tip3 = 'Snug but comfortable';
  static const onboardingStep2TipNumber1 = '1';
  static const onboardingStep2TipNumber2 = '2';
  static const onboardingStep2TipNumber3 = '3';
  static const onboardingStep3Title = 'Pair your devices';
  static const onboardingStep3Body =
      'Turn on your prosthetic arm and MindRove armband, then tap Pair next to each device.';
  static const onboardingStep3ArmName = 'MyoGrip Arm';
  static const onboardingStep3ArmbandName = 'MindRove\nArmband';
  static const onboardingStep3ArmbandSemantics = 'MindRove Armband';
  static const onboardingDeviceFoundNearby = 'Found nearby';
  static const onboardingDeviceSearching = 'Looking for devices…';
  static const onboardingDevicePair = 'Pair';
  static const onboardingDevicePairing = 'Pairing…';
  static const onboardingDevicePaired = '✓ Paired';
  static const onboardingDevicePairedSemantics = 'Paired';
  static const onboardingDevicePairFailed = 'Could not pair';
  static const onboardingDeviceTryAgain = 'Try again';
  static const onboardingDeviceSkipForNow = 'Skip for now';
  static const onboardingDeviceHelp =
      'Cannot see a device? Check that it is switched on and close to your phone.';
  static const onboardingFinish = 'Finish';
  static const onboardingPermissionReason =
      'MyoGrip AI needs access to your local network to find your arm and armband.';
  static const onboardingPermissionContinue = 'Continue';
  static const onboardingPermissionNotNow = 'Not now';
  static const onboardingPermissionSheetLabel =
      'Local network permission explanation';
  static const loginTitle = 'Sign in';
  static const loginSubtitle = 'to manage your prosthetic arm';
  static const loginEmailLabel = 'Email';
  static const loginEmailHint = 'name@example.com';
  static const loginPasswordLabel = 'Password';
  static const loginShowPassword = 'Show';
  static const loginHidePassword = 'Hide';
  static const loginForgotPassword = 'Forgot password?';
  static const loginSubmit = 'Sign in';
  static const loginNewHere = 'New here? ';
  static const loginCreateAccount = 'Create an account';
  static const loginEmailInvalid = 'Enter a valid email address';
  static const loginPasswordRequired = 'Enter your password';
  static const loginCredentialsIncorrect = 'Email or password is incorrect.';
  static const loginNoConnection = 'No connection';
  static const loginRetry = 'Retry';
  static const authPasswordResetUnavailable =
      'Password reset is not available yet.';
  static const forgotPasswordBack = '← Back';
  static const forgotPasswordTitle = 'Reset password';
  static const forgotPasswordBody =
      'Enter your email and we will send you a link to reset your password.';
  static const forgotPasswordEmail = 'Email';
  static const forgotPasswordSend = 'Send link';
  static const forgotPasswordConfirmation = 'Check your email.';
  static const forgotPasswordBackToSignIn = 'Back to sign in';
  static const registerBack = '← Back';
  static const registerTitle = 'Create account';
  static const registerSubtitle =
      'Your clinic code links the app to your clinician.';
  static const registerFullName = 'Full name';
  static const registerFullNameHint = 'Patient name';
  static const registerAge = 'Age';
  static const registerAgeHint = '34';
  static const registerEmail = 'Email';
  static const registerPassword = 'Password';
  static const registerClinicCode = 'Clinic code';
  static const registerClinicCodeHint = 'Code from your clinic';
  static const registerPasswordRule =
      'At least 8 characters, with at least one letter and one number.';
  static const registerRuleLength = '8+ characters';
  static const registerRuleLetter = 'one letter';
  static const registerRuleNumber = 'one number';
  static const registerRuleMet = 'met';
  static const registerRuleNeeded = 'needed';
  static const registerNameRequired = 'Enter your full name';
  static const registerAgeRequired = 'Enter your age';
  static const registerAgeMustBeNumber = 'Age must be a whole number';
  static const registerAgeInvalid = 'Age must be a whole number from 1 to 120';
  static const registerEmailRequired = 'Enter your email address';
  static const registerEmailInvalid = 'Enter a valid email address';
  static const registerEmailTaken = 'This email is already registered';
  static const registerPasswordRequired = 'Enter a password';
  static const registerPasswordInvalid =
      'Use at least 8 characters, including a letter and a number';
  static const registerClinicCodeRequired = 'Enter your clinic code';
  static const registerClinicCodeInvalid = 'We could not find this clinic code';
  static const registerSubmit = 'Create account';
  static const registerExistingAccount = 'Already have an account? ';
  static const registerSignIn = 'Sign in';
  static const registerServerError = 'Something went wrong. Please try again.';
  static const homeDateFormat = 'EEEE d MMMM';
  static const homeTitle = 'Your arm';
  static const homeConnectionLinked = 'Connected over Wi-Fi, armband linked';
  static const homeConnectionNotLinked =
      'Connected over Wi-Fi, armband not linked';
  static const homeConnecting = 'Connecting…';
  static const homeDisconnected = 'Not connected · last seen';
  static const homeHolding = 'Holding';
  static const homeStatus = 'Status';
  static const homeResting = 'Resting';
  static const homeNoData = 'No data';
  static const homeSignalConfidence = 'Signal confidence';
  static const homeLastSignalAt = 'Last signal at';
  static const homeArmBattery = 'Arm battery';
  static const homeArmbandBattery = 'MindRove armband';
  static const homeLowBattery = 'Low';
  static const homeEmergencyStop = 'Emergency stop';
  static const homeEmergencyStopSemantics =
      'Emergency stop, double tap to halt the arm';
  static const homeResume = 'Resume';
  static const homeStopped = 'Arm stopped';
  static const homeStoppedDetail = 'Motors and haptic feedback are off.';
  static const homeNoDeviceLinked = 'No device linked';
  static const homePairDevices = 'Pair your devices';
  static const homeConnectionSheetTodo =
      'Connection details will be available soon.';
  static const homeConnectionsTitle = 'Connections';
  static const homeArmController = 'Arm controller';
  static const homeArmbandConnection = 'MindRove armband';
  static const homeWifi = 'Wi-Fi';
  static const homeWifiDirect = 'Wi-Fi Direct';
  static const homeReconnect = 'Reconnect';
  static const homeConnected = 'Connected';
  static const homeDisconnectedStatus = 'Disconnected';
  static const homeReconnectUnsupported = 'Reconnect is not available yet.';
  static const homeReconnectFailed = 'Could not reconnect device.';
  static const homeDisconnectedLastSeen = 'Disconnected · last seen';
  static const homePairPrompt =
      'Your devices are not linked yet. Pair them to get started.';
  static const homeRePairMode = 'repair';
  static const homeLowBatterySnackbar = 'Low battery';
  static const homeGesture = 'Gesture';
  static const homeLiveGesture = 'Live gesture';
  static const homeFingerThumb = 'thumb';
  static const homeFingerIndex = 'index';
  static const homeFingerMiddle = 'middle';
  static const homeFingerRing = 'ring';
  static const homeFingerLittle = 'little';
  static const homeTabHome = 'Home';
  static const homeTabSettings = 'Settings';
  static const homeTabProfile = 'Profile';
  static const homeStopFailed = 'Could not stop the arm.';
  static const homeStopNotDelivered = 'Stop not delivered. Retry.';
  static const homeStoppedAnnouncement = 'Arm stopped';
  static const settingsTitle = 'Settings';
  static const settingsSensitivity = 'Sensitivity';
  static const settingsSensitivityDescription =
      'How strong a muscle signal must be to move the arm.';
  static const settingsLow = 'Low';
  static const settingsMedium = 'Medium';
  static const settingsHigh = 'High';
  static const settingsHapticFeedback = 'Haptic feedback';
  static const settingsTensDescription = 'TENS pulses when you grip';
  static const settingsGrips = 'Grips';
  static const settingsOnCount = 'of 10 on';
  static const settingsPending = 'Pending';
  static const settingsSaved = 'Saved';
  static const settingsSaveFailed = 'Could not save. Retry.';
  static const settingsRetry = 'Retry';
  static const settingsLastGripRequired = 'At least one grip must stay on.';
  static const settingsTensNotice =
      'TENS uses small electrical pulses through skin electrodes. Make sure the electrodes are placed as shown by your clinician.';
  static const settingsTensTurnOn = 'Turn on';
  static const settingsTensCancel = 'Cancel';
  static const settingsTensSheetLabel = 'TENS safety information';
  static const tensNoticeSeenPreferenceKey = 'tens_notice_seen';
  static const settingsGestureNames = <String>[
    'Gesture 0',
    'Gesture 1',
    'Gesture 2',
    'Gesture 3',
    'Gesture 4',
    'Gesture 5',
    'Gesture 6',
    'Gesture 7',
    'Gesture 8',
    'Gesture 9',
  ];
  static const settingsMore = 'More';
  static const settingsCalibration = 'Calibration';
  static const settingsActivityLog = 'Activity log';
  static const settingsHelpSafety = 'Help and safety';
  static const settingsSignOut = 'Sign out';
  static const calibrationTitle = 'Calibration';
  static const calibrationCancel = 'Cancel';
  static const calibrationRelaxTitle = 'Relax your arm';
  static const calibrationRelaxBody =
      'Rest your arm on a table and let it go loose.';
  static const calibrationGesture1Title = 'Make Gesture 1';
  static const calibrationGesture1Body =
      'Squeeze and hold for 2 seconds, then release. Repeat 3 times.';
  static const calibrationGesture2Title = 'Make Gesture 2';
  static const calibrationGesture2Body =
      'Squeeze and hold for 2 seconds, then release. Repeat 3 times.';
  static const calibrationCompleteTitle = 'Calibration complete';
  static const calibrationGood = 'Good';
  static const calibrationQuality = 'Signal quality 92%';
  static const calibrationStart = 'Start';
  static const calibrationRecord = 'Record';
  static const calibrationDone = 'Done';
  static const calibrationSaved = 'Calibration saved';
  static const activityTitle = 'Activity';
  static const activityAll = 'All';
  static const activityAlerts = 'Alerts';
  static const activityToday = 'Today';
  static const activityYesterday = 'Yesterday';
  static const activityEmpty = 'No activity yet';
  static const activityEntries =
      <({String time, String title, String detail, bool alert, String day})>[
        (
          time: '09:40',
          title: 'Synced with your clinic',
          detail: '',
          alert: false,
          day: 'Today',
        ),
        (
          time: '08:15',
          title: 'Sensitivity changed to High',
          detail: '',
          alert: false,
          day: 'Today',
        ),
        (
          time: '07:52',
          title: 'Emergency stop pressed',
          detail: 'Arm stopped, resumed 12 s later',
          alert: true,
          day: 'Today',
        ),
        (
          time: '06:30',
          title: 'Armband battery low',
          detail: '19%',
          alert: true,
          day: 'Yesterday',
        ),
        (
          time: '17:10',
          title: 'Connection lost',
          detail: 'Back after 2 min',
          alert: true,
          day: 'Yesterday',
        ),
        (
          time: '15:20',
          title: 'Calibration completed',
          detail: '',
          alert: false,
          day: 'Yesterday',
        ),
      ];
  static const helpTitle = 'Help and safety';
  static const helpQuestions = <String>[
    'If the arm does not respond',
    'How the emergency stop works',
    'Cleaning and care',
    'Charging the arm and armband',
  ];
  static const helpAnswers = <String>[
    'Check that the armband is snug and its sensors are against clean, dry skin. Reconnect the devices and try a comfortable gesture again.',
    'Emergency stop immediately asks the arm to stop movement. Resume when you are ready; if the arm does not respond, contact your clinician.',
    'Wipe the exterior with a soft, slightly damp cloth. Do not immerse the arm or armband, and follow your clinician’s instructions for skin and electrode care.',
    'Use the supplied chargers and keep charging ports dry. Disconnect the charger before using the arm or armband.',
  ];
  static const helpContactClinic = 'Contact your clinic';
  static const helpCallClinic = 'Call clinic';
  static const helpSendMessage = 'Send a message';
  static const helpNotAvailable = 'Not available in demo';
  static const helpVersion = 'MyoGrip AI · version 0.1.0 (demo)';
  static const connectionArmStatus = 'Connected · Wi-Fi';
  static const connectionArmbandStatus = 'Connected · Wi-Fi Direct';
  static const connectionSignalStrong = 'Strong';

  static String settingsSwitchSemantics(String label, bool enabled) =>
      '$label, ${enabled ? 'on' : 'off'}';
  static const profileTitle = 'Profile';
  static const profilePatientFallbackName = 'Patient name';
  static const profileEdit = 'Edit';
  static const profileLinkedToClinic = 'Linked to your clinic';
  static const profileAge = 'Age';
  static const profileHoursWorn = 'Hours worn per day';
  static const profileSevenDays = '7 days';
  static const profileThirtyDays = '30 days';
  static const profileGripStrength = 'Grip strength';
  static const profileRising = 'Rising over 30 days';
  static const profileSteady = 'Steady over 30 days';
  static const profileFalling = 'Falling over 30 days';
  static const profileNoUsage = 'No usage recorded yet';
  static const profileLoadError = 'Could not load your data.';
  static const profileRetry = 'Retry';
  static const profileSyncedToday = 'Last synced today at';
  static const profileSyncedYesterday = 'Last synced yesterday at';
  static const profileSyncedDate = 'Last synced';
  static const profileSendReport = 'Send report to my doctor';
  static const profileNoClinician = 'Link a clinic to send reports.';
  static const profileReportSheetLabel = 'Send a report';
  static const profileReportTodo = 'Report sharing will be available soon.';
  static const profileReportConfirm = 'Send';
  static const profileReportCancel = 'Cancel';
  static const profileReportTitle = 'Send report to your doctor';
  static const profileReportPeriod = 'Last 30 days';
  static const profileReportUsageHours = 'Usage hours';
  static const profileReportGripTrend = 'Grip strength trend';
  static const profileReportErrors = 'Error reports';
  static const profileReportSent = 'Report sent';
  static const profileReportFailed = 'Could not send report.';
  static const profileReportClinician = 'Clinician';
  static const editProfileBack = '← Back';
  static const editProfileTitle = 'Edit profile';
  static const editProfileName = 'Name';
  static const editProfileAge = 'Age';
  static const editProfileEmail = 'Email';
  static const editProfileClinicCode = 'Clinic code';
  static const editProfileClinicCodeCaption = 'Set by your clinic';
  static const editProfileCancel = 'Cancel';
  static const editProfileSave = 'Save';
  static const editProfileEdit = 'Edit';
  static const editProfileSaved = 'Saved';
  static const editProfileSaveError = 'Could not save. Retry.';
  static const editProfileSaving = 'Saving';
  static const editProfileLoadError = 'Could not load your profile.';
  static const profileHoursChartDescription =
      'Hours worn per day chart. Select a bar to hear its value.';
  static const profileWeekdayLabels = <String>[
    'M',
    'T',
    'W',
    'T',
    'F',
    'S',
    'S',
  ];
  static const profileTooltipHours = 'hours';

  static String onboardingStepLabel(int step) => 'Step $step of 3';

  static String onboardingTipSemantics(int position, int total, String text) =>
      'Step $position of $total tips: $text';
}
