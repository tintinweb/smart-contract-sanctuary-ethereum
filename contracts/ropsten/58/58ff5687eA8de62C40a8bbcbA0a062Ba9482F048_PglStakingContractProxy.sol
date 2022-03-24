// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract PglStakingContractProxy {
    // Current contract admin address
    address public admin;

    // Current contract implementation address
    address public implementation;

    constructor() public {
        admin = msg.sender;
    }

    // modified function to set the implementation contract.
    function setImplementation(address newImplementation) public adminOnly {
        implementation = newImplementation;
    }

    //fallback function
    fallback() external payable {
        (bool success, ) = implementation.delegatecall(msg.data);
    }

    // modifiers
    modifier adminOnly() {
        require(msg.sender == admin, "admin only");
        _;
    }
}