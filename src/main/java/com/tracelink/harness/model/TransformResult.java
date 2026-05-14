package com.tracelink.harness.model;

public class TransformResult {

    private final boolean success;
    private final String logs;

    public TransformResult(boolean success, String logs) {
        this.success = success;
        this.logs = logs;
    }

    public TransformResult() {
        this(true, "");
    }

    public boolean isSuccess() {
        return success;
    }

    public String logs() {
        return logs;
    }

    public static TransformResult fromContivo(Object results) {
        return new TransformResult(true, results != null ? results.toString() : "");
    }

    @Override
    public String toString() {
        return "TransformResult{success=" + success + "}";
    }
}
