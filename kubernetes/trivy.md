# trivy

```bash
# 下载trivy
wget https://github.com/aquasecurity/trivy/releases/download/v0.67.2/trivy_0.67.2_Linux-64bit.tar.gz
tar -zxvf trivy_0.67.2_Linux-64bit.tar.gz
mv trivy /usr/bin

# 下载oras
wget https://github.com/oras-project/oras/releases/download/v1.3.0/oras_1.3.0_linux_amd64.tar.gz
tar -zxvf oras_1.3.0_linux_amd64.tar.gz
mv oras /usr/bin



# 使用trivy在线下载漏洞库
# 漏洞库下载后默认放在 /$USER/.cache/trivy/db 目录下
# 目录地址可以由 --cache-dir指定
trivy image --download-db-only --db-repository ghcr.nju.edu.cn/aquasecurity/trivy-db:2

# 使用trivy在线下载java漏洞库
# 漏洞库下载后默认放在 /$USER/.cache/trivy/java-db 目录下
trivy image --download-java-db-only --java-db-repository ghcr.nju.edu.cn/aquasecurity/trivy-java-db:1

# 使用trivy下载规则扫描库
# trivy没有提供单独下载规则扫描库的命令，这里通过扫描一个文件来下载规则扫描库
# 规则库下载后默认放在 /$USER/.cache/trivy/policy 目录下
trivy fs --scanners=misconfig  --checks-bundle-repository ghcr.nju.edu.cn/aquasecurity/trivy-checks:1 /etc/hosts



# oras 离线下载漏洞库
mkdir /home/earthgod/trivy/db
cd /home/earthgod/trivy/db
oras pull ghcr.nju.edu.cn/aquasecurity/trivy-db:2
tar -zxvf db.tar.gz

# oras 离线下载java漏洞库
mkdir /home/earthgod/trivy/java-db
cd /home/earthgod/trivy/java-db
oras pull  ghcr.nju.edu.cn/aquasecurity/trivy-java-db:1
tar -zxvf java-db.tar.gz

# oras 离线下载规则库
mkdir /home/earthgod/trivy/policy/content
cd /home/earthgod/trivy/policy/content
oras pull  ghcr.nju.edu.cn/aquasecurity/trivy-checks:1
tar -zxvf bundle.tar.gz
```

## 推送漏洞库到nexus

```bash
#  注意，推送时必须使用相对路径./db.tar.gz
#  使用绝对路径会导致下载失败
#  Fatal error     run error: init error: DB error: failed to download vulnerability DB: OCI artifact error: failed to download vulnerability DB: failed to download artifact from registry-dev.xcloud.lenovo.com:18083/aquasecurity/trivy-db:2: oci download error: failed to create a temp file: open /tmp/trivy-20911/oci-download-4109815648/data/sync_trivydb/db.tar.gz: no such file or directory
#  查看制品type
#  oras manifest fetch ghcr.nju.edu.cn/aquasecurity/trivy-checks:1
oras push  registry-dev.xcloud.lenovo.com:18083/aquasecurity/trivy-db:2 \
--artifact-type application/vnd.aquasec.trivy.db.layer.v1.tar+gzip \
./db.tar.gz:application/vnd.aquasec.trivy.db.layer.v1.tar+gzip

oras push  registry-dev.xcloud.lenovo.com:18083/aquasecurity/trivy-java-db:1 \
--artifact-type application/vnd.aquasec.trivy.javadb.layer.v1.tar+gzip \
./javadb.tar.gz:application/vnd.aquasec.trivy.javadb.layer.v1.tar+gzip

oras push  registry-dev.xcloud.lenovo.com:18083/aquasecurity/trivy-checks:1 \
--artifact-type application/vnd.cncf.openpolicyagent.layer.v1.tar+gzip \
./bundle.tar.gz:application/vnd.cncf.openpolicyagent.layer.v1.tar+gzip

oras push  registry-dev.xcloud.lenovo.com:18083/aquasecurity/installer-db:1 \
--artifact-type xcloud.poc.com/db \
./installer.db:xcloud.poc.com/db
```


## 镜像扫描

```bash
# scanners 介绍
# vuln     漏洞扫描
# secret   密码扫描
# misconfig 配置扫描
# license  许可证扫描

# severity 漏洞的严重级别
# CRITICAL
# HIGH
# MEDIUM
# LOW
trivy image \
--scanners vuln,secret,misconfig,license  \
--severity CRITICAL,HIGH  \
registry-public.lenovo.com/lq/syncer:v0.0.1

# 若漏洞数据文件过期
# 可以跳过下载最新漏洞数据文件
trivy \
--insecure \
image \
--scanners vuln,secret,misconfig,license  \
--severity CRITICAL,HIGH  \
--skip-db-update \
--skip-java-db-update \
--skip-check-update \
--username admin \
--password 123456 \
registry-public.lenovo.com/lq/syncer:v0.0.1

## 指定漏洞库地址
trivy \
--insecure \
image \
--scanners vuln,secret,misconfig,license  \
--severity CRITICAL,HIGH  \
--db-repository registry-dev.xcloud.lenovo.com:18083/aquasecurity/trivy-db:2 \
--java-db-repository registry-dev.xcloud.lenovo.com:18083/aquasecurity/trivy-java-db:1 \
--checks-bundle-repository registry-dev.xcloud.lenovo.com:18083/aquasecurity/trivy-checks:1 \
--username admin \
--password admin123 \
registry-dev.xcloud.lenovo.com:18083/earth_system/multikube:v0.0.2
```

## k8s扫描


