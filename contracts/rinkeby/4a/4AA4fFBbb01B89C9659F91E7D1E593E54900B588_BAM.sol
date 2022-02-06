// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;


contract BAM{
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

    error InsufuccientBalance();
    error InsufficientAllowance();

    string public name = unicode"Blockchain Academy Token 🛸";
    string public symbol = "BAM";
    uint8 public decimals = 18;
    uint256 public totalSupply = 100_000_000e18;

    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    constructor(){
        balanceOf[msg.sender] = totalSupply;
    }

    function transfer(address _to, uint256 _value) public returns (bool success){
        if(balanceOf[msg.sender] < _value) revert InsufuccientBalance();

        balanceOf[msg.sender] -= _value;
        balanceOf[_to] += _value;

        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    function approve(address _spender, uint256 _value) public returns (bool success){
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success){
        if(balanceOf[_from] < _value) revert InsufuccientBalance();

        if (_from != msg.sender && allowance[_from][msg.sender] != type(uint256).max) {
            if(allowance[_from][msg.sender] < _value) revert InsufficientAllowance();
            allowance[_from][msg.sender] -= _value;
        }

        balanceOf[_from] -= _value;
        balanceOf[_to] += _value;

        emit Transfer(_from, _to, _value);
        return true;
    }
    
    
}