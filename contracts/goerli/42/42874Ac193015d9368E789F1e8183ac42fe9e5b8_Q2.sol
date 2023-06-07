/**
 *Submitted for verification at Etherscan.io on 2023-06-07
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

contract Q2 {
    /*
    10보다 작은 한개의 input값을 받아서 그숫자의 구구단을 반환해주는 함수를 만들어주세요
    3일경우 => 3X1=3,  3X2=6 .... 3X9=27
    8일경우 => 8X1=8,  8X2=16 .... 8X9=72

    힌트 - openzeppelin
    */

    function uintToString(uint _n) internal pure returns(string memory) {
        if(_n == 0) {
            return "0";
        }

        uint count;
        uint n = _n;

        while(n != 0) {
            count++;
            n /= 10;
        }

        bytes memory uintToBytes = new bytes(count);

        while (_n != 0) {
            count--;
            uintToBytes[count] = bytes1(uint8(48 + (_n % 10)));
            _n /= 10;
        }

        return string(uintToBytes);
    }

    function getMultiplication(uint _n) public pure returns(string[] memory) {
        require(_n>0 && _n<10);
        string[] memory array = new string[](9);
        
        for(uint i = 0; i < array.length; i++) {
            array[i] = string(abi.encodePacked(uintToString(_n), ' X ', uintToString(i+1), ' = ', uintToString(_n*(i+1))));
        }

        return array;
    }
}