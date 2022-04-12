/**
 *Submitted for verification at Etherscan.io on 2022-04-12
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

/**
 * @title HelloWorld
 * @dev Store & retrieve value in a variable
 */
contract HelloWorld {

    uint256 num;

    /**
     * @dev Store value in variable
     * @param _num value to store
     */
    function storeNumber(uint256 _num) public {
        num = _num;
    }

    /**
     * @dev Return value 
     * @return value of 'num'
     */
    function retrieveNumber() public view returns (uint256){
        return num;
    }
}