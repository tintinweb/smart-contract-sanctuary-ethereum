/**
 *Submitted for verification at Etherscan.io on 2022-12-07
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.0;

contract A {
    uint public abc;
    
    function setABC2(uint _abc) public {
        abc = _abc;
    }

}

contract B {
    A public a;

    constructor(address _a){
        a = A(_a);
    }


    function setACB(uint _new_abc2) public {
        a.setABC2(_new_abc2);
    }
}