/**
 *Submitted for verification at Etherscan.io on 2022-11-11
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

/**
 * @title Storage
 * @dev Store & retrieve value in a variable
 * @custom:dev-run-script ./scripts/deploy_with_ethers.ts
 */
contract Transaction {

    uint256 number;

    /**
     * @dev Store value in variable
     * @param num value to store
     */

    function storestamp(uint256 num) public {
        number = num;
    }

    function getData() public view returns (uint256){
        return number;
    }

    function store(uint256 num) public {
        number += num;
    }

    function buy(uint256 num) public {
        number -= num;
    }



    /**
     * @dev Return value 
     * @return value of 'number'
     */
    function retrieve() public view returns (uint256){
        return number;
    }
}