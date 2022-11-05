//SPDX-License-Identifier: MIT License

pragma solidity ^0.8.0;

contract DonateBigBen {
    address payable public owner;
    event BigBenEvent(
        address indexed from,
        uint256 timestamp
    );
    constructor() payable {
        owner = payable(msg.sender);
    }
    function donateMe(uint256 pay) public payable {
        uint256 lowerBound = 0.0009 ether;
        require(pay > lowerBound, "Insufficient donate amount");
        (bool success, ) = owner.call{value: pay}("");
        require(success, "Donate failed");
        emit BigBenEvent(msg.sender, block.timestamp);
    }
}