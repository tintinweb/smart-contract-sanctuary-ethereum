//SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.0;

contract B {
    uint num2;
    
    function getNum2() public view returns(uint) {
        return num2;
    }

    function setNum2(uint _a) public {
        num2 = _a;
    }
}