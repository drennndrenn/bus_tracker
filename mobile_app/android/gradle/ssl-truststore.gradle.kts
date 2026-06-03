// Truststore for HTTPS on Windows (Norton/antivirus SSL inspection).
val userTrustStore = File(System.getProperty("user.home"), ".gradle/windows-truststore.jks")
val projectTrustStore = File(settings.rootDir, "gradle/windows-truststore.jks")
val trustStore = when {
    userTrustStore.exists() -> userTrustStore
    projectTrustStore.exists() -> projectTrustStore
    else -> userTrustStore
}

if (trustStore.exists()) {
    val path = trustStore.absolutePath.replace('\\', '/')
    System.setProperty("javax.net.ssl.trustStore", path)
    System.setProperty("javax.net.ssl.trustStorePassword", "changeit")
    logger.lifecycle("Gradle SSL truststore: $path")
} else {
    logger.warn(
        "Missing SSL truststore at ${trustStore.absolutePath}. " +
            "Run: powershell -ExecutionPolicy Bypass -File android/gradle/sync-truststore.ps1",
    )
}
