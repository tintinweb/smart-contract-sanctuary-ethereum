/**
 *Submitted for verification at Etherscan.io on 2022-05-11
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

/**
 * @title Storage
 * @dev Store & retrieve value in a variable
 */
contract Storage {

    uint256 number;
    event NumberChanged(uint256 indexed from, uint256 indexed to);

    /**
     * @dev Store value in variable
     * @param num value to store
     */
    function store(uint256 num) public {
        emit NumberChanged(number, num);
        number = num;
    }

    /**
     * @dev Return value 
     * @return value of 'number'
     */
    function retrieve() public view returns (uint256){
        return number;
    }
}