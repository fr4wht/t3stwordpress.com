# cert SSL google managed
resource "google_compute_managed_ssl_certificate" "wordpress_ssl" {
  name        = "wordpress-ssl"
  description = "Certificato SSL Wordpress"
  domains     = "t3stwordpress.com"
}

# crea il LB
resource "google_compute_global_forwarding_rule" "wordpress_forwarding_rule" {
  name        = "wordpress-forwarding-rule"
  description = "Load balancer Wordpress"
  ip_address   = google_compute_global_address.wordpress_address.address
  port_range   = var.port_range
  target       = google_compute_backend_service.wordpress_backend.self_link
  protocol     = var.protocol
  ssl_certificates = [google_compute_managed_ssl_certificate.wordpress_ssl.self_link]
}

# crea global IP per LB
resource "google_compute_global_address" "wordpress_address" {
  name        = "wordpress-address"
  description = "Global IP per LB Wordpress"
}

# health check per LB
resource "google_compute_health_check" "wordpress_health_check" {
  name               = "wordpress-health-check"
  check_interval_sec = 1
  timeout_sec        = 1
  tcp_health_check {
    port_name = "http"
  }
}

# backend per LB
resource "google_compute_backend_service" "wordpress_backend" {
  name        = "wordpress-backend"
  description = "Backend per il load balancer di Wordpress"

  backend {
    group = google_compute_instance_group.wordpress_group.self_link
  }

  health_checks = ["${google_compute_health_check.wordpress_health_check.self_link}"]
  port_name     = "http"
  protocol      = "HTTP"
}

# fw
resource "google_compute_firewall" "http_firewall" {
  name    = "http-firewall"
  network = "default"

  allow {
    protocol = "tcp"
    ports    = "80"
  }
  source_ranges = ["0.0.0.0/0"]
}

# cloud armor
resource "google_recaptcha_enterprise_key" "primary" {
  display_name = "recaptcha"

  labels = {
    label-one = "value-one"
}

  project = "project_ts"

  web_settings {
    integration_type  = "INVISIBLE"
    allow_all_domains = true
    allowed_domains   = "t3stwordpress.com"
  }
}

resource "google_compute_security_policy" "policy" {
  name        = "my-policy"
  description = "basic security policy"
  type        = "CLOUD_ARMOR"

  recaptcha_options_config {
    redirect_site_key = google_recaptcha_enterprise_key.primary.name
  }
}