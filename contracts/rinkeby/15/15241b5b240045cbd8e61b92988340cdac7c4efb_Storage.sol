/**
 *Submitted for verification at Etherscan.io on 2022-02-13
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract Storage {

    uint256 number1;
    uint256 number2;

    function store(uint256 num1, uint256 num2) public {
        // number.push(Number(num1));
        // number.push(Number(num2));
        number1 = num1;
        number2 = num2;

    }

    function retrieve() public view returns (uint256, uint256){
        return (number1, number2);
    }

}