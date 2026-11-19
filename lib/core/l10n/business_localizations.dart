import 'package:material_ui/material_ui.dart';

import '../storage/app_preferences.dart';

/// Supported interface locales matching uCraft Design System 1.0 (`ru`, `tg`, `en`).
enum AppLocale {
  ru('ru', 'RU'),
  tg('tg', 'TG'),
  en('en', 'EN');

  const AppLocale(this.code, this.shortLabel);

  final String code;
  final String shortLabel;

  static AppLocale fromCode(String? code) {
    return switch (code) {
      'tg' => AppLocale.tg,
      'en' => AppLocale.en,
      _ => AppLocale.ru,
    };
  }
}

/// Strongly-typed UI strings synchronized with `lib/l10n/app_*.arb`.
@immutable
final class BusinessStrings {
  const BusinessStrings._({
    required this.appTitle,
    required this.navOverview,
    required this.navMembers,
    required this.navOperations,
    required this.navAnalytics,
    required this.navMore,
    required this.readOnlyBanner,
    required this.healthOk,
    required this.healthError,
    required this.checkHealth,
    required this.switchTheme,
    required this.selectBranch,
    required this.themeLightLabel,
    required this.themeDarkLabel,
    required this.signOutLabel,
    required this.detailsLabel,
    required this.retryLabel,
    required this.refreshLabel,
    required this.branchNotSelected,
    required this.noCompanyTitle,
    required this.noCompanyDescription,
    required this.createCompanyCta,
    required this.openClientAppCta,
    required this.permissionDeniedTitle,
    required this.permissionDeniedDescription,
    required this.subTabClients,
    required this.subTabExpiring,
    required this.subTabTypes,
    required this.subTabVisits,
    required this.subTabRequests,
    required this.subTabSales,
    required this.subTabProducts,
    required this.subTabSchedule,
    required this.subTabTrainers,
    required this.subTabSettings,
    required this.subTabStorefront,
    required this.subTabStaff,
    required this.subTabAnnouncements,
    required this.subTabBilling,
    required this.receptionAndPosTitle,
    required this.scanClientQrButton,
    required this.kioskQrButton,
    required this.openPosButton,
    required this.quickActionsTitle,
    required this.roleLabel,
    required this.roleUnset,
    required this.branchLabel,
    required this.revenueTodayTitle,
    required this.visitsTodayTitle,
    required this.pendingRequestsTitle,
    required this.pendingRequestsEmpty,
    required this.pendingRequestsHint,
    required this.goToRequestsButton,
    required this.expiringSoonTitle,
    required this.expiringSoonEmpty,
    required this.expiringSoonHint,
    required this.goToExpiringButton,
    required this.openAnalyticsButton,
    required this.overviewErrorTitle,
    required this.receiptsCountLabel,
    required this.membershipsLabel,
    required this.manualVisitsLabel,
    required this.newClientsLabel,
    required this.cancelLabel,
    required this.authEmailOrPhoneLabel,
    required this.authPasswordLabel,
    required this.authSignInButton,
    required this.authCreateAccountButton,
    required this.authResetPasswordButton,
    required this.authPhoneOptionalLabel,
    required this.authPasswordMinLabel,
    required this.authRegisterButton,
    required this.authBackToLoginButton,
    required this.authOtpCodeLabel,
    required this.authVerifyEmailButton,
    required this.authResendOtpButton,
    required this.authSendCodeButton,
    required this.authNewPasswordLabel,
    required this.authSaveNewPasswordButton,
    required this.authSubtitleLogin,
    required this.authSubtitleRegister,
    required this.authSubtitleOtp,
    required this.authSubtitleReset,
    required this.scannerCheckingMembership,
    required this.scannerCameraHint,
    required this.scannerVisitRecorded,
    required this.scannerMembershipPrefix,
    required this.scannerRemainingVisitsPrefix,
    required this.scannerScanNextButton,
    required this.scannerAcceptPaymentButton,
    required this.scannerOpenClientsButton,
    required this.scannerNetworkErrorTitle,
    required this.scannerNetworkRetryHint,
    required this.scannerRefusalNoActive,
    required this.scannerRefusalFrozen,
    required this.scannerRefusalDailyLimit,
    required this.scannerRefusalOutsideTime,
    required this.scannerRefusalInvalidQr,
    required this.scannerRefusalGeneric,
    required this.kioskLockedBadge,
    required this.kioskModeBadge,
    required this.kioskLoadingQr,
    required this.kioskScanPrompt,
    required this.kioskRefreshPrefix,
    required this.kioskSecondsSuffix,
    required this.kioskSlotPrefix,
    required this.kioskSetPinLabel,
    required this.kioskEnableLockButton,
    required this.kioskLockWithPinButton,
    required this.kioskExitButton,
    required this.kioskUnlockPinLabel,
    required this.kioskConfirmPinButton,
    required this.kioskUnlockAndExitButton,
    required this.kioskPinFormatError,
    required this.kioskWrongPinError,
    required this.paymentCashLabel,
    required this.paymentTerminalLabel,
    required this.paymentTransferLabel,
    required this.posTitle,
    required this.posLoadingCatalog,
    required this.posLoadErrorTitle,
    required this.posClientIdLabel,
    required this.posNoActivePlans,
    required this.posNoActiveProducts,
    required this.posPaymentMethodLabel,
    required this.posTotalPrefix,
    required this.posSubmitSaleButton,
    required this.posDecreaseQtyTooltip,
    required this.posIncreaseQtyTooltip,
    required this.analyticsNoAccessTitle,
    required this.analyticsOwnerOnlyDesc,
    required this.analyticsPeriodFilterTitle,
    required this.analyticsTodayLabel,
    required this.analyticsWeekLabel,
    required this.analyticsMonthLabel,
    required this.analyticsFromDateLabel,
    required this.analyticsToDateLabel,
    required this.analyticsInactiveDaysLabel,
    required this.analyticsApplyButton,
    required this.analyticsLoading,
    required this.analyticsErrorTitle,
    required this.analyticsEmptyTitle,
    required this.analyticsEmptyDesc,
    required this.analyticsRevenuePrefix,
    required this.analyticsClientsAndVisitsTitle,
    required this.analyticsTopPlansTitle,
    required this.analyticsTopProductsTitle,
    required this.analyticsNoSalesInPeriod,
    required this.chartVisitsByDayLabel,
    required this.chartPeakDayPrefix,
    required this.chartVisitsEmpty,
    required this.chartPaymentsEmpty,
    required this.announcementsTitle,
    required this.announcementsNoAccessDesc,
    required this.announcementsTitleField,
    required this.announcementsBodyField,
    required this.announcementsSendButton,
    required this.billingNoAccessDesc,
    required this.billingLoading,
    required this.billingStatusPrefix,
    required this.billingValidUntilPrefix,
    required this.billingReadOnlyHint,
    required this.billingPlansTitle,
    required this.billingPlansEmpty,
    required this.billingStatusTrial,
    required this.billingStatusActive,
    required this.billingStatusExpired,
    required this.onboardingTitle,
    required this.onboardingSubtitle,
    required this.onboardingCompanyNameLabel,
    required this.onboardingGymNameLabel,
    required this.onboardingGymAddressLabel,
    required this.branchesAddTitle,
    required this.branchesEditTitle,
    required this.branchesNameLabel,
    required this.branchesAddressLabel,
    required this.branchesGeoCheckSwitch,
    required this.branchesGeoRadiusLabel,
    required this.branchesNoGeofence,
    required this.branchesSaveChangesButton,
    required this.companyCurrencyTitle,
    required this.visitsLogTitle,
    required this.visitsManualButton,
    required this.visitsSelectBranchHint,
    required this.visitsLoading,
    required this.visitsEmptyTitle,
    required this.visitsEmptyDesc,
    required this.visitStatusCancelled,
    required this.visitStatusCompleted,
    required this.visitCancelButton,
    required this.visitMethodGymQr,
    required this.visitMethodClientQr,
    required this.visitManualSheetTitle,
    required this.visitClientIdLabel,
    required this.visitBackdatedCheckbox,
    required this.visitDateTimeLabel,
    required this.visitSubmitButton,
    required this.visitCancelReasonLabel,
    required this.visitConfirmCancelButton,
    required this.backLabel,
    required this.clientsMergeDuplicatesButton,
    required this.clientsAddButton,
    required this.clientsSearchLabel,
    required this.clientsSearchHint,
    required this.clientsFindButton,
    required this.clientsLoading,
    required this.clientsEmptyTitle,
    required this.clientsEmptyDesc,
    required this.clientsShowMoreButton,
    required this.clientLinkedBadge,
    required this.clientOfflineBadge,
    required this.clientNewSheetTitle,
    required this.clientNameLabel,
    required this.clientPhoneLabel,
    required this.clientEmailOptionalLabel,
    required this.clientAutoLinkHint,
    required this.clientOpenExistingButton,
    required this.clientCreateButton,
    required this.clientMergeDesc,
    required this.clientMergeConfirmButton,
    required this.clientSellCta,
    required this.clientTabVisits,
    required this.clientTabSales,
    required this.clientDetailLoading,
    required this.clientNoMembershipsTitle,
    required this.clientNoMembershipsDesc,
    required this.clientFreezeButton,
    required this.clientUnfreezeButton,
    required this.clientManualCheckInButton,
    required this.clientNoVisitsTitle,
    required this.clientNoVisitsDesc,
    required this.clientNoSalesTitle,
    required this.clientNoSalesDesc,
    required this.plansTitle,
    required this.plansShowAllButton,
    required this.plansOnlyActiveButton,
    required this.plansCreateButton,
    required this.plansLoading,
    required this.plansEmptyTitle,
    required this.plansEmptyDesc,
    required this.planStatusActive,
    required this.planStatusArchived,
    required this.planArchiveButton,
    required this.planActivateButton,
    required this.planKindUnlimited,
    required this.planKindVisitsPack,
    required this.planKindMixed,
    required this.planNewTitle,
    required this.planNameLabel,
    required this.planPriceInCurrencyLabel,
    required this.planKindSectionLabel,
    required this.planStartModeSectionLabel,
    required this.planStartOnPurchase,
    required this.planStartOnFirstVisit,
    required this.planDurationDaysLabel,
    required this.planVisitsCountLabel,
    required this.planValidityDaysLabel,
    required this.planDailyLimitLabel,
    required this.planTimeFromLabel,
    required this.planTimeToLabel,
    required this.planFreezeDaysLabel,
    required this.planFreezeTimesLabel,
    required this.planSaveButton,
    required this.expiringLoading,
    required this.expiringEmptyTitle,
    required this.expiringEmptyDesc,
    required this.membershipCancelButton,
    required this.membershipCancelDialogTitle,
    required this.requestsTitle,
    required this.requestStatusPending,
    required this.requestStatusPaid,
    required this.requestStatusCancelled,
    required this.requestStatusExpired,
    required this.requestsLoading,
    required this.requestsEmptyTitle,
    required this.requestsEmptyDesc,
    required this.requestCancelButton,
    required this.requestConfirmPaymentButton,
    required this.reasonOptionalLabel,
    required this.confirmLabel,
    required this.salesHistoryTitle,
    required this.salesLoading,
    required this.salesEmptyTitle,
    required this.salesEmptyDesc,
    required this.saleStatusPaid,
    required this.saleRefundButton,
    required this.saleRefundReasonLabel,
    required this.saleConfirmRefundButton,
    required this.productsTitle,
    required this.productsAddButton,
    required this.productsLoading,
    required this.productsEmptyTitle,
    required this.productsEmptyDesc,
    required this.productEditButton,
    required this.productNewTitle,
    required this.productPriceLabel,
    required this.productStockLabel,
    required this.productCreateButton,
    required this.productActiveAtPosCheckbox,
    required this.saveLabel,
    required this.trainersSelectBranchDesc,
    required this.trainersTitle,
    required this.trainersAddButton,
    required this.trainersLoading,
    required this.trainersEmptyTitle,
    required this.trainersEmptyDesc,
    required this.trainerStatusInactive,
    required this.trainerEditDialogTitle,
    required this.trainerNewDialogTitle,
    required this.trainerBioOptionalLabel,
    required this.scheduleSelectBranchDesc,
    required this.scheduleGenerateButton,
    required this.scheduleNewTemplateButton,
    required this.scheduleSessionsTab,
    required this.scheduleTemplatesTab,
    required this.scheduleLoading,
    required this.scheduleNoSessionsTitle,
    required this.scheduleNoSessionsDesc,
    required this.scheduleSessionCancelled,
    required this.scheduleBookingsButton,
    required this.scheduleCancelSessionTitle,
    required this.scheduleCancelSessionDesc,
    required this.scheduleNoTemplatesTitle,
    required this.scheduleNoTemplatesDesc,
    required this.scheduleTrainerLookupTitle,
    required this.scheduleTrainerLookupDesc,
    required this.scheduleSessionIdLabel,
    required this.scheduleOpenRosterButton,
    required this.bookingsLoading,
    required this.bookingsEmptyTitle,
    required this.bookingsEmptyDesc,
    required this.bookingStatusBooked,
    required this.bookingStatusCancelled,
    required this.scheduleGenerateDialogTitle,
    required this.scheduleStartDateLabel,
    required this.scheduleEndDateLabel,
    required this.scheduleNewTemplateDialogTitle,
    required this.scheduleWeekdayLabel,
    required this.scheduleStartTimeLabel,
    required this.scheduleDurationMinLabel,
    required this.scheduleCapacityLabel,
    required this.storefrontOwnerOnlyDesc,
    required this.storefrontTitlePrefix,
    required this.storefrontSelectBranchDesc,
    required this.storefrontApprovedWarning,
    required this.storefrontPendingHint,
    required this.storefrontDescriptionLabel,
    required this.storefrontAddressLabel,
    required this.storefrontDistrictLabel,
    required this.storefrontLatitudeLabel,
    required this.storefrontLongitudeLabel,
    required this.storefrontPhoneLabel,
    required this.storefrontHoursLabel,
    required this.storefrontAmenitiesLabel,
    required this.storefrontSaveButton,
    required this.storefrontSubmitModerationButton,
    required this.storefrontUnpublishButton,
    required this.storefrontPublishButton,
    required this.storefrontModerationDraft,
    required this.storefrontModerationPending,
    required this.storefrontModerationApproved,
    required this.storefrontModerationRejected,
    required this.galleryTitlePrefix,
    required this.galleryUploadButton,
    required this.galleryEmptyHint,
    required this.deleteLabel,
    required this.staffOwnerOnlyDesc,
    required this.staffAddTitle,
    required this.staffEmailLabel,
    required this.staffRoleOwner,
    required this.staffRoleAdmin,
    required this.staffRoleTrainer,
    required this.staffOtpOnboardingHint,
    required this.staffAddButton,
    required this.staffListTitle,
    required this.staffLoading,
    required this.staffEmptyTitle,
    required this.staffEmptyDesc,
    required this.staffMakeTrainerButton,
    required this.staffMakeAdminButton,
  });

