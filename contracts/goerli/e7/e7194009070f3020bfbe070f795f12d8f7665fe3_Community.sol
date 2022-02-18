// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ReentrancyGuard.sol";
import "./Ownable.sol";

interface IApeSkull {
    function sellOut() external view returns (bool);
    function ownerOf(uint256 tokenId) external view returns (address);//
}

contract Community is Ownable, ReentrancyGuard {
  struct TokenOwnership {
    address addr;
    uint64 startTimestamp;
  }

  event Income(address sender,uint value,bytes data);
  event WithdrawIncome(address addr,uint256 tokenId,uint256 amount,uint256 gas);
  event WithdrawGas(uint256 gasAmount);

  address public apeSkullContract = address(0);

  uint256 public totalAmount = 0;

  uint256 gasAmount = 0;
  uint256 drawGasAmount = 0;

  constructor(){}

  modifier callerIsApeSkull() {
    require(tx.origin == apeSkullContract, "The caller is another contract");
    _;
  }

  fallback () external payable{
   _income();
  }


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

  function apeSkull(address addr) external onlyOwner{
    apeSkullContract = addr;
  }

  modifier callerIsUser() {
    require(tx.origin == msg.sender, "The caller is another contract");
    _;
  }

  function withdrawIncome(address addr,uint256 tokenId,uint256 amount) external onlyOwner returns (uint256) {
    require(canClaim(addr,tokenId), "");
    require(totalAmount >= amount + tx.gasprice, "The caller is another contract");
    require(amount > 0, "The caller is another contract");
    (bool success, ) = msg.sender.call{value: amount}("");
   
    if(success){
      gasAmount += tx.gasprice;
    }
    emit WithdrawIncome(addr,tokenId,amount,tx.gasprice);
    return amount;
  }

  function canClaim(address addr,uint256 tokenId) public view returns (bool) {
    require(IApeSkull(apeSkullContract).sellOut(), "");
    address owner = IApeSkull(apeSkullContract).ownerOf(tokenId);
    require(owner == addr, "");
    return true;
  }


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