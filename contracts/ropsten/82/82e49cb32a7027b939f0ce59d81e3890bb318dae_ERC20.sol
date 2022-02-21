/**
 *Submitted for verification at Etherscan.io on 2022-02-21
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
    // For hold statuses:
    enum HoldStatusCode {
        Nonexistent,
        Ordered,
        Executed,
        ExecutedAndKeptOpen,
        ReleasedByNotary,
        ReleasedByPayee,
        ReleasedOnExpiration
    }
    // The structure of a hold
    struct Hold {
        address issuer;
        address origin;
        address target;
        address notary;
        uint256 expiration;
        uint256 value;
        HoldStatusCode status;
    }
    
    // individual holds
    mapping(bytes32 => Hold) private _holds;
    // the balance held at every address
    mapping(address => uint256) private _heldBalance;
    // the hold operates of each address
    mapping(address => mapping(address => bool)) private _holdOperators;
    // the total held amount
    uint256 internal _totalHeldBalance;
    
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
    event MetaData(string indexed functionName, bytes data);

    /**
     * @dev Emitted when contract minter is changed
     */
    event MinterChanged(address indexed oldMinter, address indexed newMinter);

    /**
     * @dev Emitted when `operator` is authorised by `tokenHolder`.
     */
    event AuthorizedOperator(address indexed operator, address indexed tokenHolder);

    /**
     * @dev Emitted when `operator` is revoked by `tokenHolder`.
     */
    event RevokedOperator(address indexed operator, address indexed tokenHolder);

    /**
     * @dev Emitted when the batched transactions failed for address `failedAddress` for function `functionName`.
     */
    event BatchFailure(string indexed functionName, address indexed failedAddress);

    /**
     * @dev Emitted when a new hold is created... batched transactions failed for address `failedAddress` for function `functionName`.
     */
    event HoldCreated(address indexed holdIssuer, string  operationId, address from, address to, address indexed notary, uint256 value, uint256 expiration);
    event HoldExecuted(address indexed holdIssuer, string operationId, address indexed notary, uint256 heldValue, uint256 transferredValue);
    event HoldReleased(address indexed holdIssuer, string operationId, HoldStatusCode status);
    event HoldRenewed(address indexed holdIssuer, string operationId, uint256 oldExpiration, uint256 newExpiration);
    event AuthorizedHoldOperator(address indexed operator, address indexed account);
    event RevokedHoldOperator(address indexed operator, address indexed account);
    event HoldExecutedAndKeptOpen(address indexed holdIssuer, string operationId, address indexed notary, uint256 heldValue,
    uint256 transferredValue);

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

    function balanceOnHold(address account) external view returns (uint256){
        return _heldBalance[account];
    }

    function netBalanceOf(address account) external view returns (uint256){
        return _balances[account] + _heldBalance[account];
    }

    function totalSupplyOnHold() external view returns (uint256) {
        return _totalHeldBalance;
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
        require(msg.sender == recipient, "ERC20: sender of transaction must be recipient");
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
     * If the operation failed, the address that failed will be returned;
     *
     * Emits a {Transfer} event for every transfer
     */
    function transferBatch(address sender, address[] calldata recipients, uint256[] calldata amounts) public virtual returns (bool, address) {
        require(isOperatorFor(msg.sender, sender), "ERC777: caller is not an operator for recipient");
        uint count;
        uint size = recipients.length;
        while (count < size){
            if (balanceOf(sender) < amounts[count]){
                emit BatchFailure("transfer", recipients[count]); //alerts the listener to the address that failed the batch
                return (false, recipients[count]);
            }
            _transfer(sender, recipients[count], amounts[count]);
            count++;
        }
        return (true, address(0x0));
    }

    /**
     * @dev Same logic as calling the transferFrom function multiple times.
     * where recipients[X] receives amounts[X] tokens
     *
     * Returns a boolean value indicating whether the operation succeeded.
     * If the operation failed, the addresses that could not perform the transfer will be returned;
     *
     * Emits a {Transfer} event for every transfer
     */
    function transferFromBatch(address recipient, address[] calldata senders, uint256[] calldata amounts) public virtual returns (bool, address[] memory) {
        require(isOperatorFor(msg.sender, recipient), "ERC777: caller is not an operator for recipient");
        uint count;
        uint size = senders.length;
        address[] memory failedAddresses;
        uint failedArrayCount = 0;
        bool success = true;
        while (count < size){
            if ((balanceOf(senders[count]) < allowance(senders[count],recipient))||(amounts[count] > allowance(senders[count],recipient))){
                failedAddresses[failedArrayCount] = senders[count];
                failedArrayCount++;
                success = false;
                emit BatchFailure("transferFrom", senders[count]);
            }
            _transferFrom(senders[count], recipient, amounts[count]);
            count++;
        }
        return (success,failedAddresses);
    }


    /**
     * @dev Creates a hold on behalf of the msg.sender in favor of the payee. 
     * It specifies a notary who is responsible to either execute or release the hold.
     * The function must revert if the operation ID has been used before.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {HoldCreated} event
     */
    function hold(
        string memory operationId,
        address to,
        address notary,
        uint256 value,
        uint256 timeToExpiration
    ) public returns (bool)
    {
        _checkHold(to);

        return _hold(
            operationId,
            msg.sender,
            msg.sender,
            to,
            notary,
            value,
            _computeExpiration(timeToExpiration)
        );
    }

    function holdFrom(
        string memory operationId,
        address from,
        address to,
        address notary,
        uint256 value,
        uint256 timeToExpiration
    ) public returns (bool)
    {
        _checkHoldFrom(to, from);

        return _hold(
            operationId,
            msg.sender,
            from,
            to,
            notary,
            value,
            _computeExpiration(timeToExpiration)
        );
    }

    function _releaseHold(Hold storage releasableHold, string memory operationId) internal returns (bool) {
        require(
            releasableHold.status == HoldStatusCode.Ordered || releasableHold.status == HoldStatusCode.ExecutedAndKeptOpen,
            "A hold can only be released in status Ordered or ExecutedAndKeptOpen"
        );
        require(
            _isExpired(releasableHold.expiration) ||
            (msg.sender == releasableHold.notary) ||
            (msg.sender == releasableHold.target),
            "A not expired hold can only be released by the notary or the payee"
        );

        if (_isExpired(releasableHold.expiration)) {
            releasableHold.status = HoldStatusCode.ReleasedOnExpiration;
        } else {
            if (releasableHold.notary == msg.sender) {
                releasableHold.status = HoldStatusCode.ReleasedByNotary;
            } else {
                releasableHold.status = HoldStatusCode.ReleasedByPayee;
            }
        }

        _heldBalance[releasableHold.origin] = _heldBalance[releasableHold.origin] - releasableHold.value;
        _totalHeldBalance = _totalHeldBalance - releasableHold.value;

        emit HoldReleased(releasableHold.issuer, operationId, releasableHold.status);

        return true;
    }

    function executeHold(string memory operationId, uint256 value) public returns (bool) {
        return _executeHold(
            operationId,
            value,
            false,
            true
        );
    }

    function renewHold(string memory operationId, uint256 timeToExpiration) public returns (bool) {
        Hold storage renewableHold = _holds[_toHash(operationId)];

        _checkRenewableHold(renewableHold);

        return _renewHold(renewableHold, operationId, _computeExpiration(timeToExpiration));
    }

    function authorizeHoldOperator(address operator) external returns (bool){
        require(msg.sender != operator, "ERC1996: authorizing self as operator");

        _holdOperators[msg.sender][operator] = true;

        emit AuthorizedHoldOperator(operator, msg.sender);

        return true;
    }

    function revokeHoldOperator(address operator) external returns (bool){
        require(msg.sender != operator, "ERC777: revoking self as operator");

        delete _holdOperators[msg.sender][operator];

        emit RevokedHoldOperator(operator, msg.sender);

        return true;
    }
    function isHoldOperatorFor(address operator, address from) public view returns (bool){
        return
            operator == from ||
            _holdOperators[from][operator];
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
    function _transfer(address sender, address recipient, uint256 amount) private {
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
    function _burn(address sender, uint256 amount, bytes calldata data) private {

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
    function _approve(address owner, address spender, uint256 amount) private {
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
    function _transferFrom(address sender, address recipient, uint256 amount) private {

        uint256 currentAllowance = _allowances[sender][recipient];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        _transfer(sender, recipient, amount);
        unchecked {
            _approve(sender, recipient, currentAllowance - amount);
        }

    }

    function _hold(
        string memory operationId,
        address issuer,
        address from,
        address to,
        address notary,
        uint256 value,
        uint256 expiration
    ) private returns (bool)
    {
        Hold storage newHold = _holds[_toHash(operationId)];

        require(!_isEmpty(operationId), "Operation ID must not be empty");
        require(value != 0, "Value must be greater than zero");
        require(newHold.value == 0, "This operationId already exists");
        require(notary != address(0), "Notary address must not be zero address");
        require(value <= balanceOf(from), "Amount of the hold can't be greater than the balance of the origin");

        newHold.issuer = issuer;
        newHold.origin = from;
        newHold.target = to;
        newHold.notary = notary;
        newHold.value = value;
        newHold.status = HoldStatusCode.Ordered;
        newHold.expiration = expiration;

        _heldBalance[from] = _heldBalance[from] + value;
        _totalHeldBalance = _totalHeldBalance + value;

        emit HoldCreated(
            issuer,
            operationId,
            from,
            to,
            notary,
            value,
            expiration
        );

        return true;
    }

    function _computeExpiration(uint256 _timeToExpiration) private view returns (uint256) {
        uint256 expiration = 0;

        if (_timeToExpiration != 0) {
            expiration = block.timestamp + _timeToExpiration;
        }

        return expiration;
    }

    function _checkHold(address to) private pure {
        require(to != address(0), "Payee address must not be zero address");
    }

    function _checkHoldFrom(address to, address from) private view {
        require(to != address(0), "Payee address must not be zero address");
        require(from != address(0), "Payer address must not be zero address");
        require(isHoldOperatorFor(msg.sender, from), "This operator is not authorized");
    }

    function _isExpired(uint256 expiration) internal view returns (bool) {
        /* solium-disable-next-line security/no-block-members */
        return expiration != 0 && (block.timestamp >= expiration);
    }

    function _executeHold(
        string memory operationId,
        uint256 value,
        bool keepOpenIfHoldHasBalance,
        bool doTransfer
    ) internal returns (bool)
    {
        Hold storage executableHold = _holds[_toHash(operationId)];

        require(
            executableHold.status == HoldStatusCode.Ordered || executableHold.status == HoldStatusCode.ExecutedAndKeptOpen,
            "A hold can only be executed in status Ordered or ExecutedAndKeptOpen"
        );
        require(value != 0, "Value must be greater than zero");
        require(executableHold.notary == msg.sender, "The hold can only be executed by the notary");
        require(!_isExpired(executableHold.expiration), "The hold has already expired");
        require(value <= executableHold.value, "The value should be equal or less than the held amount");

        if (keepOpenIfHoldHasBalance && ((executableHold.value - value) > 0)) {
            _setHoldToExecutedAndKeptOpen(
                executableHold,
                operationId,
                value,
                value
            );
        } else {
            _setHoldToExecuted(
                executableHold,
                operationId,
                value,
                executableHold.value
            );
        }

        if (doTransfer) {
            _transfer(executableHold.origin, executableHold.target, value);
        }

        return true;
    }

    function _setHoldToExecutedAndKeptOpen(
        Hold storage executableHold,
        string memory operationId,
        uint256 value,
        uint256 heldBalanceDecrease
    ) internal
    {
        _decreaseHeldBalance(executableHold, heldBalanceDecrease);

        executableHold.status = HoldStatusCode.ExecutedAndKeptOpen;
        executableHold.value = executableHold.value - value;

        emit HoldExecutedAndKeptOpen(
            executableHold.issuer,
            operationId,
            executableHold.notary,
            executableHold.value,
            value
        );
    }

    function _decreaseHeldBalance(Hold storage executableHold, uint256 value) private {
        _heldBalance[executableHold.origin] = _heldBalance[executableHold.origin] - value;
        _totalHeldBalance = _totalHeldBalance - value;
    }

    function _setHoldToExecuted(
        Hold storage executableHold,
        string memory operationId,
        uint256 value,
        uint256 heldBalanceDecrease
    ) internal
    {
        _decreaseHeldBalance(executableHold, heldBalanceDecrease);

        executableHold.status = HoldStatusCode.Executed;

        emit HoldExecuted(
            executableHold.issuer,
            operationId,
            executableHold.notary,
            executableHold.value,
            value
        );
    }

    function _checkRenewableHold(Hold storage renewableHold) private view {
        require(
            renewableHold.status == HoldStatusCode.Ordered || renewableHold.status == HoldStatusCode.ExecutedAndKeptOpen,
            "A hold can only be renewed in status Ordered or ExecutedAndKeptOpen"
        );
        require(!_isExpired(renewableHold.expiration), "An expired hold can not be renewed");
        require(
            renewableHold.origin == msg.sender || renewableHold.issuer == msg.sender,
            "The hold can only be renewed by the issuer or the payer"
        );
    }

    function _renewHold(Hold storage renewableHold, string memory operationId, uint256 expiration) internal returns (bool) {
        uint256 oldExpiration = renewableHold.expiration;
        renewableHold.expiration = expiration;

        emit HoldRenewed(
            renewableHold.issuer,
            operationId,
            oldExpiration,
            expiration
        );

        return true;
    }

    function _toHash(string memory _s) private pure returns (bytes32) {
        return keccak256(abi.encode(_s));
    }

    function _isEmpty(string memory _s) private pure returns (bool) {
        return bytes(_s).length == 0;
    }

}