# otusproject-clusterbootstrap

Получить доступ к кластеру:
```
 yc k8s cluster get-credentials --id $(yc k8s cluster list  | grep 'RUNNING' | awk -F '|' '{print $2}')  --external --force
```

Argocd: https://argocd.evgsh.space \
Username: admin \
Узнать пароль:
```
 kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
```

Grafana: https://grafana.evgsh.space \
Username: admin \
Узнать пароль: 
```
 kubectl get secret --namespace infra grafana -o jsonpath="{.data.admin-password}" | base64 --decode ; echo
```
jaeger: https://jaeger.evgsh.space \

\
Стейдж приложение: https://stage.evgsh.space \
Прод приложние: https://shop.evgsh.space \


