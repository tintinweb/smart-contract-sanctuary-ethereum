/**
 *Submitted for verification at Etherscan.io on 2022-12-05
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.0;


contract A {

    uint number=1;

    function getNumber() public view returns(uint) {
        return (number);   
    }


    function getNumber2() public view returns(uint,uint) {
        return (number,2);   
    }


    function getNumber3() public view returns(uint,uint,uint) {
        return (number,10,15);   
    }

}