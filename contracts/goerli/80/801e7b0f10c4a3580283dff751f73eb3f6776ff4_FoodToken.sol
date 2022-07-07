/**
 *Submitted for verification at Etherscan.io on 2022-07-07
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.0 <0.9.0;

/**
 * @title Storage
 * @dev Store & retrieve value in a variable
 * @custom:dev-run-script ./scripts/deploy_with_ethers.ts
 */
contract FoodToken {

    address public admin;
    uint256 public totalSupply;
    mapping(address => uint256) public tokenBalances;

    constructor() {
        admin = msg.sender;
    }

    modifier onlyAdmin {
        require(msg.sender == admin, "You are not admin");
        _;
    }

    function mintTokens(address minter, uint256 amount) public onlyAdmin returns (uint256){
        totalSupply += amount;
        tokenBalances[minter] += amount;
        return tokenBalances[minter];
    }

    function burnTokens(address holder, uint256 amount) public onlyAdmin {
        tokenBalances[holder] -= amount;
        totalSupply -= amount;
    }

    function sendTokens(address sender, address recipient, uint256 amount) public {
        require(msg.sender == sender);
        tokenBalances[sender] -= amount;
        tokenBalances[recipient] += amount;
    }
}