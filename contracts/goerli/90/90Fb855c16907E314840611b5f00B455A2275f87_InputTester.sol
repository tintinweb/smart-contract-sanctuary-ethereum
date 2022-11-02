/**
 *Submitted for verification at Etherscan.io on 2022-11-02
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

contract InputTester {

    struct TheStruct {
        bool isToggled;
        string title;
        string author;
        uint book_id;
        address addr;
        string[] tags;
        TheStruct2 meta;
    }

    struct TheStruct2 {
        string subtitle;
        uint pages;
    }

    TheStruct public originalTheStruct;

    event Uint256Inputed(uint256 num);
    event AddressInputed(address addr);
    event StringInputed(string str);
    event BoolInputed(bool bl);
    event UnlimitedStringsInputed(string[] strings);
    event UnlimitedUint256Inputed(uint256[] nums);
    event StructInputed(TheStruct theStruct);
    event StructArrayInputed(TheStruct[3] structs);

    function inputUint256(uint256 num) public {
        emit Uint256Inputed(num);
    }

    function inputAddress(address addr) public {
        emit AddressInputed(addr);
    }

    function inputString(string calldata str) public {
        emit StringInputed(str);
    }

    function inputBool(bool bl) public {
        emit BoolInputed(bl);
    }

    function inputUnlimitedStrings(string[] calldata strings) public {
        emit UnlimitedStringsInputed(strings);
    }

    function inputUnlimitedUints(uint256[] calldata nums) public {
        emit UnlimitedUint256Inputed(nums);
    }

    function inputStruct(TheStruct calldata theStruct) public {
        emit StructInputed(theStruct);
    }

    function inputArrayOfStructs(TheStruct[3] calldata structs) public {
        emit StructArrayInputed(structs);
    }
}