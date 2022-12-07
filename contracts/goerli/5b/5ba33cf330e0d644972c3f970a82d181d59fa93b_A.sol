/**
 *Submitted for verification at Etherscan.io on 2022-12-07
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract A {
    uint public abc;

    function setABC() public {
        abc = 10;
    }

    function setABC2(uint _abc) public {
        abc = _abc;
    }

    function getABC() public view returns(uint) {
        return abc;
    }
}

contract B {
    A public a;

    function setA(address _a) public {
        a = A(_a);
    }

    function setABC(uint _new_abc) public {
        a.setABC2(_new_abc);
    }
}

contract C {
    A public a;

    constructor(address _a) {
        a = A(_a);
    }

    function setABC2(uint _new_abc2) public {
        a.setABC2(_new_abc2);
    }
}