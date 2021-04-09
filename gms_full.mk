
PRODUCT_PACKAGES += \
    CalculatorGooglePrebuilt \
    CalendarGooglePrebuilt \
    CarrierMetrics \
    DevicePolicyPrebuilt \
    GoogleContacts \
    GoogleContactsSyncAdapter \
    GoogleTTS \
    LatinIMEGooglePrebuilt \
    LocationHistoryPrebuilt \
    MarkupGoogle \
    OPScreenRecord \
    PlayAutoInstallConfig \
    PrebuiltBugle \
    SoundPickerPrebuilt \
    TrichromeLibrary \
    TrichromeLibrary-Stub \
    WebViewGoogle \
    WebViewGoogle-Stub \
    AndroidAutoStubPrebuilt \
    AndroidMigratePrebuilt \
    AppDirectedSMSService \
    CarrierLocation \
    CarrierServices \
    CarrierSettings \
    CarrierWifi \
    ConfigUpdater \
    ConnMetrics \
    GoogleOneTimeInitializer \
    DevicePersonalizationPrebuiltPixel2020 \
    OBDM_Permissions \
    PartnerSetupPrebuilt \
    Phonesky \
    SettingsIntelligenceGooglePrebuilt \
    SetupWizardPrebuilt \
    TetheringEntitlement \
    Velvet \
    WfcActivation \
    NetworkPermissionConfigGoogle \
    NetworkStackGoogle \
    Flipendo \
    CaptivePortalLoginGoogle \
    GoogleExtShared \
    CarrierSetup \
    CbrsNetworkMonitor \
    GoogleFeedback \
    GoogleOneTimeInitializer \
    GoogleServicesFramework \
    grilservice \
    NexusLauncherRelease \
    PixelSetupWizard \
    RilConfigService \
    StorageManagerGoogle \
    PrebuiltGmsCoreRvc \
    PrebuiltGmsCoreRvc_AdsDynamite \
    PrebuiltGmsCoreRvc_CronetDynamite \
    PrebuiltGmsCoreRvc_DynamiteLoader \
    PrebuiltGmsCoreRvc_DynamiteModulesA \
    PrebuiltGmsCoreRvc_DynamiteModulesC \
    PrebuiltGmsCoreRvc_GoogleCertificates \
    PrebuiltGmsCoreRvc_MapsDynamite \
    PrebuiltGmsCoreRvc_MeasurementDynamite \
    AndroidPlatformServices \
    libprotobuf-cpp-full \
    librsjni

$(call inherit-product, vendor/gms/product/blobs/product_blobs.mk)
$(call inherit-product, vendor/gms/system/blobs/system_blobs.mk)
$(call inherit-product, vendor/gms/system_ext/blobs/system-ext_blobs.mk)
