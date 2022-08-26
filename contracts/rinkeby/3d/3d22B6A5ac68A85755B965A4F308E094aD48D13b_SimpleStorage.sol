//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract SimpleStorage {
    string public data;

    function setData(string memory newData) public {
        data = newData;
    }
}