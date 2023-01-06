#!/bin/bash
#
# $Header: oggcore/install/scripts/oggca.sh /main/29 2020/12/16 23:26:56 jovillag Exp $
#
# oggca.sh
#
# Copyright (c) 2016, 2020, Oracle and/or its affiliates. 
# 

silent="false"
help="false";
for arg in $*
do
    if [ "$arg" = "-silent" ]; then
       silent="true"
    else
      if [ "$arg" = "-h" -o "$arg" = "-help" ]; then
         help="true";
      fi
    fi
    if [ $silent = "true" -a $help = "true" ]; then
       break;
    fi  
done
UNAME="/bin/uname"
XDPYINFO="/usr/bin/xdpyinfo"
if [ ! -f $XDPYINFO ]; then
    case `$UNAME` in
        AIX)
            XDPYINFO="/usr/bin/X11/xdpyinfo"
        ;;
        HP-UX)
            XDPYINFO="/usr/contrib/bin/X11/xdpyinfo"
        ;;
        Linux)
            XDPYINFO="/usr/X11R6/bin/xdpyinfo"
        ;;
        SunOS)
            XDPYINFO="/usr/openwin/bin/xdpyinfo"
        ;;
    esac
    if [ ! -f $XDPYINFO ]; then
        XDPYINFO="/usr/lpp/tcpip/X11R6/Xamples/clients/xdpyinfo"
        if [ ! -f $XDPYINFO ]; then
            XDPYINFO="xdpyinfo"
        fi
    fi
fi
${XDPYINFO} > /dev/null 2>&1
#if xdpyinfo fails and -silent is not passed then error out
if [ $? -ne 0 -a "$silent" = "false" -a "$help" = "false" ]; then
    echo "ERROR: Unable to verify the graphical display setup. This application requires X display. Make sure that xdpyinfo exist under PATH variable."
fi

ORIG_ORACLE_HOME=${ORACLE_HOME};
ORACLE_HOME="";

