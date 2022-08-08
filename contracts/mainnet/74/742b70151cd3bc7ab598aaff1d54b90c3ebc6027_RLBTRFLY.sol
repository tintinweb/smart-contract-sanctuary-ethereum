/**
 *Submitted for verification at Etherscan.io on 2022-08-08
*/

// Sources flattened with hardhat v2.9.2 https://hardhat.org

// File @rari-capital/solmate/src/utils/[email protected]




/// @notice Gas optimized reentrancy protection for smart contracts.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/utils/ReentrancyGuard.sol)
/// @author Modified from OpenZeppelin (https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/security/ReentrancyGuard.sol)
abstract contract ReentrancyGuard {
    uint256 private reentrancyStatus = 1;

    modifier nonReentrant() {
        require(reentrancyStatus == 1, "REENTRANCY");

        reentrancyStatus = 2;

        _;

        reentrancyStatus = 1;
    }
}


// File @rari-capital/solmate/src/tokens/[email protected]




/// @notice Modern and gas efficient ERC20 + EIP-2612 implementation.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/tokens/ERC20.sol)
/// @author Modified from Uniswap (https://github.com/Uniswap/uniswap-v2-core/blob/master/contracts/UniswapV2ERC20.sol)
/// @dev Do not manually set balances without updating totalSupply, as the sum of all user balances must not exceed it.
abstract contract ERC20 {
    /*///////////////////////////////////////////////////////////////
                                  EVENTS
    //////////////////////////////////////////////////////////////*/

    event Transfer(address indexed from, address indexed to, uint256 amount);

    event Approval(address indexed owner, address indexed spender, uint256 amount);

    /*///////////////////////////////////////////////////////////////
                             METADATA STORAGE
    //////////////////////////////////////////////////////////////*/

    string public name;

    string public symbol;

    uint8 public immutable decimals;

    /*///////////////////////////////////////////////////////////////
                              ERC20 STORAGE
    //////////////////////////////////////////////////////////////*/

    uint256 public totalSupply;

    mapping(address => uint256) public balanceOf;

    mapping(address => mapping(address => uint256)) public allowance;

    /*///////////////////////////////////////////////////////////////
                             EIP-2612 STORAGE
    //////////////////////////////////////////////////////////////*/

    bytes32 public constant PERMIT_TYPEHASH =
        keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");

    uint256 internal immutable INITIAL_CHAIN_ID;

    bytes32 internal immutable INITIAL_DOMAIN_SEPARATOR;

    mapping(address => uint256) public nonces;

    /*///////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(
        string memory _name,
        string memory _symbol,
        uint8 _decimals
    ) {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;

        INITIAL_CHAIN_ID = block.chainid;
        INITIAL_DOMAIN_SEPARATOR = computeDomainSeparator();
    }

    /*///////////////////////////////////////////////////////////////
                              ERC20 LOGIC
    //////////////////////////////////////////////////////////////*/

    function approve(address spender, uint256 amount) public virtual returns (bool) {
        allowance[msg.sender][spender] = amount;

        emit Approval(msg.sender, spender, amount);

        return true;
    }

    function transfer(address to, uint256 amount) public virtual returns (bool) {
        balanceOf[msg.sender] -= amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(msg.sender, to, amount);

        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual returns (bool) {
        uint256 allowed = allowance[from][msg.sender]; // Saves gas for limited approvals.

        if (allowed != type(uint256).max) allowance[from][msg.sender] = allowed - amount;

        balanceOf[from] -= amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(from, to, amount);

        return true;
    }

    /*///////////////////////////////////////////////////////////////
                              EIP-2612 LOGIC
    //////////////////////////////////////////////////////////////*/

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public virtual {
        require(deadline >= block.timestamp, "PERMIT_DEADLINE_EXPIRED");

        // Unchecked because the only math done is incrementing
        // the owner's nonce which cannot realistically overflow.
        unchecked {
            bytes32 digest = keccak256(
                abi.encodePacked(
                    "\x19\x01",
                    DOMAIN_SEPARATOR(),
                    keccak256(abi.encode(PERMIT_TYPEHASH, owner, spender, value, nonces[owner]++, deadline))
                )
            );

            address recoveredAddress = ecrecover(digest, v, r, s);

            require(recoveredAddress != address(0) && recoveredAddress == owner, "INVALID_SIGNER");

            allowance[recoveredAddress][spender] = value;
        }

        emit Approval(owner, spender, value);
    }

    function DOMAIN_SEPARATOR() public view virtual returns (bytes32) {
        return block.chainid == INITIAL_CHAIN_ID ? INITIAL_DOMAIN_SEPARATOR : computeDomainSeparator();
    }

    function computeDomainSeparator() internal view virtual returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                    keccak256(bytes(name)),
                    keccak256("1"),
                    block.chainid,
                    address(this)
                )
            );
    }

    /*///////////////////////////////////////////////////////////////
                       INTERNAL MINT/BURN LOGIC
    //////////////////////////////////////////////////////////////*/

    function _mint(address to, uint256 amount) internal virtual {
        totalSupply += amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(address(0), to, amount);
    }

    function _burn(address from, uint256 amount) internal virtual {
        balanceOf[from] -= amount;

        // Cannot underflow because a user's balance
        // will never be larger than the total supply.
        unchecked {
            totalSupply -= amount;
        }

        emit Transfer(from, address(0), amount);
    }
}


