/**
 *Submitted for verification at Etherscan.io on 2022-04-20
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

// ERC-20 Smart Contract to create any token

contract Token {
  
    // Define Token Parameters 
    string public name;
    string public symbol;
    uint256 public decimals;
    uint256 public totalSupply; // 1 Million + 18 0's for the deceimal places

    // Create mapping(ID/Value Pair) to track all the wallet/contract 
    // addresses that hold this token and how many tokens
    mapping (address => uint256) public balanceOf;

    // Create mapping(ID/Value Pair) to track the address and 
    // the tokens and max amount to send. The exchange has approval to swap
    mapping(address => mapping(address => uint256)) public allowance;


    // ERC-20 requires you to track all events for a transfer or approval 
    // Fired on state changes
    event Transfer (address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    // Constructor to dynamically create any token
    constructor(string memory _name, string memory _symbol, uint _decimals, uint _totalSupply) {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
        totalSupply = _totalSupply; 

        // Assign all the tokens to the wallet address that deployed the Smart Contract
        balanceOf[msg.sender] = totalSupply;
    }

    // Define: Internal helper transfer function
    // @param _from: sender address where tokens are coming from
    // @param _to: receiver address where tokens are going to
    // @param _value: amount of tokens to transfer  
    function _transfer(address _from, address _to, uint256 _value) internal {
        
        // Validate receiver address is a valid address! 0x0 address can be used to burn() 
        require(_to != address(0));

        // Debit the account address of the sender 
        balanceOf[_from] = balanceOf[_from] - (_value);

        //Credit the account address of the receiver
        balanceOf[_to] = balanceOf[_to] + (_value);

        // Track the Transfer event
        emit Transfer(_from, _to, _value);
    }

    // Transfer function to transfer tokens to an address
    // Will be external function that returns a bool success value: true/false
    function transfer(address _to, uint256 _value) external returns(bool){

        // Validate if sender has enough tokens to send
        require(balanceOf[msg.sender] >= _value);

        // Call internal Transfer function
        _transfer(msg.sender, _to, _value);

        return true;
    }

    // Define: Used by exchange to track and get approval to send the token 
    // Allow _spender to spend up to _value on your behalf
    // @param _spender: allowed to spend and a max amount allowed to spend
    // @param _value: amount value of token to send
    // @return true, success once address approved
    function approve(address _spender, uint256 _value) external returns (bool) {
        
        // Validate spender address is a valid address! 0x0 address can be used to burn() 
        require(_spender != address(0));

        // Set the approval to for spender to swap token and max amount
        allowance[msg.sender][_spender] = _value;

        // Track the Approval event
        emit Approval(msg.sender, _spender, _value);

        return true;
    }

    // Define: Called by the Exchange. Transfer by approved address from original address of an amount within approved limit 
    // Allow _spender to spend up to _value on your behalf
    // @param _from: sender address where tokens are coming from
    // @param _to: receiver address where tokens are going to
    // @param _value: amount of tokens to transfer  
    // @return true: success once transfered from the _from account    
    function transferFrom(address _from, address _to, uint256 _value) external returns (bool) {
        
        // Validate if sender has enough tokens to send
        require(_value <= balanceOf[_from]);

        // Validate if sender has enough tokens to send based on max approval amount
        require(_value <= allowance[_from][msg.sender]);

        // Subtract the _value from the approved max transfer amount 
        allowance[_from][msg.sender] = allowance[_from][msg.sender] - (_value);

        // Call internal Transfer function
        _transfer(_from, _to, _value);

        return true;
    }

}