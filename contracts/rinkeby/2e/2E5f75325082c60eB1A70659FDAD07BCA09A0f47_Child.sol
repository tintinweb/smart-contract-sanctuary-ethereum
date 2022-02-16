// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

contract Factory {
      Child[] public  children;
      function createChild(uint data) public {
         Child child = new Child(data);
         children.push(child);
      }
}
contract Child{
     uint data;
     constructor(uint _data){
        data = _data;
     }
}