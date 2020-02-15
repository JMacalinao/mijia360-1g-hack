# Activate native hack traces
if [ "${MCH_NATIVE_TRACES}" = true ]; then
    export XIAOMI_HACK_NATIVE_TRACES=YES
fi

if [ "${MCH_LANGUAGE_TRACES}" = true ]; then
    export XIAOMI_HACK_LANGUAGE_TRACES_LOGFILE="${MCH_LOGS}/audio.log"
fi

# Let's native hack library be loaded in all forecoming processes
export LD_PRELOAD=${MCH_HOME}/bin/libxiaomihack.so
