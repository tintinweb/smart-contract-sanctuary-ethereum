// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract EtherWallet  {
    
    address payable private  Owner;
    
    constructor() {
      Owner=payable(msg.sender);
    }

    modifier onlyOwner(){
        require(msg.sender==Owner,"NOT Owner");
        _;
    }
  
   receive() external payable {}

   function send(uint _value) public onlyOwner returns(bool){
        (bool success,)=Owner.call{value:_value}("");
        return success;
   }

    function getBl()public view returns(uint){
        return address(this).balance;
    }


}