# GCP Environment Module

## Overview

This repo demonstrates how one might construct a Terraform module that can be used to provision a GCP environment housing a VPC network and GKE cluster with a secure by default design and following the best practices recommendations of GCP for network and cluster hardening.

The repo contains a `modules/` directory contains the sample module for creating the environment's resources, and a sample project under the `myenv/` directory that instantiates the module and provisions the resources within it in the provided project.

> **IMPORTANT NOTE:** The Terraform configuration demonstrated here assumes you have a GCP project created already and does not create one for you as per the requirements specified in the exercise. Because of this, the default network that is typically created automatically by Google Cloud is unable to be deleted automatically as is typically recommended.

## Getting Started with the Sample Project

To get started creating resources in a GCP environment of your own using the provided `myenv/` sample project, you'll first need to take care of a few pre-requisite steps below.

### Pre-requisites

1. [Create a GCP project in Google Cloud](https://cloud.google.com/resource-manager/docs/creating-managing-projects#creating_a_project)
2. Install the `gcloud` command line tool by following the steps outlined [here](https://cloud.google.com/sdk/gcloud#download_and_install_the). **NOTE:** On MacOS, with [brew](https://brew.sh/) installed you can simply run `brew install --cask google-cloud-sdk`.
3. Configure the `gcloud` CLI tool by first setting the default project using the project ID you retrieved on step 1. You can do so by running the command `gcloud config set project <your_gcp_project_id>`
4. Login to `gcloud` at the terminal using a `gcloud auth login` command
5. Generate application default credentials for `gcloud` by running the command `gcloud auth application default login`
6. Lastly, set the value of the `gcp_project_id` Terraform variable to the project ID for your GCP project by running the following at your terminal `export TF_VAR_gcp_project_id=<your_gcp_project_id>`
7. [Install the Terraform CLI tool](https://developer.hashicorp.com/terraform/install) if you do not have it installed already

> **NOTE:** You can optionally install the tool [tfswitch](https://tfswitch.warrensbox.com/Install/) instead of installing the Terraform CLI tool directly. This tool can make things easier since it will allow you to automatically install the required version for the Terraform configuration you are running against by simply running `tfswitch` from the parent directory of the Terraform project. This is optional for the purposes of this demonstration though.

### Plan/Apply Changes

Once you have taken care of the pre-requisites above, you can proceed to plan/apply the changes from the terminal by first changing directory to the `myenv/` Terraform project folder and running `terraform init`.

You'll then want to run `terraform plan` to see the changes Terraform will make. When you are satisfied that they look correct, you can proceed to apply them to your GCP project by running the `terraform apply` command and confirming the changes. Be aware that this may take some time to complete (~10-15 minutes).

It is important to note at this time that, due to some shortcomings of the GCP terraform provider, you may see an error that indicates that required service API's have not been enabled. This can happen on the first pass of the apply since, although the module enables the requisite API's they can take some time to fully enable. If your apply fails the first time, simply run it again and you should see resources being created as expected.

### Connecting to the Environment's Cluster

By default, the Kubernetes cluster created by the example project should be reachable from your public IP despite the fact that it uses a [private cluster topology](https://cloud.google.com/kubernetes-engine/docs/concepts/private-cluster-concept). This is taken care of by the Terraform configuration fetching your public IP address, and automatically adding it to the cluster's authorized networks.

To reach the cluster, once it has been created, you should only need to ensure that you have first [downloaded and installed the Kubernetes CLI tool `kubectl`](https://kubernetes.io/docs/tasks/tools/#kubectl) and run the requisite `gcloud` command to generate a kube config entry for the new cluster. To do so run the following command:

```shell
gcloud container clusters get-credentials main --region us-central1 --project <your_gcp_project_id>
```

You should now be able to list pods in the cluster by executing a `kubectl get pods --all-namespaces` among other commands :tada:.

### Undoing all Changes

To destroy the resources Terraform created, you can run a `terraform destroy` command from the `myenv/` directory and confirm the changes. Please note, similar to the apply command, deletion may take some time to complete (~10-15 minutes)
