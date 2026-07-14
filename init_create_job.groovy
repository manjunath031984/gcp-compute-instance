// Groovy script to create the Jenkins pipeline job for the Terraform project.
import jenkins.model.*
import hudson.model.*
import org.jenkinsci.plugins.workflow.job.WorkflowJob
import org.jenkinsci.plugins.workflow.cps.CpsScmFlowDefinition
import hudson.plugins.git.GitSCM
import hudson.plugins.git.BranchSpec
import hudson.plugins.git.UserRemoteConfig
import hudson.plugins.git.extensions.impl.*

Jenkins jenkins = Jenkins.get()
String jobName = 'gcp-compute-instance'
String repositoryUrl = 'https://github.com/manjunath031984/gcp-compute-instance'
String branchName = 'gcp-compute-instance'

WorkflowJob job = jenkins.getItem(jobName)
if (job == null) {
  job = new WorkflowJob(jenkins, jobName)
  jenkins.add(job, jobName)
}

job.setDescription('Terraform deployment of Google Compute Engine VM.')
job.setConcurrentBuild(false)
job.setLogRotator(new LogRotator(-1, 5, -1, -1))

GitSCM scm = new GitSCM(
  Collections.singletonList(new UserRemoteConfig(repositoryUrl, null, null, 'github-creds')),
  Collections.singletonList(new BranchSpec(branchName)),
  false,
  Collections.emptyList(),
  null,
  null,
  Collections.emptyList()
)

job.setDefinition(new CpsScmFlowDefinition(scm, 'Jenkinsfile'))
job.save()
