/**
 *Submitted for verification at Etherscan.io on 2022-07-19
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract Bank {

    mapping(address => uint) _balances;
    event Deposit(address indexed owner, uint amount); // indexed เอาไว้ track ว่า owner ฝากเงินมากี่ครั้งแล้ว
    event Withdraw(address indexed owner, uint amount); 

    function deposit() public payable {
        require(msg.value > 0, "deposit money is zero");

        _balances[msg.sender] += msg.value;
        emit Deposit(msg.sender, msg.value); // emit เป็นการแจ้งเตือนว่า event เกิดขึ้นแล้ว
    }

    function withdraw(uint amount) public {
        require(amount > 0 && amount <= _balances[msg.sender], "not enough money");

        payable(msg.sender).transfer(amount); // หน่วย amount เป็น wei

        _balances[msg.sender] -= amount;
        emit Withdraw(msg.sender, amount);
    }

    function checkBalance() public view returns(uint){
        return _balances[msg.sender];
    }

    // function balanceOf(address owner) public view returns(uint){ // function นี้ ใช้เช็คเงินในบัญชีของใครก็ได้
    //     return _balances[owener];
    // }
}