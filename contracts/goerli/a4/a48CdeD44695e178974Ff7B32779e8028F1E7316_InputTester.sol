/**
 *Submitted for verification at Etherscan.io on 2022-11-02
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

contract InputTester {

    struct StructWithArray {
        string title;
        string[] tags;
    }

    struct NestedStruct {
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

    event Uint256Inputed(uint256 num);
    event AddressInputed(address addr);
    event StringInputed(string str);
    event BoolInputed(bool bl);
    event UnlimitedStringsInputed(string[] strings);
    event UnlimitedUint256Inputed(uint256[] nums);
    event StructWithArrayInputed(StructWithArray structWithArray);
    event NestedStructInputed(NestedStruct nestedStruct);
    event NestedStructsArrayInputed(NestedStruct[] nestedStructs);

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

    function inputStructWithArray(StructWithArray calldata structWithArray) public {
        emit StructWithArrayInputed(structWithArray);
    }

    function inputNestedStruct(NestedStruct calldata nestedStruct) public {
        emit NestedStructInputed(nestedStruct);
    }

    function inputArrayOfNestedStructs(NestedStruct[] calldata nestedStructs) public {
        emit NestedStructsArrayInputed(nestedStructs);
    }
}