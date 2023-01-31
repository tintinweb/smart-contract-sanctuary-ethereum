/**
 *Submitted for verification at Etherscan.io on 2023-01-31
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

/**
 * @title Storage
 * @dev Store & retrieve value in a variable
 * @custom:dev-run-script ./scripts/deploy_with_ethers.ts
 */
contract Storage {

    uint256 number;

    /**
     * @dev Store value in variable
     * @param num value to store
     */
    function store(uint256 num) public {
        number = num;
    }

    /**
     * @dev Return value 
     * @return value of 'number'
     */
    function retrieve() public view returns (uint256){
        return number;
    }


    function checkvalue(uint256 value) public view {
        require(number == value, "assertion failed");
    }

    function incrementAndCheck(uint256 check) public  {
        number += 1;
        require(number == check, "assertion failed");
    }
    function incrementAndCheckLessThan(uint256 check) public  {
        number += 1;
        require(number < check, "assertion failed");
    }
}