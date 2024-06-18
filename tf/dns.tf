resource "yandex_dns_zone" "evgsh" {

  zone             = "evgsh.space."
  public           = true
  deletion_protection = true
}

resource "yandex_dns_recordset" "rs1" {
  zone_id = yandex_dns_zone.evgsh.id
  name    = "kube-api"
  type    = "A"
  ttl     = 10
  data    = ["${[for s in yandex_lb_network_load_balancer.cplb.listener: s.external_address_spec.*.address].0[0]}"]
}
