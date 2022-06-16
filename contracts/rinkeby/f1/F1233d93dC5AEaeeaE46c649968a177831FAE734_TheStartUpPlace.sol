// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "./interfaces/IERC20.sol";


contract TheStartUpPlace is IERC20 {
    string private _name;
    string private _symbol;
    uint256 private _totalSupply;

    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;

    constructor() {
        _name = "The StartUp Place";
        _symbol = "TSUP";

        // mint 1_000_000_000 TSUP to the owner
        _mint(msg.sender, 1_000_000 ether);
    }

    function name() external view returns(string memory) {
        return _name;
    }

    function symbol() external view returns(string memory) {
        return _symbol;
    }

    function decimals() external pure returns(uint8) {
        return 18;
    }

    function totalSupply() external view returns(uint256) {
        return _totalSupply;
    }

    function balanceOf(address _account) external view returns(uint256) {
        return _balances[_account];
    }

    function allowance(address _sender, address _recipient) external view returns(uint256) {
        return _allowances[_sender][_recipient];
    }

    function _approve(address _sender, address _recipient, uint256 _amount) internal {
        require(_sender != address(0), "TheStartUpPlace: token approval from ZERO_ADDRESS");
        require(_recipient != address(0), "TheStartUpPlace: token approval to ZERO_ADDRESS");

        _allowances[_sender][_recipient] = _amount;
        emit Approval(_sender, _recipient, _amount);
    }

    function approve(address _recipient, uint256 _amount) external returns(bool) {
        _approve(msg.sender, _recipient, _amount);
        return true;
    }

    function _transfer(address _sender, address _recipient, uint256 _amount) internal {
        require(_sender != address(0), "TheStartUpPlace: token transfer from ZERO_ADDRESS");
        require(_recipient != address(0), "TheStartUpPlace: token transfer to ZERO_ADDRESS");
        require(_balances[_sender] >= _amount, "TheStartUpPlace: insufficient balance");

        _balances[_sender] -= _amount;
        _balances[_recipient] += _amount;
        emit Transfer(_sender, _recipient, _amount);
    }

    function _mint(address _recipient, uint256 _amount) internal {
        require(_recipient != address(0), "TheStartUpPlace: token mint to ZERO_ADDRESS");

        emit Transfer(address(0), _recipient, _amount);
        _totalSupply += _amount;
        _balances[_recipient] += _amount;
    }


    function transfer(address _recipient, uint256 _amount) external returns(bool) {
        _transfer(msg.sender, _recipient, _amount);
        return true;
    }

    function transferFrom(address _sender, address _recipient, uint256 _amount) external returns(bool) {
        // decrease allowances
        uint256 _recipientAllowance = _allowances[_sender][msg.sender];
        require(_recipientAllowance >= _amount, "TheStartUpPlace: amount exceeds allowance");
        _approve(_sender, msg.sender, _recipientAllowance - _amount);

        _transfer(_sender, _recipient, _amount);
        return true;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transfer(address to, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}