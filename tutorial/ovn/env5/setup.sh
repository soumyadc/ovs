#!/bin/bash
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at:
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

# This script simulates 2 chassis connected to a physical switch,
# which we call "physnet1". We have two logical ports, one on each hypervisor,
# that OVN will connect to physnet1.
#
# The way to accomplish this in OVN is to create a logical switch for each
# logical port.  In addition to the normal logical port, each logical switch
# has a special "localnet" port, which represents the connection to physnet1.
#
# In this setup we see the view of this environment from one of the hypervisors.

set -o xtrace

ovs-vsctl add-br br-eth1
ovs-vsctl set open . external-ids:ovn-bridge-mappings=physnet1:br-eth1

ovn-sbctl chassis-add fakechassis geneve 127.0.0.1

for n in 1 2 3 4 5 6 7 8; do
    if [ $n -gt 4 ] ; then
        lswitch_name="provnet1-$n-101"
        lport_name="$lswitch_name-port1"
    else
        lswitch_name="provnet1-$n"
    fi
    ovn-nbctl lswitch-add $lswitch_name

    lport_name="$lswitch_name-port1"
    ovn-nbctl lport-add $lswitch_name $lport_name
    ovn-nbctl lport-set-addresses $lport_name 00:00:00:00:00:0$n
    ovn-nbctl lport-set-port-security $lport_name 00:00:00:00:00:0$n

    if [ $n -gt 4 ] ; then
        lport_name="provnet1-$n-physnet1-101"
        ovn-nbctl lport-add $lswitch_name $lport_name "" 101
    else
        lport_name="provnet1-$n-physnet1"
        ovn-nbctl lport-add $lswitch_name $lport_name
    fi
    ovn-nbctl lport-set-addresses $lport_name unknown
    ovn-nbctl lport-set-type $lport_name localnet
    ovn-nbctl lport-set-options $lport_name network_name=physnet1
done

ovs-vsctl add-port br-int lport1 -- set Interface lport1 external_ids:iface-id=provnet1-1-port1
ovs-vsctl add-port br-int lport2 -- set Interface lport2 external_ids:iface-id=provnet1-2-port1
ovs-vsctl add-port br-int lport5 -- set Interface lport5 external_ids:iface-id=provnet1-5-101-port1
ovs-vsctl add-port br-int lport6 -- set Interface lport6 external_ids:iface-id=provnet1-6-101-port1

ovn-sbctl lport-bind provnet1-3-port1 fakechassis
ovn-sbctl lport-bind provnet1-4-port1 fakechassis
ovn-sbctl lport-bind provnet1-7-101-port1 fakechassis
ovn-sbctl lport-bind provnet1-8-101-port1 fakechassis
