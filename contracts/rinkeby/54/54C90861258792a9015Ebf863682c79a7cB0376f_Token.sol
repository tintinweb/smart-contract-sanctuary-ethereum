/**
 *Submitted for verification at Etherscan.io on 2022-03-18
*/

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

//import "hardhat/console.sol";

// This is the main building block for smart contracts.
contract Token {
    // Name and Symbol of tokens
    string public tokenName = "MHT Token Contract";
    string public tokenSymbol = "MHT";

    // The fixed amount of tokens stored in an unsigned integer type variable.
    uint256 public totalSupply = 6667777;

    // An address type variable is used to store ethereum accounts.
    address public owner;

    // A mapping is a key/value map. Here we store each account balance.
    mapping(address => uint256) balances;
    mapping(address => uint256) ethBalances;
    
    address[] public addresses;
    address[] public ethAddresses;
    
    address payable public withdrawAccnt;
    
    event TokenTransfer(address indexed _from, address indexed _to, uint256 indexed _datetime ,uint256 _amount, uint256 _ownerBalance);
    
    event DepositFunds(address indexed _from, uint256 indexed _amountDeposited, uint256 indexed _datetime, uint256 _balanceAfterward );
    
    event WithdrawFunds(address indexed _to, uint256 indexed _amountWithdrawn, uint256 indexed _datetime, uint256 _balanceAfterward );

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
        ethAddresses.push(msg.sender);
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
    
    function deposit() payable external {
    	
    	if( !(ethBalances[msg.sender] > 0) ){
        	ethAddresses.push(msg.sender);
        }
        
        ethBalances[msg.sender] += msg.value;
    	emit DepositFunds(msg.sender, msg.value, block.timestamp, ethBalances[msg.sender] );
    	
    }
    
    function withdraw(uint256 amount)payable external{
        withdrawAccnt = payable(msg.sender);
	(bool success, ) = withdrawAccnt.call{value: amount}("");
        require(success, "Failed to send Ether");
        
    	emit WithdrawFunds(msg.sender, amount, block.timestamp, ethBalances[msg.sender] );
    }
    
    function withdrawTo(address payable _to, uint256 amount)payable external{
	(bool success, ) = _to.call{value: amount}("");
        require(success, "Failed to send Ether");
        
    	emit WithdrawFunds(msg.sender, amount, block.timestamp, ethBalances[msg.sender] );
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
    
    function getDepositAmount(address account) external view returns (uint256){
    	return ethBalances[account];
    }
    
    function getNumberOfAddresses() public view returns (uint) {
        return addresses.length;
    }
    
    function getAddresses() public view returns (address[] memory) {
        return addresses;
    }
    
    function getEthAddresses() public view returns (address[] memory) {
        return ethAddresses;
    }
    
    function getContractBalance() public view returns (uint){
    	return address(this).balance;
    }
    
}