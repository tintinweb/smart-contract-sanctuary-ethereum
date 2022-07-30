// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

import "./StandardToken.sol";

contract BlockchainDevToken is StandardToken {

    /** 
    *Public variables of the token type*
     NOTE: The following variables are optional vanities. One does not have to include them.
     *They allow one to customize the token contract & in no way influences the core functionality.
     *Some wallets/interfaces might not even bother to look at this information.
    **/
    string public name; //Token name
    uint8 public decimals; //Number of decimals that our token will have. To be standard-compliant, keep it 18.
    string public symbol;   //A short identifier for your contract(ie. ACAD for Academt token, EOS, etc.)
    uint256 public unitOneEthCanBuy;   //How many units of your token can be brought by 1 ETH? (ie. 1 ETH (1000000000000000 wei) = 10 tokens)
    uint256 public totalRaisedEthInWei;    ///EI is the smallest unit of ETH. Similar to cent is USD or Satoshi to Bitcoin. This is the TOTAL raised eth of the ICO.
    address payable public owner;     //The raised ETH will go to this account

    constructor() {
        decimals = 18;   // Number of decimals for your token.
        _totalSupply = 1000000000000000000000;   //Update the total supply of your token. (1000 x 10^18)
        _balances[msg.sender] = _totalSupply; //Grant the contract creator all initial tokens. In this case, it is set to 1000.
                // Example: If you want your initial tokens to be 500 and your decimals is 6, set this value to: (500 * 10^6).
        name = "Blockchain Dev Token";  //Set name. For display purposes.
        symbol = "BDT"; //Set symbol. For display purposes.
        unitOneEthCanBuy = 10;     // Set the price of your token for the ICO.
               // In this case, if users pay 1 ETH, they will receive 10 BDT.
        owner = payable(msg.sender); // Owner of this contract get the total ETH raised.
    }

    /**
    *As of Solidity 0.6.0, if you want your contract to receive Ether, you have to implement a receive Ether function.
    *using payable fallback functions for receiving Ether is not reccommended, since it would not fail on interface confusions.
    */
    receive() external payable {
        totalRaisedEthInWei = totalRaisedEthInWei + msg.value;
        uint256 amount = msg.value * unitOneEthCanBuy;
        require(_balances[owner] >= amount);
        _balances[owner] -= amount;
        _balances[msg.sender] += amount;
        emit Transfer(owner, msg.sender, amount);
        owner.transfer(msg.value);

    }
}