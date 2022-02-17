// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ReentrancyGuard.sol";
import "./Ownable.sol";

interface IApeSkull {
    function sellOut() external view returns (bool);//是否售罄
}

// interface IFounder {
//     function save() public;//传入收益
// }

contract Founder is Ownable, ReentrancyGuard {
  
  uint256[] withdrawScale = [0 ether,1,
                              100 ether,20,
                              300 ether,50,
                              1000 ether,80,
                              10000 ether,100];//提现比例

  uint256 public totalAmount = 0; //总收益
  uint256 public withdrawAmount = 0; //已提现金额
  address public apeSkullContract = address(0); //nft合约地址

  constructor(){
  }

 //必须nft合约调用
  modifier callerIsApeSkull() {
    require(tx.origin == apeSkullContract, "The caller is another contract");
    _;
  }
  
  fallback () external payable{
   _income();
  }

  //转账处理事件税收处理
  receive () external payable{
   _income();
  }

  function _income() private{
     if(msg.sender == apeSkullContract){//必须是nft的合约存入才算收益
        totalAmount += msg.value;
      }
  }
  //设置nft合约地址
  function apeSkull(address addr) external onlyOwner{
    apeSkullContract = addr;
  }
  //可以提现的金额
  function canWithdrawAmount() public view returns (uint256) {
    if(!IApeSkull(apeSkullContract).sellOut()){//判断是否售罄
      return 0;
    }
    uint256 percent = 0;
    for (uint256 i = 0; i < withdrawScale.length; i=i+2) {
      if(totalAmount>=withdrawScale[i]){
          percent = withdrawScale[i+1];
      }else{
        break;
      }
    }
    uint256 amount = percent*totalAmount/100;
    return amount;
  }
  //合约转账到合约主人钱包
  function withdrawMoney() external onlyOwner nonReentrant {
    uint256 balance = address(this).balance;//余额
    uint256 amount = canWithdrawAmount();//可提现金额
    amount = amount - withdrawAmount;//减去已提现
    if(amount>balance){
      amount = balance;
    }
    (bool success, ) = msg.sender.call{value: amount}("");
    if(success){
      withdrawAmount = withdrawAmount + amount;
    }
    require(success, "Transfer failed.");
  }
  function getBalance() external view returns(uint256){
      return address(this).balance;
  }
}