/**
 *Submitted for verification at Etherscan.io on 2022-11-10
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

contract VaultManager {
    mapping(address => uint) public balances;
 
    function depositFunds() external payable {
        balances[msg.sender] += msg.value;
    }

    function withdrawFunds(uint _weiToWithdraw) external {
        require(balances[msg.sender] >= _weiToWithdraw);

        balances[msg.sender] -= _weiToWithdraw;
        
        (bool isSent, ) = msg.sender.call{value: _weiToWithdraw}("");
        require(isSent);
    }
}

contract Vault {
    VaultManager manager;

    constructor(address contractAddr) {
        manager = VaultManager(contractAddr);
    }

    function deposit() public payable {
        manager.depositFunds{value: msg.value}();
    }

    function withdraw(uint _weiToWithdraw) external {
        manager.withdrawFunds(_weiToWithdraw);
    }
}