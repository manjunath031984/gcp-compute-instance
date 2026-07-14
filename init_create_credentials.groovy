import jenkins.model.Jenkins
import com.cloudbees.plugins.credentials.CredentialsScope
import com.cloudbees.plugins.credentials.domains.Domain
import com.cloudbees.plugins.credentials.SystemCredentialsProvider
import com.cloudbees.jenkins.plugins.plaincredentials.impl.FileCredentialsImpl
import java.nio.file.Files
import java.nio.file.Paths
import java.nio.charset.StandardCharsets

Jenkins instance = Jenkins.get()
SystemCredentialsProvider provider = instance.getExtensionList(SystemCredentialsProvider.class)[0]
def store = provider.getStore()
Domain domain = Domain.global()

def gcpKeyPath = Paths.get('/var/jenkins_home/gcp-sa-key.json')
String keyContent = null
if (Files.exists(gcpKeyPath)) {
  keyContent = new String(Files.readAllBytes(gcpKeyPath), StandardCharsets.UTF_8)
  println("Loaded key from ${gcpKeyPath}")
} else {
  String envKey = System.getenv('GCP_SA_KEY_JSON')
  if (envKey && envKey.trim()) {
    keyContent = envKey
    println("Loaded key from GCP_SA_KEY_JSON environment variable")
  } else {
    println("No GCP key found at ${gcpKeyPath} and GCP_SA_KEY_JSON is not set; aborting.")
  }
}

if (keyContent) {
  def gcpCredential = new FileCredentialsImpl(
    CredentialsScope.GLOBAL,
    'gcp-sa-key',
    'Google Cloud service account JSON Key',
    'gcp-sa-key.json',
    keyContent
  )

  def existing = store.getCredentials(domain).find { it.id == gcpCredential.id }
  if (existing) {
    store.updateCredentials(domain, existing, gcpCredential)
    println("Updated credential 'gcp-sa-key'")
  } else {
    store.addCredentials(domain, gcpCredential)
    println("Created credential 'gcp-sa-key'")
  }
  provider.save()
} else {
  println("No credential created.")
}