/**
 *Submitted for verification at Etherscan.io on 2022-09-15
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

 contract Resolver {

    mapping(bytes32 => address) public nodeRecords;

    function setNodeOwner(string[] memory name_array, address owner) public {
        bytes32 node = getNode(name_array);
        nodeRecords[node] = owner;
    }

    // full_name[www.alice.eth] => name_array[www,alice,eth]
    function resolve(string[] memory name_array) public view returns (address){
        bytes32 node = getNode(name_array);
        return nodeRecords[node];
    }

    function getNode(string[] memory name_array) public pure returns (bytes32){
        bytes32 node = bytes32(0);
        for (uint256 i = name_array.length; i > 0; i--) {
            node = encodeNameToNode(node, name_array[i-1]);
        }
        return node;
    } 

    function encodeNameToNode(bytes32 parent, string memory name) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(parent, keccak256(abi.encodePacked(name))));
    }

    // // full_name[www.alice.eth] => name_array[www,alice,eth]
    // function resolve(string[] memory name_array) public view returns (address) {
    //     bytes32 node = getNode(name_array);
    //     address nodeOwner = getNodeOwner[node];
    //     return nodeOwner;
    // }
   
 }