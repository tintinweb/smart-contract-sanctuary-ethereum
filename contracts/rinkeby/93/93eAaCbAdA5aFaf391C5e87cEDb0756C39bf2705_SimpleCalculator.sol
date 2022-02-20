/**
 *Submitted for verification at Etherscan.io on 2022-02-20
*/

//SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.7.0 <0.9.0;

contract SimpleCalculator {

    uint256 result;

    function power(uint256 base, uint256 exponent) public {
        result = base ** exponent;
    }

    function factorial(uint256 number) public {
        result = 1;
        for (uint i=1; i<=number; i++) {
            result = result*i;
        }
    }

    function modulo(uint256 num1, uint256 num2) public {
        if (num2 != 0) {
            result = num1 % num2;
        }
    }

    function addition(uint256 num1, uint256 num2) public {
        result = num1 + num2;
    }

    function substitution(uint256 num1, uint256 num2) public {
        result = num1 - num2;
    }

    function multiplication(uint256 num1, uint256 num2) public {
        result = num1 * num2;
    }

    function getResult() public view returns (uint256){
        return result;
    }
}