  final String appTitle;
  final String navOverview;
  final String navMembers;
  final String navOperations;
  final String navAnalytics;
  final String navMore;
  final String readOnlyBanner;
  final String healthOk;
  final String healthError;
  final String checkHealth;
  final String switchTheme;
  final String selectBranch;
  final String themeLightLabel;
  final String themeDarkLabel;
  final String signOutLabel;
  final String detailsLabel;
  final String retryLabel;
  final String refreshLabel;
  final String branchNotSelected;
  final String noCompanyTitle;
  final String noCompanyDescription;
  final String createCompanyCta;
  final String openClientAppCta;
  final String permissionDeniedTitle;
  final String permissionDeniedDescription;
  final String subTabClients;
  final String subTabExpiring;
  final String subTabTypes;
  final String subTabVisits;
  final String subTabRequests;
  final String subTabSales;
  final String subTabProducts;
  final String subTabSchedule;
  final String subTabTrainers;
  final String subTabSettings;
  final String subTabStorefront;
  final String subTabStaff;
  final String subTabAnnouncements;
  final String subTabBilling;
  final String receptionAndPosTitle;
  final String scanClientQrButton;
  final String kioskQrButton;
  final String openPosButton;
  final String quickActionsTitle;
  final String roleLabel;
  final String roleUnset;
  final String branchLabel;
  final String revenueTodayTitle;
  final String visitsTodayTitle;
  final String pendingRequestsTitle;
  final String pendingRequestsEmpty;
  final String pendingRequestsHint;
  final String goToRequestsButton;
  final String expiringSoonTitle;
  final String expiringSoonEmpty;
  final String expiringSoonHint;
  final String goToExpiringButton;
  final String openAnalyticsButton;
  final String overviewErrorTitle;
  final String receiptsCountLabel;
  final String membershipsLabel;
  final String manualVisitsLabel;
  final String newClientsLabel;
  final String cancelLabel;
  final String authEmailOrPhoneLabel;
  final String authPasswordLabel;
  final String authSignInButton;
  final String authCreateAccountButton;
  final String authResetPasswordButton;
  final String authPhoneOptionalLabel;
  final String authPasswordMinLabel;
  final String authRegisterButton;
  final String authBackToLoginButton;
  final String authOtpCodeLabel;
  final String authVerifyEmailButton;
  final String authResendOtpButton;
  final String authSendCodeButton;
  final String authNewPasswordLabel;
  final String authSaveNewPasswordButton;
  final String authSubtitleLogin;
  final String authSubtitleRegister;
  final String authSubtitleOtp;
  final String authSubtitleReset;
  final String scannerCheckingMembership;
  final String scannerCameraHint;
  final String scannerVisitRecorded;
  final String scannerMembershipPrefix;
  final String scannerRemainingVisitsPrefix;
  final String scannerScanNextButton;
  final String scannerAcceptPaymentButton;
  final String scannerOpenClientsButton;
  final String scannerNetworkErrorTitle;
  final String scannerNetworkRetryHint;
  final String scannerRefusalNoActive;
  final String scannerRefusalFrozen;
  final String scannerRefusalDailyLimit;
  final String scannerRefusalOutsideTime;
  final String scannerRefusalInvalidQr;
  final String scannerRefusalGeneric;
  final String kioskLockedBadge;
  final String kioskModeBadge;
  final String kioskLoadingQr;
  final String kioskScanPrompt;
  final String kioskRefreshPrefix;
  final String kioskSecondsSuffix;
  final String kioskSlotPrefix;
  final String kioskSetPinLabel;
  final String kioskEnableLockButton;
  final String kioskLockWithPinButton;
  final String kioskExitButton;
  final String kioskUnlockPinLabel;
  final String kioskConfirmPinButton;
  final String kioskUnlockAndExitButton;
  final String kioskPinFormatError;
  final String kioskWrongPinError;
  final String paymentCashLabel;
  final String paymentTerminalLabel;
  final String paymentTransferLabel;
  final String posTitle;
  final String posLoadingCatalog;
  final String posLoadErrorTitle;
  final String posClientIdLabel;
  final String posNoActivePlans;
  final String posNoActiveProducts;
  final String posPaymentMethodLabel;
  final String posTotalPrefix;
  final String posSubmitSaleButton;
  final String posDecreaseQtyTooltip;
  final String posIncreaseQtyTooltip;
  final String analyticsNoAccessTitle;
  final String analyticsOwnerOnlyDesc;
  final String analyticsPeriodFilterTitle;
  final String analyticsTodayLabel;
  final String analyticsWeekLabel;
  final String analyticsMonthLabel;
  final String analyticsFromDateLabel;
  final String analyticsToDateLabel;
  final String analyticsInactiveDaysLabel;
  final String analyticsApplyButton;
  final String analyticsLoading;
  final String analyticsErrorTitle;
  final String analyticsEmptyTitle;
  final String analyticsEmptyDesc;
  final String analyticsRevenuePrefix;
  final String analyticsClientsAndVisitsTitle;
  final String analyticsTopPlansTitle;
  final String analyticsTopProductsTitle;
  final String analyticsNoSalesInPeriod;
  final String chartVisitsByDayLabel;
  final String chartPeakDayPrefix;
  final String chartVisitsEmpty;
  final String chartPaymentsEmpty;
  final String announcementsTitle;
  final String announcementsNoAccessDesc;
  final String announcementsTitleField;
  final String announcementsBodyField;
  final String announcementsSendButton;
  final String billingNoAccessDesc;
  final String billingLoading;
  final String billingStatusPrefix;
  final String billingValidUntilPrefix;
  final String billingReadOnlyHint;
  final String billingPlansTitle;
  final String billingPlansEmpty;
  final String billingStatusTrial;
  final String billingStatusActive;
  final String billingStatusExpired;
  final String onboardingTitle;
  final String onboardingSubtitle;
  final String onboardingCompanyNameLabel;
  final String onboardingGymNameLabel;
  final String onboardingGymAddressLabel;
  final String branchesAddTitle;
  final String branchesEditTitle;
  final String branchesNameLabel;
  final String branchesAddressLabel;
  final String branchesGeoCheckSwitch;
  final String branchesGeoRadiusLabel;
  final String branchesNoGeofence;
  final String branchesSaveChangesButton;
  final String companyCurrencyTitle;
  final String visitsLogTitle;
  final String visitsManualButton;
  final String visitsSelectBranchHint;
  final String visitsLoading;
  final String visitsEmptyTitle;
  final String visitsEmptyDesc;
  final String visitStatusCancelled;
  final String visitStatusCompleted;
  final String visitCancelButton;
  final String visitMethodGymQr;
  final String visitMethodClientQr;
  final String visitManualSheetTitle;
  final String visitClientIdLabel;
  final String visitBackdatedCheckbox;
  final String visitDateTimeLabel;
  final String visitSubmitButton;
  final String visitCancelReasonLabel;
  final String visitConfirmCancelButton;
  final String backLabel;
  final String clientsMergeDuplicatesButton;
  final String clientsAddButton;
  final String clientsSearchLabel;
  final String clientsSearchHint;
  final String clientsFindButton;
  final String clientsLoading;
  final String clientsEmptyTitle;
  final String clientsEmptyDesc;
  final String clientsShowMoreButton;
  final String clientLinkedBadge;
  final String clientOfflineBadge;
  final String clientNewSheetTitle;
  final String clientNameLabel;
  final String clientPhoneLabel;
  final String clientEmailOptionalLabel;
  final String clientAutoLinkHint;
  final String clientOpenExistingButton;
  final String clientCreateButton;
  final String clientMergeDesc;
  final String clientMergeConfirmButton;
  final String clientSellCta;
  final String clientTabVisits;
  final String clientTabSales;
  final String clientDetailLoading;
  final String clientNoMembershipsTitle;
  final String clientNoMembershipsDesc;
  final String clientFreezeButton;
  final String clientUnfreezeButton;
  final String clientManualCheckInButton;
  final String clientNoVisitsTitle;
  final String clientNoVisitsDesc;
  final String clientNoSalesTitle;
  final String clientNoSalesDesc;
  final String plansTitle;
  final String plansShowAllButton;
  final String plansOnlyActiveButton;
  final String plansCreateButton;
  final String plansLoading;
  final String plansEmptyTitle;
  final String plansEmptyDesc;
  final String planStatusActive;
  final String planStatusArchived;
  final String planArchiveButton;
  final String planActivateButton;
  final String planKindUnlimited;
  final String planKindVisitsPack;
  final String planKindMixed;
  final String planNewTitle;
  final String planNameLabel;
  final String planPriceInCurrencyLabel;
  final String planKindSectionLabel;
  final String planStartModeSectionLabel;
  final String planStartOnPurchase;
  final String planStartOnFirstVisit;
  final String planDurationDaysLabel;
  final String planVisitsCountLabel;
  final String planValidityDaysLabel;
  final String planDailyLimitLabel;
  final String planTimeFromLabel;
  final String planTimeToLabel;
  final String planFreezeDaysLabel;
  final String planFreezeTimesLabel;
  final String planSaveButton;
  final String expiringLoading;
  final String expiringEmptyTitle;
  final String expiringEmptyDesc;
  final String membershipCancelButton;
  final String membershipCancelDialogTitle;
  final String requestsTitle;
  final String requestStatusPending;
  final String requestStatusPaid;
  final String requestStatusCancelled;
  final String requestStatusExpired;
  final String requestsLoading;
  final String requestsEmptyTitle;
  final String requestsEmptyDesc;
  final String requestCancelButton;
  final String requestConfirmPaymentButton;
  final String reasonOptionalLabel;
  final String confirmLabel;
  final String salesHistoryTitle;
  final String salesLoading;
  final String salesEmptyTitle;
  final String salesEmptyDesc;
  final String saleStatusPaid;
  final String saleRefundButton;
  final String saleRefundReasonLabel;
  final String saleConfirmRefundButton;
  final String productsTitle;
  final String productsAddButton;
  final String productsLoading;
  final String productsEmptyTitle;
  final String productsEmptyDesc;
  final String productEditButton;
  final String productNewTitle;
  final String productPriceLabel;
  final String productStockLabel;
  final String productCreateButton;
  final String productActiveAtPosCheckbox;
  final String saveLabel;
  final String trainersSelectBranchDesc;
  final String trainersTitle;
  final String trainersAddButton;
  final String trainersLoading;
  final String trainersEmptyTitle;
  final String trainersEmptyDesc;
  final String trainerStatusInactive;
  final String trainerEditDialogTitle;
  final String trainerNewDialogTitle;
  final String trainerBioOptionalLabel;
  final String scheduleSelectBranchDesc;
  final String scheduleGenerateButton;
  final String scheduleNewTemplateButton;
  final String scheduleSessionsTab;
  final String scheduleTemplatesTab;
  final String scheduleLoading;
  final String scheduleNoSessionsTitle;
  final String scheduleNoSessionsDesc;
  final String scheduleSessionCancelled;
  final String scheduleBookingsButton;
  final String scheduleCancelSessionTitle;
  final String scheduleCancelSessionDesc;
  final String scheduleNoTemplatesTitle;
  final String scheduleNoTemplatesDesc;
  final String scheduleTrainerLookupTitle;
  final String scheduleTrainerLookupDesc;
  final String scheduleSessionIdLabel;
  final String scheduleOpenRosterButton;
  final String bookingsLoading;
  final String bookingsEmptyTitle;
  final String bookingsEmptyDesc;
  final String bookingStatusBooked;
  final String bookingStatusCancelled;
  final String scheduleGenerateDialogTitle;
  final String scheduleStartDateLabel;
  final String scheduleEndDateLabel;
  final String scheduleNewTemplateDialogTitle;
  final String scheduleWeekdayLabel;
  final String scheduleStartTimeLabel;
  final String scheduleDurationMinLabel;
  final String scheduleCapacityLabel;
  final String storefrontOwnerOnlyDesc;
  final String storefrontTitlePrefix;
  final String storefrontSelectBranchDesc;
  final String storefrontApprovedWarning;
  final String storefrontPendingHint;
  final String storefrontDescriptionLabel;
  final String storefrontAddressLabel;
  final String storefrontDistrictLabel;
  final String storefrontLatitudeLabel;
  final String storefrontLongitudeLabel;
  final String storefrontPhoneLabel;
  final String storefrontHoursLabel;
  final String storefrontAmenitiesLabel;
  final String storefrontSaveButton;
  final String storefrontSubmitModerationButton;
  final String storefrontUnpublishButton;
  final String storefrontPublishButton;
  final String storefrontModerationDraft;
  final String storefrontModerationPending;
  final String storefrontModerationApproved;
  final String storefrontModerationRejected;
  final String galleryTitlePrefix;
  final String galleryUploadButton;
  final String galleryEmptyHint;
  final String deleteLabel;
  final String staffOwnerOnlyDesc;
  final String staffAddTitle;
  final String staffEmailLabel;
  final String staffRoleOwner;
  final String staffRoleAdmin;
  final String staffRoleTrainer;
  final String staffOtpOnboardingHint;
  final String staffAddButton;
  final String staffListTitle;
  final String staffLoading;
  final String staffEmptyTitle;
  final String staffEmptyDesc;
  final String staffMakeTrainerButton;
  final String staffMakeAdminButton;

