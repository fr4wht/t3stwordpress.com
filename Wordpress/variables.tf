variable "machine_type" {
  default = "e2-highmem-4"
}

variable "zone" {
  default = "europe-west3-b"
}

variable "wordpress_version" {
  default = "latest"
}

variable "min_size" {
  default = 1
}

variable "max_size" {
  default = 3
}

variable "target_cpu_utilization" {
  default = 0.6
}

variable "disk_size_gb" {
  default = 100
}

