//SPDX-License-Identifier: Unlicense
pragma solidity >=0.7.0 <0.9.0;

contract Owner {
   address private owner;
   event _changeOwner(address  _oldOwner,address  _newOwner);
   constructor() {
       owner = msg.sender;
       emit _changeOwner (address(0), owner);
    }
   modifier isOwner() {
   require(msg.sender == owner, "Only owner can run this function");
      _; 
   }
    function changeOwner(address _newOwner) public isOwner{
        emit _changeOwner(_newOwner, owner);
        owner = _newOwner;
    }
    
     function getOwner() public view returns (address){
         return owner;
      
    }   
}