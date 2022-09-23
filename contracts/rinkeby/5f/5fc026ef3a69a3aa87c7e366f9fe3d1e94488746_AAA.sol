/**
 *Submitted for verification at Etherscan.io on 2022-09-23
*/

// SPDX-License-Identifier: GPL-3.0
// 2022.09.23
pragma solidity 0.8.0;

contract AAA {
   
    string[] nameList;  //배열선언

    // 이름을 추가할 수 있는 배열을 만들고,
    function pushName(string memory _name) public {
        nameList.push(_name);
    }

     // 배열의 길이
    function getLength() public view returns(uint) {
        return nameList.length;
    }

    // n번째 등록자가 누구인지 확인할 수 있는 contract를 구현하세요
    function getName(uint a) public view returns(string memory) {
        return nameList[a-1];
    }
}