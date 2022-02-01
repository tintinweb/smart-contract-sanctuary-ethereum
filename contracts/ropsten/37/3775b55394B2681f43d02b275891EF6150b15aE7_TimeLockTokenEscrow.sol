/**
 *Submitted for verification at Etherscan.io on 2022-02-01
*/

pragma solidity 0.5.14;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP. Does not include
 * the optional functions; to access them see {ERC20Detailed}.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract Ownable {

    // Owner of the contract
    address private _owner;

    /**
    * @dev Event to show ownership has been transferred
    * @param previousOwner representing the address of the previous owner
    * @param newOwner representing the address of the new owner
    */
    event OwnershipTransferred(address previousOwner, address newOwner);

    /**
    * @dev The constructor sets the original owner of the contract to the sender account.
    */
    constructor() public {
        setOwner(msg.sender);
    }

    /**
   * @dev Tells the address of the owner
   * @return the address of the owner
   */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Sets a new owner address
     */
    function setOwner(address newOwner) internal {
        _owner = newOwner;
    }

    /**
    * @dev Throws if called by any account other than the owner.
    */
    modifier onlyOwner() {
        require(msg.sender == owner());
        _;
    }

    /**
     * @dev Allows the current owner to transfer control of the contract to a newOwner.
     * @param newOwner The address to transfer ownership to.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        emit OwnershipTransferred(owner(), newOwner);
        setOwner(newOwner);
    }
}

// File: @openzeppelin/contracts/utils/ReentrancyGuard.sol


/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 */
contract ReentrancyGuard {
    // counter to allow mutex lock with only one SSTORE operation
    uint256 private _guardCounter;

    constructor () internal {
        // The counter starts at one to prevent changing it from zero to a non-zero
        // value, which is a more expensive operation.
        _guardCounter = 1;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        _guardCounter += 1;
        uint256 localCounter = _guardCounter;
        _;
        require(localCounter == _guardCounter, "ReentrancyGuard: reentrant call");
    }
}

// File: contracts/TimeLockTokenEscrow.sol

contract TimeLockTokenEscrow is ReentrancyGuard, Ownable {

    event Lockup(
        address indexed _creator,
        address indexed _beneficiary,
        uint256 indexed _amount,
        uint256 _lockedUntil
    );

    event LockupReverted(
        address indexed _creator,
        address indexed _beneficiary,
        uint256 indexed _amount
    );

    event Withdrawal(
        address indexed _beneficiary,
        address indexed _caller
    );

    event lockAdminAdd(address indexed _account);

    struct TimeLock {
        address creator;
        uint256 amount;
        uint256 lockedUntil;
    }

    IERC20 public token;

    mapping(address => TimeLock) public beneficiaryToTimeLock;
    mapping(address => bool) public lockAdmin;

    modifier onlyOwner() {
        require(msg.sender == owner());
        _;
    }

    modifier onlyLockAdmin(address _account) {
        require(lockAdmin[_account] == true);
        _;
    }

    constructor(IERC20 _token) public {
        token = _token;
        setLockAdmin(msg.sender);
    }

    function islockAdmin(address _account) public view returns (bool) {
        return lockAdmin[_account];
    }

    function setLockAdmin(address _account) public onlyOwner {
        lockAdmin[_account] = true;
        emit lockAdminAdd(_account);
    }

    function lock(address _beneficiary, uint256 _amount, uint256 _lockedUntil) public nonReentrant onlyLockAdmin(msg.sender) {
        require(_beneficiary != address(0), "You cannot lock up tokens for the zero address");
        require(_amount > 0, "Lock up amount of zero tokens is invalid");
        require(beneficiaryToTimeLock[_beneficiary].amount == 0, "Tokens have already been locked up for the given address");
        require(token.allowance(msg.sender, address(this)) >= _amount, "The contract does not have enough of an allowance to escrow");

        beneficiaryToTimeLock[_beneficiary] = TimeLock({
            creator : msg.sender,
            amount : _amount,
            lockedUntil : _lockedUntil
        });

        bool transferSuccess = token.transferFrom(msg.sender, address(this), _amount);
        require(transferSuccess, "Failed to escrow tokens into the contract");

        emit Lockup(msg.sender, _beneficiary, _amount, _lockedUntil);
    }

    function revertLock(address _beneficiary) public nonReentrant onlyLockAdmin(msg.sender) {
        TimeLock storage lockup = beneficiaryToTimeLock[_beneficiary];
        require(lockup.creator == msg.sender, "Cannot revert a lock unless you are the creator");
        require(lockup.amount > 0, "There are no tokens left to revert lock up for this address");

        uint256 transferAmount = lockup.amount;
        lockup.amount = 0;

        bool transferSuccess = token.transfer(lockup.creator, transferAmount);
        require(transferSuccess, "Failed to send tokens back to lock creator");

        emit LockupReverted(msg.sender, _beneficiary, transferAmount);
    }

    function withdrawal(address _beneficiary) public nonReentrant {
        TimeLock storage lockup = beneficiaryToTimeLock[_beneficiary];
        require(lockup.amount > 0, "There are no tokens locked up for this address");
        require(now >= lockup.lockedUntil, "Tokens are still locked up");

        uint256 transferAmount = lockup.amount;
        lockup.amount = 0;

        bool transferSuccess = token.transfer(_beneficiary, transferAmount);
        require(transferSuccess, "Failed to send tokens to the beneficiary");

        emit Withdrawal(_beneficiary, msg.sender);
    }
}