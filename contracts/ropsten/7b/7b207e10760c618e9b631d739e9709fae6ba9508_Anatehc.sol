/**
 *Submitted for verification at Etherscan.io on 2022-03-18
*/

pragma solidity ^0.8.13;

contract Anatehc{
    string public name;
    string public symbol;
    uint public decimals;

    uint256 public _totalSupply;

    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowed;

    event Transfer(address indexed _from, address indexed _to, uint _value);
    event Approval(address indexed _owner, address indexed _spender, uint _value);

    // Constuctor to initalise contract w inital supply token to the contract creater 

   constructor() public {
        name = "Anatehc";
        symbol = "ATC";
        decimals = 18;
        _totalSupply = 100000000000000000000000000; //1 billion token with 18 decimal places

        balances[msg.sender]= _totalSupply;
        emit Transfer(address(0), msg.sender, _totalSupply);
    }

    function totalSupply() public view returns (uint){
        return _totalSupply - balances[address(0)];
    }

    function balanceOf(address _owner) public view returns (uint balance){
        return balances[_owner];
    }

    function allowance(address _owner, address _spender) public view returns (uint remaining){
        return allowed[_owner][_spender];
    }

    function approve(address _spender, uint _value) public returns (bool success){
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }
    function transfer(address _to, uint _value) public returns (bool success){
        balances[msg.sender] = balances[msg.sender] - _value;
        balances[_to] = balances[_to] + _value;
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint _value) public returns (bool success){
        balances[_from] = balances[_from] - _value;
        allowed[_from][msg.sender] = allowed[_from][msg.sender]- _value;
        balances[_to] = balances[_to] + _value;
        emit Transfer(_from, _to, _value);
        return true;
    }
}