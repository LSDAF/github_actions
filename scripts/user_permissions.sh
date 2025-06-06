#!/bin/bash
# Copyright 2025 LSDAF
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.


# Function to check if a user has admin permissions in the LSDAF organization
# Arguments:
#   $1: GitHub token
check_user_permissions() {
  local github_token="$1"

  # Get the authenticated user's information
  USER_INFO=$(curl -s -H "Authorization: token ${github_token}" \
    https://api.github.com/user)

  # Extract username
  USERNAME=$(echo "$USER_INFO" | jq -r '.login')
  echo "Authenticated as: $USERNAME"

  # Check if the user is an organization member and their role
  ORG_MEMBERSHIP=$(curl -s -H "Authorization: token ${github_token}" \
    https://api.github.com/orgs/LSDAF/memberships/$USERNAME)

  # Check if the response contains an error
  ERROR=$(echo "$ORG_MEMBERSHIP" | jq -r '.message')
  if [[ "$ERROR" == "Not Found" ]]; then
    echo "::error::User $USERNAME is not a member of the LSDAF organization"
    return 1
  fi

  # Extract the user's role in the organization
  ROLE=$(echo "$ORG_MEMBERSHIP" | jq -r '.role')
  echo "User role in organization: $ROLE"

  # Check if the user is an admin
  if [[ "$ROLE" == "admin" ]]; then
    echo "User is an organization admin. Proceeding with the workflow."
    return 0
  elif [[ "$ROLE" == "member" ]]; then
    # Check if the user has maintainer permissions
    ORG_PERMISSION=$(curl -s -H "Authorization: token ${github_token}" \
      https://api.github.com/orgs/LSDAF/memberships/$USERNAME | jq -r '.role')

    if [[ "$ORG_PERMISSION" == "maintainer" ]]; then
      echo "::error::User $USERNAME is a maintainer. Only organization admins can perform this action."
      return 1
    else
      echo "::error::User $USERNAME is a regular member. Only organization admins can perform this action."
      return 1
    fi
  else
    echo "::error::Unknown role: $ROLE. Only organization admins can perform this action."
    return 1
  fi
}