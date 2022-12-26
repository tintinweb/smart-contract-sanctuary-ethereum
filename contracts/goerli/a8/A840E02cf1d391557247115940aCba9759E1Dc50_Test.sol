//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

contract Test {
    uint[] arrayA;

    function getLength() public view returns(uint){
        return arrayA.length;
    }
    function putNumber(uint _n)public {
        arrayA.push(_n);
    }
    function biggerN(uint _a, uint _b) public pure returns(uint){
        if (_a>=_b) {
            return _a;
        }else{
            return _b;
        }
    }
}