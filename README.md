# Fast-Executor Project

## 🎯 Purpose
Optimized single-JVM batch transformer for Contivo maps. Processes all files in one JVM call instead of spawning separate JVM per file.

## 📁 Project Structure
```
maptest_git/bin/
├── transformerList.sh              # Original script (one JVM per file)
├── transformerList2.sh             # Optimized script (single JVM for all files)
├── transform-test-harness.jar     # Your compiled fast-executor JAR
├── lib/                           # Main library folder (285+ items)
└── fast-executor/                 # Java source code
    ├── pom.xml                    # Maven configuration
    └── com/tracelink/harness/
        ├── execution/
        │   └── TransformExecutor.java    # Main class
        ├── transform/
        │   └── ContivoEngine.java        # Contivo wrapper with performance optimizations
        └── util/
            └── TransformEngineFactory.java
```

## 🚀 Key Features

### 1. **Performance Optimization**
- **Pre-loads map JAR** at construction time (ContivoEngine warmup)
- **Single JVM** processes all files in one batch
- **~20x faster** than original per-file approach
- **Reduced disk I/O** - map JAR read once instead of per-file

### 2. **Enhanced Error Handling**
- **Graceful termination** - Completes current file on Ctrl+C
- **Automatic cleanup** - Removes console logs and temporary files
- **Smart error detection** - Stops on expected errors if needed

### 3. **Flexible Processing**
- **Limit parameter** - `--limit=N` to process subset of files
- **Perfect 1:1 relationship** - Output files and copied originals always match
- **Batch or individual** - Works for both scenarios

## 📋 Usage Examples

### Process all files (default):
```bash
./transformerList2.sh \
  -m=BAHRAIN_Compliance_JSon_ShipmentReportDisplay_OB_V4 \
  -l=../testdata/json/ob/BAHRAIN/BAHRAIN_Compliance_JSon_ShipmentReportDisplay_OB/0_BAHRAIN_LIST_json.txt \
  -e=.json \
  -c=../testdata/json/ob/BAHRAIN/BAHRAIN_Compliance_JSon_ShipmentReportDisplay_OB/VALIDATED \
  -o=../Results/BAHRAIN_Compliance_JSon_ShipmentReportDisplay_OB_V4
```

### Process limited subset:
```bash
./transformerList2.sh \
  -m=BAHRAIN_Compliance_JSon_ShipmentReportDisplay_OB_V4 \
  -l=../testdata/json/ob/BAHRAIN/BAHRAIN_Compliance_JSon_ShipmentReportDisplay_OB/0_BAHRAIN_LIST_json.txt \
  --limit=5 \
  -e=.json \
  -c=../testdata/json/ob/BAHRAIN/BAHRAIN_Compliance_JSon_ShipmentReportDisplay_OB/VALIDATED \
  -o=../Results/BAHRAIN_Compliance_JSon_ShipmentReportDisplay_OB_V4_subset
```

## 🛠 Dependencies

### Core Dependencies (from `../lib/`):
- **Runtime-6.6.3.jar** - Contivo mixed runtime
- **RuntimeCoremodel-6.6.3.jar** - Core model classes (CRITICAL for whitespace handling)

### Build Requirements:
- **Java 11+** (or Java 17 for main project)
- **Maven 3.11.0+** for building

## 🔧 Development

### Build the JAR:
```bash
cd fast-executor
export JAVA_HOME=/path/to/java
mvn clean package
cp target/transform-test-harness-base.jar ../transform-test-harness-base.jar
```

### Update the JAR:
1. Edit Java files in `fast-executor/com/tracelink/harness/`
2. Rebuild with Maven
3. Copy new JAR to `../transform-test-harness.jar`

## 🎯 Performance Results

| Metric | Original Script | Fast-Executor |
|---------|---------------|-------------|
| Files Processed | 447 | 447 |
| JVM Launches | 447 | 1 |
| Total Time | ~10 min | ~30 sec |
| Speed Improvement | ~20x faster |

## 📝 Notes

- The `transform-test-harness.jar` is the only JAR needed by `transformerList2.sh`
- `fast-executor-libs/` contains only the 2 essential JARs
- Main `lib/` folder contains all runtime dependencies
- Source code is in `fast-executor/` for easy maintenance

## 🔄 Version History

- **v1.0** - Initial optimized version with ContivoEngine warmup
- **v1.1** - Added graceful termination and console log cleanup
- **v1.2** - Added `--limit` parameter for subset processing
- **v1.3** - Added exit on expected error failure

---
*Last updated: April 3, 2026*

# Fast-Executor Project Structure

## 📁 Current Organization
```
maptest_git/bin/
├── transformerList.sh              # Original script (one JVM per file)
├── transformerList2.sh             # Optimized script (single JVM for all files)
├── transform-test-harness.jar     # Your compiled fast-executor JAR (9KB)
├── fast-executor-libs/             # Minimal dependencies only
│   ├── Runtime-6.6.3.jar          # Contivo mixedruntime
│   ├── RuntimeCoremodel-6.6.3.jar # Contivo core model (CRITICAL)
│   └── README.md                  # Documentation
├── lib/                           # Original full library set (keep for legacy)
└── fast-executor/                 # Java source code
    ├── pom.xml                    # Maven configuration
    └── com/tracelink/harness/
        ├── execution/
        │   └── TransformExecutor.java    # Main class
        ├── transform/
        │   └── ContivoEngine.java        # Contivo wrapper
        └── util/
            └── TransformEngineFactory.java
```

## 🎯 What You Need vs What You Can Remove

### ✅ KEEP (Required for Fast-Executor)
- `transform-test-harness.jar` - Your compiled code
- `fast-executor-libs/` - Only 2 essential JARs
- `transformerList2.sh` - Optimized script
- `fast-executor/` - Source code (for future updates)

### ❌ CAN REMOVE (Optional Cleanup)
- Most of `lib/` - Except for the 2 JARs copied to `fast-executor-libs/`

### 🔧 When You'll Need This Again

**Only for UPDATES to your Java code:**
1. Edit Java files in `fast-executor/`
2. Run: `cd fast-executor && mvn clean package`
3. New JAR is created: `../transform-test-harness.jar`

**For daily use:**
- Just run: `./transformerList2.sh` with your parameters
- No Java compilation needed!

## 🚀 Performance Benefit
- **Original**: 447 files = 447 JVM launches = ~10+ minutes
- **Fast-Executor**: 447 files = 1 JVM launch = ~30 seconds

## 📋 Minimal Dependencies Explained
1. **Runtime-6.6.3.jar** - Contains `com.contivo.mixedruntime.runtime.wrapper.Transformer`
2. **RuntimeCoremodel-6.6.3.jar** - Contains `WSPFlag` class (fixes whitespace issue)

# Fast-Executor Minimal Libraries

These are the ONLY libraries required for the fast-executor to work:

## Core Dependencies
- **Runtime-6.6.3.jar** - Contivo mixedruntime classes (Transformer, etc.)
- **RuntimeCoremodel-6.6.3.jar** - Contivo core model with WSPFlag class (CRITICAL for whitespace handling)

## Why Only These?
- The fast-executor JAR contains your custom code (TransformExecutor, ContivoEngine, etc.)
- These 2 JARs provide the external dependencies needed at runtime
- All other libraries in the main lib/ folder are for the original transformerList.sh script

## Usage
Update transformerList2.sh to use this folder:
```bash
LIB_FOLDER="./fast-executor-libs"
```

