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
contract Storage {

    uint256 buyer;
    uint256 condoName;


    function store(uint256 name, uint256 cName) public {
        buyer = name;
        condoName = cName;
    }

    /**
     * @dev Return value 
     * @return value of 'number'
     */
    function getBuyer() public view returns (uint256){
        return buyer;
    }

    function getName() public view returns (uint256){
        return condoName;
    }
}