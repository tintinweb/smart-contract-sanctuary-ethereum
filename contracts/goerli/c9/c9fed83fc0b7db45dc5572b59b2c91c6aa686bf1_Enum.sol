/**
 *Submitted for verification at Etherscan.io on 2023-02-07
*/

pragma solidity ^0.8.0;
// SPDX-License-Identifier: MIT
// https://solidity-by-example.org/array

contract Enum {

    // <addrss, [node1, node2, ...]>
    mapping(address => bytes32[]) public relation;

    // <address, node, index>
    mapping(address => mapping(bytes32 => uint256)) public indexPlusOne;

    function push(address addr, bytes32 node) external returns (bool) {
        if (indexPlusOne[addr][node] != 0) {
            return false;
        }
        
        relation[addr].push(node);
        indexPlusOne[addr][node] = relation[addr].length;
        return true;
    }

    function remove(address addr, bytes32 node) external returns (bool) {
        uint256 idx = indexPlusOne[addr][node];
        if (idx == 0) {
            return false;
        }

        uint256 idxLast = relation[addr].length - 1;
        bytes32 nodeLast = relation[addr][idxLast];

        relation[addr][idx - 1] = nodeLast;
        indexPlusOne[addr][nodeLast] = idx;

        relation[addr].pop();
        indexPlusOne[addr][node] = 0;

        return true;
    }

}