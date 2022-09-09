// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

contract Hello {
    string private _storedString;
    uint256 private _storedUint;

    function setString(string memory newString) public {
        _storedString = newString;
    }

    function getString() public view returns (string memory) {
        return _storedString;
    }

    function setUint(uint256 newUint) public {
        _storedUint = newUint;
    }

    function getUint() public view returns (uint256) {
        return _storedUint;
    }
}