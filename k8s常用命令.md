##### kubectl get

```
#获取类型为Deployment的资源列表
kubectl get deployments --all-namespaces
kubectl get deployments -A
#指定命名空间
kubectl get deployments -n default

#获取类型为pod的资源列表 -A -n
kubectl get pods

#获取类型为node的资源列表 -A -n
kubectl get nodes
```



##### kubectl describe

```
# kubectl describe 资源类型 资源名称

#查看名称为XXX的Pod的信息
kubectl describe pod XXX	

#查看名称为XXX的Deployment的信息
kubectl describe deployment XXX	
```



##### kubectl logs

```
# kubectl logs Pod名称
#和dockerlogs类似

kubectl logs -f XXX
```



