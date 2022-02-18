/**
 *Submitted for verification at Etherscan.io on 2022-02-18
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

/**
 * @title Storage
 * @dev Store & retrieve value in a variable
 */
contract Storage {

    uint256 number;
    uint256 number1;

    /**
     * @dev Store value in variable
     * @param num value to store
     */
    // function store(uint256 num,uint256 num1) public {
    //     number = num;
    //     number1 = num1;
    // }
    function store(uint256 num) public {
        number = num;
    }

    // function store(uint256 num) public {
    //     number = num;
    // }

    // function store1(uint256 num1) public {
    //     number1 = num1;
    // }

    /**
     * @dev Return value 
     * @return value of 'number'
     */
    // function retrieve() public view returns (uint256,uint256){
    //     return (number,number1);
    // }

        function retrieve() public view returns (uint256){
        return number;
    }
}