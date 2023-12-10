path="$1"
echo $CREDENTIALS > gcloud-api-key.json
export GOOGLE_APPLICATION_CREDENTIALS=$(pwd)/gcloud-api-key.json
echo 'yes' | terraform -chdir=$path init 
terraform -chdir=$path  plan
terraform -chdir=$path  apply -auto-approve -input=false