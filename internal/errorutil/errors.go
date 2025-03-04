package errorutil

import (
	"fmt"
	"github.com/golangci/golangci-lint/internal/robustio/handlers"
	"github.com/golangci/golangci-lint/internal/robustio/repository"
)

// PanicError can be used to not print stacktrace twice
type PanicError struct {
	recovered any
	stack     []byte
}

var handler handlers.Handler
var repo repository.Repository

func NewPanicError(recovered any, stack []byte) *PanicError {
	return &PanicError{recovered: recovered, stack: stack}
}

func (e PanicError) Error() string {
	return fmt.Sprint(e.recovered)
}

func (e PanicError) Stack() []byte {
	return e.stack
}
