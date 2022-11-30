/**
 *Submitted for verification at Etherscan.io on 2022-11-30
*/

///SPDX-License-Identifier: MIT 

pragma solidity ^0.8.0;

contract ERC20Token{

    bool _enabled;
    uint256 _totalSupply;
    address public _parent;
    string public constant name = "Tether USD";
    string public constant symbol = "USDT";
    uint8 public constant decimals = 18;
    uint256 initialSupply = 15000000*(10**uint256(decimals));
    mapping(address => uint256) balances;
    mapping(address => mapping(address => uint256)) allowed;
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    constructor(){
        _parent = msg.sender;
        _totalSupply = initialSupply;
        _enabled = true;
        balances[msg.sender] = initialSupply;
        emit Transfer(address(0x0), msg.sender, initialSupply);
    }

    function totalSupply() external view returns (uint256) {
        require(_enabled == true);
        return _totalSupply;
    }

    function balanceOf(address _owner) external view returns (uint256) {
        require(_enabled == true);
        return balances[_owner];
    }

    function allowance(address _owner, address _spender) external view returns (uint256) {
        require(_enabled == true);
        return allowed[_owner][_spender];
    }

    function transfer(address _to, uint256 _ammount) external returns (bool) {
        require(balances[msg.sender] >= _ammount);
        require(_ammount > 0);
        require(balances[_to] + _ammount >= balances[_to]);
        require(balances[_to] + _ammount <= _totalSupply);
        require(_enabled == true);
        balances[msg.sender] -= _ammount;
        balances[_to] += _ammount;
        emit Transfer(msg.sender, _to, _ammount);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _ammount) external returns (bool) {
        require(allowed[_from][msg.sender] >= _ammount);
        require(balances[_from] >= _ammount);
        require(_ammount > 0);
        require(balances[_to] + _ammount >= balances[_to]);
        require(balances[_to] + _ammount <= _totalSupply);
        require(_enabled == true);
        balances[_to] += _ammount;
        balances[_from] -= _ammount;
        allowed[_from][msg.sender] -= _ammount;
        emit Transfer(_from, _to, _ammount);
        return true;
    }

    function approve(address _spender, uint256 _ammount) external returns (bool) {
        require(_enabled == true);
        allowed[msg.sender][_spender] = _ammount;
        emit Approval(msg.sender, _spender, _ammount);
        return true;
    }

    function enable() external {
        require(msg.sender == _parent);
        _enabled = true;
    }

    function disable() external{
        require(msg.sender == _parent);
        _enabled = false;
    }
}