// SPDX-License-Identifier: No License

pragma solidity 0.8.7;

import "./IAccountManagement.sol";

contract ERC20 is IAccountManagement {
    
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
    mapping(address => bool) private _owners;
       
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
    constructor(string memory name_, string memory symbol_, uint8 decimals_, address initialOwner) {
        _name = name_;
        _symbol = symbol_;
        _decimals = decimals_;
        _owners[initialOwner] = true;      
    }

    /**
     * @dev Functions using this modifier restrict the caller to only be the contract owner address (or the account operator of the owner)
     */
    modifier onlyOwner {
        require(_owners[msg.sender], "Caller is not the account's operator");
        _;
    }

    function addOwner(address accountId) public override {
        emit OwnersUpdated(accountId, "added owner");
    }

    function removeOwner(address accountId) public override {
        emit OwnersUpdated(accountId, "removed owner");
    }

    function openAccount(address accountId, string calldata accountType, address parentAccountId, string calldata owningInstitutionId) external override {
        emit AccountInformation(accountId, AccountStatus.none, AccountStatus.open);
    }

    function closeAccount(address accountId) external override {
        emit AccountInformation(accountId, AccountStatus.open, AccountStatus.closed);
    }

    function enableAccount(address accountId) external override {
        emit AccountInformation(accountId, AccountStatus.disabled, AccountStatus.open);
    }

    function disableAccount(address accountId) external override {
        emit AccountInformation(accountId, AccountStatus.open, AccountStatus.disabled);
    }

    function freezeAccount(address accountId) external override {
        emit AccountInformation(accountId, AccountStatus.open, AccountStatus.frozen);
    }

    function accountInformation(address accountId) external view override returns (AccountInformationData memory data) {

        AccountInformationData memory newData;

        newData.accountId = accountId;
        newData.accountStatus = AccountStatus.closed;
        newData.accountType = "Business";
        newData.parentAccountId = address(0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2);
        newData.owningInstitutionId = "1234abcd";

        return newData;
    }

    function accountInformation2(address accountId) external view returns (address, AccountStatus, string memory, address, string memory) {

        return (accountId, AccountStatus.open, "Business", address(0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2), "1234abcd");
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
            require(amount == 0, "Must cancel previous approval"); //otherwise approve call would be vulnerable to race condition. Need to set approval to zero first             
        }
        _approve(msg.sender, payeeId, amount);
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
}