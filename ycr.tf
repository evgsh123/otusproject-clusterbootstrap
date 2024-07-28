resource "yandex_container_registry" "otus" {
  name      = "otus"
  folder_id = "${var.folder_id}"
}

resource "yandex_container_repository" "otusproject" {
  name = "${yandex_container_registry.otus.id}/otusproject"
}

resource "yandex_container_repository_iam_binding" "pusher" {
  repository_id = yandex_container_repository.otusproject.id
  role        = "container-registry.images.pusher"

  members = [
    "serviceAccount:${yandex_iam_service_account.otus-sa.id}",
  ]
}

resource "local_file" "ycr_conf" {
  content  = "${yandex_container_registry.otus.id}"
  filename = "${path.module}/out/ycr.conf"
}

