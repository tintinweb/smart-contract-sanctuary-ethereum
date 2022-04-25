// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.10;

import "./StandardToken.sol";

contract CacoaToken is StandardToken {

    /* Public variables of the token */

    /*
    * NOTE:
    * The following variables are OPTIONAL vanities. One does not have to include them.
    * They allow one to customise the token contract & in no way influences the core functionality.
    * Some wallets/interfaces might not even bother to look at this information.
    */
    string public name;                   // Token Name
    uint8 public decimals;                // How many decimals to show. To be standard complicant keep it 18
    string public symbol;                 // A short identifier for your contract: eg SBX, XPR etc..
    uint256 public unitsOneEthCanBuy;     // How many units of your coin can be bought by 1 ETH?
    uint256 public totalRaisedEthInWei;   // WEI is the smallest unit of ETH (the equivalent of cent in USD or satoshi in BTC). We'll store the total ETH raised via our ICO here.  
    address payable public owner;          // The raised ETH will go to this account

    // address public fundsWallet;        // Where should the raised ETH go?


    // This is a constructor function 
    // which means the following function name has to match the contract name declared above
    constructor(){
        _balances[msg.sender] = 1000000000000000000000;               // Give the creator all initial tokens. This is set to 1000 for example. If you want your initial tokens to be X and your decimal is 5, set this value to X * 100000. (CHANGE THIS)
        _totalSupply = 1000000000000000000000;                        // Update total supply (1000 for example) (CHANGE THIS)
        name = "Cacoa Token";                                              // Set the name for display purposes (CHANGE THIS)
        decimals = 18;                                               // Amount of decimals for display purposes (CHANGE THIS)
        symbol = "CACOA";                                            // Set the symbol for display purposes (CHANGE THIS)
        unitsOneEthCanBuy = 10;                                      // Set the price of your token for the ICO (CHANGE THIS)
        owner = payable(msg.sender);                                          // The owner of the contract gets ETH
    }

    /**
    * As of Solidity 0.6.0, if you want your contract to recieve Ether, you have to implement a recieve Ether function
    * (using payable fallback functions for receiving Ether is not recommended, since it would not fail on interface confusions.)
    */
   receive() external payable{
        totalRaisedEthInWei = totalRaisedEthInWei + msg.value;
        uint256 amount = msg.value * unitsOneEthCanBuy;
        require(_balances[owner] >= amount);

        _balances[owner] -= amount;
        _balances[msg.sender]+= amount;

         // Broadcast a message to the blockchain
        emit Transfer(owner,msg.sender,amount);

        //Transfer ether to fundsWallet
        owner.transfer(msg.value);
   }


    /* Approves and then calls the receiving contract */
    // function approveAndCall(address _spender, uint256 _value, bytes _extraData) returns (bool success) {
    //     allowed[msg.sender][_spender] = _value;
    //     Approval(msg.sender, _spender, _value);

    //     //call the receiveApproval function on the contract you want to be notified. This crafts the function signature manually so one doesn't have to include a contract in here just for this.
    //     //receiveApproval(address _from, uint256 _value, address _tokenContract, bytes _extraData)
    //     //it is assumed that when does this that the call *should* succeed, otherwise one would use vanilla approve instead.
    //     if(!_spender.call(bytes4(bytes32(sha3("receiveApproval(address,uint256,address,bytes)"))), msg.sender, _value, this, _extraData)) { throw; }
    //     return true;
    // }
}