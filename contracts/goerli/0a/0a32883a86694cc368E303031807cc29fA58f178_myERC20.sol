// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.8;

contract myERC20 {
  mapping(address=>uint256) public balancies;

  function setAddressList(address _address, uint256 _balance) public {
      balancies[_address]=_balance;
  }
  function getBalance(address _address)public view returns(uint256){
      return balancies[_address];
  }
  
  function transfer(address to, uint256 amount) public {
      require (balancies[msg.sender]>=amount,"not enough funds");
     
          balancies[msg.sender]-=amount;
          balancies[to]+=amount;
  }
  mapping(address=>mapping(address=>uint)) approveList;
  
  function approve(address whom,uint256 howMuch) public {
      approveList[msg.sender][whom]=howMuch;
  }
  function allowance(address from,address to,uint amount) public{
      require(approveList[from][msg.sender]>=amount,"you are not allowed to use that amount");
      require(balancies[from]>=amount,"there is not enough funds on account you refer to");
      approveList[from][msg.sender]-=amount;
      balancies[from]-=amount;
      balancies[to]+=amount;
}
function viewAllowed(address from, address allowed) public view returns(uint256){
  return approveList[from][allowed];
}

}