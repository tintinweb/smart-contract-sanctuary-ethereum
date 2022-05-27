/**
 *Submitted for verification at Etherscan.io on 2022-05-27
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.14;

/**
 * @title Storage
 * @dev Store & retrieve value in a variable
 * @custom:dev-run-script ./scripts/deploy_with_ethers.ts
 */
contract Storage {

    string mood;

    /**
     * @dev Store value in variable
     * @param mymood value to store
     */
    function store(string memory mymood) public {
        mood = mymood;
    }

    /**
     * @dev Return value 
     * @return value of 'mood'
     */
    function retrieve() public view returns (string memory){
        return mood;
    }
}