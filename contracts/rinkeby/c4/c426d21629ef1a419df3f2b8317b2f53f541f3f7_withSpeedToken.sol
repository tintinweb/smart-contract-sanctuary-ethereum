/**
 *Submitted for verification at Etherscan.io on 2022-05-05
*/

pragma solidity ^0.4.24;

contract withSpeedToken {
    address public owner;
    SpeedToken speedToken;

    mapping (address => uint256) public transferMap;

    constructor(address _address) public payable {
        owner = msg.sender;
        speedToken = SpeedToken(_address);
    }

    function () payable public {
    }

    function balanceof(address _address) public view returns (uint256 _value) {
        return transferMap[_address];
    }

    function transfer(uint256 _value) public returns (bool success) {
        transferMap[msg.sender] += _value;
        return speedToken.transfer(owner,_value);
    }

    function withdraw(uint256 _value) public returns (bool success) {
        require(transferMap[msg.sender] >= _value);
        transferMap[msg.sender] -= _value;
        return speedToken.transfer(msg.sender,_value);
    }
}

contract SpeedToken {
    string public name="Speed token coin"; // 代币的名称
    uint8 public decimals = 18;// 精确小数点位数
    string public symbol = "SPD";//代币符号
    uint public totalPublic;//代币发行量
    
    mapping (address => uint256) public balances;// 余额map 
    mapping (address => mapping(address =>uint256)) public allowed;// 授权map
    
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
    
    constructor() public{
        totalPublic = 10e30;
        balances[msg.sender] = totalPublic;
    }
    
    // 根据地址获取获取代币金额 
    function balanceOf(address _owner) public view returns (uint256 balance) {
        return balances[_owner];
    }
    
    // 授权额度申请 
    function approve(address _spender, uint256 _value) public returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    // // 授权额度申请并转账
    // function approveAndtransfer(address _spender, uint256 _value) public returns (bool success) {
    //     allowed[msg.sender][_spender] = _value;
    //     emit Approval(msg.sender, _spender, _value);
    //     return transferFrom(msg.sender,_spender,_value);
    // }
    
    // 根据 _owner和 _spender查询 _owner给 _spender授权了多少额度 
    function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }
    
    // 转账 
    function transfer(address _to, uint256 _value) public returns (bool success) {
        require(balances[msg.sender] >= _value);
        require(balances[_to] + _value >= balances[_to]);
        balances[msg.sender] -= _value;
        balances[_to] += _value;
        emit Transfer(msg.sender, _to, _value);
        return true;
    }
    
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        uint256 allowanceValue = allowed[_from][msg.sender];
        require(balances[_from] >= _value && allowanceValue >= _value);
        require(balances[_to] + _value > balances[_to]);
        allowed[_from][msg.sender] -= _value;
        balances[_to] += _value;
        balances[_from] -= _value;
        emit Transfer(_from, _to, _value);
        return true;
    }
 
}