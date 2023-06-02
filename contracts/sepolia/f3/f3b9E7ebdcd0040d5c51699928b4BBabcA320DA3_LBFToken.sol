// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC20.sol";

contract LBFToken is IERC20 {
    string public _name; // 代币名称
    string public _symbol; // 代币符号
    uint8 private _decimals; // 代币精度
    uint256 public _totalSupply; // 发行总量
    mapping(address => uint256) private balances; // 额度
    mapping(address => mapping(address => uint256)) private allowBalance; // 授权额度
    address public owner; // 发布人

    constructor() {
        _name = "FirstCurrency";
        _symbol = "LBF";
        _decimals = 18;
        _totalSupply = 10000000;
        owner = msg.sender; // 发行者
        balances[owner] = _totalSupply; // 额度全部给发行者
    }

    // 返回名称
    function name() public view override returns (string memory) {
        return _name;
    }

    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    function decimals() public view override returns (uint8) {
        return _decimals;
    }

    function symbol() public view override returns (string memory) {
        return _symbol;
    }

    function balanceOf(
        address _address
    ) external view override returns (uint256 balance) {
        return balances[_address];
    }

    function transfer(
        address _to,
        uint256 _value
    ) external override returns (bool success) {
        require(_to != address(0), "Address is error");
        require(
            _value > 0,
            "Approved amount must be greater than or equal to zero"
        );
        require(balances[msg.sender] >= _value, "Not enough money");
        // 扣除发送者额度
        balances[msg.sender] -= _value;
        balances[_to] += _value;
        // 触发转换
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    //
    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    ) external override returns (bool success) {
        require(_to != address(0), "Invalid recipient address");
        require(_from != address(0), "Invalid recipient address");
        require(
            _value > 0,
            "Approved amount must be greater than or equal to zero"
        );
        // 发送者额度是否足够
        require(balances[_from] >= _value, "Not enough money");
        // 扣除发送者额度
        balances[_from] -= _value;
        balances[_to] += _value;
        // 触发转换
        emit Transfer(_from, _to, _value);
        return true;
    }

    // 授权额度
    function approve(
        address _spender,
        uint256 _value
    ) external override returns (bool success) {
        require(_spender != address(0), "Invalid recipient address");
        require(
            _value > 0,
            "Approved amount must be greater than or equal to zero"
        );
        allowBalance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(
        address _owner,
        address _spender
    ) external view override returns (uint256 remaining) {
        require(_spender != address(0), "Invalid recipient address");
        require(_owner != address(0), "Invalid recipient address");
        return allowBalance[_owner][_spender];
    }
}