# otusproject-clusterbootstrap

Проект разворачивает management кластер kubernetes в yandex cloud использую terraform
Кластер состоит из следующих компонентов:


- **cert-manager-webhook-yandex** - создает сертефикаты для  доменов с использованием letscrypt
- **externaldns** - регестриует доменные имена третьяего уровня через yandex cloud dns
- **nginx-ingress-controller** - ingress контролер, предназначен для получения трафика к кластерс использованием yandex lb
- **kube-prometheus** система сбора метрик и алертирования. Отправляет алерты в телеграм
- **loki** - Храние логов   
- **promtail** - сбор логов
- **grafana** -дашборды для логов и метрик
*Доступен по адресу https://grafana.evgsh.space*
Username: admin \
Узнать пароль: 
```
 kubectl get secret --namespace infra grafana -o jsonpath="{.data.admin-password}" | base64 --decode ; echo
```
- **jaeger**  - трейсинг
  *адрес https://jaeger.evgsh.space* 
- **argocd**
  *адрес https://argocd.evgsh.space* 
  Username: admin \
  Узнать пароль:
```
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
```

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
Argocd настроен на установку helm-chart из https://github.com/evgsh123/otusproject-apps-cd

Репозитарии приложений
- https://github.com/evgsh123/otusproject-boutique-frontend
- https://github.com/evgsh123/otusproject-boutique-shippingservice
- https://github.com/evgsh123/otusproject-boutique-cartservice
- https://github.com/evgsh123/otusproject-boutique-checkoutservice
- https://github.com/evgsh123/otusproject-boutique-currencyservice
- https://github.com/evgsh123/otusproject-boutique-emailservice
- https://github.com/evgsh123/otusproject-boutique-paymentservice
- https://github.com/evgsh123/otusproject-boutique-productcatalogservice
- https://github.com/evgsh123/otusproject-boutique-recommendationservice    
- https://github.com/evgsh123/otusproject-boutique-loadgenerator

Стейдж приложений: https://stage.evgsh.space \
Прод приложний: https://shop.evgsh.space 
CI приложений настроен так, что после сборки и пуша докер образа в regestry создается коммит и пуш в CD репозиторий откуда уже argocd подтягивает измнения и выкатывает их на нужную среду stage/prod
Измнения на стейдж применяеются при любом изменении репозитария.
Изминение на прод применяют при создании релиза с тэгом

Авторизоваться в кластере через yc:
```
yc k8s cluster get-credentials --id $(yc k8s cluster list  | grep 'RUNNING' | awk -F '|' '{print $2}')  --external --force
```