```bash
# 扫描k8s trivy和集群不在同一台机器上
# 如果有镜像无法获取
# 会导致扫描失败
# 可以添加--skip-images参数,会跳过镜像和secret的扫描
# 如果扫描集群中的images
# 需要trivy所在节点可以访问到镜像仓库，docker login
trivy k8s \
--skip-db-update \
--skip-java-db-update \
--skip-check-update \
--node-collector-imageref registry-dev.xcloud.lenovo.com:18083/aquasecurity/node-collector:0.3.1 \
--include-namespaces kube-system --report summary

# cis 扫描使用node-collector
trivy k8s --compliance=k8s-cis-1.23 --report all  \
--node-collector-imageref registry-dev.xcloud.lenovo.com:18083/aquasecurity/node-collector:0.3.1 \
--debug --skip-db-update --skip-java-db-update --skip-check-update

# csi 扫描自定义规则
# https://github.com/aquasecurity/trivy-checks/blob/31e779916f3863dd74a28cee869ea24fdc4ca8c2/specs/compliance/k8s-cis-1.23.yaml

# --report all 不知为什么没输出
trivy k8s --compliance=@/root/k8s-cis-1.23.yaml --report summary  \
--node-collector-imageref registry-dev.xcloud.lenovo.com:18083/aquasecurity/node-collector:0.3.1 \
--debug --skip-db-update --skip-java-db-update --skip-check-update
```

## trivy server

```bash
# trivy 扫描中只有config，k8s没有server mode
#   config      扫描配置文件
#   filesystem  扫描本地文件系统
#   image       扫描镜像
#   kubernetes  扫描k8s集群
#   repository  扫描git仓库
#   rootfs      扫描rootfs
#   sbom        扫描 SBOM 中漏洞和licenses
#   vm          扫描虚拟机镜像

# 启动server
trivy server \
--skip-db-update \
--listen 0.0.0.0:10000

# client

# filesystem
trivy filesystem --server http://10.122.166.104:10000 /etc

# image
# trivy 以客户端/服务器模式运行
# 但错误配置( misconfiguration )和许可证(license)扫描将在客户端完成

# scanner 添加misconfig需要本地有check db(bundle.tar.gz)
trivy image --server http://10.122.166.104:10000 registry-dev.xcloud.lenovo.com:18083/earth_system/seaweedfs:3.80 \
--username admin --password admin123 \
--scanners vuln,secret,misconfig,license
```

## 源码编译trivy

```bash
cd cmd/trivy
# trivy 使用了jsonv2特性，需要添加编译标签
go build -tags=goexperiment.jsonv2 -o trivy
```

## 编写trivy cis 扫描自定义规则

```yaml
# /root/test.yaml
spec:
  id: k8s-cis
  title: CIS Kubernetes Benchmarks v1.24
  description: CIS Kubernetes Benchmarks
  version: "1.24"
  relatedResources:
    - https://www.cisecurity.org/benchmark/kubernetes
  controls:
    - id: 1.1.1
      name: 确保 API 服务器 pod 规范文件的权限限制为 700 或更多。
      description: 确保 API 服务器 pod 规范文件具有 700 或更多限制性权限。
      checks:
        - id: AVD-CK8S-0001 # trivy/pkg/compliance/spec/compliance.go 必须是 avd- cve- vuln- secret- dla- 开头
      severity: HIGH
      commands:
        - id: CCMD-0001
```

```yaml
# /root/.cache/trivy/policy/content/commands/kubernetes/test.yaml
- id: CCMD-0001
  key: TestKey # 设置自定义key
  title: API server pod specification file permissions
  nodeType: master
  audit: stat -c %a $apiserver.confs # 检查命令
  platforms:
    - k8s
    - rke2
```

所在位置: /root/.cache/trivy/policy/content/policies/kubernetes/policies/test.rego
```rego
package builtin.kubernetes.CK8S0001

import rego.v1

validate_spec_permission(sp) := {"TestKey": violation} if {
	sp.kind == "NodeInfo"
	sp.type == "master"
	violation := {permission | permission = sp.info.TestKey.values[_]; permission > 700}
	count(violation) > 0
}

deny contains res if {
	output := validate_spec_permission(input)
	msg := "确保 API 服务器 pod 规范文件权限设置为 700 或更多限制性"
	res := result.new(msg, output)
}
```

测试
```bash
trivy k8s --compliance=@/root/test.yaml --report summary  \
--node-collector-imageref registry-dev.xcloud.lenovo.com:18083/aquasecurity/node-collector:0.3.1 \
--debug --skip-db-update --skip-java-db-update --skip-check-update
```

