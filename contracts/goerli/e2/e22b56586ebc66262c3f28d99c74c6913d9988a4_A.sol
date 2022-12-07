/**
 *Submitted for verification at Etherscan.io on 2022-12-07
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
//20221207

contract A {

    uint public abc;

    function setABC2(uint _abc2) public {
       abc = _abc2;
    }

}

contract B {
    A public a;

    constructor (address _a) {
        a = A(_a);
    }

    function setABC2_c(uint _new_abc2) public {
        a.setABC2(_new_abc2);
    }

}