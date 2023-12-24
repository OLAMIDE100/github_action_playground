path="$1"
echo $CREDENTIALS > gcloud-api-key.json
export GOOGLE_APPLICATION_CREDENTIALS=$(pwd)/gcloud-api-key.json
export TF_VAR_function_version=${GITHUB_RUN_NUMBER}_${GITHUB_RUN_ATTEMPT}
echo 'yes' | terraform -chdir=$path init 
terraform -chdir=$path  plan
terraform -chdir=$path  apply -auto-approve -input=false