#!/bin/sh 

register() {
  echo "url of gitlab runner (e.g. https://gitlab.com/): "
  read runner_url
  echo "Description of gitlab runner: "
  read runner_description
  echo "Authentication token (begin with glrt-): "
  read runner_auth_token
  echo "Executor (shell, docker): "
  read runner_exec
  if [ "$runner_exec" = "docker" ]; then
    echo "Using $runner_exec as executor"
    echo -n "Docker image: " && read runner_docker_image
    sudo gitlab-runner register \
      --non-interactive \
      --url "$runner_url" \
      --token "$runner_auth_token" \
      --executor "$runner_exec" \
      --docker-image $runner_docker_image \
      --description "$runner_description"

  elif [ "$runner_exec" = "shell" ]; then
    echo "Using $runner_exec as executor"

    sudo gitlab-runner register \
      --non-interactive \
      --url "$runner_url" \
      --token "$runner_auth_token" \
      --executor "$runner_exec" \
      --description "$runner_description"

  else
    echo "Not supported"
    exit 1
  fi
}

output=$(sh linux/getos.sh 2>&1)
exit_code=$?

if [ $exit_code -eq 1 ]; then
  echo "Debian system: $output"
  sudo bash linux/deb.sh
  sudo apt install gitlab-runner
  register

elif [ $exit_code -eq 2 ]; then
  echo "RedHat system: $output"
  sudo bash linux/rpm.sh
  sudo yum install gitlab-runner
  register

elif [ $exit_code -eq 0 ]; then
  echo "Unsupported system: $output"
else
  echo "Error $exit_code: $output"
fi

