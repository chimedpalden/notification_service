pipeline {
    options {
        buildDiscarder(
            logRotator(daysToKeepStr: '30', artifactDaysToKeepStr: '15', artifactNumToKeepStr: '15')
        )
        timeout(time: 10, unit: 'MINUTES')
    }

    agent {
        label 'generic-worker'
    }

    environment {
        PATH = "$PATH:/var/lib/jenkins/.rbenv/bin:/var/lib/jenkins/.rbenv/shims"
        RBENV_ROOT = '/var/lib/jenkins/.rbenv'
        SSH_KEY_FILE = credentials('jenkins_github_ssh')
        DATABASE_URL="postgres://postgres:postgres@localhost:5432/notification_test"
    }

    stages {
        // Check for branch name, only branches starting with feature and hotfix are allowed
        stage('Validate git branch') {
            when {
                beforeAgent true
                changeRequest target: '^master$', branch: '^(?:(?!feature|release).)*$', comparator: "REGEXP"
            }
            steps {
                echo 'Read more: https://vineti.atlassian.net/wiki/spaces/EN/pages/275153046/Git+Flow'
                error 'GitFlow Error; Branch name is not correct'
            }
        }

        stage('Abort Previous Builds') {
            when {
                beforeAgent true
                expression { env.CHANGE_ID ==~ /.*/ }
            }
            steps {
                abortPreviousBuilds()
            }
        }

        stage('Configure Environment') {
            steps {
                sh label: 'Clean Workspace', script: 'rm -rf * .*', returnStatus: true
                checkout scm
                sh label: 'Environment', script: 'env|sort'
                sh label: 'Software Versions', script: '''\
                    set -x
                    id
                    rbenv --version
                    rbenv versions
                    git --version
                    bash --version
                    node --version
                '''.stripIndent()
                sh label: "Start Databases", script: """\
                    set +e
                    sudo podman ps -aq | xargs -r sudo podman rm --force
                    sudo buildah ps -aq | xargs -r sudo buildah rm
                    rm -rf /var/tmp/*
                    set -e
                    sudo -n podman run --name redis -d -p 6379:6379 redis:latest
                    sudo -n podman run --name postgres -d -p 5432:5432 -e POSTGRES_USER=postgres -e POSTGRES_PASSWORD=postgres postgres:9.6
                """
            }
        }

        stage('Setup') {
            environment {
                GIT_SSH_COMMAND = "/usr/bin/ssh -o StrictHostKeyChecking=no -i ${env.SSH_KEY_FILE}"
            }
            steps {
                // This needs to be moved to worker creation to maintain isolate
                // and limit impacts in other pipelines running on new workers.
                sh label: 'Install Bundler', script: 'gem install "bundler:1.17.3"'
                sh label: 'Freeze Bundler', script: 'bundle config --local set frozen true; bundle config --local set jobs 4'
                sh label: 'Run bundle install', script: 'bundle install; cd spec/dummy; bundle install; cd ../../'
            }
        }

        stage('Database Setup') {
            steps {
                sh label: 'Drop old Databases', script: 'bundle exec rake db:drop'
                sh label: 'Create Database', script: 'bundle exec rake db:create'
                sh label: 'Run Migrations', script: 'RAILS_ENV=test bundle exec rake db:migrate'
                sh label: 'Create host database', script: 'cd spec/dummy; RAILS_ENV=test bundle exec rake db:migrate; cd ../../'
            }
        }

        stage('Lint code and Running RSpecs') {
            steps {
                sh label: 'Code Lint', script: 'bundle exec rubocop --fail-level A --format simple'
                sh label: 'RSpec', script: 'bundle exec rspec'
            }
        }
    }
}
