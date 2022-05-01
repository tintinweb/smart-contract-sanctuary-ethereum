/**
 *Submitted for verification at Etherscan.io on 2022-05-01
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

contract Token {
    string public name;
    string public symbol;
    uint256 public decimals;
    uint256 public totalSupply;

    //Keep track of balances and allowance
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    //fire events on state changes
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    constructor(string memory _name, string memory _symbol, uint _decimals, uint _totalSupply) {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
        totalSupply = _totalSupply; 
        balanceOf[msg.sender] = totalSupply; //all tokens owned by person who deploy contract
    }

    //transfer tokens from owner to another person account
    function transfer(address _to, uint256 _value) external returns (bool success) {
        require(balanceOf[msg.sender] >= _value); //condition to ensure person have tokens
        _transfer(msg.sender, _to, _value);
        return true; 
    }

    function _transfer(address _from, address _to, uint256 _value) internal {
        // Ensure sending is to valid address! 0x0 address cane be used to burn() 
        require(_to != address(0));
        balanceOf[_from] = balanceOf[_from] - (_value);
        balanceOf[_to] = balanceOf[_to] + (_value);
        emit Transfer(_from, _to, _value);
    }

    //Allow approval of tokens before swap
    function approve(address _spender, uint256 _value) external returns (bool) {
        require(_spender != address(0));
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    //Allow dex to swap your tokens for another token
    function transferFrom(address _from, address _to, uint256 _value) external returns (bool) {
        require(_value <= balanceOf[_from]);
        require(_value <= allowance[_from][msg.sender]);
        allowance[_from][msg.sender] = allowance[_from][msg.sender] - (_value);
        _transfer(_from, _to, _value);
        return true;
    }
}