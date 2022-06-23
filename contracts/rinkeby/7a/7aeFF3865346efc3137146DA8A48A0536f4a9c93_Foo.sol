// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

contract Foo {

    uint public bar;
    constructor(uint  _bar)
    {
        bar = _bar;
    }

    function setBar(uint  _bar) public
    {
        bar = _bar;
    }
}