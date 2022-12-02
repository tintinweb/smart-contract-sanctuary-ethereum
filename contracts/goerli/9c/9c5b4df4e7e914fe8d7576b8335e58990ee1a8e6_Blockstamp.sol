// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

contract Blockstamp {
    mapping(bytes32 => uint256) public roots;

    error DuplicateRoot();

    function postRoot(bytes32 root) public {
        if (roots[root] != 0) revert DuplicateRoot();
        roots[root] = block.timestamp;
    }
}