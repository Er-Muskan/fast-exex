package com.tracelink.harness.config;

import java.util.List;

public class HarnessConfig {

    private String mapName;
    private String fileSeparator;
    private List<String> filesToTransform;
    private String outputFile;

    public String getMapName() {
        return mapName;
    }

    public void setMapName(String mapName) {
        this.mapName = mapName;
    }

    public String getFileSeparator() {
        return fileSeparator;
    }

    public void setFileSeparator(String fileSeparator) {
        this.fileSeparator = fileSeparator;
    }

    public List<String> getFilesToTransform() {
        return filesToTransform;
    }

    public void setFilesToTransform(List<String> filesToTransform) {
        this.filesToTransform = filesToTransform;
    }

    public String getOutputFile() {
        return outputFile;
    }

    public void setOutputFile(String outputFile) {
        this.outputFile = outputFile;
    }
}
