import groovy.transform.Field

@Field
def checkoutDone = false
// Helper Functions
def checkoutConfig(fluentbitHost) {
    if (checkoutDone && fileExists("fb/config/server/${fluentbitHost}.json")) {
        return
    }
    checkoutDone = true
    dir("fb") {
        deleteDir()
    }
    checkout([
        $class: 'GitSCM',
        branches: [[name: '*/main']],
        doGenerateSubmoduleConfigurations: false,
        extensions: [
            [$class: 'RelativeTargetDirectory', relativeTargetDir: 'fb'],
            [$class: 'SparseCheckoutPaths',  sparseCheckoutPaths:[[$class:'SparseCheckoutPath', path: "config/server/${fluentbitHost}.json"]]]
        ],
        submoduleCfg: [],
        userRemoteConfigs: [
            [
                credentialsId: 'f1e16323-de75-4eac-a5a0-f1fc733e3621',
                url: 'https://bwa.nrs.gov.bc.ca/int/stash/scm/oneteam/oneteam-nr-funbucks.git'
            ]
        ]
    ])
}

def getHost(fluentbitHost) {
    checkoutConfig(fluentbitHost)
    def props = readJSON file: "fb/config/server/${fluentbitHost}.json"
    return props.address
}

def getFluentBitRelease(fluentbitHost) {
    checkoutConfig(fluentbitHost)
    def baseProps = readJSON file: "fb/config/base.json"
    def props = readJSON file: "fb/config/server/${fluentbitHost}.json"
    return props.fluentBitRelease ? props.fluentBitRelease : baseProps.fluentBitRelease
}

def getHttpProxy(fluentbitHost) {
    checkoutConfig(fluentbitHost)
    def props = readJSON file: "fb/config/server/${fluentbitHost}.json"
    return props.proxy
}

def getLogsProxyDisabled(fluentbitHost) {
    checkoutConfig(fluentbitHost)
    def props = readJSON file: "fb/config/server/${fluentbitHost}.json"
    return props.logsProxyDisabled
}

def getCauseUserId() {
    final hudson.model.Cause$UserIdCause userIdCause = currentBuild.rawBuild.getCause(hudson.model.Cause$UserIdCause);
    final String nameFromUserIdCause = userIdCause != null ? userIdCause.userId : null;
    if (nameFromUserIdCause != null) {
        return nameFromUserIdCause + "@idir";
    } else {
        return 'unknown'
    }
}
return this