#!/bin/bash


# Import ImageStreams
ssh root@host01 'echo "Importing Red Hat Process Automation Manager 7 Image Streams into OpenShift." >> script.log'
ssh root@host01 'for i in {1..200}; do oc create -f https://raw.githubusercontent.com/jboss-container-images/rhpam-7-openshift-image/7.1.0.GA/rhpam70-image-streams.yaml -n openshift && break || sleep 2; done'

# Import Templates
ssh root@host01 'echo "Importing Red Hat Process Automation Manager 7 - Trial template into OpenShift." >> script.log'
ssh root@host01 'for i in {1..200}; do oc create -f https://raw.githubusercontent.com/jboss-container-images/rhpam-7-openshift-image/7.0.2.GA/templates/rhpam70-trial-ephemeral.yaml -n openshift && break || sleep 2; done'
ssh root@host01 'for i in {1..200}; do oc create -f https://raw.githubusercontent.com/openshift/origin/v3.7.0/examples/db-templates/postgresql-ephemeral-template.json -n openshift && break || sleep 2; done'

ssh root@host01 'echo "Logging into OpenShift as developer." >> script.log'
ssh root@host01 'for i in {1..200}; do oc login -u developer -p developer && break || sleep 2; done'

# Create new project
ssh root@host01 'echo "Creating new demo project in OpenShift." >> script.log'
ssh root@host01 'for i in {1..200}; do oc new-project rhpam7-workshop --display-name="RHPAM 7 Reporting" --description="Red Hat Process Automation Manager 7 - Reporting Project" && break || sleep 2; done'
ssh root@host01 'echo "Importing secrets and service accounts."'

# Create PAM containers.
ssh root@host01 'echo "Creating Business Central and KIE Server containers in OpenShift." >> script.log'
ssh root@host01 'for i in {1..200}; do oc new-app --template=rhpam71-trial-ephemeral -p APPLICATION_NAME="rhpam7-workshop" -p IMAGE_STREAM_NAMESPACE="openshift" -p KIE_ADMIN_USER="developer" -p KIE_SERVER_CONTROLLER_USER="kieserver" -p KIE_SERVER_USER="kieserver" -p DEFAULT_PASSWORD="developer" -p MAVEN_REPO_USERNAME="developer" -p MAVEN_REPO_PASSWORD="developer" -p BUSINESS_CENTRAL_MEMORY_LIMIT="2Gi" -e JAVA_OPTS_APPEND=-Derrai.bus.enable_sse_support=false -n rhpam7-workshop && break || sleep 2; done'
ssh root@host01 'echo "Patching Business Central OpenShift route to increase proxy timeout." >> script.log'
ssh root@host01 'for i in {1..200}; do oc annotate route rhpam7-workshop-rhpamcentr --overwrite haproxy.router.openshift.io/timeout=600s -n rhpam7-workshop && break || sleep 2; done'

# Create PostgreSQL container
ssh root@host01 'for i in {1..200}; do oc new-app --template=postgresql-ephemeral -p NAMESPACE=openshift -p POSTGRESQL_DATABASE="rhpam7_workshop_reporting" -p POSTGRESQL_USER=postgres -p POSTGRESQL_PASSWORD=postgres -n rhpam7-workshop && break || sleep 2; done'
ssh root@host01 'for i in {1..200}; do oc create configmap postgresql-config-map --from-file=~/.init/provision_data.sh --from-file=~/.init/wait_for_postgres.sh --from-file=~/.init/provision_test_data.sql -n rhpam7-workshop && break || sleep 2; done'
ssh root@host01 'for i in {1..200}; do oc volume dc/postgresql --name=postgresql-config-volume --add -m /tmp/config-files -t configmap --configmap-name=postgresql-config-map && break || sleep 2; done'
ssh root@host01 'for i in {1..200}; do oc set deployment-hook dc/postgresql --post -c postgresql -e POSTGRESQL_HOSTNAME=postgresql -e POSTGRESQL_USER=postgres -e POSTGRESQL_PASSWORD=postgres --volumes=postgresql-config-volume --failure-policy=abort -- /bin/bash /tmp/config-files/wait_for_postgres.sh /tmp/config-files/provision_data.sh && break || sleep 2; done'
