// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ContractA.sol";
import "./ContractB.sol";

contract MainContract {
    uint public c;
    ContractA public contractA;
    ContractB public contractB;

    constructor(uint _c, uint _a, uint _b) {
        c = _c;
        contractA = new ContractA(_a);
        contractB = new ContractB(_b, address(contractA));
    }

    function setC(uint _c) public {
        c = _c;
    }

    function setA(uint _a) public {
        contractA.setA(_a);
    }

    function setB(uint _b) public {
        contractB.setB(_b);
    }

    function setAB(uint _a, uint _b) public {
        contractA.setA(_a);
        contractB.setB(_b);
    }
}