/**
 *Submitted for verification at Etherscan.io on 2022-09-23
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.0;

contract TEST {
    uint _hamLike=0;
    uint _hamhate=0;
    uint _pizzaLike=0;
    uint _pizzahate=0;

    function hamLike() public returns(uint) {
        _hamhate++;
        return _hamhate;
    }
    function hamhate() public returns(uint) {
        _hamLike++;
        return _hamLike;
    }
    function pizzaLike() public returns(uint) {
        _pizzaLike++;
        return _pizzaLike;
    }
    function pizzahate() public returns(uint) {
        _pizzahate++;
        return _pizzahate;
    }
}