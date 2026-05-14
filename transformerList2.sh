#!/bin/bash

# ##################################################
# transformerList
#
VERSION="1.1.0"               # Sets VERSION variable
echo --------------------------------------------------------   
echo transformerList   VERSION: $VERSION                      
echo --------------------------------------------------------   
#
#  This script is for running lots of feed files through the new Contivo21.2 transformer 
#  function, one after the other, and to report the Results.
#  ALL of the console output is written to log files
MAP_FILE_NAME=$MAP_NAME".jar"
MAP_FILE=$CLASSES_FOLDER"/"$MAP_FILE_NAME
countMapsRun=0
# Disable normal suspend (Ctrl+Z)
stty susp undef

stty intr ^Z
# --- Trap termination signals to ensure cleanup of copied JAR ---
cleanup() {
    echo ""
    echo "Termination detected. Cleaning up..."
    echo "Files processed: $(echo $processedFiles | wc -w)"
    
    # Kill all child processes (Java, etc.)
    pkill -P $$

    if [[ -n "$MAP_FILE_NAME" && -f "$MAP_FILE_NAME" ]]; then
        echo "Cleaning up $MAP_FILE_NAME from bin directory..."
        rm -f "$MAP_FILE_NAME"
    fi
    
    # Clean up unprocessed files (files that were transformed but not validated)
    if [[ -n "$processedFiles" ]]; then
        echo "Cleaning up unprocessed output files..."
        for file in $processedFiles; do
            if [[ -f "$file" ]]; then
                # echo "Keeping processed file: $(basename "$file")"  # Commented out to reduce output
                :
            fi
        done
        
        # Find and remove output files that were NOT processed
        find "$OUTPUT" -name "*-OUT${OUTPUT_EXTENSION}" -type f | while read -r file; do
            if [[ " $processedFiles" != *"$file"* ]]; then
                echo "Removing unprocessed file: $(basename "$file")"
               # rm -f "$file"
            fi
        done
    fi
    
    # Clean up console logs even if terminated early
    if [[ -n "$CONSOLE_LOG_DIR" && -d "$CONSOLE_LOG_DIR" ]]; then
        echo "Cleaning up console logs..."
        #rm -rf "$CONSOLE_LOG_DIR"
    fi
    
    echo "Cleanup complete. Exiting."
    exit 0
}

trap cleanup SIGINT SIGTERM EXIT

# Usage:
#  This script must be run from map-test/bin folder, then supply the map name and the 
#  path and filename of a .txt file containing the list of feed files to run. this list 
#  file must be in the same folder as all the feed files it references.
#  Example:  
#  $ ./transformerList.sh -m=BAHRAIN_Compliance_EPCIS_Shipment_Report_1_2_OB_V1_0 
#                         -l=../../testdata/json/ob/BAHRAIN_Compliance_EPCIS_Shipment_Report_1_2_OB/BAHRAIN_LIST.txt  
#                         -o=../../Results/BAHRAIN_Compliance_EPCIS_Shipment_Report_1_2_OB 
#                         -e=.xml -c=../testdata/json/ob/BAHRAIN_Compliance_EPCIS_Shipment_Report_1_2_OB/VALIDATED -o=../Results/BAHRAIN_Compliance_EPCIS_Shipment_Report_1_2_OB_016


# Description:
#    Runs a list of feeds, from a file, using the java command to call Contivo21.2 and saves the results to specified output files. 
#    Any errors go to specific log file.

# Inputs:
#    1) the map you are running, example BAHRAIN_Compliance_EPCIS_Shipment_Report_1_2_OB_V1_0
    
#    2) filename of a .txt file which contains a list of maps
#       This file needs to be in the same folder as the feed files you are referencing.
#       The file should be plain text and structured like this:
#               # Comments can be added preceded by a pound symbol in the first position on the line.
#				# feedFilename.extension
#               Inbound_shipment_canonical_sample.json
#               shipment_canonical_sample_CJ.json
#       Since comments will be output to the log, i recommend using the comments for test case naming such as MissingRE, MissingOE, Variations

#    3) the output folder to put the results.(Optional - Defaults to ../Results/<Mapname><DateTime>)

#    4) the file extension for the output files.(Optional - Defaults to .xml)

#    5) the folder path to your validated files for comparison to the output file. This will verify that
#       files are the same.

# Output:
#    Results of the command are put in the specified output folder along with log files.



