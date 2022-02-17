/**
 *Submitted for verification at Etherscan.io on 2022-02-17
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Bank {

    mapping(address => uint) _balances; //dictionary 0xYYY = 5ETH
    uint _totalBalance = 0;

    event Deposit(address indexed owner, uint amount);
    event Withdraw(address indexed owner, uint amount);
    

    function deposit() public payable{
        require(msg.value >0, "balance is zero");
        _balances[msg.sender] += msg.value;
        _totalBalance += msg.value;
        emit Deposit(msg.sender, msg.value);
    }

    function withdraw(uint amount) public {  //unit in wei
        uint amountE = 1000000000000000000 * amount;
        require(amount > 0 && amountE <= _balances[msg.sender], "not enough");
        payable(msg.sender).transfer(amountE);
        _balances[msg.sender] -= amountE;
        _totalBalance -= amountE;
        emit Withdraw(msg.sender, amountE);
    }

    function getTotalBalance() public view returns(uint Total)  {
        return _totalBalance / 1000000000000000000;
    }

    function getVersion() public pure returns(string memory Version) {
        return "1.0.0";
    }

    function getMyBalance() public view returns (uint amount){
        return _balances[msg.sender] / 1000000000000000000;
    }

}