执行该测试命令生成的node-collector pod yaml 如下：
```yaml
apiVersion: v1
kind: Pod
metadata:
  annotations:
    cni.projectcalico.org/containerID: dd8e3a4505ead9caf4766cd5241fed81574cbc2e81f54383c5d63d7209f84878
    cni.projectcalico.org/podIP: ""
    cni.projectcalico.org/podIPs: ""
  creationTimestamp: "2025-10-28T03:39:06Z"
  finalizers:
  - batch.kubernetes.io/job-tracking
  generateName: node-collector-775d7b7765-
  labels:
    app: node-collector
    batch.kubernetes.io/controller-uid: 23307379-733f-4b3d-adaa-90f0954b86bc
    batch.kubernetes.io/job-name: node-collector-775d7b7765
    controller-uid: 23307379-733f-4b3d-adaa-90f0954b86bc
    job-name: node-collector-775d7b7765
  name: node-collector-775d7b7765-wqxzs
  namespace: trivy-temp
  ownerReferences:
  - apiVersion: batch/v1
    blockOwnerDeletion: true
    controller: true
    kind: Job
    name: node-collector-775d7b7765
    uid: 23307379-733f-4b3d-adaa-90f0954b86bc
  resourceVersion: "131531271"
  uid: 484b46d7-2833-429b-bb02-0e22014d8c4d
spec:
  automountServiceAccountToken: true
  containers:
  - args:
    - k8s
    - --kubelet-config
    - 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
    - --node-config
    - QlpoNjFBWSZTWRr5nQYAAiVZgFAQQAP4UD//3+BQBSt3ve973ve973ve973ve973ve973ve973hEUgSj9TTGVNqaqfvUqb1PU/QRIgp6pqeINKp+1U/Kn6p+VH+qgRIlPQptVVP/09E1VT/8Kqn/6qpv1T/VT/VQESIp6CKbaaqqf+qo/9VT/1VD/1VAwRKap5EMgypnqqn/lVH+VR/tVQwogd/Y48V8znO5/ltsyth9fyzHrGMrTTOENVut40ZhISEh/cW4LNaN5sc7uy79DGsTBM1LaqSs23MUVMV+p/qvnrJmisabZmbOvRAEelBCnaBJIMiyBISMgySSBIyCEjIoFBA0ksYqpRVvIKMxcDJ6xom71NycuYY7GoPULlt+oOILjvNaNlbo9KM1+gxDb1clw2Zo1yV/jmWnfNaKhoXRpHRqtbKum0xeMPbSsnKnHK36ZPchINqeb/pLojlhU1CiqIcSrQxcP8diAcq1Lc4Hc/Ay7ZnNMDiDJiBlVhq1rfZc+5CGRCCR0WubpLCZPQCk7SQUNVHjhQrqdEOaMnQI8F2hRMmLKSwCjlupsRK0CKYcKJ8fjuh7QON+bz2nFQgalclN9mCBVFY8VQ6nDR4a2AwUD7Ru7HVR8I9BYo7GETgDz8ETop0yd3HVQu4r/UUT0XUQDZ+2xI55CmYBb6nur2FsP4roDNwLgURKhUb6XCSSZwBqOMEQ6U4NgdVsXsHH8FIYc0vQBM4Td155r9eAoLV4MD00rwj+CJGnQ4Q1qXADwfT/K3UNy4Ke/AgagU4NgfkhBNjUvxv0gOITFlttktttoqiiqrql3Ji0JjGOM0iPh7Au0R+lHkK2SQH8EA8SEAPN9UR+yAPdQ6UeSwU+G21jkB5IKZQY7KaRepmZu5qaCv+2AIDY1UdzsCmjDfENjk5Q5dfdPgGoZEcB5gEgSdyBYMiRhohJRGmNH5D2DODFUpkjZFC4qM3UD8Oh5PB67gwWWCmor5OEfSZUM/GCHoHr6DduEgSBIhgA2cNoYzA9SEkkkBhG5hO5GyayQIcke6JBfJuiPfRBDJF9n94diPQAIj+A4HEH6Pn4Oz3WkEPVppHx39n7+XqIe6J34O7aGg6zapAo7FBdKjgR6UpQBHvwL6eRYZU4DCHhBcA+0exD7F3wueFX0nN+NPx6FkpC9JIkiVbhlJRYhxEwRUsNCGGfI++p47ME8cYO0gySeQDSeTCJ9vmj8BzggfDap+zxpQL7/UKISU1R97lgVE6kALUxGkhEuU1Frd06sQDMRIBJSIUiOSwzSOC4Jcje36iie1clDgXmomTmC9fIh9CHCgenRQP8LuSKcKEgNfM6DA==
    - --kubelet-config-mapping
    - QlpoNjFBWSZTWR3xl14AABrfgAAQWAfiNS+q/gA/79/wQAHrd3d3d3d3CRTRGkn6p6mj9Uaqn+0aBVP8VH+lR+MlT/Kp/6qgkRJU/01Tw1VVT/9hVVH/6qp//6qqn/+hVUf/6qqb/9KqH/qqA//1VU/9mqqglBE1TaMVVP/zVVT/9DRVT/9Kqf+qp/7VVP/aqp/+iqn/qqf/qqj/1VN/qp/gkkTEp4BMm0qqn//qqqB/+qqf/tVVN/+lVH/qqH/6qp/6qh/5VRwjD3+Jj4sylEco3x/Ww/Jnahfcq1Jca8NN95l+m9yKZzhvotphS0nGPG3zy7euPrVI3f38d5/pLtktuHCUxHMR4TRxrcm9u0i8VhQVuw2vmg2kIqHddWSX9g9yeSkZW/IRMzjq2UCb728bV/jcuKDDumOW7cyytoJLwXqlPq+XZC16gMTL6RuN3oVfe4H3OKQyvBAdqKnlnOMDY4/xuSShLpbqbGoK4ypx/h1E1K0uWw6ZtEEUESvlsMB7AuAIsyiTJ2+QKq7AZXjJjHYHl4wOAGPqcy4I6niYCyy87BQzP1CaFjmdg10NbB69qohL2zv16mx3Oiv1vFAWhBTwQWFnXE5FADFP0mYee9v2RSiBIs47jRXnIRQCuZEjDA8FGSKUm4a0bbiqRd37e+Z62KR59VUs1MdwWhEsIRyg0CAE8511aMs60pHlRokaO09kYsSlEoGQbSShtgwTVtAhC5gQPNmPuxsqWDIwXsN5KuU/ng1K6AmYoBBzgCXWhvgi85n2+ZRc/96YsS8lVSfhdyRThQkB3xl14A==
    - --node-commands
    - QlpoNjFBWSZTWSiA9tIAADXfgFQQRgNwUCwqRAAvL98gIACKhqepM1T9TymgVU/8qp/6qn/lVM/9VR/qp/gqhFT3qI9E9Sqn/tNVU//VVH/6qp/+qqb/00VQ/9Kp/+kkAKdXfd4TmEAEGAG/HiQx6MavZvWbjHMcWKu0G5kQSYjArX7c2+mtsdMPFTliFvPXMW+1GLRnGSFSVX3ZK/3ukZM+t8ra2o8/yJmT2VK0oxNK3uzR2gS5B5TmJ7oA8ITXfgSNES1Kfwu5IpwoSBRAe2kA
    command:
    - node-collector
    image: registry-dev.xcloud.lenovo.com:18083/aquasecurity/node-collector:0.3.1
    imagePullPolicy: IfNotPresent
    name: node-collector
    resources:
      limits:
        cpu: 100m
        memory: 100M
      requests:
        cpu: 50m
        memory: 50M
    securityContext:
      allowPrivilegeEscalation: false
      capabilities:
        drop:
        - all
      privileged: false
      readOnlyRootFilesystem: true
    terminationMessagePath: /dev/termination-log
    terminationMessagePolicy: File
    volumeMounts:
    - mountPath: /var/lib/etcd
      name: var-lib-etcd
      readOnly: true
    - mountPath: /var/lib/kubelet
      name: var-lib-kubelet
      readOnly: true
    - mountPath: /var/lib/kube-scheduler
      name: var-lib-kube-scheduler
      readOnly: true
    - mountPath: /var/lib/kube-controller-manager
      name: var-lib-kube-controller-manager
      readOnly: true
    - mountPath: /etc/systemd
      name: etc-systemd
      readOnly: true
    - mountPath: /lib/systemd/
      name: lib-systemd
      readOnly: true
    - mountPath: /etc/kubernetes
      name: etc-kubernetes
      readOnly: true
    - mountPath: /etc/cni/net.d/
      name: etc-cni-netd
      readOnly: true
    - mountPath: /var/run/secrets/kubernetes.io/serviceaccount
      name: kube-api-access-bwwnv
      readOnly: true
  dnsPolicy: ClusterFirst
  enableServiceLinks: true
  hostPID: true
  nodeName: sldw93dwm29
  nodeSelector:
    kubernetes.io/hostname: sldw93dwm29
  preemptionPolicy: PreemptLowerPriority
  priority: 0
  restartPolicy: Never
  schedulerName: default-scheduler
  securityContext:
    runAsGroup: 0
    runAsUser: 0
    seccompProfile:
      type: RuntimeDefault
  serviceAccount: default
  serviceAccountName: default
  terminationGracePeriodSeconds: 30
  tolerations:
  - effect: NoExecute
    key: node.kubernetes.io/not-ready
    operator: Exists
    tolerationSeconds: 300
  - effect: NoExecute
    key: node.kubernetes.io/unreachable
    operator: Exists
    tolerationSeconds: 300
  volumes:
  - hostPath:
      path: /var/lib/etcd
      type: ""
    name: var-lib-etcd
  - hostPath:
      path: /var/lib/kubelet
      type: ""
    name: var-lib-kubelet
  - hostPath:
      path: /var/lib/kube-scheduler
      type: ""
    name: var-lib-kube-scheduler
  - hostPath:
      path: /var/lib/kube-controller-manager
      type: ""
    name: var-lib-kube-controller-manager
  - hostPath:
      path: /etc/systemd
      type: ""
    name: etc-systemd
  - hostPath:
      path: /lib/systemd
      type: ""
    name: lib-systemd
  - hostPath:
      path: /etc/kubernetes
      type: ""
    name: etc-kubernetes
  - hostPath:
      path: /etc/cni/net.d/
      type: ""
    name: etc-cni-netd
  - name: kube-api-access-bwwnv
    projected:
      defaultMode: 420
      sources:
      - serviceAccountToken:
          expirationSeconds: 3607
          path: token
      - configMap:
          items:
          - key: ca.crt
            path: ca.crt
          name: kube-root-ca.crt
      - downwardAPI:
          items:
          - fieldRef:
              apiVersion: v1
              fieldPath: metadata.namespace
            path: namespace
```

