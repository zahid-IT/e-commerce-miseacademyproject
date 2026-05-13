agent {
    kubernetes {

        yaml '''
apiVersion: v1
kind: Pod

spec:
  restartPolicy: Never

  containers:

    - name: kaniko
      image: gcr.io/kaniko-project/executor:v1.23.2
      command:
        - sleep
      args:
        - "9999999"
      tty: true

      volumeMounts:
        - name: docker-config
          mountPath: /kaniko/.docker

    - name: jnlp
      image: jenkins/inbound-agent:latest
      tty: true

  volumes:

    - name: docker-config
      secret:
        secretName: dockerhub-secret
        items:
          - key: .dockerconfigjson
            path: config.json
'''
    }
}
