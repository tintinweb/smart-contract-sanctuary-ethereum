/**
 *Submitted for verification at Etherscan.io on 2022-04-14
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
    // For each account, a mapping of its account operators.
    mapping(address => mapping(address => bool)) private _accountOperators;
    // For hold statuses:
    enum HoldStatusCode {
        Nonexistent,
        Ordered,
        Executed,
        ReleasedByHoldOperator,
        ReleasedOnExpiration
    }
    // The structure of a hold
    struct Hold {
        address creator;
        address payer;
        address payee;
        address operator;
        uint256 expiration;
        uint256 amount;
        HoldStatusCode status;
    }
    
    // individual holds
    mapping(bytes32 => Hold) private _holds;
    // the balance held at every address
    mapping(address => uint256) private _heldBalance;
    // the hold operators of each address
    mapping(address => mapping(address => bool)) private _holdOperators;
    // the total held amount for all accounts
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
     * @dev Emitted when `accountOperator` is authorised by `tokenHolder`.
     */
    event AuthorizedOperator(address indexed accountOperator, address indexed tokenHolder);

    /**
     * @dev Emitted when `accountOperator` is revoked by `tokenHolder`.
     */
    event RevokedOperator(address indexed accountOperator, address indexed tokenHolder);

    /**
     * @dev Emitted when the batched transactions failed for address `failedAddress` for function `functionName`.
     */
    event BatchFailure(string indexed functionName, address indexed failedAddress);

    /**
     * @dev Emitted when a new hold is created by `holdCreator`. This hold has been given the id `operationId` and is from `payerId` to `payeeId`. 
     * The hold is currently under the control of `holdOperator`. The hold contains `amount` of tokens and can be executed or renewed until `expiration`. 
     */
    event HoldCreated(address holdCreator, string indexed operationId, address indexed payerId, address payeeId, address indexed holdOperator, uint256 amount, uint256 expiration);
    /**
     * @dev Emitted when the hold with id `operationId' has been executed by it's assigned holdOperator.
     */
    event HoldExecuted(string indexed operationId);
    /**
     * @dev Emitted when the hold with id `operationId' has been released (without payment) by it's assigned holdOperator.
     * It has been released for the reason given in `status`.
     */
    event HoldReleased(string indexed operationId, HoldStatusCode status);
    /**
     * @dev Emitted when the hold with id `operationId' has been renewed (expiration extended).
     * It has been released for the reason given in `status`.
     */
    event HoldRenewed(string indexed operationId, uint256 newExpiration);
    /**
     * @dev Emitted when an authorised operator `holdOperator` has been assigned to be able to manage holds for `account`.
     */
    event AuthorizedHoldOperator(address indexed holdOperator, address indexed account);
    /**
     * @dev Emitted when an authorised operator `holdOperator` has been assigned to be able to manage holds for `account`.
     */
    event RevokedHoldOperator(address indexed holdOperator, address indexed account);

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
     * @dev Functions using this modifier restrict the caller to only be the minter address (or the account operator of the minter address)
     */
   modifier onlyMinter {
        require(isOperatorFor(msg.sender, minter()), "Caller is not an account operator for Minter");
      _;
   }

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
     * Ether and Wei.
     *
     * NOTE: This information is only used for display purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {balanceOf} and {transfer}.
     */
    function decimals() public view returns (uint8) {
        return _decimals;
    }

     /**
     * @dev Returns the amount of tokens in existence.
     *
     * This value changes when {mint} and {burn} are called.
     */
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev Returns the address with the minter role of this token contract, 
     * i.e. what address can mint new tokens.
     * if a multi-sig account operator is required, this address should 
     * point to a smart contract implementing this multi-sig.
     */
    function minter() public view returns (address) {
        return _minter;
    }

    /**
     * @dev Returns the amount of tokens owned by `accountId`.
     *
     * This value changes when {transfer} and {transferFrom} are called.
     */
    function balanceOf(address accountId) public view returns (uint256) {
        return _balances[accountId];
    }

    /**
     * @dev Returns the remaining number of tokens that `payeeId` will be
     * allowed to spend on behalf of `payerId` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address payerId, address payeeId) public view returns (uint256) {
        return _allowances[payerId][payeeId];
    }

    /**
     * @dev Returns the amount of tokens in `accountId` that are currently on hold.
     *
     * This value changes when {hold}, {holdFrom}, {releaseHold} and {executehold}  are called.
     */
    function balanceOnHold(address accountId) public view returns (uint256) {
        return _heldBalance[accountId];
    }

   /**
     * @dev Returns the combined amount of tokens in `accountId` (i.e. the account's held and non-held balances).
     *
     * This value changes when {transfer}, {transferFrom}, {mint}, {burn}, {hold}, {holdFrom}, {releaseHold} and {executehold}  are called.
     */
    function netBalanceOf(address accountId) public view returns (uint256) {
        return _balances[accountId] + _heldBalance[accountId];
    }

   /**
     * @dev Returns the combined amount of tokens currently held for all accounts.
     *
     * This value changes when {hold}, {holdFrom}, {releaseHold} and {executehold}  are called.
     */
    function totalSupplyOnHold() public view returns (uint256) {
        return _totalHeldBalance;
    }

    /**
     * @dev Returns true if `accountOperatorId` is an account operator of `accountId`.
     * Account operators can send and burn tokens for an authorised account. All
     * accounts are their own account operator.
     */
    function isOperatorFor(address accountOperatorId, address accountId) public view returns (bool) {
        return
            accountOperatorId == accountId ||
            _accountOperators[accountId][accountOperatorId];
    }

    /**
     * @dev Moves `amount` tokens from the caller's account to `payeeId`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     *
     * Requirements
     *
     * -  the caller must have at least `amount` tokens.
     * - `payeeId` cannot be the zero address.
     */
    function transfer(address payeeId, uint256 amount) public returns (bool) {
        _transfer(msg.sender, payeeId, amount);
        return true;
    }

    /**
     * @dev Moves `amount` tokens from `payerId` to `payeeId`. The caller must
     * be an account operator of `payerId`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     *
     * Requirements
     *
     * - `payerId` cannot be the zero address.
     * - `payerId` must have at least `amount` tokens.
     * -  the caller must be an account operator for `payerId`.
     * - `payeeId` cannot be the zero address.
     */
    function operatorTransfer(
        address payerId,
        address payeeId,
        uint256 amount
    ) public returns (bool) {
        require(isOperatorFor(msg.sender, payerId), "Caller is not an account operator for payerId");
        _transfer(payerId, payeeId, amount);
        return true;
    }

    /**
     * @dev Sets `amount` as the allowance of `payeeId` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits an {Approval} event.
     *
     * Requirements
     *
     * - the caller must have at least `amount` tokens.
     * - `payeeId` cannot be the zero address.
     */
    function approve(address payeeId, uint256 amount) public returns (bool) {
        _approve(msg.sender, payeeId, amount);
        return true;
    }

    /**
     * @dev Approves `amount` tokens from `payerId` to `payeeId`. The caller must
     * be an account operator of `payerId`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Approval} event.
     *
     * Requirements
     *
     * - `payerId` cannot be the zero address.
     * - `payerId` must have at least `amount` tokens.
     * - the caller must be an account operator for `payerId`.
     * - `payeeId` cannot be the zero address.
     */
    function operatorApprove(
        address payerId,
        address payeeId,
        uint256 amount
    ) public returns (bool) {
        require(isOperatorFor(msg.sender, payerId), "Caller is not an account operator for payerId");
        _approve(payerId, payeeId, amount);
        return true;
    }

    /**
     * @dev Moves `amount` tokens from `payerId` to `payeeId` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     *
     * Requirements
     *
     * - `payerId` cannot be the zero address.
     * - the caller must have at least `amount` tokens approved tokens from `payeeId`.
     * - `payeeId` cannot be the zero address.
     */
    function transferFrom(address payerId, address payeeId, uint256 amount) public returns (bool) {
        require(msg.sender == payeeId, "Sender of transaction must be payeeId");
        _transferFrom(payerId, payeeId, amount);
        return true;
    }

    /**
     * @dev Moves `amount` tokens from `payerId` to `payeeId` using the
     * allowance mechanism. `amount` is then deducted from the 'payeeId'
     * allowance.
     *
     * Emits a {Transfer} event.
     *
     * Requirements
     *
     * - `payerId` cannot be the zero address.
     * - `payeeId` must have at least `amount` approved tokens from `payeeId`.
     * -  the caller must be an account operator for `payeeId`.
     * - `payeeId` cannot be the zero address.
     */
    function operatorTransferFrom(
        address payerId,
        address payeeId,
        uint256 amount
    ) public {
        require(isOperatorFor(msg.sender, payeeId), "Caller is not an account operator for payeeId");
        _transferFrom(payerId, payeeId, amount);
    }


    /** @dev Creates `amount` tokens and assigns them to `accountId`, increasing
     * the total supply. Metadata can be assigned to this mint via the 'message' 
     * parameter if required.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     * Emits a {MetaData} event.
     *
     * Requirements:
     *
     * - `accountId` cannot be the zero address.
     * - `msg.sender` must be the contract's minter address.
     */
    function mint(address accountId, uint256 amount, bytes calldata message) public onlyMinter() returns (bool) {
        require(accountId != address(0), "Mint to the zero address");

        _totalSupply += amount;
        _balances[accountId] += amount;
        
        emit Transfer(address(0), accountId, amount);
        emit MetaData("mint", message);

        return true;

    }

    /**
     * @dev Destroys `amount` tokens from the sender's address, reducing the
     * total supply. Metadata can be assigned to this burn via the 'message' 
     * parameter if required.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     * Emits a {MetaData} event.
     *
     * Requirements:
     *
     * - the caller's account must have at least `amount` tokens.
     */
    function burn(uint256 amount, bytes calldata message) public returns (bool) {

        _burn(msg.sender, amount, message);
        return true;

    }

    /**
     * @dev Destroys `amount` tokens from `accountId`, reducing the total supply.
     * The caller must be an account operator of `accountId`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     * Emits a {MetaData} event.
     *
     * Requirements
     *
     * - `accountId` cannot be the zero address.
     * - `accountId` must have at least `amount` tokens.
     * - the caller must be an account operator for `accountId`.
     */
    function operatorBurn(address accountId, uint256 amount, bytes calldata message) public returns (bool) {
        require(isOperatorFor(msg.sender, accountId), "Caller is not an account operator for accountId");
        _burn(accountId, amount, message);
        return true;
    }

    /**
     * @dev Changes the account that can mint tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Requirements:
     *
     * - caller must have the minter role.
     */
    function changeMinter(address newMinter) public onlyMinter() returns (bool) {
        address oldMinter = _minter;
        _minter = newMinter;
        emit MinterChanged(oldMinter, newMinter);
        return true;
    }


    /**
     * @dev Make `accountOperatorId` an account operator of `accountId`.
     *
     * Emits an {AuthorizedOperator} event.
     *
     * Requirements:
     *
     * -  caller must be a current account operator of `accountId`.
     * - `accountOperatorId` must not equal the caller.
     */
    function authorizeOperator(address accountId, address accountOperatorId) public {
        require(isOperatorFor(msg.sender, accountId), "Caller is not an operator for accountId");
        require(msg.sender != accountOperatorId, "Authorizing self as operator");

        _accountOperators[accountId][accountOperatorId] = true;

        emit AuthorizedOperator(accountOperatorId, accountId);
    }

    /**
     * @dev Revoke `accountOperatorId`'s account operator status for `accountId`.
     *
     * Emits a {RevokedOperator} event.
     *
     * Requirements:
     *
     * -  caller must be an account operator of `accountId`.
     * - `accountOperatorId` must not equal the caller.
     */
    function revokeOperator(address accountId, address accountOperatorId) public {
        require(isOperatorFor(msg.sender, accountId), "Caller is not an account operator for accountId");

        delete _accountOperators[accountId][accountOperatorId];

        emit RevokedOperator(accountOperatorId, accountId);
    }


    /**
     * @dev Same logic as calling the transfer function multiple times.
     * where payeeIds[x] receives amounts[x] tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     * If the operation failed, the payeeId causing the first failure will be returned;
     *
     * Emits a {Transfer} event for every transfer.
     *
     * Requirements:
     *
     * - `payerId` cannot be the zero address.
     * - `payerId` must have a balance of at least the total of the `amounts` array.
     * -  the caller must be `payerId` or an account operator for `payerId`.
     * -  Each `payeeIds[x]` cannot be the zero address.
     */
    function transferBatch(address payerId, address[] calldata payeeIds, uint256[] calldata amounts) public returns (bool, address) {
        require(isOperatorFor(msg.sender, payerId), "Caller is not an account operator for payerId");
        uint count;
        uint size = payeeIds.length;
        while (count < size){
            if (balanceOf(payerId) < amounts[count]){
                emit BatchFailure("transfer", payeeIds[count]); //alerts the listener to the address that failed the batch
                return (false, payeeIds[count]);
            }
            _transfer(payerId, payeeIds[count], amounts[count]);
            count++;
        }
        return (true, address(0x0));
    }

    /**
     * @dev Same logic as calling the transferFrom function multiple times.
     * where payeeId attempts to debit amounts[X] tokens from payerIds[X].
     * If a particular debit did is not possible (as the allowance is not high enough
     * for this particular payerIds[X]), the batch continues. 
     *
     * Returns firstly boolean value indicating whether the batch transfer succeeded for every given payerId (true)
     * or if the batch transfer failed for some payerIds (false). If false, then the payerIds that could not
     * perform the transfer are also returned;
     *
     * Emits a {Transfer} event for every transfer
     *
     * Requirements
     *
     * -  Each `payerIds[x]` cannot be the zero address.
     * - `payeeId` must have at least `amount[x]` approved tokens from each `payerIds[x]`.
     * -  the caller must be `payeeId` or an account operator for `payeeId`.
     * -  `payeeId` cannot be the zero address.
     */
    function transferFromBatch(address[] calldata payerIds, address payeeId, uint256[] calldata amounts) public returns (bool, address[] memory) {
        require(isOperatorFor(msg.sender, payeeId), "Caller is not an account operator for payeeId");
        uint count;
        uint size = payerIds.length;
        address[] memory failedAddresses;
        uint failedArrayCount = 0;
        bool success = true;
        while (count < size){
            if ((balanceOf(payerIds[count]) < allowance(payerIds[count],payeeId))||(amounts[count] > allowance(payerIds[count],payeeId))){
                failedAddresses[failedArrayCount] = payerIds[count];
                failedArrayCount++;
                success = false;
                emit BatchFailure("transferFrom", payerIds[count]);
            } else {
                //only perform the transfer from if it will succeed
                _transferFrom(payerIds[count], payeeId, amounts[count]);
            }
            count++;
        }
        return (success,failedAddresses);
    }


    /**
     * @dev Creates a hold for `amount` of tokens on behalf of the `payerId` in favor of the `payeeId`. 
     * It specifies a `holdOperator` who is responsible to either execute or release the hold.
     * This hold can be executed by `holdOperator` until `secondsToExpiration` have passed from the current block timestamp.
     * Afterwhich, this hold can be renewed or released.
     * Held tokens do not leave an account until the correspond hold is executed or released.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {HoldCreated} event
     *
     * Requirements
     *
     * - `operationId` cannot have been used before and must not be empty.
     * - `payeeId` cannot be the zero address.
     * - `holdOperator` cannot be the zero address.
     * - `payeeId` must have at least `amount` tokens (where `amount` is greater than zero).
     * -  caller must be `payerId` or an authorised account operator for `payerId`.
     * - `holdOperator` must be an authorised hold operator of `payerId`.
     */
    function hold(
        string memory operationId,
        address payerId,
        address payeeId,
        address holdOperator,
        uint256 amount,
        uint256 secondsToExpiration
    ) public returns (bool)
    {
        require(isOperatorFor(msg.sender, payerId), "Caller is not an account operator for payerId");
        return _hold(
            operationId,
            msg.sender,
            payerId,
            payeeId,
            holdOperator,
            amount,
            _computeExpiration(secondsToExpiration)
        );
    }

    /**
     * @dev Creates a hold for `amount` of tokens on behalf of the 'payerId' in favor of the `payeeId`. 
     * It specifies a `holdOperator` who is responsible to either execute or release the hold.
     * This hold can be executed by `holdOperator` until `secondsToExpiration` have passed from the current block timestamp.
     * Afterwhich, this hold can be renewed or released.
     * Held tokens do not leave an account until the correspond hold is executed or released.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {HoldCreated} event
     *
     * Requirements
     *
     * - `operationId` cannot have been used before and must not be empty.
     * - `payeeId` cannot be the zero address.
     * - `holdOperator` cannot be the zero address.
     * - `payeeId` must have at least `amount` tokens (where `amount` is greater than zero).
     * -  caller must be `payeeId` or an authorised account operator for `payerId`.
     * - `holdOperator` must be an authorised hold operator of `payerId`.
     */
    function holdFrom(
        string memory operationId,
        address payerId,
        address payeeId,
        address holdOperator,
        uint256 amount,
        uint256 secondsToExpiration
    ) public returns (bool)
    {
        require(isOperatorFor(msg.sender, payeeId), "Caller is not an account operator for payeeId");
        return _hold(
            operationId,
            msg.sender,
            payerId,
            payeeId,
            holdOperator,
            amount,
            _computeExpiration(secondsToExpiration)
        );
    }

    /**
     * @dev Releases the hold corresponding to `operationId`. Releasing allows the hold payer to once again spend these tokens (that we previously frozen).
     * This hold can be only be released by `holdOperator` until `secondsToExpiration` have passed from the current block timestamp.
     * After which this hold can be released by any account.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {HoldReleased} event
     *
     * Requirements
     *
     * - `operationId` must correspond to a hold.
     * - if the hold has not expired, only the holdOperator (or the holdOperator's account operator) can release the hold
     */
    function releaseHold(string memory operationId) public returns (bool) {

        Hold storage releasableHold = _holds[_toHash(operationId)];

        require(
            releasableHold.status == HoldStatusCode.Ordered,
            "A hold can only be released in status Ordered"
        );
        require(
            _isExpired(releasableHold.expiration) ||
            (isOperatorFor(msg.sender, releasableHold.operator)),
            "A not expired hold can only be released by the hold operator"
        );

        if (_isExpired(releasableHold.expiration)) {
            releasableHold.status = HoldStatusCode.ReleasedOnExpiration;
        } else {
            releasableHold.status = HoldStatusCode.ReleasedByHoldOperator;
        }

        _decreaseHeldBalance(releasableHold);

        emit HoldReleased(operationId, releasableHold.status);

        return true;
    }

    /**
     * @dev executes the hold corresponding to `operationId`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {HoldExecuted} event
     *
     * Requirements
     *
     * - the hold must be in the ordered state.
     * - the caller must be the hold's hold operator.
     * - the hold must not have expired.
     */
    function executeHold(string memory operationId) public returns (bool) {
        return _executeHold(
            operationId,
            true
        );
    }

    /**
     * @dev renews the hold corresponding to `operationId`. This holds new expiration time is set to 
     * the current blocktime + `additionalTimeToExpiry`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {HoldExecuted} event
     *
     * Requirements
     *
     * - the hold must be in the ordered state.
     * - the hold cannot be expired
     * - the caller must be the hold's creator or payer (or their corresponding account operators)
     */
    function renewHold(string memory operationId, uint256 additionalTimeToExpiry) public returns (bool) {
        Hold storage renewableHold = _holds[_toHash(operationId)];

        require(
            renewableHold.status == HoldStatusCode.Ordered,
            "A hold can only be renewed in status Ordered"
        );
        require(!_isExpired(renewableHold.expiration), "An expired hold can not be renewed");
        require(
            isOperatorFor(msg.sender, renewableHold.payer) || isOperatorFor(msg.sender, renewableHold.creator),
            "The hold can only be renewed by the issuer or the payer"
        );

        return _renewHold(renewableHold, operationId, _computeExpiration(additionalTimeToExpiry));
    }


    /**
     * @dev authorises `holdOperator' to receive holds from `account`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {AuthorizedHoldOperator} event
     *
     * Requirements
     *
     * - both `account` and `holdOperator` must be different
     * - the caller must be `account` or an authorised account operator of `account`.
     */
    function authorizeHoldOperator(address account, address holdOperator) public returns (bool){
        require(isOperatorFor(msg.sender, account), "Caller is not an account operator for account");
        require(account != holdOperator, "Authorizing self as hold operator");

        _holdOperators[account][holdOperator] = true;

        emit AuthorizedHoldOperator(holdOperator, account);

        return true;
    }

    /**
     * @dev revokes `holdOperator' from receiving holds from `account`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {AuthorizedHoldOperator} event
     *
     * Requirements
     *
     * - both `account` and `holdOperator` must be different
     * - the caller must be `account` or an authorised hold operator of `account`.
     */
    function revokeHoldOperator(address account, address holdOperator) public returns (bool){
        require(isOperatorFor(msg.sender, account), "Caller is not an account operator for account");
        require(account != holdOperator, "Revoking self as hold operator");

        delete _holdOperators[account][holdOperator];

        emit RevokedHoldOperator(holdOperator, account);

        return true;
    }

     /**
     * @dev checks to see if `holdOperator` is an authorised hold operator of `account`
     */   
    function isHoldOperatorFor(address holdOperator, address account) public view returns (bool){
        return
            holdOperator == account ||
            _holdOperators[account][holdOperator];
    }

    /**
     * @dev Moves `amount` of tokens from `payerId` to `payeeId`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `payerId` cannot be the zero address.
     * - `payeeId` cannot be the zero address.
     * - `payerId` must have a balance of at least `amount`.
     */
    function _transfer(address payerId, address payeeId, uint256 amount) private {
        require(payerId != address(0), "Transfer from the zero address");
        require(payeeId != address(0), "Transfer to the zero address");
        require(payeeId != address(this), "Transfer to the contract address");

        uint256 senderBalance = _balances[payerId];
        require(senderBalance >= amount, "Transfer amount exceeds balance");
        unchecked {
            _balances[payerId] = senderBalance - amount;
        }
        _balances[payeeId] += amount;

        emit Transfer(payerId, payeeId, amount);

    }

    /**
     * @dev Burns (deletes) `amount` of tokens from `payerId`, with optional metadata `data`.
     *
     * Emits a {Transfer} event.
     * Emits a {MetaData} event.
     *
     * Requirements:
     *
     * - `payerId` cannot be the zero address.
     * - `payerId` must have a balance of at least `amount`.
     */
    function _burn(address payerId, uint256 amount, bytes calldata data) private {

        require(payerId != address(0), "Burn from the zero address");

        uint256 accountBalance = _balances[payerId];
        require(accountBalance >= amount, "Burn amount exceeds balance");
        unchecked {
            _balances[payerId] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(payerId, address(0), amount);
        emit MetaData("burn", data);

    }

    /**
     * @dev Sets `amount` as the allowance of `payeeId` over the `payerId` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `payerId` cannot be the zero address.
     * - `payeeId` cannot be the zero address.
     */
    function _approve(address payerId, address payeeId, uint256 amount) private {
        require(payerId != address(0), "Approve from the zero address");
        require(payeeId != address(0), "Approve to the zero address");

        if (_allowances[payerId][payeeId] > 0){
            require(amount == 0, "Approve call vulnerable to race condition");            
        }

        _allowances[payerId][payeeId] = amount;
        emit Approval(payerId, payeeId, amount);
    }


    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Emits a {Transfer} event.
     */
    function _transferFrom(address payerId, address payeeId, uint256 amount) private {

        uint256 currentAllowance = _allowances[payerId][payeeId];
        require(currentAllowance >= amount, "Transfer amount exceeds allowance");
        _transfer(payerId, payeeId, amount);
        unchecked {
            _approve(payerId, payeeId, currentAllowance - amount);
        }

    }


   /**
     * @dev `creatorId` creates a hold for `amount` of tokens on behalf of the 'payerId' in favor of the `payeeId`. 
     * It specifies a `holdOperator` who is responsible to either execute or release the hold.
     * This hold can be executed by `holdOperator` until `secondsToExpiration` have passed from the current block timestamp.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {HoldCreated} event
     *
     * Requirements
     *
     * - `operationId` must not be empty.
     * - `amount` must be greater than zero.
     * -  a hold corresponding to `operationId` cannot already exist.
     * - `payerId` must have at least `amount` of tokens.
     * - `payerId` must not be the empty address.
     * - `payeeId` must not be the empty address.
     * - `holdOperator` must be an authorised hold operator of `payerId`
     */
    function _hold(
        string memory operationId,
        address creatorId,
        address payerId,
        address payeeId,
        address holdOperator,
        uint256 amount,
        uint256 secondsToExpiration
    ) private returns (bool)
    {

        Hold storage newHold = _holds[_toHash(operationId)];

        require(!_isEmpty(operationId), "Operation ID must not be empty");
        require(amount != 0, "Amount must be greater than zero");
        require(newHold.amount == 0, "This operationId already exists");
        require(holdOperator != address(0), "holdOperator address must not be zero address");
        require(amount <= balanceOf(payerId), "Amount of the hold can't be greater than the balance of the payer");
        require(payerId != address(0), "Payer address must not be zero address");
        require(payeeId != address(0), "Payee address must not be zero address");
        require(isHoldOperatorFor(holdOperator, payerId), "This holdOperator is not authorized for payerId");
        

        newHold.creator = creatorId;
        newHold.payer = payerId;
        newHold.payee = payeeId;
        newHold.operator = holdOperator;
        newHold.amount = amount;
        newHold.status = HoldStatusCode.Ordered;
        newHold.expiration = secondsToExpiration;

        _heldBalance[payerId] = _heldBalance[payerId] + amount;
        _totalHeldBalance = _totalHeldBalance + amount;

        emit HoldCreated(
            creatorId,
            operationId,
            payerId,
            payeeId,
            holdOperator,
            amount,
            secondsToExpiration
        );

        return true;
    }


    /**
     * @dev executes the hold corresponding to `operationId`.
     * Via `doTransfer` the holdOperator says whether to send the held funds to the payee (true) or to return the funds to the payer (false)
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {HoldCreated} event
     *
     * Requirements
     *
     * - the hold must be in the ordered state.
     * - the caller must be the hold's holdOperator.
     * - the hold must not have expired.
     */
    function _executeHold(
        string memory operationId,
        bool doTransfer
    ) internal returns (bool)
    {
        Hold storage executableHold = _holds[_toHash(operationId)];

        require(executableHold.status == HoldStatusCode.Ordered,"A hold can only be executed in status Ordered");
        require(executableHold.operator == msg.sender, "The hold can only be executed by the holdOperator");
        require(!_isExpired(executableHold.expiration), "The hold has already expired");

        _setHoldToExecuted(executableHold,operationId);

        if (doTransfer) {
            _transfer(executableHold.payer, executableHold.payee, executableHold.amount);
        }

        return true;
    }


    /**
     * @dev decreases the total held balance in this contract and the held balance at the executableHold.payer address.
     * this function is triggered when a hold is executed or released.
     */
    function _decreaseHeldBalance(Hold storage thisHold) private {
        _heldBalance[thisHold.payer] = _heldBalance[thisHold.payer] - thisHold.amount;
        _totalHeldBalance = _totalHeldBalance - thisHold.amount;
    }

    /**
     * @dev sets the hold corresponding to `operationId` to the executed status.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {HoldExecuted} event
     *
     */
    function _setHoldToExecuted(
        Hold storage executableHold,
        string memory operationId
    ) internal
    {
        _decreaseHeldBalance(executableHold);

        executableHold.status = HoldStatusCode.Executed;

        emit HoldExecuted(operationId);
    }


    /**
     * @dev increases the time to expirey of the hold corresponding to `operationId` for `expiration` more seconds.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {HoldRenewed} event
     *
     */
    function _renewHold(Hold storage renewableHold, string memory operationId, uint256 expiration) internal returns (bool) {
        renewableHold.expiration = expiration;

        emit HoldRenewed(operationId,expiration);

        return true;
    }

    /**
     * @dev hashes a given string
     */
    function _toHash(string memory _s) private pure returns (bytes32) {
        return keccak256(abi.encode(_s));
    }

    /**
     * @dev checks to see if a given string is empty
     */
    function _isEmpty(string memory _s) private pure returns (bool) {
        return bytes(_s).length == 0;
    }

    /**
     * @dev adds secondsToExpiration to the current block timestamp to find the hold expiration time
     */
    function _computeExpiration(uint256 secondsToExpiration) private view returns (uint256) {
        uint256 expiration = 0;
        if (secondsToExpiration != 0) {
            expiration = block.timestamp + secondsToExpiration;
        }
        return expiration;
    }

   /**
     * @dev checks if the hold is expired
     */
    function _isExpired(uint256 expiration) internal view returns (bool) {
        return expiration != 0 && (block.timestamp >= expiration);
    }

}