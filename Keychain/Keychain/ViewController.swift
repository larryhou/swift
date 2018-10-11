//
//  ViewController.swift
//  Keychain
//
//  Created by larryhou on 02/10/2017.
//  Copyright © 2017 larryhou. All rights reserved.
//

import UIKit
import Security

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        var query: [CFString: Any] = [:]
//        query[kSecClass] = kSecClassInternetPassword
//        query[kSecClass] = kSecClassGenericPassword
        query[kSecClass] = kSecClassIdentity
//        query[kSecClass] = kSecClassKey
//        query[kSecClass] = kSecClassCertificate
//        query[kSecReturnData] = true
        query[kSecReturnAttributes] = true
        query[kSecMatchLimit] = kSecMatchLimitAll
//        query[kSecAttrProtocol] = kSecAttrProtocolHTTP
//        query[kSecAttrSynchronizable] = true

        var result: CFTypeRef?
        print(query as CFDictionary)
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        if status == errSecSuccess {
            print(result!)
        } else {
            print(errors[status]!)
        }

        // Do any additional setup after loading the view, typically from a nib.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}

var errors: [OSStatus: String] = {
    var data: [OSStatus: String] = [:]
    data[errSecSuccess] = "errSecSuccess"
    data[errSecUnimplemented] = "errSecUnimplemented"
    data[errSecDskFull] = "errSecDskFull"
    data[errSecIO] = "errSecIO"
    data[errSecOpWr] = "errSecOpWr"
    data[errSecParam] = "errSecParam"
    data[errSecWrPerm] = "errSecWrPerm"
    data[errSecAllocate] = "errSecAllocate"
    data[errSecUserCanceled] = "errSecUserCanceled"
    data[errSecBadReq] = "errSecBadReq"
    data[errSecInternalComponent] = "errSecInternalComponent"
    data[errSecCoreFoundationUnknown] = "errSecCoreFoundationUnknown"
    data[errSecMissingEntitlement] = "errSecMissingEntitlement"
    data[errSecNotAvailable] = "errSecNotAvailable"
    data[errSecReadOnly] = "errSecReadOnly"
    data[errSecAuthFailed] = "errSecAuthFailed"
    data[errSecNoSuchKeychain] = "errSecNoSuchKeychain"
    data[errSecInvalidKeychain] = "errSecInvalidKeychain"
    data[errSecDuplicateKeychain] = "errSecDuplicateKeychain"
    data[errSecDuplicateCallback] = "errSecDuplicateCallback"
    data[errSecInvalidCallback] = "errSecInvalidCallback"
    data[errSecDuplicateItem] = "errSecDuplicateItem"
    data[errSecItemNotFound] = "errSecItemNotFound"
    data[errSecBufferTooSmall] = "errSecBufferTooSmall"
    data[errSecDataTooLarge] = "errSecDataTooLarge"
    data[errSecNoSuchAttr] = "errSecNoSuchAttr"
    data[errSecInvalidItemRef] = "errSecInvalidItemRef"
    data[errSecInvalidSearchRef] = "errSecInvalidSearchRef"
    data[errSecNoSuchClass] = "errSecNoSuchClass"
    data[errSecNoDefaultKeychain] = "errSecNoDefaultKeychain"
    data[errSecInteractionNotAllowed] = "errSecInteractionNotAllowed"
    data[errSecReadOnlyAttr] = "errSecReadOnlyAttr"
    data[errSecWrongSecVersion] = "errSecWrongSecVersion"
    data[errSecKeySizeNotAllowed] = "errSecKeySizeNotAllowed"
    data[errSecNoStorageModule] = "errSecNoStorageModule"
    data[errSecNoCertificateModule] = "errSecNoCertificateModule"
    data[errSecNoPolicyModule] = "errSecNoPolicyModule"
    data[errSecInteractionRequired] = "errSecInteractionRequired"
    data[errSecDataNotAvailable] = "errSecDataNotAvailable"
    data[errSecDataNotModifiable] = "errSecDataNotModifiable"
    data[errSecCreateChainFailed] = "errSecCreateChainFailed"
    data[errSecInvalidPrefsDomain] = "errSecInvalidPrefsDomain"
    data[errSecInDarkWake] = "errSecInDarkWake"
    data[errSecACLNotSimple] = "errSecACLNotSimple"
    data[errSecPolicyNotFound] = "errSecPolicyNotFound"
    data[errSecInvalidTrustSetting] = "errSecInvalidTrustSetting"
    data[errSecNoAccessForItem] = "errSecNoAccessForItem"
    data[errSecInvalidOwnerEdit] = "errSecInvalidOwnerEdit"
    data[errSecTrustNotAvailable] = "errSecTrustNotAvailable"
    data[errSecUnsupportedFormat] = "errSecUnsupportedFormat"
    data[errSecUnknownFormat] = "errSecUnknownFormat"
    data[errSecKeyIsSensitive] = "errSecKeyIsSensitive"
    data[errSecMultiplePrivKeys] = "errSecMultiplePrivKeys"
    data[errSecPassphraseRequired] = "errSecPassphraseRequired"
    data[errSecInvalidPasswordRef] = "errSecInvalidPasswordRef"
    data[errSecInvalidTrustSettings] = "errSecInvalidTrustSettings"
    data[errSecNoTrustSettings] = "errSecNoTrustSettings"
    data[errSecPkcs12VerifyFailure] = "errSecPkcs12VerifyFailure"
    data[errSecNotSigner] = "errSecNotSigner"
    data[errSecDecode] = "errSecDecode"
    data[errSecServiceNotAvailable] = "errSecServiceNotAvailable"
    data[errSecInsufficientClientID] = "errSecInsufficientClientID"
    data[errSecDeviceReset] = "errSecDeviceReset"
    data[errSecDeviceFailed] = "errSecDeviceFailed"
    data[errSecAppleAddAppACLSubject] = "errSecAppleAddAppACLSubject"
    data[errSecApplePublicKeyIncomplete] = "errSecApplePublicKeyIncomplete"
    data[errSecAppleSignatureMismatch] = "errSecAppleSignatureMismatch"
    data[errSecAppleInvalidKeyStartDate] = "errSecAppleInvalidKeyStartDate"
    data[errSecAppleInvalidKeyEndDate] = "errSecAppleInvalidKeyEndDate"
    data[errSecConversionError] = "errSecConversionError"
    data[errSecAppleSSLv2Rollback] = "errSecAppleSSLv2Rollback"
    data[errSecDiskFull] = "errSecDiskFull"
    data[errSecQuotaExceeded] = "errSecQuotaExceeded"
    data[errSecFileTooBig] = "errSecFileTooBig"
    data[errSecInvalidDatabaseBlob] = "errSecInvalidDatabaseBlob"
    data[errSecInvalidKeyBlob] = "errSecInvalidKeyBlob"
    data[errSecIncompatibleDatabaseBlob] = "errSecIncompatibleDatabaseBlob"
    data[errSecIncompatibleKeyBlob] = "errSecIncompatibleKeyBlob"
    data[errSecHostNameMismatch] = "errSecHostNameMismatch"
    data[errSecUnknownCriticalExtensionFlag] = "errSecUnknownCriticalExtensionFlag"
    data[errSecNoBasicConstraints] = "errSecNoBasicConstraints"
    data[errSecNoBasicConstraintsCA] = "errSecNoBasicConstraintsCA"
    data[errSecInvalidAuthorityKeyID] = "errSecInvalidAuthorityKeyID"
    data[errSecInvalidSubjectKeyID] = "errSecInvalidSubjectKeyID"
    data[errSecInvalidKeyUsageForPolicy] = "errSecInvalidKeyUsageForPolicy"
    data[errSecInvalidExtendedKeyUsage] = "errSecInvalidExtendedKeyUsage"
    data[errSecInvalidIDLinkage] = "errSecInvalidIDLinkage"
    data[errSecPathLengthConstraintExceeded] = "errSecPathLengthConstraintExceeded"
    data[errSecInvalidRoot] = "errSecInvalidRoot"
    data[errSecCRLExpired] = "errSecCRLExpired"
    data[errSecCRLNotValidYet] = "errSecCRLNotValidYet"
    data[errSecCRLNotFound] = "errSecCRLNotFound"
    data[errSecCRLServerDown] = "errSecCRLServerDown"
    data[errSecCRLBadURI] = "errSecCRLBadURI"
    data[errSecUnknownCertExtension] = "errSecUnknownCertExtension"
    data[errSecUnknownCRLExtension] = "errSecUnknownCRLExtension"
    data[errSecCRLNotTrusted] = "errSecCRLNotTrusted"
    data[errSecCRLPolicyFailed] = "errSecCRLPolicyFailed"
    data[errSecIDPFailure] = "errSecIDPFailure"
    data[errSecSMIMEEmailAddressesNotFound] = "errSecSMIMEEmailAddressesNotFound"
    data[errSecSMIMEBadExtendedKeyUsage] = "errSecSMIMEBadExtendedKeyUsage"
    data[errSecSMIMEBadKeyUsage] = "errSecSMIMEBadKeyUsage"
    data[errSecSMIMEKeyUsageNotCritical] = "errSecSMIMEKeyUsageNotCritical"
    data[errSecSMIMENoEmailAddress] = "errSecSMIMENoEmailAddress"
    data[errSecSMIMESubjAltNameNotCritical] = "errSecSMIMESubjAltNameNotCritical"
    data[errSecSSLBadExtendedKeyUsage] = "errSecSSLBadExtendedKeyUsage"
    data[errSecOCSPBadResponse] = "errSecOCSPBadResponse"
    data[errSecOCSPBadRequest] = "errSecOCSPBadRequest"
    data[errSecOCSPUnavailable] = "errSecOCSPUnavailable"
    data[errSecOCSPStatusUnrecognized] = "errSecOCSPStatusUnrecognized"
    data[errSecEndOfData] = "errSecEndOfData"
    data[errSecIncompleteCertRevocationCheck] = "errSecIncompleteCertRevocationCheck"
    data[errSecNetworkFailure] = "errSecNetworkFailure"
    data[errSecOCSPNotTrustedToAnchor] = "errSecOCSPNotTrustedToAnchor"
    data[errSecRecordModified] = "errSecRecordModified"
    data[errSecOCSPSignatureError] = "errSecOCSPSignatureError"
    data[errSecOCSPNoSigner] = "errSecOCSPNoSigner"
    data[errSecOCSPResponderMalformedReq] = "errSecOCSPResponderMalformedReq"
    data[errSecOCSPResponderInternalError] = "errSecOCSPResponderInternalError"
    data[errSecOCSPResponderTryLater] = "errSecOCSPResponderTryLater"
    data[errSecOCSPResponderSignatureRequired] = "errSecOCSPResponderSignatureRequired"
    data[errSecOCSPResponderUnauthorized] = "errSecOCSPResponderUnauthorized"
    data[errSecOCSPResponseNonceMismatch] = "errSecOCSPResponseNonceMismatch"
    data[errSecCodeSigningBadCertChainLength] = "errSecCodeSigningBadCertChainLength"
    data[errSecCodeSigningNoBasicConstraints] = "errSecCodeSigningNoBasicConstraints"
    data[errSecCodeSigningBadPathLengthConstraint] = "errSecCodeSigningBadPathLengthConstraint"
    data[errSecCodeSigningNoExtendedKeyUsage] = "errSecCodeSigningNoExtendedKeyUsage"
    data[errSecCodeSigningDevelopment] = "errSecCodeSigningDevelopment"
    data[errSecResourceSignBadCertChainLength] = "errSecResourceSignBadCertChainLength"
    data[errSecResourceSignBadExtKeyUsage] = "errSecResourceSignBadExtKeyUsage"
    data[errSecTrustSettingDeny] = "errSecTrustSettingDeny"
    data[errSecInvalidSubjectName] = "errSecInvalidSubjectName"
    data[errSecUnknownQualifiedCertStatement] = "errSecUnknownQualifiedCertStatement"
    data[errSecMobileMeRequestQueued] = "errSecMobileMeRequestQueued"
    data[errSecMobileMeRequestRedirected] = "errSecMobileMeRequestRedirected"
    data[errSecMobileMeServerError] = "errSecMobileMeServerError"
    data[errSecMobileMeServerNotAvailable] = "errSecMobileMeServerNotAvailable"
    data[errSecMobileMeServerAlreadyExists] = "errSecMobileMeServerAlreadyExists"
    data[errSecMobileMeServerServiceErr] = "errSecMobileMeServerServiceErr"
    data[errSecMobileMeRequestAlreadyPending] = "errSecMobileMeRequestAlreadyPending"
    data[errSecMobileMeNoRequestPending] = "errSecMobileMeNoRequestPending"
    data[errSecMobileMeCSRVerifyFailure] = "errSecMobileMeCSRVerifyFailure"
    data[errSecMobileMeFailedConsistencyCheck] = "errSecMobileMeFailedConsistencyCheck"
    data[errSecNotInitialized] = "errSecNotInitialized"
    data[errSecInvalidHandleUsage] = "errSecInvalidHandleUsage"
    data[errSecPVCReferentNotFound] = "errSecPVCReferentNotFound"
    data[errSecFunctionIntegrityFail] = "errSecFunctionIntegrityFail"
    data[errSecInternalError] = "errSecInternalError"
    data[errSecMemoryError] = "errSecMemoryError"
    data[errSecInvalidData] = "errSecInvalidData"
    data[errSecMDSError] = "errSecMDSError"
    data[errSecInvalidPointer] = "errSecInvalidPointer"
    data[errSecSelfCheckFailed] = "errSecSelfCheckFailed"
    data[errSecFunctionFailed] = "errSecFunctionFailed"
    data[errSecModuleManifestVerifyFailed] = "errSecModuleManifestVerifyFailed"
    data[errSecInvalidGUID] = "errSecInvalidGUID"
    data[errSecInvalidHandle] = "errSecInvalidHandle"
    data[errSecInvalidDBList] = "errSecInvalidDBList"
    data[errSecInvalidPassthroughID] = "errSecInvalidPassthroughID"
    data[errSecInvalidNetworkAddress] = "errSecInvalidNetworkAddress"
    data[errSecCRLAlreadySigned] = "errSecCRLAlreadySigned"
    data[errSecInvalidNumberOfFields] = "errSecInvalidNumberOfFields"
    data[errSecVerificationFailure] = "errSecVerificationFailure"
    data[errSecUnknownTag] = "errSecUnknownTag"
    data[errSecInvalidSignature] = "errSecInvalidSignature"
    data[errSecInvalidName] = "errSecInvalidName"
    data[errSecInvalidCertificateRef] = "errSecInvalidCertificateRef"
    data[errSecInvalidCertificateGroup] = "errSecInvalidCertificateGroup"
    data[errSecTagNotFound] = "errSecTagNotFound"
    data[errSecInvalidQuery] = "errSecInvalidQuery"
    data[errSecInvalidValue] = "errSecInvalidValue"
    data[errSecCallbackFailed] = "errSecCallbackFailed"
    data[errSecACLDeleteFailed] = "errSecACLDeleteFailed"
    data[errSecACLReplaceFailed] = "errSecACLReplaceFailed"
    data[errSecACLAddFailed] = "errSecACLAddFailed"
    data[errSecACLChangeFailed] = "errSecACLChangeFailed"
    data[errSecInvalidAccessCredentials] = "errSecInvalidAccessCredentials"
    data[errSecInvalidRecord] = "errSecInvalidRecord"
    data[errSecInvalidACL] = "errSecInvalidACL"
    data[errSecInvalidSampleValue] = "errSecInvalidSampleValue"
    data[errSecIncompatibleVersion] = "errSecIncompatibleVersion"
    data[errSecPrivilegeNotGranted] = "errSecPrivilegeNotGranted"
    data[errSecInvalidScope] = "errSecInvalidScope"
    data[errSecPVCAlreadyConfigured] = "errSecPVCAlreadyConfigured"
    data[errSecInvalidPVC] = "errSecInvalidPVC"
    data[errSecEMMLoadFailed] = "errSecEMMLoadFailed"
    data[errSecEMMUnloadFailed] = "errSecEMMUnloadFailed"
    data[errSecAddinLoadFailed] = "errSecAddinLoadFailed"
    data[errSecInvalidKeyRef] = "errSecInvalidKeyRef"
    data[errSecInvalidKeyHierarchy] = "errSecInvalidKeyHierarchy"
    data[errSecAddinUnloadFailed] = "errSecAddinUnloadFailed"
    data[errSecLibraryReferenceNotFound] = "errSecLibraryReferenceNotFound"
    data[errSecInvalidAddinFunctionTable] = "errSecInvalidAddinFunctionTable"
    data[errSecInvalidServiceMask] = "errSecInvalidServiceMask"
    data[errSecModuleNotLoaded] = "errSecModuleNotLoaded"
    data[errSecInvalidSubServiceID] = "errSecInvalidSubServiceID"
    data[errSecAttributeNotInContext] = "errSecAttributeNotInContext"
    data[errSecModuleManagerInitializeFailed] = "errSecModuleManagerInitializeFailed"
    data[errSecModuleManagerNotFound] = "errSecModuleManagerNotFound"
    data[errSecEventNotificationCallbackNotFound] = "errSecEventNotificationCallbackNotFound"
    data[errSecInputLengthError] = "errSecInputLengthError"
    data[errSecOutputLengthError] = "errSecOutputLengthError"
    data[errSecPrivilegeNotSupported] = "errSecPrivilegeNotSupported"
    data[errSecDeviceError] = "errSecDeviceError"
    data[errSecAttachHandleBusy] = "errSecAttachHandleBusy"
    data[errSecNotLoggedIn] = "errSecNotLoggedIn"
    data[errSecAlgorithmMismatch] = "errSecAlgorithmMismatch"
    data[errSecKeyUsageIncorrect] = "errSecKeyUsageIncorrect"
    data[errSecKeyBlobTypeIncorrect] = "errSecKeyBlobTypeIncorrect"
    data[errSecKeyHeaderInconsistent] = "errSecKeyHeaderInconsistent"
    data[errSecUnsupportedKeyFormat] = "errSecUnsupportedKeyFormat"
    data[errSecUnsupportedKeySize] = "errSecUnsupportedKeySize"
    data[errSecInvalidKeyUsageMask] = "errSecInvalidKeyUsageMask"
    data[errSecUnsupportedKeyUsageMask] = "errSecUnsupportedKeyUsageMask"
    data[errSecInvalidKeyAttributeMask] = "errSecInvalidKeyAttributeMask"
    data[errSecUnsupportedKeyAttributeMask] = "errSecUnsupportedKeyAttributeMask"
    data[errSecInvalidKeyLabel] = "errSecInvalidKeyLabel"
    data[errSecUnsupportedKeyLabel] = "errSecUnsupportedKeyLabel"
    data[errSecInvalidKeyFormat] = "errSecInvalidKeyFormat"
    data[errSecUnsupportedVectorOfBuffers] = "errSecUnsupportedVectorOfBuffers"
    data[errSecInvalidInputVector] = "errSecInvalidInputVector"
    data[errSecInvalidOutputVector] = "errSecInvalidOutputVector"
    data[errSecInvalidContext] = "errSecInvalidContext"
    data[errSecInvalidAlgorithm] = "errSecInvalidAlgorithm"
    data[errSecInvalidAttributeKey] = "errSecInvalidAttributeKey"
    data[errSecMissingAttributeKey] = "errSecMissingAttributeKey"
    data[errSecInvalidAttributeInitVector] = "errSecInvalidAttributeInitVector"
    data[errSecMissingAttributeInitVector] = "errSecMissingAttributeInitVector"
    data[errSecInvalidAttributeSalt] = "errSecInvalidAttributeSalt"
    data[errSecMissingAttributeSalt] = "errSecMissingAttributeSalt"
    data[errSecInvalidAttributePadding] = "errSecInvalidAttributePadding"
    data[errSecMissingAttributePadding] = "errSecMissingAttributePadding"
    data[errSecInvalidAttributeRandom] = "errSecInvalidAttributeRandom"
    data[errSecMissingAttributeRandom] = "errSecMissingAttributeRandom"
    data[errSecInvalidAttributeSeed] = "errSecInvalidAttributeSeed"
    data[errSecMissingAttributeSeed] = "errSecMissingAttributeSeed"
    data[errSecInvalidAttributePassphrase] = "errSecInvalidAttributePassphrase"
    data[errSecMissingAttributePassphrase] = "errSecMissingAttributePassphrase"
    data[errSecInvalidAttributeKeyLength] = "errSecInvalidAttributeKeyLength"
    data[errSecMissingAttributeKeyLength] = "errSecMissingAttributeKeyLength"
    data[errSecInvalidAttributeBlockSize] = "errSecInvalidAttributeBlockSize"
    data[errSecMissingAttributeBlockSize] = "errSecMissingAttributeBlockSize"
    data[errSecInvalidAttributeOutputSize] = "errSecInvalidAttributeOutputSize"
    data[errSecMissingAttributeOutputSize] = "errSecMissingAttributeOutputSize"
    data[errSecInvalidAttributeRounds] = "errSecInvalidAttributeRounds"
    data[errSecMissingAttributeRounds] = "errSecMissingAttributeRounds"
    data[errSecInvalidAlgorithmParms] = "errSecInvalidAlgorithmParms"
    data[errSecMissingAlgorithmParms] = "errSecMissingAlgorithmParms"
    data[errSecInvalidAttributeLabel] = "errSecInvalidAttributeLabel"
    data[errSecMissingAttributeLabel] = "errSecMissingAttributeLabel"
    data[errSecInvalidAttributeKeyType] = "errSecInvalidAttributeKeyType"
    data[errSecMissingAttributeKeyType] = "errSecMissingAttributeKeyType"
    data[errSecInvalidAttributeMode] = "errSecInvalidAttributeMode"
    data[errSecMissingAttributeMode] = "errSecMissingAttributeMode"
    data[errSecInvalidAttributeEffectiveBits] = "errSecInvalidAttributeEffectiveBits"
    data[errSecMissingAttributeEffectiveBits] = "errSecMissingAttributeEffectiveBits"
    data[errSecInvalidAttributeStartDate] = "errSecInvalidAttributeStartDate"
    data[errSecMissingAttributeStartDate] = "errSecMissingAttributeStartDate"
    data[errSecInvalidAttributeEndDate] = "errSecInvalidAttributeEndDate"
    data[errSecMissingAttributeEndDate] = "errSecMissingAttributeEndDate"
    data[errSecInvalidAttributeVersion] = "errSecInvalidAttributeVersion"
    data[errSecMissingAttributeVersion] = "errSecMissingAttributeVersion"
    data[errSecInvalidAttributePrime] = "errSecInvalidAttributePrime"
    data[errSecMissingAttributePrime] = "errSecMissingAttributePrime"
    data[errSecInvalidAttributeBase] = "errSecInvalidAttributeBase"
    data[errSecMissingAttributeBase] = "errSecMissingAttributeBase"
    data[errSecInvalidAttributeSubprime] = "errSecInvalidAttributeSubprime"
    data[errSecMissingAttributeSubprime] = "errSecMissingAttributeSubprime"
    data[errSecInvalidAttributeIterationCount] = "errSecInvalidAttributeIterationCount"
    data[errSecMissingAttributeIterationCount] = "errSecMissingAttributeIterationCount"
    data[errSecInvalidAttributeDLDBHandle] = "errSecInvalidAttributeDLDBHandle"
    data[errSecMissingAttributeDLDBHandle] = "errSecMissingAttributeDLDBHandle"
    data[errSecInvalidAttributeAccessCredentials] = "errSecInvalidAttributeAccessCredentials"
    data[errSecMissingAttributeAccessCredentials] = "errSecMissingAttributeAccessCredentials"
    data[errSecInvalidAttributePublicKeyFormat] = "errSecInvalidAttributePublicKeyFormat"
    data[errSecMissingAttributePublicKeyFormat] = "errSecMissingAttributePublicKeyFormat"
    data[errSecInvalidAttributePrivateKeyFormat] = "errSecInvalidAttributePrivateKeyFormat"
    data[errSecMissingAttributePrivateKeyFormat] = "errSecMissingAttributePrivateKeyFormat"
    data[errSecInvalidAttributeSymmetricKeyFormat] = "errSecInvalidAttributeSymmetricKeyFormat"
    data[errSecMissingAttributeSymmetricKeyFormat] = "errSecMissingAttributeSymmetricKeyFormat"
    data[errSecInvalidAttributeWrappedKeyFormat] = "errSecInvalidAttributeWrappedKeyFormat"
    data[errSecMissingAttributeWrappedKeyFormat] = "errSecMissingAttributeWrappedKeyFormat"
    data[errSecStagedOperationInProgress] = "errSecStagedOperationInProgress"
    data[errSecStagedOperationNotStarted] = "errSecStagedOperationNotStarted"
    data[errSecVerifyFailed] = "errSecVerifyFailed"
    data[errSecQuerySizeUnknown] = "errSecQuerySizeUnknown"
    data[errSecBlockSizeMismatch] = "errSecBlockSizeMismatch"
    data[errSecPublicKeyInconsistent] = "errSecPublicKeyInconsistent"
    data[errSecDeviceVerifyFailed] = "errSecDeviceVerifyFailed"
    data[errSecInvalidLoginName] = "errSecInvalidLoginName"
    data[errSecAlreadyLoggedIn] = "errSecAlreadyLoggedIn"
    data[errSecInvalidDigestAlgorithm] = "errSecInvalidDigestAlgorithm"
    data[errSecInvalidCRLGroup] = "errSecInvalidCRLGroup"
    data[errSecCertificateCannotOperate] = "errSecCertificateCannotOperate"
    data[errSecCertificateExpired] = "errSecCertificateExpired"
    data[errSecCertificateNotValidYet] = "errSecCertificateNotValidYet"
    data[errSecCertificateRevoked] = "errSecCertificateRevoked"
    data[errSecCertificateSuspended] = "errSecCertificateSuspended"
    data[errSecInsufficientCredentials] = "errSecInsufficientCredentials"
    data[errSecInvalidAction] = "errSecInvalidAction"
    data[errSecInvalidAuthority] = "errSecInvalidAuthority"
    data[errSecVerifyActionFailed] = "errSecVerifyActionFailed"
    data[errSecInvalidCertAuthority] = "errSecInvalidCertAuthority"
    data[errSecInvaldCRLAuthority] = "errSecInvaldCRLAuthority"
    data[errSecInvalidCRLEncoding] = "errSecInvalidCRLEncoding"
    data[errSecInvalidCRLType] = "errSecInvalidCRLType"
    data[errSecInvalidCRL] = "errSecInvalidCRL"
    data[errSecInvalidFormType] = "errSecInvalidFormType"
    data[errSecInvalidID] = "errSecInvalidID"
    data[errSecInvalidIdentifier] = "errSecInvalidIdentifier"
    data[errSecInvalidIndex] = "errSecInvalidIndex"
    data[errSecInvalidPolicyIdentifiers] = "errSecInvalidPolicyIdentifiers"
    data[errSecInvalidTimeString] = "errSecInvalidTimeString"
    data[errSecInvalidReason] = "errSecInvalidReason"
    data[errSecInvalidRequestInputs] = "errSecInvalidRequestInputs"
    data[errSecInvalidResponseVector] = "errSecInvalidResponseVector"
    data[errSecInvalidStopOnPolicy] = "errSecInvalidStopOnPolicy"
    data[errSecInvalidTuple] = "errSecInvalidTuple"
    data[errSecMultipleValuesUnsupported] = "errSecMultipleValuesUnsupported"
    data[errSecNotTrusted] = "errSecNotTrusted"
    data[errSecNoDefaultAuthority] = "errSecNoDefaultAuthority"
    data[errSecRejectedForm] = "errSecRejectedForm"
    data[errSecRequestLost] = "errSecRequestLost"
    data[errSecRequestRejected] = "errSecRequestRejected"
    data[errSecUnsupportedAddressType] = "errSecUnsupportedAddressType"
    data[errSecUnsupportedService] = "errSecUnsupportedService"
    data[errSecInvalidTupleGroup] = "errSecInvalidTupleGroup"
    data[errSecInvalidBaseACLs] = "errSecInvalidBaseACLs"
    data[errSecInvalidTupleCredendtials] = "errSecInvalidTupleCredendtials"
    data[errSecInvalidEncoding] = "errSecInvalidEncoding"
    data[errSecInvalidValidityPeriod] = "errSecInvalidValidityPeriod"
    data[errSecInvalidRequestor] = "errSecInvalidRequestor"
    data[errSecRequestDescriptor] = "errSecRequestDescriptor"
    data[errSecInvalidBundleInfo] = "errSecInvalidBundleInfo"
    data[errSecInvalidCRLIndex] = "errSecInvalidCRLIndex"
    data[errSecNoFieldValues] = "errSecNoFieldValues"
    data[errSecUnsupportedFieldFormat] = "errSecUnsupportedFieldFormat"
    data[errSecUnsupportedIndexInfo] = "errSecUnsupportedIndexInfo"
    data[errSecUnsupportedLocality] = "errSecUnsupportedLocality"
    data[errSecUnsupportedNumAttributes] = "errSecUnsupportedNumAttributes"
    data[errSecUnsupportedNumIndexes] = "errSecUnsupportedNumIndexes"
    data[errSecUnsupportedNumRecordTypes] = "errSecUnsupportedNumRecordTypes"
    data[errSecFieldSpecifiedMultiple] = "errSecFieldSpecifiedMultiple"
    data[errSecIncompatibleFieldFormat] = "errSecIncompatibleFieldFormat"
    data[errSecInvalidParsingModule] = "errSecInvalidParsingModule"
    data[errSecDatabaseLocked] = "errSecDatabaseLocked"
    data[errSecDatastoreIsOpen] = "errSecDatastoreIsOpen"
    data[errSecMissingValue] = "errSecMissingValue"
    data[errSecUnsupportedQueryLimits] = "errSecUnsupportedQueryLimits"
    data[errSecUnsupportedNumSelectionPreds] = "errSecUnsupportedNumSelectionPreds"
    data[errSecUnsupportedOperator] = "errSecUnsupportedOperator"
    data[errSecInvalidDBLocation] = "errSecInvalidDBLocation"
    data[errSecInvalidAccessRequest] = "errSecInvalidAccessRequest"
    data[errSecInvalidIndexInfo] = "errSecInvalidIndexInfo"
    data[errSecInvalidNewOwner] = "errSecInvalidNewOwner"
    data[errSecInvalidModifyMode] = "errSecInvalidModifyMode"
    data[errSecMissingRequiredExtension] = "errSecMissingRequiredExtension"
    data[errSecExtendedKeyUsageNotCritical] = "errSecExtendedKeyUsageNotCritical"
    data[errSecTimestampMissing] = "errSecTimestampMissing"
    data[errSecTimestampInvalid] = "errSecTimestampInvalid"
    data[errSecTimestampNotTrusted] = "errSecTimestampNotTrusted"
    data[errSecTimestampServiceNotAvailable] = "errSecTimestampServiceNotAvailable"
    data[errSecTimestampBadAlg] = "errSecTimestampBadAlg"
    data[errSecTimestampBadRequest] = "errSecTimestampBadRequest"
    data[errSecTimestampBadDataFormat] = "errSecTimestampBadDataFormat"
    data[errSecTimestampTimeNotAvailable] = "errSecTimestampTimeNotAvailable"
    data[errSecTimestampUnacceptedPolicy] = "errSecTimestampUnacceptedPolicy"
    data[errSecTimestampUnacceptedExtension] = "errSecTimestampUnacceptedExtension"
    data[errSecTimestampAddInfoNotAvailable] = "errSecTimestampAddInfoNotAvailable"
    data[errSecTimestampSystemFailure] = "errSecTimestampSystemFailure"
    data[errSecSigningTimeMissing] = "errSecSigningTimeMissing"
    data[errSecTimestampRejection] = "errSecTimestampRejection"
    data[errSecTimestampWaiting] = "errSecTimestampWaiting"
    data[errSecTimestampRevocationWarning] = "errSecTimestampRevocationWarning"
    data[errSecTimestampRevocationNotification] = "errSecTimestampRevocationNotification"
    return data
}()
