// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {IChonkyAttributes} from "./interface/IChonkyAttributes.sol";

contract ChonkyAttributes is IChonkyAttributes {
    function _getBodyAttribute(uint256 _id)
        internal
        pure
        returns (IChonkyAttributes.AttributeType, uint256)
    {
        if (_id == 0) return (IChonkyAttributes.AttributeType.NONE, 0);

        if (_id == 1) return (IChonkyAttributes.AttributeType.CUTE, 7);
        if (_id == 2) return (IChonkyAttributes.AttributeType.CUTE, 6);
        if (_id == 3) return (IChonkyAttributes.AttributeType.WICKED, 8);
        if (_id == 4) return (IChonkyAttributes.AttributeType.BRAIN, 9);
        if (_id == 5) return (IChonkyAttributes.AttributeType.POWER, 3);
        if (_id == 6) return (IChonkyAttributes.AttributeType.WICKED, 10);
        if (_id == 7) return (IChonkyAttributes.AttributeType.CUTE, 9);
        if (_id == 8) return (IChonkyAttributes.AttributeType.POWER, 10);
        if (_id == 9) return (IChonkyAttributes.AttributeType.WICKED, 2);
        if (_id == 10) return (IChonkyAttributes.AttributeType.POWER, 2);
        if (_id == 11) return (IChonkyAttributes.AttributeType.CUTE, 6);
        if (_id == 12) return (IChonkyAttributes.AttributeType.CUTE, 4);
        if (_id == 13) return (IChonkyAttributes.AttributeType.POWER, 1);
        if (_id == 14) return (IChonkyAttributes.AttributeType.BRAIN, 2);
        if (_id == 15) return (IChonkyAttributes.AttributeType.BRAIN, 6);
        if (_id == 16) return (IChonkyAttributes.AttributeType.CUTE, 5);
        if (_id == 17) return (IChonkyAttributes.AttributeType.POWER, 3);
        if (_id == 18) return (IChonkyAttributes.AttributeType.POWER, 2);
        if (_id == 19) return (IChonkyAttributes.AttributeType.BRAIN, 1);
        if (_id == 20) return (IChonkyAttributes.AttributeType.CUTE, 2);
        if (_id == 21) return (IChonkyAttributes.AttributeType.WICKED, 3);
        if (_id == 22) return (IChonkyAttributes.AttributeType.WICKED, 4);
        if (_id == 23) return (IChonkyAttributes.AttributeType.POWER, 5);
        if (_id == 24) return (IChonkyAttributes.AttributeType.POWER, 8);
        if (_id == 25) return (IChonkyAttributes.AttributeType.WICKED, 6);
        if (_id == 26) return (IChonkyAttributes.AttributeType.POWER, 8);
        if (_id == 27) return (IChonkyAttributes.AttributeType.CUTE, 1);
        if (_id == 28) return (IChonkyAttributes.AttributeType.WICKED, 8);
        if (_id == 29) return (IChonkyAttributes.AttributeType.POWER, 2);
        if (_id == 30) return (IChonkyAttributes.AttributeType.BRAIN, 8);
        if (_id == 31) return (IChonkyAttributes.AttributeType.POWER, 6);
        if (_id == 32) return (IChonkyAttributes.AttributeType.CUTE, 4);
        if (_id == 33) return (IChonkyAttributes.AttributeType.POWER, 1);
        if (_id == 34) return (IChonkyAttributes.AttributeType.POWER, 2);
        if (_id == 35) return (IChonkyAttributes.AttributeType.WICKED, 5);
        if (_id == 36) return (IChonkyAttributes.AttributeType.CUTE, 7);
        if (_id == 37) return (IChonkyAttributes.AttributeType.CUTE, 5);
        if (_id == 38) return (IChonkyAttributes.AttributeType.POWER, 5);
        if (_id == 39) return (IChonkyAttributes.AttributeType.POWER, 10);
        if (_id == 40) return (IChonkyAttributes.AttributeType.POWER, 4);
        if (_id == 41) return (IChonkyAttributes.AttributeType.WICKED, 7);
        if (_id == 42) return (IChonkyAttributes.AttributeType.WICKED, 8);
        if (_id == 43) return (IChonkyAttributes.AttributeType.POWER, 9);
        if (_id == 44) return (IChonkyAttributes.AttributeType.BRAIN, 8);
        if (_id == 45) return (IChonkyAttributes.AttributeType.CUTE, 1);
        if (_id == 46) return (IChonkyAttributes.AttributeType.WICKED, 8);
        if (_id == 47) return (IChonkyAttributes.AttributeType.CUTE, 6);
        if (_id == 48) return (IChonkyAttributes.AttributeType.POWER, 7);
        if (_id == 49) return (IChonkyAttributes.AttributeType.CUTE, 1);
        if (_id == 50) return (IChonkyAttributes.AttributeType.POWER, 1);
        if (_id == 51) return (IChonkyAttributes.AttributeType.POWER, 6);
        if (_id == 52) return (IChonkyAttributes.AttributeType.WICKED, 7);
        if (_id == 53) return (IChonkyAttributes.AttributeType.POWER, 9);
        if (_id == 54) return (IChonkyAttributes.AttributeType.POWER, 3);
        if (_id == 55) return (IChonkyAttributes.AttributeType.CUTE, 2);
        if (_id == 56) return (IChonkyAttributes.AttributeType.POWER, 2);
        if (_id == 57) return (IChonkyAttributes.AttributeType.CUTE, 3);
        if (_id == 58) return (IChonkyAttributes.AttributeType.BRAIN, 1);
        if (_id == 59) return (IChonkyAttributes.AttributeType.POWER, 8);
        if (_id == 60) return (IChonkyAttributes.AttributeType.WICKED, 9);
        if (_id == 61) return (IChonkyAttributes.AttributeType.POWER, 5);
        if (_id == 62) return (IChonkyAttributes.AttributeType.BRAIN, 8);
        if (_id == 63) return (IChonkyAttributes.AttributeType.BRAIN, 2);
        if (_id == 64) return (IChonkyAttributes.AttributeType.BRAIN, 3);
        if (_id == 65) return (IChonkyAttributes.AttributeType.CUTE, 10);
        if (_id == 66) return (IChonkyAttributes.AttributeType.CUTE, 1);
        if (_id == 67) return (IChonkyAttributes.AttributeType.CUTE, 3);
        if (_id == 68) return (IChonkyAttributes.AttributeType.BRAIN, 8);
        if (_id == 69) return (IChonkyAttributes.AttributeType.POWER, 1);
        if (_id == 70) return (IChonkyAttributes.AttributeType.BRAIN, 10);
        if (_id == 71) return (IChonkyAttributes.AttributeType.BRAIN, 7);
        if (_id == 72) return (IChonkyAttributes.AttributeType.POWER, 6);
        if (_id == 73) return (IChonkyAttributes.AttributeType.POWER, 7);
        if (_id == 74) return (IChonkyAttributes.AttributeType.POWER, 7);
        if (_id == 75) return (IChonkyAttributes.AttributeType.POWER, 5);
        if (_id == 76) return (IChonkyAttributes.AttributeType.BRAIN, 9);
        if (_id == 77) return (IChonkyAttributes.AttributeType.BRAIN, 1);
        if (_id == 78) return (IChonkyAttributes.AttributeType.CUTE, 2);
        if (_id == 79) return (IChonkyAttributes.AttributeType.POWER, 9);
        if (_id == 80) return (IChonkyAttributes.AttributeType.BRAIN, 9);
        if (_id == 81) return (IChonkyAttributes.AttributeType.POWER, 2);
        if (_id == 82) return (IChonkyAttributes.AttributeType.BRAIN, 3);
        if (_id == 83) return (IChonkyAttributes.AttributeType.CUTE, 8);
        if (_id == 84) return (IChonkyAttributes.AttributeType.CUTE, 7);
        if (_id == 85) return (IChonkyAttributes.AttributeType.BRAIN, 7);
        if (_id == 86) return (IChonkyAttributes.AttributeType.POWER, 9);
        if (_id == 87) return (IChonkyAttributes.AttributeType.POWER, 4);
        if (_id == 88) return (IChonkyAttributes.AttributeType.WICKED, 5);
        if (_id == 89) return (IChonkyAttributes.AttributeType.BRAIN, 4);
        if (_id == 90) return (IChonkyAttributes.AttributeType.POWER, 1);
        if (_id == 91) return (IChonkyAttributes.AttributeType.WICKED, 8);

        return (IChonkyAttributes.AttributeType.NONE, 0);
    }

    function _getEyesAttribute(uint256 _id)
        internal
        pure
        returns (IChonkyAttributes.AttributeType, uint256)
    {
        if (_id == 0) return (IChonkyAttributes.AttributeType.NONE, 0);

        if (_id == 1) return (IChonkyAttributes.AttributeType.CUTE, 2);
        if (_id == 2) return (IChonkyAttributes.AttributeType.CUTE, 1);
        if (_id == 3) return (IChonkyAttributes.AttributeType.NONE, 0);
        if (_id == 4) return (IChonkyAttributes.AttributeType.POWER, 6);
        if (_id == 5) return (IChonkyAttributes.AttributeType.POWER, 5);
        if (_id == 6) return (IChonkyAttributes.AttributeType.WICKED, 7);
        if (_id == 7) return (IChonkyAttributes.AttributeType.NONE, 0);
        if (_id == 8) return (IChonkyAttributes.AttributeType.WICKED, 2);
        if (_id == 9) return (IChonkyAttributes.AttributeType.CUTE, 7);
        if (_id == 10) return (IChonkyAttributes.AttributeType.BRAIN, 8);
        if (_id == 11) return (IChonkyAttributes.AttributeType.WICKED, 10);
        if (_id == 12) return (IChonkyAttributes.AttributeType.NONE, 0);
        if (_id == 13) return (IChonkyAttributes.AttributeType.NONE, 0);
        if (_id == 14) return (IChonkyAttributes.AttributeType.CUTE, 8);
        if (_id == 15) return (IChonkyAttributes.AttributeType.NONE, 0);
        if (_id == 16) return (IChonkyAttributes.AttributeType.NONE, 0);
        if (_id == 17) return (IChonkyAttributes.AttributeType.WICKED, 8);
        if (_id == 18) return (IChonkyAttributes.AttributeType.BRAIN, 6);
        if (_id == 19) return (IChonkyAttributes.AttributeType.CUTE, 5);
        if (_id == 20) return (IChonkyAttributes.AttributeType.NONE, 0);
        if (_id == 21) return (IChonkyAttributes.AttributeType.NONE, 0);
        if (_id == 22) return (IChonkyAttributes.AttributeType.WICKED, 4);
        if (_id == 23) return (IChonkyAttributes.AttributeType.BRAIN, 3);
        if (_id == 24) return (IChonkyAttributes.AttributeType.POWER, 3);
        if (_id == 25) return (IChonkyAttributes.AttributeType.POWER, 6);
        if (_id == 26) return (IChonkyAttributes.AttributeType.CUTE, 7);
        if (_id == 27) return (IChonkyAttributes.AttributeType.CUTE, 6);
        if (_id == 28) return (IChonkyAttributes.AttributeType.NONE, 0);
        if (_id == 29) return (IChonkyAttributes.AttributeType.BRAIN, 1);
        if (_id == 30) return (IChonkyAttributes.AttributeType.CUTE, 4);
        if (_id == 31) return (IChonkyAttributes.AttributeType.POWER, 3);
        if (_id == 32) return (IChonkyAttributes.AttributeType.BRAIN, 8);
        if (_id == 33) return (IChonkyAttributes.AttributeType.WICKED, 6);
        if (_id == 34) return (IChonkyAttributes.AttributeType.POWER, 9);
        if (_id == 35) return (IChonkyAttributes.AttributeType.NONE, 0);
        if (_id == 36) return (IChonkyAttributes.AttributeType.NONE, 0);
        if (_id == 37) return (IChonkyAttributes.AttributeType.WICKED, 2);
        if (_id == 38) return (IChonkyAttributes.AttributeType.POWER, 5);
        if (_id == 39) return (IChonkyAttributes.AttributeType.CUTE, 5);
        if (_id == 40) return (IChonkyAttributes.AttributeType.NONE, 0);
        if (_id == 41) return (IChonkyAttributes.AttributeType.BRAIN, 7);
        if (_id == 42) return (IChonkyAttributes.AttributeType.WICKED, 10);
        if (_id == 43) return (IChonkyAttributes.AttributeType.NONE, 0);
        if (_id == 44) return (IChonkyAttributes.AttributeType.NONE, 0);
        if (_id == 45) return (IChonkyAttributes.AttributeType.WICKED, 9);
        if (_id == 46) return (IChonkyAttributes.AttributeType.CUTE, 4);
        if (_id == 47) return (IChonkyAttributes.AttributeType.BRAIN, 8);
        if (_id == 48) return (IChonkyAttributes.AttributeType.NONE, 0);
        if (_id == 49) return (IChonkyAttributes.AttributeType.CUTE, 6);
        if (_id == 50) return (IChonkyAttributes.AttributeType.POWER, 5);
        if (_id == 51) return (IChonkyAttributes.AttributeType.NONE, 0);
        if (_id == 52) return (IChonkyAttributes.AttributeType.BRAIN, 4);
        if (_id == 53) return (IChonkyAttributes.AttributeType.BRAIN, 9);
        if (_id == 54) return (IChonkyAttributes.AttributeType.POWER, 4);
        if (_id == 55) return (IChonkyAttributes.AttributeType.CUTE, 2);
        if (_id == 56) return (IChonkyAttributes.AttributeType.NONE, 0);
        if (_id == 57) return (IChonkyAttributes.AttributeType.POWER, 3);
        if (_id == 58) return (IChonkyAttributes.AttributeType.NONE, 0);
        if (_id == 59) return (IChonkyAttributes.AttributeType.NONE, 0);
        if (_id == 60) return (IChonkyAttributes.AttributeType.WICKED, 1);
        if (_id == 61) return (IChonkyAttributes.AttributeType.WICKED, 3);

        return (IChonkyAttributes.AttributeType.NONE, 0);
    }

    function _getMouthAttribute(uint256 _id)
        internal
        pure
        returns (IChonkyAttributes.AttributeType, uint256)
    {
        if (_id == 0) return (IChonkyAttributes.AttributeType.NONE, 0);

        if (_id == 1) return (IChonkyAttributes.AttributeType.POWER, 7);
        if (_id == 2) return (IChonkyAttributes.AttributeType.WICKED, 6);
        if (_id == 3) return (IChonkyAttributes.AttributeType.NONE, 0);
        if (_id == 4) return (IChonkyAttributes.AttributeType.WICKED, 4);
        if (_id == 5) return (IChonkyAttributes.AttributeType.NONE, 0);
        if (_id == 6) return (IChonkyAttributes.AttributeType.NONE, 0);
        if (_id == 7) return (IChonkyAttributes.AttributeType.CUTE, 8);
        if (_id == 8) return (IChonkyAttributes.AttributeType.BRAIN, 5);
        if (_id == 9) return (IChonkyAttributes.AttributeType.WICKED, 8);
        if (_id == 10) return (IChonkyAttributes.AttributeType.POWER, 4);
        if (_id == 11) return (IChonkyAttributes.AttributeType.BRAIN, 8);
        if (_id == 12) return (IChonkyAttributes.AttributeType.NONE, 0);
        if (_id == 13) return (IChonkyAttributes.AttributeType.POWER, 8);
        if (_id == 14) return (IChonkyAttributes.AttributeType.CUTE, 5);
        if (_id == 15) return (IChonkyAttributes.AttributeType.WICKED, 5);
        if (_id == 16) return (IChonkyAttributes.AttributeType.CUTE, 3);
        if (_id == 17) return (IChonkyAttributes.AttributeType.BRAIN, 1);
        if (_id == 18) return (IChonkyAttributes.AttributeType.POWER, 6);
        if (_id == 19) return (IChonkyAttributes.AttributeType.NONE, 0);
        if (_id == 20) return (IChonkyAttributes.AttributeType.BRAIN, 9);
        if (_id == 21) return (IChonkyAttributes.AttributeType.CUTE, 3);
        if (_id == 22) return (IChonkyAttributes.AttributeType.CUTE, 4);
        if (_id == 23) return (IChonkyAttributes.AttributeType.NONE, 0);
        if (_id == 24) return (IChonkyAttributes.AttributeType.POWER, 5);
        if (_id == 25) return (IChonkyAttributes.AttributeType.WICKED, 4);
        if (_id == 26) return (IChonkyAttributes.AttributeType.BRAIN, 6);
        if (_id == 27) return (IChonkyAttributes.AttributeType.BRAIN, 3);
        if (_id == 28) return (IChonkyAttributes.AttributeType.BRAIN, 4);
        if (_id == 29) return (IChonkyAttributes.AttributeType.NONE, 0);
        if (_id == 30) return (IChonkyAttributes.AttributeType.POWER, 6);
        if (_id == 31) return (IChonkyAttributes.AttributeType.NONE, 0);
        if (_id == 32) return (IChonkyAttributes.AttributeType.POWER, 9);
        if (_id == 33) return (IChonkyAttributes.AttributeType.NONE, 0);
        if (_id == 34) return (IChonkyAttributes.AttributeType.NONE, 0);
        if (_id == 35) return (IChonkyAttributes.AttributeType.WICKED, 3);
        if (_id == 36) return (IChonkyAttributes.AttributeType.BRAIN, 8);
        if (_id == 37) return (IChonkyAttributes.AttributeType.POWER, 9);
        if (_id == 38) return (IChonkyAttributes.AttributeType.WICKED, 7);
        if (_id == 39) return (IChonkyAttributes.AttributeType.BRAIN, 6);
        if (_id == 40) return (IChonkyAttributes.AttributeType.CUTE, 4);
        if (_id == 41) return (IChonkyAttributes.AttributeType.POWER, 4);
        if (_id == 42) return (IChonkyAttributes.AttributeType.BRAIN, 5);
        if (_id == 43) return (IChonkyAttributes.AttributeType.CUTE, 3);
        if (_id == 44) return (IChonkyAttributes.AttributeType.BRAIN, 9);
        if (_id == 45) return (IChonkyAttributes.AttributeType.WICKED, 8);
        if (_id == 46) return (IChonkyAttributes.AttributeType.CUTE, 2);
        if (_id == 47) return (IChonkyAttributes.AttributeType.BRAIN, 2);
        if (_id == 48) return (IChonkyAttributes.AttributeType.CUTE, 1);
        if (_id == 49) return (IChonkyAttributes.AttributeType.CUTE, 1);
        if (_id == 50) return (IChonkyAttributes.AttributeType.WICKED, 1);
        if (_id == 51) return (IChonkyAttributes.AttributeType.WICKED, 5);
        if (_id == 52) return (IChonkyAttributes.AttributeType.NONE, 0);
        if (_id == 53) return (IChonkyAttributes.AttributeType.NONE, 0);
        if (_id == 54) return (IChonkyAttributes.AttributeType.NONE, 0);

        return (IChonkyAttributes.AttributeType.NONE, 0);
    }

    function _getHatAttribute(uint256 _id)
        internal
        pure
        returns (IChonkyAttributes.AttributeType, uint256)
    {
        if (_id == 0) return (IChonkyAttributes.AttributeType.NONE, 0);

        if (_id == 1) return (IChonkyAttributes.AttributeType.CUTE, 8);
        if (_id == 2) return (IChonkyAttributes.AttributeType.WICKED, 8);
        if (_id == 3) return (IChonkyAttributes.AttributeType.BRAIN, 9);
        if (_id == 4) return (IChonkyAttributes.AttributeType.CUTE, 4);
        if (_id == 5) return (IChonkyAttributes.AttributeType.WICKED, 9);
        if (_id == 6) return (IChonkyAttributes.AttributeType.WICKED, 3);
        if (_id == 7) return (IChonkyAttributes.AttributeType.CUTE, 7);
        if (_id == 8) return (IChonkyAttributes.AttributeType.POWER, 2);
        if (_id == 9) return (IChonkyAttributes.AttributeType.CUTE, 1);
        if (_id == 10) return (IChonkyAttributes.AttributeType.POWER, 4);
        if (_id == 11) return (IChonkyAttributes.AttributeType.POWER, 6);
        if (_id == 12) return (IChonkyAttributes.AttributeType.POWER, 2);
        if (_id == 13) return (IChonkyAttributes.AttributeType.WICKED, 10);
        if (_id == 14) return (IChonkyAttributes.AttributeType.POWER, 10);
        if (_id == 15) return (IChonkyAttributes.AttributeType.WICKED, 3);
        if (_id == 16) return (IChonkyAttributes.AttributeType.BRAIN, 2);
        if (_id == 17) return (IChonkyAttributes.AttributeType.WICKED, 6);
        if (_id == 18) return (IChonkyAttributes.AttributeType.WICKED, 5);
        if (_id == 19) return (IChonkyAttributes.AttributeType.BRAIN, 9);
        if (_id == 20) return (IChonkyAttributes.AttributeType.POWER, 2);
        if (_id == 21) return (IChonkyAttributes.AttributeType.WICKED, 3);
        if (_id == 22) return (IChonkyAttributes.AttributeType.POWER, 6);
        if (_id == 23) return (IChonkyAttributes.AttributeType.WICKED, 4);
        if (_id == 24) return (IChonkyAttributes.AttributeType.BRAIN, 2);
        if (_id == 25) return (IChonkyAttributes.AttributeType.WICKED, 7);
        if (_id == 26) return (IChonkyAttributes.AttributeType.WICKED, 4);
        if (_id == 27) return (IChonkyAttributes.AttributeType.POWER, 5);
        if (_id == 28) return (IChonkyAttributes.AttributeType.POWER, 10);
        if (_id == 29) return (IChonkyAttributes.AttributeType.WICKED, 6);
        if (_id == 30) return (IChonkyAttributes.AttributeType.WICKED, 6);
        if (_id == 31) return (IChonkyAttributes.AttributeType.CUTE, 6);
        if (_id == 32) return (IChonkyAttributes.AttributeType.POWER, 1);
        if (_id == 33) return (IChonkyAttributes.AttributeType.CUTE, 9);
        if (_id == 34) return (IChonkyAttributes.AttributeType.BRAIN, 7);
        if (_id == 35) return (IChonkyAttributes.AttributeType.WICKED, 5);
        if (_id == 36) return (IChonkyAttributes.AttributeType.CUTE, 3);
        if (_id == 37) return (IChonkyAttributes.AttributeType.POWER, 3);
        if (_id == 38) return (IChonkyAttributes.AttributeType.BRAIN, 5);
        if (_id == 39) return (IChonkyAttributes.AttributeType.WICKED, 5);
        if (_id == 40) return (IChonkyAttributes.AttributeType.WICKED, 8);
        if (_id == 41) return (IChonkyAttributes.AttributeType.CUTE, 1);
        if (_id == 42) return (IChonkyAttributes.AttributeType.WICKED, 4);
        if (_id == 43) return (IChonkyAttributes.AttributeType.BRAIN, 7);
        if (_id == 44) return (IChonkyAttributes.AttributeType.CUTE, 9);
        if (_id == 45) return (IChonkyAttributes.AttributeType.BRAIN, 4);
        if (_id == 46) return (IChonkyAttributes.AttributeType.POWER, 6);
        if (_id == 47) return (IChonkyAttributes.AttributeType.BRAIN, 5);
        if (_id == 48) return (IChonkyAttributes.AttributeType.POWER, 9);
        if (_id == 49) return (IChonkyAttributes.AttributeType.CUTE, 3);
        if (_id == 50) return (IChonkyAttributes.AttributeType.CUTE, 4);
        if (_id == 51) return (IChonkyAttributes.AttributeType.WICKED, 1);
        if (_id == 52) return (IChonkyAttributes.AttributeType.BRAIN, 3);
        if (_id == 53) return (IChonkyAttributes.AttributeType.WICKED, 8);
        if (_id == 54) return (IChonkyAttributes.AttributeType.CUTE, 2);
        if (_id == 55) return (IChonkyAttributes.AttributeType.POWER, 4);
        if (_id == 56) return (IChonkyAttributes.AttributeType.WICKED, 3);
        if (_id == 57) return (IChonkyAttributes.AttributeType.POWER, 8);
        if (_id == 58) return (IChonkyAttributes.AttributeType.CUTE, 8);
        if (_id == 59) return (IChonkyAttributes.AttributeType.CUTE, 7);
        if (_id == 60) return (IChonkyAttributes.AttributeType.POWER, 2);
        if (_id == 61) return (IChonkyAttributes.AttributeType.CUTE, 4);
        if (_id == 62) return (IChonkyAttributes.AttributeType.BRAIN, 1);
        if (_id == 63) return (IChonkyAttributes.AttributeType.POWER, 8);
        if (_id == 64) return (IChonkyAttributes.AttributeType.CUTE, 2);
        if (_id == 65) return (IChonkyAttributes.AttributeType.CUTE, 4);
        if (_id == 66) return (IChonkyAttributes.AttributeType.CUTE, 3);
        if (_id == 67) return (IChonkyAttributes.AttributeType.WICKED, 3);
        if (_id == 68) return (IChonkyAttributes.AttributeType.BRAIN, 6);
        if (_id == 69) return (IChonkyAttributes.AttributeType.POWER, 8);
        if (_id == 70) return (IChonkyAttributes.AttributeType.WICKED, 8);
        if (_id == 71) return (IChonkyAttributes.AttributeType.WICKED, 2);
        if (_id == 72) return (IChonkyAttributes.AttributeType.POWER, 3);
        if (_id == 73) return (IChonkyAttributes.AttributeType.CUTE, 1);
        if (_id == 74) return (IChonkyAttributes.AttributeType.BRAIN, 2);
        if (_id == 75) return (IChonkyAttributes.AttributeType.CUTE, 10);
        if (_id == 76) return (IChonkyAttributes.AttributeType.CUTE, 9);
        if (_id == 77) return (IChonkyAttributes.AttributeType.CUTE, 1);
        if (_id == 78) return (IChonkyAttributes.AttributeType.CUTE, 2);
        if (_id == 79) return (IChonkyAttributes.AttributeType.WICKED, 3);
        if (_id == 80) return (IChonkyAttributes.AttributeType.BRAIN, 3);
        if (_id == 81) return (IChonkyAttributes.AttributeType.BRAIN, 10);
        if (_id == 82) return (IChonkyAttributes.AttributeType.POWER, 9);
        if (_id == 83) return (IChonkyAttributes.AttributeType.POWER, 8);
        if (_id == 84) return (IChonkyAttributes.AttributeType.BRAIN, 8);
        if (_id == 85) return (IChonkyAttributes.AttributeType.POWER, 6);
        if (_id == 86) return (IChonkyAttributes.AttributeType.POWER, 7);
        if (_id == 87) return (IChonkyAttributes.AttributeType.BRAIN, 9);
        if (_id == 88) return (IChonkyAttributes.AttributeType.CUTE, 6);
        if (_id == 89) return (IChonkyAttributes.AttributeType.POWER, 7);
        if (_id == 90) return (IChonkyAttributes.AttributeType.CUTE, 4);
        if (_id == 91) return (IChonkyAttributes.AttributeType.BRAIN, 3);
        if (_id == 92) return (IChonkyAttributes.AttributeType.BRAIN, 2);
        if (_id == 93) return (IChonkyAttributes.AttributeType.POWER, 9);
        if (_id == 94) return (IChonkyAttributes.AttributeType.POWER, 4);
        if (_id == 95) return (IChonkyAttributes.AttributeType.CUTE, 10);
        if (_id == 96) return (IChonkyAttributes.AttributeType.POWER, 2);

        return (IChonkyAttributes.AttributeType.NONE, 0);
    }

    function _getWingsAttribute(uint256 _id)
        internal
        pure
        returns (IChonkyAttributes.AttributeType, uint256)
    {
        if (_id == 0) return (IChonkyAttributes.AttributeType.NONE, 0);

        if (_id == 1) return (IChonkyAttributes.AttributeType.CUTE, 6);
        if (_id == 2) return (IChonkyAttributes.AttributeType.WICKED, 8);
        if (_id == 3) return (IChonkyAttributes.AttributeType.CUTE, 4);
        if (_id == 4) return (IChonkyAttributes.AttributeType.POWER, 9);
        if (_id == 5) return (IChonkyAttributes.AttributeType.WICKED, 4);
        if (_id == 6) return (IChonkyAttributes.AttributeType.POWER, 4);
        if (_id == 7) return (IChonkyAttributes.AttributeType.CUTE, 7);
        if (_id == 8) return (IChonkyAttributes.AttributeType.BRAIN, 5);
        if (_id == 9) return (IChonkyAttributes.AttributeType.BRAIN, 9);

        return (IChonkyAttributes.AttributeType.NONE, 0);
    }

    function _getSetAttribute(uint256 _id)
        internal
        pure
        returns (IChonkyAttributes.AttributeType, uint256)
    {
        if (_id == 0) return (IChonkyAttributes.AttributeType.NONE, 0);

        if (_id == 1) return (IChonkyAttributes.AttributeType.POWER, 1);
        if (_id == 2) return (IChonkyAttributes.AttributeType.CUTE, 3);
        if (_id == 3) return (IChonkyAttributes.AttributeType.BRAIN, 5);
        if (_id == 4) return (IChonkyAttributes.AttributeType.WICKED, 5);
        if (_id == 5) return (IChonkyAttributes.AttributeType.CUTE, 5);
        if (_id == 6) return (IChonkyAttributes.AttributeType.POWER, 5);
        if (_id == 7) return (IChonkyAttributes.AttributeType.POWER, 3);
        if (_id == 8) return (IChonkyAttributes.AttributeType.CUTE, 2);
        if (_id == 9) return (IChonkyAttributes.AttributeType.BRAIN, 2);
        if (_id == 10) return (IChonkyAttributes.AttributeType.POWER, 1);
        if (_id == 11) return (IChonkyAttributes.AttributeType.BRAIN, 1);
        if (_id == 12) return (IChonkyAttributes.AttributeType.WICKED, 5);
        if (_id == 13) return (IChonkyAttributes.AttributeType.WICKED, 2);
        if (_id == 14) return (IChonkyAttributes.AttributeType.POWER, 2);
        if (_id == 15) return (IChonkyAttributes.AttributeType.BRAIN, 2);
        if (_id == 16) return (IChonkyAttributes.AttributeType.BRAIN, 5);
        if (_id == 17) return (IChonkyAttributes.AttributeType.BRAIN, 3);
        if (_id == 18) return (IChonkyAttributes.AttributeType.BRAIN, 5);
        if (_id == 19) return (IChonkyAttributes.AttributeType.WICKED, 1);
        if (_id == 20) return (IChonkyAttributes.AttributeType.WICKED, 3);
        if (_id == 21) return (IChonkyAttributes.AttributeType.CUTE, 5);
        if (_id == 22) return (IChonkyAttributes.AttributeType.CUTE, 1);
        if (_id == 23) return (IChonkyAttributes.AttributeType.WICKED, 3);
        if (_id == 24) return (IChonkyAttributes.AttributeType.POWER, 2);
        if (_id == 25) return (IChonkyAttributes.AttributeType.POWER, 2);
        if (_id == 26) return (IChonkyAttributes.AttributeType.POWER, 1);
        if (_id == 27) return (IChonkyAttributes.AttributeType.WICKED, 2);
        if (_id == 28) return (IChonkyAttributes.AttributeType.CUTE, 2);
        if (_id == 29) return (IChonkyAttributes.AttributeType.CUTE, 3);
        if (_id == 30) return (IChonkyAttributes.AttributeType.POWER, 5);
        if (_id == 31) return (IChonkyAttributes.AttributeType.WICKED, 3);
        if (_id == 32) return (IChonkyAttributes.AttributeType.POWER, 2);
        if (_id == 33) return (IChonkyAttributes.AttributeType.BRAIN, 5);
        if (_id == 34) return (IChonkyAttributes.AttributeType.WICKED, 3);
        if (_id == 35) return (IChonkyAttributes.AttributeType.CUTE, 1);
        if (_id == 36) return (IChonkyAttributes.AttributeType.POWER, 1);
        if (_id == 37) return (IChonkyAttributes.AttributeType.POWER, 5);
        if (_id == 38) return (IChonkyAttributes.AttributeType.POWER, 5);
        if (_id == 39) return (IChonkyAttributes.AttributeType.WICKED, 5);
        if (_id == 40) return (IChonkyAttributes.AttributeType.CUTE, 5);
        if (_id == 41) return (IChonkyAttributes.AttributeType.POWER, 3);
        if (_id == 42) return (IChonkyAttributes.AttributeType.CUTE, 3);
        if (_id == 43) return (IChonkyAttributes.AttributeType.POWER, 3);
        if (_id == 44) return (IChonkyAttributes.AttributeType.POWER, 3);
        if (_id == 45) return (IChonkyAttributes.AttributeType.BRAIN, 5);
        if (_id == 46) return (IChonkyAttributes.AttributeType.CUTE, 3);
        if (_id == 47) return (IChonkyAttributes.AttributeType.POWER, 5);
        if (_id == 48) return (IChonkyAttributes.AttributeType.POWER, 2);
        if (_id == 49) return (IChonkyAttributes.AttributeType.BRAIN, 5);
        if (_id == 50) return (IChonkyAttributes.AttributeType.CUTE, 3);
        if (_id == 51) return (IChonkyAttributes.AttributeType.CUTE, 1);
        if (_id == 52) return (IChonkyAttributes.AttributeType.POWER, 3);
        if (_id == 53) return (IChonkyAttributes.AttributeType.CUTE, 1);
        if (_id == 54) return (IChonkyAttributes.AttributeType.BRAIN, 3);
        if (_id == 55) return (IChonkyAttributes.AttributeType.POWER, 3);
        if (_id == 56) return (IChonkyAttributes.AttributeType.POWER, 2);
        if (_id == 57) return (IChonkyAttributes.AttributeType.WICKED, 3);
        if (_id == 58) return (IChonkyAttributes.AttributeType.CUTE, 0);

        return (IChonkyAttributes.AttributeType.NONE, 0);
    }

    function _addAttributeValue(
        uint256[4] memory _array,
        uint256 _value,
        IChonkyAttributes.AttributeType _valueType
    ) internal pure returns (uint256[4] memory) {
        if (_valueType != IChonkyAttributes.AttributeType.NONE) {
            _array[uint256(_valueType) - 1] += _value;
        }

        return _array;
    }

    function getAttributeValues(uint256[12] memory _attributes, uint256 _setId)
        public
        pure
        returns (uint256[4] memory result)
    {
        uint256 value;
        IChonkyAttributes.AttributeType valueType;

        (valueType, value) = _getWingsAttribute(_attributes[2]);
        result = _addAttributeValue(result, value, valueType);

        (valueType, value) = _getBodyAttribute(_attributes[6]);
        result = _addAttributeValue(result, value, valueType);

        (valueType, value) = _getMouthAttribute(_attributes[7]);
        result = _addAttributeValue(result, value, valueType);

        (valueType, value) = _getEyesAttribute(_attributes[8]);
        result = _addAttributeValue(result, value, valueType);

        (valueType, value) = _getHatAttribute(_attributes[9]);
        result = _addAttributeValue(result, value, valueType);

        (valueType, value) = _getSetAttribute(_setId);
        result = _addAttributeValue(result, value, valueType);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IChonkyAttributes {
    enum AttributeType {
        NONE,
        BRAIN,
        CUTE,
        POWER,
        WICKED
    }

    function getAttributeValues(uint256[12] memory _attributes, uint256 _setId)
        external
        pure
        returns (uint256[4] memory result);
}