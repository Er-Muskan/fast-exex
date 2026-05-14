package com.tracelink.harness.execution;

import java.util.HashMap;
import java.util.Map;

/**
 * Simple MDC (Mapped Diagnostic Context) implementation for thread-local isolation.
 * This provides thread-local context storage to prevent cross-contamination between transformations.
 */
public class MDCContext {
    private static final ThreadLocal<Map<String, String>> context = new ThreadLocal<Map<String, String>>() {
        @Override
        protected Map<String, String> initialValue() {
            return new HashMap<>();
        }
    };

    /**
     * Puts a value into the thread-local context.
     * 
     * @param key The context key
     * @param value The context value
     */
    public static void put(String key, String value) {
        context.get().put(key, value);
    }

    /**
     * Gets a value from the thread-local context.
     * 
     * @param key The context key
     * @return The context value, or null if not found
     */
    public static String get(String key) {
        return context.get().get(key);
    }

    /**
     * Removes a value from the thread-local context.
     * 
     * @param key The context key
     */
    public static void remove(String key) {
        context.get().remove(key);
    }

    /**
     * Clears the entire thread-local context.
     */
    public static void clear() {
        context.get().clear();
    }

    /**
     * Gets the entire context map.
     * 
     * @return The context map
     */
    public static Map<String, String> getContext() {
        return new HashMap<>(context.get());
    }

    /**
     * Sets the entire context map.
     * 
     * @param newContext The new context map
     */
    public static void setContext(Map<String, String> newContext) {
        context.get().clear();
        context.get().putAll(newContext);
    }
}
