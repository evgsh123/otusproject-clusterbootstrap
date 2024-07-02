resource "yandex_dns_zone" "evgsh" {

  zone             = "evgsh.space."
  public           = true
  deletion_protection = true
}

