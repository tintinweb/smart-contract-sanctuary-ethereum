/**
 *Submitted for verification at Etherscan.io on 2023-06-06
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.2 <0.9.0;

struct Endpoint {
    address addr;
    string host;
    uint32 port;
}

struct VersionedEndpoints {
    Endpoint[] endpoints;
    uint64 version;
}

contract Registry {

    mapping (address => Endpoint) public endpoints;
    address[] public nodes;
    uint64 public version;

    constructor() {
        version = 0;
    }

    function register(address addr, string memory host, uint32 port) public {
        bool exists;
        for (uint i = 0; i < nodes.length; i++) {
            if (endpoints[nodes[i]].addr == addr) {
                exists = true;
            }
        }

        if (!exists) {
            nodes.push(addr);
        }

        Endpoint memory e = Endpoint({
            addr: addr, 
            host: host,
            port: port
        });
        endpoints[addr] = e;
        version++;
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

            for (uint i = indexToDelete; i < nodes.length-1; i++){
                nodes[i] = nodes[i+1];
            }
            nodes.pop();
            version++;
        }
    }

    function listEndpoints() public view returns (VersionedEndpoints memory) {
        Endpoint[] memory ret = new Endpoint[](nodes.length);
        for (uint i = 0; i < nodes.length; i++) {
            ret[i] = endpoints[nodes[i]];
        }

        return VersionedEndpoints({
            endpoints : ret,
            version: version
        });
    }
}