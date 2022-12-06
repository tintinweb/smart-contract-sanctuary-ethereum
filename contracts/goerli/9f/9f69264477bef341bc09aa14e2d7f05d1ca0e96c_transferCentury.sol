/**
 *Submitted for verification at Etherscan.io on 2022-12-06
*/

// SPDX-License-Identifier: GPL-3.0
// 20221206
pragma solidity 0.8.0;

contract Test1 {
    mapping(uint => uint) map; 
    mapping(string => string) map2;

    function push(uint a, uint _a) public {
        map[a] = _a;
    }

    function push2(string memory b, string memory _b) public {
        map2[b] = _b;
    }

    function get(uint a) public view returns(uint) {
        return map[a];
    }

    function get2(string memory b) public view returns(string memory) {
        return map2[b];
    }
}

contract arrangeNum {
    uint a;
    uint[] array;
    uint[] numbers_r;

    function pushNumber(uint a) public{
        array.push(a);
    }

    function getArrayLength() public view returns(uint) {
        return array.length; 
    }

    function getArray() public view returns(uint[] memory) {
        return array;
    }

    function reverse() public returns(uint[] memory) {
        for(uint i=array.length; i>0; i--) {
            numbers_r.push(array[i-1]);
        }
        
        return numbers_r;
    }
}

contract transferCentury {
    function getNumber(uint year) public view returns(uint) {
        uint index; 
        while(year != 0) {
            index++;
            year = year/10;
        }
        return index;
    }

    uint[] numbers;
    function divideNumber(uint year) public returns(uint[] memory) {
        while(year != 0) {
            numbers.push(year%10);
            year = year/10;
        }
        return numbers;
    }
}