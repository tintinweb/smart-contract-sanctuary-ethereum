/**
 *Submitted for verification at Etherscan.io on 2022-12-07
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.0;

contract A {
    uint public abc;

    function setABC() public {
        abc = 10;
    }

    function setABC2(uint _abc) public {
        abc = _abc;
    }
}

contract C {
    A public a;

    constructor(address adr) {
        a = A(adr);
    }

    function setABC(uint _abc) public {
        a.setABC2(_abc);
    }
}