allprojects {
    repositories {
        google()
        mavenCentral()
    }

    // Eklenti modülleri (home_widget, shared_preferences vb.) kendi JVM hedeflerini
    // 1.8 olarak bırakıyor; bağımlılıkları ise JVM 11+ ile derlenmiş olarak geliyor.
    // Tüm modülleri app modülüyle aynı hedefe (17) sabitliyoruz.
    tasks.withType<org.jetbrains.kotlin.gradle.tasks.KotlinJvmCompile>().configureEach {
        compilerOptions {
            jvmTarget.set(org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17)
        }
    }

    // Kotlin 17'ye çıkınca Java tarafı da aynı seviyede olmalı,
    // aksi hâlde AGP "Inconsistent JVM-target compatibility" hatası verir.
    plugins.withId("com.android.library") {
        extensions.configure<com.android.build.gradle.LibraryExtension> {
            compileOptions {
                sourceCompatibility = JavaVersion.VERSION_17
                targetCompatibility = JavaVersion.VERSION_17
            }
        }
    }

    configurations.all {
        resolutionStrategy {
            // 16 KB sayfa boyutu uyumluluğu: eski DataStore sürümlerindeki
            // libdatastore_shared_counter.so, Android 15+ 16 KB cihazlarda çökmeye
            // yol açıyor. Play Console bu yüzden uyarı veriyor.
            force("androidx.datastore:datastore-core:1.2.1")
            force("androidx.datastore:datastore-core-android:1.2.1")
            force("androidx.datastore:datastore-preferences:1.2.1")
            force("androidx.datastore:datastore-preferences-android:1.2.1")
            force("androidx.datastore:datastore:1.2.1")
            force("androidx.datastore:datastore-android:1.2.1")
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
// Eklenti modülleri (ör. home_widget, app_settings) kendi JVM hedefini
// belirtmediği için Kotlin varsayılanı 1.8 / Java 11 ile derleniyor; bu da
// "Cannot inline bytecode built with JVM target 11" ve Java-Kotlin hedef
// uyuşmazlığı hatalarına yol açıyor. Tüm alt modülleri :app ile aynı hedefe sabitle.
subprojects {
    // Java hedefi AGP'nin `android` uzantısından okunuyor ve modülün kendi
    // build.gradle'ı bunu değerlendirme sırasında yazıyor; bu yüzden ayarı
    // değerlendirme sonrasına bırak (bu blok evaluationDependsOn'dan önce gelmeli).
    afterEvaluate {
        (extensions.findByName("android") as? com.android.build.gradle.BaseExtension)
            ?.compileOptions {
                sourceCompatibility = JavaVersion.VERSION_17
                targetCompatibility = JavaVersion.VERSION_17
            }
    }
    tasks.withType<org.jetbrains.kotlin.gradle.tasks.KotlinJvmCompile>().configureEach {
        compilerOptions {
            jvmTarget.set(org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17)
        }
    }
}

subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
