package com.wycklops.protoware;

import com.getcapacitor.JSObject;
import com.getcapacitor.Plugin;
import com.getcapacitor.PluginCall;
import com.getcapacitor.PluginMethod;
import com.getcapacitor.annotation.CapacitorPlugin;
import com.google.android.play.agesignals.AgeSignalsException;
import com.google.android.play.agesignals.AgeSignalsManager;
import com.google.android.play.agesignals.AgeSignalsManagerFactory;
import com.google.android.play.agesignals.AgeSignalsRequest;
import com.google.android.play.agesignals.AgeSignalsResult;
import com.google.android.play.agesignals.model.AgeSignalsVerificationStatus;
import java.text.SimpleDateFormat;
import java.util.Locale;
import java.util.TimeZone;

@CapacitorPlugin(name = "AgeSignal")
public class AgeSignalPlugin extends Plugin {
    @PluginMethod
    public void checkAvailability(PluginCall call) {
        JSObject result = baseResult();
        result.put("status", "notAvailable");
        result.put("message", "Google Play Age Signals plugin is present. Real values depend on Play region, account, and device eligibility.");
        call.resolve(result);
    }

    @PluginMethod
    public void requestDeclaredAge(PluginCall call) {
        AgeSignalsManager manager = AgeSignalsManagerFactory.create(getContext());
        AgeSignalsRequest request = AgeSignalsRequest.builder().build();

        manager.checkAgeSignals(request)
            .addOnSuccessListener(ageSignalsResult -> call.resolve(toPayload(ageSignalsResult)))
            .addOnFailureListener(error -> call.resolve(toErrorPayload(error)));
    }

    private JSObject toPayload(AgeSignalsResult ageSignalsResult) {
        JSObject result = baseResult();
        Integer userStatusCode = ageSignalsResult.userStatus();
        String userStatus = userStatusName(userStatusCode);

        result.put("userStatus", userStatus);
        result.put("ageRangeDeclaration", ageRangeDeclarationName(userStatusCode));
        result.put("activeParentalControls", parentalControls(userStatusCode));
        result.put("lowerBound", ageSignalsResult.ageLower());
        result.put("upperBound", ageSignalsResult.ageUpper());
        result.put("installId", ageSignalsResult.installId());
        result.put("mostRecentApprovalDate", formatDate(ageSignalsResult.mostRecentApprovalDate()));

        if (userStatus == null) {
            result.put("status", "notAvailable");
            result.put("message", "Google Play did not return an age signal for this user, region, or app context.");
            return result;
        }

        if (userStatusCode == AgeSignalsVerificationStatus.UNKNOWN) {
            result.put("status", "notAvailable");
            result.put("message", "Google Play reports the user's age status as unknown.");
            return result;
        }

        result.put("status", "shared");
        result.put("message", "Google Play returned an age signal.");
        return result;
    }

    private JSObject toErrorPayload(Exception error) {
        JSObject result = baseResult();
        result.put("available", false);
        result.put("status", "error");
        result.put("message", errorMessage(error));
        return result;
    }

    private JSObject baseResult() {
        JSObject result = new JSObject();
        result.put("available", true);
        result.put("source", "google");
        return result;
    }

    private String errorMessage(Exception error) {
        if (error instanceof AgeSignalsException) {
            AgeSignalsException ageSignalsException = (AgeSignalsException) error;
            return "Google Play Age Signals failed with code " + ageSignalsException.getErrorCode() + ".";
        }

        return error.getMessage() == null ? "Google Play Age Signals failed." : error.getMessage();
    }

    private String formatDate(java.util.Date date) {
        if (date == null) {
            return null;
        }

        SimpleDateFormat formatter = new SimpleDateFormat("yyyy-MM-dd", Locale.US);
        formatter.setTimeZone(TimeZone.getTimeZone("UTC"));
        return formatter.format(date);
    }

    private String userStatusName(Integer userStatus) {
        if (userStatus == null) {
            return null;
        }

        switch (userStatus) {
            case AgeSignalsVerificationStatus.VERIFIED:
                return "VERIFIED";
            case AgeSignalsVerificationStatus.SUPERVISED:
                return "SUPERVISED";
            case AgeSignalsVerificationStatus.SUPERVISED_APPROVAL_PENDING:
                return "SUPERVISED_APPROVAL_PENDING";
            case AgeSignalsVerificationStatus.SUPERVISED_APPROVAL_DENIED:
                return "SUPERVISED_APPROVAL_DENIED";
            case AgeSignalsVerificationStatus.UNKNOWN:
                return "UNKNOWN";
            case AgeSignalsVerificationStatus.DECLARED:
                return "DECLARED";
            default:
                return "UNRECOGNIZED_" + userStatus;
        }
    }

    private String ageRangeDeclarationName(Integer userStatus) {
        if (userStatus == null) {
            return null;
        }

        switch (userStatus) {
            case AgeSignalsVerificationStatus.DECLARED:
                return "selfDeclared";
            case AgeSignalsVerificationStatus.SUPERVISED:
            case AgeSignalsVerificationStatus.SUPERVISED_APPROVAL_PENDING:
            case AgeSignalsVerificationStatus.SUPERVISED_APPROVAL_DENIED:
                return "guardianDeclared";
            case AgeSignalsVerificationStatus.VERIFIED:
                return "verifiedAdult";
            default:
                return null;
        }
    }

    private String[] parentalControls(Integer userStatus) {
        if (userStatus == null) {
            return new String[0];
        }

        switch (userStatus) {
            case AgeSignalsVerificationStatus.SUPERVISED:
            case AgeSignalsVerificationStatus.SUPERVISED_APPROVAL_PENDING:
            case AgeSignalsVerificationStatus.SUPERVISED_APPROVAL_DENIED:
                return new String[] { "googlePlaySupervision" };
            default:
                return new String[0];
        }
    }
}
