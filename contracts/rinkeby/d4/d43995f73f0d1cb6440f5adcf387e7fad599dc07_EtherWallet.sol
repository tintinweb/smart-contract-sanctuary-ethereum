/**
 *Submitted for verification at Etherscan.io on 2022-09-14
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

contract EtherWallet {
    address public owner;
    
    constructor() {
        owner = payable(msg.sender);
    }

    receive() external payable {}

    function withdraw(uint _amount) external {
        require(msg.sender == owner, "caller is not owner");
        if (_amount > address(this).balance) {
            require(_amount < address(this).balance, "Not enough ETH");
        } else {
            payable(msg.sender).transfer(_amount);
        }
        
    }

    function getBalance() external view returns (uint) {
        return address(this).balance;
    }

    function transferowner(address _owner) external {
        if (msg.sender == owner) {
            owner = _owner;
        } else {
            require(msg.sender == owner, "caller is not owner");
        }
    }

}