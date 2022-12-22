/**
 *Submitted for verification at Etherscan.io on 2022-12-21
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.17;

contract NestedArgs {
    struct Obj {
        uint8 num;
        string str;
        string[] arr;
    }

    event Function1Called(uint8);
    event Function2Called(uint8, string[]);
    event Function3Called(uint8, string[], Obj);

    function function1(uint8 num) public {
        emit Function1Called(num);
    }

    function function2(uint8 num, string[] calldata arr) public {
        emit Function2Called(num, arr);
    }

    function function3(uint8 num, string[] calldata arr, Obj calldata obj) public {
        emit Function3Called(num, arr, obj);
    }
}