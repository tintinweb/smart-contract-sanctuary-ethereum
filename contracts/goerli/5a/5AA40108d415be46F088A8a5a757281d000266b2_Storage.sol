/**
 *Submitted for verification at Etherscan.io on 2022-11-15
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

/**
 * @title Storage
 * @dev Store & retrieve value in a variable
 * @custom:dev-run-script ./scripts/deploy_with_ethers.ts
 */
contract Storage {

    uint256 amount;
    uint256 price;

    
    function store(uint256 amountt,uint256 pricee) public {
        amount = amountt;
        price = pricee;
    }

    
    function retrieveAmount() public view returns (uint256){
        return amount;
    }

    function retrievePrice() public view returns (uint256){
        return price;
    }
}