rootProject.layout.buildDirectory = file("../build")

subprojects {
    evaluationDependsOn(":app")
}

subprojects {
    project.layout.buildDirectory = rootProject.layout.buildDirectory.dir(project.name)
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
