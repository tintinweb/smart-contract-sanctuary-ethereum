// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract EthereumRegex {
    struct State {
        bool accepts;
        function(bytes1) internal pure returns (State memory) func;
    }

    string public constant regex = "0x[0-9a-fA-F]{40}";

    function s0(bytes1 c) internal pure returns (State memory) {
        c = c;
        return State(false, s0);
    }

    function s1(bytes1 c) internal pure returns (State memory) {
        uint8 _cint = uint8(c);

        if (_cint == 48) {
            return State(false, s2);
        }

        return State(false, s0);
    }

    function s2(bytes1 c) internal pure returns (State memory) {
        uint8 _cint = uint8(c);

        if (_cint == 120) {
            return State(false, s3);
        }

        return State(false, s0);
    }

    function s3(bytes1 c) internal pure returns (State memory) {
        uint8 _cint = uint8(c);

        if ((_cint >= 48 && _cint <= 57) || (_cint >= 65 && _cint <= 70) || (_cint >= 97 && _cint <= 102)) {
            return State(false, s4);
        }

        return State(false, s0);
    }

    function s4(bytes1 c) internal pure returns (State memory) {
        uint8 _cint = uint8(c);

        if ((_cint >= 48 && _cint <= 57) || (_cint >= 65 && _cint <= 70) || (_cint >= 97 && _cint <= 102)) {
            return State(false, s5);
        }

        return State(false, s0);
    }

    function s5(bytes1 c) internal pure returns (State memory) {
        uint8 _cint = uint8(c);

        if ((_cint >= 48 && _cint <= 57) || (_cint >= 65 && _cint <= 70) || (_cint >= 97 && _cint <= 102)) {
            return State(false, s6);
        }

        return State(false, s0);
    }

    function s6(bytes1 c) internal pure returns (State memory) {
        uint8 _cint = uint8(c);

        if ((_cint >= 48 && _cint <= 57) || (_cint >= 65 && _cint <= 70) || (_cint >= 97 && _cint <= 102)) {
            return State(false, s7);
        }

        return State(false, s0);
    }

    function s7(bytes1 c) internal pure returns (State memory) {
        uint8 _cint = uint8(c);

        if ((_cint >= 48 && _cint <= 57) || (_cint >= 65 && _cint <= 70) || (_cint >= 97 && _cint <= 102)) {
            return State(false, s8);
        }

        return State(false, s0);
    }

    function s8(bytes1 c) internal pure returns (State memory) {
        uint8 _cint = uint8(c);

        if ((_cint >= 48 && _cint <= 57) || (_cint >= 65 && _cint <= 70) || (_cint >= 97 && _cint <= 102)) {
            return State(false, s9);
        }

        return State(false, s0);
    }

    function s9(bytes1 c) internal pure returns (State memory) {
        uint8 _cint = uint8(c);

        if ((_cint >= 48 && _cint <= 57) || (_cint >= 65 && _cint <= 70) || (_cint >= 97 && _cint <= 102)) {
            return State(false, s10);
        }

        return State(false, s0);
    }

    function s10(bytes1 c) internal pure returns (State memory) {
        uint8 _cint = uint8(c);

        if ((_cint >= 48 && _cint <= 57) || (_cint >= 65 && _cint <= 70) || (_cint >= 97 && _cint <= 102)) {
            return State(false, s11);
        }

        return State(false, s0);
    }

    function s11(bytes1 c) internal pure returns (State memory) {
        uint8 _cint = uint8(c);

        if ((_cint >= 48 && _cint <= 57) || (_cint >= 65 && _cint <= 70) || (_cint >= 97 && _cint <= 102)) {
            return State(false, s12);
        }

        return State(false, s0);
    }

    function s12(bytes1 c) internal pure returns (State memory) {
        uint8 _cint = uint8(c);

        if ((_cint >= 48 && _cint <= 57) || (_cint >= 65 && _cint <= 70) || (_cint >= 97 && _cint <= 102)) {
            return State(false, s13);
        }

        return State(false, s0);
    }

    function s13(bytes1 c) internal pure returns (State memory) {
        uint8 _cint = uint8(c);

        if ((_cint >= 48 && _cint <= 57) || (_cint >= 65 && _cint <= 70) || (_cint >= 97 && _cint <= 102)) {
            return State(false, s14);
        }

        return State(false, s0);
    }

    function s14(bytes1 c) internal pure returns (State memory) {
        uint8 _cint = uint8(c);

        if ((_cint >= 48 && _cint <= 57) || (_cint >= 65 && _cint <= 70) || (_cint >= 97 && _cint <= 102)) {
            return State(false, s15);
        }

        return State(false, s0);
    }

    function s15(bytes1 c) internal pure returns (State memory) {
        uint8 _cint = uint8(c);

        if ((_cint >= 48 && _cint <= 57) || (_cint >= 65 && _cint <= 70) || (_cint >= 97 && _cint <= 102)) {
            return State(false, s16);
        }

        return State(false, s0);
    }

    function s16(bytes1 c) internal pure returns (State memory) {
        uint8 _cint = uint8(c);

        if ((_cint >= 48 && _cint <= 57) || (_cint >= 65 && _cint <= 70) || (_cint >= 97 && _cint <= 102)) {
            return State(false, s17);
        }

        return State(false, s0);
    }

    function s17(bytes1 c) internal pure returns (State memory) {
        uint8 _cint = uint8(c);

        if ((_cint >= 48 && _cint <= 57) || (_cint >= 65 && _cint <= 70) || (_cint >= 97 && _cint <= 102)) {
            return State(false, s18);
        }

        return State(false, s0);
    }

    function s18(bytes1 c) internal pure returns (State memory) {
        uint8 _cint = uint8(c);

        if ((_cint >= 48 && _cint <= 57) || (_cint >= 65 && _cint <= 70) || (_cint >= 97 && _cint <= 102)) {
            return State(false, s19);
        }

        return State(false, s0);
    }

    function s19(bytes1 c) internal pure returns (State memory) {
        uint8 _cint = uint8(c);

        if ((_cint >= 48 && _cint <= 57) || (_cint >= 65 && _cint <= 70) || (_cint >= 97 && _cint <= 102)) {
            return State(false, s20);
        }

        return State(false, s0);
    }

    function s20(bytes1 c) internal pure returns (State memory) {
        uint8 _cint = uint8(c);

        if ((_cint >= 48 && _cint <= 57) || (_cint >= 65 && _cint <= 70) || (_cint >= 97 && _cint <= 102)) {
            return State(false, s21);
        }

        return State(false, s0);
    }

    function s21(bytes1 c) internal pure returns (State memory) {
        uint8 _cint = uint8(c);

        if ((_cint >= 48 && _cint <= 57) || (_cint >= 65 && _cint <= 70) || (_cint >= 97 && _cint <= 102)) {
            return State(false, s22);
        }

        return State(false, s0);
    }

    function s22(bytes1 c) internal pure returns (State memory) {
        uint8 _cint = uint8(c);

        if ((_cint >= 48 && _cint <= 57) || (_cint >= 65 && _cint <= 70) || (_cint >= 97 && _cint <= 102)) {
            return State(false, s23);
        }

        return State(false, s0);
    }

    function s23(bytes1 c) internal pure returns (State memory) {
        uint8 _cint = uint8(c);

        if ((_cint >= 48 && _cint <= 57) || (_cint >= 65 && _cint <= 70) || (_cint >= 97 && _cint <= 102)) {
            return State(false, s24);
        }

        return State(false, s0);
    }

    function s24(bytes1 c) internal pure returns (State memory) {
        uint8 _cint = uint8(c);

        if ((_cint >= 48 && _cint <= 57) || (_cint >= 65 && _cint <= 70) || (_cint >= 97 && _cint <= 102)) {
            return State(false, s25);
        }

        return State(false, s0);
    }

    function s25(bytes1 c) internal pure returns (State memory) {
        uint8 _cint = uint8(c);

        if ((_cint >= 48 && _cint <= 57) || (_cint >= 65 && _cint <= 70) || (_cint >= 97 && _cint <= 102)) {
            return State(false, s26);
        }

        return State(false, s0);
    }

    function s26(bytes1 c) internal pure returns (State memory) {
        uint8 _cint = uint8(c);

        if ((_cint >= 48 && _cint <= 57) || (_cint >= 65 && _cint <= 70) || (_cint >= 97 && _cint <= 102)) {
            return State(false, s27);
        }

        return State(false, s0);
    }

    function s27(bytes1 c) internal pure returns (State memory) {
        uint8 _cint = uint8(c);

        if ((_cint >= 48 && _cint <= 57) || (_cint >= 65 && _cint <= 70) || (_cint >= 97 && _cint <= 102)) {
            return State(false, s28);
        }

        return State(false, s0);
    }

    function s28(bytes1 c) internal pure returns (State memory) {
        uint8 _cint = uint8(c);

        if ((_cint >= 48 && _cint <= 57) || (_cint >= 65 && _cint <= 70) || (_cint >= 97 && _cint <= 102)) {
            return State(false, s29);
        }

        return State(false, s0);
    }

    function s29(bytes1 c) internal pure returns (State memory) {
        uint8 _cint = uint8(c);

        if ((_cint >= 48 && _cint <= 57) || (_cint >= 65 && _cint <= 70) || (_cint >= 97 && _cint <= 102)) {
            return State(false, s30);
        }

        return State(false, s0);
    }

    function s30(bytes1 c) internal pure returns (State memory) {
        uint8 _cint = uint8(c);

        if ((_cint >= 48 && _cint <= 57) || (_cint >= 65 && _cint <= 70) || (_cint >= 97 && _cint <= 102)) {
            return State(false, s31);
        }

        return State(false, s0);
    }

    function s31(bytes1 c) internal pure returns (State memory) {
        uint8 _cint = uint8(c);

        if ((_cint >= 48 && _cint <= 57) || (_cint >= 65 && _cint <= 70) || (_cint >= 97 && _cint <= 102)) {
            return State(false, s32);
        }

        return State(false, s0);
    }

    function s32(bytes1 c) internal pure returns (State memory) {
        uint8 _cint = uint8(c);

        if ((_cint >= 48 && _cint <= 57) || (_cint >= 65 && _cint <= 70) || (_cint >= 97 && _cint <= 102)) {
            return State(false, s33);
        }

        return State(false, s0);
    }

    function s33(bytes1 c) internal pure returns (State memory) {
        uint8 _cint = uint8(c);

        if ((_cint >= 48 && _cint <= 57) || (_cint >= 65 && _cint <= 70) || (_cint >= 97 && _cint <= 102)) {
            return State(false, s34);
        }

        return State(false, s0);
    }

    function s34(bytes1 c) internal pure returns (State memory) {
        uint8 _cint = uint8(c);

        if ((_cint >= 48 && _cint <= 57) || (_cint >= 65 && _cint <= 70) || (_cint >= 97 && _cint <= 102)) {
            return State(false, s35);
        }

        return State(false, s0);
    }

    function s35(bytes1 c) internal pure returns (State memory) {
        uint8 _cint = uint8(c);

        if ((_cint >= 48 && _cint <= 57) || (_cint >= 65 && _cint <= 70) || (_cint >= 97 && _cint <= 102)) {
            return State(false, s36);
        }

        return State(false, s0);
    }

    function s36(bytes1 c) internal pure returns (State memory) {
        uint8 _cint = uint8(c);

        if ((_cint >= 48 && _cint <= 57) || (_cint >= 65 && _cint <= 70) || (_cint >= 97 && _cint <= 102)) {
            return State(false, s37);
        }

        return State(false, s0);
    }

    function s37(bytes1 c) internal pure returns (State memory) {
        uint8 _cint = uint8(c);

        if ((_cint >= 48 && _cint <= 57) || (_cint >= 65 && _cint <= 70) || (_cint >= 97 && _cint <= 102)) {
            return State(false, s38);
        }

        return State(false, s0);
    }

    function s38(bytes1 c) internal pure returns (State memory) {
        uint8 _cint = uint8(c);

        if ((_cint >= 48 && _cint <= 57) || (_cint >= 65 && _cint <= 70) || (_cint >= 97 && _cint <= 102)) {
            return State(false, s39);
        }

        return State(false, s0);
    }

    function s39(bytes1 c) internal pure returns (State memory) {
        uint8 _cint = uint8(c);

        if ((_cint >= 48 && _cint <= 57) || (_cint >= 65 && _cint <= 70) || (_cint >= 97 && _cint <= 102)) {
            return State(false, s40);
        }

        return State(false, s0);
    }

    function s40(bytes1 c) internal pure returns (State memory) {
        uint8 _cint = uint8(c);

        if ((_cint >= 48 && _cint <= 57) || (_cint >= 65 && _cint <= 70) || (_cint >= 97 && _cint <= 102)) {
            return State(false, s41);
        }

        return State(false, s0);
    }

    function s41(bytes1 c) internal pure returns (State memory) {
        uint8 _cint = uint8(c);

        if ((_cint >= 48 && _cint <= 57) || (_cint >= 65 && _cint <= 70) || (_cint >= 97 && _cint <= 102)) {
            return State(false, s42);
        }

        return State(false, s0);
    }

    function s42(bytes1 c) internal pure returns (State memory) {
        uint8 _cint = uint8(c);

        if ((_cint >= 48 && _cint <= 57) || (_cint >= 65 && _cint <= 70) || (_cint >= 97 && _cint <= 102)) {
            return State(true, s43);
        }

        return State(false, s0);
    }

    function s43(bytes1 c) internal pure returns (State memory) {
        uint8 _cint = uint8(c);

        // silence unused var warning
        _cint = _cint;

        return State(false, s0);
    }

    function matches(string memory input) public pure returns (bool) {
        State memory cur = State(false, s1);

        for (uint256 i = 0; i < bytes(input).length; i++) {
            bytes1 c = bytes(input)[i];

            cur = cur.func(c);
        }

        return cur.accepts;
    }
}