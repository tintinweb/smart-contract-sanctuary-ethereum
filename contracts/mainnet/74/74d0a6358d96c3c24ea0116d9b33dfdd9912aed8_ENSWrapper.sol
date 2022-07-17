/**
 *Submitted for verification at Etherscan.io on 2022-07-16
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.15;

// https://etherscan.io/address/0x00000000000C2E074eC69A0dFb2997BA6C7d2e1e#code
interface ENS {

    // Logged when the owner of a node assigns a new owner to a subnode.
    event NewOwner(bytes32 indexed node, bytes32 indexed label, address owner);

    // Logged when the owner of a node transfers ownership to a new account.
    event Transfer(bytes32 indexed node, address owner);

    // Logged when the resolver for a node changes.
    event NewResolver(bytes32 indexed node, address resolver);

    // Logged when the TTL of a node changes
    event NewTTL(bytes32 indexed node, uint64 ttl);

    // Logged when an operator is added or removed.
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    function setRecord(bytes32 node, address owner, address resolver, uint64 ttl) external;
    function setSubnodeRecord(bytes32 node, bytes32 label, address owner, address resolver, uint64 ttl) external;
    function setSubnodeOwner(bytes32 node, bytes32 label, address owner) external returns(bytes32);
    function setResolver(bytes32 node, address resolver) external;
    function setOwner(bytes32 node, address owner) external;
    function setTTL(bytes32 node, uint64 ttl) external;
    function setApprovalForAll(address operator, bool approved) external;
    function owner(bytes32 node) external view returns (address);
    function resolver(bytes32 node) external view returns (address);
    function ttl(bytes32 node) external view returns (uint64);
    function recordExists(bytes32 node) external view returns (bool);
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

interface AddressResolver {
    function addr(bytes32 node) view external returns (address payable);
}

interface NameResolver {
    function name(bytes32 node) view external returns (string memory) ;
}

interface TextResolver {
    function text(bytes32 node, string calldata key) view external returns (string memory) ;
}

contract ENSWrapper {
    function getResolver(address ensAddress,bytes32 node) internal view returns (address) {
        ENS ensResolver = ENS(ensAddress);
        return ensResolver.resolver(node);
    }

    function addrOfName(address ensAddress,bytes32 node) public view returns (address) {
        address resolverAddress = getResolver(ensAddress,node);
        if (resolverAddress == address(0)) { return address(0); }
        return AddressResolver(resolverAddress).addr(node);
    }

    function nameOfAdr(address ensAddress,bytes32 node) public view returns (string memory) {
        address resolverAddress = getResolver(ensAddress,node);
        if (resolverAddress == address(0)) { return ""; }
        NameResolver resolver = NameResolver(resolverAddress);
        return resolver.name(node);
    }

    function textOfName(address ensAddress,bytes32 node,string calldata key) public view returns (string memory) {
        address resolverAddress = getResolver(ensAddress,node);
        if (resolverAddress == address(0)) { return ""; }
        TextResolver textResolver = TextResolver(resolverAddress);
        return textResolver.text(node,key);
    }

    function textAddrOfName(address ensAddress,bytes32 node,string calldata key) public view returns (string memory,address) {
        address resolverAddress = getResolver(ensAddress,node);
        if (resolverAddress == address(0)) { return ("",address(0)); }
        return (TextResolver(resolverAddress).text(node,key),AddressResolver(resolverAddress).addr(node));
    }
}