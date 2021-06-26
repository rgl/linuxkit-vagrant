package main

import (
	"bufio"
	"encoding/json"
	"flag"
	"fmt"
	"html/template"
	"io/ioutil"
	"log"
	"net/http"
	"os"
	"sort"
	"strconv"
	"strings"
	"time"
	_ "time/tzdata" // include the embedded timezone database.

	"github.com/tomruk/oui/ouidata"
)

type MachineStatus struct {
	Type      string    `json:"type"`
	Name      string    `json:"name"`
	Ip        string    `json:"ip"`
	Mac       string    `json:"mac"`
	MacVendor string    `json:"macVendor"`
	Hostname  string    `json:"hostname"`
	ClientId  string    `json:"clientId"`
	ExpiresAt time.Time `json:"expiresAt"`
}

type machineStatusByName []MachineStatus

func (a machineStatusByName) Len() int           { return len(a) }
func (a machineStatusByName) Swap(i, j int)      { a[i], a[j] = a[j], a[i] }
func (a machineStatusByName) Less(i, j int) bool { return a[i].Name < a[j].Name }

// read from /vagrant/shared/machines.json
type Machine struct {
	Type string `json:"type"`
	Name string `json:"name"`
	Ip   string `json:"ip"`
	Mac  string `json:"mac"`
}

// read from /var/lib/misc/dnsmasq.leases
// each line is <timestamp> <mac> <ip> <hostname> <client_id>
// e.g. 1624470573 ec:b1:d7:71:ff:f3 10.3.0.131 DESKTOP-8RFCDG6 01:ec:b1:d7:71:ff:f3
type DhcpLease struct {
	ExpiresAt time.Time
	Mac       string
	Ip        string
	Hostname  string
	ClientId  string
}

func GetMachinesStatus() ([]MachineStatus, error) {
	ouiDb, err := ouidata.NewDB()
	if err != nil {
		return nil, err
	}

	machines, err := GetMachines("machines.json")
	if err != nil {
		return nil, err
	}

	dhcpLeases, err := GetDhcpLeases("dnsmasq.leases")
	if err != nil {
		return nil, err
	}

	machinesMap := make(map[string]Machine)
	for _, m := range machines {
		machinesMap[m.Mac] = m
	}

	machinesStatusMap := make(map[string]MachineStatus)

	for _, m := range machines {
		macVendor, _ := ouiDb.Lookup(m.Mac)
		machinesStatusMap[m.Mac] = MachineStatus{
			Type:      m.Type,
			Name:      m.Name,
			Ip:        m.Ip,
			Mac:       m.Mac,
			MacVendor: macVendor,
		}
	}

	for _, l := range dhcpLeases {
		if machine, ok := machinesStatusMap[l.Mac]; ok {
			machinesStatusMap[l.Mac] = MachineStatus{
				Type:      machine.Type,
				Name:      machine.Name,
				Ip:        l.Ip,
				Mac:       machine.Mac,
				MacVendor: machine.MacVendor,
				Hostname:  l.Hostname,
				ClientId:  l.ClientId,
				ExpiresAt: l.ExpiresAt, // TODO add LastSeenAt that reflects ExpiresAt - TTL.
			}
		} else {
			macVendor, _ := ouiDb.Lookup(l.Mac)
			machinesStatusMap[l.Mac] = MachineStatus{
				Ip:        l.Ip,
				Mac:       l.Mac,
				MacVendor: macVendor,
				Hostname:  l.Hostname,
				ClientId:  l.ClientId,
				ExpiresAt: l.ExpiresAt, // TODO add LastSeenAt that reflects ExpiresAt - TTL.
			}
		}
	}

	machineStatus := make([]MachineStatus, 0, len(machinesStatusMap))

	for _, m := range machinesStatusMap {
		machineStatus = append(machineStatus, m)
	}

	sort.Sort(machineStatusByName(machineStatus))

	return machineStatus, nil
}

func GetMachines(filePath string) ([]Machine, error) {
	data, err := ioutil.ReadFile(filePath)
	if err != nil {
		return nil, err
	}
	var machines []Machine
	if err := json.Unmarshal(data, &machines); err != nil {
		return nil, err
	}
	return machines, nil
}

