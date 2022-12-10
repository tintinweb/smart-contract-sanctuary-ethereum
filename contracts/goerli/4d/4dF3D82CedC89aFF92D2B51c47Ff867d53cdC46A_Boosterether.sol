// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

contract Boosterether {
  address owner;
  mapping(address => uint256) public accountBalances;
  mapping(address => address) public confirmationAddress;
  uint256 withdrawable=0;
  //address confirmationAddress;

  event PaymentAdded(address user, uint256 amount, uint256 timestamp);

modifier onlyOwner(){
    require(msg.sender==owner,"only owner can call this");
    require(withdrawable!=0,"zero balance to withdraw");
    _;

}
  constructor() {
    owner = msg.sender;
  }


  function deposit() external payable{
    require (msg.value > 0, "Empty transact");
    //payable(address(this)).transfer(msg.value);
    accountBalances[msg.sender]=msg.value;
    emit PaymentAdded(msg.sender, msg.value, block.timestamp);

  }

  function confirmation(address _confirms) external {
    //withdrawable[msg.sender]=accountBalances[]
    withdrawable+=accountBalances[_confirms];

  }
  function withdraw(uint inputassest) onlyOwner external  {
    payable(owner).transfer(inputassest);
    withdrawable=0;
  }
  function checkwithdrawbalance() public view returns (uint256){
    return withdrawable;
  }
  function balance() public view returns (uint256){
    return payable(address(this)).balance;
  }
}