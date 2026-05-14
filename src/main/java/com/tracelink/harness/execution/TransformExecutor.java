package com.tracelink.harness.execution;

import com.tracelink.harness.transform.TransformEngine;
import com.tracelink.harness.transform.TransformEngineFactory;

import java.io.File;
import java.io.PrintStream;
import java.nio.file.Files;
import java.nio.file.Paths;
import java.util.List;

/**
 * Single-JVM batch transformer.
 *
 * Usage:
 *   java -cp $CLASSPATH com.tracelink.harness.execution.TransformExecutor \
 *        <listFile> <mapName> <outputDir> <outputExtension> <sourceDir>
 *
 * Reads every file from <listFile>, runs all transforms inside one JVM
 * (map JAR loaded once via ContivoEngine warmup), and writes output files
 * in <outputDir>.
 *
 * Supports console log redirection to per-file logs.
 */
public class TransformExecutor {

    public static void main(String[] args) {
        if (args.length != 5) {
            System.err.println("Usage: java -cp $CLASSPATH com.tracelink.harness.execution.TransformExecutor <listFile> <mapName> <outputDir> <outputExtension> <sourceDir>");
            System.exit(1);
            return;
        }

        String listFile = args[0];
        String mapName = args[1];
        String outputDir = args[2];
        String outputExt = args[3];
        String sourceDir = args[4];
        String consoleLog = System.getenv("CONSOLE_LOG_DIR");
        String sep = System.getProperty("file.separator");

        // Redirect console output to per-file logs if CONSOLE_LOG_DIR is set
        PrintStream originalOut = System.out;
        PrintStream originalErr = System.err;

        List<String> lines;
        try {
            lines = Files.readAllLines(Paths.get(listFile));
        } catch (Exception e) {
            System.err.println("Cannot read list file: " + e.getMessage());
            System.exit(1);
            return;
        }

        // Build engine once — ContivoEngine constructor warms up the map JAR
        // so every subsequent execute() hits already-loaded classes.
        // System.err.println("DEBUG: Creating TransformEngine for map: " + mapName);
                // System.err.println("DEBUG: TransformEngine created successfully");

        int processed = 0;
        // System.err.println("DEBUG: Total lines read: " + lines.size());

        for (String line : lines) {
            line = line.trim();
            // System.err.println("DEBUG: Processing line: '" + line + "'");

            // Skip blank lines, comments, in-list settings, and non-file lines
            if (line.isEmpty() || line.startsWith("#")
                    || line.startsWith("ExpectedError=")
                    || line.startsWith("ExpectedResult=")
                    || line.startsWith("SkipLine=")
                    || line.startsWith("CSVCOUNT=")
                    || line.startsWith("CSVDELIM=")
                    || !line.contains(".")) {  // Only process lines with dots (file extensions)
                // System.err.println("DEBUG: Skipping line (filtered): " + line);
                continue;
            }

            // System.err.println("DEBUG: Processing file: " + line);

            String sourceName  = new File(line).getName();
            String baseName    = sourceName.contains(".")
                    ? sourceName.substring(0, sourceName.lastIndexOf('.'))
                    : sourceName;
            String inputPath   = sourceDir + sep + sourceName;
            String outputPath  = outputDir + sep + baseName + "-OUT" + outputExt;

            // System.err.println("DEBUG: inputPath=" + inputPath + ", outputPath=" + outputPath);

            // Ensure output file exists (script does: touch "$OUTPUT_NAME")
            try {
                new File(outputPath).getParentFile().mkdirs();
                new File(outputPath).createNewFile();
            } catch (Exception ignored) {}

            try {
                // System.err.println("DEBUG: About to transform " + sourceName);

                // Create TestExecutionContext for isolation
                TestExecutionContext execContext = TestExecutionContext.builder()
                        .testSuite("Transform")
                        .testCaseId("TC" + processed)
                        .baseFileName(baseName)
                        .testType("Transform")
                        .isGrouped(false)
                        .inputFilePath(inputPath)
                        .outputFilePath(outputPath)
                        .build();

                // Set MDC context for thread-local isolation
                MDCContext.put("correlationId", execContext.getCorrelationId());
                MDCContext.put("testCase", execContext.getFormattedContext());
                MDCContext.put("map", mapName);
                MDCContext.put("inputFile", inputPath);
                MDCContext.put("outputFile", outputPath);

                // Create TransformEngine using same pattern as working BatchTransformPipeline
                TransformEngine engine = TransformEngineFactory.create(mapName, sep);

                // Execute the transformation
                engine.execute(mapName, inputPath, outputPath, sep);
                
                // Add correlation ID to captured console output for tracking
                System.out.println("=== FILE: " + sourceName + " (Correlation ID: " + execContext.getCorrelationId() + ") ===");

                processed++;
                // System.err.println("DEBUG: Successfully transformed " + sourceName + ", count=" + processed);
            } catch (Exception e) {
                // Clear MDC context even on error to prevent cross-contamination
                MDCContext.clear();
                System.err.println("Transform failed for " + sourceName + ": " + e.getMessage());
                e.printStackTrace();
            }
        }

        System.out.println("TransformExecutor: " + processed + " file(s) transformed.");
        // System.err.println("DEBUG: TransformExecutor completed successfully, about to exit");
        System.exit(0);
    }
}