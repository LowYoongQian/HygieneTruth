import 'package:flutter/material.dart';
import 'core/theme/app_theme.dart';
import 'core/routes/app_routes.dart';
import 'core/models/user_model.dart';
import 'core/widgets/role_dashboard_scaffold.dart';

// Authentication & Onboarding Module (auth)
import 'auth/screens/onboarding_screen.dart';
import 'auth/screens/splash_role_select_screen.dart';
import 'auth/screens/login_screen.dart';
import 'auth/screens/register_screen.dart';
import 'auth/screens/reset_password_screen.dart';
import 'auth/screens/profile_screen.dart';
import 'auth/screens/edit_profile_screen.dart';
import 'auth/screens/activity_history_screen.dart';
import 'auth/screens/manage_user_accounts_screen.dart';
import 'auth/screens/account_detail_screen.dart';

// GPS & Restaurant Info Module (gps)
import 'gps/screens/restaurant_search_screen.dart';
import 'gps/screens/restaurant_list_screen.dart';
import 'gps/screens/restaurant_detail_screen.dart';
import 'gps/screens/restaurant_map_screen.dart';
import 'gps/screens/add_restaurant_screen.dart';
import 'gps/screens/restaurant_verification_queue_screen.dart';
import 'gps/screens/restaurant_verification_detail_screen.dart';

// Hygiene Complaint Reporting Module (report)
import 'report/screens/submit_complaint_screen.dart';
import 'report/screens/complaint_history_screen.dart';
import 'report/screens/complaint_status_detail_screen.dart';

// Complaint Verification & Administration Module (complaint)
import 'complaint/screens/all_complaints_screen.dart';
import 'complaint/screens/complaint_review_detail_screen.dart';
import 'complaint/screens/verify_evidence_screen.dart';
import 'complaint/screens/duplicate_fake_review_screen.dart';
import 'complaint/screens/restaurant_validation_queue_screen.dart';
import 'complaint/screens/inspection_report_review_screen.dart';
import 'complaint/screens/admin_action_log_screen.dart';

// Inspection & Enforcement Module (inspect)
import 'inspect/screens/verified_complaints_list_screen.dart';
import 'inspect/screens/complaint_full_detail_screen.dart';
import 'inspect/screens/schedule_inspection_screen.dart';
import 'inspect/screens/conduct_inspection_screen.dart';
import 'inspect/screens/issue_enforcement_screen.dart';
import 'inspect/screens/enforcement_history_screen.dart';
import 'inspect/screens/close_case_screen.dart';

// Risk Score Analysis & Smart Recommendation Module (risk)
import 'risk/screens/recommendation_home_screen.dart';
import 'risk/screens/hygiene_heatmap_screen.dart';
import 'risk/screens/restaurant_risk_detail_screen.dart';
import 'risk/screens/risk_ranking_list_screen.dart';

// Restaurant Owner Portal Module (owner)
import 'owner/screens/notice_detail_screen.dart';
import 'owner/screens/mark_issue_resolved_screen.dart';
import 'owner/screens/final_report_screen.dart';

void main() {
  runApp(const RestaurantHygieneApp());
}

