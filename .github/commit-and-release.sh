#!/usr/bin/env bash

CHANGES=0
GITHUB_ACTOR_EMAIL="${GITHUB_ACTOR}@users.noreply.github.com"

echo "Commit and Release"
echo "------------------"
echo "Current Hash: ${GITHUB_SHA}"

# Set GH settings
git config --global user.email "${GITHUB_ACTOR_EMAIL}"
git config --global user.name "${GITHUB_ACTOR}"

# Test if changes
git diff --quiet roles || CHANGES=1

# If changes are present
if [[ ${CHANGES} -eq 1 ]]; then
  # Create a CAI-formatted inventory of all the roles
  echo "Generating gcp_roles_cai.json"
  cat roles/* | jq -c '. + {asset_type: "iam.googleapis.com/ExportedIAMRole"}' > gcp_roles_cai.json

  # Add and commit
  echo "git add -A roles"
  git add -A roles
  echo "git commit -m 'Fetch all roles'"
  git commit -m 'Fetch all roles'

  # Create tag
  NEW_TAG="$(date +'%Y-%m-%d-%H-%M-%S')"
  echo "New tag: ${NEW_TAG}"
  NEW_GITHUB_SHA="$(git rev-parse HEAD)"
  echo "New sha: ${NEW_GITHUB_SHA}"
  echo "git tag ${NEW_TAG}" 
  git tag ${NEW_TAG} 

  # Push tag
  echo "git push --tags --follow-tags --set-upstream origin main"
  git push --tags --follow-tags --set-upstream origin main

  # Create release body
  RELEASE_DIFF="$(git diff ${GITHUB_SHA} ${NEW_GITHUB_SHA} --compact-summary | sed -e ':a' -e 'N' -e '$!ba' -e 's/\n/\\n/g')"
  RELEASE_TEXT="GCP IAM Update ${NEW_TAG}\n\n\`\`\`\n${RELEASE_DIFF}\n\`\`\`"
  RELEASE_BODY="$(printf '{"tag_name": "%s","target_commitish": "main","name": "Release %s","body": "%s","draft": false,"prerelease": false}' $NEW_TAG $NEW_TAG "$RELEASE_TEXT")"
  # Push release
  echo curl -H "Authorization: token <mytoken>" -XPOST --data "${RELEASE_BODY}" "https://api.github.com/repos/${GITHUB_REPOSITORY}/releases" 
  curl -H "Authorization: token ${GITHUB_TOKEN}" -XPOST --data "${RELEASE_BODY}" "https://api.github.com/repos/${GITHUB_REPOSITORY}/releases" 
else
  echo "No changes detected"
fi