配置都使用base64编码并使用bzip2压缩

解码算法如下
```go

func uncompressAndDecode(kubeletConfig string) ([]byte, error) {
	encodedReader := io.NopCloser(strings.NewReader(kubeletConfig))
	// base64 decode logs
	compressedLogsBytes, err := base64Decode(encodedReader)
	if err != nil {
		return nil, err
	}
	// bzip2 decompress logs
	unCompressedLogsReader, err := decompressBzip2(compressedLogsBytes)
	if err != nil {
		return nil, err
	}
	return io.ReadAll(unCompressedLogsReader)
}

func base64Decode(encodedReader io.Reader) ([]byte, error) {
	encodedBytes, err := io.ReadAll(encodedReader)
	if err != nil {
		return nil, err
	}
	return base64.StdEncoding.DecodeString(string(bytes.TrimSpace(encodedBytes)))
}


// decompressBzip2 accept bzip2 compressed bytes and decompress it
// #nosec
func decompressBzip2(compressedBytes []byte) (io.Reader, error) {
	bz2Reader := bzip2.NewReader(bytes.NewReader(compressedBytes))
	uncompressedWriter := new(bytes.Buffer)
	//nolint:gosec
	_, err := io.Copy(uncompressedWriter, bz2Reader)
	if err != nil {
		return nil, err
	}
	return uncompressedWriter, nil
}
```

kubelet-config 解码后如下
```json
{"kubeletconfig":{"enableServer":true,"staticPodPath":"/etc/kubernetes/manifests","podLogsDir":"/var/log/pods","syncFrequency":"1m0s","fileCheckFrequency":"20s","httpCheckFrequency":"20s","address":"0.0.0.0","port":10250,"tlsCertFile":"/var/lib/kubelet/pki/kubelet.crt","tlsPrivateKeyFile":"/var/lib/kubelet/pki/kubelet.key","rotateCertificates":true,"authentication":{"x509":{"clientCAFile":"/etc/kubernetes/pki/ca.crt"},"webhook":{"enabled":true,"cacheTTL":"2m0s"},"anonymous":{"enabled":false}},"authorization":{"mode":"Webhook","webhook":{"cacheAuthorizedTTL":"5m0s","cacheUnauthorizedTTL":"30s"}},"registryPullQPS":5,"registryBurst":10,"eventRecordQPS":50,"eventBurst":100,"enableDebuggingHandlers":true,"healthzPort":10248,"healthzBindAddress":"127.0.0.1","oomScoreAdj":-999,"clusterDomain":"cluster.local","clusterDNS":["10.96.0.10"],"streamingConnectionIdleTimeout":"4h0m0s","nodeStatusUpdateFrequency":"10s","nodeStatusReportFrequency":"5m0s","nodeLeaseDurationSeconds":40,"imageMinimumGCAge":"2m0s","imageMaximumGCAge":"0s","imageGCHighThresholdPercent":85,"imageGCLowThresholdPercent":80,"volumeStatsAggPeriod":"1m0s","cgroupsPerQOS":true,"cgroupDriver":"systemd","cpuManagerPolicy":"none","cpuManagerReconcilePeriod":"10s","memoryManagerPolicy":"None","topologyManagerPolicy":"none","topologyManagerScope":"container","runtimeRequestTimeout":"2m0s","hairpinMode":"promiscuous-bridge","maxPods":110,"podPidsLimit":-1,"resolvConf":"/etc/resolv.conf","cpuCFSQuota":true,"cpuCFSQuotaPeriod":"100ms","nodeStatusMaxImages":50,"maxOpenFiles":1000000,"contentType":"application/vnd.kubernetes.protobuf","kubeAPIQPS":50,"kubeAPIBurst":100,"serializeImagePulls":true,"evictionHard":{"imagefs.available":"15%","imagefs.inodesFree":"5%","memory.available":"100Mi","nodefs.available":"10%","nodefs.inodesFree":"5%"},"evictionPressureTransitionPeriod":"5m0s","enableControllerAttachDetach":true,"makeIPTablesUtilChains":true,"iptablesMasqueradeBit":14,"iptablesDropBit":15,"failSwapOn":true,"memorySwap":{},"containerLogMaxSize":"10Mi","containerLogMaxFiles":5,"containerLogMaxWorkers":1,"containerLogMonitorInterval":"10s","configMapAndSecretChangeDetectionStrategy":"Watch","enforceNodeAllocatable":["pods"],"volumePluginDir":"/usr/libexec/kubernetes/kubelet-plugins/volume/exec/","logging":{"format":"text","flushFrequency":"5s","verbosity":0,"options":{"text":{"infoBufferSize":"0"},"json":{"infoBufferSize":"0"}}},"enableSystemLogHandler":true,"enableSystemLogQuery":false,"shutdownGracePeriod":"0s","shutdownGracePeriodCriticalPods":"0s","enableProfilingHandler":true,"enableDebugFlagsHandler":true,"seccompDefault":false,"memoryThrottlingFactor":0.9,"registerNode":true,"localStorageCapacityIsolation":true,"containerRuntimeEndpoint":"unix:///var/run/cri-dockerd.sock","failCgroupV1":false}}
```

