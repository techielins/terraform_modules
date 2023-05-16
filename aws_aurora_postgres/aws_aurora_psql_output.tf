output "master_password"{
    description     =   "The database master password "
    value           =   random_password.master_password.result
    sensitive       =   true
}
