/**
 *Submitted for verification at Etherscan.io on 2022-08-27
*/

pragma solidity ^0.5.0;
contract Token
{
    string name;
    string symbol;
    uint decimal;
    uint totalSupply;
    mapping(address=> uint) balances;
            //Owner             spender     amount
    mapping (address => mapping (address => uint256)) public allowed;
    constructor(string memory _name, string memory _symbol, uint _decimal) public
    {
        name=_name;
        symbol=_symbol;
        decimal=_decimal;
    }
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
    function Name() public view returns(string memory)
    {
    return name;
    }
    function Symbol() public view returns (string memory)
    {
        return symbol;
    }
    function decimals() public view returns (uint)
    {
        return decimal;
    }
    function total_supply() public view returns (uint)
    {
        return totalSupply;
    }
    function balanceOf(address owner) public view returns (uint)
    {
    return balances[owner];
    }
    function transfer(address to, uint256 value) public returns (bool success)
    {
        require(balances[msg.sender] >= value);
        balances[msg.sender] -= value;
        balances[to] += value;
        emit Transfer(msg.sender, to, value);
         return true;
    }
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success)
    {
        uint256 allowance = allowed[_from][msg.sender];
        require(balances[_from] >= _value && allowance >= _value);
        balances[_to] += _value;
        balances[_from] -= _value;
        emit Transfer(_from, _to, _value);
        return true;
    }
    function approve(address _spender, uint256 _value) public returns (bool success)
    {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }
    function allowance(address _owner, address _spender) public view returns (uint256 remaining)
    {
          return allowed[_owner][_spender];
    }
}