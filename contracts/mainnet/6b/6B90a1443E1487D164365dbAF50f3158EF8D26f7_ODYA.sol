// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "./IERC20.sol";
import "./Ownable.sol";
import "./Whitelist.sol";



library SafeMath {

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
        return c;       
    }       

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}

/**
 * @title ERC20 Basic.
 *
 * @dev ERC20 ODYA token.
 */
contract ODYA is IERC20, Ownable, Whitelist {
    
    using SafeMath for uint256;

    string public name = "ODYA Coin";
    string public symbol = "ODYA";
    uint8 public constant decimals = 18;

    uint256 _initialSupply = 1000000000;
    uint256 private _totalSupply = _initialSupply * (10 ** uint256(decimals));
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
        require(from != address(0), "ODYA: transfer from the zero address");
        require(to != address(0), "ODYA: transfer to the zero address");

        uint256 currentBalance = balanceOf(from);
        uint256 lockedAmount = lockedAmountOf(from);
        uint256 availableAmount;

        require(currentBalance >= lockedAmount);
        unchecked { availableAmount = currentBalance.sub(lockedAmount); }
        require(availableAmount >= amount, "ODYA: transfer amount exceeds balance");

        unchecked {
            _balances[from] = _balances[from].sub(amount);
            _balances[to] = _balances[to].add(amount);
            require(_balances[to] >= amount, "ODYA: overflow of the to's balance");
        }

        emit Transfer(from, to, amount);
    }

    function _approve(address owner, address spender, uint256 amount) internal {
        require(owner != address(0), "ODYA: approve owner the zero address");
        require(spender != address(0), "ODYA: approve spender the zero address");

        _allowances[owner][spender] = amount;

        emit Approval(owner, spender, amount);
    }

    /**
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     */
    function _spendAllowance(address owner, address spender, uint256 amount) internal {
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= amount, "ODYA: insufficient allowance");

        if (currentAllowance != type(uint256).max) {
            unchecked {
                _approve(owner, spender, currentAllowance.sub(amount));
            }
        }
    }

    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        uint256 currentAllowance = allowance(msg.sender, spender);
        unchecked {
            uint256 newAllowance = currentAllowance.add(addedValue);
            require(newAllowance >= currentAllowance, "ODYA: overflow of the allowance");

            _approve(msg.sender, spender, newAllowance);
        }

        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        uint256 currentAllowance = allowance(msg.sender, spender);
        require(currentAllowance >= subtractedValue, "ODYA: decreased allowance below zero");

        unchecked {
            _approve(msg.sender, spender, currentAllowance.sub(subtractedValue));
        }

        return true;
    }

    function lock(address account, uint256 amount) public onlyWhitelisted returns (bool) {
        require(balanceOf(account) >= amount, "ODYA: Insufficient balance to lock");

        unchecked {
            _lockedAmount[account] = _lockedAmount[account].add(amount);
            require(_lockedAmount[account] >= amount, "ODYA: overflow of locked amount");

            emit Lock(msg.sender, account, amount);
        }

        return true;
    }

    function unlock(address account, uint256 amount) public onlyWhitelisted returns (bool) {
        require(_lockedAmount[account] >= amount, "ODYA: underflow of locked amount");

        unchecked {
            _lockedAmount[account] = _lockedAmount[account].sub(amount);

            emit Unlock(msg.sender, account, amount);
        }

        return true;
    }

    function transferWithLock(address to, uint256 amount) public onlyWhitelisted returns (bool) {
        _transfer(msg.sender, to, amount);
        lock(to, amount);

        return true;
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ODYA: burn from the zero address");

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ODYA: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance.sub(amount);
            // Overflow not possible: amount <= accountBalance <= totalSupply.
            _totalSupply = _totalSupply.sub(amount);
        }

        emit Transfer(account, address(0), amount);
    }

    function burn(uint256 amount) public returns (bool) {
        _burn(address(msg.sender), amount);
        
        return true;
    }
}