DIRNAME="/usr/bin/dirname";
DIRLOC="`${DIRNAME} $0`";
if [ "`${UNAME}`" = "SunOS" ] && [ "`${UNAME} -r`" = "5.10" ]; then
  SYMLINKSFOUND="false";
  AUXDIRLOC="${DIRLOC}";
  while [ "${AUXDIRLOC}" != "." ] && [ "${AUXDIRLOC}" != "/" ]; do
    if [ -L "${AUXDIRLOC}" ]; then
      SYMLINKSFOUND="true";
      break;
    fi
    AUXDIRLOC="`${DIRNAME} ${AUXDIRLOC}`";
  done
 
  if [ "${SYMLINKSFOUND}" = "true" ]; then
    case "${DIRLOC}" in
      /*)
        ORACLE_HOME="${DIRLOC}/..";
      ;;
      *)
        CURRENTDIR="`pwd`";
        ORACLE_HOME="${CURRENTDIR}/${DIRLOC}/..";
      ;;
    esac
  else
    cd "${DIRLOC}/..";
    ORACLE_HOME="`pwd -L`";
  fi
else
  cd "${DIRLOC}/..";
  ORACLE_HOME="`pwd -L`";
fi

export ORACLE_HOME;

# Set OGGCA_JAVA_HOME env var needed for backend JAR files
OGGCA_JAVA_HOME=$ORACLE_HOME/jdk
export OGGCA_JAVA_HOME

# Determine temporary directory
TEMPLOC=${TEMP};
if [ "${TEMPLOC}" = "" ]; then
  TEMPLOC=${TMP};
  if [ "${TEMPLOC}" = "" ]; then
    TEMPLOC=${TMPDIR};
    if [ "${TEMPLOC}" = "" ]; then
      TEMPLOC="/tmp";
    fi
  fi
fi

# Create temporary log directory
LOG_DIR_PREFIX="OGGCAConfigActions";
TIMESTAMP=`/bin/date +%Y-%m-%d_%H-%M-%S%p`;
TEMP_LOG_DIR="${TEMPLOC}/${LOG_DIR_PREFIX}${TIMESTAMP}";
/bin/mkdir ${TEMP_LOG_DIR};

# Add timestamp and temporary log directory to the system properties
SYS_PROPS="-Doracle.installer.timestamp=${TIMESTAMP} -Doracle.installer.tempLogDir=${TEMP_LOG_DIR}";

unset module;

# JAR files
INSTALLCOMMONS=installcommons_1.0.0b.jar
INSTCOMMON=instcommon.jar
OGGCA=oggca.jar

# Directory Variables
JRE_DIR=${ORACLE_HOME}/jdk/jre;

# Classpath
INVENTORY_SCRIPTS_JLIB_EXT="${ORACLE_HOME}/inventory/Scripts/ext/jlib";
INSTALLCOMMONS_JAR="${INVENTORY_SCRIPTS_JLIB_EXT}/installcommons_1.0.0b.jar";
INSTCOMMON_JAR="${INVENTORY_SCRIPTS_JLIB_EXT}/instcommon.jar";
INSTCOMMON_18N_JAR="${INVENTORY_SCRIPTS_JLIB_EXT}/instcommon_i18n.jar";
CVU_JAR="${INVENTORY_SCRIPTS_JLIB_EXT}/cvu.jar";
OLAF_JAR="${INVENTORY_SCRIPTS_JLIB_EXT}/olaf2.jar"
OGGCA_JAR="${INVENTORY_SCRIPTS_JLIB_EXT}/oggca.jar";
INSTALL_JARS="${INSTALLCOMMONS_JAR} ${INSTCOMMON_JAR} ${INSTCOMMON_18N_JAR}  ${CVU_JAR} ${OLAF_JAR} ${OGGCA_JAR}";

OGG_JLIB="${ORACLE_HOME}/jlib";
OGG_VERSION4J="${OGG_JLIB}/version4j.jar";
OGG_JARS="${OGG_VERSION4J}";

OUI_JLIB="${ORACLE_HOME}/oui/jlib";
JEWT4_JAR="${OUI_JLIB}/jewt4.jar";
SRVM_JAR="${OUI_JLIB}/srvm.jar";
OHJ_JAR="${OUI_JLIB}/ohj.jar";
HELP_SHARE_JAR="${OUI_JLIB}/help-share.jar";
ORACHECKPOINT_JAR="${OUI_JLIB}/OraCheckPoint.jar";
ORAINSTALLER_JAR="${OUI_JLIB}/OraInstaller.jar";
ORAINSTALLER_NET_JAR="${OUI_JLIB}/OraInstallerNet.jar"
SHARE_JAR="${OUI_JLIB}/share.jar";
XML_JAR="${OUI_JLIB}/xml.jar";
XMLPARSERV2_JAR="${OUI_JLIB}/xmlparserv2.jar";
ICE_JAR1="${OUI_JLIB}/oracle_ice.jar"
ICE_JAR2="${OUI_JLIB}/ohj.jar"

FRAMEWORK_HELP_JARS=""
for entry in `ls ${OUI_JLIB}/InstHelp*`; do
    FRAMEWORK_HELP_JARS="${FRAMEWORK_HELP_JARS}:${entry}"
done

OUI_JARS="${JEWT4_JAR} ${SRVM_JAR} ${OHJ_JAR} ${HELP_SHARE_JAR} ${ORACHECKPOINT_JAR} ${ORAINSTALLER_JAR} ${ORAINSTALLER_NET_JAR} ${SHARE_JAR} ${XML_JAR} ${XMLPARSERV2_JAR} ${FRAMEWORK_HELP_JARS} ${ICE_JAR1} ${ICE_JAR2}";

OGGSCA_JLIB="${ORACLE_HOME}/lib/utl/install";
OGGSCA_JAR="${OGGSCA_JLIB}/oggsca.jar";

OGG_CLASSPATH="";
ALL_JARS="${INSTALL_JARS} ${OUI_JARS} ${OGG_JARS} ${OGGSCA_JAR}";
for JAR_FILE in `echo ${ALL_JARS}`; do
  OGG_CLASSPATH="${OGG_CLASSPATH}:${JAR_FILE}";
done

#call platform_common script
PLATFORM=`uname`
ARCH="";
PLATFORM_DIRECTORY_NAME="";

case $PLATFORM in
HP-UX)

    ARCH=`uname -m`;

    if [[ $ARCH = "ia64" ]]; then
      PLATFORM_DIRECTORY_NAME="hpia64";
    else
      PLATFORM_DIRECTORY_NAME="hpunix";
    fi
    ;;
AIX)

    PLATFORM_DIRECTORY_NAME="aix";
    ;;
Linux)

    ARCH=`uname -m`;

    if [[ $ARCH = "x86_64" ]]; then
      PLATFORM_DIRECTORY_NAME="linux64";
    elif [[ $ARCH = "ppc64" ]]; then
      PLATFORM_DIRECTORY_NAME="linuxppc64";
    elif [[ $ARCH = "s390x" ]]; then
      PLATFORM_DIRECTORY_NAME="linuxS390";
      # zLinux OUI shiphome ships the IBM JRE as well, set the same JRE flags as AIX
      AIX_JCE_LOC=${OGGSCA_JLIB}/JCE8_IBM
      AIX_JCE_FLAGS="-Djava.security.debug=ibmjcefw"
    else
      PLATFORM_DIRECTORY_NAME="linux";
    fi

    ;;
SunOS)

    ARCH=`uname -p`;

    if [ $ARCH = "sparc" ]; then
      PLATFORM_DIRECTORY_NAME="solaris";
    else
      PLATFORM_DIRECTORY_NAME="intelsolaris";
    fi

    ;;
MSWin)

    PLATFORM_DIRECTORY_NAME="win64";
    ;;
esac

OUI_LIBRARY_LOCATION=${ORACLE_HOME}/oui/lib/$PLATFORM_DIRECTORY_NAME;

if [ "${PLATFORM}" != "Linux" ]; then
    OGG_CLASSPATH=${OGG_CLASSPATH}:1;
else
    OGG_CLASSPATH=${OGG_CLASSPATH:1};
fi

case $PLATFORM in
Linux)
       
    if [  "`uname -m`" = "ia64" ] ; then
        LD_LIBRARY_PATH=${OUI_LIBRARY_LOCATION}:${ORACLE_HOME}/install/lib${LD_LIBRARY_PATH:+:${LD_LIBRARY_PATH}}
    else
        LD_LIBRARY_PATH=${ORACLE_HOME}/install/lib:${OUI_LIBRARY_LOCATION}:$LD_LIBRARY_PATH
    fi
    export LD_LIBRARY_PATH
    ORIG_LIBRARY_PATH=${LD_LIBRARY_PATH};
   
    ;;
HP-UX)
    
    SHLIB_PATH=${ORACLE_HOME}/install/lib:${OUI_LIBRARY_LOCATION}:$SHLIB_PATH
    export SHLIB_PATH
    LD_LIBRARY_PATH=${ORACLE_HOME}/install/lib:${OUI_LIBRARY_LOCATION}:$LD_LIBRARY_PATH
    export LD_LIBRARY_PATH
    ORIG_LIBRARY_PATH=${LD_LIBRARY_PATH};

    # /bin/file uses ELF-64 for specifying 64-bitness for hpux parisc and itanium
# else it is specified as ELF-32, PARISC1.1 etc
    if [ `/bin/file ${ORIG_ORACLE_HOME}/lib/nautab.o | /bin/awk '{print $2}'` = "ELF-64" ];
    then
        JAVA64FLAG="-d64"
        export JAVA64FLAG
    fi
    ;;
AIX)
   
    LIBPATH=${ORACLE_HOME}/install/lib:${OUI_LIBRARY_LOCATION}:$LIBPATH
    export LIBPATH
    ORIG_LIBRARY_PATH=${LIBPATH};

    AIX_JCE_LOC=${OGGSCA_JLIB}/JCE8_IBM
    AIX_JCE_FLAGS="-Djava.security.debug=ibmjcefw"

    ;;
SunOS)
     LD_LIBRARY_PATH=${ORACLE_HOME}/install/lib:${OUI_LIBRARY_LOCATION}:$LD_LIBRARY_PATH
     export LD_LIBRARY_PATH
     ORIG_LIBRARY_PATH=${LD_LIBRARY_PATH};

     if [ `/bin/file ${ORIG_ORACLE_HOME}/lib/nautab.o | /bin/awk '{print substr($3,0,2)}'` != "32" ];
     then
        LD_LIBRARY_PATH_64=${ORACLE_HOME}/install/lib:${OUI_LIBRARY_LOCATION}:$LD_LIBRARY_PATH_64
        export LD_LIBRARY_PATH_64
        ORIG_LIBRARY_PATH=${LD_LIBRARY_PATH_64};

        JAVA64FLAG="-d64"
        export JAVA64FLAG
     fi
           
     ;;
esac

JRE_OPTIONS="${JAVA64FLAG} -DORIG_ORACLE_HOME=${ORIG_ORACLE_HOME} -DORACLE_HOME=${ORACLE_HOME} -DOGGCA_JAVA_HOME=${OGGCA_JAVA_HOME} -DOGGCA_PLATFORM_DIRECTORY_NAME=${PLATFORM_DIRECTORY_NAME} -DORIG_LIBRARY_PATH=${ORIG_LIBRARY_PATH} -Dhttps.protocols=TLSv1.1,TLSv1.2 -Djdk.tls.client.protocols=TLSv1.1,TLSv1.2 -XX:-OmitStackTraceInFastThrow -XX:CompileCommand=quiet -XX:CompileCommand=exclude,javax/swing/text/GlyphView,getBreakSpot"

RUID=`/usr/bin/id|/bin/awk -F= '{print $2}'|/bin/awk -F\( '{print $1}'` 

# Check if user is non-root
if [ "$RUID" = "0" ]; then
        echo "OGGCA cannot be run as root."
        exit 1;
fi

# make sure others can not read/write any files created
umask 27

# The environment variable $JAVA_HOME cannot be set during the installation
unset JAVA_HOME

# Basic error checking
case ${ORACLE_HOME} in
    "") echo "*** ORACLE_HOME Not Set!"
        echo "    Set and export ORACLE_HOME, then re-run"
        echo "    ORACLE_HOME points to the main directory that"
        echo "    contains all Oracle products."
        exit 1;;
esac


# Set Classpath for OGG Configuration Assistant
CLASSPATH="${INSTALL_CLASSPATH}:${EXT_CLASSPATH}:${OGG_CLASSPATH}";

JVM_OPTIONS=""
ARGUMENTS=""
for j in $*
do
   index=`expr match "$j" "-J-"`
   if [ $index = 3 ]; then
      j=`echo $j | sed 's/-J//'`
      JVM_OPTIONS="${JVM_OPTIONS} $j"
   else
      ARGUMENTS="${ARGUMENTS} $j"
   fi
done

JRE_OPTIONS="${JRE_OPTIONS} -DDISPLAY=${DISPLAY} -mx512m"

# Check for custom JRE
USE_CUSTOM_JRE="false"

for k in $*
do
   if [ $USE_CUSTOM_JRE = "true" ]; then
      JRE_DIR=$k
      USE_CUSTOM_JRE="false"
   elif [ $k = "-jreLoc" ]; then
      USE_CUSTOM_JRE="true"
   fi
done

###################################Remote debugging############################
#To enable Remote debugging
# DEBUG_ASSISTANTS="true"
# DEBUG_PORT="<desired port>"

DEFAULT_DEBUG_PORT=8001

if [ "$DEBUG_ASSISTANTS" = "true" ]; then
        if [ "$DEBUG_PORT" = "" ]; then
                #If port not specified then assign default port
                DEBUG_PORT=$DEFAULT_DEBUG_PORT
        fi
        DEBUG_STRING="-Xdebug -Xrunjdwp:transport=dt_socket,address=$DEBUG_PORT,server=y,suspend=y -client"
         echo "Remote Debugging is enabled in port $DEBUG_PORT"
else
        DEBUG_STRING=""
fi
##############################################################################
# Run OGGCA
exec $JRE_DIR/bin/java  $JRE_OPTIONS  $DEBUG_STRING $JVM_OPTIONS ${AIX_JCE_FLAGS} ${SYS_PROPS} -classpath $CLASSPATH oracle.install.ivw.oggca.driver.OGGCA "$@"
