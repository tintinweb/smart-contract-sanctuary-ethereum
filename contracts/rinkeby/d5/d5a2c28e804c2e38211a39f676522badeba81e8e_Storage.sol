/**
 *Submitted for verification at Etherscan.io on 2022-05-29
*/

// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;

contract Storage {
    uint256 number;
    address owner;  // 合约拥有者

    constructor() {
      owner = msg.sender; // 合约创建者
    }

    // 写入
    function store(uint256 num) public {
      number = num;
    }

    // 读取
    function retrieve() public view returns (uint256){
      return number;
    }

    // 查询指定地址余额
    function getBalanceOfAddress(address addr) public view returns (uint256){
      return addr.balance;
    }

    // transfer转账
    function transfer(address toAddr) payable public{
        payable(address(toAddr)).transfer(msg.value);   // 调用者转给指定地址
    }

    // 获取合约地址
    function getContractAddress() public view returns (address){
        return address(this);   // this指向合约地址本身的指针（合约本身）
    }

    // 获取合约地址余额
    function getContractBalance() public view returns (uint256) {
      return address(this).balance;
    }

    // 向合约地址转账
    function transderToContract() payable public {
      // 当向合约地址转账时，执行这个函数
      payable(address(this)).transfer(msg.value);
    }

    // 合约销毁
    function kill(address addr) payable public {
      if(owner != msg.sender){
          revert();
      }
      selfdestruct(payable(address(addr)));
    }

    fallback() external payable {}
    receive() external payable {}
}