// SPDX-License-Identifier: MIT
pragma solidity >= 0.8.4;

import "./IERC20.sol";

contract RayToken is IERC20 {
    mapping (address => uint256) _balances;
    mapping (address => mapping (address => uint256)) _allowences;
    string private _name;
    string private _symbol;
    uint256 private _totalSupply;
    uint8 private _decimals;

    constructor () {
        _name = "RayToken";
        _symbol = "RAY";
        _decimals = 18;
        _totalSupply = 10_000_000 * 10 ** _decimals;
        _balances[msg.sender] = _totalSupply;
        emit Transfer(address(0), msg.sender, _totalSupply);
    }

    function transfer(address _to, uint256 _value) external override returns(bool success) {
        require(_balances[msg.sender] >= _value, "You exceed your balance!");
        _balances[msg.sender] = _balances[msg.sender] - _value;
        _balances[_to] = _balances[_to] + _value;
        emit Transfer(msg.sender, _to, _value);

        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) external override returns(bool success) {
        require(_allowences[_from][msg.sender] >= _value, "You don't have enough allowance!");
        require(_balances[_from] >= _value, "You exceed the balance of owner!");
        _allowences[_from][msg.sender] = _allowences[_from][msg.sender] - _value;
        _balances[_from] = _balances[_from] - _value;
        _balances[_to] = _balances[_to] + _value;
        emit Transfer(_from, _to, _value);

        return true;
    }

    function approve(address _spender, uint256 _value) external override returns(bool success) {
        _allowences[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);

        return true;
    }
    
    function name() external view override returns(string memory) {
        return _name;
    }

    function symbol() external view override returns(string memory) {
        return _symbol;
    }

    function decimals() external view override returns(uint8) {
        return _decimals;
    }

    function totalSupply() external view override returns(uint256) {
        return _totalSupply;
    }

    function balanceOf(address _owner) external override view returns(uint256 balance) {
        return _balances[_owner];
    }

    function allowance(address _owner, address _spender) external override view returns(uint256 remaining) {
        return _allowences[_owner][_spender];
    }
}