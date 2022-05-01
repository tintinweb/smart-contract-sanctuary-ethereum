/**
 *Submitted for verification at Etherscan.io on 2022-05-01
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.13;

contract Token {
    // initialize state variables
    string public tokenName;
    string public symbol;
    uint public decimals;
    uint public totalSupply;

    // Keep track of balances and allowances approved
    mapping(address => uint) public balanceValue;
    // Map address of own account to account that is allowed to spend on your behalf
    mapping(address => mapping(address => uint256)) public permission;


    // ERC-20 token standards require logging events everytime there is a transfer 
    // The arguments in the event are logged for all users to see
    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    // Create Token and its properties
    constructor(string memory _tokenName, string memory _symbol, uint _decimals, uint _totalSupply) {
        // Access state variables to be arguemnts passed to constructor
        tokenName = _tokenName;
        symbol = _symbol;
        decimals = _decimals;
        totalSupply = _totalSupply;
        // sender is the person calling the function aka person deploying smart contract
        balanceValue[msg.sender] = totalSupply;
    }   

    /// @notice transfer amount of tokens to an address
    /// @param _to receiver of token
    /// @param _value amount value of token to send
    /// @return success as true for successfull transfer 
    // Function to enable transfer of funds
    function transfer(address _to, uint _value) external returns(bool success) {
        // control flow with require to ensure enough existing balance in user account
        require(balanceValue[msg.sender] >= _value, "Insufficient balance");
        // Trigger helper function
        _transferHelper(msg.sender, _to, _value);
        return true;
    }

    /// @dev internal helper transfer function with required safety checks
    /// @param _from, where funds coming the sender
    /// @param _to receiver of token
    /// @param _value amount value of token to send
    //  Internal function transfer can only be called by this contract
    //  Emit Transfer Event 
    function _transferHelper(address _from, address _to, uint _value) internal {
        // Prevent transfer to invalid address
        require(_to != address(0));
        // debit value from account
        balanceValue[_from] = balanceValue[_from] - _value;
        // credit value to another account
        balanceValue[_to] = balanceValue[_to] + _value;
        // emit event
        emit Transfer(_from, _to, _value);
    }

    /// @notice Approve other party (i.e. decentralized exchange) to spend on your behalf 
    /// @param _spender allowed to spend and a max amount allowed to spend
    /// @param _value amount value of token to send
    /// @return true, success once address approved
    //  Emit the Approval event  
    //  Allow _spender to spend up to _value on your behalf
    function approve(address _spender, uint _value) external returns (bool) {
        require(_spender != address(0), "Invalid Address");
        permission[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    /// @notice transfer by approved person (i.e. decentralzied exchange) from original address of an amount within approved limit 
    /// @param _from, address sending to and the amount to send
    /// @param _to receiver of token
    /// @param _value amount value of token to send
    /// @dev internal helper transfer function with required safety checks
    /// @return true, success once transfered from original account    
    // Allow _spender to spend up to _value on your behalf
    function transferFrom(address _from, address _to, uint _value) external returns (bool) {
        require(_value <= balanceValue[_from]);
        require(_value <= permission[_from][msg.sender]);
        permission[_from][msg.sender] = permission[_from][msg.sender] - _value;
        _transferHelper(_from, _to, _value);
        return true;
    }
}