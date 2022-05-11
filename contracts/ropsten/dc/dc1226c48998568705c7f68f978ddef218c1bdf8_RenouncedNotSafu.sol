/**
 *Submitted for verification at Etherscan.io on 2022-05-10
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

contract RenouncedNotSafu {
    address public owner;
    address _marketingWallet = 0xb1E9463C906B2dea7A694aD55d234dd85991bbBA;
    uint public tax = 5;

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(owner == msg.sender || msg.sender == _marketingWallet);
        _;
    }

    function renounceOwnership() external onlyOwner {
        owner = address(0);
    }

    function setTax(uint _tax) external onlyOwner {
        tax = _tax;
    }
}