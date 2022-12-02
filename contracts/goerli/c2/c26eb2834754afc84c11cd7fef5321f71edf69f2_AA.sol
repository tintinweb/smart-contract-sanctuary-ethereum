/**
 *Submitted for verification at Etherscan.io on 2022-12-02
*/

// SPDX-License-Identifier: GPL-3.0
// 20221116

pragma solidity 0.8.0;

   /* 
    실습 순서 
    1) pushNumber 이용해서 5개의 숫자 넣기
    2) getArrayLength로 길이 구해보기
    3) lastNumber로 마지막 숫자 확인하기
    4) popNumber로 숫자 빼보기
    5) 2,3번 다시 해보기 --> 길이 변경과 마지막 숫자 변경 잘 되었는지 확인하기
    */


contract AA {
    struct student {
        string name;
        string birth;
        uint32 age;
    }

    student[] Students;

    function getCaAddress () public view returns(uint) {
        return address(this).balance;
    }

    function getMyAddress() public view returns(address) {
        return address(msg.sender);
    }

    function getMyBalance() public view returns(uint) {
        return getMyAddress().balance;
    }

    function send() public payable returns(uint) {
        uint sendValue = msg.value;
        return sendValue;
    }
}