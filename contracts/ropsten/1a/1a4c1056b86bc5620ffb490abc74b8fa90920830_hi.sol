// SPDX-License-Identifier: MIT

pragma solidity >= 0.7.3;

contract hi {
    event updatedString(string oldStr, string newStr);

    string public s;

    constructor (string memory initStr) {
        s = initStr;
    }
    
    function update(string memory newStr) public {
        string memory oldStr = s; 
        s = newStr;
        emit updatedString(oldStr, newStr);
    }
}