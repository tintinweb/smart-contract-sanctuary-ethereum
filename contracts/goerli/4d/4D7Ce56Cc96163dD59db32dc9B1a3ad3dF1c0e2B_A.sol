//contracts?A.sol
// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

contract A{
    uint[] arr;

    function getArrLength() public view returns(uint) {
        return arr.length;
    }

    function push(uint _a) public {
        arr.push(_a);
    }

    function compareNum(uint _a, uint _b) public pure returns(uint) {
        if(_a > _b){
            return _a;
        } else{
            return _b;
        }
    }
}