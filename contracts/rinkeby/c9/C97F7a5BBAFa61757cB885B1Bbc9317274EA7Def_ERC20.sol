//SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.12;

import "./IERC20.sol";
import "./AccessControl.sol";

contract ERC20 is IERC20, AccessControl {

    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;

    string private _name;                   
    uint8 private _decimals;                
    string private _symbol; 
    uint256 private _totalSupply;
    uint256 private _initialAmount;

    constructor(
        string memory name_, 
        string memory symbol_, 
        uint8 decimals_,
        uint256 initialAmount_) {
        _name = name_;
        _symbol = symbol_;
        _decimals = decimals_;
        _totalSupply = initialAmount_;
        _balances[msg.sender] += initialAmount_;
    }

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public view returns (uint8) {
        return _decimals;
    }

    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address _owner) public view override returns (uint256) {
        return _balances[_owner];
    }

    function transfer(address _to, uint _value) public override returns (bool) {
        require(_balances[msg.sender] >= _value);
        _balances[msg.sender] -= _value;
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public override returns (bool) {
        require(_balances[_from] >= _value && _allowances[_from][msg.sender] >= _value);
        _balances[_from] -= _value;
        _balances[_to] += _value;
        emit Transfer(_from, _to, _value);
        return true;
    }

    function approve (address _spender, uint256 _value) public override returns (bool) {
        _allowances[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) public view override returns (uint256) {
        return _allowances[_owner][_spender];
    }

    function mint(address _owner, uint256 _value) internal onlyRole(ADMIN) {
        _balances[_owner] += _value;
        _totalSupply += _value;
        emit Mint(_owner, _value);
    }

    function burn(address _owner, uint256 _value) internal onlyRole(ADMIN) {
        _balances[_owner] -= _value;
        _totalSupply -= _value;
        emit Burn(_owner, _value);
    }

    event Mint(address indexed _owner, uint256 _value);
    
    event Burn(address indexed _owner, uint256 _value); 
}