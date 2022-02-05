/**
 *Submitted for verification at Etherscan.io on 2022-02-04
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

contract Wallet {
    address public owner;
    
    constructor() {

        owner = payable(msg.sender);
    }

    fallback() external payable{}

    receive() external payable{}

    modifier onlyOwner() {
        require(msg.sender == owner, "not owner");
        _;
    }

    function setOwner(address _owner) external {
        owner = _owner;
    }

    function sendEther(uint _amount) external onlyOwner {
        payable(msg.sender).transfer(_amount);
    }
}