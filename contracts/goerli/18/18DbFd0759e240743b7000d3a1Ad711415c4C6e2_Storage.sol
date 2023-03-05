/**
 *Submitted for verification at Etherscan.io on 2023-03-05
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.2 <0.9.0;

/**
 * @title Storage
 * @dev Store & retrieve value in a variable
 * @custom:dev-run-script ./scripts/deploy_with_ethers.ts
 */
contract Storage {

    uint256 count;

   constructor() public {
      count = 0;
   }

    /**
     * @dev Increment wave count
     */
    function wave() public {
        count = count + 1;
    }

    /**
     * @dev Return value 
     * @return value of 'count'
     */
    function retrieveWavesCount() public view returns (uint256){
        return count;
    }
}