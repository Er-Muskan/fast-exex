package com.tracelink.harness.transform;

import java.io.IOException;
import java.io.OutputStream;
import java.util.concurrent.atomic.AtomicReference;

/**
 * Thread-safe OutputStream that delegates all writes to a swappable target.
 *
 * Used to avoid repeated System.setOut/setErr calls between files.
 * System.out/err is pointed here once at startup; per-file routing is done
 * by calling setTarget() instead of touching System.out/err again.
 *
 * This prevents stray async writes from a previous Transformer.cleanup()
 * bleeding into the next file's captured log.
 */
public class DispatchingOutputStream extends OutputStream {

    private final AtomicReference<OutputStream> target =
            new AtomicReference<>(OutputStream.nullOutputStream());

    public void setTarget(OutputStream out) {
        target.set(out != null ? out : OutputStream.nullOutputStream());
    }

    @Override
    public void write(int b) throws IOException {
        target.get().write(b);
    }

    @Override
    public void write(byte[] b, int off, int len) throws IOException {
        target.get().write(b, off, len);
    }

    @Override
    public void flush() throws IOException {
        target.get().flush();
    }

    @Override
    public void close() {
        // Never close — this stream lives for the entire JVM lifetime.
    }
}