# Command Line Processing
# -----------------------------------
# Process the Command Line arguments and dole them out as needed.
# -----------------------------------
## Check the command line for correct input
MAP_NAME=""
LIST=""
OUTPUT=""
OUTPUT_EXTENSION=""
COMPARE_FOLDER=""

for i in "$@"
do
	case $i in

		-m=* | --map=*)
    		MAP_NAME="${i#*=}"
    		echo
    	;;
    	-l=* | --list=*)
    		LIST="${i#*=}"
    	;;
    	-o=* | --output=*)
    		OUTPUT="${i#*=}"
    	;;
    	-c=* | --compare=*)
    		COMPARE_FOLDER="${i#*=}"
    	;;
    	-e=* | --extension=*)
    		OUTPUT_EXTENSION="${i#*=}"
    	;;
    	-v | --version)
    		echo " "
     		echo "=== transformerList ==="
     		echo " "
     		echo "Version = $VERSION "
     		echo " "
     		echo " "
    	;;
    	-h | --help | -? | ? | *)

		echo -n "
		=== TransformerList ===

Your working directory is expected to be the map-test/bin folder.

From there, the recommended command line call should look like this:
    ./transformerList.sh -m=BAHRAIN_Compliance_EPCIS_Shipment_Report_1_2_OB_V1_0
    -l=../testdata/json/ob/BAHRAIN_Compliance_EPCIS_Shipment_Report_1_2_OB/BAHRAIN_LIST.txt
    -e=.xml -c=../testdata/json/ob/BAHRAIN_Compliance_EPCIS_Shipment_Report_1_2_OB/VALIDATED
    -o=../Results/BAHRAIN_Compliance_EPCIS_Shipment_Report_1_2_OB_016

"
		echo -n "Options:
  -h, --help        Display this help and exit
  -v, --version     Output version information and exit
  -m, --map		    Required, The MAP name and version under test, e.g. BAHRAIN_Compliance_EPCIS_Shipment_Report_1_2_OB_V1_0
  -l, --list		Required, The path and filename of the list file to be used.
  -o, --output      Optional, Path for the output files, this is optional.
  -e, --extension   the file extension for the output files.  Must include the period. ex: .xml, .csv, .json, .txt
  -c, --compare     Optional, The folder location of your files for validation.  this must be a file
                    named the same as the output from a transform performed with this
                    script with '-VALIDATED' appended before the extension.
                    ex: shipment_canonical_sample_CJ-OUT-VALIDATED.xml

  You can also set some settings within your list file. Add the following elements to change the default setting:

  CSVCOUNT=NO       - Set this to NO to turn off counting the CSV delimiters per row.
                      This count verifies that the map writes the same number of columns for every row. The default is YES.
  CSVCOUNT=YES      - Set this to YES to turn on counting the CSV delimiters per row. This is the default setting.
  CSVDELIM=,        - Sets the expected CSV delimiter to a comma ",".  This is the default setting.
  CSVDELIM=|          Sets the expected CSV delimiter to a vertical line, "|"

  ExpectedError=	- add a string to look for as an expected error.  this will count as a test.
                      Multiple expected errors can be added on each line with the preceding
                      ExpectedError= keyword.
  ExpectedResult=	- add a specific string that is expected to be in the target file.
                      Multiple expected results can be added on each line with the preceding
                      ExpectedResult= keyword.

  SkipLine=			- add a string to define a line in the output to skip the compare to VALIDATED.
  					  this allows us to ignore lines that cannot be matched to the VALIDATED file,
  					  such as when the system date/time are used. This setting will apply globally,
  					  so setting this at the start of your List file will allow it to
  					  work for every test that is run.
"
		echo " "
		exit 0
		;;
	esac
done

# Check that the MAP_NAME is set
if [[ $MAP_NAME == "" ]]
then
	echo -n "	ERROR: You forgot some parameters.

	try using the -h or -? switches to learn how to use this script.

"
	exit 2
fi

# Set the output file extension if not declared.
if [[ "$OUTPUT_EXTENSION" == "" ]]
then
   OUTPUT_EXTENSION=".xml"
fi

# -----------------------------------
# Global Variables and Flags
# -----------------------------------
CSVCOUNT="YES"
CSVDELIM=","

# -----------------------------------
# Build the log folder name
# -----------------------------------
#The : character in the timestamp format (%H:%M:%S) is causing issues when used in the folder name so I replace the : characters with hyphen (-), underscore (_)
#timestamp=$(date "+%Y/%m/%d__%H:%M:%S")
timestamp=$(date "+%Y-%m-%d__%H-%M-%S")
if [[ $OUTPUT == "" ]]
then
    OUTPUT="../Results/${MAP_NAME}_${timestamp}"
