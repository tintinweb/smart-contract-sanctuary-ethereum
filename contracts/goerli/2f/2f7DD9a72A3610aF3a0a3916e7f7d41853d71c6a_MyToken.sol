/**
 *Submitted for verification at Etherscan.io on 2022-12-20
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

contract MyToken{
    //Var
    string public name = "Chad Token";
    string public symbol = "CTK";
    uint256 public decimals = 18; //The convention is to do 18 decimal places because that's how ethers work
    uint256 public totalSupply = 1000000000000000000;

    //mapping
    mapping(address => uint256) public balanceOf;
    mapping(address=>mapping(address=>uint256)) public allowance;
    //events
    event Transfer(address indexed from, address indexed to, uint value); //The erc20 standard requires us to actually log events every time a transfer events append
    event Approval(address indexed owner, address indexed spender, uint256 value);

    constructor(string memory _name,string memory _symbol,uint256 _decimals,uint256 _totalSupply){
        name=_name;
        symbol=_symbol;
        decimals=_decimals;
        totalSupply=_totalSupply;
        balanceOf[msg.sender] = totalSupply; //the person who deploys the contrat gets all the token
    }

    //transfer amount of tokens to an address
    function tranfer(address _to, uint256 _value) external returns(bool success){
        require(balanceOf[msg.sender] >= _value, "Not enough money");
        require(_value<totalSupply, "You asked for too much tokens");
        _transfer(msg.sender,_to,_value);
        return true;
    }

    function approve(address _spender, uint256 _value) external returns (bool) {
        require(_spender != address(0));
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) external returns (bool) {
        require(_value <= balanceOf[_from]);
        require(_value <= allowance[_from][msg.sender]);
        allowance[_from][msg.sender] = allowance[_from][msg.sender] - (_value);
        _transfer(_from, _to, _value);
        return true;
    }

    //internal helper transfer function with required safety checks
    function _transfer(address _from, address _to, uint256 _value) internal {
        require(_to != address(0)); // Ensure sending is to valid address! 0x0 address can be used to burn() 
        balanceOf[_from] = balanceOf[_from] - _value;
        balanceOf[_to] = balanceOf[_to] + _value;
        emit Transfer(_from, _to, _value);
    }
}