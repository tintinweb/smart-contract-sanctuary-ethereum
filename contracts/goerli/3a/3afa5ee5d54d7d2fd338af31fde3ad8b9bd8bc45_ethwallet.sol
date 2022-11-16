/**
 *Submitted for verification at Etherscan.io on 2022-11-16
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.17;

contract ethwallet{
    // make contract which can store ether for an owner 
     address payable owner;
     string name;

     constructor (string memory _name){
         owner =payable (msg.sender);
         name = _name;
     }

     function withdrawAll() public {
         uint bal=address(this).balance;
         owner.transfer(bal);
     }
     
     function withdraw(uint value) public {
         owner.transfer(value);
     }
    function getBalance() public view returns(uint){
        return address(this).balance;
    }
    function editname(string memory newname) external{
        name = newname;
    
    } 
    function getname() external view returns(string memory){
        return name;
    }
     

     event Recipt(uint value);
    receive() external payable{
     emit Recipt(msg.value);
    }
}