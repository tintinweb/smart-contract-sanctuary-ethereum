/**
 *Submitted for verification at Etherscan.io on 2022-09-02
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract PiggyBank {
    
    address private  Owner;
    string public name;
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

    function setName(string memory _name)public {
        name=_name;
    }
    function getBl()public view returns(uint){
        return address(this).balance;
    }


}