/**
 *Submitted for verification at Etherscan.io on 2022-02-10
*/

// SPDX-License-Identifier: MIT
pragma solidity  ^0.8.0;

contract Bank {

    mapping(address => uint) _balances;
    uint _totalSupply ;

    function deposit() public payable {
        _balances[msg.sender] += msg.value;
        _totalSupply += msg.value;
    }

    function withdraw(uint amount) public {
        require(amount <= _balances[msg.sender], "Balance is not enough");
        payable(msg.sender).transfer(amount);
        _balances[msg.sender] -= amount;
        _totalSupply -= amount;
    }

    function getBalance() public view returns(uint balance){
        return _balances[msg.sender];
    }

    function getTotalSupply() public view returns(uint totalSupply){
        return address(this).balance;
    }

    function getAddressContract() public view returns(address){
        return address(this);
    }

}