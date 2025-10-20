package main

import (
	"net/http"
	"strconv"

	"github.com/labstack/echo/v4"
)

const (
	iterations = 20
	modulus    = 1000003
)

func cpuWork(iter int) int {
	acc := 0
	for i := 0; i < iter; i++ {
		value := i
		for j := 0; j < iter; j++ {
			value = (value*31 + j) % modulus
		}
		acc = (acc + value) % modulus
	}
	return acc
}

func main() {
	e := echo.New()
	e.HideBanner = true
	e.HidePort = true

	e.GET("/", func(c echo.Context) error {
		result := cpuWork(iterations)
		return c.String(http.StatusOK, "Hello, world "+strconv.Itoa(result))
	})

	e.Logger.Fatal(e.Start(":8080"))
}
