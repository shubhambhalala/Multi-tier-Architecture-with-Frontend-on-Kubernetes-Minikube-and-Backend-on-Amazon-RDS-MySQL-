provider "aws" {
        region = "ap-south-1"
}

resource "aws_security_group" "mysql" {
  	name        = "mysql-sg"
  	description = "allow connectivity"
  	ingress {
    		from_port   = 3306
    		to_port     = 3306
    		protocol    = "tcp"
            cidr_blocks = ["0.0.0.0/0"]
  	    }


  	egress {
    		from_port       = 0
    		to_port         = 0
    		protocol        = "-1"
    		cidr_blocks     = ["0.0.0.0/0"]
  	    }
	tags = {
		Name = "mysql-sg"
	}
} 

resource "aws_db_instance" "default" {
	allocated_storage    = 20
    vpc_security_group_ids = [aws_security_group.mysql.id]
	storage_type         = "gp2"
	identifier           = "mysqldb"
	engine               = "mysql"
    engine_version       = "5.7"
	instance_class       = "db.t2.micro"
	name                 = "wpdatabase"
	username             = "shubham"
	password             = "shubhamredhat"
	publicly_accessible  = true
	port                 = 3306
	parameter_group_name = "default.mysql5.7"
	skip_final_snapshot  = true
	tags = {
 	    Name             = "database"
	}
}

output "dns" {
  value = aws_db_instance.default.address
}

provider "kubernetes" {
  config_context_cluster = "minikube"
}
 
 resource "kubernetes_deployment" "wordpress" {
  metadata {
        name= "wordpress"
   }
   spec {
      replicas = 1
      selector {
            match_labels= {
                env    = "frontend"
                region = "IN"
                App    = "wordpress"
            }
            match_expressions {
            key      = "env"
            operator = "In"
            values   = ["frontend", "webserver"]
            }
    }
    template {
        metadata {
          labels = {
            env    = "frontend"
            region = "IN"
            App    = "wordpress"
                }
            }
    spec {
         container {
             image = "wordpress:5.1.1-php7.3-apache"
             name  = "wordpress-frontend"
         }
      }
    }
  }
}
resource "kubernetes_service" "service" {
 metadata {
 name = "service"
 }

 spec {
     selector = {
          App = kubernetes_deployment.wordpress.spec.0.template.0.metadata[0].labels.App
       }
    port {
       node_port   = 31000
       port        = 80
       target_port = 80
      }
      type = "NodePort"
   }
}