else
    OUTPUT="$OUTPUT"
fi

# Create the output folder if its not there
if [ ! -d $OUTPUT ]; then
    mkdir -p $OUTPUT;
    chmod 777 $OUTPUT
fi

LOG_FILE=${OUTPUT}/Log_All.txt
exec 3>&1 4>&1 1>>${LOG_FILE} 2>&1  # fd3=terminal for tee, fd4=backup of terminal, fd1/fd2=log

# -----------------------------------
# Build the classpath for java
BASEDIR=$(pwd)
LIB_FOLDER=$(cd $BASEDIR/lib && pwd)

# Check for maps2_git repo first
if [ -d "$BASEDIR/../../maps2_git/classes" ]; then
    CLASSES_FOLDER=$(cd $BASEDIR/../../maps2_git/classes && pwd)
# If maps2git is not found, check for maps repo
elif [ -d "$BASEDIR/../../maps/classes" ]; then
    CLASSES_FOLDER=$(cd $BASEDIR/../../maps/classes && pwd)
else
    echo "Neither maps nor maps2git repositories found."
    exit 1
fi

# CRITICAL FIX: Build classpath with RuntimeCoremodel JAR first to prioritize its WSPFlag class
CLASSPATH="$CLASSES_FOLDER":"$LIB_FOLDER"

# Add map JARs
for f in `ls $CLASSES_FOLDER/*.jar`
do
    CLASSPATH=$CLASSPATH:$f
done

# FIXED: Prioritize RuntimeCoremodel JAR to handle whitespace flags properly
if [ -f "${LIB_FOLDER}/RuntimeCoremodel-6.6.3.jar" ]; then
    CLASSPATH=$CLASSPATH:${LIB_FOLDER}/RuntimeCoremodel-6.6.3.jar
fi

# Add all other lib JARs except the contivocallout JARs (add them later)
for f in `ls ${LIB_FOLDER}/*.jar`
do
    # Skip RuntimeCoremodel (already added) and contivocallout JARs (add later)
    if [[ "$f" != *"RuntimeCoremodel"* ]] && [[ "$f" != *"contivocallout"* ]]; then
        CLASSPATH=$CLASSPATH:$f
    fi
done

# Add contivocallout JARs AFTER RuntimeCoremodel to ensure RuntimeCoremodel's WSPFlag takes precedence
for f in `ls ${LIB_FOLDER}/*contivocallout*.jar`
do
    CLASSPATH=$CLASSPATH:$f
done


OS=`uname`
if [[ "$OS" == *"CYGWIN"* ]]
then
    CLASSPATH=`cygpath -wp $CLASSPATH`
    # OUTFILE=`cygpath -wp $OUTFILE`
    # INFILE=`cygpath -wp $INFILE`
	# DGF 20Dec2023 handle line endings for PC
	set -o igncr
fi

export CLASSPATH

# Path to the transform-test-harness JAR (the Java module that runs all files in one JVM).
# Adjust this path to wherever the harness JAR is built/deployed.
HARNESS_JAR="$BASEDIR/bin/lib/transform-test-harness.jar"



# The Script
# -----------------------------------
# Start scripting here
# -----------------------------------


CONSOLE_LOG_DIR="$OUTPUT/console_logs"

echo --------------------------------------------------------   > $LOG_FILE
echo transformerList   VERSION: $VERSION                        >> $LOG_FILE

MAP_FILE_NAME=$MAP_NAME".jar"
MAP_FILE=$CLASSES_FOLDER"/"$MAP_FILE_NAME
countMapsRun=0

# Copy the map locally since this doesn't work unless the map is local to the script.
cp "$MAP_FILE" "$MAP_FILE_NAME"

# Set the name of the function we are calling
API_NAME="com.contivo.mixedruntime.runtime.wrapper.Transformer"

# get the folder path for the source files
SOURCE_LOCATION=$(dirname $LIST)

# Reporting the status of the script:
# -----------------------------------
echo -------------------------------------------------------- | tee /dev/fd/3
echo MAP_NAME:  | tee /dev/fd/3
echo ${MAP_NAME}| tee /dev/fd/3
echo  | tee /dev/fd/3