node-config 解码后如下
```yaml
---
node:
  apiserver:
    confs:
      - /etc/kubernetes/manifests/kube-apiserver.yaml
      - /etc/kubernetes/manifests/kube-apiserver.yml
      - /etc/kubernetes/manifests/kube-apiserver.manifest
      - /var/snap/kube-apiserver/current/args
      - /var/snap/microk8s/current/args/kube-apiserver
      - /etc/origin/master/master-config.yaml
      - /etc/kubernetes/manifests/talos-kube-apiserver.yaml
      - /var/lib/rancher/rke2/agent/pod-manifests/kube-apiserver.yaml
    defaultconf: /etc/kubernetes/manifests/kube-apiserver.yaml
  controllermanager:
    confs:
      - /etc/kubernetes/manifests/kube-controller-manager.yaml
      - /etc/kubernetes/manifests/kube-controller-manager.yml
      - /etc/kubernetes/manifests/kube-controller-manager.manifest
      - /var/snap/kube-controller-manager/current/args
      - /var/snap/microk8s/current/args/kube-controller-manager
      - /etc/kubernetes/manifests/talos-kube-controller-manager.yaml
      - /var/lib/rancher/rke2/agent/pod-manifests/kube-controller-manager.yaml
    defaultconf: /etc/kubernetes/manifests/kube-controller-manager.yaml
    kubeconfig:
      - /etc/kubernetes/controller-manager.conf
      - /var/lib/kube-controller-manager/kubeconfig
      - /system/secrets/kubernetes/kube-controller-manager/kubeconfig
    defaultkubeconfig: /etc/kubernetes/controller-manager.conf
  scheduler:
    confs:
      - /etc/kubernetes/manifests/kube-scheduler.yaml
      - /etc/kubernetes/manifests/kube-scheduler.yml
      - /etc/kubernetes/manifests/kube-scheduler.manifest
      - /var/snap/kube-scheduler/current/args
      - /var/snap/microk8s/current/args/kube-scheduler
      - /etc/origin/master/scheduler.json
      - /etc/kubernetes/manifests/talos-kube-scheduler.yaml
      - /var/lib/rancher/rke2/agent/pod-manifests/kube-scheduler.yaml
    defaultconf: /etc/kubernetes/manifests/kube-scheduler.yaml
    kubeconfig:
      - /etc/kubernetes/scheduler.conf
      - /var/lib/kube-scheduler/kubeconfig
      - /var/lib/kube-scheduler/config.yaml
      - /system/secrets/kubernetes/kube-scheduler/kubeconfig
    defaultkubeconfig: /etc/kubernetes/scheduler.conf
  etcd:
    datadirs:
      - /var/lib/etcd/default.etcd
      - /var/lib/etcd/data.etcd
    confs:
      - /etc/kubernetes/manifests/etcd.yaml
      - /etc/kubernetes/manifests/etcd.yml
      - /etc/kubernetes/manifests/etcd.manifest
      - /etc/etcd/etcd.conf
      - /var/snap/etcd/common/etcd.conf.yml
      - /var/snap/etcd/common/etcd.conf.yaml
      - /var/snap/microk8s/current/args/etcd
      - /usr/lib/systemd/system/etcd.service
      - /var/lib/rancher/rke2/agent/pod-manifests/etcd.yaml
      - /var/lib/rancher/k3s/server/db/etcd/config
    defaultconf: /etc/kubernetes/manifests/etcd.yaml
    defaultdatadir: /var/lib/etcd/default.etcd
  flanneld:
    defaultconf: /etc/sysconfig/flanneld
  kubernetes:
    defaultconf: /etc/kubernetes/config
  kubelet:
    cafile:
      - /etc/kubernetes/pki/ca.crt
      - /etc/kubernetes/certs/ca.crt
      - /etc/kubernetes/cert/ca.pem
      - /var/snap/microk8s/current/certs/ca.crt
      - /var/lib/rancher/rke2/agent/server.crt
      - /var/lib/rancher/rke2/agent/client-ca.crt
      - /var/lib/rancher/k3s/agent/client-ca.crt
    svc:
      - /etc/systemd/system/kubelet.service.d/10-kubeadm.conf
      - /etc/systemd/system/kubelet.service
      - /lib/systemd/system/kubelet.service
      - /etc/systemd/system/snap.kubelet.daemon.service
      - /etc/systemd/system/snap.microk8s.daemon-kubelet.service
      - /etc/systemd/system/atomic-openshift-node.service
      - /etc/systemd/system/origin-node.service
    bins:
      - hyperkube kubelet
      - kubelet
    kubeconfig:
      - /etc/kubernetes/kubelet.conf
      - /etc/kubernetes/kubelet-kubeconfig.conf
      - /var/lib/kubelet/kubeconfig
      - /etc/kubernetes/kubelet-kubeconfig
      - /etc/kubernetes/kubelet/kubeconfig
      - /etc/kubernetes/ssl/kubecfg-kube-node.yaml
      - /var/snap/microk8s/current/credentials/kubelet.config
      - /etc/kubernetes/kubeconfig-kubelet
      - /var/lib/rancher/rke2/agent/kubelet.kubeconfig
      - /var/lib/rancher/k3s/server/cred/admin.kubeconfig
      - /var/lib/rancher/k3s/agent/kubelet.kubeconfig
    confs:
      - /etc/kubernetes/kubelet-config.yaml
      - /var/lib/kubelet/config.yaml
      - /var/lib/kubelet/config.yml
      - /etc/kubernetes/kubelet/kubelet-config.json
      - /etc/kubernetes/kubelet/config
      - /home/kubernetes/kubelet-config.yaml
      - /home/kubernetes/kubelet-config.yml
      - /etc/default/kubeletconfig.json
      - /etc/default/kubelet
      - /var/lib/kubelet/kubeconfig
      - /var/snap/kubelet/current/args
      - /var/snap/microk8s/current/args/kubelet
      - /etc/systemd/system/kubelet.service.d/10-kubeadm.conf
      - /etc/systemd/system/kubelet.service
      - /lib/systemd/system/kubelet.service
      - /etc/systemd/system/snap.kubelet.daemon.service
      - /etc/systemd/system/snap.microk8s.daemon-kubelet.service
      - /etc/kubernetes/kubelet.yaml
      - /var/lib/rancher/rke2/agent/kubelet.kubeconfig
    defaultconf: /var/lib/kubelet/config.yaml
    defaultsvc: /etc/systemd/system/kubelet.service.d/10-kubeadm.conf
    defaultkubeconfig: /etc/kubernetes/kubelet.conf
    defaultcafile: /etc/kubernetes/pki/ca.crt
  proxy:
    bins:
      - kube-proxy
      - hyperkube proxy
      - hyperkube kube-proxy
      - proxy
      - openshift start network
    confs:
      - /etc/kubernetes/proxy
      - /etc/kubernetes/addons/kube-proxy-daemonset.yaml
      - /etc/kubernetes/addons/kube-proxy-daemonset.yml
      - /var/snap/kube-proxy/current/args
      - /var/snap/microk8s/current/args/kube-proxy
    kubeconfig:
      - /etc/kubernetes/kubelet-kubeconfig
      - /etc/kubernetes/kubelet-kubeconfig.conf
      - /etc/kubernetes/kubelet/config
      - /etc/kubernetes/ssl/kubecfg-kube-proxy.yaml
      - /var/lib/kubelet/kubeconfig
      - /var/snap/microk8s/current/credentials/proxy.config
      - /var/lib/rancher/rke2/agent/kubeproxy.kubeconfig
      - /var/lib/rancher/k3s/agent/kubeproxy.kubeconfig
    svc:
      - /lib/systemd/system/kube-proxy.service
      - /etc/systemd/system/snap.microk8s.daemon-proxy.service
    defaultconf: /etc/kubernetes/addons/kube-proxy-daemonset.yaml
    defaultkubeconfig: /etc/kubernetes/proxy.conf
```

