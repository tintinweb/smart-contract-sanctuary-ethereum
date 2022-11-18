/**
 *Submitted for verification at Etherscan.io on 2022-11-18
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;






contract Foo {
    Bar bar;

    constructor(address _bar) {
        bar = Bar(_bar);
    }

    function changeBar(address bar_) external {

        bar = Bar(bar_);

    }

    function callBar() public {
        bar.log();
        bar.cunt();
    }
}

contract Bar {
    event Log(string message);

    function log() public {
        emit Log("Bar was called");
    }


    function cunt() public {
        emit Log("cuntr was called");
    }
}