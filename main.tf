provider "google" {
  project = "project_ts"
  region = var.region
}

module "wordpress_ssl" {
  name        = "wordpress-ssl"
  description = "Certificato SSL Wordpress"
  domains     = "t3stwordpress.com"
}

module "wordpress_forwarding_rule" {
  name        = "wordpress-forwarding-rule"
  description = "Load balancer Wordpress"

  ip_address   = google_compute_global_address.wordpress_address.address
  port_range   = "80-80"
  target       = google_compute_backend_service.wordpress_backend.self_link
  protocol     = "TCP"
  ssl_certificates = [google_compute_managed_ssl_certificate.wordpress_ssl.self_link]
}

module "wordpress_address" {
  name        = "wordpress-address"
  description = "Global IP per LB Wordpress"
}

module "wordpress_health_check" {
  name = "wordpress-health-check"
  check_interval_sec = 1
  timeout_sec        = 1
  tcp_health_check {
    port_name = "http"
  }
}

module "http_firewall" {
  name    = "http-firewall"
  network = "default"

  allow {
    protocol = "tcp"
    ports    = "80"
  }
  source_ranges = ["0.0.0.0/0"]
}

module "primary" {
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

module "policy" {
  name        = "my-policy"
  description = "basic security policy"
  type        = "CLOUD_ARMOR"

  recaptcha_options_config {
    redirect_site_key = google_recaptcha_enterprise_key.primary.name
  }
}

module "wordpress_mig" {
  name               = "wordpress"
  base_instance_name = "wordpress"
  instance_template  = google_compute_instance_template.template_wordpress
  target_size        = 1
  version            = "latest"
  zones = [
    "us-central1-a",
    "eu-west1-a",
    "asia-east1-a"
  ]

named_ports {
    name = "http"
    port = 80
  }

  auto_healing_policies {
    health_check {
      self_link = [google_compute_http_health_check.wordpress_health_check.self_link]
    }
  }
  update_policy {
    type = "PROACTIVE"
    minimal_action {
      replacement_method = "REPLACE_VM"
    }
  }

  autoscaling_policy {
    min_num_replicas = 1
    max_num_replicas = 3
    cpu_utilization {
      target = 0.6
  }
}

module "wordpress_health_check" {
  name = "wordpress-health-check"
  request_path = "/"
  port = 80
}

module "template_wordpress" {
  
  name_prefix  = "vm-Wordpress-"
  machine_type = "e2-highmem-4"

  disk {
    source_image = "debian-cloud/debian-11"
    auto_delete  = true
    disk_size_gb = 100
    boot         = true
  }

  network_interface {
    network = "default"
  }
    metadata_startup_script = <<-EOF
      sudo apt-get update
      sudo apt-get install -y apache2 php php-mysql
      wget https://wordpress.org/wordpress-${var.wordpress_version}.tar.gz
      tar -xvf wordpress-${var.wordpress_version}.tar.gz
      sudo mv wordpress /var/www/html/
      sudo chown -R www-data:www-data /var/www/html/wordpress
      sudo chmod -R 775 /var/www/html/wordpress
      
      "startup-script-url" = "https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar"
      "wordpress-db-user" = "root"
      "wordpress-db-password" = "password123"
      "wordpress-db-name" = "wordpress_db"
      "wordpress-version" = var.wordpress_version
      echo "ServerName $(hostname)" >> /etc/apache2/apache2.conf
      a2enmod rewrite
      service apache2 restart
      EOF
  }
}

