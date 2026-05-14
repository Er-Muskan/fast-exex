package com.tracelink.harness.transform;

import com.contivo.mixedruntime.runtime.wrapper.Transformer;
import com.contivo.mixedruntime.runtime.wrapper.TransformerResults;
import com.tracelink.harness.model.TransformResult;

import java.io.*;

public class ContivoEngine implements TransformEngine {

    /**
     * Single dispatching stream installed on System.out and System.err once,
     * for the lifetime of the JVM. Per-file routing is done by swapping the
     * target on this stream rather than calling System.setOut/setErr repeatedly.
     *
     * This prevents stray async writes from Transformer.cleanup() in file N
     * from bleeding into file N+1's captured log.
     */
    private static final DispatchingOutputStream DISPATCH = new DispatchingOutputStream();
    private static final PrintStream DISPATCH_STREAM = new PrintStream(DISPATCH, true);

    /**
     * Pre-loads the map JAR into the JVM classloader once at construction time.
     * Installs the dispatching stream on System.out/err here so it is set exactly
     * once rather than save/restore on every execute() call.
     */
    public ContivoEngine(String mapName) {
        // Suppress warmup output, then hand System.out/err to our dispatcher.
        System.setOut(DISPATCH_STREAM);
        System.setErr(DISPATCH_STREAM);
        DISPATCH.setTarget(OutputStream.nullOutputStream());
        try {
            new Transformer(mapName);
        } catch (Exception e) {
            // Warmup failure is non-fatal; per-file execute() will retry.
        } finally {
            // Keep target at null between files — stray async writes disappear safely.
            DISPATCH.setTarget(OutputStream.nullOutputStream());
        }
    }

    @Override
    public TransformResult execute(String mapName, String inputFile, String outputFile,
                                   String fileSeparator) {
        ByteArrayOutputStream captured = new ByteArrayOutputStream();
        // Route all Contivo output to this file's capture buffer.
        DISPATCH.setTarget(captured);

        Transformer transformer = null;
        try {
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
                    // cleanup() may trigger async Contivo logging threads.
                    // Those writes still go to `captured` while target is set here.
                    transformer.cleanup();
                } catch (Exception ignored) {
                }
            }

            DISPATCH_STREAM.flush();

            // Switch target to null BEFORE writing the log and BEFORE the next
            // file's capture is installed. Any late async writes from this file's
            // cleanup() now disappear into null rather than contaminating the
            // next file's capture buffer.
            DISPATCH.setTarget(OutputStream.nullOutputStream());

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
        }
    }
}
