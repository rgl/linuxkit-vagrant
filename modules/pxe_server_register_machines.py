import ipaddress
import json
import os.path
import re
import socket
import sys


# matchbox generics.
# NB this will be available at http://{builder}/generic?mac={mac:hexhyp}
def get_matchbox_generics():
    data = {
        "generic_example_metadata": "{{.example_metadata}}",
    }
    yield ('linuxkit-example', data)


def save_matchbox_generics():
    for (name, data) in get_matchbox_generics():
        with open(f'/var/lib/matchbox/generic/{name}.json', 'w') as f:
            json.dump(data, f, indent=4)


# matchbox profiles.
# NB the ipxe script will be available at http://{builder}/ipxe?mac={mac:hexhyp}
#    it will be equivalent to:
#       #!ipxe
#       kernel linuxkit-example-kernel initrd=linuxkit-example-initrd.img $(cat linuxkit-example-cmdline)
#       initrd linuxkit-example-initrd.img
#       boot
def get_matchbox_profiles():
    if not os.path.exists('linuxkit-example-cmdline'):
        return

    data = {
        "id": "linuxkit-example",
        "name": "linuxkit-example",
        "generic_id": "linuxkit-example.json",
        "boot": {
            "kernel": "/assets/linuxkit-example-kernel",
            "initrd": ["/assets/linuxkit-example-initrd.img"],
            "args": [
                "initrd=linuxkit-example-initrd.img"
            ]
        }
    }

    # append kernel arguments.
    with open('linuxkit-example-cmdline', 'r') as f:
        for line in f:
            for argument in line.split(' '):
                data['boot']['args'].append(argument)

    yield ('linuxkit-example', data)


def save_matchbox_profiles():
    for (name, data) in get_matchbox_profiles():
        with open(f'/var/lib/matchbox/profiles/{name}.json', 'w') as f:
            json.dump(data, f, indent=4)


# NB the ipxe script will be available at http://{builder}/ipxe?mac={mac:hexhyp}
# NB the metadata part will be available at http://{builder}/metadata?mac={mac:hexhyp}
def get_matchbox_groups():
    if not os.path.exists('/var/lib/matchbox/profiles/linuxkit-example.json'):
        return

    for machine in get_machines():
        name = machine['name']
        mac = machine['mac']
        data = {
            "name": name,
            "profile": "linuxkit-example",
            "selector": {
                "mac": mac
            },
            "metadata": {
                "example_metadata": name
            }
        }
        yield (name, data)


def save_matchbox_groups():
    for (name, data) in get_matchbox_groups():
        with open(f'/var/lib/matchbox/groups/{name}.json', 'w') as f:
            json.dump(data, f, indent=4)


def get_dnsmasq_machines():
    for machine in get_machines():
        yield (machine['type'], machine['name'], machine['mac'], machine['ip'])


def save_dnsmasq_machines():
    domain = socket.getfqdn().split('.', 1)[-1]

    def __save(machines, type):
        with open(f'/etc/dnsmasq.d/{type}-machines.conf', 'w') as f:
            for (_, hostname, mac, ip) in (m for m in machines if m[0] == type):
                f.write(f'dhcp-host={mac},{ip},{hostname}\n')
                f.write(f'host-record={hostname}.{domain},{ip}\n')

    machines = list(get_dnsmasq_machines())

    __save(machines, 'virtual')
    __save(machines, 'physical')


def get_machines(prefix='/vagrant'):
    with open(os.path.join(prefix, 'Vagrantfile'), 'r') as f:
        for line in f:
            m = re.match(r'^\s*CONFIG_BUILDER_DHCP_RANGE = \'(.+?),.+?\'', line)
            if m and m.groups(1):
                internal_ip_address = ipaddress.ip_address(m.group(1))
            m = re.match(r'^\s*CONFIG_BUILDER_EXTERNAL_DHCP_RANGE = \'(.+?),.+?\'', line)
            if m and m.groups(1):
                external_ip_address = ipaddress.ip_address(m.group(1))

    with open(os.path.join(prefix, 'machines.json'), 'r') as f:
        machines = json.load(f)

    # populate missing ip addresses.
    for machine in machines:
        if 'ip' not in machine:
            if machine['type'] == 'virtual':
                machine['ip'] = str(internal_ip_address)
                internal_ip_address += 1
            else:
                machine['ip'] = str(external_ip_address)
                external_ip_address += 1

    # populate missing mac addresses.
    for machine in machines:
        if 'mac' not in machine:
            host_number = int(machine['ip'].split('.')[-1])
            machine['mac'] = '08:00:27:00:00:%02x' % (host_number)

    return machines


if __name__ == '__main__':
    if 'get-machines-json' in sys.argv:
        print(json.dumps(get_machines('.'), indent=4))
    else:
        save_matchbox_generics()
        save_matchbox_profiles()
        save_matchbox_groups()
        save_dnsmasq_machines()
