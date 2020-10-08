JupyterHub-Fastbook
==============================
<img src="https://jupyter.org/assets/hublogo.svg" width="200">
+ 
<img src="https://images-na.ssl-images-amazon.com/images/I/516YvsJCS9L._SX379_BO1,204,203,200_.jpg" height="140">

1. ##### Deploy JupyterHub:
    - ###### To your Kubernetes cluster<sup>[[0]](#microk8s)</sup> via the [official Helm chart](https://jupyterhub.github.io/helm-chart).
    - ###### With the `JupyterHub-Fastbook` docker image<sup>[[1]](#jupyter-minimal-notebook)</sup> which comes pre-loaded with [fast.ai's Practical Deep Learning for Coders course](https://course.fast.ai/) [notebooks repository](https://github.com/fastai/fastbook) and all the required dependencies.
    - ###### [_Optional_] Using [Github Oauth](https://docs.github.com/en/free-pro-team@latest/developers/apps/building-oauth-apps) for user authentication
2. ##### Build and push your own `JupyterHub-Fastbook` images to your own Docker registry.

This is really handy if you would like to use
[fast.ai's Practical Deep Learning for Coders course](https://course.fast.ai/):
1. As the basis for a study group
2. To onboard new junior members of your organization's AI/ML team
3. As a way to go through the course on your own with very minimal setup
(i.e., by [running the Docker image in a container locally](#docker-container-deployment))
4. Anything else you can think of!

 <a name="microk8s">[0]</a> Tested with [Microk8s](https://microk8s.io/) on Ubuntu 18.04.4.

 <a name="jupyter-minimal-notebook">[1]</a> Based on the official [jupyter/minimal-notebook](https://jupyter-docker-stacks.readthedocs.io/en/latest/using/selecting.html#jupyter-minimal-notebook) from [Jupyter Docker Stacks](https://jupyter-docker-stacks.readthedocs.io/en/latest/index.html).

Disclaimer
------------

Neither I nor my employer are affiliated in any way with fast.ai, Project Jupyter,
or any other organizations responsible for any of the technologies used in this project.

Overview
------------

You may run the Docker image as a container in single-user mode, outside of Kubernetes,
in which case you would interact directly with the Jupyter Notebook interface instead (see: [Quickstart: Running the Docker image locally](#docker-container-deployment))

The JupyterHub Kubernetes deployment portion of this project is based on
the official [Zero to JupyterHub with Kubernetes guide ](https://zero-to-jupyterhub.readthedocs.io/en/latest/)
and assumes you have your own Kubernetes cluster already set up. If not and you are just starting out,
[Minikube](https://kubernetes.io/docs/setup/learning-environment/minikube/) is great for local development
and [Microk8s](https://microk8s.io/) works well for single-node clusters.


Quickstart
------------

## <a name="docker-container-deployment">Running the Docker image locally</a>

```shell script
# Specify the Docker image tag you want to use,
# i.e., `TAG=latest` or, even better, a specific tag such as `TAG=v20201007-7890c25`
TAG=${YOUR_DESIRED_TAG}
docker run -p 8888:8888 teozosa/jupyterhub-fastbook:${TAG}
```

###### Note: This will automatically pull the image from Docker Hub if it is not already present on your machine

<img src=".github/docker_run_jupyter_address.png" width="946">

Follow the directions on-screen to log in to your local Jupyter notebook environment! 🎉

### **Important**: When running the fast.ai notebooks, be sure to switch the notebook kernel to the `fastbook` environment:

<img src=".github/jupyter_notebook_fastbook_kernel_selection.png" width="600">

## Deploying JupyterHub to your Kubernetes cluster

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
# using the secret token you generated in step 1 and
# specifying the Docker image tag you want to use,
# i.e., `TAG=latest` or, even better, a specific tag such as `TAG=v20201007-7890c25`
make deploy TAG=${YOUR_DESIRED_TAG}
```

#### You should then be greeted by a Helm messages similar to the below:

<img src=".github/helm_success.png" width="400">

#### Once all the pods are running:

<img src=".github/jupyterhub_pods_running.png" width="1492">

#### Get the address of the JupyterHub client:

```shell script
JUPYTERHUB_IP=$(kubectl --namespace jhub get service proxy-public -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
echo $JUPYTERHUB_IP
```

#### Type the IP from the previous step into your browser, login, and you should now be in the JupyterLab UI! 🎉

<img src=".github/jupyterlab_ui_homepage.png" width="400">

### **Important**: When running the fast.ai notebooks, be sure to switch the notebook kernel to the `fastbook` environment:

<img src=".github/jupyterlab_kernel_selection.png" width="400">
<p></p>
<img src=".github/jupyterlab_fastbook_kernel_selection.png" width="400">

Advanced Usage:
------------

## Makefile overview:  

##### Available rules:

    build               Build Docker container
    config.yaml         Generate JupyterHub Helm chart configuration file
    deploy              Deploy JupyterHub to your Kubernetes cluster
    push                Push image to Docker Hub container registry


Tip: invoking `make` without any arguments will display auto-generated
documentation similar to the above.  

## Build and push your own Docker image

In addition to deployment, the `makefile` contains facilities to build and push
Docker images to your own repository. Simply edit the appropriate fields in `Makefile`
and invoke `make` with one of: `build`, `push`.


## Enabling GitHub Oauth<sup>[[2]](#jupyterhub-documentation-oauth2)</sup>:

##### Determine your JupyterHub host address (the address you use in your browser to access JupyterHub) and add it to your `.env` file:
```shell script
JUPYTERHUB_IP=$(kubectl --namespace jhub get service proxy-public -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
echo "export JUPYTERHUB_IP=${JUPYTERHUB_IP}" >> .env
```

##### Generate your GitHub Oauth credentials and add them to your `.env` file:
Follow this tutorial: [GitHub documentation: Building OAuth Apps - Creating an OAuth App](https://docs.github.com/en/free-pro-team@latest/developers/apps/creating-an-oauth-app), then:

```shell script
GITHUB_CLIENT_ID=$YOUR_GITHUB_CLIENT_ID
GITHUB_CLIENT_SECRET=$YOUR_GITHUB_CLIENT_SECRET
echo "export GITHUB_CLIENT_ID=${GITHUB_CLIENT_ID}" >> .env
echo "export GITHUB_CLIENT_SECRET=${GITHUB_CLIENT_SECRET}" >> .env
```

#### Redeploy your JupyterHub instance:

 ```shell script
make config.yaml
make deploy TAG=${YOUR_DESIRED_TAG}
```

Now, the first time a user logs in to your JupyterHub instance,
they will be greeted by a screen that looks like this:

<img src=".github/github_oauth_confirmation.png" width="400">

Once they click "Authorize", users will now automatically be authenticated via
GitHub's Oauth whenever they log in.

 <a name="jupyterhub-documentation-oauth2">[2] see: [JupyterHub documentation: Authenticating with OAuth2 - GitHub](https://zero-to-jupyterhub.readthedocs.io/en/latest/administrator/authentication.html#github) </a>

<a name="jupyterhub-kubernetes-deployment-overview">JupyterHub Kubernetes Deployment Overview</a>
------------

## Setup:

source: [JupyterHub documentation: Setting up JupyterHub](https://zero-to-jupyterhub.readthedocs.io/en/latest/setup-jupyterhub/setup-jupyterhub.html#setting-up-jupyterhub)


Note: commands in this section should be run on the command line from the root of your repository.

#### Generate a secret token for your JupyterHub deployment and place it in your local `.env` file:

 ```shell script
 echo "export PROXY_SECRET=$(openssl rand -hex 32)" > .env
```
##### DANGER! **DO NOT VERSION CONTROL THIS FILE!**

If you need to store these values in version control, consider using something
like [SOPS](https://github.com/mozilla/sops).

#### Install Helm:

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


## Deployment:

source: [JupyterHub documentation: Setting up JupyterHub](https://zero-to-jupyterhub.readthedocs.io/en/latest/setup-jupyterhub/setup-jupyterhub.html)

#### Generate a JupyterHub configuration file<sup>[*](#config-auto-regenerated-on-deploy)</sup>:

```shell script
make config.yaml
```
This will create a `config.yaml` by populating fields of `config.TEMPLATE.yaml`
with the pre-set deployment variables[†](#override-docker-env-var) and values specified in your `.env` file.

<a name="config-auto-regenerated-on-deploy">*</a> 
Anything generated here will be overwritten by the following deployment 
step with the most recent values, but it this step is here for completion's sake.


#### Deploy JupyterHub to your Kubernetes cluster:

Once you've verified `config.yaml` contains the correct information,
on the command line, run:

```shell script
make deploy TAG=${YOUR_DESIRED_TAG}
```

This will deploy the JupyterHub instance to your cluster via the
[official Helm chart](https://zero-to-jupyterhub.readthedocs.io/en/latest/setup-jupyterhub/setup-jupyterhub.html#install-jupyterhub), parametrized by pre-set deployment variables[†](#override-docker-env-var) and
the `config.yaml` file you generated in the previous step.


<a name="override-docker-env-var">†</a> to override a pre-set deployment variable, simply edit the appropriate value in `Makefile`.

### A note on built-in image tag logic:

The `makefile` defaults to strong versioning of image tags (derived from [Google's Kubeflow](https://www.kubeflow.org/) [Central Dashboard Makefile](https://github.com/kubeflow/kubeflow/blob/305393b0a543feeec6c1dc866ce2637ef1985a74/components/centraldashboard/Makefile)) for unambiguous container image provenance.

Unless you are pushing and pulling to your own registry, you *MUST* override the
the generated tag with your desired tag when deploying to your own cluster.

Further Reading
------------

### [`fast.ai`](https://www.fast.ai/): Making neural nets uncool again
- Practical Deep Learning for Coders:
[(Course)](https://course.fast.ai/) [(Book)](https://www.amazon.com/Deep-Learning-Coders-fastai-PyTorch/dp/1492045527) [(Notebook Repository)](https://github.com/fastai/fastbook)

<img src="https://jupyter.org/assets/hublogo.svg" width="200">

### [`JupyterHub`](https://jupyter.org/hub): A multi-user version of the notebook designed for companies, classrooms and research labs
