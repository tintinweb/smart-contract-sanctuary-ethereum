// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

contract Hello {
    string private _storedString;

    function setString(string memory newString) public {
        _storedString = newString;
    }

    function getString() public view returns (string memory) {
        return _storedString;
    }
}