  static const BusinessStrings ru = BusinessStrings._(
    appTitle: 'uGym Business',
    navOverview: 'Обзор',
    navMembers: 'Клиенты',
    navOperations: 'Операции',
    navAnalytics: 'Аналитика',
    navMore: 'Ещё',
    readOnlyBanner: 'Подписка истекла — доступен только просмотр',
    healthOk: 'Сервер и базы доступны',
    healthError: 'Сервер недоступен',
    checkHealth: 'Проверить связь',
    switchTheme: 'Сменить тему',
    selectBranch: 'Выбор филиала',
    themeLightLabel: 'Светлая тема',
    themeDarkLabel: 'Тёмная тема',
    signOutLabel: 'Выйти',
    detailsLabel: 'Подробнее',
    retryLabel: 'Повторить',
    refreshLabel: 'Обновить',
    branchNotSelected: 'Филиал не выбран',
    noCompanyTitle: 'Вы не являетесь сотрудником зала',
    noCompanyDescription:
        'Создайте свою компанию или откройте клиентское приложение uGym.',
    createCompanyCta: 'Создать компанию (14 дней бесплатно)',
    openClientAppCta: 'Перейти в клиентское приложение uGym',
    permissionDeniedTitle: 'Недостаточно прав для доступа к разделу',
    permissionDeniedDescription:
        'Доступ ограничен вашей текущей ролью в компании.',
    subTabClients: 'Клиенты',
    subTabExpiring: 'Истекающие',
    subTabTypes: 'Тарифы',
    subTabVisits: 'Визиты',
    subTabRequests: 'Заявки',
    subTabSales: 'Продажи',
    subTabProducts: 'Товары',
    subTabSchedule: 'Расписание',
    subTabTrainers: 'Тренеры',
    subTabSettings: 'Настройки',
    subTabStorefront: 'Витрина',
    subTabStaff: 'Штат',
    subTabAnnouncements: 'Рассылки',
    subTabBilling: 'Подписка',
    receptionAndPosTitle: 'Ресепшен и касса',
    scanClientQrButton: 'Сканер QR клиента',
    kioskQrButton: 'Киоск QR зала',
    openPosButton: 'Открыть кассу',
    quickActionsTitle: 'Быстрые действия',
    roleLabel: 'Роль',
    roleUnset: 'не определена',
    branchLabel: 'Филиал',
    revenueTodayTitle: 'Выручка сегодня',
    visitsTodayTitle: 'Посещения сегодня',
    pendingRequestsTitle: 'Заявки в ожидании',
    pendingRequestsEmpty: 'Необработанных заявок из uGym нет',
    pendingRequestsHint: 'Ожидают подтверждения оплаты на кассе',
    goToRequestsButton: 'К заявкам',
    expiringSoonTitle: 'Истекают за 7 дней',
    expiringSoonEmpty: 'Истекающих абонементов нет',
    expiringSoonHint: 'Абонементы для напоминания о продлении',
    goToExpiringButton: 'К истекающим',
    openAnalyticsButton: 'Открыть аналитику',
    overviewErrorTitle: 'Ошибка загрузки сводки',
    receiptsCountLabel: 'Чеков',
    membershipsLabel: 'Абонементы',
    manualVisitsLabel: 'Ручные',
    newClientsLabel: 'Новых клиентов',
    cancelLabel: 'Отмена',
    authEmailOrPhoneLabel: 'Email или телефон',
    authPasswordLabel: 'Пароль',
    authSignInButton: 'Войти',
    authCreateAccountButton: 'Создать аккаунт',
    authResetPasswordButton: 'Сбросить пароль',
    authPhoneOptionalLabel: 'Телефон (необязательно)',
    authPasswordMinLabel: 'Пароль (минимум 8 символов)',
    authRegisterButton: 'Зарегистрироваться',
    authBackToLoginButton: 'Назад ко входу',
    authOtpCodeLabel: '6-значный код из письма',
    authVerifyEmailButton: 'Подтвердить email',
    authResendOtpButton: 'Отправить код повторно',
    authSendCodeButton: 'Получить код на email',
    authNewPasswordLabel: 'Новый пароль',
    authSaveNewPasswordButton: 'Сохранить новый пароль',
    authSubtitleLogin: 'Вход для владельца, администратора и тренера',
    authSubtitleRegister: 'Регистрация аккаунта сотрудника или владельца',
    authSubtitleOtp: 'Подтверждение email по одноразовому коду',
    authSubtitleReset: 'Восстановление доступа по коду из письма',
    scannerCheckingMembership: 'Проверяем абонемент...',
    scannerCameraHint:
        'Наведите камеру на личный QR-код клиента из приложения uGym',
    scannerVisitRecorded: 'Посещение отмечено',
    scannerMembershipPrefix: 'Абонемент №',
    scannerRemainingVisitsPrefix: 'Осталось занятий: ',
    scannerScanNextButton: 'Сканировать следующего',
    scannerAcceptPaymentButton: 'Принять оплату',
    scannerOpenClientsButton: 'Открыть клиентов',
    scannerNetworkErrorTitle: 'Нет связи с сервером',
    scannerNetworkRetryHint:
        'Нажмите «Повторить» — дубль посещения не будет создан.',
    scannerRefusalNoActive: 'Нет активного абонемента',
    scannerRefusalFrozen: 'Абонемент заморожен',
    scannerRefusalDailyLimit: 'Лимит входов на сегодня исчерпан',
    scannerRefusalOutsideTime: 'Вне разрешённого времени абонемента',
    scannerRefusalInvalidQr: 'QR-код недействителен или устарел',
    scannerRefusalGeneric: 'Посещение не отмечено',
    kioskLockedBadge: 'Киоск заблокирован',
    kioskModeBadge: 'Режим стойки',
    kioskLoadingQr: 'Загрузка QR-кода зала...',
    kioskScanPrompt: 'Отсканируйте код в приложении uGym',
    kioskRefreshPrefix: 'Обновление через ',
    kioskSecondsSuffix: ' сек',
    kioskSlotPrefix: 'Слот #',
    kioskSetPinLabel: 'PIN-код из 4 цифр для выхода',
    kioskEnableLockButton: 'Включить блокировку киоска',
    kioskLockWithPinButton: 'Заблокировать киоск PIN-кодом',
    kioskExitButton: 'Выйти из режима киоска',
    kioskUnlockPinLabel: 'Введите 4-значный PIN сотрудника',
    kioskConfirmPinButton: 'Подтвердить PIN',
    kioskUnlockAndExitButton: 'Разблокировать и выйти',
    kioskPinFormatError: 'Введите 4 цифры PIN-кода',
    kioskWrongPinError: 'Неверный PIN-код',
    paymentCashLabel: 'Наличные',
    paymentTerminalLabel: 'Терминал',
    paymentTransferLabel: 'Перевод',
    posTitle: 'Касса',
    posLoadingCatalog: 'Загружаем товары и тарифы...',
    posLoadErrorTitle: 'Ошибка загрузки',
    posClientIdLabel: 'ID клиента (обязателен для абонемента)',
    posNoActivePlans: 'Нет активных тарифов.',
    posNoActiveProducts: 'Нет активных товаров.',
    posPaymentMethodLabel: 'Способ оплаты',
    posTotalPrefix: 'Итого: ',
    posSubmitSaleButton: 'Провести продажу',
    posDecreaseQtyTooltip: 'Уменьшить количество',
    posIncreaseQtyTooltip: 'Увеличить количество',
    analyticsNoAccessTitle: 'Недостаточно прав',
    analyticsOwnerOnlyDesc: 'Аналитика и выручка доступны только владельцу.',
    analyticsPeriodFilterTitle: 'Фильтр периода',
    analyticsTodayLabel: 'Сегодня',
    analyticsWeekLabel: 'Неделя',
    analyticsMonthLabel: 'Месяц',
    analyticsFromDateLabel: 'С (ГГГГ-ММ-ДД)',
    analyticsToDateLabel: 'По (ГГГГ-ММ-ДД)',
    analyticsInactiveDaysLabel: 'Неактивные (1–365 дн.)',
    analyticsApplyButton: 'Применить',
    analyticsLoading: 'Загружаем аналитику...',
    analyticsErrorTitle: 'Ошибка аналитики',
    analyticsEmptyTitle: 'Данных нет',
    analyticsEmptyDesc: 'Выберите период и обновите отчёт.',
    analyticsRevenuePrefix: 'Выручка: ',
    analyticsClientsAndVisitsTitle: 'Клиенты и посещаемость',
    analyticsTopPlansTitle: 'Топ тарифов',
    analyticsTopProductsTitle: 'Топ товаров',
    analyticsNoSalesInPeriod: 'За период продаж не было.',
    chartVisitsByDayLabel: 'Посещения по дням',
    chartPeakDayPrefix: 'Максимум за день',
    chartVisitsEmpty: 'Нет данных по посещениям за выбранный период.',
    chartPaymentsEmpty: 'Оплат за выбранный период нет.',
    announcementsTitle: 'Массовая рассылка',
    announcementsNoAccessDesc: 'Рассылки доступны владельцу и администратору.',
    announcementsTitleField: 'Заголовок (до 120)',
    announcementsBodyField: 'Текст сообщения (до 1000)',
    announcementsSendButton: 'Отправить рассылку',
    billingNoAccessDesc:
        'Подписка платформы доступна владельцу и администратору.',
    billingLoading: 'Загружаем подписку...',
    billingStatusPrefix: 'Подписка платформы: ',
    billingValidUntilPrefix: 'Действует до: ',
    billingReadOnlyHint: 'Режим только для чтения: для продления свяжитесь с поддержкой платформы.',
    billingPlansTitle: 'Тарифы платформы',
    billingPlansEmpty: 'Список тарифов пуст.',
    billingStatusTrial: 'Пробный период (trial)',
    billingStatusActive: 'Активна (active)',
    billingStatusExpired: 'Истекла (expired)',
    onboardingTitle: 'Создание компании (14 дней бесплатно)',
    onboardingSubtitle: 'Укажите название компании и первого филиала — пробный период активируется автоматически.',
    onboardingCompanyNameLabel: 'Название компании',
    onboardingGymNameLabel: 'Название первого зала',
    onboardingGymAddressLabel: 'Адрес зала (необязательно)',
    branchesAddTitle: 'Добавить филиал',
    branchesEditTitle: 'Редактировать зал',
    branchesNameLabel: 'Название филиала',
    branchesAddressLabel: 'Адрес филиала',
    branchesGeoCheckSwitch: 'Проверять геозону при чекине',
    branchesGeoRadiusLabel: 'Радиус геозоны (50–5000 м)',
    branchesNoGeofence: 'Без геозоны',
    branchesSaveChangesButton: 'Сохранить изменения',
    companyCurrencyTitle: 'Валюта компании',
    visitsLogTitle: 'Журнал визитов',
    visitsManualButton: 'Ручная отметка',
    visitsSelectBranchHint: 'Выберите филиал для ручной отметки посещения.',
    visitsLoading: 'Загружаем визиты...',
    visitsEmptyTitle: 'Визитов пока нет',
    visitsEmptyDesc:
        'Отметки по QR-коду и ручные визиты появятся в этом списке.',
    visitStatusCancelled: 'Отменён',
    visitStatusCompleted: 'Завершён',
    visitCancelButton: 'Отменить визит',
    visitMethodGymQr: 'QR зала',
    visitMethodClientQr: 'QR клиента',
    visitManualSheetTitle: 'Ручная отметка визита',
    visitClientIdLabel: 'ID клиента',
    visitBackdatedCheckbox: 'Отметить задним числом',
    visitDateTimeLabel: 'Дата и время визита (+05:00)',
    visitSubmitButton: 'Отметить посещение',
    visitCancelReasonLabel: 'Причина отмены',
    visitConfirmCancelButton: 'Подтвердить отмену',
    backLabel: 'Назад',
    clientsMergeDuplicatesButton: 'Объединить дубли',
    clientsAddButton: 'Добавить клиента',
    clientsSearchLabel: 'Поиск',
    clientsSearchHint: 'Имя, телефон или email',
    clientsFindButton: 'Найти',
    clientsLoading: 'Загружаем клиентов...',
    clientsEmptyTitle: 'Клиенты не найдены',
    clientsEmptyDesc:
        'Измените запрос поиска или зарегистрируйте нового клиента.',
    clientsShowMoreButton: 'Показать ещё',
    clientLinkedBadge: 'Привязан к uGym',
    clientOfflineBadge: 'Оффлайн-карточка',
    clientNewSheetTitle: 'Новый клиент',
    clientNameLabel: 'Имя',
    clientPhoneLabel: 'Телефон',
    clientEmailOptionalLabel: 'Email (необязательно)',
    clientAutoLinkHint: 'Если клиент подтвердит этот email в приложении uGym, карточка и абонемент привяжутся автоматически.',
    clientOpenExistingButton: 'Открыть существующую карточку',
    clientCreateButton: 'Создать клиента',
    clientMergeDesc: 'Абонементы, визиты и чеки исходного клиента будут перенесены в целевую карточку.',
    clientMergeConfirmButton: 'Подтвердить слияние',
    clientSellCta: 'Продать абонемент / товар',
    clientTabVisits: 'Посещения',
    clientTabSales: 'Покупки/Чеки',
    clientDetailLoading: 'Загружаем данные клиента...',
    clientNoMembershipsTitle: 'Абонементов нет',
    clientNoMembershipsDesc:
        'У этого клиента пока нет оформленных абонементов.',
    clientFreezeButton: 'Заморозить',
    clientUnfreezeButton: 'Разморозить',
    clientManualCheckInButton: 'Отметить вручную',
    clientNoVisitsTitle: 'Посещений нет',
    clientNoVisitsDesc: 'Клиент ещё не отмечался в зале.',
    clientNoSalesTitle: 'Покупок нет',
    clientNoSalesDesc: 'У этого клиента пока нет чеков.',
    plansTitle: 'Тарифы абонементов',
    plansShowAllButton: 'Показать все',
    plansOnlyActiveButton: 'Только активные',
    plansCreateButton: 'Создать тариф',
    plansLoading: 'Загружаем тарифы...',
    plansEmptyTitle: 'Тарифов пока нет',
    plansEmptyDesc: 'Создайте первый тариф, чтобы продавать абонементы на кассе и в приложении.',
    planStatusActive: 'Активен',
    planStatusArchived: 'В архиве',
    planArchiveButton: 'В архив',
    planActivateButton: 'Активировать',
    planKindUnlimited: 'Безлимит',
    planKindVisitsPack: 'Пакет визитов',
    planKindMixed: 'Визиты + срок',
    planNewTitle: 'Новый тариф',
    planNameLabel: 'Название',
    planPriceInCurrencyLabel: 'Цена в валюте зала',
    planKindSectionLabel: 'Тип тарифа',
    planStartModeSectionLabel: 'Начало действия',
    planStartOnPurchase: 'С момента покупки',
    planStartOnFirstVisit: 'С первого визита',
    planDurationDaysLabel: 'Длительность (дней)',
    planVisitsCountLabel: 'Количество визитов',
    planValidityDaysLabel: 'Срок годности пакета (дней, опционально)',
    planDailyLimitLabel: 'Лимит визитов в день (1–100)',
    planTimeFromLabel: 'Окно с (ЧЧ:ММ)',
    planTimeToLabel: 'Окно до (ЧЧ:ММ)',
    planFreezeDaysLabel: 'Заморозка (дней)',
    planFreezeTimesLabel: 'Заморозок (раз)',
    planSaveButton: 'Сохранить тариф',
    expiringLoading: 'Загружаем абонементы...',
    expiringEmptyTitle: 'Нет истекающих абонементов',
    expiringEmptyDesc:
        'В ближайшие 7 дней ни у одного клиента абонемент не заканчивается.',
    membershipCancelButton: 'Отменить',
    membershipCancelDialogTitle: 'Отменить абонемент',
    requestsTitle: 'Заявки на абонементы',
    requestStatusPending: 'Ожидают',
    requestStatusPaid: 'Оплачены',
    requestStatusCancelled: 'Отменены',
    requestStatusExpired: 'Истекли',
    requestsLoading: 'Загружаем заявки...',
    requestsEmptyTitle: 'Заявок нет',
    requestsEmptyDesc: 'Новые заявки из приложения uGym появятся здесь.',
    requestCancelButton: 'Отменить заявку',
    requestConfirmPaymentButton: 'Подтвердить оплату',
    reasonOptionalLabel: 'Причина (необязательно)',
    confirmLabel: 'Подтвердить',
    salesHistoryTitle: 'История продаж',
    salesLoading: 'Загружаем продажи...',
    salesEmptyTitle: 'Продаж пока нет',
    salesEmptyDesc:
        'Оформленные чеки кассы и оплаченные заявки появятся здесь.',
    saleStatusPaid: 'Оплачен',
    saleRefundButton: 'Возврат',
    saleRefundReasonLabel: 'Причина возврата',
    saleConfirmRefundButton: 'Подтвердить возврат',
    productsTitle: 'Склад товаров',
    productsAddButton: 'Добавить товар',
    productsLoading: 'Загружаем товары...',
    productsEmptyTitle: 'Товаров нет',
    productsEmptyDesc: 'Добавьте воду, коктейли или экипировку для кассы.',
    productEditButton: 'Изменить',
    productNewTitle: 'Новый товар',
    productPriceLabel: 'Цена',
    productStockLabel: 'Остаток',
    productCreateButton: 'Создать',
    productActiveAtPosCheckbox: 'Активен на кассе',
    saveLabel: 'Сохранить',
    trainersSelectBranchDesc: 'Выберите зал, чтобы просматривать тренеров.',
    trainersTitle: 'Тренеры зала',
    trainersAddButton: 'Добавить тренера',
    trainersLoading: 'Загружаем тренеров...',
    trainersEmptyTitle: 'Тренеров пока нет',
    trainersEmptyDesc:
        'Добавьте тренера, чтобы создавать шаблоны групповых занятий.',
    trainerStatusInactive: 'Неактивен',
    trainerEditDialogTitle: 'Редактировать тренера',
    trainerNewDialogTitle: 'Новый тренер',
    trainerBioOptionalLabel: 'О тренере (необязательно)',
    scheduleSelectBranchDesc: 'Выберите зал, чтобы работать с расписанием.',
    scheduleGenerateButton: 'Сгенерировать',
    scheduleNewTemplateButton: 'Новый шаблон',
    scheduleSessionsTab: 'Занятия',
    scheduleTemplatesTab: 'Шаблоны',
    scheduleLoading: 'Загружаем расписание...',
    scheduleNoSessionsTitle: 'Занятий за период нет',
    scheduleNoSessionsDesc: 'Создайте шаблон и сгенерируйте расписание.',
    scheduleSessionCancelled: 'Отменено',
    scheduleBookingsButton: 'Записавшиеся',
    scheduleCancelSessionTitle: 'Отменить занятие',
    scheduleCancelSessionDesc: 'Занятие будет отменено, а всем записавшимся клиентам автоматически вернутся списанные посещения.',
    scheduleNoTemplatesTitle: 'Шаблонов нет',
    scheduleNoTemplatesDesc: 'Добавьте еженедельный шаблон занятия.',
    scheduleTrainerLookupTitle: 'Список группы по занятию',
    scheduleTrainerLookupDesc:
        'Укажите ID занятия, чтобы просмотреть записавшихся клиентов.',
    scheduleSessionIdLabel: 'ID занятия',
    scheduleOpenRosterButton: 'Открыть список группы',
    bookingsLoading: 'Загружаем записи...',
    bookingsEmptyTitle: 'Записей пока нет',
    bookingsEmptyDesc: 'Клиенты ещё не записались на это занятие.',
    bookingStatusBooked: 'Записан',
    bookingStatusCancelled: 'Отменена',
    scheduleGenerateDialogTitle: 'Сгенерировать расписание',
    scheduleStartDateLabel: 'Дата начала (ГГГГ-ММ-ДД)',
    scheduleEndDateLabel: 'Дата окончания (до 62 дней)',
    scheduleNewTemplateDialogTitle: 'Новый шаблон занятия',
    scheduleWeekdayLabel: 'День недели',
    scheduleStartTimeLabel: 'Начало (ЧЧ:ММ)',
    scheduleDurationMinLabel: 'Длительность (15–240 мин)',
    scheduleCapacityLabel: 'Вместимость (1–200)',
    storefrontOwnerOnlyDesc:
        'Редактирование витрины доступно только владельцу.',
    storefrontTitlePrefix: 'Витрина зала',
    storefrontSelectBranchDesc: 'Выберите зал, чтобы настроить его витрину.',
    storefrontApprovedWarning: 'Внимание: сохранение или изменение фото переведёт витрину в статус draft и снимет её с публикации.',
    storefrontPendingHint: 'Витрина на модерации: редактирование и загрузка фото временно заблокированы.',
    storefrontDescriptionLabel: 'Описание зала',
    storefrontAddressLabel: 'Адрес',
    storefrontDistrictLabel: 'Район',
    storefrontLatitudeLabel: 'Широта',
    storefrontLongitudeLabel: 'Долгота',
    storefrontPhoneLabel: 'Телефон зала',
    storefrontHoursLabel: 'Часы работы (пн–вс)',
    storefrontAmenitiesLabel: 'Удобства (через запятую, до 30)',
    storefrontSaveButton: 'Сохранить витрину',
    storefrontSubmitModerationButton: 'На модерацию',
    storefrontUnpublishButton: 'Снять с публикации',
    storefrontPublishButton: 'Опубликовать в каталоге',
    storefrontModerationDraft: 'Черновик (draft)',
    storefrontModerationPending: 'На модерации (pending)',
    storefrontModerationApproved: 'Одобрено (approved)',
    storefrontModerationRejected: 'Отклонено (rejected)',
    galleryTitlePrefix: 'Фотогалерея',
    galleryUploadButton: 'Загрузить фото',
    galleryEmptyHint:
        'Фотографий пока нет (до 10 файлов JPEG/PNG/WEBP до 5 МБ).',
    deleteLabel: 'Удалить',
    staffOwnerOnlyDesc: 'Управление штатом доступно только владельцу.',
    staffAddTitle: 'Добавить сотрудника',
    staffEmailLabel: 'Email сотрудника',
    staffRoleOwner: 'Владелец',
    staffRoleAdmin: 'Администратор',
    staffRoleTrainer: 'Тренер',
    staffOtpOnboardingHint: 'Памятка: сотрудник должен установить uGym/uGym Business, зарегистрироваться с этим email и ввести OTP-код подтверждения.',
    staffAddButton: 'Добавить в штат',
    staffListTitle: 'Штат компании',
    staffLoading: 'Загружаем штат...',
    staffEmptyTitle: 'Сотрудников нет',
    staffEmptyDesc: 'Добавьте администратора или тренера по email.',
    staffMakeTrainerButton: 'Сделать тренером',
    staffMakeAdminButton: 'Сделать админом',
  );

