// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

contract implementation {

 string public str1="hello1";
   address sender;
function setstr() public {
      sender=msg.sender;
    }
    function getstr() public view returns (string memory){
      return str1;
    }

}