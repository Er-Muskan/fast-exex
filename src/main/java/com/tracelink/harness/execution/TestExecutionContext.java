package com.tracelink.harness.execution;

import java.util.UUID;

/**
 * Immutable execution context for a test case, used for correlation and tracing.
 * Contains all contextual information needed for logging and error messages.
 *
 * <p>This context object is threaded through the entire execution pipeline:
 * Test Suite Executor -> Input Generators -> Transform Engines -> Validators -> Reporters
 *
 * <p>The correlation ID enables end-to-end tracing of a single test case across all components.
 */
public class TestExecutionContext {
    private final String correlationId;
    private final String testSuite;
    private final String testCaseId;
    private final String baseFileName;
    private final Integer operationIndex;  // null for non-grouped tests
    private final String testType;
    private final boolean isGrouped;
    private final long startTimeMillis;
    private final String inputFilePath;
    private final String outputFilePath;
    private final String toolLogPath;

    private TestExecutionContext(Builder builder) {
        this.correlationId = builder.correlationId;
        this.testSuite = builder.testSuite;
        this.testCaseId = builder.testCaseId;
        this.baseFileName = builder.baseFileName;
        this.operationIndex = builder.operationIndex;
        this.testType = builder.testType;
        this.isGrouped = builder.isGrouped;
        this.startTimeMillis = builder.startTimeMillis;
        this.inputFilePath = builder.inputFilePath;
        this.outputFilePath = builder.outputFilePath;
        this.toolLogPath = builder.toolLogPath;
    }

    /**
     * Creates a new builder for constructing a TestExecutionContext.
     */
    public static Builder builder() {
        return new Builder();
    }

    /**
     * Creates a copy of this context with a specific operation index.
     * Used for grouped test cases where each operation needs its own context.
     *
     * @param index 1-based operation index
     * @return New context with operation index set
     */
    public TestExecutionContext withOperationIndex(int index) {
        return new Builder(this).operationIndex(index).build();
    }

    /**
     * Returns a formatted context string for log messages.
     * Format: [TestSuite:TestCaseId] or [TestSuite:TestCaseId:Op1] for grouped operations
     *
     * @return Formatted context like "[CompareFields:TC001:Op2]"
     */
    public String getFormattedContext() {
        StringBuilder sb = new StringBuilder("[")
            .append(testSuite).append(":").append(testCaseId);
        if (operationIndex != null) {
            sb.append(":Op").append(operationIndex);
        }
        return sb.append("]").toString();
    }

    /**
     * Returns a detailed context string for error messages with file paths.
     * Includes all relevant paths for debugging.
     *
     * @return Detailed context with file paths
     */
    public String getDetailedContext() {
        return String.format("%s Input=%s, Output=%s, BaseFile=%s",
            getFormattedContext(),
            inputFilePath != null ? inputFilePath : "N/A",
            outputFilePath != null ? outputFilePath : "N/A",
            baseFileName);
    }

    /**
     * Returns execution duration in milliseconds from start time to now.
     */
    public long getExecutionDurationMillis() {
        return System.currentTimeMillis() - startTimeMillis;
    }

    // Getters
    public String getCorrelationId() { return correlationId; }
    public String getTestSuite() { return testSuite; }
    public String getTestCaseId() { return testCaseId; }
    public String getBaseFileName() { return baseFileName; }
    public Integer getOperationIndex() { return operationIndex; }
    public String getTestType() { return testType; }
    public boolean isGrouped() { return isGrouped; }
    public long getStartTimeMillis() { return startTimeMillis; }
    public String getInputFilePath() { return inputFilePath; }
    public String getOutputFilePath() { return outputFilePath; }
    public String getToolLogPath() { return toolLogPath; }

    @Override
    public String toString() {
        return getFormattedContext() + " [" + correlationId + "]";
    }

    /**
     * Builder for TestExecutionContext with fluent API.
     */
    public static class Builder {
        private String correlationId;
        private String testSuite;
        private String testCaseId;
        private String baseFileName;
        private Integer operationIndex;
        private String testType;
        private boolean isGrouped;
        private long startTimeMillis;
        private String inputFilePath;
        private String outputFilePath;
        private String toolLogPath;

        private Builder() {
            this.correlationId = UUID.randomUUID().toString();
            this.startTimeMillis = System.currentTimeMillis();
        }

        // Copy constructor for withOperationIndex()
        private Builder(TestExecutionContext context) {
            this.correlationId = context.correlationId;
            this.testSuite = context.testSuite;
            this.testCaseId = context.testCaseId;
            this.baseFileName = context.baseFileName;
            this.operationIndex = context.operationIndex;
            this.testType = context.testType;
            this.isGrouped = context.isGrouped;
            this.startTimeMillis = context.startTimeMillis;
            this.inputFilePath = context.inputFilePath;
            this.outputFilePath = context.outputFilePath;
            this.toolLogPath = context.toolLogPath;
        }

        public Builder correlationId(String correlationId) {
            this.correlationId = correlationId;
            return this;
        }

        public Builder testSuite(String testSuite) {
            this.testSuite = testSuite;
            return this;
        }

        public Builder testCaseId(String testCaseId) {
            this.testCaseId = testCaseId;
            return this;
        }

        public Builder baseFileName(String baseFileName) {
            this.baseFileName = baseFileName;
            return this;
        }

        public Builder operationIndex(Integer operationIndex) {
            this.operationIndex = operationIndex;
            return this;
        }

        public Builder testType(String testType) {
            this.testType = testType;
            return this;
        }

        public Builder isGrouped(boolean isGrouped) {
            this.isGrouped = isGrouped;
            return this;
        }

        public Builder startTimeMillis(long startTimeMillis) {
            this.startTimeMillis = startTimeMillis;
            return this;
        }

        public Builder inputFilePath(String inputFilePath) {
            this.inputFilePath = inputFilePath;
            return this;
        }

        public Builder outputFilePath(String outputFilePath) {
            this.outputFilePath = outputFilePath;
            return this;
        }

        public Builder toolLogPath(String toolLogPath) {
            this.toolLogPath = toolLogPath;
            return this;
        }

        public TestExecutionContext build() {
            // Validation
            if (testSuite == null || testSuite.isEmpty()) {
                throw new IllegalStateException("testSuite is required");
            }
            if (testCaseId == null || testCaseId.isEmpty()) {
                throw new IllegalStateException("testCaseId is required");
            }
            if (testType == null || testType.isEmpty()) {
                throw new IllegalStateException("testType is required");
            }

            return new TestExecutionContext(this);
        }
    }
}
