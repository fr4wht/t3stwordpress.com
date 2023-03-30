# crea gruppo di MIG 
resource "google_compute_instance_group_manager" "wordpress_mig" {
  name               = "wordpress"
  base_instance_name = "wordpress"
  instance_template  = google_compute_instance_template.template_wordpress
  target_size        = var.min_size
  version            = var.wordpress_version
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

  # Configura l'autoscaler
  autoscaling_policy {
    min_num_replicas = var.min_size
    max_num_replicas = var.max_size
    cpu_utilization {
      target = var.target_cpu_utilization
  }
}

# health check Wordpress
resource "google_compute_http_health_check" "wordpress_health_check" {
  name = "wordpress-health-check"
  request_path = "/"
  port = 80
}

# template della MIG
resource "google_compute_instance_template" "template_wordpress" {
  
  name_prefix  = "vm-Wordpress-"
  machine_type = var.machine_type

  disk {
    source_image = "debian-cloud/debian-11"
    auto_delete  = true
    disk_size_gb = var.disk_size_gb
    boot         = true
  }

  network_interface {
    network = "default"
  }
    metadata_startup_script = <<-EOF
      sudo apt-get update
      sudo apt-get install -y apache2
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

