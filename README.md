# otusproject-clusterbootstrap

Получить доступ к кластеру yc k8s cluster get-credentials --id $(yc k8s cluster list  | grep 'RUNNING' | awk -F '|' '{print $2}')  --external --force

Argocd: argocd.evgsh.space
Username: admin
Узнать пароль: kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
