/**
 *Submitted for verification at Etherscan.io on 2022-09-22
*/

//제곱, 3제곱, 몫과 나머지 기능을 보유한 스마트 컨트랙트를 구현하세요
// SPDX-License-Identifier: GPL-3.0 
//20220921


pragma solidity 0.8.0;
contract a{
 function multi(uint a) public view returns(uint)
 {
    a = a * a;
    return a;
 }

 function third(uint a) public view returns(uint)
 {
    a = a*a*a;
    return a;
 }

  function div(uint a, uint b) public view returns(uint, uint) {
        return (a/b, a%b);
    }
}