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

def putFile(username, password, apiURL, filePath) {
    // @Grab(group='org.codehaus.groovy.modules.http-builder', module='http-builder', version='0.7.1')
    // import groovyx.net.http.RESTClient

    // def client = new RESTClient(apiUrl)
    // client.auth.basic(username, password)

    // def response = client.put(
    //     path: '',
    //     body: new File(filePath),
    //     requestContentType: 'application/octet-stream'
    // )

    // println "Response Code: ${response.status}"
}
return this
