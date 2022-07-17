/**
 *Submitted for verification at Etherscan.io on 2022-07-17
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Bank {

    mapping (address => uint256) private _balances;

    function deposit() payable public {
        _balances[msg.sender] += msg.value;
    }

    function withdraw(uint256 amount) public {
        require(balanceOf(msg.sender) >= amount);
        _balances[msg.sender] -= amount;
        payable(msg.sender).transfer(amount);
    }

    function balanceOf(address account) public view returns(uint256){
        return _balances[account];
    }
}