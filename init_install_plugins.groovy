// Groovy script to install required Jenkins plugins if they are not already installed.
import jenkins.model.*
import java.util.logging.Logger

Logger logger = Logger.getLogger('plugin-installer')

List<String> requiredPlugins = [
  'pipeline',
  'pipeline-stage-view',
  'git',
  'github',
  'github-branch-source',
  'git-client',
  'credentials',
  'credentials-binding',
  'ssh-credentials',
  'ssh-agent',
  'google-oauth-credentials',
  'google-cloud-storage',
  'google-compute-engine',
  'google-kubernetes-engine',
  'docker-plugin',
  'docker-workflow',
  'workspace-cleanup',
  'blueocean',
  'ansicolor',
  'timestamper',
  'pipeline-utility-steps',
  'config-file-provider',
  'job-dsl',
  'role-strategy',
  'matrix-auth'
]

Jenkins instance = Jenkins.get()

def pluginManager = instance.getPluginManager()
def updateCenter = instance.getUpdateCenter()

requiredPlugins.each { pluginId ->
  if (!pluginManager.getPlugin(pluginId)) {
    logger.info("Installing missing plugin: ${pluginId}")
    def plugin = updateCenter.getPlugin(pluginId)
    if (plugin) {
      plugin.deploy()
    } else {
      logger.warning("Plugin not found in update center: ${pluginId}")
    }
  } else {
    logger.info("Plugin already installed: ${pluginId}")
  }
}

instance.save()
