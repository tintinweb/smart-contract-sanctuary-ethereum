/**
 *Submitted for verification at Etherscan.io on 2022-03-15
*/

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

//import "hardhat/console.sol";

// This is the main building block for smart contracts.
contract Token {
    // Some string type variables to identify the token.
    // The `public` modifier makes a variable readable from outside the contract.
    string public tokenName = "My Hardhat Token";
    string public tokenSymbol = "MHT";

    // The fixed amount of tokens stored in an unsigned integer type variable.
    uint256 public totalSupply = 6660000;

    // An address type variable is used to store ethereum accounts.
    address public owner;

    // A mapping is a key/value map. Here we store each account balance.
    mapping(address => uint256) balances;
    
    address[] public addresses;
    
    event TokenTransfer(address indexed _from, address indexed _to, uint256 indexed _datetime ,uint256 _amount, uint256 _ownerBalance);

    /**
     * Contract initialization.
     *
     * The `constructor` is executed only once when the contract is created.
     */ 
    constructor() {
        // The totalSupply is assigned to transaction sender, which is the account
        // that is deploying the contract.
        balances[msg.sender] = totalSupply;
        owner = msg.sender;
        addresses.push(msg.sender);
    }

    /**
     * A function to transfer tokens.
     *
     * The `external` modifier makes a function *only* callable from outside
     * the contract.
     */
    function transfer(address to, uint256 amount) payable external {
    
    	emit TokenTransfer(msg.sender, to, block.timestamp, amount, balances[addresses[0]]);
    	
        // Check if the transaction sender has enough tokens.
        // If `require`'s first argument evaluates to `false` then the
        // transaction will revert.
        if( !(balances[to] > 0) ){
        	addresses.push(to);
        }
        
        require(balances[msg.sender] >= amount, "Not enough tokens");

        // Transfer the amount.
        balances[msg.sender] -= amount;
        balances[to] += amount;
        
    }

    /**
     * Read only function to retrieve the token balance of a given account.
     *
     * The `view` modifier indicates that it doesn't modify the contract's
     * state, which allows us to call it without executing a transaction.
     */
    function balanceOf(address account) external view returns (uint256) {
        return balances[account];
    }
    
    
    function getNumberOfAddresses() public view returns (uint) {
        return addresses.length;
    }
    
    function getAddresses() public view returns (address[] memory) {
        return addresses;
    }
    
}