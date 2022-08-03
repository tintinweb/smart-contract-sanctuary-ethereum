/**
 *Submitted for verification at Etherscan.io on 2022-08-03
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

/**
 * @title Storage
 * @dev Store & retrieve value in a variable
 * @custom:dev-run-script ./scripts/deploy_with_ethers.ts
 */
contract Storage {

    bytes storedBytes;

    /**
     * @dev Store value in variable
     * @param str value to store
     */
    function store(bytes calldata str) public {
        storedBytes = str;
    }

    /**
     * @dev Reset value in variable
     */
    function reset(bytes calldata /* str */) public {
        storedBytes = "";
    }

    /**
     * @dev Return value 
     * @return value of 'storedBytes'
     */
    function retrieve() public view returns (bytes memory){
        return storedBytes;
    }
}