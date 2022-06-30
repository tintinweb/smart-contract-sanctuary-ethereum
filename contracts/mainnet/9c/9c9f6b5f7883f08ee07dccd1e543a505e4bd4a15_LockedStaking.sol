/**
 *Submitted for verification at Etherscan.io on 2022-06-30
*/

//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.10;

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// OpenZeppelin Contracts (last updated v4.6.0) (proxy/utils/Initializable.sol)

// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * The initialization functions use a version number. Once a version number is used, it is consumed and cannot be
 * reused. This mechanism prevents re-execution of each "step" but allows the creation of new initialization steps in
 * case an upgrade adds a module that needs to be initialized.
 *
 * For example:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
 * contract MyTokenV2 is MyToken, ERC20PermitUpgradeable {
 *     function initializeV2() reinitializer(2) public {
 *         __ERC20Permit_init("MyToken");
 *     }
 * }
 * ```
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To prevent the implementation contract from being used, you should invoke
 * the {_disableInitializers} function in the constructor to automatically lock it when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() {
 *     _disableInitializers();
 * }
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     * @custom:oz-retyped-from bool
     */
    uint8 private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Triggered when the contract has been initialized or reinitialized.
     */
    event Initialized(uint8 version);

    /**
     * @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
     * `onlyInitializing` functions can be used to initialize parent contracts. Equivalent to `reinitializer(1)`.
     */
    modifier initializer() {
        bool isTopLevelCall = _setInitializedVersion(1);
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(1);
        }
    }

    /**
     * @dev A modifier that defines a protected reinitializer function that can be invoked at most once, and only if the
     * contract hasn't been initialized to a greater version before. In its scope, `onlyInitializing` functions can be
     * used to initialize parent contracts.
     *
     * `initializer` is equivalent to `reinitializer(1)`, so a reinitializer may be used after the original
     * initialization step. This is essential to configure modules that are added through upgrades and that require
     * initialization.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     */
    modifier reinitializer(uint8 version) {
        bool isTopLevelCall = _setInitializedVersion(version);
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(version);
        }
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} and {reinitializer} modifiers, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    /**
     * @dev Locks the contract, preventing any future reinitialization. This cannot be part of an initializer call.
     * Calling this in the constructor of a contract will prevent that contract from being initialized or reinitialized
     * to any version. It is recommended to use this to lock implementation contracts that are designed to be called
     * through proxies.
     */
    function _disableInitializers() internal virtual {
        _setInitializedVersion(type(uint8).max);
    }

    function _setInitializedVersion(uint8 version) private returns (bool) {
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, and for the lowest level
        // of initializers, because in other contexts the contract may have been reentered.
        if (_initializing) {
            require(
                version == 1 && !AddressUpgradeable.isContract(address(this)),
                "Initializable: contract is already initialized"
            );
            return false;
        } else {
            require(_initialized < version, "Initializable: contract is already initialized");
            _initialized = version;
            return true;
        }
    }
}

// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal onlyInitializing {
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

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
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal onlyInitializing {
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal onlyInitializing {
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

contract LockedStaking is Initializable, OwnableUpgradeable {
    /*///////////////////////////////////////////////////////////////
                                  EVENTS
    //////////////////////////////////////////////////////////////*/
    event LockAdded(address indexed from, uint208 amount, uint32 end, uint16 multiplier);
    event LockUpdated(address indexed from, uint8 index, uint208 amount, uint32 end, uint16 multiplier);
    event Unlock(address indexed from, uint256 amount, uint256 index);
    event Claim(address indexed from, uint256 amount);
    event RewardAdded(uint256 start, uint256 end, uint256 amountPerSecond);
    event RewardUpdated(uint256 index, uint256 start, uint256 end, uint256 amountPerSecond);
    event RewardRemoved(uint256 index);

    /*///////////////////////////////////////////////////////////////
                                  ERRORS
    //////////////////////////////////////////////////////////////*/
    error MustProlongLock(uint256 oldDuration, uint256 newDuration);
    error AmountIsZero();
    error TransferFailed();
    error NothingToClaim();
    error LockStillActive();
    error IndexOutOfBounds(uint256 index, uint256 length);
    error DurationOutOfBounds(uint256 duration);
    error UpdateToSmallerMultiplier(uint16 oldMultiplier, uint16 newMultiplier);
    error ZeroAddress();
    error ZeroPrecision();
    error MaxLocksSucceeded();
    error MaxRewardsSucceeded();
    error CanOnlyAddFutureRewards();

    /*///////////////////////////////////////////////////////////////
                             IMMUTABLES & CONSTANTS
    //////////////////////////////////////////////////////////////*/
    IERC20 public swapToken;
    uint256 public precision;
    uint256 public constant MAX_LOCK_COUNT = 5;
    uint256 public constant MAX_REWARD_COUNT = 5;

    /*///////////////////////////////////////////////////////////////
                             STRUCTS
    //////////////////////////////////////////////////////////////*/
    struct Lock {
        uint16 multiplier;
        uint32 end;
        uint208 amount;
    }

    struct Reward {
        uint32 start;
        uint32 end;
        uint192 amountPerSecond;
    }

    /*///////////////////////////////////////////////////////////////
                             STORAGE
    //////////////////////////////////////////////////////////////*/
    Reward[] public rewards;
    mapping(address => Lock[]) public locks;
    mapping(address => uint256) public userLastAccRewardsWeight;

    uint256 public lastRewardUpdate;
    uint256 public totalScore;
    uint256 public accRewardWeight;

    function initialize(address _swapToken, uint256 _precision) external initializer {
        if (_swapToken == address(0)) revert ZeroAddress();
        if (_precision == 0) revert ZeroPrecision();

        swapToken = IERC20(_swapToken);
        precision = _precision;

        __Ownable_init();
    }

    function getRewardsLength() external view returns (uint256) {
        return rewards.length;
    }

    function getLockInfo(address addr, uint256 index) external view returns (Lock memory) {
        return locks[addr][index];
    }

    function getUserLocks(address addr) external view returns (Lock[] memory) {
        return locks[addr];
    }

    function getLockLength(address addr) external view returns (uint256) {
        return locks[addr].length;
    }

    function getRewards() external view returns (Reward[] memory) {
        return rewards;
    }

    function addReward(
        uint32 start,
        uint32 end,
        uint192 amountPerSecond
    ) external onlyOwner {
        if (rewards.length == MAX_REWARD_COUNT) revert MaxRewardsSucceeded();
        if (amountPerSecond == 0) revert AmountIsZero();
        if (start < block.timestamp || end < block.timestamp) revert CanOnlyAddFutureRewards();

        rewards.push(Reward(start, end, amountPerSecond));

        if (!IERC20(swapToken).transferFrom(msg.sender, address(this), (end - start) * amountPerSecond))
            revert TransferFailed();

        emit RewardAdded(start, end, amountPerSecond);
    }

    function removeReward(uint256 index) external onlyOwner {
        updateRewardsWeight();

        Reward memory reward = rewards[index];

        rewards[index] = rewards[rewards.length - 1];
        rewards.pop();

        // if rewards are not unlocked completely, send remaining to owner
        if (reward.end > block.timestamp) {
            uint256 lockedRewards = (reward.end - max(block.timestamp, reward.start)) * reward.amountPerSecond;

            if (!IERC20(swapToken).transfer(msg.sender, lockedRewards)) revert TransferFailed();
        }

        emit RewardRemoved(index);
    }

    function updateReward(
        uint256 index,
        uint256 start,
        uint256 end,
        uint256 amountPerSecond
    ) external onlyOwner {
        uint256 newRewards = (end - start) * amountPerSecond;

        Reward storage reward = rewards[index];
        uint256 oldStart = reward.start;
        uint256 oldEnd = reward.end;

        uint256 oldRewards = (oldEnd - oldStart) * reward.amountPerSecond;

        uint32 newStart = uint32(min(oldStart, start));
        uint32 newEnd = uint32(max(oldEnd, end));
        uint192 newAmountPerSecond = uint192((newRewards + oldRewards) / (newEnd - newStart));

        reward.start = newStart;
        reward.end = newEnd;
        reward.amountPerSecond = newAmountPerSecond;

        if (!IERC20(swapToken).transferFrom(msg.sender, address(this), newRewards)) revert TransferFailed();

        emit RewardUpdated(index, newStart, newEnd, newAmountPerSecond);
    }

    // claims for current locks and creates new lock
    function addLock(uint208 amount, uint256 duration) external {
        if (amount == 0) revert AmountIsZero();
        if (locks[msg.sender].length == MAX_LOCK_COUNT) revert MaxLocksSucceeded();

        uint256 newAccRewardsWeight = updateRewardsWeight();

        uint256 claimable = calculateUserClaimable(msg.sender, newAccRewardsWeight);

        userLastAccRewardsWeight[msg.sender] = newAccRewardsWeight;

        uint32 end = uint32(block.timestamp + duration);
        uint16 multiplier = getDurationMultiplier(duration);

        locks[msg.sender].push(Lock(multiplier, end, amount));

        totalScore += multiplier * amount;

        if (claimable < amount) {
            if (!IERC20(swapToken).transferFrom(msg.sender, address(this), amount - claimable)) revert TransferFailed();
        }

        if (claimable > amount) {
            if (!IERC20(swapToken).transfer(msg.sender, claimable - amount)) revert TransferFailed();
        }

        if (claimable > 0) {
            emit Claim(msg.sender, claimable);
        }

        emit LockAdded(msg.sender, amount, end, multiplier);
    }

    // adds claimable to current lock, keeping the same end
    function compound(uint8 index) external {
        uint256 newAccRewardsWeight = updateRewardsWeight();

        uint256 claimable = calculateUserClaimable(msg.sender, newAccRewardsWeight);
        if (claimable == 0) revert NothingToClaim();

        userLastAccRewardsWeight[msg.sender] = newAccRewardsWeight;

        Lock storage lock = locks[msg.sender][index];
        uint208 newAmount = uint208(lock.amount + claimable);
        uint16 multiplier = lock.multiplier;

        lock.amount = newAmount;
        totalScore += claimable * multiplier;

        emit Claim(msg.sender, claimable);

        emit LockUpdated(msg.sender, index, newAmount, lock.end, multiplier);
    }

    // claims for current lock and adds amount to existing lock, keeping the same end
    function updateLockAmount(uint256 index, uint208 amount) external {
        if (amount == 0) revert AmountIsZero();

        uint256 newAccRewardsWeight = updateRewardsWeight();

        Lock storage lock = locks[msg.sender][index];
        uint208 newAmount = lock.amount + amount;
        uint16 multiplier = lock.multiplier;

        uint256 claimable = calculateUserClaimable(msg.sender, newAccRewardsWeight);

        userLastAccRewardsWeight[msg.sender] = newAccRewardsWeight;

        lock.amount = newAmount;

        totalScore += amount * multiplier;

        if (claimable < amount) {
            if (!IERC20(swapToken).transferFrom(msg.sender, address(this), amount - claimable)) revert TransferFailed();
        }
        if (claimable > amount) {
            if (!IERC20(swapToken).transfer(msg.sender, claimable - amount)) revert TransferFailed();
        }

        if (claimable > 0) {
            emit Claim(msg.sender, claimable);
        }

        emit LockUpdated(msg.sender, uint8(index), newAmount, lock.end, multiplier);
    }

    // claims for current locks and increases duration of existing lock
    function updateLockDuration(uint8 index, uint256 duration) external {
        uint256 newAccRewardsWeight = updateRewardsWeight();

        Lock storage lock = locks[msg.sender][index];

        uint32 end = uint32(block.timestamp + duration);
        if (lock.end > end) revert MustProlongLock(lock.end, end);

        uint256 claimable = calculateUserClaimable(msg.sender, newAccRewardsWeight);

        userLastAccRewardsWeight[msg.sender] = newAccRewardsWeight;

        uint16 multiplier = getDurationMultiplier(duration);

        lock.end = end;

        uint16 oldMultiplier = lock.multiplier;

        if (oldMultiplier > multiplier) revert UpdateToSmallerMultiplier(oldMultiplier, multiplier);

        lock.multiplier = multiplier;

        uint208 amount = lock.amount;
        totalScore += (multiplier - oldMultiplier) * amount;

        if (claimable > 0) {
            if (!IERC20(swapToken).transfer(msg.sender, claimable)) revert TransferFailed();

            emit Claim(msg.sender, claimable);
        }

        emit LockUpdated(msg.sender, index, amount, end, multiplier);
    }

    // updates rewards weight & returns users claimable amount
    function getUserClaimable(address user) external view returns (uint256 claimable) {
        uint256 accRewardsWeight = getRewardsWeight();

        return calculateUserClaimable(user, accRewardsWeight);
    }

    // returns users claimable amount
    function calculateUserClaimable(address user, uint256 accRewardsWeight_) internal view returns (uint256 claimable) {
        uint256 userScore = getUsersTotalScore(user);

        return (userScore * (accRewardsWeight_ - userLastAccRewardsWeight[user])) / precision;
    }

    // returns users score for all locks
    function getUsersTotalScore(address user) public view returns (uint256 score) {
        uint256 lockLength = locks[user].length;
        Lock storage lock;
        for (uint256 lockId = 0; lockId < lockLength; ++lockId) {
            lock = locks[user][lockId];
            score += lock.amount * lock.multiplier;
        }
    }

    // claims for current locks
    function claim() external {
        uint256 newAccRewardsWeight = updateRewardsWeight();

        uint256 claimable = calculateUserClaimable(msg.sender, newAccRewardsWeight);
        if (claimable == 0) revert NothingToClaim();

        userLastAccRewardsWeight[msg.sender] = newAccRewardsWeight;

        if (!IERC20(swapToken).transfer(msg.sender, claimable)) revert TransferFailed();

        emit Claim(msg.sender, claimable);
    }

    // returns locked amount to user and deletes lock from array
    function unlock(uint256 index) external {
        uint256 newAccRewardsWeight = updateRewardsWeight();
        Lock storage lock = locks[msg.sender][index];

        if (lock.end > block.timestamp) revert LockStillActive();

        uint256 amount = lock.amount;

        uint256 claimable = calculateUserClaimable(msg.sender, newAccRewardsWeight);

        userLastAccRewardsWeight[msg.sender] = newAccRewardsWeight;

        totalScore -= amount * lock.multiplier;

        locks[msg.sender][index] = locks[msg.sender][locks[msg.sender].length - 1];
        locks[msg.sender].pop();

        if (!IERC20(swapToken).transfer(msg.sender, amount + claimable)) revert TransferFailed();

        if (claimable > 0) {
            emit Claim(msg.sender, claimable);
        }

        emit Unlock(msg.sender, amount, index);
    }

    // calculates and updates rewards weight
    function updateRewardsWeight() public returns (uint256) {
        // already updated
        if (block.timestamp == lastRewardUpdate) {
            return accRewardWeight;
        }

        uint256 newAccRewardsWeight = getRewardsWeight();

        if (newAccRewardsWeight > 0) {
            lastRewardUpdate = block.timestamp;
            accRewardWeight = newAccRewardsWeight;
        }

        return newAccRewardsWeight;
    }

    // calculates rewards weight
    function getRewardsWeight() public view returns (uint256) {
        // to avoid div by zero on first lock
        if (totalScore == 0) {
            return 0;
        }

        uint256 _lastRewardUpdate = lastRewardUpdate;

        uint256 length = rewards.length;
        uint256 newRewards;
        for (uint256 rewardId = 0; rewardId < length; ++rewardId) {
            Reward storage reward = rewards[rewardId];
            uint256 start = reward.start;
            uint256 end = reward.end;

            if (block.timestamp < start) continue;
            if (_lastRewardUpdate > end) continue;

            newRewards += (min(block.timestamp, end) - max(start, _lastRewardUpdate)) * reward.amountPerSecond;
        }

        return newRewards == 0 ? accRewardWeight : accRewardWeight + (newRewards * precision) / totalScore;
    }

    function min(uint256 x, uint256 y) internal pure returns (uint256 z) {
        return x < y ? x : y;
    }

    function max(uint256 x, uint256 y) internal pure returns (uint256 z) {
        return x > y ? x : y;
    }

    // returns multiplier(2 decimals) on amount locked for duration in seconds
    // aprox of function (2592000,1),(31536000,2),(94608000,5),(157680000,10)
    // 2.22574×10^-16 x^2 + 2.19094×10^-8 x + 0.993975
    function getDurationMultiplier(uint256 duration) public pure returns (uint16) {
        if (duration < 30 days || duration > 1825 days) revert DurationOutOfBounds(duration);

        return uint16((222574 * duration * duration + 21909400000000 * duration + 993975000000000000000) / 1e19);
    }
}