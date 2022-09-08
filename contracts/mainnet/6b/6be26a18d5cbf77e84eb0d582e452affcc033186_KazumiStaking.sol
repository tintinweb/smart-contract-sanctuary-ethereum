/**
 *Submitted for verification at Etherscan.io on 2022-09-07
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;


abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

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
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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

abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}


contract KazumiStaking is Ownable, ReentrancyGuard {

    address public constant token = 0x1852baAF94015634d948862D03fF04489772Cf65;

    uint256 public MIN_LOCK_DURATION = 15 * 24 * 60 * 60;
    uint256 public MIN_THRESHOLD_TOKENS = 100000 * 10**18;

    bool public PAUSED = true;

    mapping(address => uint256) public stakedBalances;

    struct LockBox {
        address depositAddress;
        uint256 tokenAmount;
        uint256 unlockTimestamp;
    }

    uint256 public LOCK_ID;
    mapping(address => uint256[]) public tokenLocksByAddress;
    mapping(uint256 => LockBox) public tokenLocks;

    event Deposit(address indexed staker, uint256 lockId, uint256 tokensAmount, uint256 lockDuration);

    /// Deposits not enabled
    error DepositsNotEnabled();
    /// Insufficient withdrawable amount
    error InsufficientWithdrawableAmount();
    /// Already withdrawn
    error AlreadyWithdrawn();
    /// Invalid amount
    error InvalidAmount();
    /// Caller does not own given lockId
    error CallerUnauthorized();
    /// Withdraw is not possible because the lock period is not over yet
    error LockPeriodOngoing();
    /// Lock period is too short
    error LockPeriodInsufficient();
    /// Could not transfer the designated ERC20 token
    error TransferFailed();



    /// @dev Deposit tokens to be locked until the end of the locking period
    /// @param amount the amount of tokens to deposit, lockDuration the duration of the lock
    function deposit(uint256 amount, uint256 lockDuration) external nonReentrant returns (uint256 _id) {

        if (PAUSED) revert DepositsNotEnabled();
        if (lockDuration < MIN_LOCK_DURATION) revert LockPeriodInsufficient();
        if (amount < MIN_THRESHOLD_TOKENS) revert InvalidAmount();
        if (!IERC20(token).transferFrom(msg.sender, address(this), amount)) revert TransferFailed();

        stakedBalances[msg.sender] += amount;

        _id = ++LOCK_ID;
        tokenLocks[_id] = LockBox({
            depositAddress: msg.sender,
            tokenAmount: amount, 
            unlockTimestamp: block.timestamp + lockDuration
        });

        tokenLocksByAddress[msg.sender].push(_id);
        
        emit Deposit(msg.sender, _id, amount, lockDuration);
    }

    /// @dev Withdraw tokens from a specific lock
    /// @param lockId the id of the lock
    function withdraw(uint256 lockId) external nonReentrant {

        LockBox storage lockBox = tokenLocks[lockId];

        if (block.timestamp < lockBox.unlockTimestamp) revert LockPeriodOngoing();
        if (lockBox.tokenAmount == 0) revert AlreadyWithdrawn();
        if (lockBox.depositAddress != msg.sender) revert CallerUnauthorized();

        unchecked {
            stakedBalances[msg.sender] -= lockBox.tokenAmount;
        }

        if (!IERC20(token).transfer(msg.sender, lockBox.tokenAmount)) revert TransferFailed();

        lockBox.tokenAmount = 0;
    }

    /// @dev Withdraws amount specified from withdrawable tokens for caller
    function withdrawAmount(uint256 amount) external nonReentrant {

        if (amount == 0) revert InvalidAmount();

        uint256[] memory locks = getLocksByAddress(msg.sender);

        uint256 withdrawableAmount;
        for (uint256 i; i < locks.length;) {
            LockBox storage lockBox = tokenLocks[locks[i]];
            if (block.timestamp >= lockBox.unlockTimestamp && lockBox.tokenAmount > 0) {
                if (withdrawableAmount + lockBox.tokenAmount >= amount) {
                    unchecked {
                        lockBox.tokenAmount -= (amount - withdrawableAmount);
                    }
                    withdrawableAmount = amount;
                    break;
                } else {
                    unchecked {
                        withdrawableAmount += lockBox.tokenAmount;
                    }
                    lockBox.tokenAmount = 0;
                }
            }
            unchecked {i++;}
        }

        if (withdrawableAmount < amount) revert InsufficientWithdrawableAmount();

        unchecked {
            stakedBalances[msg.sender] -= withdrawableAmount;
        }

        if (!IERC20(token).transfer(msg.sender, withdrawableAmount)) revert TransferFailed();
    }

    /// @dev Withdraw all withdrawable tokens for caller
    function withdrawAll() external nonReentrant {

        uint256[] memory locks = getLocksByAddress(msg.sender);
        
        uint256 withdrawableAmount;
        for (uint256 i; i < locks.length;) {
            LockBox storage lockBox = tokenLocks[locks[i]];
            if (block.timestamp >= lockBox.unlockTimestamp && lockBox.tokenAmount > 0) {
                unchecked {
                    withdrawableAmount += lockBox.tokenAmount;
                }
                lockBox.tokenAmount = 0;
            }
            unchecked {i++;}
        }

        if (withdrawableAmount == 0) revert InsufficientWithdrawableAmount();

        unchecked {
            stakedBalances[msg.sender] -= withdrawableAmount;
        }

        if (!IERC20(token).transfer(msg.sender, withdrawableAmount)) revert TransferFailed();
    }

    /// @dev Redeposits withdrawable tokens from a given lock and creates a new lock for it
    /// @param lockId the id of the lock, lockDuration the duration of the new lock
    function redeposit(uint256 lockId, uint256 lockDuration) external nonReentrant returns (uint256 _id) {

        LockBox storage lockBox = tokenLocks[lockId];

        if (block.timestamp < lockBox.unlockTimestamp) revert LockPeriodOngoing();
        if (lockDuration < MIN_LOCK_DURATION) revert LockPeriodInsufficient();
        if (lockBox.tokenAmount == 0) revert AlreadyWithdrawn();
        if (lockBox.depositAddress != msg.sender) revert CallerUnauthorized();

        _id = ++LOCK_ID;
        tokenLocks[_id] = LockBox({
            depositAddress: msg.sender,
            tokenAmount: lockBox.tokenAmount, 
            unlockTimestamp: block.timestamp + lockDuration
        });

        tokenLocksByAddress[msg.sender].push(_id);

        emit Deposit(msg.sender, _id, lockBox.tokenAmount, lockDuration);

        lockBox.tokenAmount = 0;
    }

    /// @dev Redeposits amount from available withdrawable tokens for caller and creates a new lock for it
    /// @param amount the amount to relock lockDuration the duration of the lock
    function redepositAmount(uint256 amount, uint256 lockDuration) external nonReentrant returns (uint256 _id) {

        if (lockDuration < MIN_LOCK_DURATION) revert LockPeriodInsufficient();
        if (amount == 0) revert InvalidAmount();

        uint256[] memory locks = getLocksByAddress(msg.sender);

        uint256 withdrawableAmount;
        for (uint256 i; i < locks.length;) {
            LockBox storage lockBox = tokenLocks[locks[i]];
            if (block.timestamp >= lockBox.unlockTimestamp && lockBox.tokenAmount > 0) {
                if (withdrawableAmount + lockBox.tokenAmount >= amount) {
                    unchecked {
                        lockBox.tokenAmount -= (amount - withdrawableAmount);
                    }
                    withdrawableAmount = amount;
                    break;
                } else {
                    unchecked {
                        withdrawableAmount += lockBox.tokenAmount;
                    }
                    lockBox.tokenAmount = 0;
                }
            }
            unchecked {i++;}
        }

        if (withdrawableAmount < amount) revert InsufficientWithdrawableAmount();

        _id = ++LOCK_ID;
        tokenLocks[_id] = LockBox({
            depositAddress: msg.sender,
            tokenAmount: withdrawableAmount, 
            unlockTimestamp: block.timestamp + lockDuration
        });

        tokenLocksByAddress[msg.sender].push(_id);

        emit Deposit(msg.sender, _id, withdrawableAmount, lockDuration);
    }

    /// @dev Redeposits all withdrawable tokens for caller and creates a new lock for it
    /// @param lockDuration the duration of the lock
    function redepositAll(uint256 lockDuration) external nonReentrant returns (uint256 _id) {

        if (lockDuration < MIN_LOCK_DURATION) revert LockPeriodInsufficient();

        uint256[] memory locks = getLocksByAddress(msg.sender);

        uint256 withdrawableAmount;
        for (uint256 i; i < locks.length;) {
            LockBox storage lockBox = tokenLocks[locks[i]];
            if (block.timestamp >= lockBox.unlockTimestamp && lockBox.tokenAmount > 0) {
                unchecked {
                    withdrawableAmount += lockBox.tokenAmount;
                }
                lockBox.tokenAmount = 0;
            }
            unchecked {i++;}
        }

        if (withdrawableAmount == 0) revert InsufficientWithdrawableAmount();

        _id = ++LOCK_ID;
        tokenLocks[_id] = LockBox({
            depositAddress: msg.sender,
            tokenAmount: withdrawableAmount, 
            unlockTimestamp: block.timestamp + lockDuration
        });

        tokenLocksByAddress[msg.sender].push(_id);

        emit Deposit(msg.sender, _id, withdrawableAmount, lockDuration);
    }


    /// @dev Get withdrawable token amount for staker
    /// @param staker the address of the staker
    function getWithdrawableTokenAmount(address staker) external view returns (uint256) {
        uint256[] memory locks = getLocksByAddress(staker);
        uint256 withdrawableAmount;
        for (uint256 i; i < locks.length;) {
            LockBox memory lockBox = tokenLocks[locks[i]];
            if (block.timestamp >= lockBox.unlockTimestamp && lockBox.tokenAmount > 0) {
                unchecked {
                    withdrawableAmount += lockBox.tokenAmount;
                }
            }
            unchecked {i++;}
        }
        return withdrawableAmount;
    }

    /// @dev Get lock ids for staker
    /// @param staker the address of the staker
    function getLocksByAddress(address staker) public view returns (uint256[] memory) {
        return tokenLocksByAddress[staker];
    }

    /// @dev Get lockboxes for staker
    /// @param staker the address of the staker
    function getLockBoxesByAddress(address staker) external view returns (LockBox[] memory) {
        uint256[] memory locks = getLocksByAddress(staker);
        LockBox[] memory lockBoxes = new LockBox[](locks.length);
        for (uint256 i; i < locks.length;) {
            lockBoxes[i] = tokenLocks[locks[i]];
            unchecked {i++;}
        }
        return lockBoxes;
    }

    /// @dev Get lockbox by id
    /// @param _id the lockbox id
    function getLockBoxById(uint256 _id) public view returns (LockBox memory) {
        return tokenLocks[_id];
    }

    /// @dev Get total staked balance for staker
    /// @param staker the address of the staker
    function getStakedBalance(address staker) external view returns (uint256) {
        return stakedBalances[staker];
    }

    /// @dev Set deposits paused
    function setPaused(bool val) external onlyOwner {
        PAUSED = val;
    }

    /// @dev Set min lock duration for deposits
    function setMinLockDuration(uint256 newDuration) external onlyOwner {
        MIN_LOCK_DURATION = newDuration;
    }

    /// @dev Set min threshold amount for deposits
    function setMinThreshold(uint256 newThreshold) external onlyOwner {
        MIN_THRESHOLD_TOKENS = newThreshold;
    }
}