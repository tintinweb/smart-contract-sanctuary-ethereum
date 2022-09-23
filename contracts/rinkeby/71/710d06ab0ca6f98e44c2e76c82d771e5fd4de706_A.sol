/**
 *Submitted for verification at Etherscan.io on 2022-09-23
*/

//여러분은 설문조사기관에 근무하고 있습니다. 피자를 좋아하는 사람, 싫어하는 사람, 햄버거를 좋아하는 사람, 싫어하는 사람의 숫자를 구해야합니다. 각각의 음식을 좋아하는 사람과 싫어하는 사람의 숫자를 구하고 기록하는 컨트랙트를 구현하세요
// SPDX-License-Identifier: GPL-3.0
// 20220923
pragma solidity 0.8.0;

contract A{
    uint a=0;
    uint b=0;
    uint c=0;
    uint d=0;
    function Lp() public returns(uint){
        a = a+1;
        return a;
    }
    function Hp() public returns(uint){
        b=b+1;
        return b;
    }
    function Lh() public returns(uint){
        c=c+1;
        return c;
    }
    function Hh() public returns(uint){
        d=d+1;
        return d;
    }
    function result() public view returns(uint, uint, uint, uint){
        return (a,b,c,d);
    }
}