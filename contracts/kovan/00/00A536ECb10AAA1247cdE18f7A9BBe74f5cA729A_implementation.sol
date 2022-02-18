// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

contract implementation {

 string  greetings="hello1";
   address sender;
function setstr(string memory _newstr) public {
      sender=msg.sender;
      greetings=_newstr;
    }
    function getstr() public view returns (string memory){
      return greetings;
    }

}