kubelet-config-mapping 解码后如下
```yaml
## this file repesent node kubelet-config api mapping param to the collector config params
## example kubectl get --raw "/api/v1/nodes/<node name>/proxy/configz"
---
kubeletAnonymousAuthArgumentSet: kubeletconfig.authentication.anonymous.enabled
kubeletAuthorizationModeArgumentSet: kubeletconfig.authorization.mode
kubeletClientCaFileArgumentSet: kubeletconfig.authentication.x509.clientCAFile
kubeletReadOnlyPortArgumentSet: kubeletconfig.readOnlyPort
kubeletStreamingConnectionIdleTimeoutArgumentSet: kubeletconfig.streamingConnectionIdleTimeout
kubeletProtectKernelDefaultsArgumentSet: kubeletconfig.protectKernelDefaults
kubeletMakeIptablesUtilChainsArgumentSet: kubeletconfig.makeIPTablesUtilChains
kubeletEventQpsArgumentSet: kubeletconfig.eventRecordQPS",
kubeletRotateKubeletServerCertificateArgumentSet: kubeletconfig.featureGates.RotateKubeletServerCertificate
kubeletRotateCertificatesArgumentSet: kubeletconfig.rotateCertificates
kubeletTlsCertFileTlsArgumentSet: kubeletconfig.tlsCertFile
kubeletTlsPrivateKeyFileArgumentSet: kubeletconfig.tlsPrivateKeyFile
kubeletOnlyUseStrongCryptographic: kubeletconfig.tlsCipherSuites
```

node-commands 解码后如下,对应test.yaml 中的命令部分
```yaml
commands:
    - audit: stat -c %a $apiserver.confs
      id: CCMD-0001
      key: TestKey
      nodeType: master
      platforms:
        - k8s
        - rke2
      title: API server pod specification file permissions
```

使用docker 模拟运行，获取结果：

