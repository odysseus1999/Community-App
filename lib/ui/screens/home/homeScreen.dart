import 'dart:io';
import 'package:flutterquiz/features/ads/interstitialAdCubit.dart';
import 'package:flutterquiz/features/badges/cubits/badgesCubit.dart';
import 'package:flutterquiz/features/battleRoom/cubits/battleRoomCubit.dart';
import 'package:flutterquiz/features/battleRoom/cubits/multiUserBattleRoomCubit.dart';
import 'package:flutterquiz/features/exam/cubits/examCubit.dart';
import 'package:flutterquiz/features/profileManagement/cubits/updateScoreAndCoinsCubit.dart';
import 'package:flutterquiz/features/profileManagement/cubits/updateUserDetailsCubit.dart';
import 'package:flutterquiz/features/profileManagement/profileManagementLocalDataSource.dart';
import 'package:flutterquiz/features/profileManagement/profileManagementRepository.dart';
import 'package:flutterquiz/features/quiz/cubits/contestCubit.dart';
import 'package:flutterquiz/features/quiz/cubits/quizCategoryCubit.dart';
import 'package:flutterquiz/features/quiz/cubits/quizoneCategoryCubit.dart';
import 'package:flutterquiz/features/quiz/cubits/subCategoryCubit.dart';
import 'package:flutterquiz/features/quiz/models/contest.dart';

import 'package:flutterquiz/ui/screens/battle/widgets/randomOrPlayFrdDialog.dart';
import 'package:flutterquiz/ui/screens/battle/widgets/roomDialog.dart';
import 'package:flutterquiz/ui/screens/home/widgets/appUnderMaintenanceDialog.dart';
import 'package:flutterquiz/ui/screens/home/widgets/guestModeDialog.dart';
import 'package:flutterquiz/ui/screens/profile/widgets/editProfileFieldBottomSheetContainer.dart';

import 'package:http/http.dart' as http;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutterquiz/app/appLocalization.dart';
import 'package:flutterquiz/app/routes.dart';
import 'package:flutterquiz/features/auth/authRepository.dart';
import 'package:flutterquiz/features/auth/cubits/authCubit.dart';
import 'package:flutterquiz/features/auth/cubits/referAndEarnCubit.dart';
import 'package:flutterquiz/features/profileManagement/cubits/userDetailsCubit.dart';
import 'package:flutterquiz/features/profileManagement/models/userProfile.dart';
import 'package:flutterquiz/features/quiz/models/quizType.dart';
import 'package:flutterquiz/features/systemConfig/cubits/systemConfigCubit.dart';
import 'package:flutterquiz/ui/screens/home/widgets/updateAppContainer.dart';
import 'package:flutterquiz/ui/widgets/circularProgressContainner.dart';
import 'package:flutterquiz/ui/widgets/errorContainer.dart';
import 'package:flutterquiz/ui/widgets/userAchievementScreen.dart';
import 'package:flutterquiz/utils/errorMessageKeys.dart';
import 'package:flutterquiz/utils/quizTypes.dart';
import 'package:flutterquiz/utils/stringLabels.dart';
import 'package:flutterquiz/utils/uiUtils.dart';
import 'package:path_provider/path_provider.dart';

class HomeScreen extends StatefulWidget {
  final bool isGuest;

  HomeScreen({
    Key? key,
    required this.isGuest,
  }) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();

  static Route<dynamic> route(RouteSettings routeSettings) {
    return CupertinoPageRoute(
        builder: (context) => MultiBlocProvider(
              providers: [
                BlocProvider<ReferAndEarnCubit>(
                  create: (_) => ReferAndEarnCubit(AuthRepository()),
                ),
                BlocProvider<UpdateScoreAndCoinsCubit>(
                    create: (_) => UpdateScoreAndCoinsCubit(
                        ProfileManagementRepository())),
                BlocProvider<UpdateUserDetailCubit>(
                  create: (context) =>
                      UpdateUserDetailCubit(ProfileManagementRepository()),
                ),
              ],
              child: HomeScreen(isGuest: routeSettings.arguments as bool),
            ));
  }
}

