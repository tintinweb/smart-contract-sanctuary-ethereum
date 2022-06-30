/**
 *Submitted for verification at Etherscan.io on 2022-06-30
*/

// SPDX-License-Identifier: MIT

pragma solidity >= 0.8.0;

contract Currency {
    
    string public name;
    string public symbol;
    uint256 public decimals;
    uint256 public totalSupply;

    mapping(address => uint) balanceOf;
    mapping(address => mapping(address => uint)) allowance;

    event Transfer(address indexed _from, address indexed _to, uint _anount);
    event Approval(address indexed _owner, address indexed _spender, uint _amount);

    constructor(string memory _name, string memory _symbol, uint256 _decimals, uint256 _totalSupply)
    {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
        totalSupply = _totalSupply;
        balanceOf[msg.sender] = _totalSupply;
    }

    function internalTransfer(address _from, address _to, uint _amount) internal
    {
        require(balanceOf[_from] >= _amount, "not enough funds");
        balanceOf[_from] -= _amount;
        balanceOf[_to] += _amount;
        emit Transfer(_from, _to, _amount);
    }

    function transfer(address _to, uint _amount) external returns(bool)
    {
        require(_to != address(0));
        internalTransfer(msg.sender, _to, _amount);
        return true;
    }

    function approve(address _spender, uint _amount) external returns(bool)
    {
        require(_spender != address(0), "invalid address");
        require(_amount > 0, "amount must be bigger than zero");
        allowance[msg.sender][_spender] = _amount;
        emit Approval(msg.sender, _spender, _amount);
        return true;
    }

    function transferFrom(address _from, address _to, uint _amount) external returns(bool)
    {
        require(balanceOf[_from] >= _amount, "not enough funds");
        require(allowance[_from][msg.sender] >= _amount, "Not approved to spend this quantity");
        allowance[_from][msg.sender] -= _amount;
        internalTransfer(_from, _to, _amount);
        return true;
    }


}