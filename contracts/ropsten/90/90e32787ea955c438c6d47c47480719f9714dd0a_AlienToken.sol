// SPDX-License-Identifier: GPL-3.0
// Contract practiced by 108820003, NTUT.
pragma solidity ^0.8.13;

import "./IERC20.sol";

contract AlienToken is IERC20 {
    address private _owner;

    // The balance of each account.
    mapping(address => uint256) private _balances;

    // The account's unique allownence object information, 
    // used to record the number of tokens that can be operated by the only authorized account of the main account.
    mapping(address => mapping(address => uint256)) private _allowances;

    // The "current" number of Tokens in the world.
    uint256 private _totalSupply;

    // The name of this token.
    string private _name;

    // The simbol of this token.
    string private _symbol;

    // The decimals of this token.
    uint8 private _decimals;

    // dev Sets the values for {name} and {symbol}.
    constructor(string memory name_, string memory symbol_, uint8 decimals_) {
        _name = name_;
        _symbol = symbol_;
        _decimals = decimals_;
        _owner = _msgSender();
    }

    // modifier to check if caller is owner
    modifier isOwner() {
        // If the first argument of 'require' evaluates to 'false', execution terminates and all
        // changes to the state and to Ether balances are reverted.
        // This used to consume all gas in old EVM versions, but not anymore.
        // It is often a good idea to use 'require' to check if functions are called correctly.
        // As a second argument, you can also provide an explanation about what went wrong.
        require(msg.sender == _owner, "Caller is not owner");
        _;
    }

    receive() external payable { 
        address account = _msgSender();
        uint256 coin = _msgValue();

        _mint(account, coin);
    }

    // Returns the name of the token.
    function name() public view override returns (string memory) {
        return _name;
    }

    // Returns the symbol of the token, usually a shorter version of the name.
    function symbol() public view override returns (string memory) {
        return _symbol;
    }

    // Returns the number of decimals used to get its user representation.
    // For example, if `decimals` equals `2`, a balance of `505` tokens should
    // be displayed to a user as `5.05` (`505 / 10 ** 2`).
    function decimals() public view override returns (uint8) {
        return _decimals;
    }

    // Returns the amount of tokens in existence.
    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    // Returns the amount of tokens owned by `account`.
    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    // Moves `amount` tokens from the caller's account to `to`.
    // Returns a boolean value indicating whether the operation succeeded.
    function transfer(address to, uint256 amount) public override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    // Returns the remaining number of tokens that `spender` will be
    // allowed to spend on behalf of `owner` through {transferFrom}. This is
    // zero by default.
    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    // Sets `amount` as the allowance of `spender` over the caller's tokens, should only be called when setting an initial allowance, or when resetting it to zero.
    // Returns a boolean value indicating whether the operation succeeded.
    function approve(address spender, uint256 amount) public override returns (bool) {
        address owner = _msgSender();

        require (
            (amount == 0) || (allowance(owner, spender) == 0),
            "ERC20: approve from non-zero to non-zero allowance"
        );

        _approve(owner, spender, amount);
        return true;
    }

    // Moves `amount` tokens from `from` to `to` using the
    // allowance mechanism. `amount` is then deducted from the caller's allowance.
    // Returns a boolean value indicating whether the operation succeeded.
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    // Atomically increases the allowance granted to `spender` by the caller.
    // This is an alternative to {approve} that can be used as a mitigation for
    // problems described in {IERC20-approve}.
    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }

    // Atomically decreases the allowance granted to `spender` by the caller.
    // This is an alternative to {approve} that can be used as a mitigation for
    // problems described in {IERC20-approve}.
    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    // Get the address of the message sender.
    function _msgSender() internal view returns (address) {
        return msg.sender;
    }

    // Get the amount of ether on the method call, use `wei` as its unit.
    function _msgValue() internal view returns (uint256) {
        return msg.value;
    }

    // Creates `amount` tokens and assigns them to `account`, increasing the total supply.
    function _mint(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: mint to the zero address");

        require(_totalSupply + amount >= _totalSupply, "ERC20: overflows happened during _mint");
        _totalSupply += amount;

        require(_balances[account] + amount >= _balances[account], "ERC20: overflows happened during _mint");
        _balances[account] += amount;

        emit Transfer(address(0), account, amount);
    }

    // Destroys `amount` tokens from `account`, reducing the total supply.
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");

        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);
    }

    // Moves `amount` of tokens from `sender` to `recipient`.
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        uint256 fromBalance = _balances[from];

        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        require(_balances[to] + amount >= _balances[to], "ERC20: overflows happened during _transfer");

        unchecked {
            _balances[from] = fromBalance - amount;
        }

        _balances[to] += amount;

        emit Transfer(from, to, amount);
    }

    // Sets `amount` as the allowance of `spender` over the `owner` s tokens.
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    // Updates `owner` s allowance for `spender` based on spent `amount`.
    // Does not update the allowance amount in case of infinite allowance.
    // Revert if not enough allowance is available.
    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }
}