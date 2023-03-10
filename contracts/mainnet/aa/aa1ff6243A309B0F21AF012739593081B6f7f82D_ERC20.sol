/**
 *Submitted for verification at Etherscan.io on 2023-03-09
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.16;


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
    // The absolute maximum supply that can be reached by minting. 
    uint256 private _maximumSupply;
    // Allow remint of tokens which have been burned.
    bool private _allowRemint;
    // Stores the accumulated burned total
    uint256 private _burnAccumulatedTotal;
        
    /**
     * @dev Emitted when `amount` tokens are moved from one account (`payerId`) to another (`payeeId`).
     *
     * Note that `amount` may be zero.
     */
    event Transfer(address indexed payerId, address indexed payeeId, uint256 amount);

    /**
     * @dev Emitted when the allowance of a `payeeId` for an `payerId` is set by
     * a call to {approve}. `amount` is the new allowance.
     */
    event Approval(address indexed payerId, address indexed payeeId, uint256 amount);

    /**
     * @dev Emitted when tokens are minted or burned.
     */
    event MetaData(string indexed functionName, bytes data);

    /**
     * @dev Emitted when contract owner is changed from `oldContractOwnerId` to `newContractOwnerId`.
     */
    event OwnerChanged(address indexed oldContractOwnerId, address indexed newContractOwnerId);

    /**
     * @dev Emitted when `additionalOwnerAccountId` is authorised by `ownerAccountId`.
     */
    event AuthorizedOperator(address indexed additionalOwnerAccountId, address indexed ownerAccountId);

    /**
     * @dev Emitted when `additionalOwnerAccountId` is revoked by `ownerAccountId`.
     */
    event RevokedOperator(address indexed additionalOwnerAccountId, address indexed ownerAccountId);

    /**
     * @dev Emitted when the batched transactions failed for address `failedAddress` for function `functionName`.
     */
    event BatchFailure(string indexed functionName, address indexed failedAddress);

    /**
     * @dev Sets the values for {_name}, {_symbol}, {_decimals}, {_totalSupply}.
     * Additionally, all of the supply is initially given to the address corresponding to {giveSupplyTo_}
     */
    constructor(string memory name_, string memory symbol_, uint8 decimals_, uint256 supply_, address giveSupplyTo_, address owner_, uint256 maximumSupply_, bool allowRemint_) {
        require(supply_<=maximumSupply_, "Current supply must be less than or equal to max supply");
        _name = name_;
        _symbol = symbol_;
        _decimals = decimals_;
        _totalSupply = supply_;
        _balances[giveSupplyTo_] = supply_;
        _owner = owner_;
        _maximumSupply = maximumSupply_;
        _allowRemint = allowRemint_;
    }

    /**
     * @dev Functions using this modifier restrict the caller to only be the contract owner address (or the account operator of the owner)
     */
   modifier onlyOwner {
        require(isOperatorFor(msg.sender, owner()), "Caller is not the account's operator");
      _;
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
    function transfer(address payeeId, uint256 amount) external returns (bool) {
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
    ) external returns (bool) {
        require(isOperatorFor(msg.sender, payerId), "Caller not an operator for payerId");
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
     * The if statement makes sure that this contract's approval system is not 
     * vulnerable to teh race condition (where a payee spends the previous
     * and new allowance)
     *
     * Requirements
     *
     * - the caller must have at least `amount` tokens.
     * - `payeeId` cannot be the zero address.
     */
    function approve(address payeeId, uint256 amount) external returns (bool) {
        if (_allowances[msg.sender][payeeId] > 0){
            require(amount == 0, "Must set approval to zero before setting new approval"); //otherwise approve call would be vulnerable to race condition. Need to set approval to zero first             
        }
        _approve(msg.sender, payeeId, amount);
        return true;
    }

    /**
     * @dev Approves `amount` tokens from `payerId` to `payeeId`. The caller must
     * be an account operator of `payerId`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * The if statement makes sure that this contract's approval system is not 
     * vulnerable to the race condition (where a payee spends the previous
     * and new allowance)
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
    ) external returns (bool) {
        require(isOperatorFor(msg.sender, payerId), "Caller is not an account operator for payerId");
        if (_allowances[payerId][payeeId] > 0){
            require(amount == 0, "Must cancel previous approval"); //otherwise approve call would be vulnerable to race condition. Need to set approval to zero first     
        }
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
    function transferFrom(address payerId, address payeeId, uint256 amount) external returns (bool) {
        require(msg.sender == payeeId, "Transaction sender is not payeeId");
        _transferFrom(payerId, payeeId, amount);
        return true;
    }

    /**
     * @dev Moves `amount` tokens from `payerId` to `payeeId` using the
     * allowance mechanism. `amount` is then deducted from the 'payerId'
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
    ) external {
        require(isOperatorFor(msg.sender, payeeId), "Caller not an operator for payeeId");
        _transferFrom(payerId, payeeId, amount);
    }


    /** @dev Creates `amount` tokens and assigns them to `beneficiaryAccountId`, increasing
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
     * - `beneficiaryAccountId` cannot be the zero address.
     * - `msg.sender` must be the contract's owner address.
     */
    function mint(address beneficiaryAccountId, uint256 amount, bytes calldata data) external onlyOwner() returns (bool) {
        require(beneficiaryAccountId != address(0), "Zero address used");
        require((_allowRemint && _maximumSupply >= (_totalSupply + amount)) ||
                (!_allowRemint && (_maximumSupply >= (_totalSupply + amount + _burnAccumulatedTotal))) , "Minting would exceed the configured maximum supply.");

        _totalSupply += amount;
        _balances[beneficiaryAccountId] += amount;
        
        emit Transfer(address(0), beneficiaryAccountId, amount);
        emit MetaData("mint", data);

        return true;
    }

    /**
     * @dev Destroys `amount` tokens from the sender's address, reducing the
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
     * - the caller's account must have at least `amount` tokens.
     */
    function burn(uint256 amount, bytes calldata data) external returns (bool) {
        _burn(msg.sender, amount, data);
        return true;
    }

    /**
     * @dev Destroys `amount` tokens from `payerId`, reducing the total supply.
     * Metadata can be assigned to this burn via the 'data' parameter if required.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     * Emits a {MetaData} event.
     *
     * Requirements
     *
     * - `payerId` cannot be the zero address.
     * - `payerId` must have at least `amount` tokens.
     * - the caller must be an account operator for `payerId`.
     */
    function operatorBurn(address payerId, uint256 amount, bytes calldata data) external returns (bool) {
        require(isOperatorFor(msg.sender, payerId), "Caller not an operator for payerId");
        _burn(payerId, amount, data);
        return true;
    }

    /**
     * @dev Changes the contract owner to 'newContractOwnerId', i.e. who can mint new tokens
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Requirements:
     *
     * - caller must have the owner role.
     */
    function changeOwner(address newContractOwnerId) external onlyOwner() returns (bool) {
        require(newContractOwnerId != address(0x0), "Zero address used");
        address oldOwner = _owner;
        _owner = newContractOwnerId;
        emit OwnerChanged(oldOwner, newContractOwnerId);
        return true;
    }


    /**
     * @dev Make `AdditionalOwnerAccountId` an account operator of caller.
     *
     * Emits an {AuthorizedOperator} event.
     *
     * Requirements:
     *
     * - `AdditionalOwnerAccountId` must not equal the caller.
     */
    function authorizeOperator(address additionalOwnerAccountId) external {
        require(msg.sender != additionalOwnerAccountId, "Authorizing self as operator");

        _accountOperators[msg.sender][additionalOwnerAccountId] = true;

        emit AuthorizedOperator(additionalOwnerAccountId, msg.sender);
    }

    /**
     * @dev Revoke `additionalOwnerAccountId`'s account operator status for caller.
     *
     * Emits a {RevokedOperator} event.
     *
     * Requirements:
     *
     * - `additionalOwnerAccountId` must not equal the caller.
     */
    function revokeOperator(address additionalOwnerAccountId) external {

        delete _accountOperators[msg.sender][additionalOwnerAccountId];

        emit RevokedOperator(additionalOwnerAccountId, msg.sender);
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
    function transferBatch(address payerId, address[] calldata payeeIds, uint256[] calldata amounts) external returns (bool, address) {
        require(isOperatorFor(msg.sender, payerId), "Caller not an operator for payerId");
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
     * Returns firstly a boolean value indicating whether the batch transfer succeeded for every given payerId (true)
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
    function transferFromBatch(address payeeId, address[] calldata payerIds, uint256[] calldata amounts) external returns (bool) {
        require(isOperatorFor(msg.sender, payeeId), "Caller not an operator for payeeId");
        require(payerIds.length == amounts.length, "Length of 'payerIds' and 'amounts' arrays are not equal");

        uint count;
        uint size = payerIds.length;
        bool success = true;

        while (count < size){
            //
            if ((balanceOf(payerIds[count]) < amounts[count]) || (amounts[count] > allowance(payerIds[count],payeeId))){
                success = false;
                emit BatchFailure("transferFrom", payerIds[count]);
            } else {
                //only perform the transfer from if it will succeed
                _transferFrom(payerIds[count], payeeId, amounts[count]);
            }
            count++;
        }
        return success;
    }


    /**
     * @dev Moves `amount` of tokens from `payerId` to `payeeId`.
     *
     * This internal function is equivalent to {transfer}
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
        require(payerId != address(0), "Zero address used");
        require(payeeId != address(0), "Zero address used");
        require(payeeId != address(this), "Contract address used");

        uint256 senderBalance = _balances[payerId];
        require(senderBalance >= amount, "Amount exceeds balance");
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

        require(payerId != address(0), "Zero address used");

        uint256 accountBalance = _balances[payerId];
        require(accountBalance >= amount, "Amount exceeds balance");
        unchecked {
            _balances[payerId] = accountBalance - amount;
        }
        _totalSupply -= amount;        
        _burnAccumulatedTotal += amount;

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
        require(payerId != address(0), "Zero address used");
        require(payeeId != address(0), "Zero address used");

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

        require(payerId != payeeId, "Different addresses required");
        uint256 currentAllowance = _allowances[payerId][payeeId];
        require(currentAllowance >= amount, "Amount exceeds allowance");
        _transfer(payerId, payeeId, amount);
        unchecked {
            _approve(payerId, payeeId, currentAllowance - amount);
        }

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
     *
     * Returns the maximum supply that can be reached by minting new tokens. A maximumSupply of zero means the supply is unlimited. 
     *
    */
    function maximumSupply() public view returns(uint256) {
        return _maximumSupply;
    }

    /**
     *
     * Returns the running total of the number of tokens burned
     *
    */
    function burnAccumulatedTotal() public view returns(uint256) {
        return _burnAccumulatedTotal;
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
     * @dev Returns true if `AdditionalOwnerAccountId` is an account operator of `OwnerAccountId`.
     * Account operators can send and burn tokens for an authorised account. All
     * accounts are their own account operator.
     */
    function isOperatorFor(address AdditionalOwnerAccountId, address OwnerAccountId) public view returns (bool) {
        return
            AdditionalOwnerAccountId == OwnerAccountId ||
            _accountOperators[OwnerAccountId][AdditionalOwnerAccountId];
    }


}