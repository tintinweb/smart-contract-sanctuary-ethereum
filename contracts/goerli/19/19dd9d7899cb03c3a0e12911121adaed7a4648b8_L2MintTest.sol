// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

contract L2MintTest {
    uint256 public nextId;

    event MintRequest(uint256 tokenId);

    constructor(uint256 _nextId) {
        nextId = _nextId;
    }

    function buy() external payable {
        require(msg.value == 0.0001 ether, "You should pay 0.0001 ether");

        emit MintRequest(nextId++);
    }
}