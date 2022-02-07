/**
 *Submitted for verification at Etherscan.io on 2022-02-07
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

contract FirstContract {

    string private _message;

    constructor(string memory initialMessage) {
        _message = initialMessage;
    }

    function setMessage(string memory newMessage) public {
        _message = newMessage;
    }

    function getMessage() public view returns(string memory) {
        return _message;
    }
}