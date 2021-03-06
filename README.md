JupyterHub-Fastbook
==============================

<img src="https://images-na.ssl-images-amazon.com/images/I/516YvsJCS9L._SX379_BO1,204,203,200_.jpg" height="140"> ➕
<img src="https://jupyter.org/assets/main-logo.svg" width="110"> ➕
<img src="https://www.docker.com/sites/default/files/d8/2019-07/Moby-logo.png" height="140">

Taking [fast.ai's](https://www.fast.ai/) [Practical Deep Learning for Coders course](https://course.fast.ai/) [notebooks repository](https://github.com/fastai/fastbook) and putting it into a [Docker](https://www.docker.com/) container.
------------

Pre-loaded with [Jupyter](https://jupyter.org/) and all the required dependencies (installed in a [`conda`](https://www.anaconda.com/) environment) for an all-in-one automated, repeatable deployment without any setup.


➕ <img src="https://jupyter.org/assets/hublogo.svg" width="200">


For those that lead a team, scale out by deploying the environment to multiple users at once via [JupyterHub](https://jupyter.org/hub), hosted on your own [Kubernetes](https://kubernetes.io/) cluster.
------------
This is a standalone deployment which can be extended or used as-is for your own multi-user Jupyter workflows.

*See the [Further Reading](#further-reading) section for more details on the above mentioned technologies.

------------

Table of Contents
<!-- toc -->

- [Quickstart](#quickstart)
  * [Running The Docker Image Locally](#running-the-docker-image-locally)
  * [Deploying JupyterHub to Your Kubernetes Cluster](#deploying-jupyterhub-to-your-kubernetes-cluster)
- [Overview](#overview)
  * [Benefits](#benefits)
  * [Example Uses](#example-uses)
  * [Why This Project?](#why-this-project)
  * [Technical Notes](#technical-notes)
- [Advanced Usage](#advanced-usage)
  * [Makefile Overview](#makefile-overview)
  * [Build and Push Your Own Docker Image](#build-and-push-your-own-docker-image)
  * [Enabling GitHub Oauth](#enabling-github-oauth2)
- [JupyterHub Kubernetes Deployment Explanation](#jupyterhub-kubernetes-deployment-explanation)
  * [Setup](#setup)
  * [Deployment](#deployment)
    + [Generate a JupyterHub configuration file](#generate-a-jupyterhub-configuration-file)
    + [Deploy JupyterHub to your Kubernetes cluster](#deploy-jupyterhub-to-your-kubernetes-cluster)
    + [A note on built-in image tag logic](#a-note-on-built-in-image-tag-logic)
- [Further Reading](#further-reading)
  * [`fast.ai`](#fastai-a-non-profit-research-group-focused-on-deep-learning-and-artificial-intelligence)
  * [`Jupyter Notebook`](#jupyter-notebook-an-open-source-web-application-that-allows-you-to-create-and-share-documents-that-contain-live-code-equations-visualizations-and-narrative-text)
  * [`JupyterHub`](#jupyterhub-a-multi-user-version-of-the-notebook-designed-for-companies-classrooms-and-research-labs)
  * [`Anaconda`](#anaconda-conda-for-short-a-free-and-open-source-distribution-of-the-python-and-r-programming-languages-for-scientific-computing-that-aims-to-simplify-package-management-and-deployment)
  * [`Docker`](#docker-a-set-of-platform-as-a-service-products-that-use-os-level-virtualization-to-deliver-software-in-packages-called-containers)
  * [`Kubernetes`](#kubernetes-an-open-source-system-for-automating-deployment-scaling-and-management-of-containerized-applications)

<!-- tocstop -->

Quickstart
==============================


<a name="docker-container-deployment">Running The Docker Image Locally</a>
------------


```shell script
# Note: the `latest` tag is used here for expediency. When possible, you should
# pin your version by specifying an exact Docker image tag,
# e.g., `TAG=v20201007-7890c25`
TAG=latest
docker run -p 8888:8888 teozosa/jupyterhub-fastbook:${TAG}
```

###### Note: This will automatically pull the image from Docker Hub if it is not already present on your machine; it is fairly large (~5 GB), so this may take awhile.

<img src=".github/docker_run_jupyter_address.png" width="946">

Follow the directions on-screen to log in to your local Jupyter notebook environment! 🎉

Note: the first URL may not work. If that happens, try the URL beginning with `http://127.0.0.1`

### **Important**: When running the fast.ai notebooks, be sure to switch the notebook kernel to the `fastbook` environment

<img src=".github/jupyter_notebook_fastbook_kernel_selection.png" width="600">

Deploying JupyterHub to Your Kubernetes Cluster
------------


###### Please see the [unabridged Kubernetes deployment section](#jupyterhub-kubernetes-deployment-overview) for an in-depth explanations of the below steps

From the root of your repository, on the command line, run:

 ```shell script
# Generate and store secret token for later usage
echo "export PROXY_SECRET=$(openssl rand -hex 32)" > .env

# Install Helm
curl https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3 | bash
# Verify Helm
helm list
# Add JupyterHub Helm charts
helm repo add jupyterhub https://jupyterhub.github.io/helm-chart/
helm repo update

# Deploy the JupyterHub service mesh onto your Kubernetes cluster
# using the secret token you generated in step 1.
# Note: the `latest` tag is used here for expediency. When possible, you should
# pin your version by specifying an exact Docker image tag,
# e.g., `TAG=v20201007-7890c25`
make deploy TAG=latest
```

#### You should then be greeted by a Helm messages similar to the below

<img src=".github/helm_success.png" width="763">

#### Check that all the pods are running

```shell script
kubectl --namespace jhub get all
```
<img src=".github/jupyterhub_pods_running.png" width="802">

#### Get the JupyterHub server address

```shell script
JUPYTERHUB_IP=$(kubectl --namespace jhub get service proxy-public -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
echo $JUPYTERHUB_IP
```

#### Type the IP from the previous step into your browser, login<sup>[*](#default-authenticator)</sup>, and you should now be in the JupyterLab UI! 🎉

<img src=".github/jupyterlab_ui_homepage.png" width="400">

<sup><a name="default-authenticator">*</a> JupyterHub is running with a default _dummy_ authenticator so entering any username and password combination will let you enter the hub.</sup>

### **Important**: When running the fast.ai notebooks, be sure to switch the notebook kernel to the `fastbook` environment

<img src=".github/jupyterlab_kernel_selection.png" width="400">

\
<img src=".github/jupyterlab_fastbook_kernel_selection.png" width="400">

------------

Overview
==============================

Benefits
------------


1. ##### Immediately get started on the [fast.ai Practical Deep Learning for Coders course](https://course.fast.ai/) without any extra setup via the `JupyterHub-Fastbook` Docker image<sup>[[1]](#jupyter-minimal-notebook)</sup>
2. ##### Deploy JupyterHub (with the `JupyterHub-Fastbook` Docker image):
    - To your Kubernetes cluster<sup>[[0]](#microk8s)</sup> via the [official Helm chart](https://jupyterhub.github.io/helm-chart).
    - [_Optional_] Using [Github Oauth](https://docs.github.com/en/free-pro-team@latest/developers/apps/building-oauth-apps) for user authentication
3. ##### Roll your own JupyterHub deployment:
    - Use the deployment as-is; you get a fully-featured JupyterHub deployment that just so happens to have [fast.ai's](https://www.fast.ai/) [Practical Deep Learning for Coders course](https://course.fast.ai/) dependencies pre-loaded.
    - Extend the configuration and deployment system in this project for your particular needs.
    - Build and push your own `JupyterHub-Fastbook` images to your own Docker registry.

<sup><a name="microk8s">[0]</a> Tested with [Microk8s](https://microk8s.io/) on Ubuntu 18.04.4.</sup>

<sup><a name="jupyter-minimal-notebook">[1]</a> Based on the official [jupyter/minimal-notebook](https://jupyter-docker-stacks.readthedocs.io/en/latest/using/selecting.html#jupyter-minimal-notebook) from [Jupyter Docker Stacks](https://jupyter-docker-stacks.readthedocs.io/en/latest/index.html). This means you get the same features of a default JupyterHub deployment with the added functionality of an isolated `fastbook` `conda` environment.</sup>

Example Uses
------------


Use `JupyterHub-Fastbook` in conjunction with the [fast.ai Practical Deep Learning for Coders course](https://course.fast.ai/):
1. To go through the course on your own
with virtually no setup by running the [`JupyterHub-Fastbook` Docker image locally](#docker-container-deployment).
2. As the basis for a study group
3. To onboard new junior members of your organization's AI/ML team

Or anything else you can think of!

Why This Project?
------------


The purpose of this project was to reduce any initial technical barriers to entry for
the [fast.ai Practical Deep Learning for Coders course](https://course.fast.ai/)
 by automating the setup, configuration, and maintenance of a compatible
 programming environment, scaling that experience to both individuals and groups of individuals.

In the same spirit as the course, if you don't need a PhD to build AI
applications, you also shouldn't need to be a DevOps expert to get started
 with the course.

We've done all the work for you. All you need to do is dive in and get started!  

Technical Notes
------------

1. When running the Docker image as a container in single-user mode, outside of Kubernetes,
you will interact directly with the Jupyter Notebook interface
(see: [Quickstart: Running the Docker image locally](#docker-container-deployment)).

2. The JupyterHub Kubernetes deployment portion of this project is based on
the official [Zero to JupyterHub with Kubernetes guide ](https://zero-to-jupyterhub.readthedocs.io/en/latest/)
and assumes you have your own Kubernetes cluster already set up. If not and you are just starting out,
[Minikube](https://kubernetes.io/docs/setup/learning-environment/minikube/) is great for local development
and [Microk8s](https://microk8s.io/) works well for single-node clusters.


Advanced Usage
==============================


Makefile Overview  
------------


##### Available rules

    build               Build Docker container
    config.yaml         Generate JupyterHub Helm chart configuration file
    deploy              Deploy JupyterHub to your Kubernetes cluster
    push                Push image to Docker Hub container registry


Tip: invoking `make` without any arguments will display auto-generated
documentation similar to the above.  

Build and Push Your Own Docker Image
------------


In addition to deployment, the `makefile` contains facilities to build and push
Docker images to your own repository. Simply edit the appropriate fields in `Makefile`
and invoke `make` with one of: `build`, `push`.


Enabling GitHub Oauth<sup>[[2]](#jupyterhub-documentation-oauth2)</sup>
------------


#### Determine your JupyterHub host address (the address you use in your browser to access JupyterHub) and add it to your `.env` file
```shell script
JUPYTERHUB_IP=$(kubectl --namespace jhub get service proxy-public -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
echo "export JUPYTERHUB_IP=${JUPYTERHUB_IP}" >> .env
```

#### Generate your GitHub Oauth credentials and add them to your `.env` file
Follow this tutorial: [GitHub documentation: Building OAuth Apps - Creating an OAuth App](https://docs.github.com/en/free-pro-team@latest/developers/apps/creating-an-oauth-app), then:

```shell script
GITHUB_CLIENT_ID=$YOUR_GITHUB_CLIENT_ID
GITHUB_CLIENT_SECRET=$YOUR_GITHUB_CLIENT_SECRET
echo "export GITHUB_CLIENT_ID=${GITHUB_CLIENT_ID}" >> .env
echo "export GITHUB_CLIENT_SECRET=${GITHUB_CLIENT_SECRET}" >> .env
```

#### Redeploy your JupyterHub instance

 ```shell script
# Note: the `latest` tag is used here for expediency. When possible, you should
# pin your version by specifying an exact Docker image tag,
# e.g., `TAG=v20201007-7890c25`
make deploy TAG=latest
```

Now, the first time a user logs in to your JupyterHub instance,
they will be greeted by a screen that looks like this:

<img src=".github/github_oauth_confirmation.png" width="400">

Once they click "Authorize", users will now automatically be authenticated via
GitHub's Oauth whenever they log in.

<sup> <a name="jupyterhub-documentation-oauth2">[2] see: [JupyterHub documentation: Authenticating with OAuth2 - GitHub](https://zero-to-jupyterhub.readthedocs.io/en/latest/administrator/authentication.html#github) </a></sup>

------------

<a name="jupyterhub-kubernetes-deployment-overview">JupyterHub Kubernetes Deployment Explanation</a>
==============================


Setup
------------


source: [JupyterHub documentation: Setting up JupyterHub](https://zero-to-jupyterhub.readthedocs.io/en/latest/setup-jupyterhub/setup-jupyterhub.html#setting-up-jupyterhub)


Note: commands in this section should be run on the command line from the root of your repository.

#### Generate a secret token for your JupyterHub deployment and place it in your local `.env` file

 ```shell script
 echo "export PROXY_SECRET=$(openssl rand -hex 32)" > .env
```
##### DANGER! **DO NOT VERSION CONTROL THIS FILE!**

If you need to store these values in version control, consider using something
like [SOPS](https://github.com/mozilla/sops).

#### Install Helm

source: [JupyterHub documentation: Setting up Helm](https://zero-to-jupyterhub.readthedocs.io/en/latest/setup-jupyterhub/setup-helm.html#setting-up-helm)

* Download and install
```shell script
curl https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3 | bash
```
* Verify installation and add JupyterHub Helm charts:

```shell script
# Verify Helm
helm list
# Add JupyterHub Helm charts
helm repo add jupyterhub https://jupyterhub.github.io/helm-chart/
helm repo update
```


Deployment
------------


source: [JupyterHub documentation: Setting up JupyterHub](https://zero-to-jupyterhub.readthedocs.io/en/latest/setup-jupyterhub/setup-jupyterhub.html)

### Generate a JupyterHub configuration file<sup>[*](#config-auto-regenerated-on-deploy)</sup>

```shell script
make config.yaml
```
This will create a `config.yaml` by populating fields of `config.TEMPLATE.yaml`
with the pre-set deployment variables<sup>[†](#override-docker-env-var)</sup> and values specified in your `.env` file.

<sup><a name="config-auto-regenerated-on-deploy">*</a>
Anything generated here will be overwritten by the following deployment
step with the most recent values, but this step is here for completion's sake.</sup>


### Deploy JupyterHub to your Kubernetes cluster

Once you've verified `config.yaml` contains the correct information,
on the command line, run:

```shell script
# Note: the `latest` tag is used here for expediency. When possible, you should
# pin your version by specifying an exact Docker image tag,
# e.g., `TAG=v20201007-7890c25`
make deploy TAG=latest
```

This will deploy the JupyterHub instance to your cluster via the
[official Helm chart](https://zero-to-jupyterhub.readthedocs.io/en/latest/setup-jupyterhub/setup-jupyterhub.html#install-jupyterhub),
parametrized by pre-set deployment variables<sup>[†](#override-docker-env-var)</sup> and
the `config.yaml` file you generated in the previous step.


<sup><a name="override-docker-env-var">†</a> to override a pre-set deployment variable, simply edit the appropriate value in `Makefile`.</sup>

### A note on built-in image tag logic

The `makefile` defaults to strong versioning of image tags (derived from [Google's Kubeflow](https://www.kubeflow.org/) [Central Dashboard Makefile](https://github.com/kubeflow/kubeflow/blob/305393b0a543feeec6c1dc866ce2637ef1985a74/components/centraldashboard/Makefile)) for unambiguous container image provenance.

Unless you are pushing and pulling to your own registry, you *MUST* override
the generated tag with your desired tag when deploying to your own cluster.

------------

<a name="further-reading">Further Reading</a>
==============================


### [`fast.ai`](https://www.fast.ai/): A non-profit research group focused on deep learning and artificial intelligence.
-  [`fastai`](https://github.com/fastai/fastai): The free, open-source software library from fast.ai that simplifies training fast and accurate neural nets using modern best practices.

&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;
<img src="https://images-na.ssl-images-amazon.com/images/I/516YvsJCS9L._SX379_BO1,204,203,200_.jpg" height="140">

- **Practical Deep Learning for Coders**: the creators of `fastai` show you how to train a model on a wide range of tasks using `fastai` and PyTorch.
You’ll also dive progressively further into deep learning theory to gain a complete understanding of the algorithms behind the scenes.

    - [(Course)](https://course.fast.ai/)
    - [(Book)](https://www.amazon.com/Deep-Learning-Coders-fastai-PyTorch/dp/1492045527)
    - [(Notebook Repository)](https://github.com/fastai/fastbook)

\
\
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;
<img src="https://jupyter.org/assets/main-logo.svg" width="100">

### [`Jupyter Notebook`](https://jupyter.org/hub): An open-source web application that allows you to create and share documents that contain live code, equations, visualizations and narrative text.

\
\
<img src="https://jupyter.org/assets/hublogo.svg" width="200">

### [`JupyterHub`](https://jupyter.org/hub): A multi-user version of the notebook designed for companies, classrooms and research labs

\
\
<img src="https://upload.wikimedia.org/wikipedia/en/c/cd/Anaconda_Logo.png" width="200">

### [`Anaconda`](https://jupyter.org/hub) (`conda` for short): A free and open-source distribution of the Python and R programming languages for scientific computing, that aims to simplify package management and deployment.

\
\
<img src="https://www.docker.com/sites/default/files/d8/2019-07/horizontal-logo-monochromatic-white.png" width="200">

### [`Docker`](https://www.docker.com/): A set of platform-as-a-service products that use OS-level virtualization to deliver software in packages called containers.

- A Docker container image is a lightweight, standalone, executable package of software that includes everything needed to run an application: code, runtime, system tools, system libraries and settings.

\
\
<img src="https://kubernetes.io/images/kubernetes-horizontal-color.png" width="300">

### [`Kubernetes`](https://kubernetes.io/): An open-source system for automating deployment, scaling, and management of containerized applications.

Disclaimer
------------

Neither I nor my employer are affiliated in any way with fast.ai, Project Jupyter,
or any other organizations responsible for any of the technologies used in this project.
