/**
 *Submitted for verification at Etherscan.io on 2022-05-12
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title Storage
 * @dev save vlaue
 */
contract SaveNum {

    uint256 number;

    /**
     * @dev save one value
     * @param num number
     */
    function store(uint256 num) public {
        number = num*1000;
    }

    /**
     * @dev return number
     * @return 'number' value
     */
    function retrieve() public view returns (uint256){
        return number;
    }
}