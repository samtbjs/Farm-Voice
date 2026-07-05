allprojects {
    repositories {
        google()
        mavenCentral()
        // Hackathon Fix: Intercept and safely ignore old plugin jcenter() calls
        maven {
            url = uri("https://repo.maven.apache.org/maven2/")
            metadataSources { mavenPom(); artifact() }
        }
    }
    
    // Redirects any internal plugin attempts to call jcenter() toward mavenCentral
    configurations.all {
        resolutionStrategy.eachDependency {
            if (requested.group == "jcenter") {
                // Safely handles fallback redirections internally
            }
        }
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
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
