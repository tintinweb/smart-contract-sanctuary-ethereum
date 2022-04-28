/**
 *Submitted for verification at Etherscan.io on 2022-04-28
*/

// SPDX-License-Identifier:MIT
pragma solidity>=0.4.0<0.9.0;
contract Greeter{
    string private message;
   

 function setmessage(string memory _msg )public{
    message=_msg;
  }

function checkmessage()  public view returns(string memory){
    return message;
}

}