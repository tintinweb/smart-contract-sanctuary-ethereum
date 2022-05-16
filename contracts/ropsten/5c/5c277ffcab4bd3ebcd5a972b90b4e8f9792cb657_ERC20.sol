/**
 *Submitted for verification at Etherscan.io on 2022-05-16
*/

pragma solidity 0.8.7;


contract ERC20 {
    
    //stores current balances
    mapping(address => uint256) private _balances;
    //stores current approvals
    mapping(address => mapping(address => uint256)) private _allowances;
    //current total supply of token
    uint256 private _totalSupply;
    //current token metadata:
    string private _name;
    string private _symbol;
    uint8 private _decimals;
    //the owner address of this contract, i.e. who can mint more tokens
    address private _owner;
    // For each account, a mapping of its account operators.
    mapping(address => mapping(address => bool)) private _accountOperators;
        
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
     * @dev Emitted when contract owner is changed
     */
    event OwnerChanged(address indexed oldOwner, address indexed newOwner);

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
     * @dev Sets the values for {_name}, {_symbol}, {_decimals}, {_totalSupply}.
     * Additionally, all of the supply is initially given to the address corresponding to {giveSupplyTo_}
     */
    constructor(string memory name_, string memory symbol_, uint8 decimals_, uint256 supply_, address giveSupplyTo_, address owner_) {
        _name = name_;
        _symbol = symbol_;
        _decimals = decimals_;
        _totalSupply = supply_;
        _balances[giveSupplyTo_] = supply_;
        _owner = owner_;
        
    }

    /**
     * @dev Functions using this modifier restrict the caller to only be the contract owner address (or the account operator of the owner)
     */
   modifier onlyOwner {
        require(isOperatorFor(msg.sender, owner()), "Caller is not the owner or the owner's account operator");
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
     * @dev Returns the address with the owner role of this token contract, 
     * i.e. what address can mint new tokens.
     * if a multi-sig account operator is required, this address should 
     * point to a smart contract implementing this multi-sig.
     */
    function owner() public view returns (address) {
        return _owner;
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
     * - `msg.sender` must be the contract's owner address.
     */
    function mint(address accountId, uint256 amount, bytes calldata message) public onlyOwner() returns (bool) {
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
     * @dev Changes the contract owner, i.e. who can mint new tokens
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Requirements:
     *
     * - caller must have the owner role.
     */
    function changeOwner(address newOwner) public onlyOwner() returns (bool) {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnerChanged(oldOwner, newOwner);
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
    function transferFromBatch(address payeeId, address[] calldata payerIds, uint256[] calldata amounts) public returns (bool, address[] memory) {
        require(isOperatorFor(msg.sender, payeeId), "Caller is not an account operator for payeeId");
        uint count;
        uint size = payerIds.length;
        address[] memory failedAddresses;
        uint failedArrayCount = 0;
        bool success = true;
        while (count < size){
            //
            if ((balanceOf(payerIds[count]) < amounts[count])||(amounts[count] > allowance(payerIds[count],payeeId))){
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


}