echo Command:  | tee /dev/fd/3
echo ./transformerList.sh -m=${MAP_NAME} -l=${LIST} -o=${OUTPUT} -e=${OUTPUT_EXTENSION} -c=${COMPARE_FOLDER} | tee /dev/fd/3
echo  | tee /dev/fd/3

curDir=`pwd`

echo All resulting files and logs will be here:   | tee /dev/fd/3
echo $OUTPUT    | tee /dev/fd/3
echo  | tee /dev/fd/3

echo All results will be logged here:   | tee /dev/fd/3
echo $LOG_FILE    | tee /dev/fd/3
echo   | tee /dev/fd/3

echo --------------------------------------------------------  | tee /dev/fd/3
totalLines=$(grep -v '^\s*#' "${LIST}" | grep -v 'CSVCOUNT=' | grep -v 'CSVDELIM=' | grep -c '\S')
# some variables for tracking metrics of the run
outputCompareErrors=0
outputComparePass=0
outputExceptionsCount=0
ExpectedErrorFail=0
ExpectedErrorPass=0
ExpectedResultFail=0
ExpectedResultPass=0
emptyFileCount=0
lineNo=0
# Track processed files for graceful cleanup
processedFiles=""
# variables for error checking
declare -a strExpectedErrors
declare -a strExpectedResults
declare -a strSkipLines
strConsoleOutput=""

# -----------------------------------
# Single-JVM batch transform — ALL files processed in one java call.
# The map JAR is loaded once (ContivoEngine warmup) and reused for every
# file in the list, instead of spawning a new JVM per file as before.
# The loop below now only handles comparison and reporting.
# -----------------------------------
echo "Running batch transform for all files in list..." | tee /dev/fd/3
echo "DEBUG: Starting Java transform at $(date)" | tee /dev/fd/3
java -Xms512m -Xmx4000m -cp "$CLASSPATH:$HARNESS_JAR" \
    com.tracelink.harness.execution.TransformExecutor \
    "$LIST" "$MAP_NAME" "$OUTPUT" "$OUTPUT_EXTENSION" "$SOURCE_LOCATION"
echo "DEBUG: Java transform completed at $(date)" | tee /dev/fd/3
echo "Batch transform complete. Starting validation loop..." | tee /dev/fd/3
echo "DEBUG: Entering validation loop at $(date)" | tee /dev/fd/3

