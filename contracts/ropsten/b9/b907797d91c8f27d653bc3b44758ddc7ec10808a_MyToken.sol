/**
 *Submitted for verification at Etherscan.io on 2022-08-20
*/

pragma solidity ^0.6.1;

contract MyToken {
    string public name = "My first token coin";
    uint8 public decimals = 18;
    string public symbol = "MFTC";
    uint public totalSupply;

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

    mapping(address => uint256)public balances;
    mapping(address => mapping(address => uint256))public allowed;

    constructor() public {
        totalSupply = 100000000000000000000000000;
        balances[msg.sender] = totalSupply;
    }
    function balanceOf(address _owner) public view returns (uint256 balance){
        return balances[_owner];
    }

    function approve(address _spender, uint256 _value) public returns (bool success){
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) public view returns (uint256 remaining){
        return allowed[_owner][_spender];
    }

    function transfer(address _to, uint256 _value) public returns (bool success){
        require(_to != address(0x0));
        require(balances[msg.sender] >= _value);
        require(balances[_to] + _value >= balances[_to]);
        balances[msg.sender] -= _value;
        balances[_to] += _value;
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success){
        require(_to != address(0x0));
        uint256 allowanceValue = allowed[_from][msg.sender];
        require(balances[_from] >= _value && allowanceValue >= _value);
        require(balances[_to] + _value >= balances[_to]);
        allowed[_from][msg.sender] -= _value;
        balances[_to] += _value;
        balances[_from] -= _value;
        emit Transfer(_from, _to, _value);
        return true;
    }
}