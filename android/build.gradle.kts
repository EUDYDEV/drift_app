import org.gradle.api.tasks.compile.JavaCompile

fun inferAndroidNamespace(project: Project): String {
    val manifestFile = project.file("src/main/AndroidManifest.xml")
    if (manifestFile.exists()) {
        val manifestText = manifestFile.readText()
        val match = Regex("""package\s*=\s*"([^"]+)"""")
            .find(manifestText)
            ?.groupValues
            ?.getOrNull(1)
            ?.trim()
        if (!match.isNullOrEmpty()) {
            return match
        }
    }

    val projectGroup = project.group.toString().trim()
    if (projectGroup.isNotEmpty() && projectGroup != "unspecified") {
        return projectGroup
    }

    return "com.drift.generated.${project.name.replace('-', '_')}"
}

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}

subprojects {
    pluginManager.withPlugin("com.android.library") {
        val androidExtension = extensions.findByName("android") ?: return@withPlugin
        val getNamespace = androidExtension.javaClass.methods.firstOrNull {
            it.name == "getNamespace" && it.parameterCount == 0
        }
        val currentNamespace = getNamespace?.invoke(androidExtension) as? String

        if (currentNamespace.isNullOrBlank()) {
            val setNamespace = androidExtension.javaClass.methods.firstOrNull {
                it.name == "setNamespace" && it.parameterCount == 1
            }
            setNamespace?.invoke(androidExtension, inferAndroidNamespace(project))
        }

        tasks.withType<JavaCompile>().configureEach {
            sourceCompatibility = JavaVersion.VERSION_1_8.toString()
            targetCompatibility = JavaVersion.VERSION_1_8.toString()
        }

        tasks.configureEach {
            val isKotlinCompileTask =
                javaClass.name == "org.jetbrains.kotlin.gradle.tasks.KotlinCompile"
            if (!isKotlinCompileTask) {
                return@configureEach
            }

            val kotlinOptions = javaClass.methods.firstOrNull {
                it.name == "getKotlinOptions" && it.parameterCount == 0
            }?.invoke(this) ?: return@configureEach

            kotlinOptions.javaClass.methods.firstOrNull {
                it.name == "setJvmTarget" && it.parameterCount == 1
            }?.invoke(kotlinOptions, JavaVersion.VERSION_1_8.toString())
        }
    }
}

subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
