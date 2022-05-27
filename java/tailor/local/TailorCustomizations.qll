import com.github.customizations.Customizations

class MyTailorSettings extends Settings::Provider {
  MyTailorSettings(){
    // The priority of these settings. If other settings
    // classes exist, the priority governs which one will
    // take precedence.
    this = 0
  }

  override predicate assign(string key, string value) {
    key = "java.local_sources" and value = "true"
  }
}
