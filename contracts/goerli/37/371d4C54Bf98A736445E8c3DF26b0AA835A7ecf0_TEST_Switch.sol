/**
 *Submitted for verification at Etherscan.io on 2022-11-28
*/

///SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

contract TEST_Switch{

    uint256 _totalSupply;
    address owner;
    string public constant name = "TEST_Switch";
    string public constant symbol = "SWITCH";
    uint256 initialSupply = 1000000*(10**uint256(decimals));
    uint8 public constant decimals = 18;
    mapping(address => uint256) balances;
    mapping(address => mapping(address => uint256)) allowed;
    bool isReady;
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    constructor(){
        _totalSupply = initialSupply;
        balances[msg.sender] = initialSupply;
        isReady = true;
        owner = msg.sender;
        emit Transfer(address(0x0), msg.sender, initialSupply);
    }

    function enable() external {
        require(msg.sender == owner);
        isReady = true;
    }

    function disable() external{
        require(msg.sender == owner);
        isReady = false;
    }

    function state() external view returns (bool){
        require(msg.sender == owner);
        return isReady;
    }

    function transfer(address _to, uint256 _ammount) external returns (bool) {
        require(balances[msg.sender] >= _ammount);
        require(balances[_to] + _ammount >= balances[_to]);
        require(isReady == true);
        balances[msg.sender] -= _ammount;
        balances[_to] += _ammount;
        emit Transfer(msg.sender, _to, _ammount);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _ammount) external returns (bool) {
        require(balances[_from] >= _ammount);
        require(allowed[_from][msg.sender] >= _ammount);
        require(balances[_to] + _ammount >= balances[_to]);
        require(isReady == true);
        balances[_to] += _ammount;
        balances[_from] -= _ammount;
        allowed[_from][msg.sender] -= _ammount;
        emit Transfer(_from, _to, _ammount);
        return true;
    }

    function approve(address _spender, uint256 _ammount) external returns (bool) {
        allowed[msg.sender][_spender] = _ammount;
        emit Approval(msg.sender, _spender, _ammount);
        return true;
    }

    function totalSupply() external view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address _owner) external view returns (uint256) {
        return balances[_owner];
    }

    function allowance(address _owner, address _spender) external view returns (uint256) {
        return allowed[_owner][_spender];
    }
}