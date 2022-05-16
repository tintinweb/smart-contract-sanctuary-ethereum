//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "./BLXToken.sol";

/// @title A BLXToken bank
/// @author HarmonyAT
/// @notice Use this token to create and simulate a bank that uses BLXToken
/// @dev Inherits Pausable for locking/unlocking account while transfer is in process
/// @dev Inherits Ownable to enable Contract owner to own a bank, transfer owner of a bank.
contract BLXBank is Ownable, Pausable {
    /// @notice Name of the bank
    /// @dev Name of the bank
    /// @return Documents string containing bank name
    string public name;
    /// @notice Type of BLXToken used in this bank
    /// @dev BLXToken used in this bank
    BLXToken _bLXToken;

    constructor(string memory _name, BLXToken blx) Ownable() {
        name = _name;
        _bLXToken = blx;
    }

    struct BankAccount {
        uint256 createdAt;
        uint256 balance;
        uint256 transactionsCount;
        bool isActive;
    }

    /// @dev Number of bank accounts in this bank
    uint256 numBankAccounts;
    /// @notice Bank accounts of a address that uses this bank
    /// @dev mapping of bank accounts of addresses
    mapping(address => mapping(uint256 => BankAccount)) public _userBank;

    /// @dev All bank accounts in this bank
    mapping(uint256 => BankAccount) BankAccounts;

    /// @dev All addresses that have account in this bank
    mapping(uint256 => address) bankAccountIds;

    /// @notice Create a bank account
    /// @dev Emit event to notify contract state change (new bank account)
    /// @return bankAccountId ID of the created bank account
    function newBankAccount() public returns (uint256 bankAccountId) {
        bankAccountId = numBankAccounts++; // numBankAccounts is return variable
        BankAccount memory c;
        c.createdAt = block.timestamp;
        c.balance = 0;
        c.transactionsCount = 0;
        c.isActive = true;
        _userBank[msg.sender][bankAccountId] = c;
        bankAccountIds[bankAccountId] = msg.sender;
        BankAccounts[bankAccountId] = c;
        emit RegisterBankAccount(msg.sender, bankAccountId);
    }

    /// @notice Total balance of BLXToken in this bank
    /// @dev Total balance of bank owner address
    function getGlobalBankBalance() public view returns (uint256) {
        return _bLXToken.balanceOf(address(this));
    }

    /// @notice Address of Owner of the bank
    /// @dev Explain to a developer any extra details
    /// @inheritdoc Ownable
    function owner() public view override returns (address) {
        return super.owner();
    }

    
    function getAddressOfBank() public view returns (address) {
        return address(this);
    }

    // 3. As a user I want to be able to deposit any number of `BLX` tokens to my bank account
    // 11. As a user I want to be unable to deposit tokens when deposits are paused
    /// @notice Deposit to your bank account
    /// @dev Only successful when account is active
    /// @param _bankAccountId ID of bank account
    /// @param _value Amount of token to deposit
    /// @return success bool result of the transaction
    function bankDeposit(uint256 _bankAccountId, uint256 _value)
        public
        whenNotPaused
        returns (bool success)
    {
        require(_value > 0, "Deposit must be more than 0");
        require(
            _bLXToken.transferFrom(msg.sender, address(this), _value),
            "Can not transfer"
        );
        BankAccount storage c = _userBank[msg.sender][_bankAccountId];
        require(c.isActive == true, "The Account is not active");
        c.balance += _value;
        c.transactionsCount += 1;
        return true;
    }

    // 4. As a user I want to be able to withdraw any number of `BLX` tokens that is available in my account
    /// @notice Withdraw Token from your account
    /// @dev Only successful when account is active
    /// @param _bankAccountId ID of bank account the withdraw
    /// @param _value Amount of token to withdraw
    /// @return success bool result of the transaction
    function withdrawToAccount(uint256 _bankAccountId, uint256 _value)
        public
        returns (bool success)
    {
        require(_value > 0, "Withdraw must be more than 0");
        BankAccount storage c = _userBank[msg.sender][_bankAccountId];
        require(c.isActive == true, "The Account is not active");
        require(c.balance >= _value, "not enough token");
        require(_bLXToken.transfer(msg.sender, _value), "Can not transfer");
        c.balance -= _value;
        c.transactionsCount += 1;

        return true;
    }

    // 6. As a user I want to get information about my account - date of creation, balance, number of transaction if account is active
    /// @notice Get information about your account
    /// @dev Only successful when account is active
    /// @param _bankAccountId ID of bank account
    /// @return creation uint256 creation time
    /// @return balance unit256 balance of the account
    /// @return nTransaction uint256 number of transaction
    function getInfoAccount(uint256 _bankAccountId)
        public
        view
        returns (
            uint256 creation,
            uint256 balance,
            uint256 nTransaction
        )
    {
        BankAccount storage c = _userBank[msg.sender][_bankAccountId];
        require(c.isActive == true, "The Account is not active");
        return (c.createdAt, c.balance, c.transactionsCount);
    }

    // 7. As a user I want to be able to deactivate my account
    /// @notice Deactivate your account
    /// @dev Set active state
    /// @param _bankAccountId ID of bank account
    /// @return success bool result of the transaction
    function deactivateAccount(uint256 _bankAccountId)
        public
        returns (bool success)
    {
        BankAccount storage c = _userBank[msg.sender][_bankAccountId];
        c.isActive = false;
        return true;
    }

    // 8. As a user I want to be able to transfer funds from my bank account to another existing bank account
    // 9. As a user I want to be unable to transfer funds from my bank account to an inactive bank account
    /// @notice Transfer between your active accounts
    /// @dev Only successful when both accounts are active
    /// @param _bankAccountIdFrom ID of transferring account
    /// @param _bankAccountIdTo ID of destination account
    /// @return success result of the transaction
    function transferAnotherAccount(
        uint256 _bankAccountIdFrom,
        uint256 _bankAccountIdTo,
        uint256 _value
    ) public returns (bool success) {
        require(_value > 0, "Transfer anount must be more than 0");
        BankAccount storage cFrom = _userBank[msg.sender][_bankAccountIdFrom];
        require(cFrom.isActive == true, "The Account is not active");
        require(cFrom.balance >= _value, "Not enough token");
        BankAccount storage cTo = _userBank[bankAccountIds[_bankAccountIdTo]][
            _bankAccountIdTo
        ];
        require(cTo.isActive == true, "The Account is not active");
        cFrom.balance -= _value;
        cFrom.transactionsCount += 1;
        cTo.balance += _value;
        cTo.transactionsCount += 1;
        return true;
    }

    // 10. As an owner I want to be able to pause and unpause deposits to the bank
    /// @notice Pause a transaction
    /// @dev Only owner of the contract can run
    /// @return success result of the transaction
    function pauseBank() external onlyOwner returns (bool success) {
        if (paused()) {
            _unpause();
        } else {
            _pause();
        }
        return true;
    }

    /// @notice Event when a bank account is created
    /// @param _from Address that created the account
    /// @param _bankId ID of account created
    event RegisterBankAccount(address indexed _from, uint256 _bankId);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.13;

// import "./interfaces/IERC20.sol";

/// @title A Token based on IERC20
/// @author Harmony-AT
/// @notice You can use this contract to create a IERC20 Token
/// @dev Custom implementation of IERC20 with custom minting logic
contract BLXToken {
    uint256 private constant MAX_UINT256 = 2**256 - 1;
    mapping(address => uint256) public balances;
    mapping(address => mapping(address => uint256)) public allowed;

    string private _name;
    uint8 private _decimals;
    string private _symbol;
    address private _ownerAddress;
    uint256 private _totalSupply;

    constructor(
        uint256 _initialAmount,
        string memory _tokenName,
        uint8 _decimalUnits,
        string memory _tokenSymbol
    ) {
        balances[msg.sender] = _initialAmount; // Give the creator all initial tokens
        _totalSupply = _initialAmount; // Update total supply
        _name = _tokenName; // Set the name for display purposes
        _decimals = _decimalUnits; // Amount of decimals for display purposes
        _symbol = _tokenSymbol; // Set the symbol for display purposes
        _ownerAddress = msg.sender; // Set the address for owner the token
    }

     event Transfer(address indexed from, address indexed to, uint256 value);
     event Approval(address indexed owner, address indexed spender, uint256 value);

    /// @notice Name of the token
    /// @dev Return the name of the token
    function name() external view returns (string memory) {
        return _name;
    }

    /// @notice Decimals of the token
    /// @dev Return Decimals of the token
    function decimals() external view returns (uint8) {
        return _decimals;
    }

    /// @notice Symbol of the token
    /// @dev Return symbol of the token
    function symbol() external view returns (string memory) {
        return _symbol;
    }

    /// @notice Total supply of token
    /// @dev Return total supply of token
    function totalSupply() external view returns (uint256) {
        return _totalSupply;
    }

    function getAddress() external view returns (address){
        return address(this);
    }

    /// @notice Mint an amount of token to the contract owner's balance and total supply
    /// @dev Emit a Transfer Event from zero address to owner's address, only contract owner can run
    /// @param amount The amount of token to mint
    function mint(uint256 amount) external virtual {
        require(_ownerAddress != address(0), "ERC20: mint to the zero address");
        require(
            _ownerAddress == msg.sender,
            "The current address is not owner of the Token"
        );
        _totalSupply += amount;
        balances[_ownerAddress] += amount;
        emit Transfer(address(0), _ownerAddress, amount);
    }

    /// @notice Transfer token from this address to another address
    /// @dev Emit a Transfer Event from sender to _to address
    /// @param _to Target address
    /// @param _value Amount of token to transfer
    /// @return success bool result of the transfer
    function transfer(address _to, uint256 _value)
        public
        returns (bool success)
    {
        require(balances[msg.sender] >= _value, "Not enough tokens");
        balances[msg.sender] -= _value;
        balances[_to] += _value;
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    /// @notice Transfer token from an address to another address
    /// @dev Emit a Transfer Event with _value token from _from to _to
    /// @param _from _from Address to get token from
    /// @param  _to Address to receive token
    /// @param _value Amount of token
    /// @return success bool result of the transfer
    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    ) public returns (bool success) {
        uint256 allowanceValue = allowed[_from][msg.sender];
        require(
            balances[_from] >= _value && allowanceValue >= _value,
            "not allow amount more than value send"
        );
        balances[_to] += _value;
        balances[_from] -= _value;
        if (allowanceValue < MAX_UINT256) {
            allowed[_from][msg.sender] -= _value;
        }
        emit Transfer(_from, _to, _value);
        return true;
    }

    function balanceOf(address _owner) public view returns (uint256 balance) {
        return balances[_owner];
    }

    function approve(address _spender, uint256 _value)
        public
        returns (bool success)
    {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender)
        public
        view
        returns (uint256 remaining)
    {
        return allowed[_owner][_spender];
    }

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}