  static const BusinessStrings tg = BusinessStrings._(
    appTitle: 'uGym Business',
    navOverview: 'Шарҳ',
    navMembers: 'Мизоҷон',
    navOperations: 'Амалиёт',
    navAnalytics: 'Таҳлил',
    navMore: 'Бештар',
    readOnlyBanner: 'Обуна ба охир расид — танҳо дидан дастрас аст',
    healthOk: 'Сервер ва пойгоҳҳо дастрасанд',
    healthError: 'Сервер дастнорас аст',
    checkHealth: 'Санҷиши пайваст',
    switchTheme: 'Иваз кардани мавзӯъ',
    selectBranch: 'Интихоби филиал',
    themeLightLabel: 'Мавзӯи равшан',
    themeDarkLabel: 'Мавзӯи торик',
    signOutLabel: 'Баромадан',
    detailsLabel: 'Муфассал',
    retryLabel: 'Такрор кардан',
    refreshLabel: 'Навсозӣ',
    branchNotSelected: 'Филиал интихоб нашудааст',
    noCompanyTitle: 'Шумо корманди толор нестед',
    noCompanyDescription:
        'Ширкати худро созед ё барномаи мизоҷи uGym-ро кушоед.',
    createCompanyCta: 'Сохтани ширкат (14 рӯз ройгон)',
    openClientAppCta: 'Гузаштан ба барномаи мизоҷи uGym',
    permissionDeniedTitle: 'Барои дастрасӣ ба ин бахш ҳуқуқ кофӣ нест',
    permissionDeniedDescription:
        'Дастрасӣ бо нақши кунунии шумо дар ширкат маҳдуд аст.',
    subTabClients: 'Мизоҷон',
    subTabExpiring: 'Анҷомёбанда',
    subTabTypes: 'Тарифҳо',
    subTabVisits: 'Ташрифҳо',
    subTabRequests: 'Дархостҳо',
    subTabSales: 'Фурӯшҳо',
    subTabProducts: 'Молҳо',
    subTabSchedule: 'Ҷадвал',
    subTabTrainers: 'Мураббиён',
    subTabSettings: 'Танзимот',
    subTabStorefront: 'Витрина',
    subTabStaff: 'Кормандон',
    subTabAnnouncements: 'Паёмномаҳо',
    subTabBilling: 'Обуна',
    receptionAndPosTitle: 'Қабулгоҳ ва хазина',
    scanClientQrButton: 'Сканери QR мизоҷ',
    kioskQrButton: 'Киоски QR толор',
    openPosButton: 'Кушодани хазина',
    quickActionsTitle: 'Амалҳои зуд',
    roleLabel: 'Нақш',
    roleUnset: 'муайян нашудааст',
    branchLabel: 'Филиал',
    revenueTodayTitle: 'Даромади имрӯз',
    visitsTodayTitle: 'Ташрифҳои имрӯз',
    pendingRequestsTitle: 'Дархостҳои интизор',
    pendingRequestsEmpty: 'Дархостҳои коркарднашуда аз uGym нестанд',
    pendingRequestsHint: 'Интизори тасдиқи пардохт дар хазина',
    goToRequestsButton: 'Ба дархостҳо',
    expiringSoonTitle: 'Дар 7 рӯз анҷом меёбанд',
    expiringSoonEmpty: 'Обунаҳои анҷомёбанда нестанд',
    expiringSoonHint: 'Обунаҳо барои ёдраскунии тамдид',
    goToExpiringButton: 'Ба анҷомёбандаҳо',
    openAnalyticsButton: 'Кушодани таҳлил',
    overviewErrorTitle: 'Хатогии боркунии хулоса',
    receiptsCountLabel: 'Чекҳо',
    membershipsLabel: 'Обунаҳо',
    manualVisitsLabel: 'Дастӣ',
    newClientsLabel: 'Мизоҷони нав',
    cancelLabel: 'Бекор кардан',
    authEmailOrPhoneLabel: 'Email ё телефон',
    authPasswordLabel: 'Рамз',
    authSignInButton: 'Ворид шудан',
    authCreateAccountButton: 'Сохтани ҳисоб',
    authResetPasswordButton: 'Барқарор кардани рамз',
    authPhoneOptionalLabel: 'Телефон (ихтиёрӣ)',
    authPasswordMinLabel: 'Рамз (ҳадди ақал 8 аломат)',
    authRegisterButton: 'Бақайдгирӣ',
    authBackToLoginButton: 'Бозгашт ба воридшавӣ',
    authOtpCodeLabel: 'Рамзи 6-рақама аз почта',
    authVerifyEmailButton: 'Тасдиқи email',
    authResendOtpButton: 'Аз нав фиристодани рамз',
    authSendCodeButton: 'Гирифтани рамз ба email',
    authNewPasswordLabel: 'Рамзи нав',
    authSaveNewPasswordButton: 'Нигоҳ доштани рамзи нав',
    authSubtitleLogin: 'Воридшавӣ барои соҳиб, маъмур ва мураббӣ',
    authSubtitleRegister: 'Бақайдгирии ҳисоби корманд ё соҳиб',
    authSubtitleOtp: 'Тасдиқи email бо рамзи якдафъаина',
    authSubtitleReset: 'Барқарорсозии дастрасӣ бо рамз аз почта',
    scannerCheckingMembership: 'Обуна санҷида мешавад...',
    scannerCameraHint:
        'Камераро ба QR-рамзи шахсии мизоҷ дар барномаи uGym равона кунед',
    scannerVisitRecorded: 'Ташриф сабт шуд',
    scannerMembershipPrefix: 'Обуна №',
    scannerRemainingVisitsPrefix: 'Машғулиятҳои боқимонда: ',
    scannerScanNextButton: 'Скан кардани навбатӣ',
    scannerAcceptPaymentButton: 'Қабули пардохт',
    scannerOpenClientsButton: 'Кушодани мизоҷон',
    scannerNetworkErrorTitle: 'Пайваст бо сервер нест',
    scannerNetworkRetryHint:
        '«Такрор кардан»-ро пахш кунед — ташрифи такрорӣ сохта намешавад.',
    scannerRefusalNoActive: 'Обунаи фаъол нест',
    scannerRefusalFrozen: 'Обуна яхбандӣ шудааст',
    scannerRefusalDailyLimit: 'Лимити вуруд барои имрӯз тамом шуд',
    scannerRefusalOutsideTime: 'Берун аз вақти иҷозатшудаи обуна',
    scannerRefusalInvalidQr: 'QR-рамз нодуруст ё кӯҳна шудааст',
    scannerRefusalGeneric: 'Ташриф сабт нашуд',
    kioskLockedBadge: 'Киоск қулф шудааст',
    kioskModeBadge: 'Реҷаи пештахта',
    kioskLoadingQr: 'Боркунии QR-рамзи толор...',
    kioskScanPrompt: 'Рамзро дар барномаи uGym скан кунед',
    kioskRefreshPrefix: 'Навсозӣ пас аз ',
    kioskSecondsSuffix: ' сон',
    kioskSlotPrefix: 'Слот #',
    kioskSetPinLabel: 'PIN-рамзи 4-рақама барои баромад',
    kioskEnableLockButton: 'Фаъол кардани қулфи киоск',
    kioskLockWithPinButton: 'Қулф кардани киоск бо PIN',
    kioskExitButton: 'Баромадан аз реҷаи киоск',
    kioskUnlockPinLabel: 'PIN-и 4-рақамаи кормандро ворид кунед',
    kioskConfirmPinButton: 'Тасдиқи PIN',
    kioskUnlockAndExitButton: 'Кушодан ва баромадан',
    kioskPinFormatError: '4 рақами PIN-рамзро ворид кунед',
    kioskWrongPinError: 'PIN-рамз нодуруст аст',
    paymentCashLabel: 'Нақд',
    paymentTerminalLabel: 'Терминал',
    paymentTransferLabel: 'Интиқол',
    posTitle: 'Хазина',
    posLoadingCatalog: 'Молҳо ва тарифҳо бор мешаванд...',
    posLoadErrorTitle: 'Хатогии боркунӣ',
    posClientIdLabel: 'ID мизоҷ (барои обуна ҳатмӣ)',
    posNoActivePlans: 'Тарифҳои фаъол нестанд.',
    posNoActiveProducts: 'Молҳои фаъол нестанд.',
    posPaymentMethodLabel: 'Усули пардохт',
    posTotalPrefix: 'Ҷамъ: ',
    posSubmitSaleButton: 'Анҷоми фурӯш',
    posDecreaseQtyTooltip: 'Кам кардани миқдор',
    posIncreaseQtyTooltip: 'Зиёд кардани миқдор',
    analyticsNoAccessTitle: 'Ҳуқуқ кофӣ нест',
    analyticsOwnerOnlyDesc: 'Таҳлил ва даромад танҳо барои соҳиб дастрас аст.',
    analyticsPeriodFilterTitle: 'Филтри давра',
    analyticsTodayLabel: 'Имрӯз',
    analyticsWeekLabel: 'Ҳафта',
    analyticsMonthLabel: 'Моҳ',
    analyticsFromDateLabel: 'Аз (СССС-ММ-РР)',
    analyticsToDateLabel: 'То (СССС-ММ-РР)',
    analyticsInactiveDaysLabel: 'Ғайрифаъол (1–365 рӯз)',
    analyticsApplyButton: 'Татбиқ',
    analyticsLoading: 'Таҳлил бор мешавад...',
    analyticsErrorTitle: 'Хатогии таҳлил',
    analyticsEmptyTitle: 'Маълумот нест',
    analyticsEmptyDesc: 'Давраро интихоб кунед ва ҳисоботро нав созед.',
    analyticsRevenuePrefix: 'Даромад: ',
    analyticsClientsAndVisitsTitle: 'Мизоҷон ва ташрифҳо',
    analyticsTopPlansTitle: 'Тарифҳои беҳтарин',
    analyticsTopProductsTitle: 'Молҳои беҳтарин',
    analyticsNoSalesInPeriod: 'Дар ин давра фурӯш набуд.',
    chartVisitsByDayLabel: 'Ташрифҳо аз рӯи рӯз',
    chartPeakDayPrefix: 'Бештарин дар як рӯз',
    chartVisitsEmpty: 'Дар давраи интихобшуда маълумоти ташриф нест.',
    chartPaymentsEmpty: 'Дар давраи интихобшуда пардохт нест.',
    announcementsTitle: 'Паёмномаи оммавӣ',
    announcementsNoAccessDesc: 'Паёмномаҳо барои соҳиб ва маъмур дастрасанд.',
    announcementsTitleField: 'Сарлавҳа (то 120)',
    announcementsBodyField: 'Матни паём (то 1000)',
    announcementsSendButton: 'Фиристодани паёмнома',
    billingNoAccessDesc: 'Обунаи платформа барои соҳиб ва маъмур дастрас аст.',
    billingLoading: 'Обуна бор мешавад...',
    billingStatusPrefix: 'Обунаи платформа: ',
    billingValidUntilPrefix: 'Амал мекунад то: ',
    billingReadOnlyHint:
        'Реҷаи танҳо дидан: барои тамдид бо дастгирии платформа тамос гиред.',
    billingPlansTitle: 'Тарифҳои платформа',
    billingPlansEmpty: 'Рӯйхати тарифҳо холӣ аст.',
    billingStatusTrial: 'Давраи озмоишӣ (trial)',
    billingStatusActive: 'Фаъол (active)',
    billingStatusExpired: 'Ба охир расид (expired)',
    onboardingTitle: 'Сохтани ширкат (14 рӯз ройгон)',
    onboardingSubtitle: 'Номи ширкат ва филиали аввалро ворид кунед — давраи озмоишӣ худкор фаъол мешавад.',
    onboardingCompanyNameLabel: 'Номи ширкат',
    onboardingGymNameLabel: 'Номи толори аввал',
    onboardingGymAddressLabel: 'Суроғаи толор (ихтиёрӣ)',
    branchesAddTitle: 'Иловаи филиал',
    branchesEditTitle: 'Таҳрири толор',
    branchesNameLabel: 'Номи филиал',
    branchesAddressLabel: 'Суроғаи филиал',
    branchesGeoCheckSwitch: 'Санҷиши минтақаи GPS ҳангоми вуруд',
    branchesGeoRadiusLabel: 'Радиуси минтақа (50–5000 м)',
    branchesNoGeofence: 'Бе минтақа',
    branchesSaveChangesButton: 'Нигоҳ доштани тағйирот',
    companyCurrencyTitle: 'Асъори ширкат',
    visitsLogTitle: 'Рӯйхати ташрифҳо',
    visitsManualButton: 'Сабти дастӣ',
    visitsSelectBranchHint: 'Барои сабти дастии ташриф филиалро интихоб кунед.',
    visitsLoading: 'Ташрифҳо бор мешаванд...',
    visitsEmptyTitle: 'Ҳоло ташриф нест',
    visitsEmptyDesc: 'Ташрифҳои QR ва дастӣ дар ин рӯйхат пайдо мешаванд.',
    visitStatusCancelled: 'Бекор шуд',
    visitStatusCompleted: 'Анҷом ёфт',
    visitCancelButton: 'Бекор кардани ташриф',
    visitMethodGymQr: 'QR толор',
    visitMethodClientQr: 'QR мизоҷ',
    visitManualSheetTitle: 'Сабти дастии ташриф',
    visitClientIdLabel: 'ID мизоҷ',
    visitBackdatedCheckbox: 'Бо санаи гузашта сабт кардан',
    visitDateTimeLabel: 'Сана ва вақти ташриф (+05:00)',
    visitSubmitButton: 'Сабти ташриф',
    visitCancelReasonLabel: 'Сабаби бекоркунӣ',
    visitConfirmCancelButton: 'Тасдиқи бекоркунӣ',
    backLabel: 'Бозгашт',
    clientsMergeDuplicatesButton: 'Муттаҳид кардани такрорҳо',
    clientsAddButton: 'Иловаи мизоҷ',
    clientsSearchLabel: 'Ҷустуҷӯ',
    clientsSearchHint: 'Ном, телефон ё email',
    clientsFindButton: 'Ёфтан',
    clientsLoading: 'Мизоҷон бор мешаванд...',
    clientsEmptyTitle: 'Мизоҷон ёфт нашуданд',
    clientsEmptyDesc:
        'Дархости ҷустуҷӯро тағйир диҳед ё мизоҷи нав сабт кунед.',
    clientsShowMoreButton: 'Бештар нишон додан',
    clientLinkedBadge: 'Ба uGym пайваст',
    clientOfflineBadge: 'Корти офлайн',
    clientNewSheetTitle: 'Мизоҷи нав',
    clientNameLabel: 'Ном',
    clientPhoneLabel: 'Телефон',
    clientEmailOptionalLabel: 'Email (ихтиёрӣ)',
    clientAutoLinkHint: 'Агар мизоҷ ин email-ро дар барномаи uGym тасдиқ кунад, корт ва обуна худкор пайваст мешаванд.',
    clientOpenExistingButton: 'Кушодани корти мавҷуда',
    clientCreateButton: 'Сохтани мизоҷ',
    clientMergeDesc:
        'Обунаҳо, ташрифҳо ва чекҳои мизоҷи аввал ба корти асосӣ мегузаранд.',
    clientMergeConfirmButton: 'Тасдиқи муттаҳидкунӣ',
    clientSellCta: 'Фурӯши обуна / мол',
    clientTabVisits: 'Ташрифҳо',
    clientTabSales: 'Харидҳо/Чекҳо',
    clientDetailLoading: 'Маълумоти мизоҷ бор мешавад...',
    clientNoMembershipsTitle: 'Обуна нест',
    clientNoMembershipsDesc: 'Ин мизоҷ ҳоло обунаи фаъол надорад.',
    clientFreezeButton: 'Яхбандӣ',
    clientUnfreezeButton: 'Кушодан',
    clientManualCheckInButton: 'Сабти дастӣ',
    clientNoVisitsTitle: 'Ташриф нест',
    clientNoVisitsDesc: 'Мизоҷ ҳоло дар толор сабт нашудааст.',
    clientNoSalesTitle: 'Харид нест',
    clientNoSalesDesc: 'Ин мизоҷ ҳоло чек надорад.',
    plansTitle: 'Тарифҳои обуна',
    plansShowAllButton: 'Ҳамаро нишон додан',
    plansOnlyActiveButton: 'Танҳо фаъолҳо',
    plansCreateButton: 'Сохтани тариф',
    plansLoading: 'Тарифҳо бор мешаванд...',
    plansEmptyTitle: 'Ҳоло тариф нест',
    plansEmptyDesc:
        'Тарифи аввалро созед, то обунаҳоро дар хазина ва барнома фурӯшед.',
    planStatusActive: 'Фаъол',
    planStatusArchived: 'Дар бойгонӣ',
    planArchiveButton: 'Ба бойгонӣ',
    planActivateButton: 'Фаъол кардан',
    planKindUnlimited: 'Белимит',
    planKindVisitsPack: 'Бастаи ташрифҳо',
    planKindMixed: 'Ташрифҳо + муҳлат',
    planNewTitle: 'Тарифи нав',
    planNameLabel: 'Ном',
    planPriceInCurrencyLabel: 'Нарх бо асъори толор',
    planKindSectionLabel: 'Навъи тариф',
    planStartModeSectionLabel: 'Оғози амал',
    planStartOnPurchase: 'Аз лаҳзаи харид',
    planStartOnFirstVisit: 'Аз ташрифи аввал',
    planDurationDaysLabel: 'Давомнокӣ (рӯз)',
    planVisitsCountLabel: 'Шумораи ташрифҳо',
    planValidityDaysLabel: 'Муҳлати баста (рӯз, ихтиёрӣ)',
    planDailyLimitLabel: 'Лимити ташриф дар рӯз (1–100)',
    planTimeFromLabel: 'Вақт аз (СС:ДД)',
    planTimeToLabel: 'Вақт то (СС:ДД)',
    planFreezeDaysLabel: 'Яхбандӣ (рӯз)',
    planFreezeTimesLabel: 'Яхбандӣ (бор)',
    planSaveButton: 'Нигоҳ доштани тариф',
    expiringLoading: 'Обунаҳо бор мешаванд...',
    expiringEmptyTitle: 'Обунаҳои анҷомёбанда нестанд',
    expiringEmptyDesc: 'Дар 7 рӯзи оянда обунаи ягон мизоҷ ба охир намерасад.',
    membershipCancelButton: 'Бекор кардан',
    membershipCancelDialogTitle: 'Бекор кардани обуна',
    requestsTitle: 'Дархостҳо барои обуна',
    requestStatusPending: 'Интизор',
    requestStatusPaid: 'Пардохтшуда',
    requestStatusCancelled: 'Бекоршуда',
    requestStatusExpired: 'Муҳлат гузашта',
    requestsLoading: 'Дархостҳо бор мешаванд...',
    requestsEmptyTitle: 'Дархост нест',
    requestsEmptyDesc:
        'Дархостҳои нав аз барномаи uGym дар ин ҷо пайдо мешаванд.',
    requestCancelButton: 'Бекор кардани дархост',
    requestConfirmPaymentButton: 'Тасдиқи пардохт',
    reasonOptionalLabel: 'Сабаб (ихтиёрӣ)',
    confirmLabel: 'Тасдиқ',
    salesHistoryTitle: 'Таърихи фурӯш',
    salesLoading: 'Фурӯшҳо бор мешаванд...',
    salesEmptyTitle: 'Ҳоло фурӯш нест',
    salesEmptyDesc:
        'Чекҳои хазина ва дархостҳои пардохтшуда дар ин ҷо пайдо мешаванд.',
    saleStatusPaid: 'Пардохт шуд',
    saleRefundButton: 'Бозгашт',
    saleRefundReasonLabel: 'Сабаби бозгашт',
    saleConfirmRefundButton: 'Тасдиқи бозгашт',
    productsTitle: 'Анбори молҳо',
    productsAddButton: 'Иловаи мол',
    productsLoading: 'Молҳо бор мешаванд...',
    productsEmptyTitle: 'Мол нест',
    productsEmptyDesc: 'Об, нӯшокиҳо ё лавозимотро барои хазина илова кунед.',
    productEditButton: 'Таҳрир',
    productNewTitle: 'Моли нав',
    productPriceLabel: 'Нарх',
    productStockLabel: 'Боқимонда',
    productCreateButton: 'Сохтан',
    productActiveAtPosCheckbox: 'Дар хазина фаъол',
    saveLabel: 'Нигоҳ доштан',
    trainersSelectBranchDesc: 'Барои дидани мураббиён толорро интихоб кунед.',
    trainersTitle: 'Мураббиёни толор',
    trainersAddButton: 'Иловаи мураббӣ',
    trainersLoading: 'Мураббиён бор мешаванд...',
    trainersEmptyTitle: 'Ҳоло мураббӣ нест',
    trainersEmptyDesc:
        'Барои сохтани қолабҳои машғулиятҳои гурӯҳӣ мураббӣ илова кунед.',
    trainerStatusInactive: 'Ғайрифаъол',
    trainerEditDialogTitle: 'Таҳрири мураббӣ',
    trainerNewDialogTitle: 'Мураббии нав',
    trainerBioOptionalLabel: 'Дар бораи мураббӣ (ихтиёрӣ)',
    scheduleSelectBranchDesc: 'Барои кор бо ҷадвал толорро интихоб кунед.',
    scheduleGenerateButton: 'Тавлид кардан',
    scheduleNewTemplateButton: 'Қолаби нав',
    scheduleSessionsTab: 'Машғулиятҳо',
    scheduleTemplatesTab: 'Қолабҳо',
    scheduleLoading: 'Ҷадвал бор мешавад...',
    scheduleNoSessionsTitle: 'Дар ин давра машғулият нест',
    scheduleNoSessionsDesc: 'Қолаб созед ва ҷадвалро тавлид кунед.',
    scheduleSessionCancelled: 'Бекор шуд',
    scheduleBookingsButton: 'Номнависшудагон',
    scheduleCancelSessionTitle: 'Бекор кардани машғулият',
    scheduleCancelSessionDesc: 'Машғулият бекор карда мешавад ва ба ҳамаи мизоҷони номнависшуда ташрифҳо худкор баргардонида мешаванд.',
    scheduleNoTemplatesTitle: 'Қолаб нест',
    scheduleNoTemplatesDesc: 'Қолаби ҳафтаинаи машғулиятро илова кунед.',
    scheduleTrainerLookupTitle: 'Рӯйхати гурӯҳ аз рӯи машғулият',
    scheduleTrainerLookupDesc:
        'Барои дидани мизоҷони номнависшуда ID-и машғулиятро ворид кунед.',
    scheduleSessionIdLabel: 'ID машғулият',
    scheduleOpenRosterButton: 'Кушодани рӯйхати гурӯҳ',
    bookingsLoading: 'Номнависҳо бор мешаванд...',
    bookingsEmptyTitle: 'Ҳоло номнавис нест',
    bookingsEmptyDesc: 'Мизоҷон ҳоло ба ин машғулият номнавис нашудаанд.',
    bookingStatusBooked: 'Номнавис шуд',
    bookingStatusCancelled: 'Бекор шуд',
    scheduleGenerateDialogTitle: 'Тавлиди ҷадвал',
    scheduleStartDateLabel: 'Санаи оғоз (СССС-ММ-РР)',
    scheduleEndDateLabel: 'Санаи анҷом (то 62 рӯз)',
    scheduleNewTemplateDialogTitle: 'Қолаби нави машғулият',
    scheduleWeekdayLabel: 'Рӯзи ҳафта',
    scheduleStartTimeLabel: 'Оғоз (СС:ДД)',
    scheduleDurationMinLabel: 'Давомнокӣ (15–240 дақ)',
    scheduleCapacityLabel: 'Ғунҷоиш (1–200)',
    storefrontOwnerOnlyDesc: 'Таҳрири витрина танҳо барои соҳиб дастрас аст.',
    storefrontTitlePrefix: 'Витринаи толор',
    storefrontSelectBranchDesc: 'Барои танзими витрина толорро интихоб кунед.',
    storefrontApprovedWarning: 'Диққат: нигоҳ доштан ё иваз кардани акс витринаро ба ҳолати draft мегузаронад ва аз нашр мегирад.',
    storefrontPendingHint: 'Витрина дар модератсия аст: таҳрир ва боргузории акс муваққатан маҳдуд аст.',
    storefrontDescriptionLabel: 'Тавсифи толор',
    storefrontAddressLabel: 'Суроға',
    storefrontDistrictLabel: 'Ноҳия',
    storefrontLatitudeLabel: 'Арзи ҷуғрофӣ',
    storefrontLongitudeLabel: 'Тӯли ҷуғрофӣ',
    storefrontPhoneLabel: 'Телефони толор',
    storefrontHoursLabel: 'Соатҳои корӣ (дш–як)',
    storefrontAmenitiesLabel: 'Имкониятҳо (бо вергул, то 30)',
    storefrontSaveButton: 'Нигоҳ доштани витрина',
    storefrontSubmitModerationButton: 'Ба модератсия',
    storefrontUnpublishButton: 'Аз нашр гирифтан',
    storefrontPublishButton: 'Дар каталог нашр кардан',
    storefrontModerationDraft: 'Сиёҳнавис (draft)',
    storefrontModerationPending: 'Дар модератсия (pending)',
    storefrontModerationApproved: 'Тасдиқ шуд (approved)',
    storefrontModerationRejected: 'Рад шуд (rejected)',
    galleryTitlePrefix: 'Галереяи аксҳо',
    galleryUploadButton: 'Боргузории акс',
    galleryEmptyHint: 'Ҳоло акс нест (то 10 файли JPEG/PNG/WEBP то 5 МБ).',
    deleteLabel: 'Нест кардан',
    staffOwnerOnlyDesc: 'Идоракунии кормандон танҳо барои соҳиб дастрас аст.',
    staffAddTitle: 'Иловаи корманд',
    staffEmailLabel: 'Email-и корманд',
    staffRoleOwner: 'Соҳиб',
    staffRoleAdmin: 'Маъмур',
    staffRoleTrainer: 'Мураббӣ',
    staffOtpOnboardingHint: 'Ёдрас: корманд бояд uGym/uGym Business-ро насб кунад, бо ин email сабти ном шавад ва рамзи тасдиқи OTP-ро ворид намояд.',
    staffAddButton: 'Ба штат илова кардан',
    staffListTitle: 'Кормандони ширкат',
    staffLoading: 'Кормандон бор мешаванд...',
    staffEmptyTitle: 'Корманд нест',
    staffEmptyDesc: 'Маъмур ё мураббиро тавассути email илова кунед.',
    staffMakeTrainerButton: 'Мураббӣ кардан',
    staffMakeAdminButton: 'Маъмур кардан',
  );

