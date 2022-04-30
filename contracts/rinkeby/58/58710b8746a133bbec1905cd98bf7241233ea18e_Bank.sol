/**
 *Submitted for verification at Etherscan.io on 2022-04-30
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;


contract Bank {
    mapping(address => uint256) private money;
    uint256 public minMoney = 1 ether;
    

    modifier hasMoney() {
        require(money[msg.sender] > 0, "Your balance is insufficient");
        _;
    }
    modifier enough(uint256 _amount) {
        require(msg.value >= _amount, "msg.value >= _amount");
        require(_amount >= minMoney,"_amount < minMoney");
        _;
    }
    function saveMoney(uint256 _amount) external payable  enough(_amount){
        money[msg.sender] += _amount;
        payable(msg.sender).transfer(msg.value - _amount);
    }

    function withDraw(uint256 _amount) external payable hasMoney{
        money[msg.sender] -= _amount;
        payable(msg.sender).transfer(_amount);
    }

    function getMoney() external view returns(uint256){
        return money[msg.sender];
    }

    function balanceOf() external view returns(uint256) {
        return address(this).balance;
    }
}