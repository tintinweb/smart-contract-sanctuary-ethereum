/**
 *Submitted for verification at Etherscan.io on 2022-05-19
*/

// SPDX-License-Identifier: GPL-3.0


pragma solidity >=0.7.0 <0.9.0;

/**
 * @title Storage
 * @dev Store & retrieve value in a variable
 */
contract Storage {

    uint[] array;


    function store(uint num) public {
        array.push(num);
    }

    function retrieve() public view returns (uint[] memory){
        return array;
    }
}