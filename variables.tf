variable "access_key" {
  type    = string
  default = ""
}

variable "secret_key" {
  type    = string
  default = ""
}

variable "ssh_ip" {
  type    = list(string)
  default = [""]
}