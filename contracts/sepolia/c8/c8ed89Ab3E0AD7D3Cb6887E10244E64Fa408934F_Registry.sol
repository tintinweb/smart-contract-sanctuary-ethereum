/**
 *Submitted for verification at Etherscan.io on 2023-06-01
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.2 <0.9.0;

struct Endpoint {
    address addr;
    string host;
    uint32 port;
}


contract Registry {

    mapping (address => Endpoint) public endpoints;
    address[] public nodes;

    function register(address addr, string memory host, uint32 port) public {
        Endpoint memory e = Endpoint({
            addr: addr, 
            host: host,
            port: port
        });
        endpoints[addr] = e;
        nodes.push(addr);
    }

    function unregister(address addr) public {
        uint indexToDelete;
        bool exists;
        for (uint i = 0; i < nodes.length; i++) {
            if (endpoints[nodes[i]].addr == addr) {
                indexToDelete = i;
                exists = true;
            }
        }

        if (exists) {
             delete endpoints[addr];
             delete nodes[indexToDelete];
        }
    }

    function listEndpoints() public view returns (Endpoint[] memory) {
        Endpoint[] memory ret = new Endpoint[](nodes.length);
        for (uint i = 0; i < nodes.length; i++) {
            ret[i] = endpoints[nodes[i]];
        }
        return ret;
    }
}