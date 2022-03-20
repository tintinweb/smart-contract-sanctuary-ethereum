/**
 *Submitted for verification at Etherscan.io on 2022-03-19
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.11;



contract Sum {

    int num1;

    int num2;



    function setNum1(int _num1) public {

        num1 = _num1;

    }



    function setNum2(int _num2) public {

        num2 = _num2;

    }



    function sum() public view returns (int) {

        return (num1 + num2);

    }

}