/**
 *Submitted for verification at Etherscan.io on 2022-05-12
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

contract MSMProxy {

   string public name;
   uint public value;

   address  public  implementation;
   address admin;

    constructor(address _delegateAddress) {
    admin = msg.sender;
    implementation = _delegateAddress;

    }
    

   modifier onlyAdmin(address _admin) {

     require (admin == _admin, "Not Admin");

     _;

   }
  

  function deploy(address _delegateAddress) onlyAdmin(msg.sender) public {

     implementation = _delegateAddress;
   
  }
 

    function getFunctionByte(string memory functiontocall,  string memory parameter) public pure returns(bytes memory data) {

       bytes memory _data = abi.encodeWithSignature(functiontocall, parameter);

       return _data;
     
   }


  fallback() external payable{
     
    address _implementation = implementation;

   _implementation.delegatecall(msg.data);

  }


    function getBalance() public view returns ( uint balance) {
       
       return address(this).balance;
   }
}