/**
 *Submitted for verification at Etherscan.io on 2022-09-23
*/

// SPDX-License-Identifier: GPL-3.0
// 2022.09.22
pragma solidity 0.8.0;

contract food{
   uint a;
   uint b;
   uint c;
   uint d;
   
    //피자를 좋아하는 사람,
    function pizzaplus() public returns(uint) {
        a = a + 1;
        return a;
    }
    //싫어하는 사람,
    function pminus() public returns(uint) {
        b = b + 1;
        return b;
    }
    //햄버거를 좋아하는 사람
     function hplus() public returns(uint) {
        c = c + 1;
        return c;
    }
    //싫어하는 사람,
    function hminus() public returns(uint) {
        d = d + 1;
        return d;
    }
    //각각의 음식을 좋아하는 사람과 , 싫어하는 사람의 숫자
    function all() public view returns(uint, uint, uint, uint){
        return (a,b,c,d);
    }
}