```bash
# 找个pod获取其挂载的servicaccount token和ca.crt
# /var/run/secrets/kubernetes.io/serviceaccount/token

echo "eyJhbGciOiJSUzI1NiIsImtpZCI6IlFaS2t2ZHpmblZkbFhxczFtdTVmTXRLMDFFaDYwR3dnMFFFMUlUZVJwOUkifQ.eyJhdWQiOlsiaHR0cHM6Ly9rdWJlcm5ldGVzLmRlZmF1bHQuc3ZjLmNsdXN0ZXIubG9jYWwiXSwiZXhwIjoxNzkzMTUwODY4LCJpYXQiOjE3NjE2MTQ4NjgsImlzcyI6Imh0dHBzOi8va3ViZXJuZXRlcy5kZWZhdWx0LnN2Yy5jbHVzdGVyLmxvY2FsIiwianRpIjoiMjIxZDQwN2EtMGM3NC00N2MzLWE1OTctMjIwMTdkYjY3Y2M1Iiwia3ViZXJuZXRlcy5pbyI6eyJuYW1lc3BhY2UiOiJrdWJlLXN5c3RlbSIsIm5vZGUiOnsibmFtZSI6InNsZHc5M2R3bTI5IiwidWlkIjoiOWE3ZTA1OWItNWNhNi00NjgxLTgzOTEtZmM3YmNjN2I3NmQ5In0sInBvZCI6eyJuYW1lIjoieGNsb3VkLWN1c3RvbW5zLWFwaS01ZDc4YzY5Nzk5LTd2bDVzIiwidWlkIjoiNmQ1YzYzZGMtMmNmMS00NzJmLWI1NDQtZDhjNjA5NjNmYTdjIn0sInNlcnZpY2VhY2NvdW50Ijp7Im5hbWUiOiJ4Y2xvdWQtY3VzdG9tbnMtYXBpIiwidWlkIjoiNzU2NmViZjYtZTk1Zi00NzY5LTg3YmItMGRhY2ZiYmJjMWVmIn0sIndhcm5hZnRlciI6MTc2MTYxODQ3NX0sIm5iZiI6MTc2MTYxNDg2OCwic3ViIjoic3lzdGVtOnNlcnZpY2VhY2NvdW50Omt1YmUtc3lzdGVtOnhjbG91ZC1jdXN0b21ucy1hcGkifQ.s_7R0XlLsSk59QBsQCfU_2GlT_79C0uHZCAV0Hvs-BO14w6i70DD1eoEmJw6ZzjJd3S2TakEQsd-OWioqrImDtf_LfSQgJf9q-h7UP-Lk4TRXspblOHUDBTKkAzCPeM2u1aQv5DEBOFq3r4ZyQ-7g-xcAOCtOtIGsB_fj1IL8tHpbpTly1dB891adTT5ecl9fjF84X_FnceNFhhwHn0iv9_03z9Wf0J3U0ibk_jP8NAPVNPCHMggffdIjxWp1pM_Cp90PrZ38SXfoRXwrdSJShtzNe-WSfYovLENB_YsNNUXHIcoFQiGXIxVSbn06NBJPx2DOyIkOGTp9PzWDCOR_g" > /tmp/empty-token

echo "-----BEGIN CERTIFICATE-----
MIIDBTCCAe2gAwIBAgIIJER2FXhyiNkwDQYJKoZIhvcNAQELBQAwFTETMBEGA1UE
AxMKa3ViZXJuZXRlczAeFw0yNDA5MDUwODA1MDhaFw0zNDA5MDMwODEwMDhaMBUx
EzARBgNVBAMTCmt1YmVybmV0ZXMwggEiMA0GCSqGSIb3DQEBAQUAA4IBDwAwggEK
AoIBAQC5CX9XU9pjF9U8TehXnlNkc0gsR1gpn0nx+pRK7gkhLIYXjeAhmq0HwsEw
YS1LOdLVAaAcKudN6X8rbzXO93/+cmdbvjqfxnL4Lkvr2doIs28Ek2i0GC8nS3Y3
zv5hZJ4HwlCmsBpRCUU8dFRNLn+WLMgYEyLSDy/WZMRSNpeEu/5OL2jcSYd8nJiB
tmNWACEl20GB9IiV2s7s6sc/LrWz9LAipeM8bIhntyWkzq/21pUaj4jXyQz1JoON
6zn3MrGqL+z8lmRVD/nhCEa1MRncqFyjylZzCjskGrHv1FvfsupfSa0pt+/puq9M
ci//T85mX6ZyONCWGKBhqWjj1uyTAgMBAAGjWTBXMA4GA1UdDwEB/wQEAwICpDAP
BgNVHRMBAf8EBTADAQH/MB0GA1UdDgQWBBQUGR6eBP7Qr+5d6+YoQbK4/8NHEzAV
BgNVHREEDjAMggprdWJlcm5ldGVzMA0GCSqGSIb3DQEBCwUAA4IBAQBcX2G66IFv
oVn2iTYWzdD7nNDKJ+YNQk9rXxCRSzYl10sp0tVN9H2h1NmDQEtyLsdte2aeFji1
nEIgefdRDhydNfXgsZCF0WjBJYgbpB0khiEAFJs6GfbWLiZOp7Y1BohqdHWhYKpr
AOTOJRewiyE3qhXyq4bRl7arGUvHESGJW140x8LE7ndhFJsSgD/2aRxovEzikjnG
STrgdZaeXk203RveQSxgp7l9VCklyG5Llh5cDvF48da0x/x0Oe7m6odRWhxbVoXO
IiDMoQaDrJnTzFnNc9VjXsHxkDkKJ95FcWj2Q2HuKoKB1he2Jg7piDbAafromSQv
T8C+IEUsNFIN
-----END CERTIFICATE-----" > /tmp/empty-token-ca.crt

docker run -it --rm  \
-v /tmp/empty-token:/var/run/secrets/kubernetes.io/serviceaccount/token \
-v /tmp/empty-token-ca.crt:/var/run/secrets/kubernetes.io/serviceaccount/ca.crt \
-e KUBERNETES_SERVICE_HOST=10.122.196.159 \
-e KUBERNETES_SERVICE_PORT=6443 \
registry-dev.xcloud.lenovo.com:18083/aquasecurity/node-collector:0.3.1  \
k8s \
--kubelet-config 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 \
--node-config QlpoNjFBWSZTWRr5nQYAAiVZgFAQQAP4UD//3+BQBSt3ve973ve973ve973ve973ve973ve973hEUgSj9TTGVNqaqfvUqb1PU/QRIgp6pqeINKp+1U/Kn6p+VH+qgRIlPQptVVP/09E1VT/8Kqn/6qpv1T/VT/VQESIp6CKbaaqqf+qo/9VT/1VD/1VAwRKap5EMgypnqqn/lVH+VR/tVQwogd/Y48V8znO5/ltsyth9fyzHrGMrTTOENVut40ZhISEh/cW4LNaN5sc7uy79DGsTBM1LaqSs23MUVMV+p/qvnrJmisabZmbOvRAEelBCnaBJIMiyBISMgySSBIyCEjIoFBA0ksYqpRVvIKMxcDJ6xom71NycuYY7GoPULlt+oOILjvNaNlbo9KM1+gxDb1clw2Zo1yV/jmWnfNaKhoXRpHRqtbKum0xeMPbSsnKnHK36ZPchINqeb/pLojlhU1CiqIcSrQxcP8diAcq1Lc4Hc/Ay7ZnNMDiDJiBlVhq1rfZc+5CGRCCR0WubpLCZPQCk7SQUNVHjhQrqdEOaMnQI8F2hRMmLKSwCjlupsRK0CKYcKJ8fjuh7QON+bz2nFQgalclN9mCBVFY8VQ6nDR4a2AwUD7Ru7HVR8I9BYo7GETgDz8ETop0yd3HVQu4r/UUT0XUQDZ+2xI55CmYBb6nur2FsP4roDNwLgURKhUb6XCSSZwBqOMEQ6U4NgdVsXsHH8FIYc0vQBM4Td155r9eAoLV4MD00rwj+CJGnQ4Q1qXADwfT/K3UNy4Ke/AgagU4NgfkhBNjUvxv0gOITFlttktttoqiiqrql3Ji0JjGOM0iPh7Au0R+lHkK2SQH8EA8SEAPN9UR+yAPdQ6UeSwU+G21jkB5IKZQY7KaRepmZu5qaCv+2AIDY1UdzsCmjDfENjk5Q5dfdPgGoZEcB5gEgSdyBYMiRhohJRGmNH5D2DODFUpkjZFC4qM3UD8Oh5PB67gwWWCmor5OEfSZUM/GCHoHr6DduEgSBIhgA2cNoYzA9SEkkkBhG5hO5GyayQIcke6JBfJuiPfRBDJF9n94diPQAIj+A4HEH6Pn4Oz3WkEPVppHx39n7+XqIe6J34O7aGg6zapAo7FBdKjgR6UpQBHvwL6eRYZU4DCHhBcA+0exD7F3wueFX0nN+NPx6FkpC9JIkiVbhlJRYhxEwRUsNCGGfI++p47ME8cYO0gySeQDSeTCJ9vmj8BzggfDap+zxpQL7/UKISU1R97lgVE6kALUxGkhEuU1Frd06sQDMRIBJSIUiOSwzSOC4Jcje36iie1clDgXmomTmC9fIh9CHCgenRQP8LuSKcKEgNfM6DA== \
--kubelet-config-mapping QlpoNjFBWSZTWR3xl14AABrfgAAQWAfiNS+q/gA/79/wQAHrd3d3d3d3CRTRGkn6p6mj9Uaqn+0aBVP8VH+lR+MlT/Kp/6qgkRJU/01Tw1VVT/9hVVH/6qp//6qqn/+hVUf/6qqb/9KqH/qqA//1VU/9mqqglBE1TaMVVP/zVVT/9DRVT/9Kqf+qp/7VVP/aqp/+iqn/qqf/qqj/1VN/qp/gkkTEp4BMm0qqn//qqqB/+qqf/tVVN/+lVH/qqH/6qp/6qh/5VRwjD3+Jj4sylEco3x/Ww/Jnahfcq1Jca8NN95l+m9yKZzhvotphS0nGPG3zy7euPrVI3f38d5/pLtktuHCUxHMR4TRxrcm9u0i8VhQVuw2vmg2kIqHddWSX9g9yeSkZW/IRMzjq2UCb728bV/jcuKDDumOW7cyytoJLwXqlPq+XZC16gMTL6RuN3oVfe4H3OKQyvBAdqKnlnOMDY4/xuSShLpbqbGoK4ypx/h1E1K0uWw6ZtEEUESvlsMB7AuAIsyiTJ2+QKq7AZXjJjHYHl4wOAGPqcy4I6niYCyy87BQzP1CaFjmdg10NbB69qohL2zv16mx3Oiv1vFAWhBTwQWFnXE5FADFP0mYee9v2RSiBIs47jRXnIRQCuZEjDA8FGSKUm4a0bbiqRd37e+Z62KR59VUs1MdwWhEsIRyg0CAE8511aMs60pHlRokaO09kYsSlEoGQbSShtgwTVtAhC5gQPNmPuxsqWDIwXsN5KuU/ng1K6AmYoBBzgCXWhvgi85n2+ZRc/96YsS8lVSfhdyRThQkB3xl14A== \
--node-commands QlpoNjFBWSZTWSiA9tIAADXfgFQQRgNwUCwqRAAvL98gIACKhqepM1T9TymgVU/8qp/6qn/lVM/9VR/qp/gqhFT3qI9E9Sqn/tNVU//VVH/6qp/+qqb/00VQ/9Kp/+kkAKdXfd4TmEAEGAG/HiQx6MavZvWbjHMcWKu0G5kQSYjArX7c2+mtsdMPFTliFvPXMW+1GLRnGSFSVX3ZK/3ukZM+t8ra2o8/yJmT2VK0oxNK3uzR2gS5B5TmJ7oA8ITXfgSNES1Kfwu5IpwoSBRAe2kA
```

