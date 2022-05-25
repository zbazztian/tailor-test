import com.github.customizations.Customizations
import com.github.customizations.Settings

class MyTailorSettings extends Settings::Provider {
  MyTailorSettings(){
    this = 0
  }

  override predicate assign(string key, string value) {
    key = "java.local_sources" and value = "true"
  }
}

from RemoteFlowSource rfs
select rfs
