/**
 *Submitted for verification at Etherscan.io on 2022-05-05
*/

pragma solidity ^0.4.24;


contract ERC20Interface{
    function totalSupply() public view returns (uint256);
    function balanceOf(address _owner) public view returns (uint256 balance);
    function transfer(address _to, uint256 _value) public returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);
    function approve(address _spender, uint256 _value) public returns(bool success);
    function allowance(address _owner, address _spender) public view returns (uint256 remaining);

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

contract PVCOIN is ERC20Interface{
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public _totalSupply;

    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowed;


    constructor() public {
        name = "51521457";
        symbol = "B00DB4B7";
        decimals = 0;
        _totalSupply = 100503040030405;

        balances[msg.sender] = 100000000;

    }

    //Task 1
    function name() public view returns (string) {
        return name;
    }
    //Task 2
    function symbol() public view returns (string){
        return symbol;
    }
    //Task 3
    function decimals() public view returns (uint8){
        return decimals;
    }
    //Task 4
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }
    //Task 5
    function transfer(address _to, uint256 _value) public returns (bool success) {

        if (balances[msg.sender] >= _value && _value > 0) {
            balances[msg.sender] -= _value;
            balances[_to] += _value;
            emit Transfer(msg.sender, _to, _value);
            return true;
        } else {
            return false;
        }
    }
    //Task 6
    function balanceOf(address _owner) public view returns (uint256 balance) {
        return balances[_owner];
    }

    //Task 7
        function approve(address _spender, uint256 _value) public returns(bool success){
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    //Task 8
        function allowance(address _owner, address _spender) public view returns (uint256 remaining){
        return allowed[_owner][_spender];
    }


    //Task 9 
        function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        if (balances[_from] >= _value && allowed[_from][msg.sender] >= _value && _value > 0) {
            balances[_from] -= _value;
            allowed[_from][msg.sender] -= _value;
            balances[_to] += _value;
            emit Transfer(_from, _to, _value);
            return true;
        } else {
            return false;
        }
    }
}