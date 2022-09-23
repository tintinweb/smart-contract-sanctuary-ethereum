/**
 *Submitted for verification at Etherscan.io on 2022-09-23
*/

// SPDX-License-Identifier: GPL-3.0
// 20220922
pragma solidity 0.8.0;

contract Name {
    uint[] array; 
    string[] narray;

    // 배열에 숫자를 넣는 함수
    function pushName(string memory s) public {
        narray.push(s);
    }

    // 배열 내 n번째 요소의 정보를 반환해주는 함수

    function getName(uint _n) public view returns(string memory) {
        return narray[_n-1];
    }

    function getNarrayLength() public view returns(uint) {
        return narray.length;
    }

}