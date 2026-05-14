package com.tracelink.harness.transform;

import com.tracelink.harness.model.TransformResult;

public interface TransformEngine {
    TransformResult execute(String mapName, String inputFile, String outputFile,
                            String fileSeparator);
}
