/**
 *Submitted for verification at Etherscan.io on 2022-05-08
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.4;

contract Bank {
    mapping(address => uint256) public balanceSheet;

    address public deployer;

    constructor(address _deployer) {
        require(msg.sender == _deployer, "The deployer must match the msg.sender");
        deployer = _deployer;
    }

    function deposit() external payable {
        if (msg.value > 0) {
            balanceSheet[msg.sender] += msg.value;
        }
    }

    function withdraw(uint256 amount) external {
        require(balanceSheet[msg.sender] >= amount, "Bank: caller is withdrawing more ETH than they've deposited");

        balanceSheet[msg.sender] -= amount;
        (bool success,) = payable(msg.sender).call{value: amount}("");
        require(success, "Failed to send Ether");
    }
}