获取输出如下
```json
{
    "apiVersion": "v1",
    "kind": "NodeInfo",
    "metadata": {
        "creationTimestamp": "2025-10-28T03:49:36Z"
    },
    "type": "worker",
    "info": {
        "TestKey": {
            "values": [

            ]
        },
        "kubeletAnonymousAuthArgumentSet": {
            "values": [
                "false"
            ]
        },
        "kubeletAuthorizationModeArgumentSet": {
            "values": [
                "Webhook"
            ]
        },
        "kubeletClientCaFileArgumentSet": {
            "values": [
                "/etc/kubernetes/pki/ca.crt"
            ]
        },
        "kubeletMakeIptablesUtilChainsArgumentSet": {
            "values": [
                "true"
            ]
        },
        "kubeletRotateCertificatesArgumentSet": {
            "values": [
                "true"
            ]
        },
        "kubeletStreamingConnectionIdleTimeoutArgumentSet": {
            "values": [
                "4h0m0s"
            ]
        },
        "kubeletTlsCertFileTlsArgumentSet": {
            "values": [
                "/var/lib/kubelet/pki/kubelet.crt"
            ]
        },
        "kubeletTlsPrivateKeyFileArgumentSet": {
            "values": [
                "/var/lib/kubelet/pki/kubelet.key"
            ]
        }
    }
}
```