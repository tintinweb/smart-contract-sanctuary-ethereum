// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

/**
 * @dev implementation of the ERC20 standard as defined in the EIP-20.
 *  https://eips.ethereum.org/EIPS/eip-20
 * + burn()
 * + mint()
 */
contract TokenERC20 {
    /**
     * **** PRIVATE STATE VARIABLES ****
     */
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;
    string private _name;
    string private _symbol;
    address payable public _contractOwner;
    uint256 private _decimals = 18;

    /**
     * **** EVENTS ****
     */

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when `value` tokens are destroyed from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    // event Burn(address indexed from, uint256 value);

    /**
     * @dev Emitted when `value` tokens are created and allocated to account
     *
     * Note that `value` may be zero.
     */
    // event Mint(address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

    /**
     * **** CONSRUCTOR ****
     */

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
        _contractOwner = payable(msg.sender);
        _totalSupply = 1000; // set initial supply from get go
        _balances[_contractOwner] = _totalSupply;
    }

    modifier onlyOwner() {
        require(msg.sender == _contractOwner, "only owner");
        _;
    }

    /**
     * **** PUBLIC VIEW FUNCIONS *****
     */

    /**
     * @dev Returns the name of the token.
     */
    function name() public view returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     */
    function decimals() public view returns (uint256) {
        return _decimals;
    }

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     *
     * @param _owner contracts address
     * @param _spender spenders addres
     *
     * @return an uint256 token value indicating the allowance granted
     */
    function allowance(address _owner, address _spender)
        public
        view
        returns (uint256)
    {
        return _allowances[_owner][_spender];
    }

    /**
     * **** PUBLIC STATE CHANGING FUNCIONS *****
     */

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * @param _to receipent address
     * @param _amount _amount to be transfered
     *
     * @return a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address _to, uint256 _amount) public returns (bool) {
        require(
            _balances[msg.sender] >= _amount,
            "sender's funds insufficient"
        );
        require(_to != address(0), "ERC20: zero address");

        _balances[msg.sender] -= _amount;
        _balances[_to] += _amount;

        emit Transfer(msg.sender, _to, _amount);
        return true;
    }

    /**
     * Set allowance for other address
     *
     * Allows `_spender` to spend no more than `_value` tokens on your behalf
     *
     * @param _spender The address authorized to spend
     * @param _value the max amount they can spend
     */
    function approve(address _spender, uint256 _value) public returns (bool) {
        require(_spender != address(0), "ERC20: zero address");
        _allowances[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function increaseAllowance(address spender, uint256 amount)
        public
        returns (bool)
    {
        _approve(
            msg.sender,
            spender,
            _allowances[msg.sender][spender] + amount
        );

        return true;
    }

    function decreaseAllowance(address spender, uint256 amount)
        public
        returns (bool)
    {
        uint256 currentAllowance = _allowances[msg.sender][spender];
        require(currentAllowance >= amount, "ERC20: amount below zero");

        _approve(msg.sender, spender, currentAllowance - amount);

        return true;
    }

    /**
     * Transfer tokens from other address
     *
     * Send `_value` tokens to `_to` on behalf of `_from`
     *
     * @param _from The address of the sender
     * @param _to The address of the recipient
     * @param _amount the amount to send
     *
     * @return bool if succeded
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address _from,
        address _to,
        uint256 _amount
    ) public returns (bool) {
        require(_balances[_from] > _amount, "sender's balance insufficient");
        require(
            _allowances[_from][msg.sender] >= _amount,
            "receipient's allowance insufficient"
        );

        _allowances[_from][msg.sender] -= _amount;
        _balances[_from] -= _amount;
        _balances[_to] += _amount;

        emit Transfer(_from, _to, _amount);
        return true;
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
    function mint(address account, uint256 amount)
        public
        onlyOwner
        returns (bool)
    {
        require(account != address(0), "ERC20: zero address");

        _totalSupply += amount;
        unchecked {
            // Overflow not possible: balance + amount is at most totalSupply + amount, which is checked above.
            _balances[account] += amount;
        }
        emit Transfer(address(0), account, amount);
        return true;
    }

    /**
     * Destroy tokens
     *
     * Remove `_value` tokens from the system irreversibly
     *
     * @param _account the account address which tokens will be deleted from
     * @param _amount the amount of money to burn
     */
    function burn(address _account, uint256 _amount)
        public
        onlyOwner
        returns (bool)
    {
        require(_balances[_account] >= _amount, "insufficient balance");

        _balances[_account] -= _amount;
        _totalSupply -= _amount;
        emit Transfer(_account, address(0), _amount);

        return true;
    }

    /**
     * **** INTERNAL STATE CHANGING FUNCIONS *****
     * @dev TBD implement approve and transfer internal to external funcs
     */

    /**
     * @dev Set allowance for other address
     *
     * @dev Allows `_spender` to spend no more than `_amount` tokens on your behalf
     *
     * @param _spender The address authorized to spend
     * @param _amount the max amount they can spend
     *
     * Emits a {Approval} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     */
    function _approve(
        address _owner,
        address _spender,
        uint256 _amount
    ) internal {
        require(_spender != address(0), "ERC20: zero address");

        _allowances[_owner][_spender] = _amount;
        emit Approval(_owner, _spender, _amount);
    }
}