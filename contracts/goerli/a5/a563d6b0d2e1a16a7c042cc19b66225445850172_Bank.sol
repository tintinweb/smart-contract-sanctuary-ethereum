/**
 *Submitted for verification at Etherscan.io on 2022-12-07
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.0;

contract Bank {
    mapping (address => uint) accounts;

    function savings(address _addr, uint _amount) public payable {
        require(_amount == msg.value);
        accounts[_addr] += _amount;
    }

    function withdrawals(address _addr, uint _amount) public payable {
        require(_amount == msg.value);
        require(accounts[_addr] >= _amount);

        accounts[_addr] -= _amount;
        payable(_addr).transfer(_amount);
    }
}