  static const BusinessStrings en = BusinessStrings._(
    appTitle: 'uGym Business',
    navOverview: 'Overview',
    navMembers: 'Members',
    navOperations: 'Operations',
    navAnalytics: 'Analytics',
    navMore: 'More',
    readOnlyBanner: 'Subscription expired — read-only mode',
    healthOk: 'Server and databases are healthy',
    healthError: 'Server unavailable',
    checkHealth: 'Check health',
    switchTheme: 'Switch theme',
    selectBranch: 'Select branch',
    themeLightLabel: 'Light theme',
    themeDarkLabel: 'Dark theme',
    signOutLabel: 'Sign out',
    detailsLabel: 'Details',
    retryLabel: 'Retry',
    refreshLabel: 'Refresh',
    branchNotSelected: 'No branch selected',
    noCompanyTitle: 'You are not a gym staff member',
    noCompanyDescription:
        'Create your own company or open the uGym member app.',
    createCompanyCta: 'Create company (14-day free trial)',
    openClientAppCta: 'Open uGym member app',
    permissionDeniedTitle: 'Insufficient permissions',
    permissionDeniedDescription:
        'Access is restricted by your current company role.',
    subTabClients: 'Clients',
    subTabExpiring: 'Expiring',
    subTabTypes: 'Plans',
    subTabVisits: 'Visits',
    subTabRequests: 'Requests',
    subTabSales: 'Sales',
    subTabProducts: 'Products',
    subTabSchedule: 'Schedule',
    subTabTrainers: 'Trainers',
    subTabSettings: 'Settings',
    subTabStorefront: 'Storefront',
    subTabStaff: 'Staff',
    subTabAnnouncements: 'Announcements',
    subTabBilling: 'Subscription',
    receptionAndPosTitle: 'Reception & POS',
    scanClientQrButton: 'Scan client QR',
    kioskQrButton: 'Gym QR kiosk',
    openPosButton: 'Open POS',
    quickActionsTitle: 'Quick actions',
    roleLabel: 'Role',
    roleUnset: 'not assigned',
    branchLabel: 'Branch',
    revenueTodayTitle: 'Revenue today',
    visitsTodayTitle: 'Visits today',
    pendingRequestsTitle: 'Pending requests',
    pendingRequestsEmpty: 'No pending requests from uGym',
    pendingRequestsHint: 'Awaiting payment confirmation at POS',
    goToRequestsButton: 'View requests',
    expiringSoonTitle: 'Expiring in 7 days',
    expiringSoonEmpty: 'No memberships expiring soon',
    expiringSoonHint: 'Memberships to follow up for renewal',
    goToExpiringButton: 'View expiring',
    openAnalyticsButton: 'Open analytics',
    overviewErrorTitle: 'Failed to load summary',
    receiptsCountLabel: 'Receipts',
    membershipsLabel: 'Memberships',
    manualVisitsLabel: 'Manual',
    newClientsLabel: 'New clients',
    cancelLabel: 'Cancel',
    authEmailOrPhoneLabel: 'Email or phone',
    authPasswordLabel: 'Password',
    authSignInButton: 'Sign in',
    authCreateAccountButton: 'Create account',
    authResetPasswordButton: 'Reset password',
    authPhoneOptionalLabel: 'Phone (optional)',
    authPasswordMinLabel: 'Password (min 8 characters)',
    authRegisterButton: 'Register',
    authBackToLoginButton: 'Back to sign in',
    authOtpCodeLabel: '6-digit email code',
    authVerifyEmailButton: 'Verify email',
    authResendOtpButton: 'Resend code',
    authSendCodeButton: 'Send code to email',
    authNewPasswordLabel: 'New password',
    authSaveNewPasswordButton: 'Save new password',
    authSubtitleLogin: 'Sign in for owner, admin, and trainer',
    authSubtitleRegister: 'Register a staff or owner account',
    authSubtitleOtp: 'Verify email with one-time code',
    authSubtitleReset: 'Restore access using the email code',
    scannerCheckingMembership: 'Checking membership...',
    scannerCameraHint:
        'Point the camera at the client personal QR code in the uGym app',
    scannerVisitRecorded: 'Visit recorded',
    scannerMembershipPrefix: 'Membership #',
    scannerRemainingVisitsPrefix: 'Remaining visits: ',
    scannerScanNextButton: 'Scan next',
    scannerAcceptPaymentButton: 'Accept payment',
    scannerOpenClientsButton: 'Open clients',
    scannerNetworkErrorTitle: 'No server connection',
    scannerNetworkRetryHint: 'Tap Retry — no duplicate visit will be created.',
    scannerRefusalNoActive: 'No active membership',
    scannerRefusalFrozen: 'Membership is frozen',
    scannerRefusalDailyLimit: 'Daily check-in limit reached',
    scannerRefusalOutsideTime: 'Outside allowed membership hours',
    scannerRefusalInvalidQr: 'QR code is invalid or expired',
    scannerRefusalGeneric: 'Check-in refused',
    kioskLockedBadge: 'Kiosk locked',
    kioskModeBadge: 'Desk mode',
    kioskLoadingQr: 'Loading gym QR code...',
    kioskScanPrompt: 'Scan this code in the uGym app',
    kioskRefreshPrefix: 'Refreshing in ',
    kioskSecondsSuffix: ' s',
    kioskSlotPrefix: 'Slot #',
    kioskSetPinLabel: '4-digit exit PIN',
    kioskEnableLockButton: 'Enable kiosk lock',
    kioskLockWithPinButton: 'Lock kiosk with PIN',
    kioskExitButton: 'Exit kiosk mode',
    kioskUnlockPinLabel: 'Enter 4-digit staff PIN',
    kioskConfirmPinButton: 'Confirm PIN',
    kioskUnlockAndExitButton: 'Unlock and exit',
    kioskPinFormatError: 'Enter a 4-digit PIN',
    kioskWrongPinError: 'Incorrect PIN',
    paymentCashLabel: 'Cash',
    paymentTerminalLabel: 'Card terminal',
    paymentTransferLabel: 'Transfer',
    posTitle: 'POS',
    posLoadingCatalog: 'Loading products and plans...',
    posLoadErrorTitle: 'Load error',
    posClientIdLabel: 'Client ID (required for membership)',
    posNoActivePlans: 'No active plans.',
    posNoActiveProducts: 'No active products.',
    posPaymentMethodLabel: 'Payment method',
    posTotalPrefix: 'Total: ',
    posSubmitSaleButton: 'Complete sale',
    posDecreaseQtyTooltip: 'Decrease quantity',
    posIncreaseQtyTooltip: 'Increase quantity',
    analyticsNoAccessTitle: 'Insufficient permissions',
    analyticsOwnerOnlyDesc:
        'Analytics and revenue are available to the owner only.',
    analyticsPeriodFilterTitle: 'Period filter',
    analyticsTodayLabel: 'Today',
    analyticsWeekLabel: 'Week',
    analyticsMonthLabel: 'Month',
    analyticsFromDateLabel: 'From (YYYY-MM-DD)',
    analyticsToDateLabel: 'To (YYYY-MM-DD)',
    analyticsInactiveDaysLabel: 'Inactive (1–365 days)',
    analyticsApplyButton: 'Apply',
    analyticsLoading: 'Loading analytics...',
    analyticsErrorTitle: 'Analytics error',
    analyticsEmptyTitle: 'No data',
    analyticsEmptyDesc: 'Select a period and refresh the report.',
    analyticsRevenuePrefix: 'Revenue: ',
    analyticsClientsAndVisitsTitle: 'Clients & attendance',
    analyticsTopPlansTitle: 'Top plans',
    analyticsTopProductsTitle: 'Top products',
    analyticsNoSalesInPeriod: 'No sales in this period.',
    chartVisitsByDayLabel: 'Visits by day',
    chartPeakDayPrefix: 'Daily peak',
    chartVisitsEmpty: 'No visit data for the selected period.',
    chartPaymentsEmpty: 'No payments in the selected period.',
    announcementsTitle: 'Bulk announcement',
    announcementsNoAccessDesc:
        'Announcements are available to owner and admin.',
    announcementsTitleField: 'Title (up to 120)',
    announcementsBodyField: 'Message text (up to 1000)',
    announcementsSendButton: 'Send announcement',
    billingNoAccessDesc:
        'Platform subscription is available to owner and admin.',
    billingLoading: 'Loading subscription...',
    billingStatusPrefix: 'Platform subscription: ',
    billingValidUntilPrefix: 'Valid until: ',
    billingReadOnlyHint: 'Read-only mode: contact platform support to renew.',
    billingPlansTitle: 'Platform plans',
    billingPlansEmpty: 'No plans available.',
    billingStatusTrial: 'Trial period (trial)',
    billingStatusActive: 'Active (active)',
    billingStatusExpired: 'Expired (expired)',
    onboardingTitle: 'Create company (14-day free trial)',
    onboardingSubtitle: 'Enter your company and first gym name — the 14-day trial starts automatically.',
    onboardingCompanyNameLabel: 'Company name',
    onboardingGymNameLabel: 'First gym name',
    onboardingGymAddressLabel: 'Gym address (optional)',
    branchesAddTitle: 'Add branch',
    branchesEditTitle: 'Edit branch',
    branchesNameLabel: 'Branch name',
    branchesAddressLabel: 'Branch address',
    branchesGeoCheckSwitch: 'Check geofence on check-in',
    branchesGeoRadiusLabel: 'Geofence radius (50–5000 m)',
    branchesNoGeofence: 'No geofence',
    branchesSaveChangesButton: 'Save changes',
    companyCurrencyTitle: 'Company currency',
    visitsLogTitle: 'Visits log',
    visitsManualButton: 'Manual check-in',
    visitsSelectBranchHint: 'Select a branch for manual check-in.',
    visitsLoading: 'Loading visits...',
    visitsEmptyTitle: 'No visits yet',
    visitsEmptyDesc: 'QR and manual check-ins will appear here.',
    visitStatusCancelled: 'Cancelled',
    visitStatusCompleted: 'Completed',
    visitCancelButton: 'Cancel visit',
    visitMethodGymQr: 'Gym QR',
    visitMethodClientQr: 'Client QR',
    visitManualSheetTitle: 'Manual visit check-in',
    visitClientIdLabel: 'Client ID',
    visitBackdatedCheckbox: 'Backdate visit',
    visitDateTimeLabel: 'Visit date & time (+05:00)',
    visitSubmitButton: 'Record visit',
    visitCancelReasonLabel: 'Cancellation reason',
    visitConfirmCancelButton: 'Confirm cancellation',
    backLabel: 'Back',
    clientsMergeDuplicatesButton: 'Merge duplicates',
    clientsAddButton: 'Add client',
    clientsSearchLabel: 'Search',
    clientsSearchHint: 'Name, phone or email',
    clientsFindButton: 'Find',
    clientsLoading: 'Loading clients...',
    clientsEmptyTitle: 'No clients found',
    clientsEmptyDesc: 'Adjust your search or register a new client.',
    clientsShowMoreButton: 'Load more',
    clientLinkedBadge: 'Linked to uGym',
    clientOfflineBadge: 'Offline profile',
    clientNewSheetTitle: 'New client',
    clientNameLabel: 'Name',
    clientPhoneLabel: 'Phone',
    clientEmailOptionalLabel: 'Email (optional)',
    clientAutoLinkHint: 'If the client verifies this email in uGym, their profile and membership link automatically.',
    clientOpenExistingButton: 'Open existing profile',
    clientCreateButton: 'Create client',
    clientMergeDesc: 'Memberships, visits, and receipts from the source client will move to the target profile.',
    clientMergeConfirmButton: 'Confirm merge',
    clientSellCta: 'Sell membership / product',
    clientTabVisits: 'Visits',
    clientTabSales: 'Sales / Receipts',
    clientDetailLoading: 'Loading client data...',
    clientNoMembershipsTitle: 'No memberships',
    clientNoMembershipsDesc: 'This client has no memberships yet.',
    clientFreezeButton: 'Freeze',
    clientUnfreezeButton: 'Unfreeze',
    clientManualCheckInButton: 'Manual check-in',
    clientNoVisitsTitle: 'No visits',
    clientNoVisitsDesc: 'The client has not checked in yet.',
    clientNoSalesTitle: 'No purchases',
    clientNoSalesDesc: 'This client has no receipts yet.',
    plansTitle: 'Membership plans',
    plansShowAllButton: 'Show all',
    plansOnlyActiveButton: 'Active only',
    plansCreateButton: 'Create plan',
    plansLoading: 'Loading plans...',
    plansEmptyTitle: 'No plans yet',
    plansEmptyDesc:
        'Create your first plan to sell memberships at POS and in the app.',
    planStatusActive: 'Active',
    planStatusArchived: 'Archived',
    planArchiveButton: 'Archive',
    planActivateButton: 'Activate',
    planKindUnlimited: 'Unlimited',
    planKindVisitsPack: 'Visits pack',
    planKindMixed: 'Visits + duration',
    planNewTitle: 'New plan',
    planNameLabel: 'Name',
    planPriceInCurrencyLabel: 'Price in gym currency',
    planKindSectionLabel: 'Plan type',
    planStartModeSectionLabel: 'Start mode',
    planStartOnPurchase: 'On purchase',
    planStartOnFirstVisit: 'On first visit',
    planDurationDaysLabel: 'Duration (days)',
    planVisitsCountLabel: 'Number of visits',
    planValidityDaysLabel: 'Pack validity (days, optional)',
    planDailyLimitLabel: 'Daily visits limit (1–100)',
    planTimeFromLabel: 'Window from (HH:MM)',
    planTimeToLabel: 'Window to (HH:MM)',
    planFreezeDaysLabel: 'Freeze (days)',
    planFreezeTimesLabel: 'Freezes (count)',
    planSaveButton: 'Save plan',
    expiringLoading: 'Loading memberships...',
    expiringEmptyTitle: 'No expiring memberships',
    expiringEmptyDesc:
        'No client memberships are expiring within the next 7 days.',
    membershipCancelButton: 'Cancel',
    membershipCancelDialogTitle: 'Cancel membership',
    requestsTitle: 'Membership requests',
    requestStatusPending: 'Pending',
    requestStatusPaid: 'Paid',
    requestStatusCancelled: 'Cancelled',
    requestStatusExpired: 'Expired',
    requestsLoading: 'Loading requests...',
    requestsEmptyTitle: 'No requests',
    requestsEmptyDesc: 'New requests from the uGym app will appear here.',
    requestCancelButton: 'Cancel request',
    requestConfirmPaymentButton: 'Confirm payment',
    reasonOptionalLabel: 'Reason (optional)',
    confirmLabel: 'Confirm',
    salesHistoryTitle: 'Sales history',
    salesLoading: 'Loading sales...',
    salesEmptyTitle: 'No sales yet',
    salesEmptyDesc: 'POS receipts and paid requests will appear here.',
    saleStatusPaid: 'Paid',
    saleRefundButton: 'Refund',
    saleRefundReasonLabel: 'Refund reason',
    saleConfirmRefundButton: 'Confirm refund',
    productsTitle: 'Product inventory',
    productsAddButton: 'Add product',
    productsLoading: 'Loading products...',
    productsEmptyTitle: 'No products',
    productsEmptyDesc: 'Add water, shakes, or gear for POS.',
    productEditButton: 'Edit',
    productNewTitle: 'New product',
    productPriceLabel: 'Price',
    productStockLabel: 'Stock',
    productCreateButton: 'Create',
    productActiveAtPosCheckbox: 'Active at POS',
    saveLabel: 'Save',
    trainersSelectBranchDesc: 'Select a gym to view trainers.',
    trainersTitle: 'Gym trainers',
    trainersAddButton: 'Add trainer',
    trainersLoading: 'Loading trainers...',
    trainersEmptyTitle: 'No trainers yet',
    trainersEmptyDesc: 'Add a trainer to create group class templates.',
    trainerStatusInactive: 'Inactive',
    trainerEditDialogTitle: 'Edit trainer',
    trainerNewDialogTitle: 'New trainer',
    trainerBioOptionalLabel: 'About trainer (optional)',
    scheduleSelectBranchDesc: 'Select a gym to manage the schedule.',
    scheduleGenerateButton: 'Generate',
    scheduleNewTemplateButton: 'New template',
    scheduleSessionsTab: 'Sessions',
    scheduleTemplatesTab: 'Templates',
    scheduleLoading: 'Loading schedule...',
    scheduleNoSessionsTitle: 'No sessions in period',
    scheduleNoSessionsDesc: 'Create a template and generate the schedule.',
    scheduleSessionCancelled: 'Cancelled',
    scheduleBookingsButton: 'Bookings',
    scheduleCancelSessionTitle: 'Cancel session',
    scheduleCancelSessionDesc: 'The session will be cancelled and booked clients will have their visits refunded automatically.',
    scheduleNoTemplatesTitle: 'No templates',
    scheduleNoTemplatesDesc: 'Add a weekly class template.',
    scheduleTrainerLookupTitle: 'Class roster by session',
    scheduleTrainerLookupDesc: 'Enter a session ID to view booked clients.',
    scheduleSessionIdLabel: 'Session ID',
    scheduleOpenRosterButton: 'Open class roster',
    bookingsLoading: 'Loading bookings...',
    bookingsEmptyTitle: 'No bookings yet',
    bookingsEmptyDesc: 'No clients have booked this session yet.',
    bookingStatusBooked: 'Booked',
    bookingStatusCancelled: 'Cancelled',
    scheduleGenerateDialogTitle: 'Generate schedule',
    scheduleStartDateLabel: 'Start date (YYYY-MM-DD)',
    scheduleEndDateLabel: 'End date (up to 62 days)',
    scheduleNewTemplateDialogTitle: 'New class template',
    scheduleWeekdayLabel: 'Weekday',
    scheduleStartTimeLabel: 'Start time (HH:MM)',
    scheduleDurationMinLabel: 'Duration (15–240 min)',
    scheduleCapacityLabel: 'Capacity (1–200)',
    storefrontOwnerOnlyDesc:
        'Storefront editing is available to the owner only.',
    storefrontTitlePrefix: 'Gym storefront',
    storefrontSelectBranchDesc: 'Select a gym to configure its storefront.',
    storefrontApprovedWarning: 'Warning: saving or changing photos resets the storefront to draft and unpublishes it.',
    storefrontPendingHint: 'Storefront is under review: editing and photo uploads are temporarily locked.',
    storefrontDescriptionLabel: 'Gym description',
    storefrontAddressLabel: 'Address',
    storefrontDistrictLabel: 'District',
    storefrontLatitudeLabel: 'Latitude',
    storefrontLongitudeLabel: 'Longitude',
    storefrontPhoneLabel: 'Gym phone',
    storefrontHoursLabel: 'Working hours (Mon–Sun)',
    storefrontAmenitiesLabel: 'Amenities (comma-separated, up to 30)',
    storefrontSaveButton: 'Save storefront',
    storefrontSubmitModerationButton: 'Submit for review',
    storefrontUnpublishButton: 'Unpublish',
    storefrontPublishButton: 'Publish to catalog',
    storefrontModerationDraft: 'Draft (draft)',
    storefrontModerationPending: 'Under review (pending)',
    storefrontModerationApproved: 'Approved (approved)',
    storefrontModerationRejected: 'Rejected (rejected)',
    galleryTitlePrefix: 'Photo gallery',
    galleryUploadButton: 'Upload photo',
    galleryEmptyHint:
        'No photos yet (up to 10 JPEG/PNG/WEBP files, max 5 MB each).',
    deleteLabel: 'Delete',
    staffOwnerOnlyDesc: 'Staff management is available to the owner only.',
    staffAddTitle: 'Add staff member',
    staffEmailLabel: 'Staff email',
    staffRoleOwner: 'Owner',
    staffRoleAdmin: 'Admin',
    staffRoleTrainer: 'Trainer',
    staffOtpOnboardingHint: 'Note: the staff member must install uGym/uGym Business, register with this email, and verify it with the OTP code.',
    staffAddButton: 'Add to staff',
    staffListTitle: 'Company staff',
    staffLoading: 'Loading staff...',
    staffEmptyTitle: 'No staff members',
    staffEmptyDesc: 'Invite an admin or trainer by email.',
    staffMakeTrainerButton: 'Make trainer',
    staffMakeAdminButton: 'Make admin',
  );

