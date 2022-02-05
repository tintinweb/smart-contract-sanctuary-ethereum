/**
 *Submitted for verification at Etherscan.io on 2022-02-05
*/

//SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;

contract FirstContract {
    
    string private message;
    
    constructor() {
        message = "Test";
    }
    
    function setMsg(string memory newMessage) public {
        message = newMessage;
    }
    
    function getMsg() public view returns (string memory) {
        return message;
    }
}