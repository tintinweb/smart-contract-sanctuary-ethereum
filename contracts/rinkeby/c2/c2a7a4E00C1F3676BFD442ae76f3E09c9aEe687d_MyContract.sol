/**
 *Submitted for verification at Etherscan.io on 2022-03-26
*/

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

contract MyContract {
    string _message;
    
    constructor(string memory name) {
        _message = string(abi.encodePacked("I love ", name));
    }

    function Hello() public pure returns(string memory) {
        return "Hello World";
    }

    function ShowMessage() public view returns(string memory) {
        return _message;
    }
}