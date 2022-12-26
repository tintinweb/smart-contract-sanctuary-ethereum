//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

contract A{
    uint[] arr;

    function getArr() public view returns(uint[] memory){
        return arr;
    }

    function pushArr(uint _a) public{
        arr.push(_a);
    }

    function getMax(uint _a, uint _b) public pure returns(uint){
        if(_a>=_b){
            return _a;
        }else{
            return _b;
        }
    }
}