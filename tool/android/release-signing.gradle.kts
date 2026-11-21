// Release signing, applied on top of the generated android/app/build.gradle.kts.
//
// `android/key.properties` is written from the WARAQ_SIGNING_B64 GitHub secret
// at build time; it never exists in the repository. Without it the default
// template keeps signing release builds with the debug key, so forks still
// build.
import java.io.FileInputStream
import java.util.Properties

val signingPropertiesFile = rootProject.file("key.properties")

if (signingPropertiesFile.exists()) {
    val signingProperties = Properties().apply {
        FileInputStream(signingPropertiesFile).use { load(it) }
    }

    android {
        signingConfigs {
            create("release") {
                storeFile = file(signingProperties.getProperty("storeFile"))
                storeType = signingProperties.getProperty("storeType", "PKCS12")
                storePassword = signingProperties.getProperty("storePassword")
                keyAlias = signingProperties.getProperty("keyAlias")
                keyPassword = signingProperties.getProperty("keyPassword")
                enableV1Signing = true
                enableV2Signing = true
                enableV3Signing = true
            }
        }
        buildTypes {
            getByName("release") {
                signingConfig = signingConfigs.getByName("release")
            }
        }
    }
}
