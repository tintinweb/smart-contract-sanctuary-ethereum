/**
 *Submitted for verification at Etherscan.io on 2022-06-27
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;
// use latest solidity version at time of writing, need not worry about overflow and underflow

/// @title ERC20 Contract 

contract Eevo004 {

    // My Variables
    string public name;
    string public symbol;
    uint256 public decimals;
    uint256 public totalSupply;
    // -- fee %
    // --- Burn
    uint256 public fee_burn;
    // --- Liquidity Partners
    uint256 public fee_liquidityPartners;
    // --- Marketing
    uint256 public fee_marketing;
    // --- Operations
    uint256 public fee_operations;
    // -- Wallets
    // --- Burn
    address public w_burn = 0x7E92016040d6FEE9b1F75853C0b006023DeF5084;
    // --- Liquidity Partners
    address public w_liquidityPartners = 0x7E92016040d6FEE9b1F75853C0b006023DeF5084;
    // --- Marketing
    address public w_marketing = 0x7E92016040d6FEE9b1F75853C0b006023DeF5084;
    // --- Operations
    address public w_operations = 0x7E92016040d6FEE9b1F75853C0b006023DeF5084;

    // Keep track balances and allowances approved
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    // Events - fire events on state changes etc
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    constructor(string memory _name, string memory _symbol, uint _decimals, uint _totalSupply, uint _fee_burn, uint _fee_liquidityPartners, uint _fee_marketing, uint _fee_operations) {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
        totalSupply = _totalSupply; 
        balanceOf[msg.sender] = totalSupply;
        fee_burn = _fee_burn;
        fee_liquidityPartners = _fee_liquidityPartners;
        fee_marketing = _fee_marketing;
        fee_operations = _fee_operations;
    }

    /// @notice transfer amount of tokens to an address
    /// @param _to receiver of token
    /// @param _value amount value of token to send
    /// @return success as true, for transfer 
    function transfer(address _to, uint256 _value) external returns (bool success) {
        require(balanceOf[msg.sender] >= _value);
        _transfer(msg.sender, _to, _value);
        return true;
    }

    //calculate fees
    function retrieveFee(address _from, address _to, uint256 _value, uint _fee) internal returns (uint fee) {
        fee = _value * _fee / 100;
        require(_to != address(0));
        _transfer(_from, _to, fee);
        return fee;
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

        uint totalFee = 0;
        //Fee for Burn Wallet
        totalFee += retrieveFee(_from, w_burn, _value, fee_burn);
        totalFee += retrieveFee(_from, w_burn, _value, fee_liquidityPartners);
        totalFee += retrieveFee(_from, w_burn, _value, fee_marketing);
        totalFee += retrieveFee(_from, w_burn, _value, fee_operations);

        _value -= totalFee;
        _transfer(_from, _to, _value);
        return true;
    }

}