/**
 *Submitted for verification at Etherscan.io on 2023-02-21
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

interface ENS {
    function resolver(bytes32 node) external view returns (Resolver);
}

interface Resolver {
    function addr(bytes32 node) external view returns (address);
}

contract InstaENSResolver {
    function resolverNames(bytes32[] memory nodes) public view returns(address[] memory ensResolvedAddresses) {
        uint256 length = nodes.length;
        ensResolvedAddresses = new address[](length);
        for (uint256 i = 0; i < length; i++) {
            bytes32 node = nodes[i];
            Resolver resolver = ENS(0x00000000000C2E074eC69A0dFb2997BA6C7d2e1e).resolver(node);
            if (address(resolver) == address(0)) continue;
            ensResolvedAddresses[i] = resolver.addr(node);
        }
    }
}