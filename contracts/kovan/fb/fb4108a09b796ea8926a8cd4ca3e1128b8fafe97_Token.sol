/**
 *Submitted for verification at Etherscan.io on 2022-05-25
*/

// declare license identifier
// SPDX-License-Identifier: MIT

// declare solidity version
pragma solidity ^0.8.6;

contract Token {

    /////////// Variables //////////////
    // every ERC20 token must have a name
    // public allows the variable to be read OUTSIDE of the smart contract
    string public name;

    // every token must have a symbol
    string public symbol;

    // 18 decimals is conventional because Ether is divisible by 18 decimal places
    uint256 public decimals;

    // 18 decimals after 1 million (6 zeros) - total 24 zeros
    uint256 public totalSupply;


    /////////// Keep track of balances and allowances approved //////////////
    // Contract should keep track of who owns how many tokens - by using mapping
    // key-value : address-balance
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;


    ////////// Events - fire events on state changes etc //////////////
    // ERC20 standard requires us to log an event every time a transaction is created
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    // properties for each token created
    constructor(string memory _name, string memory _symbol, uint _decimals, uint _totalSupply) {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
        totalSupply = _totalSupply;
        // all tokens have been assigned to us
        balanceOf[msg.sender] = totalSupply;
    }

    /// @notice transfer amount of tokens to an address
    /// @param _to receiver of token
    /// @param _value amount value of token to send
    /// @return success as true, for transfer 
    function transfer(address _to, uint256 _value) external returns (bool success) {
        // make sure the sender has enough tokens to make transaction - else transfer will not execute
        require(balanceOf[msg.sender] >= _value);

        // subtract send amount from balance of sender
        balanceOf[msg.sender] = balanceOf[msg.sender] - (_value);
        // add send amount to balance of receiver
        balanceOf[_to] = balanceOf[_to] + (_value);
        // log transfer event
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    /// @dev internal helper transfer function with required safety checks
    /// @param _from, where funds coming the sender
    /// @param _to receiver of token
    /// @param _value amount value of token to send
    // Internal function transfer can only be called by this contract
    //  Emit Transfer Event event 
    function _transfer(address _from, address _to, uint256 _value) internal {
        // Ensure sending is to valid address! 0x0 address cane be used to burn() 
        require(_to != address(0));
        balanceOf[_from] = balanceOf[_from] - (_value);
        balanceOf[_to] = balanceOf[_to] + (_value);
        emit Transfer(_from, _to, _value);
    }
    
    /// @notice Approve other to spend on your behalf eg an exchange 
    /// @param _spender allowed to spend and a max amount allowed to spend
    /// @param _value amount value of token to send
    /// @return true, success once address approved
    //  Emit the Approval event  
    // Allow _spender to spend up to _value on your behalf
    function approve(address _spender, uint256 _value) external returns (bool) {
        require(_spender != address(0));
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    /// transferFrom because listed on exchange and gives approval to exchange to spend our token
    /// @notice transfer by approved person from original address of an amount within approved limit 
    /// @param _from, address sending to and the amount to send
    /// @param _to receiver of token
    /// @param _value amount value of token to send
    /// @dev internal helper transfer function with required safety checks
    /// @return true, success once transfered from original account    
    // Allow _spender to spend up to _value on your behalf
    function transferFrom(address _from, address _to, uint256 _value) external returns (bool) {
        require(_value <= balanceOf[_from]);
        require(_value <= allowance[_from][msg.sender]);
        allowance[_from][msg.sender] = allowance[_from][msg.sender] - (_value);
        _transfer(_from, _to, _value);
        return true;
    }
}