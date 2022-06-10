/**
 *Submitted for verification at Etherscan.io on 2022-06-09
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

/**
 * @title Storage
 * @dev Store & retrieve value in a variable
 * @custom:dev-run-script ./scripts/deploy_with_ethers.ts
 */
contract Storage {
    mapping(address => uint) balances;

    function setBalance(address owner, uint amount) public {
        require(owner == msg.sender, "Must be owner.");
        balances[owner] = amount;
    }

    function getBalance(address owner) public view returns (uint){
        return balances[owner];
    }

    function transferBalance(address from, address to) public {
        require(from == msg.sender, "Must be owner.");
        balances[to] = balances[from];
        balances[from] = 0;
    }
}