func GetDhcpLeases(filePath string) ([]DhcpLease, error) {
	file, err := os.Open(filePath)
	if err != nil {
		return nil, err
	}
	defer file.Close()

	dhcpLeases := make([]DhcpLease, 0)

	scanner := bufio.NewScanner(file)

	for scanner.Scan() {
		fields := strings.Fields(scanner.Text())
		timestamp, err := strconv.ParseInt(fields[0], 10, 64)
		if err != nil {
			return nil, err
		}
		dhcpLeases = append(dhcpLeases, DhcpLease{
			ExpiresAt: time.Unix(timestamp, 0).Local(),
			Mac:       fields[1],
			Ip:        fields[2],
			Hostname:  fields[3],
			ClientId:  fields[4],
		})
	}

	if err := scanner.Err(); err != nil {
		return nil, err
	}

	return dhcpLeases, nil
}

var machinesStatusTemplate = template.Must(template.New("MachinesStatus").Parse(`<!DOCTYPE html>
<html>
<head>
<title>Machines</title>
<style>
body {
	font-family: monospace;
	color: #555;
	background: #e6edf4;
	padding: 1.25rem;
	margin: 0;
}
table {
	background: #fff;
	border: .0625rem solid #c4cdda;
	border-radius: 0 0 .25rem .25rem;
	border-spacing: 0;
    margin-bottom: 1.25rem;
	padding: .75rem 1.25rem;
	text-align: left;
	white-space: pre;
}
table > caption {
	background: #f1f6fb;
	text-align: left;
	font-weight: bold;
	padding: .75rem 1.25rem;
	border: .0625rem solid #c4cdda;
	border-radius: .25rem .25rem 0 0;
	border-bottom: 0;
}
table td, table th {
	padding: .25rem;
}
table > tbody > tr:hover {
	background: #f1f6fb;
}
</style>
</head>
<body>
	<table>
		<caption>Machines</caption>
		<thead>
			<tr>
				<th>Name</th>
				<th>Ip</th>
				<th>Mac</th>
				<th>MacVendor</th>
				<th>ClientId</th>
				<th>Hostname</th>
				<th>ExpiresAt ({{.Location}})</th>
			</tr>
		</thead>
		<tbody>
			{{- range .MachinesStatus}}
			<tr>
				<td>{{.Name}}</td>
				<td>{{.Ip}}</td>
				<td>{{.Mac}}</td>
				<td>{{.MacVendor}}</td>
				<td>{{.ClientId}}</td>
				<td>{{.Hostname}}</td>
				<td>{{if not .ExpiresAt.IsZero}}{{.ExpiresAt}}{{end}}</td>
			</tr>
			{{- end}}
		</tbody>
	</table>
</body>
</html>
`))

type machinesStatusData struct {
	Location       *time.Location
	MachinesStatus []MachineStatus
}

func main() {
	log.SetFlags(0)

	var listenAddress = flag.String("listen", ":8000", "Listen address.")

	flag.Parse()

	if flag.NArg() != 0 {
		flag.Usage()
		log.Fatalf("\nERROR You MUST NOT pass any positional arguments")
	}

	timezone, err := ioutil.ReadFile("/etc/timezone")
	if err != nil {
		log.Fatalf("\nERROR Failed to get the local time zone: %v", err)
	}

	location, err := time.LoadLocation(strings.TrimSpace(string(timezone)))
	if err != nil {
		log.Fatalf("\nERROR Failed to load local time zone: %v", err)
	}

	http.HandleFunc("/machines.json", func(w http.ResponseWriter, r *http.Request) {
		machinesStatus, err := GetMachinesStatus()
		if err != nil {
			http.Error(w, err.Error(), http.StatusInternalServerError)
			return
		}

		w.Header().Set("Content-Type", "application/json")

		json.NewEncoder(w).Encode(machinesStatus)
	})

	http.HandleFunc("/", func(w http.ResponseWriter, r *http.Request) {
		if r.URL.Path != "/" {
			http.Error(w, "Not Found", http.StatusNotFound)
			return
		}

		machinesStatus, err := GetMachinesStatus()
		if err != nil {
			http.Error(w, err.Error(), http.StatusInternalServerError)
			return
		}

		w.Header().Set("Content-Type", "text/html")

		err = machinesStatusTemplate.ExecuteTemplate(w, "MachinesStatus", machinesStatusData{
			Location:       location,
			MachinesStatus: machinesStatus,
		})
		if err != nil {
			http.Error(w, err.Error(), http.StatusInternalServerError)
			return
		}
	})

	fmt.Printf("Listening at http://%s\n", *listenAddress)

	err = http.ListenAndServe(*listenAddress, nil)
	if err != nil {
		log.Fatalf("Failed to ListenAndServe: %v", err)
	}
}
