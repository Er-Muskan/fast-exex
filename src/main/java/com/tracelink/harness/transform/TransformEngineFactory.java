package com.tracelink.harness.transform;

public class TransformEngineFactory {

    public static TransformEngine create(String mapName, String fileSeparator) {
        // ContivoEngine takes mapName to do a one-time warm-up at construction.
        return new ContivoEngine(mapName);
    }
}