# While loop, while there are feed names in an input file run the mvn command for each map.
while IFS="" read -r line;
do
    if [[ ${line:0:1} != "#" ]] && [[ ${line:0:1} != " " ]] && [[ ${line:0:8} != "CSVCOUNT" ]] && [[ ${line:0:8} != "CSVDELIM" ]] &&  [[ -n "${line//[[:space:]]/}" ]]; then
               # Increment line number and progress counter
               lineNo=$((lineNo + 1))
               echo "Test Count : " "${lineNo}" "/" "${totalLines}" | tee /dev/fd/3
    fi
    if [[ ${line:0:1} == "#" ]] || [[ ${line:0:1} == "" ]] || [[ ${line:0:1} == " " ]]

    then

    	echo "${line}"   | tee /dev/fd/3

    	# Check for ExpectedError
    	if echo "${line}" | grep -iqF "ExpectedError="
        then
            strExpectedErrors+=("${line##*=}")

        # Check for ExpectedResult
    	elif echo "${line}" | grep -iqF "ExpectedResult="
        then
            strExpectedResults+=("${line##*=}")

        # Check for ExpectedResults
    	elif echo "${line}" | grep -iqF "ExpectedResults="
        then
            strExpectedResults+=("${line##*=}")


        # Check for SkipLines
    	elif echo "${line}" | grep -iqF "SkipLine="
        then
            strSkipLines+=("${line##*=}")
        fi

        # Check for commands for .csv delimited target files
        # delimiter of comma or | are supported
    elif [[ ${line:0:11} == "CSVCOUNT=NO" ]]
    then

    	# SETTING: Turn off the counting of CSV delimiters
    	CSVCOUNT="NO"
    	echo === Counting CSV delimiters is turned off ===  | tee /dev/fd/3

    elif [[ ${line:0:12} == "CSVCOUNT=YES" ]]
    then

    	# SETTING: Turn on the counting of CSV delimiters
    	CSVCOUNT="YES"
    	echo === Counting CSV delimiters is turned on ===  | tee /dev/fd/3

    elif [[ ${line:0:10} == "CSVDELIM=|" ]]
    then
    	# SETTING: Found the switch to delimiter "|"
    	echo === Using CSV delimiter of "|" ===  | tee /dev/fd/3
    	CSVDELIM="|"

    elif [[ ${line:0:10} == "CSVDELIM=," ]]
    then
    	# SETTING: Found the switch to delimiter ","
    	echo === Using CSV delimiter of "," ===  | tee /dev/fd/3
    	CSVDELIM=","

    	elif [[ ${line:0:10} == "CSVDELIM=;" ]]
          then
          	# SETTING: Found the switch to delimiter ","
          	echo === Using CSV delimiter of ";" ===  | tee /dev/fd/3
          	CSVDELIM=";"

    else
        # at this point, the $line contains a source feed to run
        echo   | tee /dev/fd/3
        echo ========================================================  | tee /dev/fd/3
        echo "Processing file: $line at $(date)" | tee /dev/fd/3

        # Add one to the total maps run
        countMapsRun=$((countMapsRun+1))

    	#The name of the map we are testing.
		#removing whitespace from the string
    	line="$(echo "${line}" | tr -d '[:space:]')"

    	# Run the transformer

        SOURCE_NAME="$line"
        SOURCE=$(basename $SOURCE_NAME)                            # source filename and extension
        SOURCE_EXTENSION=".${SOURCE_NAME##*.}"
        SOURCE_FILENAME=$(basename -s $SOURCE_EXTENSION $SOURCE)               # source filename without extension
        SOURCE_FINAL=$SOURCE_LOCATION/$SOURCE
        # echo Source Final:  $SOURCE_FINAL
        OUTPUT_NAME=$OUTPUT/$SOURCE_FILENAME"-OUT"$OUTPUT_EXTENSION     # output location and filename
        PRETTY_NAME=$OUTPUT_NAME".pretty"$OUTPUT_EXTENSION                      # output name for the Pretty Print


        echo Start: ${SOURCE_FILENAME}   | tee /dev/fd/3
    	echo "-------------------------------------------  "  | tee /dev/fd/3
        # copy the source file to the output location
        cp "$SOURCE_FINAL" "$OUTPUT/$SOURCE"

        # create the output file
        touch "$OUTPUT_NAME"

        # Track this file as processed for cleanup
        processedFiles="$processedFiles $OUTPUT_NAME"

        # Transform already done above by TransformExecutor (single JVM for all files).
        # Read the per-file Contivo console log (written to console_logs/ by ContivoEngine)
        # back into strConsoleOutput so all validation checks below work exactly as before.
        strConsoleOutput=$(cat "$CONSOLE_LOG_DIR/${SOURCE_FILENAME}-OUT${OUTPUT_EXTENSION}.log" 2>/dev/null)
        echo -e "$strConsoleOutput" | tidy -xml -iq | tee /dev/fd/3

        # =========================================================
        # Pretty format JSON, XML, CSV, EDI output (if applicable)
        # =========================================================
        if [[ -f "$OUTPUT_NAME" && -s "$OUTPUT_NAME" ]]; then
            case "$OUTPUT_EXTENSION" in
                ".json" | ".JSON")
                    if command -v jq >/dev/null 2>&1; then
                        echo "Pretty-formatting JSON output..." | tee /dev/fd/3
                        jq . "$OUTPUT_NAME" > "${OUTPUT_NAME}.pretty" 2>/dev/null && mv "${OUTPUT_NAME}.pretty" "$OUTPUT_NAME"
                    else
                        echo "Warning: jq not installed — skipping JSON pretty-formatting." | tee /dev/fd/3
                    fi
                    ;;
                ".xml" | ".XML")
                    if command -v xmllint >/dev/null 2>&1; then
                        echo "Pretty-formatting XML output with xmllint..." | tee /dev/fd/3
                        xmllint --format "$OUTPUT_NAME" -o "$OUTPUT_NAME"
                    elif command -v tidy >/dev/null 2>&1; then
                        echo "Pretty-formatting XML output with tidy..." | tee /dev/fd/3
                        tidy -xml -i -q -w 0 "$OUTPUT_NAME" > "${OUTPUT_NAME}.pretty" 2>/dev/null && mv "${OUTPUT_NAME}.pretty" "$OUTPUT_NAME"
                    else
                        echo "Warning: neither xmllint nor tidy installed — skipping XML pretty-formatting." | tee /dev/fd/3
                    fi
                    ;;
            esac
        fi

        # Check output for expected error
        if [[ ! ${#strExpectedErrors[@]} == "0" ]]
        then
          for str in "${strExpectedErrors[@]}"; do
            if echo "${strConsoleOutput}" | grep -iqF "$str"
            then
              ((ExpectedErrorPass=ExpectedErrorPass+1))
              echo "----------------------------------------------  "      | tee /dev/fd/3
              echo "PASS: Expected Error found.  $str"                | tee /dev/fd/3
            else
              ((ExpectedErrorFail=ExpectedErrorFail+1))
              echo "----------------------------------------------  "      | tee /dev/fd/3
              echo "FAIL: Expected Error not found.  $str"                | tee /dev/fd/3
            fi
          done
          echo "----------------------------------------------  "    | tee /dev/fd/3
          unset strExpectedErrors
        else
         # Check that the console hasn't shown an unexpected error or exception
         if ! echo "${strConsoleOutput}" | grep -iqF "MessageCount value=\"0\""
         then
           ((outputExceptionsCount=outputExceptionsCount+1))
           # echo -e $strConsoleOutput  | tee /dev/fd/3
           echo "----------------------------------------------  "      | tee /dev/fd/3
           echo "FAIL: Unexpected Error found."                | tee /dev/fd/3
           echo "----------------------------------------------  "    | tee /dev/fd/3
         fi
        fi

         # Check output for expected results
        if [[ ! ${#strExpectedResults[@]} == "0" ]]
        then
          for result in "${strExpectedResults[@]}"; do
            if grep -Fiq "$result" "$OUTPUT_NAME"
            then
              ((ExpectedResultPass=ExpectedResultPass+1))
              echo "----------------------------------------------  "      | tee /dev/fd/3
              echo "PASS: Expected Result found.  $result"                | tee /dev/fd/3
            else
              ((ExpectedResultFail=ExpectedResultFail+1))
              echo "----------------------------------------------  "      | tee /dev/fd/3
              echo "FAIL: Expected Result not found.  $result"                | tee /dev/fd/3
            fi
          done
          echo "----------------------------------------------  "    | tee /dev/fd/3
          unset strExpectedResults
        fi


        # Check that the console hasn't shown an unexpected error or exception
        # MPC_2023.3.0 MAPS-1995 the exception test skips errors with <exception>
          if echo “${strConsoleOutput}” | grep -iqF “Exception”;
          then
            if echo “${strConsoleOutput}” | grep -iqF “<exception>“  || echo “${strConsoleOutput}” | grep -iqF “Error in XLate” ; then
               echo “Contivo <exception>” | tee /dev/fd/3
            else
              ((outputExceptionsCount=outputExceptionsCount+1))
              echo -e $strConsoleOutput  | tee /dev/fd/3
              echo “----------------------------------------------  ”      | tee /dev/fd/3
              echo “FAIL: Exception Error found.”                | tee /dev/fd/3
              echo “----------------------------------------------  ”    | tee /dev/fd/3
            fi
          fi

       if [[ "$OUTPUT_EXTENSION" == ".edi" ]]; then
         if test -f "$OUTPUT_NAME"; then
          sed "s/[~']/\n/g" "$OUTPUT_NAME" > temp_file && mv temp_file "$OUTPUT_NAME"
         fi
       fi

        # Check all CSV output for correct number of commas; they must all have the same number of commas as the header.
        if [[ "$OUTPUT_EXTENSION" == ".csv" ]] || [[ "$OUTPUT_EXTENSION" == ".CSV" ]] && [[ "$CSVCOUNT" == "YES" ]];
        then
          # Check if the output file exists
          if test -f "$OUTPUT_NAME";then

              # Read the file and compare the number of commas to the previous line.
              HeaderLineCount=0
              rowNumber=1
              while read -r row
              do
                # Count the number of commas in the line
               THIS_COUNT=$(awk -v line="$row" '
               BEGIN {
                   inquotes = 0;
                   count = 0;
                   for (i = 1; i <= length(line); i++) {
                       ch = substr(line, i, 1);
                       if (ch == "\"") {
                           inquotes = !inquotes;
                       } else if (ch == "," && inquotes == 0) {
                           count++;
                       }
                   }
                   print count;
               }')


                # IF this is the first line, set the count
                if [[ "$HeaderLineCount" == 0 ]]
                then
                  HeaderLineCount=$THIS_COUNT
                  echo "----------------------------------------------  "      | tee /dev/fd/3
                  echo "CSV Expecting " $HeaderLineCount " delimiters per row."                | tee /dev/fd/3
                fi

                # validate the same number of columns in the row as the header.
                if [[ ! "$THIS_COUNT" == "$HeaderLineCount" ]]
                then
                	((outputExceptionsCount=outputExceptionsCount+1))
                     echo "----------------------------------------------  "      | tee /dev/fd/3
                     echo "FAIL: CSV row $rowNumber has issue with number of delimiters."                | tee /dev/fd/3
                     echo "Expected delimiters: " $HeaderLineCount                | tee /dev/fd/3
                     echo "Found delimiters: " $THIS_COUNT                | tee /dev/fd/3
                     echo "----------------------------------------------  "    | tee /dev/fd/3
                else
                	 echo "PASS: row $rowNumber delimiters: " $THIS_COUNT               | tee /dev/fd/3
                fi
                ((rowNumber=rowNumber+1))
              done < "$OUTPUT_NAME"
          else
            echo "----------------------------------------------  "      | tee /dev/fd/3
            echo "Output file was not created"               | tee /dev/fd/3
            echo "----------------------------------------------  "    | tee /dev/fd/3
          fi
          echo "CSV Delimiter check completed."      | tee /dev/fd/3
          echo "----------------------------------------------  "      | tee /dev/fd/3
          THIS_COUNT=0
        fi


    # At the point where the output file is generated, after the transformation:


    OUTPUT_NAME=$OUTPUT/$SOURCE_FILENAME"-OUT"$OUTPUT_EXTENSION

    # Check if the output file is empty
    echo "------------------------------------------- "| tee /dev/fd/3
    if [[ -f "$OUTPUT_NAME" ]]; then
        # Check if the output file is empty
        if [[ ! -s "$OUTPUT_NAME" ]]; then
            isFileEmpty=true
            emptyFileCount=$((emptyFileCount + 1))
            echo "EMPTY OUTPUT FILE = $isFileEmpty" | tee /dev/fd/3
        else
            isFileEmpty=false
            echo "EMPTY OUTPUT FILE = $isFileEmpty" | tee /dev/fd/3
        fi
    else
        echo "Output file $OUTPUT_NAME does not exist." | tee /dev/fd/3
    fi
        echo "------------------------------------------- "     | tee /dev/fd/3

   # Here we are checking the encoding format for all the output files
   # Note: To ensure the output files are encoded in UTF-8, it’s important that the input file contains some special characters. These characters must pass through the transformation process and be preserved in the output.
   #       Without special characters or a sufficiently large dataset, the output file may not be recognized as UTF-8 encoded.
          echo "Check Output file encoding format"      | tee /dev/fd/3
          ENCODING=$(file -b --mime-encoding "$OUTPUT_NAME")
          ENCODING_FORMATS=$(echo "$ENCODING" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9-].*//')

          if [[ "$ENCODING_FORMATS" =~ ^(utf-8)$ ]]; then
            echo "$SOURCE_FILENAME"-OUT"$OUTPUT_EXTENSION: is UTF-8 encoded ✅ ✅ " | tee /dev/fd/3
            else
              echo "$SOURCE_FILENAME"-OUT"$OUTPUT_EXTENSION: is NOT UTF-8 encoded (Detected encoding: $ENCODING) ⛔️⛔ " | tee /dev/fd/3
         fi
                      echo "----------------------------------------------  "      | tee /dev/fd/3


# ****************************************************************************************************************************************************************************************

        # Compare the output to a previously validated version of the file, if the folder was provided.

        if [[ ! "$COMPARE_FOLDER" == "" ]]
        then
            echo " "  | tee /dev/fd/3
            echo "-------------------------------------------  "  | tee /dev/fd/3
            echo Comparing the output to the validated file.      | tee /dev/fd/3
            echo "-------------------------------------------  "  | tee /dev/fd/3
            VALIDATED_FILENAME=$COMPARE_FOLDER/$SOURCE_FILENAME"-OUT-VALIDATED"$OUTPUT_EXTENSION
            fileIsFailed="NO"

            # Check if the files exist to compare
            if ! test -f "$OUTPUT_NAME" ;
            then
              fileIsFailed="YES"
              #echo "$OUTPUT_NAME" DOES NOT EXIST  | tee /dev/fd/3

            elif ! test -f "$VALIDATED_FILENAME" ;
            then
              fileIsFailed="YES"
              #echo "$VALIDATED_FILENAME" DOES NOT EXIST  | tee /dev/fd/3

            fi

          # Check if we are skipping lines in the compare
          if [[ ! ${#strSkipLines[@]} == "0" ]]; then
              fileIsFailed="NO"
              while IFS= read -r sourceRow; do
                  rowIsSkipped="NO"

                  for skipKey in "${strSkipLines[@]}"; do
                      if echo "${sourceRow}" | grep -iqF "${skipKey}"; then
                          rowIsSkipped="YES"
                          echo "SKIP Line: $sourceRow" | tee /dev/fd/3
                          break  # Exit loop once a match is found
                      fi
                  done

                  if [[ "${rowIsSkipped}" == "NO" ]]; then
                      if ! grep -qF "$sourceRow" "$OUTPUT_NAME"; then
                          echo "FAIL: Missing line in output: $sourceRow" | tee /dev/fd/3
                          fileIsFailed="YES"
                      fi
                  fi
              done < "${VALIDATED_FILENAME}"

              # Also check that OUTPUT_NAME doesn't have extra lines not in VALIDATED_FILENAME (excluding skipped lines)
              while IFS= read -r outputRow; do
                  rowIsSkipped="NO"
                  for skipKey in "${strSkipLines[@]}"; do
                      if echo "${outputRow}" | grep -iqF "${skipKey}"; then
                          rowIsSkipped="YES"
                          break
                      fi
                  done

                  if [[ "${rowIsSkipped}" == "NO" ]]; then
                      if ! grep -qF "$outputRow" "${VALIDATED_FILENAME}"; then
                          echo "FAIL: Extra line in output: $outputRow" | tee /dev/fd/3
                          fileIsFailed="YES"
                          break
                      fi
                  fi
              done < "${OUTPUT_NAME}"

          # If no lines need to be skipped, do a full diff
          else
              if ! diff -w "${OUTPUT_NAME}" "${VALIDATED_FILENAME}"; then
                  fileIsFailed="YES"
              fi
          fi


            if [[ ! "$fileIsFailed" == "YES" ]]
            then
                ((outputComparePass=outputComparePass+1))
                echo "----------------------------------------------  "      | tee /dev/fd/3
                echo "PASS: The comparison was successful."                  | tee /dev/fd/3
                echo "----------------------------------------------  "      | tee /dev/fd/3
            else
                ((outputCompareErrors=outputCompareErrors+1))
                echo "----------------------------------------------  "      | tee /dev/fd/3
                echo "***"                                                   | tee /dev/fd/3
                echo "FAIL: There are differences from the Validated file."  | tee /dev/fd/3
                echo "***"                                                   | tee /dev/fd/3
                echo "----------------------------------------------  "      | tee /dev/fd/3
            fi

        fi
# ****************************************************************************************************************************************************************************************

        # reset the error check variables
        strConsoleOutput=""

        echo " "  | tee /dev/fd/3
        echo ========================================================   | tee /dev/fd/3
        echo ========================================================   | tee /dev/fd/3
    fi
done < "${LIST}"

echo ========================================================   | tee /dev/fd/3
echo ========================================================   | tee /dev/fd/3
endTime=$(date "+%Y-%m-%d__%H-%M-%S")
echo Suite Name          = $MAP_NAME            | tee /dev/fd/3
echo Start Time          = $timestamp           | tee /dev/fd/3
echo End Time            = $endTime             | tee /dev/fd/3
echo Feed Files run      = $countMapsRun        | tee /dev/fd/3

if [[ ! "$COMPARE_FOLDER" == "" ]]
then
    echo Successful compares = $outputComparePass   | tee /dev/fd/3
    echo Failed compares     = $outputCompareErrors | tee /dev/fd/3
fi

echo " "  | tee /dev/fd/3
echo Tests run: $countMapsRun, Compare Failures: $outputCompareErrors, Unexpected Errors: $outputExceptionsCount,  | tee /dev/fd/3
echo Expected Results Pass: $ExpectedResultPass, Expected Results Fail: $ExpectedResultFail, | tee /dev/fd/3
echo Expected Errors Pass: $ExpectedErrorPass, Expected Errors Fail: $ExpectedErrorFail | tee /dev/fd/3
echo Total number of empty files: $emptyFileCount | tee /dev/fd/3
echo " "  | tee /dev/fd/3

# Clean Up the mess I've made.
# Delete the map file that was copied here earlier.
rm -rf "$MAP_FILE_NAME"
# Delete the temporary console log folder used for validation.
#rm -rf "$CONSOLE_LOG_DIR"


echo ========================================================  | tee /dev/fd/3
echo Finished testing  | tee /dev/fd/3