// File @rari-capital/solmate/src/utils/[email protected]




/// @notice Safe ETH and ERC20 transfer library that gracefully handles missing return values.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/utils/SafeTransferLib.sol)
/// @author Modified from Gnosis (https://github.com/gnosis/gp-v2-contracts/blob/main/src/contracts/libraries/GPv2SafeERC20.sol)
/// @dev Use with caution! Some functions in this library knowingly create dirty bits at the destination of the free memory pointer.
library SafeTransferLib {
    /*///////////////////////////////////////////////////////////////
                            ETH OPERATIONS
    //////////////////////////////////////////////////////////////*/

    function safeTransferETH(address to, uint256 amount) internal {
        bool callStatus;

        assembly {
            // Transfer the ETH and store if it succeeded or not.
            callStatus := call(gas(), to, amount, 0, 0, 0, 0)
        }

        require(callStatus, "ETH_TRANSFER_FAILED");
    }

    /*///////////////////////////////////////////////////////////////
                           ERC20 OPERATIONS
    //////////////////////////////////////////////////////////////*/

    function safeTransferFrom(
        ERC20 token,
        address from,
        address to,
        uint256 amount
    ) internal {
        bool callStatus;

        assembly {
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata to memory piece by piece:
            mstore(freeMemoryPointer, 0x23b872dd00000000000000000000000000000000000000000000000000000000) // Begin with the function selector.
            mstore(add(freeMemoryPointer, 4), and(from, 0xffffffffffffffffffffffffffffffffffffffff)) // Mask and append the "from" argument.
            mstore(add(freeMemoryPointer, 36), and(to, 0xffffffffffffffffffffffffffffffffffffffff)) // Mask and append the "to" argument.
            mstore(add(freeMemoryPointer, 68), amount) // Finally append the "amount" argument. No mask as it's a full 32 byte value.

            // Call the token and store if it succeeded or not.
            // We use 100 because the calldata length is 4 + 32 * 3.
            callStatus := call(gas(), token, 0, freeMemoryPointer, 100, 0, 0)
        }

        require(didLastOptionalReturnCallSucceed(callStatus), "TRANSFER_FROM_FAILED");
    }

    function safeTransfer(
        ERC20 token,
        address to,
        uint256 amount
    ) internal {
        bool callStatus;

        assembly {
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata to memory piece by piece:
            mstore(freeMemoryPointer, 0xa9059cbb00000000000000000000000000000000000000000000000000000000) // Begin with the function selector.
            mstore(add(freeMemoryPointer, 4), and(to, 0xffffffffffffffffffffffffffffffffffffffff)) // Mask and append the "to" argument.
            mstore(add(freeMemoryPointer, 36), amount) // Finally append the "amount" argument. No mask as it's a full 32 byte value.

            // Call the token and store if it succeeded or not.
            // We use 68 because the calldata length is 4 + 32 * 2.
            callStatus := call(gas(), token, 0, freeMemoryPointer, 68, 0, 0)
        }

        require(didLastOptionalReturnCallSucceed(callStatus), "TRANSFER_FAILED");
    }

    function safeApprove(
        ERC20 token,
        address to,
        uint256 amount
    ) internal {
        bool callStatus;

        assembly {
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata to memory piece by piece:
            mstore(freeMemoryPointer, 0x095ea7b300000000000000000000000000000000000000000000000000000000) // Begin with the function selector.
            mstore(add(freeMemoryPointer, 4), and(to, 0xffffffffffffffffffffffffffffffffffffffff)) // Mask and append the "to" argument.
            mstore(add(freeMemoryPointer, 36), amount) // Finally append the "amount" argument. No mask as it's a full 32 byte value.

            // Call the token and store if it succeeded or not.
            // We use 68 because the calldata length is 4 + 32 * 2.
            callStatus := call(gas(), token, 0, freeMemoryPointer, 68, 0, 0)
        }

        require(didLastOptionalReturnCallSucceed(callStatus), "APPROVE_FAILED");
    }

    /*///////////////////////////////////////////////////////////////
                         INTERNAL HELPER LOGIC
    //////////////////////////////////////////////////////////////*/

    function didLastOptionalReturnCallSucceed(bool callStatus) private pure returns (bool success) {
        assembly {
            // Get how many bytes the call returned.
            let returnDataSize := returndatasize()

            // If the call reverted:
            if iszero(callStatus) {
                // Copy the revert message into memory.
                returndatacopy(0, 0, returnDataSize)

                // Revert with the same message.
                revert(0, returnDataSize)
            }

            switch returnDataSize
            case 32 {
                // Copy the return data into memory.
                returndatacopy(0, 0, returnDataSize)

                // Set success to whether it returned true.
                success := iszero(iszero(mload(0)))
            }
            case 0 {
                // There was no return data.
                success := 1
            }
            default {
                // It returned some malformed input.
                success := 0
            }
        }
    }
}


