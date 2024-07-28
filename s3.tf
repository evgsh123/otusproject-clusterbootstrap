resource "yandex_iam_service_account_static_access_key" "s3" {
 service_account_id = yandex_iam_service_account_key.sa-auth-key.service_account_id
 description        = "s3"
}

resource "yandex_storage_bucket" "monitoring-loki-chunks" {
  access_key = yandex_iam_service_account_static_access_key.s3.access_key
  secret_key = yandex_iam_service_account_static_access_key.s3.secret_key
  bucket = "monitoring-loki-chunks"
  force_destroy = true
}
resource "yandex_storage_bucket" "monitoring-loki-ruler" {
  access_key = yandex_iam_service_account_static_access_key.s3.access_key
  secret_key = yandex_iam_service_account_static_access_key.s3.secret_key
  bucket = "monitoring-loki-ruler"
  force_destroy = true
}
resource "yandex_storage_bucket" "monitoring-loki-admin" {
  access_key = yandex_iam_service_account_static_access_key.s3.access_key
  secret_key = yandex_iam_service_account_static_access_key.s3.secret_key
  bucket = "monitoring-loki-admin"
  force_destroy = true
}
