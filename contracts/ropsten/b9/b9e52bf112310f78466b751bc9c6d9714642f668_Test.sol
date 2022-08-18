/**
 *Submitted for verification at Etherscan.io on 2022-08-18
*/

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

contract Test {
    uint256 public constant CHECK = 1;
    address public owner;

    constructor() {
        owner = msg.sender;
    }

    function test(uint8 num) external pure returns (bytes memory) {
        return abi.encode(num);
    }

    function getSelector(string memory message) external pure returns (bytes4) {
        return bytes4(keccak256(abi.encodePacked(message)));
    }
}