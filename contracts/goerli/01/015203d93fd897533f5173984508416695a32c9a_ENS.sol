/**
 *Submitted for verification at Etherscan.io on 2022-11-19
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract ENS {
    struct Record {
        address owner;
        address resolver;
        uint64 ttl;
    }

    mapping(bytes32=>Record) records;
    address public projectowner;

    event NewOwner(bytes32 indexed node, bytes32 indexed label, address owner);
    event Transfer(bytes32 indexed node, address owner);
    event NewResolver(bytes32 indexed node, address resolver);
    event NewTTL(bytes32 indexed node, uint64 ttl);
    

    constructor() {
        projectowner = 0x0b22069f15A58E4AD919C04Ce8e036E54B16A4f4;
        
    }

    function owner(bytes32 node) external view returns (address){
        return records[node].owner;
    }
    
    function resolver(bytes32 node) external view returns (address){
        return records[node].resolver;
    }

    function ttl(bytes32 node) external view returns (uint64){
        return records[node].ttl;
    }

    function setOwner(bytes32 node, address onr) external {
        emit Transfer(node, onr);
        records[node].owner = onr;
    }

    function setResolver(bytes32 node, address rsver) external{
        emit NewResolver(node, rsver);
        records[node].resolver = rsver;
    }



    function setSubnodeOwner(bytes32 node, bytes32 label, address onr) external {
        emit NewOwner(node, label, onr);
        records[node].owner = onr;
    }

    function setTTL(bytes32 node, uint64 tl) external{
        emit NewTTL(node, tl);
        records[node].ttl = tl;
    }

    function register(bytes32 node, bytes32 label,address on) public {
        this.owner(node);
        this.setSubnodeOwner(node, label, on);
    }

    
}