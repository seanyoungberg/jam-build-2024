## Dummy placeholder resource

resource "null_resource" "example" {
  triggers = {
    # This will cause the resource to be recreated on every terraform apply
    always_run = "${timestamp()}"
  }

  provisioner "local-exec" {
    command = "echo 'This is a placeholder resource'"
  }
}