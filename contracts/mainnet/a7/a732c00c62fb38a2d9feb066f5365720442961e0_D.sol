/**
 *Submitted for verification at Etherscan.io on 2022-11-23
*/

pragma solidity >=0.6.0 <0.6.4;
// This will not compile after 0.7.0
// SPDX-License-Identifier: GPL-3.0
contract C {
    // FIXME: remove constructor visibility and make the contract abstract
    constructor() internal {}
}

contract D {
    uint time;

    function f() public payable {
        // FIXME: change now to block.timestamp
        time = now;
    }
}

contract E {
    D d;

    // FIXME: remove constructor visibility
    constructor() public {}

    function g() public {
        // FIXME: change .value(5) =>  {value: 5}
        d.f.value(5)();
    }
}