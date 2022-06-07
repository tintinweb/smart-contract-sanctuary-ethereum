/**
 *Submitted for verification at Etherscan.io on 2022-06-07
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title Storage
 * @dev Store & retrieve value in a variable
 * @custom:dev-run-script ./scripts/deploy_with_ethers.ts
 */
contract Storage {

    uint256 number; 
    event valueUpdated(uint indexed old, uint current, string message);
    /**
     * @dev Store value in variable
     * @param num value to store
     */
    function store(uint256 num) public {
        //uint256 temp = number;
        emit valueUpdated(number, num, "Value updated");
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