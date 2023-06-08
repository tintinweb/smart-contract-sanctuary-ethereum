/**
 *Submitted for verification at Etherscan.io on 2023-06-08
*/

// File: @openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol


// OpenZeppelin Contracts (last updated v4.9.0) (utils/Address.sol)

pragma solidity ^0.8.1;

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
     *
     * Furthermore, `isContract` will also return true if the target contract within
     * the same transaction is already scheduled for destruction by `SELFDESTRUCT`,
     * which only has an effect at the end of a transaction.
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
     * https://consensys.net/diligence/blog/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.8.0/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
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
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
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
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
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
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
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
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
     * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
     *
     * _Available since v4.8._
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason or using the provided one.
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
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
        // Look for revert reason and bubble it up if present
        if (returndata.length > 0) {
            // The easiest way to bubble the revert reason is using memory via assembly
            /// @solidity memory-safe-assembly
            assembly {
                let returndata_size := mload(returndata)
                revert(add(32, returndata), returndata_size)
            }
        } else {
            revert(errorMessage);
        }
    }
}

// File: @openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol


// OpenZeppelin Contracts (last updated v4.9.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;


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
 * ```solidity
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
 *
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
     * `onlyInitializing` functions can be used to initialize parent contracts.
     *
     * Similar to `reinitializer(1)`, except that functions marked with `initializer` can be nested in the context of a
     * constructor.
     *
     * Emits an {Initialized} event.
     */
    modifier initializer() {
        bool isTopLevelCall = !_initializing;
        require(
            (isTopLevelCall && _initialized < 1) || (!AddressUpgradeable.isContract(address(this)) && _initialized == 1),
            "Initializable: contract is already initialized"
        );
        _initialized = 1;
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
     * A reinitializer may be used after the original initialization step. This is essential to configure modules that
     * are added through upgrades and that require initialization.
     *
     * When `version` is 1, this modifier is similar to `initializer`, except that functions marked with `reinitializer`
     * cannot be nested. If one is invoked in the context of another, execution will revert.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     *
     * WARNING: setting the version to 255 will prevent any future reinitialization.
     *
     * Emits an {Initialized} event.
     */
    modifier reinitializer(uint8 version) {
        require(!_initializing && _initialized < version, "Initializable: contract is already initialized");
        _initialized = version;
        _initializing = true;
        _;
        _initializing = false;
        emit Initialized(version);
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
     *
     * Emits an {Initialized} event the first time it is successfully executed.
     */
    function _disableInitializers() internal virtual {
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized != type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }

    /**
     * @dev Returns the highest version that has been initialized. See {reinitializer}.
     */
    function _getInitializedVersion() internal view returns (uint8) {
        return _initialized;
    }

    /**
     * @dev Returns `true` if the contract is currently initializing. See {onlyInitializing}.
     */
    function _isInitializing() internal view returns (bool) {
        return _initializing;
    }
}

// File: @openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol


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

// File: @openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol


// OpenZeppelin Contracts (last updated v4.9.0) (access/Ownable.sol)

pragma solidity ^0.8.0;



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
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby disabling any functionality that is only available to the owner.
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

// File: Staking.sol

//SPDX-License-Identifier: MIT
pragma solidity 0.8.13;


library TransferHelper {
    function safeApprove(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) =
            token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "TransferHelper::safeApprove: approve failed"
        );
    }

    function safeTransfer(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) =
            token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "TransferHelper::safeTransfer: transfer failed"
        );
    }

    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) =
            token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "TransferHelper::transferFrom: transferFrom failed"
        );
    }

    function safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(
            success,
            "TransferHelper::safeTransferETH: ETH transfer failed"
        );
    }
}


contract UnimoonStaking is OwnableUpgradeable {
    uint256 internal constant WEIGHT_MULTIPLIER = 1e6;
    uint256 internal constant MIN_STAKE_PERIOD = 1 days;
    uint256 internal constant MAX_STAKE_PERIOD = 365 days;
    uint256 internal constant REWARD_PER_WEIGHT_MULTIPLIER = 1e32;
    uint256 internal constant DENOMINATOR = 100;

    address public REWARD_TOKEN;

    address public treasury;
    PoolInfo[2] public poolInfo;
    GeneralInfo public generalInfo;

    mapping(uint256 => mapping(address => UserStat)) public userStat;
    mapping(uint256 => mapping(address => Data[])) public userInfo;

    struct GeneralInfo {
        uint256 totalAllocPoint;
        uint256 totalWeight;
    }

    struct PoolInfo {
        address token;
        uint256 allocPoint;
        uint256 accPerShare;
        uint256 totalWeight;
        uint256 totalStaked;
    }

    struct Data {
        uint256 value;
        uint64 lockedFrom;
        uint64 lockedUntil;
        uint256 weight;
        uint256 lastAccValue;
        uint256 pendingYield;
    }

    struct UserStat {
        uint256 totalStaked;
        uint256 totalClaimed;
    }

    event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event ClaimRewards(
        address indexed user,
        uint256 indexed pid,
        uint256 amount
    );
    event PoolUpdated(uint8 pid, address token, uint256 allocPoint);

    modifier poolExist(uint256 _pid) {
        require(_pid < poolInfo.length, "UnimoonStaking: wrong pool ID");
        _;
    }

    /** @dev one-time used moethod instead of constructor
     * @notice available for initializer only
     * @param tokens an array of 0 - unimoon, 1 - lp, 2 - usdc token addresses
     * @param points an array of pools allocation points
     * @param owner address
     */
    function initialize(
        address[3] memory tokens,
        uint256[2] memory points,
        address owner
    ) public initializer {
        require(
            tokens[0] != address(0) &&
                tokens[1] != address(0) &&
                tokens[2] != address(0) &&
                owner != address(0),
            "UnimoonStaking: address 0x00..."
        );
        require(
            points[0] > 0 && points[1] > 0,
            "UnimoonStaking: zero allocation"
        );
        REWARD_TOKEN = tokens[2];
        poolInfo[0].token = tokens[0];
        poolInfo[0].allocPoint = points[0];
        poolInfo[1].token = tokens[1];
        poolInfo[1].allocPoint = points[1];
        generalInfo.totalAllocPoint = points[0] + points[1];

        __Ownable_init();
        if (owner != _msgSender()) _transferOwnership(owner);
    }

    /** @dev View function to see weight amount according to the staked value and lock duration
     * @param value staked value
     * @param duration lock duration
     * @return weight
     */
    function valueToWeight(uint256 value, uint256 duration)
        public
        pure
        returns (uint256)
    {
        return
            value *
            ((duration * WEIGHT_MULTIPLIER) /
                MAX_STAKE_PERIOD +
                WEIGHT_MULTIPLIER);
    }

    /** @dev View function to see all user's stakes at the current pool
     * @param user address
     * @param pid pool ID
     * @return all user's stakes info at the current pool
     */
    function getUserStakes(address user, uint256 pid)
        external
        view
        returns (Data[] memory)
    {
        return userInfo[pid][user];
    }

    /** @dev View function to get user’s pending rewards in current pool
     * @param user user address
     * @param pid pool id
     * @param stakeId index in array of deposits
     * @return earned rewards
     */
    function pendingRewardPerDeposit(
        address user,
        uint8 pid,
        uint256 stakeId
    ) public view returns (uint256) {
        if (stakeId >= userInfo[pid][user].length) return 0;
        else
            return
                userInfo[pid][user][stakeId].pendingYield +
                (((poolInfo[pid].accPerShare -
                    userInfo[pid][user][stakeId].lastAccValue) *
                    userInfo[pid][user][stakeId].weight) /
                    REWARD_PER_WEIGHT_MULTIPLIER);
    }

    /** @dev View function to get deniminators (necessary to treasury contract)
     * @return total allocation point value
     * @return total weight of both pools
     */
    function getAllocAndWeight() external view returns (uint256, uint256) {
        return (generalInfo.totalAllocPoint, generalInfo.totalWeight);
    }

    /** @dev View function to get (totalEarned, totalClaimed, totalPending) values for both pools
     * @param user address
     * @return total earned value
     * @return total claimed value
     * @return total pending value
     */
    function getRewardTotalStat(address user)
        external
        view
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        uint256 totalPending;
        uint256 i;
        for (i; i < userInfo[0][user].length; i++) {
            totalPending += pendingRewardPerDeposit(user, 0, i);
        }
        for (i = 0; i < userInfo[1][user].length; i++) {
            totalPending += pendingRewardPerDeposit(user, 1, i);
        }
        return (
            totalPending +
                userStat[0][user].totalClaimed +
                userStat[1][user].totalClaimed,
            userStat[0][user].totalClaimed + userStat[1][user].totalClaimed,
            totalPending
        );
    }

    /** @dev Function to change treasury contract address
     * @notice available for owner only
     * @param _treasury new treasury contract address
     */
    function setTreasury(address _treasury) external onlyOwner {
        require(_treasury != address(0), "UnimoonStaking: address 0x0...");
        treasury = _treasury;
    }

    /** @dev Function to change pool weight (its possible to close pool by setting 0 allocation)
     * @notice available for owner only
     * @param _pid pool ID
     * @param _allocPoint new pool wight
     */
    function setAllocPoint(uint8 _pid, uint256 _allocPoint)
        external
        onlyOwner
        poolExist(_pid)
    {
        uint256 prevAllocPoint = poolInfo[_pid].allocPoint;
        poolInfo[_pid].allocPoint = _allocPoint;
        generalInfo.totalAllocPoint =
            generalInfo.totalAllocPoint -
            prevAllocPoint +
            _allocPoint;

        emit PoolUpdated(_pid, poolInfo[_pid].token, _allocPoint);
    }

    /** @dev Function to increase reward accumulators
     * @notice available for treasury only
     * @param amount reward amount to distribute
     */
    function increaseRewardPool(uint256 amount) external {
        require(_msgSender() == treasury, "UnimoonStaking: wrong sender");
        require(amount > 0, "UnimoonStaking: zero amount");
        require(
            generalInfo.totalAllocPoint > 0 && generalInfo.totalWeight > 0,
            "UnimoonStaking: zero denominator"
        );

        // to avoid division by zero
        if (poolInfo[0].totalWeight > 0 && poolInfo[1].totalWeight > 0) {
            poolInfo[0].accPerShare +=
                (((amount * poolInfo[0].allocPoint) /
                    generalInfo.totalAllocPoint) *
                    REWARD_PER_WEIGHT_MULTIPLIER) /
                poolInfo[0].totalWeight;
            poolInfo[1].accPerShare +=
                (((amount * poolInfo[1].allocPoint) /
                    generalInfo.totalAllocPoint) *
                    REWARD_PER_WEIGHT_MULTIPLIER) /
                poolInfo[1].totalWeight;
        } else if (poolInfo[0].totalWeight > 0) {
            poolInfo[0].accPerShare +=
                (amount * REWARD_PER_WEIGHT_MULTIPLIER) /
                poolInfo[0].totalWeight;
        } else {
            poolInfo[1].accPerShare +=
                (amount * REWARD_PER_WEIGHT_MULTIPLIER) /
                poolInfo[1].totalWeight;
        }
    }

    /** @dev Function to stake
     * @param pid pool id
     * @param amount to stake
     * @param duration lock duration
     */
    function deposit(
        uint8 pid,
        uint256 amount,
        uint32 duration
    ) external poolExist(pid) {
        require(amount > 0, "UnimoonStaking: zero amount");
        require(
            duration >= MIN_STAKE_PERIOD && duration <= MAX_STAKE_PERIOD,
            "UnimoonStaking: wrong duration"
        );

        PoolInfo storage pool = poolInfo[pid];

        uint256 stakeWeight = valueToWeight(amount, duration);

        userInfo[pid][_msgSender()].push(
            Data({
                value: amount,
                lockedFrom: uint64(block.timestamp),
                lockedUntil: uint64(block.timestamp + duration),
                weight: stakeWeight,
                lastAccValue: pool.accPerShare,
                pendingYield: 0
            })
        );
        userStat[pid][_msgSender()].totalStaked += amount;
        pool.totalWeight += stakeWeight;
        generalInfo.totalWeight += stakeWeight;
        pool.totalStaked += amount;

        TransferHelper.safeTransferFrom(
            pool.token,
            _msgSender(),
            address(this),
            amount
        );

        emit Deposit(_msgSender(), pid, amount);
    }

    /** @dev Function to unstake
     * @param pid pool id
     * @param stakeId an index of user's deposit in array of all user stakes
     * @param amount to unstake
     */
    function unstake(
        uint8 pid,
        uint256 stakeId,
        uint256 amount
    ) external poolExist(pid) {
        PoolInfo storage pool = poolInfo[pid];
        require(
            userInfo[pid][_msgSender()].length > stakeId,
            "UnimoonStaking: wrong stakeId"
        );
        Data storage stake = userInfo[pid][_msgSender()][stakeId];
        require(
            stake.lockedUntil <= block.timestamp,
            "UnimoonStaking: too early"
        );
        require(
            stake.value >= amount && amount > 0,
            "UnimoonStaking: wrong amount"
        );

        _updateUserReward(stake, pool);

        uint256 difference = stake.weight -
            valueToWeight(
                stake.value - amount,
                stake.lockedUntil - stake.lockedFrom
            );
        if (stake.value == amount) {
            _claimRewards(pid, stakeId);
            _removeUserStake(_msgSender(), pid, stakeId);
        } else {
            stake.value -= amount;
            stake.weight -= difference;
        }
        userStat[pid][_msgSender()].totalStaked -= amount;
        pool.totalWeight -= difference;
        generalInfo.totalWeight -= difference;
        pool.totalStaked -= amount;

        TransferHelper.safeTransfer(pool.token, _msgSender(), amount);

        emit Withdraw(_msgSender(), pid, amount);
    }

    /** @dev Function to claim earned rewards
     * @param pid pool ID
     */
    function claimRewards(uint8 pid, uint256 stakeId) external poolExist(pid) {
        _claimRewards(pid, stakeId);
    }

    function _updateUserReward(Data storage _stake, PoolInfo storage _pool)
        internal
    {
        _stake.pendingYield +=
            (_stake.weight * (_pool.accPerShare - _stake.lastAccValue)) /
            REWARD_PER_WEIGHT_MULTIPLIER;
        _stake.lastAccValue = _pool.accPerShare;
    }

    function _removeUserStake(
        address _user,
        uint256 _pid,
        uint256 _id
    ) internal {
        uint256 len = userInfo[_pid][_user].length;
        if (_id < len - 1) {
            Data memory _lastStake = userInfo[_pid][_user][len - 1];
            userInfo[_pid][_user][_id] = _lastStake;
        }
        userInfo[_pid][_user].pop();
    }

    function _claimRewards(uint8 _pid, uint256 _stakeId) internal {
        require(
            userInfo[_pid][_msgSender()].length > _stakeId,
            "UnimoonStaking: wrong stake id"
        );
        Data storage stake = userInfo[_pid][_msgSender()][_stakeId];
        PoolInfo storage pool = poolInfo[_pid];
        _updateUserReward(stake, pool);

        uint256 pendingYieldToClaim = stake.pendingYield;
        if (pendingYieldToClaim == 0) return;
        stake.pendingYield = 0;

        userStat[_pid][_msgSender()].totalClaimed += pendingYieldToClaim;

        TransferHelper.safeTransfer(
            REWARD_TOKEN,
            _msgSender(),
            pendingYieldToClaim
        );

        emit ClaimRewards(_msgSender(), _pid, pendingYieldToClaim);
    }
}