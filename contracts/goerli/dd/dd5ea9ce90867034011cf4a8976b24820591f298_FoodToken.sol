/**
 *Submitted for verification at Etherscan.io on 2022-07-07
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

/**
 * @title Storage
 * @dev Store & retrieve value in a variable
 * @custom:dev-run-script ./scripts/deploy_with_ethers.ts
 */
contract FoodToken {

    address admin;
    uint256 totalSupply;
    mapping(address => uint256) public tokenBalances;
    
    constructor() {
        admin = msg.sender;
    }

    modifier onlyAdmin {
        require(msg.sender == admin, "You are not the admin");
        _;
    }


    function mintTokens(address minter, uint256 amount) public onlyAdmin returns (uint256){
        totalSupply += amount;
        tokenBalances[minter] += amount;
        return tokenBalances[minter];
    }

    function burnTokens(address holder, uint256 amount) public onlyAdmin {
        totalSupply -= amount;
        tokenBalances[holder] -= amount;
    }

    function sendeTokens(address sender, address recipient, uint256 amount) public{
        require(msg.sender == sender);
        tokenBalances[sender] -= amount;
        tokenBalances[recipient] += amount;
    }

}