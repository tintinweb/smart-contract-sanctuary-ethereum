/**
 *Submitted for verification at Etherscan.io on 2022-09-23
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.0;

// 여러분은 설문조사기관에 근무하고 있습니다. 
// 피자를 좋아하는 사람, 싫어하는 사람, 햄버거를 좋아하는 사람, 싫어하는 사람의 숫자를 구해야합니다. 
// 각각의 음식을 좋아하는 사람과 싫어하는 사람의 숫자를 구하고 기록하는 컨트랙트를 구현하세요.

contract A{

    uint pUp;
    uint pDn;
    uint bUp;
    uint bDn;
// 피자를 좋아하는 사람을 구하는 함수
    function piUp(uint) public returns(uint){
        pUp = pUp+1;
        return pUp;
    }
// 피자를 싫어하는 사람을 구하는 함수    
    function piDn(uint) public returns(uint){
        pDn = pDn+1;
        return pDn;
    }
// 햄버거를 좋아하는 사람을 구하는 함수
    function bgUp(uint) public returns(uint){
        bUp = bUp+1;
        return bUp;
    }
//햄버거를 싫어하는 사람을 구하는 함수
    function bgDn(uint) public returns(uint){
        bDn = bDn+1;
        return bDn;
    }
}