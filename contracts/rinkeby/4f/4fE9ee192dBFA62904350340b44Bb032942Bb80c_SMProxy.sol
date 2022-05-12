// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

contract SMProxy {

   string public name;
   uint public value;

   address  public  delegateAddress;
   address admin;

    constructor(address _delegateAddress) {
    admin = msg.sender;
    delegateAddress = _delegateAddress;

    }
    

   modifier onlyAdmin(address _admin) {

     require (admin == _admin, "Not Admin");

     _;

   }
  

  function deploy(address _delegateAddress) onlyAdmin(msg.sender) public {

     delegateAddress = _delegateAddress;
   
  }
 

    function getFunctionByte(string memory functiontocall,  string memory parameter) public pure returns(bytes memory data) {

       bytes memory _data = abi.encodeWithSignature(functiontocall, parameter);

       return _data;
     
   }


  fallback() external payable{
     
    address _delegateaddress = delegateAddress;

   _delegateaddress.delegatecall(msg.data);

  }


    function getBalance() public view returns ( uint balance) {
       
       return address(this).balance;
   }
}



contract SMV1 {
  string public name;

  // fallback() external payable {
     
    
  // }

   function setXandSendEther(string memory _x) public returns (string memory) {
        name = _x;
       return name;
   }
}