/**
 *Submitted for verification at Etherscan.io on 2022-06-21
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

contract Test {
    struct TupleBool {
        bool a;
        bool b;
    }
    struct TupleBoolWithBoolArray {
        bool a;
        bool[] b;
    }

    function a(bool data) public pure returns(bool) {
        return data;
    }
    function b(TupleBool memory data) public pure returns(TupleBool memory) {
        return data;
    }
    function c(TupleBool[] memory data) public pure returns(TupleBool[] memory) {
        return data;
    }
    function c(TupleBoolWithBoolArray memory data) public pure returns(TupleBoolWithBoolArray memory) {
        return data;
    }
    function d(TupleBoolWithBoolArray[] memory data) public pure returns(TupleBoolWithBoolArray[] memory) {
        return data;
    }
}