// File @openzeppelin/contracts/utils/[email protected]

// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)


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


// File @openzeppelin/contracts/access/[email protected]

// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)


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


// File contracts/core/RLBTRFLY.sol

// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;




/// @title RLBTRFLY
/// @author ████

/**
    @notice
    Partially adapted from Convex's CvxLockerV2 contract with some modifications and optimizations for the BTRFLY V2 requirements
*/

contract RLBTRFLY is ReentrancyGuard, Ownable {
    using SafeTransferLib for ERC20;

    /**
        @notice Lock balance details
        @param  amount      uint224  Locked amount in the lock
        @param  unlockTime  uint32   Unlock time of the lock
     */
    struct LockedBalance {
        uint224 amount;
        uint32 unlockTime;
    }

    /**
        @notice Balance details
        @param  locked           uint224          Overall locked amount
        @param  nextUnlockIndex  uint32           Index of earliest next unlock
        @param  lockedBalances   LockedBalance[]  List of locked balances data
     */
    struct Balance {
        uint224 locked;
        uint32 nextUnlockIndex;
        LockedBalance[] lockedBalances;
    }

    // 1 epoch = 1 week
    uint32 public constant EPOCH_DURATION = 1 weeks;
    // Full lock duration = 16 epochs
    uint256 public constant LOCK_DURATION = 16 * EPOCH_DURATION;

    ERC20 public immutable btrflyV2;

    uint256 public lockedSupply;

    mapping(address => Balance) public balances;

    bool public isShutdown;

    string public constant name = "Revenue-Locked BTRFLY";
    string public constant symbol = "rlBTRFLY";
    uint8 public constant decimals = 18;

    event Shutdown();
    event Locked(
        address indexed account,
        uint256 indexed epoch,
        uint256 amount
    );
    event Withdrawn(address indexed account, uint256 amount, bool relock);

    error ZeroAddress();
    error ZeroAmount();
    error IsShutdown();
    error InvalidNumber(uint256 value);

    /**
        @param  _btrflyV2  address  BTRFLYV2 token address
     */
    constructor(address _btrflyV2) {
        if (_btrflyV2 == address(0)) revert ZeroAddress();
        btrflyV2 = ERC20(_btrflyV2);
    }

    /**
        @notice Emergency method to shutdown the current locker contract which also force-unlock all locked tokens
     */
    function shutdown() external onlyOwner {
        if (isShutdown) revert IsShutdown();

        isShutdown = true;

        emit Shutdown();
    }

    /**
        @notice Locked balance of the specified account including those with expired locks
        @param  account  address  Account
        @return amount   uint256  Amount
     */
    function lockedBalanceOf(address account)
        external
        view
        returns (uint256 amount)
    {
        return balances[account].locked;
    }

    /**
        @notice Balance of the specified account by only including tokens in active locks
        @param  account  address  Account
        @return amount   uint256  Amount
     */
    function balanceOf(address account) external view returns (uint256 amount) {
        // Using storage as it's actually cheaper than allocating a new memory based variable
        Balance storage userBalance = balances[account];
        LockedBalance[] storage locks = userBalance.lockedBalances;
        uint256 nextUnlockIndex = userBalance.nextUnlockIndex;

        amount = balances[account].locked;

        uint256 locksLength = locks.length;

        // Skip all old records
        for (uint256 i = nextUnlockIndex; i < locksLength; ++i) {
            if (locks[i].unlockTime <= block.timestamp) {
                amount -= locks[i].amount;
            } else {
                break;
            }
        }

        // Remove amount locked in the next epoch
        if (
            locksLength > 0 &&
            uint256(locks[locksLength - 1].unlockTime) - LOCK_DURATION >
            getCurrentEpoch()
        ) {
            amount -= locks[locksLength - 1].amount;
        }

        return amount;
    }

    /**
        @notice Pending locked amount at the specified account
        @param  account  address  Account
        @return amount   uint256  Amount
     */
    function pendingLockOf(address account)
        external
        view
        returns (uint256 amount)
    {
        LockedBalance[] storage locks = balances[account].lockedBalances;

        uint256 locksLength = locks.length;

        if (
            locksLength > 0 &&
            uint256(locks[locksLength - 1].unlockTime) - LOCK_DURATION >
            getCurrentEpoch()
        ) {
            return locks[locksLength - 1].amount;
        }

        return 0;
    }

    /**
        @notice Locked balances details for the specifed account
        @param  account     address          Account
        @return total       uint256          Total amount
        @return unlockable  uint256          Unlockable amount
        @return locked      uint256          Locked amount
        @return lockData    LockedBalance[]  List of active locks
     */
    function lockedBalances(address account)
        external
        view
        returns (
            uint256 total,
            uint256 unlockable,
            uint256 locked,
            LockedBalance[] memory lockData
        )
    {
        Balance storage userBalance = balances[account];
        LockedBalance[] storage locks = userBalance.lockedBalances;
        uint256 nextUnlockIndex = userBalance.nextUnlockIndex;
        uint256 idx;

        for (uint256 i = nextUnlockIndex; i < locks.length; ++i) {
            if (locks[i].unlockTime > block.timestamp) {
                if (idx == 0) {
                    lockData = new LockedBalance[](locks.length - i);
                }

                lockData[idx] = locks[i];
                locked += lockData[idx].amount;
                ++idx;
            } else {
                unlockable += locks[i].amount;
            }
        }

        return (userBalance.locked, unlockable, locked, lockData);
    }

    /**
        @notice Get current epoch
        @return uint256  Current epoch
     */
    function getCurrentEpoch() public view returns (uint256) {
        return (block.timestamp / EPOCH_DURATION) * EPOCH_DURATION;
    }

    /**
        @notice Locked tokens cannot be withdrawn for the entire lock duration and are eligible to receive rewards
        @param  account  address  Account
        @param  amount   uint256  Amount
     */
    function lock(address account, uint256 amount) external nonReentrant {
        if (account == address(0)) revert ZeroAddress();
        if (amount == 0) revert ZeroAmount();

        btrflyV2.safeTransferFrom(msg.sender, address(this), amount);

        _lock(account, amount);
    }

    /**
        @notice Perform the actual lock
        @param  account  address  Account
        @param  amount   uint256  Amount
     */
    function _lock(address account, uint256 amount) internal {
        if (isShutdown) revert IsShutdown();

        Balance storage balance = balances[account];

        uint224 lockAmount = _toUint224(amount);

        balance.locked += lockAmount;
        lockedSupply += lockAmount;

        uint256 lockEpoch = getCurrentEpoch() + EPOCH_DURATION;
        uint256 unlockTime = lockEpoch + LOCK_DURATION;
        LockedBalance[] storage locks = balance.lockedBalances;
        uint256 idx = locks.length;

        // If the latest user lock is smaller than this lock, add a new entry to the end of the list
        // else, append it to the latest user lock
        if (idx == 0 || locks[idx - 1].unlockTime < unlockTime) {
            locks.push(
                LockedBalance({
                    amount: lockAmount,
                    unlockTime: _toUint32(unlockTime)
                })
            );
        } else {
            locks[idx - 1].amount += lockAmount;
        }

        emit Locked(account, lockEpoch, amount);
    }

    /**
        @notice Withdraw all currently locked tokens where the unlock time has passed
        @param  account     address  Account
        @param  relock      bool     Whether should relock
        @param  withdrawTo  address  Target receiver
     */
    function _processExpiredLocks(
        address account,
        bool relock,
        address withdrawTo
    ) internal {
        // Using storage as it's actually cheaper than allocating a new memory based variable
        Balance storage userBalance = balances[account];
        LockedBalance[] storage locks = userBalance.lockedBalances;
        uint224 locked;
        uint256 length = locks.length;

        if (isShutdown || locks[length - 1].unlockTime <= block.timestamp) {
            locked = userBalance.locked;
            userBalance.nextUnlockIndex = _toUint32(length);
        } else {
            // Using nextUnlockIndex to reduce the number of loops
            uint32 nextUnlockIndex = userBalance.nextUnlockIndex;

            for (uint256 i = nextUnlockIndex; i < length; ++i) {
                // Unlock time must be less or equal to time
                if (locks[i].unlockTime > block.timestamp) break;

                // Add to cumulative amounts
                locked += locks[i].amount;
                ++nextUnlockIndex;
            }

            // Update the account's next unlock index
            userBalance.nextUnlockIndex = nextUnlockIndex;
        }

        if (locked == 0) revert ZeroAmount();

        // Update user balances and total supplies
        userBalance.locked -= locked;
        lockedSupply -= locked;

        emit Withdrawn(account, locked, relock);

        // Relock or return to user
        if (relock) {
            _lock(withdrawTo, locked);
        } else {
            btrflyV2.safeTransfer(withdrawTo, locked);
        }
    }

    /**
        @notice Withdraw expired locks to a different address
        @param  to  address  Target receiver
     */
    function withdrawExpiredLocksTo(address to) external nonReentrant {
        if (to == address(0)) revert ZeroAddress();

        _processExpiredLocks(msg.sender, false, to);
    }

    /**
        @notice Withdraw/relock all currently locked tokens where the unlock time has passed
        @param  relock  bool  Whether should relock
     */
    function processExpiredLocks(bool relock) external nonReentrant {
        _processExpiredLocks(msg.sender, relock, msg.sender);
    }

    /**
        @notice Validate and cast a uint256 integer to uint224
        @param  value  uint256  Value
        @return        uint224  Casted value
     */
    function _toUint224(uint256 value) internal pure returns (uint224) {
        if (value > type(uint224).max) revert InvalidNumber(value);

        return uint224(value);
    }

    /**
        @notice Validate and cast a uint256 integer to uint32
        @param  value  uint256  Value
        @return        uint32   Casted value
     */
    function _toUint32(uint256 value) internal pure returns (uint32) {
        if (value > type(uint32).max) revert InvalidNumber(value);

        return uint32(value);
    }
}