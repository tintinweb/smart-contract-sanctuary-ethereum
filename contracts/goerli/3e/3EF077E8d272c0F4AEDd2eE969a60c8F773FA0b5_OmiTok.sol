/**
 *Submitted for verification at Etherscan.io on 2023-02-23
*/

pragma solidity ^0.8.17;

contract OmiTok {
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply;
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;
    address public owner;
    address public upgradedTo;

    constructor(
    ) {
        name = "OmiToken";
        symbol = "OMK";
        decimals = 16;
        totalSupply = 10000000000;
        balanceOf[msg.sender] = totalSupply;
        owner = msg.sender;
    }

    function transfer(address _to, uint256 _value) public returns (bool success) {
        require(balanceOf[msg.sender] >= _value, "Insufficient balance");
        balanceOf[msg.sender] -= _value;
        balanceOf[_to] += _value;
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    function approve(address _spender, uint256 _value) public returns (bool success) {
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(_value <= balanceOf[_from], "Insufficient balance");
        require(_value <= allowance[_from][msg.sender], "Insufficient allowance");
        balanceOf[_from] -= _value;
        balanceOf[_to] += _value;
        allowance[_from][msg.sender] -= _value;
        emit Transfer(_from, _to, _value);
        return true;
    }

    function upgrade(address _newContract) public {
        require(msg.sender == owner, "Only the contract owner can upgrade");
        OmiTok newToken = OmiTok(_newContract);
        require(newToken.totalSupply() == totalSupply, "The new contract must have the same total supply");
        upgradedTo = _newContract;
        emit Upgrade(_newContract);
    }

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
    event Upgrade(address indexed _newContract);
}