#!/bin/sh 

Add_user() {
  sudo pw group add -n gitlab-runner
  sudo pw user add -n gitlab-runner -g gitlab-runner -s /usr/local/bin/bash
  sudo mkdir /home/gitlab-runner
  sudo chown gitlab-runner:gitlab-runner /home/gitlab-runner
}

Fetch_binary() {
  arch=$(uname -m)
  url="https://s3.dualstack.us-east-1.amazonaws.com/gitlab-runner-downloads/latest/binaries/gitlab-runner-freebsd-"
  if [ $arch = "amd64" ]; then
    echo "detected 64-bit architecture"
    url="${url}amd64"
  elif [ $arch = "i386" ]; then
    echo "detected 32-bit architecture"
    url="${url}386"
  fi
}

Start_service() {
  sudo mkdir -p /usr/local/etc/rc.d
  sudo bash -c 'cat > /usr/local/etc/rc.d/gitlab_runner' << "EOF"
#!/bin/sh
# PROVIDE: gitlab_runner
# REQUIRE: DAEMON NETWORKING
# BEFORE:
# KEYWORD:

. /etc/rc.subr

name="gitlab_runner"
rcvar="gitlab_runner_enable"

user="gitlab-runner"
user_home="/home/gitlab-runner"
command="/usr/local/bin/gitlab-runner"
command_args="run"
pidfile="/var/run/${name}.pid"

start_cmd="gitlab_runner_start"

gitlab_runner_start()
{
   export USER=${user}
   export HOME=${user_home}
   if checkyesno ${rcvar}; then
      cd ${user_home}
      /usr/sbin/daemon -u ${user} -p ${pidfile} ${command} ${command_args} > /var/log/gitlab_runner.log 2>&1
   fi
}

load_rc_config $name
run_rc_command $1
EOF
}

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
    sudo -u gitlab-runner -H /usr/local/bin/gitlab-runner register \
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

main() {
  echo "Adding gitlab runner as a user..."
  Add_user

  echo "Fetching binary..."
  Fetch_binary

  echo "Giving the binary permission to execute"
  sudo chmod +x /usr/local/bin/gitlab-runner

  echo "Creating empty log file at /var/log/gitlab_runner.log"
  sudo touch /var/log/gitlab_runner.log
  sudo chown gitlab-runner:gitlab-runner /var/log/gitlab_runner.log

  echo "Writing the start script..."
  Start_service

  echo "Making the gitlab_runner script executable..."
  sudo chmod +x /usr/local/etc/rc.d/gitlab_runner

  echo "Make sure gitlab_runner auto start after a reboot"
  sudo sysrc gitlab_runner_enable=YES
  sudo service gitlab_runner start

  echo "Now register a runner on any gitlab platform, and copy the generated token."
  echo "After this, Press Enter to continue"
  read abc

  register
}
