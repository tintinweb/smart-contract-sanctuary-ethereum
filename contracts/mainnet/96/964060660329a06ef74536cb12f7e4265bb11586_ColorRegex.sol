/**
 *Submitted for verification at Etherscan.io on 2022-09-11
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8;

contract ColorRegex {
    struct State {
        bool accepts;
        function (bytes1) pure internal returns (State memory) func;
    }

    string public constant regex = "#([0-9a-f]{3}){1,2}";

    function s0(bytes1 c) pure internal returns (State memory) {
        c = c;
        return State(false, s0);
    }

    function s1(bytes1 c) pure internal returns (State memory) {
        uint8 _cint = uint8(c);
        if (_cint == 35) 
            return State(false, s2);
        return State(false, s0);
    }

    function s2(bytes1 c) pure internal returns (State memory) {
        uint8 _cint = uint8(c);
        if (_cint >= 48 && _cint <= 57 || _cint >= 97 && _cint <= 102)
            return State(false, s3);
        return State(false, s0);
    }

    function s3(bytes1 c) pure internal returns (State memory) {
        uint8 _cint = uint8(c);
        if (_cint >= 48 && _cint <= 57 || _cint >= 97 && _cint <= 102)
            return State(false, s4);
        return State(false, s0);
    }

    function s4(bytes1 c) pure internal returns (State memory) {
        uint8 _cint = uint8(c);
        if (_cint >= 48 && _cint <= 57 || _cint >= 97 && _cint <= 102)
            return State(true, s5);
        return State(false, s0);
    }

    function s5(bytes1 c) pure internal returns (State memory) {
        uint8 _cint = uint8(c);
        if (_cint >= 48 && _cint <= 57 || _cint >= 97 && _cint <= 102)
            return State(false, s6);
        return State(false, s0);
    }

    function s6(bytes1 c) pure internal returns (State memory) {
        uint8 _cint = uint8(c);
        if (_cint >= 48 && _cint <= 57 || _cint >= 97 && _cint <= 102)
            return State(false, s7);
        return State(false, s0);
    }

    function s7(bytes1 c) pure internal returns (State memory) {
        uint8 _cint = uint8(c);
        if (_cint >= 48 && _cint <= 57 || _cint >= 97 && _cint <= 102)
            return State(true, s8);
        return State(false, s0);
    }

    function s8(bytes1 c) pure internal returns (State memory) {
        uint8 _cint = uint8(c);
        _cint = _cint;
        return State(false, s0);
    }

    function matches(string memory input) public pure returns (bool) {
        State memory cur = State(false, s1);
        uint i = 0;
        while (i < bytes(input).length) {
            bytes1 c = bytes(input)[i];
            cur = cur.func(c);
            i++;
        }
        return cur.accepts;
    }
}