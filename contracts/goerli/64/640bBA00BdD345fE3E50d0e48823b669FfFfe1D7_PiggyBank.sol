// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract PiggyBank {
    
    address private  Owner;
    
    constructor() {
      Owner=msg.sender;
    }

    modifier onlyOwner(){
        require(msg.sender==Owner ,"NOT Owner");
        _;
    }
  
   receive() external payable {}

   function kill() public onlyOwner(){
    
        selfdestruct(payable(msg.sender));
     
   }

    function getBl()public view returns(uint){
        return address(this).balance;
    }


}