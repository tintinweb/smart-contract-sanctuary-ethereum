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

    receive() external payable {}

    modifier onlyOwner() {
        require(msg.sender == owner, "not owner");
        _;
    }

    function setOwner(address _owner) external {
        owner = _owner;
    }

    function withdraw() external onlyOwner {
        payable(owner).transfer(address(this).balance);
    }
    
}