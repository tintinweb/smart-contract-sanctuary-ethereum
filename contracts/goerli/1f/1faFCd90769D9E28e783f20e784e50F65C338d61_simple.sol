// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract simple{
    uint[] array;
    function getA(uint _n)public view returns(uint){
        require(_n<=array.length && 0<_n);
        return array[_n-1];
    }

    function getLength()public view returns(uint){
        return array.length;
    }

    function setA(uint _a)public{
        array.push(_a);
    }

    function compare(uint _a,uint _b)public pure returns(uint){
        
        if(_a>_b){
            return _a;
        }

        return _b;

    }
}