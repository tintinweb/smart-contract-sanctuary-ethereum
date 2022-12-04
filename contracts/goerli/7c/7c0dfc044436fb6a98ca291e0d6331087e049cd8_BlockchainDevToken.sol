// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.10;

import "./StandardToken.sol";

contract BlockchainDevToken is StandardToken {
    /**
     * Public variables of the token
     * NOTE: The following variables are OPTIONAL variables. One does not have to include them
     * They allow one to customize the token contract & in no way influences the core functionality
     * Some wallet/interfaces might not even bother to look at this information
     */
    string public name; // Token Name
    uint8 public decimals; // Number of decimals that our token will have. To be standard-compliant, keep it 18
    string public symbol; // A short identifier for your contract (eg: ACAD for Academt toke, EOS, etc)
    uint256 public unitsOneEthCanBuy; // How many units of your token can be bought by 1 ETH?
    // (eg: 1 ETH (1,000,000,000,000,000,000 wei) = 10 tokens)
    uint256 public totalRaisedEthInWei; // WEI is the smallest unit of ETH. Similar to cent in USD or Sat in BTC. This is...
    // the total raised eth of the ICO
    address payable public owner; // The raised ETH will go to this account

    constructor() {
        decimals = 18; // Number of decimals for your token
        _totalSupply = 1000000000000000000000; // Update the total supply of your token (1000 * 10^18)
        _balances[msg.sender] = _totalSupply; // Grant the contract creator all initial tokens. In this cae, 1000
        // eg: if you wnat initial tokens to be 500, & your deimals is 6,...
        // then set this value to: (500 * 10^6)
        name = "Blockchain Dev Token"; // Set name - for display purposes
        symbol = "BDT"; // Set symbol - for display purposes
        unitsOneEthCanBuy = 10; // Set the price of your token for the ICO
        // in this case: if users pay 1 ETH, they will receive 10 BDT
        owner = payable(msg.sender); // Owner of this contract gets the total ETH raised
    }

    /**
     * As of Solidity 0.6.0, if you want your contract to receive Ether, you have to implement a receive Ether function
     * (using payable fallback fcns for receiving Ether is not recommended, as it would not fail on interface confusions)
     */
    receive() external payable {
        totalRaisedEthInWei = totalRaisedEthInWei + msg.value;
        uint256 amount = msg.value * unitsOneEthCanBuy;
        require(_balances[owner] >= amount);
        _balances[owner] -= amount;
        _balances[msg.sender] += amount;
        emit Transfer(owner, msg.sender, amount);
        owner.transfer(msg.value);
    }
}