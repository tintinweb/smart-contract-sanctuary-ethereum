/**
 *Submitted for verification at Etherscan.io on 2022-01-31
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;
contract HelloWorld{
    string private message ;

    constructor(string memory _message) {
        message = _message;
        
    }
    function getmessage() public view returns (string memory )  {
        return  message;
    }
    function setmessage (string memory _message) public{
       message = _message;
    }
}