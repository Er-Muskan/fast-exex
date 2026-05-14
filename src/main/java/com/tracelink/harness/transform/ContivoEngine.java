package com.tracelink.harness.transform;

import com.contivo.mixedruntime.runtime.wrapper.Transformer;
import com.contivo.mixedruntime.runtime.wrapper.TransformerResults;
import com.tracelink.harness.model.TransformResult;

import java.io.*;

public class ContivoEngine implements TransformEngine {
    private static final PrintStream NULL_PRINT_STREAM =
            new PrintStream(OutputStream.nullOutputStream());

    /**
     * Pre-loads the map JAR into the JVM classloader once at construction time.
     * Every subsequent new Transformer(mapName) call in execute() hits already-loaded
     * classes instead of re-reading the JAR from disk for each file.
     */
    public ContivoEngine(String mapName) {
        PrintStream originalOut = System.out;
        PrintStream originalErr = System.err;
        try {
            System.setOut(NULL_PRINT_STREAM);
            System.setErr(NULL_PRINT_STREAM);
            new Transformer(mapName);
        } catch (Exception e) {
            System.err.println("Contivo warm-up warning for map '" + mapName
                    + "' (will retry per-file): " + e.getMessage());
        } finally {
            System.setOut(originalOut);
            System.setErr(originalErr);
        }
    }

    @Override
    public TransformResult execute(String mapName, String inputFile, String outputFile,
                                   String fileSeparator) {
        PrintStream originalOut = System.out;
        PrintStream originalErr = System.err;
        ByteArrayOutputStream captured = new ByteArrayOutputStream();
        PrintStream capturedStream = new PrintStream(captured);
        Transformer transformer = null;
        try {
            System.setOut(capturedStream);
            System.setErr(capturedStream);

            // Fresh Transformer per file keeps source/input state clean.
            // Map JAR classes are already in the JVM classloader from the warm-up
            // above, so this instantiation is fast for every file after the first.
            transformer = new Transformer(mapName);
            try (FileInputStream fis = new FileInputStream(new File(inputFile));
                 FileOutputStream fos = new FileOutputStream(new File(outputFile))) {
                transformer.addSource(fis);
                transformer.toTargetStream(fos);
            }
            TransformerResults results = transformer.getResults();
            return TransformResult.fromContivo(results);
        } catch (Exception e) {
            throw new RuntimeException("Contivo transform failed: " + e.getMessage(), e);
        } finally {
            if (transformer != null) {
                try {
                    // Contivo's CLI-compatible logging completes during cleanup.
                    transformer.cleanup();
                } catch (Exception ignored) {
                }
            }

            capturedStream.flush();
            System.setOut(originalOut);
            System.setErr(originalErr);
            writePerFileLog(outputFile, captured);
        }
    }

    private void writePerFileLog(String outputFile, ByteArrayOutputStream captured) {
        try {
            File consoleLogDir = new File(new File(outputFile).getParent(), "console_logs");
            consoleLogDir.mkdirs();
            File logFile = new File(consoleLogDir, new File(outputFile).getName() + ".log");
            try (FileOutputStream logOut = new FileOutputStream(logFile)) {
                captured.writeTo(logOut);
            }
        } catch (Exception ignored) {
            // The shell script already handles missing logs as a failed validation case.
        }
    }
}