  static BusinessStrings of(AppLocale locale) {
    return switch (locale) {
      AppLocale.ru => ru,
      AppLocale.tg => tg,
      AppLocale.en => en,
    };
  }
}

/// Propagates the active [BusinessStrings] down the widget tree and pushed routes.
final class BusinessStringsScope extends InheritedWidget {
  const BusinessStringsScope({
    super.key,
    required this.strings,
    required super.child,
  });

  final BusinessStrings strings;

  /// Returns active strings from the nearest scope or defaults to [BusinessStrings.ru].
  static BusinessStrings of(BuildContext context) {
    final scope = context
        .dependOnInheritedWidgetOfExactType<BusinessStringsScope>();
    return scope?.strings ?? BusinessStrings.ru;
  }

  @override
  bool updateShouldNotify(BusinessStringsScope oldWidget) =>
      oldWidget.strings != strings;
}

/// Persists and broadcasts active application language changes.
final class LocaleController extends ChangeNotifier {
  LocaleController({
    required this.preferences,
    AppLocale initialLocale = AppLocale.ru,
  }) : _locale = initialLocale;

  final AppPreferences preferences;
  AppLocale _locale;

  AppLocale get locale => _locale;
  String get localeCode => _locale.code;
  BusinessStrings get strings => BusinessStrings.of(_locale);

  Future<void> load() async {
    final stored = await preferences.readLocaleCode();
    final parsed = AppLocale.fromCode(stored);
    if (parsed != _locale) {
      _locale = parsed;
      notifyListeners();
    }
  }

  Future<void> setLocale(AppLocale newLocale) async {
    if (newLocale == _locale) {
      return;
    }
    _locale = newLocale;
    notifyListeners();
    await preferences.writeLocaleCode(newLocale.code);
  }
}
