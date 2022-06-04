/**
 *Submitted for verification at Etherscan.io on 2022-06-03
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >= 0.5.0 < 0.9.0;

contract Byte_Array_Dynamic
{
    address public Owner;
    string public name;
    string public symbol;
    uint256 public decimals;
    uint256 public totalSupply;
    mapping (address => uint256) public Balances;
    mapping (address => mapping (address => uint256)) public Allowed;
    
    event Transfer(address indexed from, address indexed to, uint256 amount);
    event Approval(address indexed owner, address indexed spender, uint256 amount);

    constructor (string memory _name, string memory _symbol, uint256 _decimals, uint256 _totalSupply)
    {
        Owner = msg.sender;
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
        totalSupply = _totalSupply;

        Balances[msg.sender] = totalSupply;
    }
    modifier OnlyOwner()
    {
        require (msg.sender == Owner,"You are not an Owner");
        _;
    }
    function balanceOf(address account) public view returns (uint256)
    {
        return Balances[account];
    }
    function mint(address account, uint256 amount) public OnlyOwner returns (bool success)
    {
        totalSupply += amount;
        Balances[account] += amount;
        return true;
    }
    function burn(uint256 amount) public OnlyOwner returns (bool success)
    {
        require (Balances[msg.sender] >= amount,"Amount is less than the Burning Amount");       
        totalSupply -= amount;
        Balances[msg.sender] -= amount;
        return true;
    }
    function transfer(address to, uint256 amount) public returns (bool success)
    {
        require (Balances[msg.sender] >= amount,"You have entered less amount");
        Balances[msg.sender] -= amount;
        Balances[to] += amount;

        emit Transfer(msg.sender, to, amount);
        return true;
    }
    function allowance(address _owner, address _spender) public view returns (uint256 remaining)
    {
        return Allowed[_owner][_spender];
    }
    function approve(address _spender, uint256 amount) public OnlyOwner() returns (bool success)
    {
        require (_spender != address (0));
        Allowed[msg.sender][_spender] = amount;
        
        emit Approval (msg.sender, _spender, amount);
        return true;
    }
    function transferFrom(address from, address to, uint256 amount) public returns (bool success)
    {
        require (Balances[from] >= amount && Allowed[from][msg.sender] >= amount, "Your amount is less");
        Balances[from] -= amount;
        Balances[to] -= amount;

        Allowed[from][msg.sender] -= amount;
        emit Transfer(from, to, amount);
        return true;
    }
}