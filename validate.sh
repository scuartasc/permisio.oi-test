#!/usr/bin/env bash
# Copyright 2018 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     https://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# bash "strict-mode", fail immediately if there is a problem
set -euo pipefail

ROOT="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
# shellcheck disable=SC1090
source "$ROOT"/common.sh

HELLO_WORLD='permission.io test'
TIMED_OUT='wget: download timed out'

# Kubectl logs of the permission.io app pod will return $TIMED_OUT for the first 5 second.
sleep 20

# A helper method to make calls to the gke cluster through the bastion.
call_bastion() {
  local command=$1; shift;
  # shellcheck disable=SC2005
  echo "$(gcloud compute ssh "$USER"@gke-permisio.oi-test  --command "${command}")"
}

# We expect to see "permisssion.oi test" in the logs with the app=permission.io label.
call_bastion "kubectl logs --tail 10 \$(kubectl get pods -oname -l app=permission.io)" \
| grep "$HELLO_WORLD" &> /dev/null || exit 1
echo "step 1 of the validation passed."

# We expect to see the same behavior in the logs with the app=not-permission.io label
# until the network-policy is applied.
call_bastion "kubectl logs --tail 10 \
 \$(kubectl get pods -oname -l app=not-permission.io)" | grep "$HELLO_WORLD" \
 &> /dev/null || exit 1
echo "step 2 of the validation passed."

# Apply the network policy.
call_bastion "kubectl apply -f ./yamls/network-policy.yaml" &> /dev/null

# Sleep for 10s while more logs come in.
sleep 10

# Now we expect to see a 'timed out' message because the network policy
# prevents the communication.
call_bastion "kubectl logs --tail 10 \
 \$(kubectl get pods -oname -l app=not-permission.io)" | grep "$TIMED_OUT" \
 &> /dev/null || exit 1
echo "step 3 of the validation passed."

# If the network policy is working correctly, we still see the original behavior
# in the logs with the app=permission.io label.
call_bastion "kubectl logs --tail 10 \$(kubectl get pods -oname -l app=permission.io)" \
| grep "$HELLO_WORLD" &> /dev/null || exit 1
echo "step 4 of the validation passed."

call_bastion "kubectl delete -f ./yamls/network-policy.yaml" &> /dev/null