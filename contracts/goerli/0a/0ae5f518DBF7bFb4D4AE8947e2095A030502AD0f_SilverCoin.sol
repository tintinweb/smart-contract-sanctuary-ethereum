// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "./IERC20.sol";

contract SilverCoin is IERC20 {
    uint8 public constant decimals = 8;
    string public constant symbol = "SLV";

    uint256 public totalSupply;
    address private admin;

    mapping(address => uint256) private balances;
    mapping(address => mapping(address => uint256)) private allowances;

    constructor(uint256 _totalSupply) {
        admin = msg.sender;
        balances[admin] = _totalSupply;
        totalSupply = _totalSupply;

        emit Transfer(address(0), admin, totalSupply);
    }

    function balanceOf(address _owner) external view returns (uint256) {
        return balances[_owner];
    }

    function transfer(address _to, uint256 _value) external returns (bool) {
        require(_value <= balances[msg.sender]);
        require(_to != address(0));

        balances[msg.sender] -= _value;
        balances[_to] += _value;

        emit Transfer(msg.sender, _to, _value);

        return true;
    }

    function approve(address _spender, uint256 _value) external returns (bool) {
        allowances[msg.sender][_spender] = _value;

        emit Approval(msg.sender, _spender, _value);

        return true;
    }

    function allowance(address _owner, address _spender) external view returns (uint256) {
        return allowances[_owner][_spender];
    }

    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    ) external returns (bool) {
        require(_value <= balances[_from]);
        require(_value <= allowances[_from][msg.sender]);
        require(_to != address(0));

        balances[_from] -= _value;
        balances[_to] += _value;
        allowances[_from][msg.sender] -= _value;

        emit Transfer(_from, _to, _value);

        return true;
    }
}