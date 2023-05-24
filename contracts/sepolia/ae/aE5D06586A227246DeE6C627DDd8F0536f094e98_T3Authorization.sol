// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

// Uncomment this line to use console.log
// import "hardhat/console.sol";

contract T3Authorization {
    mapping(address => bool) public isAuthorized;
    error CallerNotAuthorized();

    constructor() {
        isAuthorized[msg.sender] = true;
    }

    function setAuthorized(address user, bool bAuthorized) public {
        if (!isAuthorized[msg.sender])
            revert CallerNotAuthorized();

        isAuthorized[user] = bAuthorized;
    }
}