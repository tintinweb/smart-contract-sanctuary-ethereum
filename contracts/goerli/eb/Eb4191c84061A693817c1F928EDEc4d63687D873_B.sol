// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

contract A {
    uint num;
    string name;
    constructor(uint _num, string memory _name) {
        num = _num;
        name = _name;
    }

    function getNumAndName() public view returns(uint, string memory) {
        return (num, name);
    }

}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import './A.sol';

contract B {
    A public aVar = new A(8, "c");
    uint public b_num;
    function setB(uint _b) public returns(uint) {
        b_num = _b;
        return b_num;
    }
    
    function getNumAndName() public view returns(uint, string memory) {
        return aVar.getNumAndName();
    }
}