class _HomeScreenState extends State<HomeScreen>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  final double quizTypeWidthPercentage = 0.4;
  late double quizTypeTopMargin = 0.0;
  final double quizTypeHorizontalMarginPercentage = 0.08;
  final List<int> maxHeightQuizTypeIndexes = [0, 3, 4, 7, 8];

  final double quizTypeBetweenVerticalSpacing = 0.02;

  late List<QuizType> _quizTypes = quizTypes;

  late AnimationController profileAnimationController;
  late AnimationController selfChallengeAnimationController;

  late Animation<Offset> profileSlideAnimation;

  late Animation<Offset> selfChallengeSlideAnimation;

  late AnimationController firstAnimationController;
  late Animation<double> firstAnimation;
  late AnimationController secondAnimationController;
  late Animation<double> secondAnimation;

  bool? dragUP;

  bool checkContest = false;
  int currentMenu = 1;

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  List battleName = [
    "groupPlay",
    "battleQuiz",
  ];

  List battleImg = ["group_battle_icon.svg", "one_vs_one_icon.svg"];

  List examSelf = ["exam", "selfChallengeLbl"];

  List examSelfdesc = ["desExam", "challengeYourselfLbl"];

  List examSelfimg = ["exam_icon.svg", "self_challenge.svg"];

  List battleDesc = ["desGroupPlay", "desBattleQuiz"];

  List playDifferentZone = [
    "dailyQuiz",
    "funAndLearn",
    "guessTheWord",
    "audioQuestions",
    "mathMania",
    "truefalse"
  ];

  List playDifferentImg = [
    "daily_quiz_icon.svg",
    "fun_icon.svg",
    "guess_icon.svg",
    "audio_icon.svg",
    "maths_icon.svg",
    "true_false_icon.svg"
  ];

  List playDifferentZoneDesc = [
    "desDailyQuiz",
    "desFunAndLearn",
    "desGuessTheWord",
    "desAudioQuestions",
    "desMathMania",
    "desTrueFalse"
  ];

  @override
  void initState() {
    initAnimations();
    showAppUnderMaintenanceDialog();
    setQuizMenu();
    _initLocalNotification();
    checkForUpdates();
    setupInteractedMessage();
    createAds();
    WidgetsBinding.instance.addObserver(this);
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 300),
      upperBound: 0.5,
    );

    if (widget.isGuest) {
      context.read<QuizCategoryCubit>().getQuizwithoutUserCategory(
            languageId: UiUtils.getCurrentQuestionLanguageId(context),
            type: UiUtils.getCategoryTypeNumberFromQuizType(QuizTypes.quizZone),
          );
    } else {
      context.read<QuizCategoryCubit>().getQuizCategory(
            languageId: UiUtils.getCurrentQuestionLanguageId(context),
            type: UiUtils.getCategoryTypeNumberFromQuizType(QuizTypes.quizZone),
            userId: context.read<UserDetailsCubit>().getUserId(),
          );
    }

    if (!widget.isGuest) {
      context.read<QuizoneCategoryCubit>().getQuizCategory(
            languageId: UiUtils.getCurrentQuestionLanguageId(context),
            userId: context.read<UserDetailsCubit>().getUserId(),
          );
      context
          .read<ContestCubit>()
          .getContest(context.read<UserDetailsCubit>().getUserId());
    } else {
      context.read<QuizoneCategoryCubit>().getQuizWithoutuserCategory(
            languageId: UiUtils.getCurrentQuestionLanguageId(context),
          );
    }

    super.initState();
  }

  void initAnimations() {
    //
    profileAnimationController =
        AnimationController(vsync: this, duration: Duration(milliseconds: 85));
    selfChallengeAnimationController =
        AnimationController(vsync: this, duration: Duration(milliseconds: 85));

    profileSlideAnimation =
        Tween<Offset>(begin: Offset.zero, end: Offset(0.0, -0.0415)).animate(
            CurvedAnimation(
                parent: profileAnimationController, curve: Curves.easeIn));

    selfChallengeSlideAnimation =
        Tween<Offset>(begin: Offset.zero, end: Offset(0.0, -0.0415)).animate(
            CurvedAnimation(
                parent: selfChallengeAnimationController,
                curve: Curves.easeIn));

    firstAnimationController =
        AnimationController(vsync: this, duration: Duration(milliseconds: 400));
    firstAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
            parent: firstAnimationController, curve: Curves.easeInOut));
    secondAnimationController =
        AnimationController(vsync: this, duration: Duration(milliseconds: 400));
    secondAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
            parent: secondAnimationController, curve: Curves.easeInOut));
  }

  void createAds() {
    Future.delayed(Duration.zero, () {
      context.read<InterstitialAdCubit>().createInterstitialAd(context);
    });
  }

  void showAppUnderMaintenanceDialog() {
    Future.delayed(Duration.zero, () {
      if (context.read<SystemConfigCubit>().appUnderMaintenance()) {
        showDialog(
            context: context, builder: (_) => AppUnderMaintenanceDialog());
      }
    });
  }

  void _initLocalNotification() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    final DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(onDidReceiveLocalNotification:
            (int id, String? title, String? body, String? payLoad) {
      print("For ios version <= 9 notification will be shown here");
    });

    final InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );
    await flutterLocalNotificationsPlugin.initialize(initializationSettings,
        onDidReceiveNotificationResponse: _onTapLocalNotification);
    _requestPermissionsForIos();
  }

  Future<void> _requestPermissionsForIos() async {
    if (Platform.isIOS) {
      flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions();
    }
  }

  void setQuizMenu() {
    Future.delayed(Duration.zero, () {
      final systemCubit = context.read<SystemConfigCubit>();
      if (systemCubit.getIsContestAvailable() == "0") {
        checkContest = true;
      }
      if (systemCubit.getIsDailyQuizAvailable() == "0") {
        playDifferentZone.removeWhere((element) => element == "dailyQuiz");
        playDifferentImg
            .removeWhere((element) => element == "daily_quiz_icon.svg");
        playDifferentZoneDesc
            .removeWhere((element) => element == "desDailyQuiz");
      }
      if (systemCubit.getIsTrueFalseAvailable() == "0") {
        playDifferentZone.removeWhere((element) => element == "truefalse");
        playDifferentImg
            .removeWhere((element) => element == "true_false_icon.svg");
        playDifferentZoneDesc
            .removeWhere((element) => element == "desTrueFalse");
      }
      if (systemCubit.getIsFunNLearnAvailable() == "0") {
        playDifferentZone.removeWhere((element) => element == "funAndLearn");
        playDifferentImg.removeWhere((element) => element == "fun_icon.svg");
        playDifferentZoneDesc
            .removeWhere((element) => element == "desFunAndLearn");
      }
      if (!systemCubit.getIsGuessTheWordAvailable()) {
        playDifferentZone.removeWhere((element) => element == "guessTheWord");
        playDifferentImg.removeWhere((element) => element == "guess_icon.svg");
        playDifferentZoneDesc
            .removeWhere((element) => element == "desGuessTheWord");
      }
      if (!systemCubit.getIsAudioQuestionAvailable()) {
        playDifferentZone.removeWhere((element) => element == "audioQuestions");
        playDifferentImg.removeWhere((element) => element == "audio_icon.svg");
        playDifferentZoneDesc
            .removeWhere((element) => element == "desAudioQuestions");
      }
      if (!systemCubit.isMathQuizAvailable()) {
        playDifferentZone.removeWhere((element) => element == "mathMania");
        playDifferentImg.removeWhere((element) => element == "maths_icon.svg");
        playDifferentZoneDesc
            .removeWhere((element) => element == "desMathMania");
      }
      if (systemCubit.getIsExamAvailable() == "0") {
        examSelf.removeWhere((element) => element == "exam");
        examSelfdesc.removeWhere((element) => element == "desExam");
        examSelfimg.removeWhere((element) => element == "exam_icon.svg");
      }
      if (!context.read<SystemConfigCubit>().isSelfChallengeEnable()) {
        examSelf.removeWhere((element) => element == "selfChallengeLbl");
        examSelfdesc
            .removeWhere((element) => element == "challengeYourselfLbl");
        examSelfimg.removeWhere((element) => element == "self_challenge.svg");
      }

      if (systemCubit.getIsBattleModeGroupAvailable() == "0") {
        battleName.removeWhere((element) => element == "groupPlay");
        battleImg.removeWhere((element) => element == "group_battle_icon.svg");
        battleDesc.removeWhere((element) => element == "desGroupPlay");
      }

      if (systemCubit.getIsBattleModeOneAvailable() == "0") {
        battleName.removeWhere((element) => element == "battleQuiz");
        battleImg.removeWhere((element) => element == "one_vs_one_icon.svg");
        battleDesc.removeWhere((element) => element == "desBattleQuiz");
      }

      setState(() {});
    });
  }

  late bool showUpdateContainer = false;

  void checkForUpdates() async {
    await Future.delayed(Duration.zero);
    if (context.read<SystemConfigCubit>().isForceUpdateEnable()) {
      try {
        bool forceUpdate = await UiUtils.forceUpdate(
            context.read<SystemConfigCubit>().getAppVersion());

        if (forceUpdate) {
          setState(() {
            showUpdateContainer = true;
          });
        }
      } catch (e) {
        print(e.toString());
      }
    }
  }

  Future<void> setupInteractedMessage() async {
    //
    if (Platform.isIOS) {
      await FirebaseMessaging.instance
          .requestPermission(announcement: true, provisional: true);
    }

    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessage);
    // handle background notification
    FirebaseMessaging.onBackgroundMessage(UiUtils.onBackgroundMessage);
    //handle foreground notification
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print("Notification arrives : $message");
      var data = message.data;

      var title = data['title'].toString();
      var body = data['body'].toString();
      var type = data['type'].toString();

      var image = data['image'];

      //if notification type is badges then update badges in cubit list
      if (type == "badges") {
        String badgeType = data['badge_type'];
        Future.delayed(Duration.zero, () {
          context.read<BadgesCubit>().unlockBadge(badgeType);
        });
      }

      if (type == "payment_request") {
        Future.delayed(Duration.zero, () {
          context.read<UserDetailsCubit>().updateCoins(
                addCoin: true,
                coins: int.parse(data['coins'].toString()),
              );
        });
      }

      //payload is some data you want to pass in local notification
      image != null
          ? generateImageNotification(title, body, image, type, type)
          : generateSimpleNotification(title, body, type);
    });
  }

  // notification type is category then move to category screen
  Future<void> _handleMessage(RemoteMessage message) async {
    try {
      if (message.data['type'] == 'category') {
        Navigator.of(context).pushNamed(Routes.category,
            arguments: {"quizType": QuizTypes.quizZone});
      } else if (message.data['type'] == 'badges') {
        //if user open app by tapping
        UiUtils.updateBadgesLocally(context);
        Navigator.of(context).pushNamed(Routes.badges);
      } else if (message.data['type'] == "payment_request") {
        //UiUtils.needToUpdateCoinsLocally(context);
        Navigator.of(context).pushNamed(Routes.wallet);
      }
    } catch (e) {
      print(e);
    }
  }

  Future<void> _onTapLocalNotification(NotificationResponse? payload) async {
    //
    String type = payload!.payload ?? "";
    if (type == "badges") {
      Navigator.of(context).pushNamed(Routes.badges);
    } else if (type == "category") {
      Navigator.of(context).pushNamed(
        Routes.category,
      );
    } else if (type == "payment_request") {
      Navigator.of(context).pushNamed(Routes.wallet);
    }
  }

  Future<void> generateImageNotification(String title, String msg, String image,
      String payloads, String type) async {
    var largeIconPath = await _downloadAndSaveFile(image, 'largeIcon');
    var bigPicturePath = await _downloadAndSaveFile(image, 'bigPicture');
    var bigPictureStyleInformation = BigPictureStyleInformation(
        FilePathAndroidBitmap(bigPicturePath),
        hideExpandedLargeIcon: true,
        contentTitle: title,
        htmlFormatContentTitle: true,
        summaryText: msg,
        htmlFormatSummaryText: true);
    var androidPlatformChannelSpecifics = AndroidNotificationDetails(
      'com.sreekanth.flutterquiz', //channel id
      'flutterquiz', //channel name
      channelDescription: 'flutterquiz',
      largeIcon: FilePathAndroidBitmap(largeIconPath),
      styleInformation: bigPictureStyleInformation,
    );
    var platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);
    await flutterLocalNotificationsPlugin
        .show(0, title, msg, platformChannelSpecifics, payload: payloads);
  }

  Future<String> _downloadAndSaveFile(String url, String fileName) async {
    final Directory directory = await getApplicationDocumentsDirectory();
    final String filePath = '${directory.path}/$fileName';
    final http.Response response = await http.get(Uri.parse(url));
    final File file = File(filePath);
    await file.writeAsBytes(response.bodyBytes);
    return filePath;
  }

  // notification on foreground
  Future<void> generateSimpleNotification(
      String title, String body, String payloads) async {
    var androidPlatformChannelSpecifics = AndroidNotificationDetails(
        'com.sreekanth.flutterquiz', //channel id
        'flutterquiz', //channel name
        channelDescription: 'flutterquiz',
        importance: Importance.max,
        priority: Priority.high,
        ticker: 'ticker');
    const DarwinNotificationDetails iosNotificationDetails =
        DarwinNotificationDetails();

    var platformChannelSpecifics = NotificationDetails(
        android: androidPlatformChannelSpecifics, iOS: iosNotificationDetails);
    await flutterLocalNotificationsPlugin
        .show(0, title, body, platformChannelSpecifics, payload: payloads);
  }

  void showUpdateNameBottomSheet() {
    final updateUserDetailCubit = context.read<UpdateUserDetailCubit>();
    showModalBottomSheet(
        isDismissible: false,
        enableDrag: false,
        isScrollControlled: true,
        elevation: 5.0,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20.0),
          topRight: Radius.circular(20.0),
        )),
        context: context,
        builder: (context) {
          return EditProfileFieldBottomSheetContainer(
              canCloseBottomSheet: false,
              fieldTitle: nameLbl,
              fieldValue: context.read<UserDetailsCubit>().getUserName(),
              numericKeyboardEnable: false,
              updateUserDetailCubit: updateUserDetailCubit);
        });
  }

  @override
  void dispose() {
    ProfileManagementLocalDataSource.updateReversedCoins(0);

    profileAnimationController.dispose();
    selfChallengeAnimationController.dispose();
    firstAnimationController.dispose();
    secondAnimationController.dispose();

    WidgetsBinding.instance.removeObserver(this);
    _controller.dispose();

    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    //show you left the game
    if (state == AppLifecycleState.resumed) {
      UiUtils.needToUpdateCoinsLocally(context);
    } else {
      ProfileManagementLocalDataSource.updateReversedCoins(0);
    }
  }

  void startAnimation() async {
    selfChallengeAnimationController.forward().then((value) async {
      await profileAnimationController.forward();
      await selfChallengeAnimationController.reverse();
      profileAnimationController.reverse();
    });
  }

  Widget _buildProfileContainer(double statusBarPadding) {
    return Align(
      alignment: Alignment.topCenter,
      child: GestureDetector(
        onTap: () {
          //
          if (widget.isGuest) {
            Navigator.of(context).pushNamed(Routes.menuScreen, arguments: true);
          } else {
            Navigator.of(context)
                .pushNamed(Routes.menuScreen, arguments: false);
          }
        },
        child: SlideTransition(
          position: profileSlideAnimation,
          child: Container(
            child: BlocBuilder<UserDetailsCubit, UserDetailsState>(
              bloc: context.read<UserDetailsCubit>(),
              builder: (context, state) {
                if (state is UserDetailsFetchSuccess) {
                  return LayoutBuilder(builder: (context, constaint) {
                    return Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(2),
                          width: constaint.maxWidth * 0.15,
                          height: constaint.maxWidth * 0.15,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                                color: Theme.of(context).primaryColor,
                                width: 0.5),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: CachedNetworkImage(
                              fit: BoxFit.cover,
                              imageUrl: state.userProfile.profileUrl!,
                            ),
                          ),
                        ),
                        SizedBox(
                          width: MediaQuery.of(context).size.width * (0.03),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: constaint.maxWidth * 0.6,
                              child: RichText(
                                maxLines: 1,
                                text: TextSpan(
                                    style: TextStyle(
                                        fontSize: 18.0,
                                        fontWeight: FontWeight.bold),
                                    children: [
                                      TextSpan(
                                          text: AppLocalization.of(context)!
                                                  .getTranslatedValues(
                                                      helloKey) ??
                                              helloKey,
                                          style: TextStyle(
                                            fontSize: 18.0,
                                            fontWeight: FontWeight.bold,
                                            color: Theme.of(context)
                                                .colorScheme
                                                .onTertiary,
                                          )),
                                      TextSpan(
                                        text:
                                            " ${state.userProfile.name ?? ""}",
                                        style: TextStyle(
                                          fontSize: 18.0,
                                          fontWeight: FontWeight.bold,
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onTertiary,
                                        ),
                                      )
                                    ]),
                              ),
                            ),
                            Text(
                              AppLocalization.of(context)!
                                  .getTranslatedValues(letsPlay)!,
                              style: TextStyle(
                                fontSize: 13.0,
                                color: Theme.of(context)
                                    .canvasColor
                                    .withOpacity(0.5),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                        Spacer(),
                        Container(
                          width: MediaQuery.of(context).size.width * 0.12,
                          height: MediaQuery.of(context).size.width * 0.12,
                          decoration: BoxDecoration(
                            color: Theme.of(context).primaryColor,
                            borderRadius: BorderRadius.circular(10.0),
                          ),
                          child: IconButton(
                            onPressed: () {
                              Navigator.of(context)
                                  .pushNamed(Routes.leaderBoard);
                            },
                            icon: SvgPicture.asset(
                              UiUtils.getImagePath("icon_leaderboard.svg"),
                              color: Theme.of(context).backgroundColor,
                            ),
                          ),
                        ),
                      ],
                    );
                  });
                }
                return Container();
              },
            ),
            margin: EdgeInsets.only(
                top: statusBarPadding + 30,
                left: MediaQuery.of(context).size.width * 0.06,
                right: MediaQuery.of(context).size.width * 0.06),
            width: MediaQuery.of(context).size.width,
          ),
        ),
      ),
    );
  }

  Widget _buildProfileGuestContainer(double statusBarPadding) {
    return Align(
      alignment: Alignment.topCenter,
      child: GestureDetector(
        onTap: () {
          //

          if (widget.isGuest) {
            Navigator.of(context).pushNamed(Routes.menuScreen, arguments: true);
          } else {
            Navigator.of(context)
                .pushNamed(Routes.menuScreen, arguments: false);
          }
        },
        child: SlideTransition(
          position: profileSlideAnimation,
          child: Container(
            child: LayoutBuilder(builder: (context, constaint) {
              return Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(2),
                    width: constaint.maxWidth * 0.15,
                    height: constaint.maxWidth * 0.15,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color: Theme.of(context).primaryColor, width: 0.5),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: CachedNetworkImage(
                          fit: BoxFit.cover,
                          imageUrl: "",
                          errorWidget: (context, imageUrl, _) => Image(
                              image: AssetImage(
                                  UiUtils.getprofileImagePath("2.png")))),
                    ),
                  ),
                  SizedBox(
                    width: MediaQuery.of(context).size.width * (0.03),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: constaint.maxWidth * 0.6,
                        child: RichText(
                          maxLines: 1,
                          text: TextSpan(
                              style: TextStyle(
                                  fontSize: 18.0, fontWeight: FontWeight.bold),
                              children: [
                                TextSpan(
                                    text: AppLocalization.of(context)!
                                            .getTranslatedValues(helloKey) ??
                                        helloKey,
                                    style: TextStyle(
                                      fontSize: 18.0,
                                      fontWeight: FontWeight.bold,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onTertiary,
                                    )),
                                TextSpan(
                                  text: " Guest",
                                  style: TextStyle(
                                    fontSize: 18.0,
                                    fontWeight: FontWeight.bold,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onTertiary,
                                  ),
                                )
                              ]),
                        ),
                      ),
                      Text(
                        AppLocalization.of(context)!
                            .getTranslatedValues(letsPlay)!,
                        style: TextStyle(
                          fontSize: 13.0,
                          color: Theme.of(context).canvasColor.withOpacity(0.5),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                  Spacer(),
                  Container(
                    width: MediaQuery.of(context).size.width * 0.12,
                    height: MediaQuery.of(context).size.width * 0.12,
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor,
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                    child: IconButton(
                      onPressed: () {
                        widget.isGuest
                            ? showDialog(
                                context: context,
                                builder: (_) =>
                                    guestModeDialog(onTapYesButton: () {
                                      Navigator.of(context).pop();
                                      Navigator.of(context)
                                          .pushReplacementNamed(Routes.login);
                                    }))
                            : Navigator.of(context)
                                .pushNamed(Routes.leaderBoard);
                      },
                      icon: SvgPicture.asset(
                        UiUtils.getImagePath("icon_leaderboard.svg"),
                        color: Theme.of(context).backgroundColor,
                      ),
                    ),
                  ),
                ],
              );
            }),
            margin: EdgeInsets.only(
                top: statusBarPadding + 30,
                left: MediaQuery.of(context).size.width * 0.06,
                right: MediaQuery.of(context).size.width * 0.06),
            width: MediaQuery.of(context).size.width,
          ),
        ),
      ),
    );
  }

  Widget _buildScoreRank(double statusBarPadding) {
    return Align(
      alignment: Alignment.topCenter,
      child: SlideTransition(
        position: profileSlideAnimation,
        child: Container(
          height: MediaQuery.of(context).size.height * 0.16,
          padding: const EdgeInsets.symmetric(vertical: 12.5, horizontal: 20.0),
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(15.0)),
          child: LayoutBuilder(builder: (context, boxConstraints) {
            return Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned(
                    top: 0,
                    left: boxConstraints.maxWidth * (0.06),
                    right: boxConstraints.maxWidth * (0.06),
                    child: Container(
                      decoration: BoxDecoration(
                          color: Colors.transparent,
                          boxShadow: const [
                            BoxShadow(
                                offset: Offset(0, 40),
                                blurRadius: 30,
                                spreadRadius: 5,
                                color: Color(0xffEF5488))
                          ],
                          borderRadius: BorderRadius.only(
                              bottomRight: Radius.circular(
                                  boxConstraints.maxWidth * (0.525)),
                              bottomLeft: Radius.circular(
                                  boxConstraints.maxWidth * (0.525)))),
                      width: boxConstraints.maxWidth,
                      height: boxConstraints.maxHeight * (0.6),
                    )),
                Positioned(
                    child: Container(
                  child: BlocBuilder<UserDetailsCubit, UserDetailsState>(
                    bloc: context.read<UserDetailsCubit>(),
                    builder: (context, state) {
                      if (state is UserDetailsFetchSuccess) {
                        return LayoutBuilder(
                          builder: (context, constraints) {
                            return Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                UserAchievementContainer(
                                    title: AppLocalization.of(context)!
                                        .getTranslatedValues("rankLbl")!,
                                    value:
                                        state.userProfile.allTimeRank ?? "0"),
                                UserAchievementContainer(
                                    title: AppLocalization.of(context)!
                                        .getTranslatedValues("coinsLbl")!,
                                    value: state.userProfile.coins ?? "0"),
                                UserAchievementContainer(
                                    title: AppLocalization.of(context)!
                                        .getTranslatedValues("scoreLbl")!,
                                    value: UiUtils.formatNumber(int.parse(
                                        state.userProfile.allTimeScore ??
                                            "0"))),
                              ], //
                            );
                          },
                        );
                      }
                      return Container();
                    },
                  ),
                  padding: const EdgeInsets.symmetric(
                      vertical: 12.5, horizontal: 20.0),
                  decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Theme.of(context).primaryColor,
                          Theme.of(context).colorScheme.secondary
                        ],
                        begin: Alignment.bottomLeft,
                        end: Alignment.topRight,
                      ),
                      borderRadius: BorderRadius.circular(15.0)),
                  width: boxConstraints.maxWidth,
                  height: boxConstraints.maxHeight,
                )),
              ],
            );
          }),
        ),
      ),
    );
  }

  Widget _buildScoreGuestRank(double statusBarPadding) {
    return Align(
      alignment: Alignment.topCenter,
      child: SlideTransition(
        position: profileSlideAnimation,
        child: Container(
          height: MediaQuery.of(context).size.height * 0.16,
          padding: const EdgeInsets.symmetric(vertical: 12.5, horizontal: 20.0),
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(15.0)),
          child: LayoutBuilder(builder: (context, boxConstraints) {
            return Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned(
                    top: 0,
                    left: boxConstraints.maxWidth * (0.06),
                    right: boxConstraints.maxWidth * (0.06),
                    child: Container(
                      decoration: BoxDecoration(
                          color: Colors.transparent,
                          boxShadow: const [
                            BoxShadow(
                                offset: Offset(0, 40),
                                blurRadius: 30,
                                spreadRadius: 5,
                                color: Color(0xffEF5488))
                          ],
                          borderRadius: BorderRadius.only(
                              bottomRight: Radius.circular(
                                  boxConstraints.maxWidth * (0.525)),
                              bottomLeft: Radius.circular(
                                  boxConstraints.maxWidth * (0.525)))),
                      width: boxConstraints.maxWidth,
                      height: boxConstraints.maxHeight * (0.6),
                    )),
                Positioned(
                    child: Container(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      return Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          UserAchievementContainer(
                              title: AppLocalization.of(context)!
                                  .getTranslatedValues("rankLbl")!,
                              value: "0"),
                          UserAchievementContainer(
                              title: AppLocalization.of(context)!
                                  .getTranslatedValues("coinsLbl")!,
                              value: "0"),
                          UserAchievementContainer(
                              title: AppLocalization.of(context)!
                                  .getTranslatedValues("scoreLbl")!,
                              value: UiUtils.formatNumber(int.parse("0"))),
                        ], //
                      );
                    },
                  ),
                  padding: const EdgeInsets.symmetric(
                      vertical: 12.5, horizontal: 20.0),
                  decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Theme.of(context).primaryColor,
                          Theme.of(context).colorScheme.secondary
                        ],
                        begin: Alignment.bottomLeft,
                        end: Alignment.topRight,
                      ),
                      borderRadius: BorderRadius.circular(15.0)),
                  width: boxConstraints.maxWidth,
                  height: boxConstraints.maxHeight,
                )),
              ],
            );
          }),
        ),
      ),
    );
  }

  Widget _buildCategoryView() {
    return Padding(
      padding: EdgeInsets.only(
          left: MediaQuery.of(context).size.width * 0.06,
          right: MediaQuery.of(context).size.width * 0.06,
          top: MediaQuery.of(context).size.height * 0.029),
      child: Row(
        children: [
          Text(
            AppLocalization.of(context)!.getTranslatedValues("quizZone")!,
            style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: Theme.of(context).colorScheme.onTertiary),
          ),
          Spacer(),
          GestureDetector(
            onTap: () {
              //   cateLength = false;
              widget.isGuest
                  ? showDialog(
                      context: context,
                      builder: (_) => guestModeDialog(onTapYesButton: () {
                            Navigator.of(context).pop();
                            Navigator.of(context)
                                .pushReplacementNamed(Routes.login);
                          }))
                  : Navigator.of(context).pushNamed(Routes.category,
                      arguments: {"quizType": QuizTypes.quizZone});
            },
            child: Text(
              AppLocalization.of(context)?.getTranslatedValues(viewAllKey) ??
                  viewAllKey,
              style: TextStyle(
                  fontSize: 14,
                  decoration: TextDecoration.underline,
                  color: Theme.of(context)
                      .colorScheme
                      .onTertiary
                      .withOpacity(0.6)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategory() {
    return Wrap(
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).size.width * 0.06),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(15.0),
              ),
              child: LayoutBuilder(builder: (context, boxConstraints) {
                return Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Positioned(
                        top: 0,
                        left: boxConstraints.maxWidth * (0.1),
                        right: boxConstraints.maxWidth * (0.1),
                        child: Container(
                          decoration: BoxDecoration(
                              color: Colors.transparent,
                              boxShadow: const [
                                BoxShadow(
                                    offset: Offset(0, 50),
                                    blurRadius: 30,
                                    spreadRadius: 5,
                                    color: Color(0xbf000000))
                              ],
                              borderRadius: BorderRadius.only(
                                  bottomRight: Radius.circular(
                                      boxConstraints.maxWidth * (0.525)),
                                  bottomLeft: Radius.circular(
                                      boxConstraints.maxWidth * (0.525)))),
                          width: boxConstraints.maxWidth,
                          height: boxConstraints.maxHeight * (0.6),
                        )),
                    Positioned(
                      child: Container(
                        clipBehavior: Clip.none,
                        margin: EdgeInsets.only(
                            top: MediaQuery.of(context).size.height * 0.01,
                            left: MediaQuery.of(context).size.width * 0.06,
                            right: MediaQuery.of(context).size.width * 0.06),
                        width: MediaQuery.of(context).size.width,
                        decoration: BoxDecoration(
                          color: Theme.of(context).backgroundColor,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Column(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: Stack(
                                clipBehavior: Clip.none,
                                children: [
                                  Padding(
                                    padding:
                                        EdgeInsets.only(left: 12, right: 12),
                                    child: Column(
                                      children: [
                                        Row(
                                          children: [
                                            SizedBox(
                                              width: MediaQuery.of(context)
                                                      .size
                                                      .width *
                                                  0.03,
                                            ),
                                          ],
                                        ),
                                        showCategory(),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              }),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    if (!cateLength) {
                      showCategory();
                    } else {
                      showCategory();
                    }
                  });
                },
                child: Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                      border: Border.all(color: Colors.transparent),
                      shape: BoxShape.circle,
                      color: Theme.of(context).scaffoldBackgroundColor),
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        if (!cateLength) {
                          showCategory();
                        } else {
                          showCategory();
                        }
                      });
                    },
                    child: Container(
                      width: 30,
                      height: 30,
                      margin: EdgeInsets.all(5),
                      decoration: BoxDecoration(
                          color: Theme.of(context).backgroundColor,
                          boxShadow: <BoxShadow>[
                            BoxShadow(
                              color: Color.fromARGB(255, 218, 218, 218),
                              blurRadius: 10.0, // soften the shadow
                              spreadRadius: 0.0, //extend the shadow
                              offset: Offset(
                                0.0, // Move to right 10  horizontally
                                2.0, // Move to bottom 10 Vertically
                              ),
                            )
                          ],
                          shape: BoxShape.circle),
                      child: Icon(
                        !cateLength
                            ? Icons.keyboard_arrow_down_outlined
                            : Icons.keyboard_arrow_up_outlined,
                        color: Theme.of(context).colorScheme.secondary,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget showCategory() {
    return BlocConsumer<QuizoneCategoryCubit, QuizoneCategoryState>(
        bloc: context.read<QuizoneCategoryCubit>(),
        listener: (context, state) {
          if (state is QuizoneCategoryFailure) {
            if (state.errorMessage == unauthorizedAccessCode) {
              //
              print(state.errorMessage);
              UiUtils.showAlreadyLoggedInDialog(context: context);
            }
          }
          if (state is QuizCategorySuccess) {}
        },
        builder: (context, state) {
          if (state is QuizoneCategoryProgress ||
              state is QuizoneCategoryInitial) {
            return Center(
              child: CircularProgressContainer(
                useWhiteLoader: false,
              ),
            );
          }
          if (state is QuizoneCategoryFailure) {
            return ErrorContainer(
              showRTryButton: false,
              showBackButton: false,
              errorMessageColor: Theme.of(context).primaryColor,
              showErrorImage: false,
              errorMessage: AppLocalization.of(context)!.getTranslatedValues(
                convertErrorCodeToLanguageKey(state.errorMessage),
              ),
              onTapRetry: () {
                context.read<QuizoneCategoryCubit>().getQuizCategory(
                      languageId: UiUtils.getCurrentQuestionLanguageId(context),
                      userId: context.read<UserDetailsCubit>().getUserId(),
                    );
              },
            );
          }
          final categoryList = (state as QuizoneCategorySuccess).categories;
          final index;
          if (!cateLength) {
            if (categoryList.length < 2) {
              index = 1;
            } else {
              index = 2;
            }
            cateLength = true;
          } else {
            if (categoryList.length > 10) {
              index = 10;
            } else {
              index = categoryList.length;
            }
            cateLength = false;
          }
          return ListView.builder(
            padding: EdgeInsets.only(
              bottom: 10,
            ),
            // scrollDirection: Axis.horizontal,
            shrinkWrap: true,
            itemCount: index,
            physics: NeverScrollableScrollPhysics(),
            itemBuilder: (BuildContext context, int index) {
              return GestureDetector(
                onTap: () {
                  //noOf means how many subcategory it has
                  //if subcategory is 0 then check for level
                  if (widget.isGuest) {
                    showDialog(
                        context: context,
                        builder: (_) => guestModeDialog(onTapYesButton: () {
                              Navigator.of(context).pop();
                              Navigator.of(context)
                                  .pushReplacementNamed(Routes.login);
                            }));
                  } else {
                    if (categoryList[index].noOf == "0") {
                      //means this category does not have level
                      if (categoryList[index].maxLevel == "0") {
                        //direct move to quiz screen pass level as 0
                        Navigator.of(context)
                            .pushNamed(Routes.quiz, arguments: {
                          "numberOfPlayer": 1,
                          "quizType": QuizTypes.quizZone,
                          "categoryId": categoryList[index].id,
                          "subcategoryId": "",
                          "level": "0",
                          "subcategoryMaxLevel": "0",
                          "unlockedLevel": 0,
                          "contestId": "",
                          "comprehensionId": "",
                          "quizName": "Quiz Zone"
                        });
                      } else {
                        //navigate to level screen
                        Navigator.of(context)
                            .pushNamed(Routes.levels, arguments: {
                          "maxLevel": categoryList[index].maxLevel,
                          "categoryId": categoryList[index].id,
                        });
                      }
                    } else {
                      Navigator.of(context).pushNamed(
                          Routes.subcategoryAndLevel,
                          arguments: categoryList[index].id);
                    }
                  }
                },
                child: Wrap(
                  children: [
                    Container(
                        child: ListTile(
                            horizontalTitleGap: 15,
                            contentPadding: EdgeInsets.zero,
                            leading: ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: CachedNetworkImage(
                                  fit: BoxFit.cover,
                                  width:
                                      MediaQuery.of(context).size.width * 0.125,
                                  height:
                                      MediaQuery.of(context).size.width * 0.125,
                                  placeholder: (context, _) => SizedBox(),
                                  imageUrl: categoryList[index].image!,
                                  errorWidget: (context, imageUrl, _) => Image(
                                      image: AssetImage(UiUtils.getImagePath(
                                          "ic_launcher.png")))),
                            ),
                            trailing: Icon(
                              Icons.arrow_forward_ios_outlined,
                              color: Theme.of(context).colorScheme.onTertiary,
                            ),
                            title: Text(
                              categoryList[index].categoryName!,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.onTertiary,
                              ),
                            ),
                            subtitle: Text(
                              "Question: " + categoryList[index].noOfQqe!,
                              style: TextStyle(
                                  fontSize: 14,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onTertiary
                                      .withOpacity(0.6)),
                            ))),
                  ],
                ),
              );
            },
          );
        });
  }

  Widget _smartExample() {
    return Container(
      width: MediaQuery.of(context).size.width * (0.85),
      height: 120, //MediaQuery.of(context).size.height * (0.15),
      margin: const EdgeInsets.symmetric(
        horizontal: 20.0,
        vertical: 10.0,
      ),
      child: LayoutBuilder(builder: (context, boxConstraints) {
        return Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(
                top: 0,
                left: boxConstraints.maxWidth * (0.06),
                right: boxConstraints.maxWidth * (0.06),
                child: Container(
                  decoration: BoxDecoration(
                      color: Colors.transparent,
                      boxShadow: const [
                        BoxShadow(
                            offset: Offset(0, 40),
                            blurRadius: 30,
                            spreadRadius: 5,
                            color: Color(0xbf000000))
                      ],
                      borderRadius: BorderRadius.only(
                          bottomRight: Radius.circular(
                              boxConstraints.maxWidth * (0.525)),
                          bottomLeft: Radius.circular(
                              boxConstraints.maxWidth * (0.525)))),
                  width: boxConstraints.maxWidth,
                  height: boxConstraints.maxHeight * (0.6),
                )),
            Positioned(
                child: Container(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          "widget.appTitle",
                          style: TextStyle(
                              fontSize: 14, //
                              fontWeight: FontWeight.w600,
                              color: Theme.of(context).colorScheme.primary),
                        ),
                      ),
                      const SizedBox(
                        height: 10,
                      ),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Container(
                            width: 40,
                            height: 5,
                            decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.primary,
                                borderRadius: BorderRadius.circular(2.0))),
                      ),
                      const SizedBox(
                        height: 10,
                      ),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          " Screens",
                          style: TextStyle(
                              color: Theme.of(context).colorScheme.onSecondary,
                              fontWeight: FontWeight.w400,
                              fontSize: 14.0),
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                ],
              ),
              padding:
                  const EdgeInsets.symmetric(vertical: 12.5, horizontal: 20.0),
              decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.background,
                  borderRadius: BorderRadius.circular(15.0)),
              width: boxConstraints.maxWidth,
              height: boxConstraints.maxHeight,
            )),
          ],
        );
      }),
    );
  }

  Widget _buildBattle() {
    return battleName.isNotEmpty
        ? Padding(
            padding: EdgeInsets.only(
              left: MediaQuery.of(context).size.width * 0.06,
              right: MediaQuery.of(context).size.width * 0.06,
              top: MediaQuery.of(context).size.height * 0.03,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppLocalization.of(context)
                          ?.getTranslatedValues(battleOfTheDayKey) ??
                      battleOfTheDayKey, //
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: Theme.of(context).colorScheme.onTertiary),
                ),
                GridView.count(
                  // Create a grid with 2 columns. If you change the scrollDirection to
                  // horizontal, this produces 2 rows.
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  mainAxisSpacing: 20,
                  padding: EdgeInsets.only(
                      top: MediaQuery.of(context).padding.top * 0.2),
                  crossAxisSpacing: 20,
                  scrollDirection: Axis.vertical,
                  physics: NeverScrollableScrollPhysics(),
                  // Generate 100 widgets that display their index in the List.
                  children: List.generate(battleName.length, (index) {
                    return Stack(
                      children: [
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              cateLength = false;
                              widget.isGuest
                                  ? showDialog(
                                      context: context,
                                      builder: (_) =>
                                          guestModeDialog(onTapYesButton: () {
                                            Navigator.of(context).pop();
                                            Navigator.of(context)
                                                .pushReplacementNamed(
                                                    Routes.login);
                                          }))
                                  : _onPressedBattle(battleName[index]);
                            });
                          },
                          child: Container(
                            child: LayoutBuilder(
                                builder: (context, boxConstraints) {
                              return Stack(
                                clipBehavior: Clip.none,
                                children: [
                                  Positioned(
                                      top: 0,
                                      left: boxConstraints.maxWidth * (0.2),
                                      right: boxConstraints.maxWidth * (0.2),
                                      child: Container(
                                        decoration: BoxDecoration(
                                            color: Colors.transparent,
                                            boxShadow: const [
                                              BoxShadow(
                                                  offset: Offset(0, 50),
                                                  blurRadius: 30,
                                                  spreadRadius: 5,
                                                  color: Color(0xbf000000))
                                            ],
                                            borderRadius: BorderRadius.only(
                                                bottomRight: Radius.circular(
                                                    boxConstraints.maxWidth *
                                                        (0.525)),
                                                bottomLeft: Radius.circular(
                                                    boxConstraints.maxWidth *
                                                        (0.525)))),
                                        width: boxConstraints.maxWidth,
                                        height:
                                            boxConstraints.maxHeight * (0.6),
                                      )),
                                  Positioned(
                                    child: Container(
                                      width: boxConstraints.maxWidth,
                                      height: boxConstraints.maxHeight,
                                      decoration: BoxDecoration(
                                          borderRadius:
                                              BorderRadius.circular(10),
                                          color: Theme.of(context)
                                              .backgroundColor),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(10),
                                        child: Stack(
                                          children: [
                                            Padding(
                                              padding: EdgeInsets.only(
                                                  top: MediaQuery.of(context)
                                                          .size
                                                          .height *
                                                      0.01,
                                                  left: MediaQuery.of(context)
                                                          .size
                                                          .width *
                                                      0.02,
                                                  right: MediaQuery.of(context)
                                                          .size
                                                          .width *
                                                      0.02),
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    AppLocalization.of(context)!
                                                        .getTranslatedValues(
                                                            battleName[index])!,
                                                    style: TextStyle(
                                                        fontSize: 16,
                                                        fontWeight:
                                                            FontWeight.normal,
                                                        color: Theme.of(context)
                                                            .colorScheme
                                                            .onTertiary),
                                                    maxLines: 2,
                                                  ),
                                                  SizedBox(
                                                    height:
                                                        MediaQuery.of(context)
                                                                .size
                                                                .height *
                                                            0.01,
                                                  ),
                                                  Text(
                                                    AppLocalization.of(context)!
                                                        .getTranslatedValues(
                                                            battleDesc[index])!,
                                                    style: TextStyle(
                                                        fontSize: 12,
                                                        color: Theme.of(context)
                                                            .colorScheme
                                                            .onTertiary
                                                            .withOpacity(0.6)),
                                                    maxLines: 2,
                                                  ),
                                                ],
                                              ),
                                            ),
                                            Padding(
                                              padding:
                                                  EdgeInsets.only(right: 10),
                                              child: Align(
                                                alignment:
                                                    Alignment.bottomRight,
                                                child: SizedBox(
                                                    width:
                                                        MediaQuery.of(context)
                                                                .size
                                                                .width *
                                                            0.09,
                                                    height:
                                                        MediaQuery.of(context)
                                                                .size
                                                                .height *
                                                            0.09,
                                                    child: SvgPicture.asset(
                                                      UiUtils.getImagePath(
                                                          battleImg[index]),
                                                      color: Theme.of(context)
                                                          .primaryColor,
                                                    )),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            }),
                          ),
                        ),
                      ],
                    );
                  }),
                ),
              ],
            ),
          )
        : SizedBox();
  }

  Widget _buildExamSelf() {
    return examSelf.isNotEmpty
        ? Container(
            child: Padding(
              padding: EdgeInsets.only(
                left: MediaQuery.of(context).size.width * 0.06,
                right: MediaQuery.of(context).size.width * 0.06,
                top: MediaQuery.of(context).size.height * 0.04,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppLocalization.of(context)
                            ?.getTranslatedValues(selfExamZoneKey) ??
                        selfExamZoneKey,
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: Theme.of(context).colorScheme.onTertiary),
                  ),
                  GridView.count(
                    // Create a grid with 2 columns. If you change the scrollDirection to
                    // horizontal, this produces 2 rows.
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    mainAxisSpacing: 20,
                    padding: EdgeInsets.only(
                        top: MediaQuery.of(context).padding.top * 0.2),
                    crossAxisSpacing: 20,
                    scrollDirection: Axis.vertical,
                    physics: NeverScrollableScrollPhysics(),
                    // Generate 100 widgets that display their index in the List.
                    children: List.generate(examSelf.length, (index) {
                      return Stack(
                        children: [
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                cateLength = false;
                                widget.isGuest
                                    ? showDialog(
                                        context: context,
                                        builder: (_) =>
                                            guestModeDialog(onTapYesButton: () {
                                              Navigator.of(context).pop();
                                              Navigator.of(context)
                                                  .pushReplacementNamed(
                                                      Routes.login);
                                            }))
                                    : _onPressedSelfexam(examSelf[index]);
                              });
                            },
                            child: Container(
                              child: LayoutBuilder(
                                  builder: (context, boxConstraints) {
                                return Stack(
                                  clipBehavior: Clip.none,
                                  children: [
                                    Positioned(
                                        top: 0,
                                        left: boxConstraints.maxWidth * (0.2),
                                        right: boxConstraints.maxWidth * (0.2),
                                        child: Container(
                                          decoration: BoxDecoration(
                                              color: Colors.transparent,
                                              boxShadow: const [
                                                BoxShadow(
                                                    offset: Offset(0, 50),
                                                    blurRadius: 30,
                                                    spreadRadius: 5,
                                                    color: Color(0xbf000000))
                                              ],
                                              borderRadius: BorderRadius.only(
                                                  bottomRight: Radius.circular(
                                                      boxConstraints.maxWidth *
                                                          (0.525)),
                                                  bottomLeft: Radius.circular(
                                                      boxConstraints.maxWidth *
                                                          (0.525)))),
                                          width: boxConstraints.maxWidth,
                                          height:
                                              boxConstraints.maxHeight * (0.6),
                                        )),
                                    Positioned(
                                      child: Container(
                                        width: boxConstraints.maxWidth,
                                        height: boxConstraints.maxHeight,
                                        decoration: BoxDecoration(
                                            borderRadius:
                                                BorderRadius.circular(10),
                                            color: Theme.of(context)
                                                .backgroundColor),
                                        child: ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(10),
                                          child: Stack(
                                            children: [
                                              Padding(
                                                padding: EdgeInsets.only(
                                                    top: MediaQuery.of(context)
                                                            .size
                                                            .height *
                                                        0.01,
                                                    left: MediaQuery.of(context)
                                                            .size
                                                            .width *
                                                        0.02,
                                                    right:
                                                        MediaQuery.of(context)
                                                                .size
                                                                .width *
                                                            0.02),
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      AppLocalization.of(
                                                              context)!
                                                          .getTranslatedValues(
                                                              examSelf[index])!,
                                                      style: TextStyle(
                                                          fontSize: 16,
                                                          fontWeight:
                                                              FontWeight.normal,
                                                          color:
                                                              Theme.of(context)
                                                                  .colorScheme
                                                                  .onTertiary),
                                                      maxLines: 2,
                                                    ),
                                                    SizedBox(
                                                      height:
                                                          MediaQuery.of(context)
                                                                  .size
                                                                  .height *
                                                              0.01,
                                                    ),
                                                    Text(
                                                      AppLocalization.of(
                                                              context)!
                                                          .getTranslatedValues(
                                                              examSelfdesc[
                                                                  index])!,
                                                      style: TextStyle(
                                                          fontSize: 12,
                                                          color:
                                                              Theme.of(context)
                                                                  .colorScheme
                                                                  .onTertiary
                                                                  .withOpacity(
                                                                      0.6)),
                                                      maxLines: 2,
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              Padding(
                                                padding:
                                                    EdgeInsets.only(right: 10),
                                                child: Align(
                                                  alignment:
                                                      Alignment.bottomRight,
                                                  child: SizedBox(
                                                      width:
                                                          MediaQuery.of(context)
                                                                  .size
                                                                  .width *
                                                              0.09,
                                                      height:
                                                          MediaQuery.of(context)
                                                                  .size
                                                                  .height *
                                                              0.09,
                                                      child: SvgPicture.asset(
                                                        UiUtils.getImagePath(
                                                            examSelfimg[index]),
                                                        color: Theme.of(context)
                                                            .primaryColor,
                                                      )),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                );
                              }),
                            ),
                          ),
                        ],
                      );
                    }),
                  ),
                ],
              ),
            ),
          )
        : SizedBox();
  }

  Widget _buildZones() {
    return Padding(
      padding: EdgeInsets.only(
        left: MediaQuery.of(context).size.width * 0.06,
        right: MediaQuery.of(context).size.width * 0.06,
        top: MediaQuery.of(context).size.height * 0.04,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          playDifferentZone.isNotEmpty
              ? Text(
                  AppLocalization.of(context)
                          ?.getTranslatedValues(playDifferentZoneKey) ??
                      playDifferentZoneKey,
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: Theme.of(context).colorScheme.onTertiary),
                )
              : SizedBox(),
          GridView.count(
            // Create a grid with 2 columns. If you change the scrollDirection to
            // horizontal, this produces 2 rows.
            crossAxisCount: 2,
            shrinkWrap: true,
            mainAxisSpacing: 20,
            padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top * 0.2,
                bottom: MediaQuery.of(context).padding.top * 0.6),
            crossAxisSpacing: 20,
            scrollDirection: Axis.vertical,
            physics: NeverScrollableScrollPhysics(),
            // Generate 100 widgets that display their index in the List.
            children: List.generate(playDifferentZone.length, (index) {
              return Stack(
                children: [
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        cateLength = false;
                        widget.isGuest
                            ? showDialog(
                                context: context,
                                builder: (_) =>
                                    guestModeDialog(onTapYesButton: () {
                                      // Navigator.pop(context);
                                      Navigator.of(context).pop();
                                      Navigator.of(context)
                                          .pushReplacementNamed(Routes.login);
                                    }))
                            : _onPressedZone(playDifferentZone[index]);
                      });
                    },
                    child: Container(
                      child: LayoutBuilder(builder: (context, boxConstraints) {
                        return Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Positioned(
                                top: 0,
                                left: boxConstraints.maxWidth * (0.2),
                                right: boxConstraints.maxWidth * (0.2),
                                child: Container(
                                  decoration: BoxDecoration(
                                      color: Colors.transparent,
                                      boxShadow: const [
                                        BoxShadow(
                                            offset: Offset(0, 50),
                                            blurRadius: 30,
                                            spreadRadius: 5,
                                            color: Color(0xbf000000))
                                      ],
                                      borderRadius: BorderRadius.only(
                                          bottomRight: Radius.circular(
                                              boxConstraints.maxWidth *
                                                  (0.525)),
                                          bottomLeft: Radius.circular(
                                              boxConstraints.maxWidth *
                                                  (0.525)))),
                                  width: boxConstraints.maxWidth,
                                  height: boxConstraints.maxHeight * (0.6),
                                )),
                            Positioned(
                              child: Container(
                                width: boxConstraints.maxWidth,
                                height: boxConstraints.maxHeight,
                                decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(10),
                                    color: Theme.of(context).backgroundColor),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: Stack(
                                    children: [
                                      Padding(
                                        padding: EdgeInsets.only(
                                            top: MediaQuery.of(context)
                                                    .size
                                                    .height *
                                                0.01,
                                            left: MediaQuery.of(context)
                                                    .size
                                                    .width *
                                                0.02,
                                            right: MediaQuery.of(context)
                                                    .size
                                                    .width *
                                                0.02),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              AppLocalization.of(context)!
                                                  .getTranslatedValues(
                                                      playDifferentZone[
                                                          index])!,
                                              style: TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.normal,
                                                  color: Theme.of(context)
                                                      .colorScheme
                                                      .onTertiary
                                                  //  fontStyle: FontWeight.normal
                                                  ),
                                              maxLines: 2,
                                            ),
                                            SizedBox(
                                              height: MediaQuery.of(context)
                                                      .size
                                                      .height *
                                                  0.01,
                                            ),
                                            Text(
                                              AppLocalization.of(context)!
                                                  .getTranslatedValues(
                                                      playDifferentZoneDesc[
                                                          index])!,
                                              style: TextStyle(
                                                  fontSize: 12,
                                                  color: Theme.of(context)
                                                      .colorScheme
                                                      .onTertiary
                                                      .withOpacity(0.6)),
                                              maxLines: 2,
                                            ),
                                          ],
                                        ),
                                      ),
                                      Padding(
                                        padding: EdgeInsets.only(right: 10),
                                        child: Align(
                                          alignment: Alignment.bottomRight,
                                          child: SizedBox(
                                              width: MediaQuery.of(context)
                                                      .size
                                                      .width *
                                                  0.09,
                                              height: MediaQuery.of(context)
                                                      .size
                                                      .height *
                                                  0.09,
                                              child: SvgPicture.asset(
                                                UiUtils.getImagePath(
                                                    playDifferentImg[index]),
                                                color: Theme.of(context)
                                                    .primaryColor,
                                              )),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        );
                      }),
                    ),
                  ),
                ],
              );
            }),
          ),
        ],
      ),
    );
  }

  void _onPressedZone(String index) {
    if (index == "dailyQuiz") {
      if (context.read<SystemConfigCubit>().getIsDailyQuizAvailable() == "1") {
        Navigator.of(context).pushNamed(Routes.quiz, arguments: {
          "quizType": QuizTypes.dailyQuiz,
          "numberOfPlayer": 1,
          "quizName": "Daily Quiz"
        });
      } else {
        UiUtils.setSnackbar(
            AppLocalization.of(context)!
                .getTranslatedValues(currentlyNotAvailableKey)!,
            context,
            false);
      }
    } else if (index == "funAndLearn") {
      Navigator.of(context).pushNamed(Routes.category,
          arguments: {"quizType": QuizTypes.funAndLearn});
    } else if (index == "guessTheWord") {
      Navigator.of(context).pushNamed(Routes.category,
          arguments: {"quizType": QuizTypes.guessTheWord});
    } else if (index == "audioQuestions") {
      Navigator.of(context).pushNamed(Routes.category,
          arguments: {"quizType": QuizTypes.audioQuestions});
    } else if (index == "mathMania") {
      Navigator.of(context).pushNamed(Routes.category,
          arguments: {"quizType": QuizTypes.mathMania});
    } else if (index == "truefalse") {
      if (context.read<SystemConfigCubit>().getIsTrueFalseAvailable() == "1") {
        Navigator.of(context).pushNamed(Routes.quiz, arguments: {
          "quizType": QuizTypes.trueAndFalse,
          "numberOfPlayer": 1,
          "quizName": "True/False Quiz"
        });
      } else {
        UiUtils.setSnackbar(
            AppLocalization.of(context)!
                .getTranslatedValues(currentlyNotAvailableKey)!,
            context,
            false);
      }
    }
  }

  void _onPressedSelfexam(String index) {
    if (index == "exam") {
      context.read<ExamCubit>().updateState(ExamInitial());
      Navigator.of(context).pushNamed(Routes.exams);
    } else if (index == "selfChallengeLbl") {
      cateLength = false;
      context.read<QuizCategoryCubit>().updateState(QuizCategoryInitial());
      context.read<SubCategoryCubit>().updateState(SubCategoryInitial());
      Navigator.of(context).pushNamed(Routes.selfChallenge);
    }
  }

  void _onPressedBattle(String index) {
    if (index == "groupPlay") {
      {
        context
            .read<MultiUserBattleRoomCubit>()
            .updateState(MultiUserBattleRoomInitial());
        context.read<QuizCategoryCubit>().updateState(QuizCategoryInitial());
        showDialog(
            context: context,
            builder: (context) => MultiBlocProvider(providers: [
                  BlocProvider<UpdateScoreAndCoinsCubit>(
                      create: (_) => UpdateScoreAndCoinsCubit(
                          ProfileManagementRepository())),
                ], child: RoomDialog(quizType: QuizTypes.groupPlay)));
      }
    } else if (index == "battleQuiz") {
      {
        context.read<BattleRoomCubit>().updateState(BattleRoomInitial());
        context.read<QuizCategoryCubit>().updateState(QuizCategoryInitial());

        showDialog(
          context: context,
          builder: (context) => MultiBlocProvider(providers: [
            BlocProvider<UpdateScoreAndCoinsCubit>(
                create: (_) =>
                    UpdateScoreAndCoinsCubit(ProfileManagementRepository())),
          ], child: RandomOrPlayFrdDialog()),
        );
      }
    }
  }

  Widget _buildContest() {
    return Stack(
      children: [
        BlocConsumer<ContestCubit, ContestState>(
            bloc: context.read<ContestCubit>(),
            listener: (context, state) {
              if (state is ContestFailure) {
                if (state.errorMessage == unauthorizedAccessCode) {
                  //
                  UiUtils.showAlreadyLoggedInDialog(
                    context: context,
                  );
                }
              }
            },
            builder: (context, state) {
              if (state is ContestProgress || state is ContestInitial) {
                return Center(
                    child: CircularProgressContainer(
                  useWhiteLoader: false,
                ));
              }
              if (state is ContestFailure) {
                print(state.errorMessage);
                return Container(
                  width: MediaQuery.of(context).size.width,
                  height: MediaQuery.of(context).size.width * 0.2,
                  margin: EdgeInsets.only(
                      left: MediaQuery.of(context).size.width * 0.055,
                      right: MediaQuery.of(context).size.width * 0.055,
                      top: MediaQuery.of(context).size.height * 0.02),
                  decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      color: Theme.of(context).backgroundColor),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Stack(
                      children: [
                        Padding(
                          padding: EdgeInsets.only(
                              left: MediaQuery.of(context).size.width * 0.02,
                              right: MediaQuery.of(context).size.width * 0.02),
                          child: Align(
                            alignment: Alignment.center,
                            child: Text(
                              AppLocalization.of(context)!.getTranslatedValues(
                                  convertErrorCodeToLanguageKey(
                                      state.errorMessage))!,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.normal,
                                  color: Theme.of(context).primaryColor),
                              maxLines: 2,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }
              final contestList = (state as ContestSuccess).contestList;
              return live(contestList.live);
            })
      ],
    );
  }

  Widget buildContestLive() {
    return Padding(
      padding: EdgeInsets.only(
          left: MediaQuery.of(context).size.width * 0.06,
          right: MediaQuery.of(context).size.width * 0.06,
          top: MediaQuery.of(context).size.height * 0.01),
      child: Row(
        children: [
          Text(
            AppLocalization.of(context)!.getTranslatedValues(contest) ??
                contest,
            style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: Theme.of(context).colorScheme.onTertiary),
          ),
          Spacer(),
          GestureDetector(
            onTap: () {
              cateLength = false;
              if (context.read<SystemConfigCubit>().getIsContestAvailable() ==
                  "1") {
                Navigator.of(context).pushNamed(Routes.contest);
              } else {
                UiUtils.setSnackbar(
                    AppLocalization.of(context)!
                        .getTranslatedValues(currentlyNotAvailableKey)!,
                    context,
                    false);
              }
            },
            child: Text(
              AppLocalization.of(context)?.getTranslatedValues(viewAllKey) ??
                  viewAllKey,
              style: TextStyle(
                  fontSize: 14,
                  decoration: TextDecoration.underline,
                  color: Theme.of(context)
                      .colorScheme
                      .onTertiary
                      .withOpacity(0.6)),
            ),
          ),
        ],
      ),
    );
  }

  Widget live(Contest data) {
    return data.errorMessage.isNotEmpty
        ? Container(
            width: MediaQuery.of(context).size.width,
            height: MediaQuery.of(context).size.width * 0.2,
            margin: EdgeInsets.only(
                left: MediaQuery.of(context).size.width * 0.055,
                right: MediaQuery.of(context).size.width * 0.055,
                top: MediaQuery.of(context).size.height * 0.02),
            decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: Theme.of(context).backgroundColor),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Stack(
                children: [
                  Center(
                    child: Text(
                      AppLocalization.of(context)!.getTranslatedValues(
                          convertErrorCodeToLanguageKey(data.errorMessage))!,
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).primaryColor),
                      maxLines: 2,
                    ),
                  ),
                ],
              ),
            ),
          )
        : Column(
            children: [
              Container(
                height: MediaQuery.of(context).size.height * 0.22,
                padding: const EdgeInsets.symmetric(
                    vertical: 12.5, horizontal: 20.0),
                decoration:
                    BoxDecoration(borderRadius: BorderRadius.circular(15.0)),
                child: LayoutBuilder(builder: (context, boxConstraints) {
                  return Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Positioned(
                          top: 0,
                          left: boxConstraints.maxWidth * (0.1),
                          right: boxConstraints.maxWidth * (0.1),
                          child: Container(
                            decoration: BoxDecoration(
                                color: Colors.transparent,
                                boxShadow: const [
                                  BoxShadow(
                                      offset: Offset(0, 50),
                                      blurRadius: 30,
                                      spreadRadius: 5,
                                      color: Color(0xbf000000))
                                ],
                                borderRadius: BorderRadius.only(
                                    bottomRight: Radius.circular(
                                        boxConstraints.maxWidth * (0.525)),
                                    bottomLeft: Radius.circular(
                                        boxConstraints.maxWidth * (0.525)))),
                            width: boxConstraints.maxWidth,
                            height: boxConstraints.maxHeight * (0.6),
                          )),
                      Positioned(
                          child: Container(
                        padding: const EdgeInsets.symmetric(
                            vertical: 12.5, horizontal: 20.0),
                        decoration: BoxDecoration(
                            color: Theme.of(context).backgroundColor,
                            borderRadius:
                                BorderRadius.all(Radius.circular(10))),
                        width: boxConstraints.maxWidth,
                        height: boxConstraints.maxHeight,
                        child: contestDesign(data, 0, 1),
                      )),
                    ],
                  );
                }),
              ),
            ],
          );
  }

  Widget contestDesign(dynamic data, int index, int type) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: ClipRRect(
                borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(10),
                    topRight: Radius.circular(10),
                    bottomRight: Radius.circular(10),
                    bottomLeft: Radius.circular(10)),
                child: CachedNetworkImage(
                  placeholder: (context, _) {
                    return Center(
                      child: CircularProgressContainer(
                        useWhiteLoader: false,
                      ),
                    );
                  },
                  imageBuilder: (context, imageProvider) {
                    return Container(
                      decoration: BoxDecoration(
                        image: DecorationImage(
                            image: imageProvider, fit: BoxFit.cover),
                        borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(10),
                            topRight: Radius.circular(10)),
                      ),
                    );
                  },
                  errorWidget: (context, image, error) {
                    print(error.toString());
                    return Center(
                      child: Icon(
                        Icons.error,
                        color: Theme.of(context).primaryColor,
                      ),
                    );
                  },
                  fit: BoxFit.cover,
                  width: 50,
                  height: 50,
                  imageUrl: data.contestDetails[index].image.toString(),
                ),
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsetsDirectional.only(start: 10),
                  child: Text(
                    data.contestDetails[index].name.toString(),
                    style: TextStyle(
                        color: Theme.of(context).colorScheme.onTertiary,
                        fontWeight: FontWeight.normal,
                        fontSize: 16),
                  ),
                ),
                Container(
                    padding: EdgeInsets.only(left: 10, bottom: 5),
                    child: Text(
                      data.contestDetails[index].description!,
                      maxLines: 2,
                      style: TextStyle(
                        fontSize: 12,
                        overflow: TextOverflow.ellipsis,
                        color: Theme.of(context)
                            .colorScheme
                            .onTertiary
                            .withOpacity(0.6),
                      ),
                    ))
              ],
            ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.only(left: 10, top: 10),
          child: Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        AppLocalization.of(context)!
                            .getTranslatedValues("entryFeesLbl")!,
                        style: TextStyle(
                          fontSize: 14,
                          color: Theme.of(context)
                              .colorScheme
                              .onTertiary
                              .withOpacity(0.6),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(left: 5),
                        child: Text(
                          data.contestDetails[index].entry.toString() +
                              " Coins",
                          style: TextStyle(
                              fontSize: 14,
                              color: Theme.of(context).colorScheme.onTertiary,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(
                    height: 5,
                  ),
                  Row(
                    children: [
                      Text(
                        AppLocalization.of(context)!
                            .getTranslatedValues("endsOnLbl")!,
                        style: TextStyle(
                          fontSize: 14,
                          color: Theme.of(context)
                              .colorScheme
                              .onTertiary
                              .withOpacity(0.6),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(left: 10),
                        child: Text(
                          data.contestDetails[index].endDate.toString() +
                              "  |  ",
                          style: TextStyle(
                              fontSize: 14,
                              color: Theme.of(context).colorScheme.onTertiary,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                      Text(
                        data.contestDetails[index].participants.toString(),
                        style: TextStyle(
                            fontSize: 14,
                            color: Theme.of(context).colorScheme.onTertiary,
                            fontWeight: FontWeight.bold),
                      ),
                      Text(
                        " " +
                            AppLocalization.of(context)!
                                .getTranslatedValues("playersLbl")!,
                        style: TextStyle(
                          fontSize: 14,
                          color: Theme.of(context)
                              .colorScheme
                              .onTertiary
                              .withOpacity(0.6),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Spacer(),
              Row(
                children: [
                  Column(
                    children: [
                      type == 1
                          ? GestureDetector(
                              onTap: () {
                                cateLength = false;
                                if (int.parse(context
                                        .read<UserDetailsCubit>()
                                        .getCoins()!) >=
                                    int.parse(
                                        data.contestDetails[index].entry!)) {
                                  context
                                      .read<UpdateScoreAndCoinsCubit>()
                                      .updateCoins(
                                        context
                                            .read<UserDetailsCubit>()
                                            .getUserId(),
                                        int.parse(
                                            data.contestDetails[index].entry!),
                                        false,
                                        AppLocalization.of(context)!
                                                .getTranslatedValues(
                                                    playedContestKey) ??
                                            "-",
                                      );

                                  context.read<UserDetailsCubit>().updateCoins(
                                      addCoin: false,
                                      coins: int.parse(
                                          data.contestDetails[index].entry!));
                                  Navigator.of(context)
                                      .pushNamed(Routes.quiz, arguments: {
                                    "numberOfPlayer": 1,
                                    "quizType": QuizTypes.contest,
                                    "contestId": data.contestDetails[index].id,
                                    "quizName": "Contest"
                                  });
                                } else {
                                  UiUtils.setSnackbar(
                                      AppLocalization.of(context)!
                                          .getTranslatedValues("noCoinsMsg")!,
                                      context,
                                      false);
                                }
                              },
                              child: Container(
                                padding: EdgeInsets.only(
                                    left: 10, right: 10, top: 10, bottom: 10),
                                decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(10),
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onTertiary
                                        .withOpacity(0.2)),
                                child: Text(
                                  AppLocalization.of(context)!
                                      .getTranslatedValues("playnowLbl")!,
                                  style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: Theme.of(context).primaryColor),
                                ),
                              ),
                            )
                          : Container()
                    ],
                  )
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHomeScreen(List<Widget> children) {
    return Stack(
      children: [
        ...children,
      ],
    );
  }

  Widget _buildHomeWithoutUser() {
    final statusBarPadding = MediaQuery.of(context).padding.top;
    return _buildHomeScreen([
      // _buildTopMenu(statusBarPadding),
      SingleChildScrollView(
        child: Column(
          children: [
            _buildProfileGuestContainer(statusBarPadding),
            _buildScoreGuestRank(statusBarPadding),
            //_smartExample(),
            _buildCategoryView(),
            _buildCategory(),
            _buildBattle(),
            _buildExamSelf(),
            _buildZones()
          ],
        ),
      ),

      showUpdateContainer ? UpdateAppContainer() : Container(),
    ]);
  }

  late bool cateLength = false;

  late AnimationController _controller;

  @override
  Widget build(BuildContext context) {
    final statusBarPadding = MediaQuery.of(context).padding.top;
    return Scaffold(
      body: widget.isGuest
          ? _buildHomeWithoutUser()
          : BlocConsumer<UserDetailsCubit, UserDetailsState>(
              listener: (context, state) {
                if (state is UserDetailsFetchSuccess) {
                  UiUtils.fetchBookmarkAndBadges(
                      context: context, userId: state.userProfile.userId!);
                  if (state.userProfile.name!.isEmpty) {
                    showUpdateNameBottomSheet();
                  } else if (state.userProfile.profileUrl!.isEmpty) {
                    Navigator.of(context)
                        .pushNamed(Routes.selectProfile, arguments: false);
                  }
                } else if (state is UserDetailsFetchFailure) {
                  if (state.errorMessage == unauthorizedAccessCode) {
                    UiUtils.showAlreadyLoggedInDialog(context: context);
                  }
                }
              },
              bloc: context.read<UserDetailsCubit>(),
              builder: (context, state) {
                if (state is UserDetailsFetchInProgress ||
                    state is UserDetailsInitial) {
                  return _buildHomeScreen([
                    Center(
                      child: CircularProgressContainer(
                        useWhiteLoader: false,
                      ),
                    )
                  ]);
                }
                if (state is UserDetailsFetchFailure) {
                  return _buildHomeScreen([
                    ErrorContainer(
                      showBackButton: true,
                      errorMessage: AppLocalization.of(context)!
                          .getTranslatedValues(convertErrorCodeToLanguageKey(
                              state.errorMessage))!,
                      onTapRetry: () {
                        context.read<UserDetailsCubit>().fetchUserDetails(
                            context.read<AuthCubit>().getUserFirebaseId());
                      },
                      showErrorImage: true,
                      errorMessageColor: Theme.of(context).primaryColor,
                    )
                  ]);
                }

                UserProfile userProfile =
                    (state as UserDetailsFetchSuccess).userProfile;
                if (userProfile.status == "0") {
                  return _buildHomeScreen([
                    ErrorContainer(
                      showBackButton: true,
                      errorMessage: AppLocalization.of(context)!
                          .getTranslatedValues(accountDeactivatedKey)!,
                      onTapRetry: () {
                        context.read<UserDetailsCubit>().fetchUserDetails(
                            context.read<AuthCubit>().getUserFirebaseId());
                      },
                      showErrorImage: true,
                      errorMessageColor: Theme.of(context).primaryColor,
                    )
                  ]);
                }
                return _buildHomeScreen([
                  // _buildTopMenu(statusBarPadding),
                  SingleChildScrollView(
                    child: Column(
                      children: [
                        _buildProfileContainer(statusBarPadding),
                        _buildScoreRank(statusBarPadding),

                        //_smartExample(),
                        _buildCategoryView(),

                        _buildCategory(),
                        !checkContest ? buildContestLive() : SizedBox(),
                        !checkContest ? _buildContest() : SizedBox(),
                        _buildBattle(),
                        _buildExamSelf(),
                        _buildZones()
                      ],
                    ),
                  ),

                  showUpdateContainer ? UpdateAppContainer() : Container(),
                ]);
              },
            ),
    );
  }
}
