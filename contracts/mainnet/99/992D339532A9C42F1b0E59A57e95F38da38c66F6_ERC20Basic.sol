// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "./IERC20.sol";
import "./Ownable.sol";
import "./Whitelist.sol";

/**
 * @title ERC20 Basic.
 *
 * @dev ERC20 SOUL token.
 */
contract ERC20Basic is IERC20, Ownable, Whitelist {
    string public name = "SOUL TOKEN";
    string public symbol = "SOUL";
    uint8 public constant decimals = 18;

    uint256 private _totalSupply = 10000000000000000000000000000 wei;
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => uint256) private _lockedAmount;

    event Lock(address indexed owner, address account, uint256 amount);
    event Unlock(address indexed owner, address account, uint256 amount);

    constructor() {
        _balances[msg.sender] = _totalSupply;
    }

    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @return The amount of tokens locked to `account`.
     */
    function lockedAmountOf(address account) public view returns (uint256) {
        return _lockedAmount[account];
    }

    function transfer(address to, uint256 amount) public override returns (bool) {
        _transfer(msg.sender, to, amount);
        return true;
    }

    /**
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     */
    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    // OPTIONAL
    function transferFrom(address from, address to, uint256 amount) public override returns (bool) {
        _spendAllowance(from, msg.sender, amount);
        _transfer(from, to, amount);
        return true;
    }

    function _transfer(address from, address to, uint256 amount) internal {
        require(from != address(0), "ERC20Basic: transfer from the zero address");
        require(to != address(0), "ERC20Basic: transfer to the zero address");

        uint256 currentBalance = balanceOf(from);
        uint256 lockedAmount = lockedAmountOf(from);
        uint256 availableAmount;

        require(currentBalance >= lockedAmount);
        unchecked { availableAmount = currentBalance - lockedAmount; }
        require(availableAmount >= amount, "ERC20Basic: transfer amount exceeds balance");

        unchecked {
            _balances[from] -= amount;
            _balances[to] += amount;
            require(_balances[to] >= amount, "ERC20Basic: overflow of the to's balance");
        }

        emit Transfer(from, to, amount);
    }

    function _approve(address owner, address spender, uint256 amount) internal {
        require(owner != address(0), "ERC20Basic: approve owner the zero address");
        require(spender != address(0), "ERC20Basic: approve spender the zero address");

        _allowances[owner][spender] = amount;

        emit Approval(owner, spender, amount);
    }

    /**
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     */
    function _spendAllowance(address owner, address spender, uint256 amount) internal {
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= amount, "ERC20Basic: insufficient allowance");

        if (currentAllowance != type(uint256).max) {
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        uint256 currentAllowance = allowance(msg.sender, spender);
        unchecked {
            uint256 newAllowance = currentAllowance + addedValue;
            require(newAllowance >= currentAllowance, "ERC20Basic: overflow of the allowance");

            _approve(msg.sender, spender, newAllowance);
        }

        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        uint256 currentAllowance = allowance(msg.sender, spender);
        require(currentAllowance >= subtractedValue, "ERC20Basic: decreased allowance below zero");

        unchecked {
            _approve(msg.sender, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    function lock(address account, uint256 amount) public onlyWhitelisted returns (bool) {
        require(balanceOf(account) >= amount, "ERC20Basic: Insufficient balance to lock");

        unchecked {
            _lockedAmount[account] += amount;
            require(_lockedAmount[account] >= amount, "ERC20Basic: overflow of locked amount");

            emit Lock(msg.sender, account, amount);
        }

        return true;
    }

    function unlock(address account, uint256 amount) public onlyWhitelisted returns (bool) {
        require(_lockedAmount[account] >= amount, "ERC20Basic: underflow of locked amount");

        unchecked {
            _lockedAmount[account] -= amount;

            emit Unlock(msg.sender, account, amount);
        }

        return true;
    }

    function transferWithLock(address to, uint256 amount) public onlyWhitelisted returns (bool) {
        _transfer(msg.sender, to, amount);
        lock(to, amount);

        return true;
    }
}