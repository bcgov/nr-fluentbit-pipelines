// Helper Functions
def getHost(fluentbitHost) {
    def props = readJSON file: "fb/config/server/${fluentbitHost}.json"
    return props.address
}

def getFluentBitRelease(fluentbitHost) {
    def baseProps = readJSON file: "fb/config/base.json"
    def props = readJSON file: "fb/config/server/${fluentbitHost}.json"
    return props.fluentBitRelease ? props.fluentBitRelease : baseProps.fluentBitRelease
}

def getHttpProxy(fluentbitHost) {
    def props = readJSON file: "fb/config/server/${fluentbitHost}.json"
    return props.proxy
}

def getLogsProxyDisabled(fluentbitHost) {
    def props = readJSON file: "fb/config/server/${fluentbitHost}.json"
    return props.logsProxyDisabled
}

def getCauseUserId() {
    def userIdCause = currentBuild.getBuildCauses('hudson.model.Cause$UserIdCause');
    final String nameFromUserIdCause = userIdCause != null && userIdCause[0] != null ? userIdCause[0].userId : null;
    if (nameFromUserIdCause != null) {
        return nameFromUserIdCause + "@idir";
    } else {
        return 'unknown'
    }
}

def getServerOS(fluentbitHost) {
    def props = readJSON file: "fb/config/server/${fluentbitHost}.json"
    return props.os
}

def getOSVariant(fluentbitHost) {
    def props = readJSON file: "fb/config/server/${fluentbitHost}.json"
    return props.os_variant
}

def getVaultCdUserField(fluentbitHost) {
    def props = readJSON file: "fb/config/server/${fluentbitHost}.json"
    return props.vault_cd_user_field
}

def getVaultCdPassField(fluentbitHost) {
    def props = readJSON file: "fb/config/server/${fluentbitHost}.json"
    return props.vault_cd_pass_field
}

def getVaultCdPath(fluentbitHost) {
    def props = readJSON file: "fb/config/server/${fluentbitHost}.json"
    return props.vault_cd_path
}
return this
