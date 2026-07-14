// Groovy script to create Jenkins credentials for GCP and GitHub.
import jenkins.model.Jenkins
import com.cloudbees.plugins.credentials.CredentialsScope
import com.cloudbees.plugins.credentials.CredentialsProvider
import com.cloudbees.plugins.credentials.domains.Domain
import com.cloudbees.plugins.credentials.impl.UsernamePasswordCredentialsImpl
import com.cloudbees.jenkins.plugins.plaincredentials.impl.FileCredentialsImpl
import com.cloudbees.jenkins.plugins.sshcredentials.impl.BasicSSHUserPrivateKey
import com.cloudbees.jenkins.plugins.sshcredentials.impl.BasicSSHUserPrivateKey.DirectEntryPrivateKeySource
import com.cloudbees.plugins.credentials.SystemCredentialsProvider
import hudson.security.ACL
import java.nio.file.Files
import java.nio.file.Paths
import java.nio.file.Path

Jenkins instance = Jenkins.get()
SystemCredentialsProvider provider = instance.getExtensionList(SystemCredentialsProvider.class)[0]
def store = provider.getStore()
Domain domain = Domain.global()

Path gcpKeyPath = Paths.get('/var/jenkins_home/gcp-sa-key.json')
String gcpKeyContent = null
if (Files.exists(gcpKeyPath)) {
  gcpKeyContent = new String(Files.readAllBytes(gcpKeyPath), 'UTF-8')
} else {
  // Fallback: allow supplying the service account JSON via environment variable
  String envKey = System.getenv('GCP_SA_KEY_JSON')
  if (envKey != null && envKey.trim().length() > 0) {
    gcpKeyContent = envKey
    println("Loaded GCP service account key from GCP_SA_KEY_JSON environment variable")
  } else {
    println("WARNING: GCP service account key not found at ${gcpKeyPath} and GCP_SA_KEY_JSON is not set. Skipping GCP credential creation.")
  }
}

if (gcpKeyContent) {
  FileCredentialsImpl gcpCredential = new FileCredentialsImpl(
    CredentialsScope.GLOBAL,
    'gcp-sa-key',
    'Google Cloud Service Account JSON Key',
    'gcp-sa-key.json',
    gcpKeyContent
  )

  addOrUpdateCredential(gcpCredential)
} else {
  println('Skipping creation of GCP file credential: no key material available.')
}

UsernamePasswordCredentialsImpl githubCredentials = new UsernamePasswordCredentialsImpl(
  CredentialsScope.GLOBAL,
  'github-creds',
  'GitHub Credentials',
  System.getenv('GITHUB_USERNAME') ?: 'REPLACE_WITH_GITHUB_USERNAME',
  System.getenv('GITHUB_PASSWORD') ?: 'REPLACE_WITH_GITHUB_PASSWORD'
)

BasicSSHUserPrivateKey githubSshCredentials = new BasicSSHUserPrivateKey(
  CredentialsScope.GLOBAL,
  'github-ssh',
  'git',
  new DirectEntryPrivateKeySource(System.getenv('GITHUB_SSH_PRIVATE_KEY') ?: '''-----BEGIN OPENSSH PRIVATE KEY-----
REPLACE_WITH_PRIVATE_KEY
-----END OPENSSH PRIVATE KEY-----'''),
  '',
  'GitHub SSH credentials'
)

def addOrUpdateCredential(credential) {
  def existing = store.getCredentials(domain).find { it.id == credential.id }
  if (existing) {
    store.updateCredentials(domain, existing, credential)
  } else {
    store.addCredentials(domain, credential)
  }
}

addOrUpdateCredential(gcpCredential)
addOrUpdateCredential(githubCredentials)
addOrUpdateCredential(githubSshCredentials)

provider.save()
