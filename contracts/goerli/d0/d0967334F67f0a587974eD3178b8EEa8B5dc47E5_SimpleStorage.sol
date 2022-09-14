// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

/**
 * @title Simple Storage
 * @dev Store & retrieve value in a variable
 * @custom:dev-run-script ./scripts/deploy_with_ethers.ts
 */
contract SimpleStorage {

    uint256 value;

    /**
     * @dev Store value in variable
     * @param num value to store
     */
    function setValue(uint256 num) public {
        value = num;
    }

    /**
     * @dev Return value 
     * @return value of 'number'
     */
    function getValue() public view returns (uint256){
        return value;
    }
}