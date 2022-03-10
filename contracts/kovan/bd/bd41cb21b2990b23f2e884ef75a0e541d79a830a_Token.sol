/**
 *Submitted for verification at Etherscan.io on 2022-03-10
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

contract Token {
    string public name = "Dalmaga";
    string public symbol= "DMA";
    uint256 public decimals = 18;
    uint256 public totalSupply = 1000000000000000000000000;

    // Maps an address to an integer
    // Keeps track of how many tokens each account holds
    mapping(address => uint256) public balanceOf;
    // Maps an address to another map
    // Keeps track of how much an account can spend of a given account's tokens
    mapping(address => mapping(address => uint256)) public allowance;
    
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    // Called by remix when executing the contract
    // Will initialize staate variables to the values passed in.
    constructor(string memory _name, string memory _symbol, uint _decimals, uint _totalSupply) {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
        totalSupply = _totalSupply;

        // msg is a global variable
        // sender is the person connecting with the contract
        balanceOf[msg.sender] = totalSupply;
    }

    // Exchanges like UniSwap spend tokens on your behalf
    // This function lets other accounts spend tokens from a given account
    // Should be called by client to make sure msg.sender is correct
    function approve(address _spender, uint256 _value) external returns (bool) {
        // Require that the account spending your crypto has a valid address
        require(_spender != address(0));
        // Allow _spender to spend a certain amount of msg.senders tokens
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    // Make this function external so that it reads directly from call data
    // This uses less gas since memory allocation is expensive
    function transfer(address _to, uint256 _value) external returns (bool success) {
        require(balanceOf[msg.sender] >= _value);
        balanceOf[msg.sender] = balanceOf[msg.sender] - (_value);
        balanceOf[_to] = balanceOf[_to] + (_value);
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    function _transfer(address _from, address _to, uint256 _value) internal {
        // Ensure sending is to valid address! 0x0 address can be used to burn() 
        require(_to != address(0));
        balanceOf[_from] = balanceOf[_from] - (_value);
        balanceOf[_to] = balanceOf[_to] + (_value);
        emit Transfer(_from, _to, _value);
    }

     function transferFrom(address _from, address _to, uint256 _value) external returns (bool) {
        require(_value <= balanceOf[_from]);
        require(_value <= allowance[_from][msg.sender]);
        allowance[_from][msg.sender] = allowance[_from][msg.sender] - (_value);
        _transfer(_from, _to, _value);
        return true;
    }
}