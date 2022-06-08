/**
 *Submitted for verification at Etherscan.io on 2022-06-07
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.7;

contract Messagee {
    string message = "";
    
    function setMessage(string calldata _message) public {
        message = _message;
    }

    function getMessage() public view returns (string memory) {
        return  message;
    }

}