class RestaurantHygieneApp extends StatelessWidget {
  const RestaurantHygieneApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ScaffoldMessenger(
      child: MaterialApp(
        title: 'Restaurant Hygiene Monitoring System',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        initialRoute: AppRoutes.onboarding,
        routes: {
          // Onboarding, Splash & Auth
          AppRoutes.onboarding: (context) => const OnboardingScreen(),
          AppRoutes.splashRoleSelect: (context) => const SplashRoleSelectScreen(),
          AppRoutes.login: (context) => const LoginScreen(),
          AppRoutes.register: (context) => const RegisterScreen(),
          AppRoutes.resetPassword: (context) => const ResetPasswordScreen(),
          AppRoutes.profile: (context) => const ProfileScreen(),
          AppRoutes.editProfile: (context) => const EditProfileScreen(),
          AppRoutes.activityHistory: (context) => const ActivityHistoryScreen(),
          AppRoutes.manageUserAccounts: (context) => const ManageUserAccountsScreen(),
          AppRoutes.accountDetail: (context) => const AccountDetailScreen(),

          // Role Dashboards
          AppRoutes.userDashboard: (context) => const RoleDashboardScaffold(initialRole: UserRole.user),
          AppRoutes.adminDashboard: (context) => const RoleDashboardScaffold(initialRole: UserRole.admin),
          AppRoutes.governmentDashboard: (context) => const RoleDashboardScaffold(initialRole: UserRole.government),
          AppRoutes.ownerDashboard: (context) => const RoleDashboardScaffold(initialRole: UserRole.owner),

          // GPS & Restaurant Info
          AppRoutes.restaurantSearch: (context) => const RestaurantSearchScreen(),
          AppRoutes.restaurantList: (context) => const RestaurantListScreen(),
          AppRoutes.restaurantDetail: (context) => const RestaurantDetailScreen(),
          AppRoutes.restaurantMap: (context) => const RestaurantMapScreen(),
          AppRoutes.addRestaurant: (context) => const AddRestaurantScreen(),
          AppRoutes.restaurantVerificationQueue: (context) => const RestaurantVerificationQueueScreen(),
          AppRoutes.restaurantVerificationDetail: (context) => const RestaurantVerificationDetailScreen(),

          // Hygiene Complaint Reporting
          AppRoutes.submitComplaint: (context) => const SubmitComplaintScreen(),
          AppRoutes.complaintHistory: (context) => const ComplaintHistoryScreen(),
          AppRoutes.complaintStatusDetail: (context) => const ComplaintStatusDetailScreen(),

          // Complaint Verification & Administration
          AppRoutes.allComplaints: (context) => const AllComplaintsScreen(),
          AppRoutes.complaintReviewDetail: (context) => const ComplaintReviewDetailScreen(),
          AppRoutes.verifyEvidence: (context) => const VerifyEvidenceScreen(),
          AppRoutes.duplicateFakeReview: (context) => const DuplicateFakeReviewScreen(),
          AppRoutes.restaurantValidationQueue: (context) => const RestaurantValidationQueueScreen(),
          AppRoutes.inspectionReportReview: (context) => const InspectionReportReviewScreen(),
          AppRoutes.adminActionLog: (context) => const AdminActionLogScreen(),

          // Inspection & Enforcement
          AppRoutes.verifiedComplaintsList: (context) => const VerifiedComplaintsListScreen(),
          AppRoutes.complaintFullDetail: (context) => const ComplaintFullDetailScreen(),
          AppRoutes.scheduleInspection: (context) => const ScheduleInspectionScreen(),
          AppRoutes.conductInspection: (context) => const ConductInspectionScreen(),
          AppRoutes.issueEnforcement: (context) => const IssueEnforcementScreen(),
          AppRoutes.enforcementHistory: (context) => const EnforcementHistoryScreen(),
          AppRoutes.closeCase: (context) => const CloseCaseScreen(),

          // Risk Score Analysis & Smart Recommendation
          AppRoutes.recommendationHome: (context) => const RecommendationHomeScreen(),
          AppRoutes.hygieneHeatmap: (context) => const HygieneHeatmapScreen(),
          AppRoutes.restaurantRiskDetail: (context) => const RestaurantRiskDetailScreen(),
          AppRoutes.riskRankingList: (context) => const RiskRankingListScreen(),

          // Restaurant Owner Portal
          AppRoutes.noticeDetail: (context) => const NoticeDetailScreen(),
          AppRoutes.markIssueResolved: (context) => const MarkIssueResolvedScreen(),
          AppRoutes.finalReport: (context) => const FinalReportScreen(),
        },
      ),
    );
  }
}
