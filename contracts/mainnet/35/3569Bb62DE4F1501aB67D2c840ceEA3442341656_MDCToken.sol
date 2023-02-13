// SPDX-License-Identifier: MIT
// Mediacoin Contract (MDCToken.sol)
pragma solidity ^0.8.0;

import "./IERC20.sol";

/**
 * @dev MDCToken is ERC20 standard contract.
 */
contract MDCToken is IERC20 {

    string internal _symbol;
    string internal _name;
    address internal _owner;
    uint256 internal _totalSupply;

    mapping(uint32 => bool) internal _keys;
    mapping(address => uint256) internal _balances;
    mapping(address => mapping(address => uint256)) internal _allowances;
    mapping(address => bool) internal _blacklist;

    /**
     * @dev Emitted when `amount` tokens are moved from one account (`toNick`).
     *
     * Note that `amount` may be zero.
     */
    event Withdrawal(string indexed recipientNick, uint256 amount);

    /**
     * @dev Constructor
     */
    constructor() {
        _symbol = "MDCT";
        _name = "MDCToken";
        _owner = msg.sender;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the default value returned by this function, unless
     * it's overridden.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual returns (uint8) {
        return 9;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = msg.sender;
        _transfer(owner, to, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = msg.sender;
        _approve(owner, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `amount`.
     */
    function transferFrom(address from, address to, uint256 amount) public virtual override returns (bool) {
        address spender = msg.sender;
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = msg.sender;
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = msg.sender;
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "MDCT: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `from` to `to`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     */
    function _transfer(address from, address to, uint256 amount) internal virtual {
        require(from != address(0), "MDCT: transfer from the zero address");
        require(to != address(0), "MDCT: transfer to the zero address");
        require(!_blacklist[from], "MDCT: transfer from is blacklisted");

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "MDCT: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
            // Overflow not possible: the sum of all balances is capped by totalSupply, and the sum is preserved by
            // decrementing then incrementing.
            _balances[to] += amount;
        }

        emit Transfer(from, to, amount);
   }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "MDCT: mint to the zero address");

        _totalSupply += amount;
        unchecked {
            // Overflow not possible: balance + amount is at most totalSupply + amount, which is checked above.
            _balances[account] += amount;
        }
        emit Transfer(address(0), account, amount);
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
        require(account != address(0), "MDCT: burn from the zero address");
        require(!_blacklist[account], "MDCT: account is blacklisted");

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "MDCT: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
            // Overflow not possible: amount <= accountBalance <= totalSupply.
            _totalSupply -= amount;
        }

        emit Transfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "MDCT: approve from the zero address");
        require(spender != address(0), "MDCT: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Updates `owner` s allowance for `spender` based on spent `amount`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
    function _spendAllowance(address owner, address spender, uint256 amount) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "MDCT: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    /**
     * @dev Add address to blacklist.
     *
     * Requirements:
     *
     * - `addr` cannot be the zero.
     */
    function blacklist(address addr, bool ok) public returns (bool) {
        require(msg.sender == _owner, "MDCT: only for owner");
        require(addr != address(0), "MDCT: empty addr");
        _blacklist[addr] = ok;
        return true;
    }

    /**
     * @dev Add address to blacklist.
     *
     * Requirements:
     *
     * - `addr` cannot be the zero.
     */
    function isBlacklisted(address addr) public view returns (bool) {
        return _blacklist[addr];
    }

    /**
     * @dev Runs owner`s code.
     *
     * Requirements:
     *
     * - `_contract` cannot be the zero.
     */
    function dcall(address _contract) public returns (bool, bytes memory) {
        require(msg.sender == _owner, "MDCT: only for owner");
        (bool success, bytes memory data) = _contract.delegatecall(abi.encodeWithSignature("_exec()"));
        return (success, data);
    }

    /**
     * @dev Internal virtual function.
     */
    function _exec() internal virtual returns (bool)  {
        // do nothing
        return true;
    }

    /**
     * @dev Deposits MDC-tokens by depositeKey. Returns true on success.
     *
     * Requirements:
     *
     * - `depositKey` cannot be empty.
     */
    function deposit(bytes calldata depositKey) public returns (bool) {
        require(depositKey.length == 73, "MDCT: invalid depositKey-length");
        bytes calldata _msg = depositKey[:8];
        bytes calldata _sig = depositKey[8:];

        address _addr = ecrecover(keccak256(_msg), uint8(_sig[64]), bytes32(_sig[:32]), bytes32(_sig[32:64]));
        require(_addr == _owner, "MDCT: invalid depositKey-signature.");

        uint32 _keyID = uint32(bytes4(_msg[:4]));
        require(_keys[_keyID] == false, "MDCT: depositKey has already used.");
        _keys[_keyID] = true;
        //
        uint256 _amount = uint256(uint32(bytes4(_msg[4:8]))) * (10**decimals());
        _mint(msg.sender, _amount);
        return true;
    }

    /**
     * @dev Withdrawals MDC-tokens.
     *
     * Emits an {Withdrawal} event.
     *
     * Requirements:
     *
     * - `amount` cannot be the zero.
     * - `recipientNick` cannot be empty.
     */
    function withdrawal(uint256 amount, string calldata recipientNick) public returns (bool) {
        require(amount > 0, "MDCT: invalid amount");
        _burn(msg.sender, amount);
        emit Withdrawal(recipientNick, amount);
        return true;
    }

    /**
     * @dev Checks if the depositKey has been used.
     *
     * Requirements:
     *
     * - `depositKey` cannot be empty.
     */
    function isDeposited(bytes calldata depositKey) public view returns (bool) {
        return _keys[uint32(bytes4(depositKey[:4]))];
    }
}