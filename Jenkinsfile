agent {
    kubernetes {

        yaml '''
apiVersion: v1
kind: Pod

spec:

  volumes:
    - name: docker-graph-storage
      emptyDir: {}

  containers:

    - name: docker
      image: docker:26-dind
      securityContext:
        privileged: true

      tty: true

      env:
        - name: DOCKER_TLS_CERTDIR
          value: ""

      command:
        - dockerd-entrypoint.sh

      args:
        - --host=tcp://0.0.0.0:2375

      volumeMounts:
        - name: docker-graph-storage
          mountPath: /var/lib/docker

    - name: docker-cli
      image: docker:26-cli

      tty: true

      command:
        - cat

      env:
        - name: DOCKER_HOST
          value: tcp://localhost:2375

        - name: DOCKER_TLS_CERTDIR
          value: ""

      volumeMounts:
        - name: docker-graph-storage
          mountPath: /var/lib/docker

    - name: jnlp
      image: jenkins/inbound-agent:latest
'''
    }
}
