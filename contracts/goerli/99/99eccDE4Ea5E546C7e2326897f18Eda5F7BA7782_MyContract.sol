// SPDX-License-Identifier: MIT

// Deployed with the Atlas IDE
// https://app.atlaszk.com

pragma solidity ^0.8.0;

contract MyContract {
    struct MyStruct {
        address userAddress;
        uint32 someNumber;
        bytes someData;
    }

    mapping(uint => MyStruct) public myStructs;

    function setMyStruct(
        uint index,
        address _userAddress,
        uint32 _someNumber,
        bytes memory _someData
    ) public {
        MyStruct memory newStruct = MyStruct(_userAddress, _someNumber, _someData);
        myStructs[index] = newStruct;
    }

    function getMyStruct(uint index) public view returns (MyStruct memory) {
        return myStructs[index];
    }
}