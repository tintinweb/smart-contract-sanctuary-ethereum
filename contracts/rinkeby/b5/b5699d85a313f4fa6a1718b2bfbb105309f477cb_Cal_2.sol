/**
 *Submitted for verification at Etherscan.io on 2022-09-22
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;


contract Cal_2 {

    function cal_2(int a, int b) public view returns(int, int, int, int){
        return (a * a, a * a * a, a / b, a % b);
    }
}