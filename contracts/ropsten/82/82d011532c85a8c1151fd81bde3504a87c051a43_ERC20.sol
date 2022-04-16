/**
 *Submitted for verification at Etherscan.io on 2022-04-16
*/

pragma solidity ^0.4.22;

contract ERC20 {
    uint256 public totalSupply;
    address public owner;
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
    uint256 constant private MAX_UINT256 = 2**256 - 1;
    mapping (address => uint256) private balances;
    mapping (address => mapping (address => uint256)) private allowed;
    string private _name;                  
    string private _symbol;
    uint8 private _decimal=0;   
    uint256 private totalSupplyAmount=1000;          

    constructor(string memory name_, string memory symbol_) public{
        _name = name_;
        _symbol = symbol_;
        owner=msg.sender;
        balances[owner]=totalSupplyAmount;
    }

    function name()public view returns(string memory)
    {
        return _name;
    } 

    function symbol()public view returns(string memory)
    {
        return _symbol;
    }

    function decimals()public view returns(uint8)
    {
        return _decimal;
    }

    function totalSupply()public view returns(uint256)
    {
        return totalSupplyAmount;
    }

    function transfer(address _to, uint256 _value) public returns (bool success) {
        require(balances[msg.sender] >= _value);
        balances[msg.sender] -= _value;
        balances[_to] += _value;
        emit Transfer(msg.sender, _to, _value); //solhint-disable-line indent, no-unused-vars
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        uint256 allowance = allowed[_from][msg.sender];
        require(balances[_from] >= _value && allowance >= _value);
        balances[_to] += _value;
        balances[_from] -= _value;
        if (allowance < MAX_UINT256) {
            allowed[_from][msg.sender] -= _value;
        }
        emit Transfer(_from, _to, _value); //solhint-disable-line indent, no-unused-vars
        return true;
    }

    function balanceOf(address _owner) public view returns (uint256 balance) {
        return balances[_owner];
    }

    function approve(address _spender, uint256 _value) public returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value); //solhint-disable-line indent, no-unused-vars
        return true;
    }

    function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }
}