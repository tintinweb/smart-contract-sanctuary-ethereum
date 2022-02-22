/**
 *Submitted for verification at Etherscan.io on 2022-02-22
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

/**
 * @title Storage
 * @dev Store & retrieve value in a variable
 */
contract Storage {

    uint256 number1;
    uint256 number2;

    function store(uint256 num1,uint256 num2) public {
        number1 = num1;
        number2 = num2;
    }

    function retrieve() public view returns (uint256,uint256){
        return (number1,number2);
    }
}