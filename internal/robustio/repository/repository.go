package repository

type Repository struct {
	Users []*User
}

type User struct {
	Name string
	Age  int
}
