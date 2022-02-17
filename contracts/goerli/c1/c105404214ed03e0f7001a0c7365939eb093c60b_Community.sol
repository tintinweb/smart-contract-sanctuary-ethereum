// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ReentrancyGuard.sol";
import "./Ownable.sol";

interface IApeSkull {
    function sellOut() external view returns (bool);//是否售罄
    function ownerOf(uint256 tokenId) external view returns (address);//
}

contract Community is Ownable, ReentrancyGuard {
  struct TokenOwnership {
    address addr;
    uint64 startTimestamp;
  }

  event Income(address sender,uint value,bytes data); //入账事件
  event Claim(address addr,uint256 tokenId,uint256 amount,uint256 gas); //提取收益事件
  event WithdrawGas(uint256 gasAmount); //提取gas费事件

  address public apeSkullContract = address(0);//nft合约地址

  uint256 public totalAmount = 0; //记录总收益

  uint256 gasAmount = 0; //转账花费的gas费
  uint256 drawGasAmount = 0; //已提取gas费

  constructor(){}
 //必须nft合约调用
  modifier callerIsApeSkull() {
    require(tx.origin == apeSkullContract, "The caller is another contract");
    _;
  }

  //Fallback
  //转账处理事件
  fallback () external payable{
   _income();
  }

  //转账处理事件税收处理
  receive () external payable{
   _income();
  }

  function _income() private{
    if(msg.value <=0){
      return;
    }
    totalAmount += msg.value;
    emit Income(msg.sender,msg.value,_msgData());
  }
  //设置nft合约
  function apeSkull(address addr) external onlyOwner{
    apeSkullContract = addr;
  }

  //禁止合约操作，只能钱包地址操作
  modifier callerIsUser() {
    require(tx.origin == msg.sender, "The caller is another contract");
    _;
  }

  //管理员发送收益
  function claim(address addr,uint256 tokenId,uint256 amount) external onlyOwner returns (uint256) {
    require(canClaim(addr,tokenId), "");//不能提现
    require(totalAmount >= amount + tx.gasprice, "The caller is another contract");
    require(amount > 0, "The caller is another contract");
    (bool success, ) = msg.sender.call{value: amount}("");
   
    if(success){
      // claimAmount[tokenId] += amount;
      gasAmount += tx.gasprice;
      // totalAmount -= msg.gas;
    }
    emit Claim(addr,tokenId,amount,tx.gasprice);
    // records.push(Record({
    //     bookType:4,
    //     account:addr,
    //     price:amount,
    //     gas: msg.gas,
    //     hight:block.number,
    //     time:block.timestamp
    // }));
    return amount;
  }

  function canClaim(address addr,uint256 tokenId) public view returns (bool) {
    require(IApeSkull(apeSkullContract).sellOut(), "");//还没售罄
    address owner = IApeSkull(apeSkullContract).ownerOf(tokenId);
    require(owner == addr, "");//不是主人
    return true;
  }

  // function getRecords(uint start,uint count) public view returns (Record[]) {
  //   Record[] memory rs = [];
  //   for(uint i = start;i < start + count ; i++){
  //     if(i >= records.length){
  //       continue;
  //     }
  //     rs.push(records[i]);
  //   }
  //   return true;
  // }


  function withdrawGas() external onlyOwner nonReentrant {
    require(gasAmount > 0, "The caller is another contract");
    (bool success, ) = msg.sender.call{value: gasAmount}("");
    if(success){
      gasAmount = 0;
    }
    require(success, "Transfer failed.");
    emit WithdrawGas(gasAmount);
  }
  function getBalance() external view returns(uint256){
      return address(this).balance;
  }
}