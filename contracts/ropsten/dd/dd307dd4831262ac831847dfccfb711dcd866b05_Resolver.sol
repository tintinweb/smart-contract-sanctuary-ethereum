/**
 *Submitted for verification at Etherscan.io on 2022-09-14
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

 contract Resolver {

    address public nodeOwner;

    function setNodeOwner(address owner) public {
        nodeOwner = owner;
    }


    function encodeNameToNode(bytes32 parent, string memory name) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(parent, keccak256(abi.encodePacked(name))));
    }

    // full_name[www.alice.eth] => name_array[www,alice,eth]
    function resolve(string[] memory name_array) external view returns (bytes32, address) {
        bytes32 node = bytes32(0);
        for (uint256 i = name_array.length; i > 0; i--) {
            node = encodeNameToNode(node, name_array[i-1]);
        }
        return (node, nodeOwner);
    }
   
 }