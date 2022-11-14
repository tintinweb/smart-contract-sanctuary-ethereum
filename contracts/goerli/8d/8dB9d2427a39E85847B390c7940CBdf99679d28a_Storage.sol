/**
 *Submitted for verification at Etherscan.io on 2022-11-14
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

/**
 * @title Storage
 * @dev Store & retrieve value in a variable
 * @custom:dev-run-script ./scripts/deploy_with_ethers.ts
 */
contract Storage {

    uint256 boatID;
    // stall ค่า
    function rent(uint256 boat) public {
        boatID = boat;
    }

    /**
     * @dev Return value 
     * @return value of 'number'
     */
     // ดึงค่าเเละเก็บค่า
    function retrieve() public view returns (uint256){
        return boatID;
    // }
}
}