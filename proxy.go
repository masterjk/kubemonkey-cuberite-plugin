package main

import (
	"bufio"
	"bytes"
	"log"
	"net/http"
	"os/exec"
	"strings"
)

func main() {

	urlStart := "http://127.0.0.1:8080/webadmin/KubeMonkey/start"
	urlStop := "http://127.0.0.1:8080/webadmin/KubeMonkey/stop"

	cmd := exec.Command("kubectl", "get", "pod", "--watch")
	cmdReader, _ := cmd.StdoutPipe()

	scanner := bufio.NewScanner(cmdReader)
	go func() {
		for scanner.Scan() {
			line := scanner.Text()
			if strings.Index(line, "Running") > -1 {
				Update(urlStart, GetId(line))
			}

			if strings.Index(line, "Terminating") > -1 {
				Update(urlStop, GetId(line))
			}
		}
	}()

	err := cmd.Start()
	if err != nil {
		log.Fatal(err)
	}
	err = cmd.Wait()
	log.Printf("Command finished with error: %v", err)
}

func GetId(line string) string {
	return line[0:strings.Index(line, " ")]
}

func Update(url, containerId string) {

	var payload = []byte("containerId=" + containerId)
	req, _ := http.NewRequest("POST", url, bytes.NewBuffer(payload))
	req.Header.Set("Content-Type", "application/x-www-form-urlencoded")
	req.SetBasicAuth("admin", "admin")
	client := &http.Client{}
	resp, _ := client.Do(req)
	defer resp.Body.Close()
}
