/**
 *Submitted for verification at Etherscan.io on 2022-02-16
*/

pragma solidity 0.8.7;


contract ERC20 {
    
    //stores current balances
    mapping(address => uint256) private _balances;
    //stores current approvals
    mapping(address => mapping(address => uint256)) private _allowances;
    //current total supply of token
    uint256 private _totalSupply;
    //current token metadata
    string private _name;
    string private _symbol;
    uint8 private _decimals;
    //the address that can mint new tokens
    address private _minter;
    // For each account, a mapping of its operators.
    mapping(address => mapping(address => bool)) private _operators;
    
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Emitted when tokens are minted or burned.
     */
    event MetaData(string functionName, bytes data);

    /**
     * @dev Emitted when contract minter is changed
     */
    event MinterChanged(address oldMinter, address newMinter);

    /**
     * @dev Emitted when `operator` is authorised by `tokenHolder`.
     */
    event AuthorizedOperator(address indexed operator, address indexed tokenHolder);

    /**
     * @dev Emitted when `operator` is revoked by `tokenHolder`.
     */
    event RevokedOperator(address indexed operator, address indexed tokenHolder);

    /**
     * @dev Sets the values for {_name}, {_symbol}, {_decimals}, {_totalSupply}.
     * Additionally, all of the supply is initially given to the address corresponding to {giveSupplyTo_}
     */
    constructor(string memory name_, string memory symbol_, uint8 decimals_, uint256 supply_, address giveSupplyTo_, address minter_) {
        _name = name_;
        _symbol = symbol_;
        _decimals = decimals_;
        _totalSupply = supply_;
        _balances[giveSupplyTo_] = supply_;
        _minter = minter_;
        
    }

    /**
     * @dev Functions using this modifier restrict the caller to only be the minter address
     */
   modifier onlyMinter {
       require(msg.sender == minter(), "ERC20: msg.sender must have the minter role");
      _;
   }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei.
     *
     * NOTE: This information is only used for display purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {balanceOf} and {transfer}.
     */
    function decimals() public view virtual returns (uint8) {
        return _decimals;
    }

     /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() public view virtual returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev Returns the address with the minter role of this token contract, 
     * i.e. what address can mint new tokens.
     * if a multi-sig operator is required, this address should 
     * point to a smart contract implementing this multi-sig.
     */
    function minter() public view virtual returns (address) {
        return _minter;
    }

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) public view virtual returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) public view virtual returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) public virtual returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) public virtual returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) public virtual returns (bool) {

        _transferFrom(sender, recipient, amount);
        return true;
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply. Metadata can be assigned to this mint via the 'data' 
     * parameter if required.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     * Emits a {MetaData} event.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `msg.sender` must be the contract's operator address.
     */
    function mint(address account, uint256 amount, bytes calldata data) external virtual onlyMinter() returns (bool) {
        require(account != address(0), "ERC20: mint to the zero address");
        require(msg.sender == minter(), "ERC20: Minter must be the contract operator");

        _totalSupply += amount;
        _balances[account] += amount;
        
        emit Transfer(address(0), account, amount);
        emit MetaData("mint", data);

        return true;

    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply. Metadata can be assigned to this burn via the 'data' 
     * parameter if required.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     * Emits a {MetaData} event.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function burn(address account, uint256 amount, bytes calldata data) external virtual onlyMinter() returns (bool) {

        _burn(account, amount, data);
        return true;

    }

    /**
     * @dev Changes the address that can mint tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Requirements:
     *
     * - `msg.sender` must have the minter role.
     */
    function changeMinter(address newMinter) public virtual onlyMinter() returns (bool) {
        address oldMinter = _minter;
        _minter = newMinter;
        emit MinterChanged(oldMinter, newMinter);
        return true;
    }

    /**
     * @dev Returns true if an account is an operator of `tokenHolder`.
     * Operators can send and burn tokens on behalf of their owners. All
     * accounts are their own operator.
     */
    function isOperatorFor(address operator, address tokenHolder) public view virtual returns (bool) {
        return
            operator == tokenHolder ||
            _operators[tokenHolder][operator];
    }

    /**
     * @dev Make an account an operator of the caller.
     *
     * Emits an {AuthorizedOperator} event.
     */
    function authorizeOperator(address operator) public virtual {
        require(msg.sender != operator, "ERC777: authorizing self as operator");

        _operators[msg.sender][operator] = true;

        emit AuthorizedOperator(operator, msg.sender);
    }

    /**
     * @dev Revoke an account's operator status for the caller.
     *
     * Emits a {RevokedOperator} event.
     */
    function revokeOperator(address operator) public virtual {
        require(msg.sender != operator, "ERC777: revoking self as operator");

        delete _operators[msg.sender][operator];

        emit RevokedOperator(operator, msg.sender);
    }


    /**
     * @dev Moves `amount` tokens from `sender` to `recipient`. The caller must
     * be an operator of `sender`.
     *
     * Emits a {Transfer} event.
     *
     * Requirements
     *
     * - `sender` cannot be the zero address.
     * - `sender` must have at least `amount` tokens.
     * - the caller must be an operator for `sender`.
     * - `recipient` cannot be the zero address.
     */
    function operatorTransfer(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual {
        require(isOperatorFor(msg.sender, sender), "ERC777: caller is not an operator for holder");
        _transfer(sender, recipient, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the total supply.
     * The caller must be an operator of `account`.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     * Emits a {MetaData} event.
     *
     * Requirements
     *
     * - `sender` cannot be the zero address.
     * - `sender` must have at least `amount` tokens.
     * - the caller must be an operator for `sender`.
     */
    function operatorBurn(
        address sender,
        uint256 amount,
        bytes calldata data
    ) public virtual {
        require(isOperatorFor(msg.sender, sender), "ERC777: caller is not an operator for holder");
        emit MetaData("burn", data);
        _burn(sender, amount, data);
    }

    /**
     * @dev Approves `amount` tokens from `sender` to `recipient`. The caller must
     * be an operator of `sender`.
     *
     * Emits a {Approval} event.
     *
     * Requirements
     *
     * - `sender` cannot be the zero address.
     * - `sender` must have at least `amount` tokens.
     * - the caller must be an operator for `sender`.
     * - `spender` cannot be the zero address.
     */
    function operatorApprove(
        address sender,
        address spender,
        uint256 amount
    ) public virtual {
        require(isOperatorFor(msg.sender, sender), "ERC777: caller is not an operator for holder");
        _approve(sender, spender, amount);
    }

    /**
     * @dev Approves `amount` tokens from `sender` to `recipient`. The caller must
     * be an operator of `sender`.
     *
     * Emits a {Approval} event.
     *
     * Requirements
     *
     * - `sender` cannot be the zero address.
     * - `sender` must have at least `amount` tokens.
     * - the caller must be an operator for `sender`.
     * - `spender` cannot be the zero address.
     */
    function operatorTransferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual {
        require(isOperatorFor(msg.sender, recipient), "ERC777: caller is not an operator for recipient");
        _transferFrom(sender, recipient, amount);
    }


    /**
     * @dev Same logic as calling the transfer function multiple times.
     * where recipients[X] receives amounts[X] tokens
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event for every transfer
     */
    function transferBatch(address sender, address[] calldata recipients, uint256[] calldata amounts) public virtual returns (bool) {
        require(isOperatorFor(msg.sender, sender), "ERC777: caller is not an operator for recipient");
        uint count;
        uint size = recipients.length;
        while (count < size){
            _transfer(sender, recipients[count], amounts[count]);
            count++;
        }
        return true;
    }

    /**
     * @dev Same logic as calling the transferFrom function multiple times.
     * where recipients[X] receives amounts[X] tokens
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event for every transfer
     */
    function transferFromBatch(address recipient, address[] calldata senders, uint256[] calldata amounts) public virtual returns (bool) {
        require(isOperatorFor(msg.sender, recipient), "ERC777: caller is not an operator for recipient");
        uint count;
        uint size = senders.length;
        while (count < size){
            _transferFrom(senders[count], recipient, amounts[count]);
            count++;
        }
        return true;
    }


    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        require(recipient != address(this), "ERC20: transfer to the contract address");

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);

    }

    /**
     * @dev Burns (deletes) `amount` of tokens from `sender`, with optional metadata `data`.
     *
     * Emits a {Transfer} event.
     * Emits a {MetaData} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _burn(address sender, uint256 amount, bytes calldata data) internal virtual {

        require(sender != address(0), "ERC20: burn from the zero address");

        uint256 accountBalance = _balances[sender];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[sender] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(sender, address(0), amount);
        emit MetaData("burn", data);

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
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        if (_allowances[owner][spender] > 0){
            require(amount == 0, "ERC20: approve call vulnerable to race condition");            
        }

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }


    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Emits a {Transfer} event.
     */
    function _transferFrom(address sender, address recipient, uint256 amount) internal virtual {

        uint256 currentAllowance = _allowances[sender][msg.sender];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        _transfer(sender, recipient, amount);
        unchecked {
            _approve(sender, msg.sender, currentAllowance - amount);
        }

    }

}