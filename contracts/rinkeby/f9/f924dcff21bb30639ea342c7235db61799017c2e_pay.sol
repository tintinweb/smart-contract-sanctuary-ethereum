/**
 *Submitted for verification at Etherscan.io on 2022-06-10
*/

pragma solidity >=0.7.0 <0.9.0;



contract pay{
  address payable user=payable(0x4B20993Bc481177ec7E8f571ceCaE8A9e22C02db);
  uint public x=10;
  function trans() public payable{

  }

  function getBalance() public view returns(uint){
    return address(this).balance;
  }

  function sendEther() public {
    user.transfer(1 ether);

  }


}