// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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
        require(
            address(this).balance >= amount,
            "Address: insufficient balance"
        );

        (bool success, ) = recipient.call{value: amount}("");
        require(
            success,
            "Address: unable to send value, recipient may have reverted"
        );
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
    function functionCall(address target, bytes memory data)
        internal
        returns (bytes memory)
    {
        return
            functionCallWithValue(
                target,
                data,
                0,
                "Address: low-level call failed"
            );
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
        return
            functionCallWithValue(
                target,
                data,
                value,
                "Address: low-level call with value failed"
            );
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
        require(
            address(this).balance >= value,
            "Address: insufficient balance for call"
        );
        (bool success, bytes memory returndata) = target.call{value: value}(
            data
        );
        return
            verifyCallResultFromTarget(
                target,
                success,
                returndata,
                errorMessage
            );
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data)
        internal
        view
        returns (bytes memory)
    {
        return
            functionStaticCall(
                target,
                data,
                "Address: low-level static call failed"
            );
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
        return
            verifyCallResultFromTarget(
                target,
                success,
                returndata,
                errorMessage
            );
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

    function _revert(bytes memory returndata, string memory errorMessage)
        private
        pure
    {
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
            (isTopLevelCall && _initialized < 1) ||
                (!AddressUpgradeable.isContract(address(this)) &&
                    _initialized == 1),
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
        require(
            !_initializing && _initialized < version,
            "Initializable: contract is already initialized"
        );
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
        if (_initialized < type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }

    /**
     * @dev Internal function that returns the initialized version. Returns `_initialized`
     */
    function _getInitializedVersion() internal view returns (uint8) {
        return _initialized;
    }

    /**
     * @dev Internal function that returns the initialized version. Returns `_initializing`
     */
    function _isInitializing() internal view returns (bool) {
        return _initializing;
    }
}

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
abstract contract Ownable is Context, Initializable {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __ownable_initialize() internal initializer {
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
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
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

pragma solidity >=0.4.0;

interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the token decimals.
     */
    function decimals() external view returns (uint8);

    /**
     * @dev Returns the token symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the token name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the erc token owner.
     */
    function getOwner() external view returns (address);

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
    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address _owner, address spender)
        external
        view
        returns (uint256);

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
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

pragma solidity ^0.8.0;

interface IBullPool {
    function userInfo(address _user)
        external
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            bool,
            uint256
        );

    function getPricePerFullShare() external view returns (uint256);

    function totalLockedAmount() external view returns (uint256);

    function totalShares() external view returns (uint256);

    function BOOST_WEIGHT() external view returns (uint256);

    function MAX_LOCK_DURATION() external view returns (uint256);
}

pragma solidity ^0.8.9;

interface IMasterChefV2 {
    function deposit(uint256 _pid, uint256 _amount) external;

    function withdraw(uint256 _pid, uint256 _amount) external;

    function pendingBull(uint256 _pid, address _user)
        external
        view
        returns (uint256);

    function userInfo(uint256 _pid, address _user)
        external
        view
        returns (
            uint256,
            uint256,
            uint256
        );

    function emergencyWithdraw(uint256 _pid) external;

    function lpToken(uint256 _pid) external view returns (address);

    function poolLength() external view returns (uint256 pools);

    function getBoostMultiplier(address _user, uint256 _pid)
        external
        view
        returns (uint256);

    function updateBoostMultiplier(
        address _user,
        uint256 _pid,
        uint256 _newMultiplier
    ) external;
}

struct ItMap {
    // pid => boost
    mapping(uint256 => uint256) data;
    // pid => index
    mapping(uint256 => uint256) indexs;
    // array of pid
    uint256[] keys;
    // never use it, just for keep compile success.
    uint256 size;
}

library IterableMapping {
    function insert(
        ItMap storage self,
        uint256 key,
        uint256 value
    ) internal {
        uint256 keyIndex = self.indexs[key];
        self.data[key] = value;
        if (keyIndex > 0) return;
        else {
            self.indexs[key] = self.keys.length + 1;
            self.keys.push(key);
            return;
        }
    }

    function remove(ItMap storage self, uint256 key) internal {
        uint256 index = self.indexs[key];
        if (index == 0) return;
        uint256 lastKey = self.keys[self.keys.length - 1];
        if (key != lastKey) {
            self.keys[index - 1] = lastKey;
            self.indexs[lastKey] = index;
        }
        delete self.data[key];
        delete self.indexs[key];
        self.keys.pop();
    }

    function contains(ItMap storage self, uint256 key)
        internal
        view
        returns (bool)
    {
        return self.indexs[key] > 0;
    }
}

contract FarmBooster is Ownable {
    using IterableMapping for ItMap;

    /// @notice bull token.
    address public BULL;
    /// @notice bull pool.
    address public BULL_POOL;
    /// @notice MCV2 contract.
    address public MASTER_CHEF;
    /// @notice boost proxy factory.
    address public BOOSTER_FACTORY;

    /// @notice Maximum allowed boosted pool numbers
    uint256 public MAX_BOOST_POOL;
    /// @notice limit max boost
    uint256 public cA;
    /// @notice include 1e4
    uint256 public constant MIN_CA = 1e4;
    /// @notice include 1e5
    uint256 public constant MAX_CA = 1e5;
    /// @notice cA precision
    uint256 public constant CA_PRECISION = 1e5;
    /// @notice controls difficulties
    uint256 public cB;
    /// @notice not include 0
    uint256 public constant MIN_CB = 0;
    /// @notice include 50
    uint256 public constant MAX_CB = 50;
    /// @notice MCV2 basic boost factor, none boosted user's boost factor
    uint256 public constant BOOST_PRECISION = 100 * 1e10;
    /// @notice MCV2 Hard limit for maxmium boost factor
    uint256 public constant MAX_BOOST_PRECISION = 200 * 1e10;
    /// @notice Average boost ratio precion
    uint256 public constant BOOST_RATIO_PRECISION = 1e5;
    /// @notice Bull pool BOOST_WEIGHT precision
    uint256 public constant BOOST_WEIGHT_PRECISION = 100 * 1e10; // 100%

    /// @notice The whitelist of pools allowed for farm boosting.
    mapping(uint256 => bool) public whiteList;
    /// @notice The boost proxy contract mapping(user => proxy).
    mapping(address => address) public proxyContract;
    /// @notice Info of each pool user.
    mapping(address => ItMap) public userInfo;

    event UpdateMaxBoostPool(uint256 factory);
    event UpdateBoostFactory(address factory);
    event UpdateCA(uint256 oldCA, uint256 newCA);
    event UpdateCB(uint256 oldCB, uint256 newCB);
    event Refresh(address indexed user, address proxy, uint256 pid);
    event UpdateBoostFarms(uint256 pid, bool status);
    event ActiveFarmPool(address indexed user, address proxy, uint256 pid);
    event DeactiveFarmPool(address indexed user, address proxy, uint256 pid);
    event UpdateBoostProxy(address indexed user, address proxy);
    event UpdatePoolBoostMultiplier(
        address indexed user,
        uint256 pid,
        uint256 oldMultiplier,
        uint256 newMultiplier
    );
    event UpdateBullPool(
        address indexed user,
        uint256 lockedAmount,
        uint256 lockedDuration,
        uint256 totalLockedAmount,
        uint256 maxLockDuration
    );

    /// @param _bull BULL token contract address.
    /// @param _bullPool Bull Pool contract address.
    /// @param _v2 MasterChefV2 contract address.
    /// @param _max Maximum allowed boosted farm  quantity
    /// @param _cA Limit max boost
    /// @param _cB Controls difficulties
    function initialize(
        address _bull,
        address _bullPool,
        address _v2,
        uint256 _max,
        uint256 _cA,
        uint256 _cB
    ) external initializer {
        require(
            _max > 0 &&
                _cA >= MIN_CA &&
                _cA <= MAX_CA &&
                _cB > MIN_CB &&
                _cB <= MAX_CB,
            "constructor: Invalid parameter"
        );
        __ownable_initialize();
        BULL = _bull;
        BULL_POOL = _bullPool;
        MASTER_CHEF = _v2;
        MAX_BOOST_POOL = _max;
        cA = _cA;
        cB = _cB;
    }

    /// @notice Checks if the msg.sender is a contract or a proxy
    modifier notContract() {
        require(!_isContract(msg.sender), "contract not allowed");
        require(msg.sender == tx.origin, "proxy contract not allowed");
        _;
    }

    /// @notice Checks if the msg.sender is the FarmBooster Factory.
    modifier onlyFactory() {
        require(msg.sender == BOOSTER_FACTORY, "onlyFactory: Not factory");
        _;
    }

    /// @notice Checks if the msg.sender is the FarmBooster Proxy.
    modifier onlyProxy(address _user) {
        require(msg.sender == proxyContract[_user], "onlyProxy: Not proxy");
        _;
    }

    /// @notice Checks if the msg.sender is the bull pool.
    modifier onlyBullPool() {
        require(msg.sender == BULL_POOL, "onlyBullPool: Not bull pool");
        _;
    }

    /// @notice set maximum allowed boosted pool numbers.
    function setMaxBoostPool(uint256 _max) external onlyOwner {
        require(
            _max > 0,
            "setMaxBoostPool: Maximum boost pool should greater than 0"
        );
        MAX_BOOST_POOL = _max;
        emit UpdateMaxBoostPool(_max);
    }

    /// @notice set boost factory contract.
    function setBoostFactory(address _factory) external onlyOwner {
        require(_factory != address(0), "setBoostFactory: Invalid factory");
        BOOSTER_FACTORY = _factory;

        emit UpdateBoostFactory(_factory);
    }

    /// @notice Set user boost proxy contract, can only invoked by boost contract.
    /// @param _user boost user address.
    /// @param _proxy boost proxy contract.
    function setProxy(address _user, address _proxy) external onlyFactory {
        require(_proxy != address(0), "setProxy: Invalid proxy address");
        require(
            proxyContract[_user] == address(0),
            "setProxy: User has already set proxy"
        );

        proxyContract[_user] = _proxy;

        emit UpdateBoostProxy(_user, _proxy);
    }

    /// @notice Only allow whitelisted pids for farm boosting
    /// @param _pid pool id(MasterchefV2 pool).
    /// @param _status farm pool allowed boosted or not
    function setBoosterFarms(uint256 _pid, bool _status) external onlyOwner {
        whiteList[_pid] = _status;
        emit UpdateBoostFarms(_pid, _status);
    }

    /// @notice limit max boost
    /// @param _cA max boost
    function setCA(uint256 _cA) external onlyOwner {
        require(_cA >= MIN_CA && _cA <= MAX_CA, "setCA: Invalid cA");
        uint256 temp = cA;
        cA = _cA;
        emit UpdateCA(temp, cA);
    }

    /// @notice controls difficulties
    /// @param _cB difficulties
    function setCB(uint256 _cB) external onlyOwner {
        require(_cB > MIN_CB && _cB <= MAX_CB, "setCB: Invalid cB");
        uint256 temp = cB;
        cB = _cB;
        emit UpdateCB(temp, cB);
    }

    /// @notice Bullpool operation(deposit/withdraw) automatically call this function.
    /// @param _user user address.
    /// @param _lockedAmount user locked amount in bull pool.
    /// @param _lockedDuration user locked duration in bull pool.
    /// @param _totalLockedAmount Total locked bull amount in bull pool.
    /// @param _maxLockDuration maximum locked duration in bull pool.
    function onBullPoolUpdate(
        address _user,
        uint256 _lockedAmount,
        uint256 _lockedDuration,
        uint256 _totalLockedAmount,
        uint256 _maxLockDuration
    ) external onlyBullPool {
        address proxy = proxyContract[_user];
        ItMap storage itmap = userInfo[proxy];
        uint256 avgDuration;
        bool flag;
        for (uint256 i = 0; i < itmap.keys.length; i++) {
            uint256 pid = itmap.keys[i];
            if (!flag) {
                avgDuration = avgLockDuration();
                flag = true;
            }
            _updateBoostMultiplier(_user, proxy, pid, avgDuration);
        }

        emit UpdateBullPool(
            _user,
            _lockedAmount,
            _lockedDuration,
            _totalLockedAmount,
            _maxLockDuration
        );
    }

    /// @notice Update user boost multiplier in V2 pool,only for proxy.
    /// @param _user user address.
    /// @param _pid pool id in MasterchefV2 pool.
    function updatePoolBoostMultiplier(address _user, uint256 _pid)
        public
        onlyProxy(_user)
    {
        // if user not actived this farm, just return.
        if (!userInfo[msg.sender].contains(_pid)) return;
        _updateBoostMultiplier(_user, msg.sender, _pid, avgLockDuration());
    }

    /// @notice Active user farm pool.
    /// @param _pid pool id(MasterchefV2 pool).
    function activate(uint256 _pid) external {
        address proxy = proxyContract[msg.sender];
        require(
            whiteList[_pid] && proxy != address(0),
            "activate: Not boosted farm pool"
        );

        ItMap storage itmap = userInfo[proxy];
        require(
            itmap.keys.length < MAX_BOOST_POOL,
            "activate: Boosted farms reach to MAX"
        );

        _updateBoostMultiplier(msg.sender, proxy, _pid, avgLockDuration());

        emit ActiveFarmPool(msg.sender, proxy, _pid);
    }

    /// @notice Deactive user farm pool.
    /// @param _pid pool id(MasterchefV2 pool).
    function deactive(uint256 _pid) external {
        address proxy = proxyContract[msg.sender];
        ItMap storage itmap = userInfo[proxy];
        require(itmap.contains(_pid), "deactive: None boost user");

        if (itmap.data[_pid] > BOOST_PRECISION) {
            IMasterChefV2(MASTER_CHEF).updateBoostMultiplier(
                proxy,
                _pid,
                BOOST_PRECISION
            );
        }
        itmap.remove(_pid);

        emit DeactiveFarmPool(msg.sender, proxy, _pid);
    }

    /// @notice Anyone can refesh sepecific user boost multiplier
    /// @param _user user address.
    /// @param _pid pool id(MasterchefV2 pool).
    function refresh(address _user, uint256 _pid) external notContract {
        address proxy = proxyContract[_user];
        ItMap storage itmap = userInfo[proxy];
        require(itmap.contains(_pid), "refresh: None boost user");

        _updateBoostMultiplier(_user, proxy, _pid, avgLockDuration());

        emit Refresh(_user, proxy, _pid);
    }

    /// @notice Whether user boosted specific farm pool.
    /// @param _user user address.
    /// @param _pid pool id(MasterchefV2 pool).
    function isBoostedPool(address _user, uint256 _pid)
        external
        view
        returns (bool)
    {
        return userInfo[proxyContract[_user]].contains(_pid);
    }

    /// @notice Actived farm pool list.
    /// @param _user user address.
    function activedPools(address _user)
        external
        view
        returns (uint256[] memory pools)
    {
        ItMap storage itmap = userInfo[proxyContract[_user]];
        if (itmap.keys.length == 0) return pools;

        pools = new uint256[](itmap.keys.length);
        // solidity for-loop not support multiple variables initializae by ',' separate.
        uint256 i;
        for (uint256 index = 0; index < itmap.keys.length; index++) {
            uint256 pid = itmap.keys[index];
            pools[i] = pid;
            i++;
        }
    }

    /// @notice Anyone can call this function, if you find some guys effectived multiplier is not fair
    /// for other users, just call 'refresh' function.
    /// @param _user user address.
    /// @param _pid pool id(MasterchefV2 pool).
    /// @dev If return value not in range [BOOST_PRECISION, MAX_BOOST_PRECISION]
    /// the actual effectived multiplier will be the close to side boundry value.
    function getUserMultiplier(address _user, uint256 _pid)
        external
        view
        returns (uint256)
    {
        return
            _boostCalculate(
                _user,
                proxyContract[_user],
                _pid,
                avgLockDuration()
            );
    }

    /// @notice bull pool average locked duration calculator.
    function avgLockDuration() public view returns (uint256) {
        uint256 totalStakedAmount = IERC20(BULL).balanceOf(BULL_POOL);

        uint256 totalLockedAmount = IBullPool(BULL_POOL).totalLockedAmount();

        uint256 pricePerFullShare = IBullPool(BULL_POOL).getPricePerFullShare();

        uint256 flexibleShares = ((totalStakedAmount - totalLockedAmount) *
            1e18) / pricePerFullShare;
        if (flexibleShares == 0) return 0;

        uint256 originalShares = (totalLockedAmount * 1e18) / pricePerFullShare;
        if (originalShares == 0) return 0;

        uint256 boostedRatio = ((IBullPool(BULL_POOL).totalShares() -
            flexibleShares) * BOOST_RATIO_PRECISION) / originalShares;
        if (boostedRatio <= BOOST_RATIO_PRECISION) return 0;

        uint256 boostWeight = IBullPool(BULL_POOL).BOOST_WEIGHT();
        uint256 maxLockDuration = IBullPool(BULL_POOL).MAX_LOCK_DURATION() *
            BOOST_RATIO_PRECISION;

        uint256 duration = ((boostedRatio - BOOST_RATIO_PRECISION) *
            365 *
            BOOST_WEIGHT_PRECISION) / boostWeight;
        return duration <= maxLockDuration ? duration : maxLockDuration;
    }

    /// @param _user user address.
    /// @param _proxy proxy address corresponding to the user.
    /// @param _pid pool id.
    /// @param _duration bull pool average locked duration.
    function _updateBoostMultiplier(
        address _user,
        address _proxy,
        uint256 _pid,
        uint256 _duration
    ) internal {
        ItMap storage itmap = userInfo[_proxy];

        // Used to be boost farm pool and current is not, remove from mapping
        if (!whiteList[_pid]) {
            if (itmap.data[_pid] > BOOST_PRECISION) {
                // reset to BOOST_PRECISION
                IMasterChefV2(MASTER_CHEF).updateBoostMultiplier(
                    _proxy,
                    _pid,
                    BOOST_PRECISION
                );
            }
            itmap.remove(_pid);
            return;
        }

        uint256 prevMultiplier = IMasterChefV2(MASTER_CHEF).getBoostMultiplier(
            _proxy,
            _pid
        );
        uint256 multiplier = _boostCalculate(_user, _proxy, _pid, _duration);

        if (multiplier < BOOST_PRECISION) {
            multiplier = BOOST_PRECISION;
        } else if (multiplier > MAX_BOOST_PRECISION) {
            multiplier = MAX_BOOST_PRECISION;
        }

        // Update multiplier to MCV2
        if (multiplier != prevMultiplier) {
            IMasterChefV2(MASTER_CHEF).updateBoostMultiplier(
                _proxy,
                _pid,
                multiplier
            );
        }
        itmap.insert(_pid, multiplier);

        emit UpdatePoolBoostMultiplier(_user, _pid, prevMultiplier, multiplier);
    }

    /// @param _user user address.
    /// @param _proxy proxy address corresponding to the user.
    /// @param _pid pool id(MasterchefV2 pool).
    /// @param _duration bull pool average locked duration.
    function _boostCalculate(
        address _user,
        address _proxy,
        uint256 _pid,
        uint256 _duration
    ) internal view returns (uint256) {
        if (_duration == 0) return BOOST_PRECISION;

        (uint256 lpBalance, , ) = IMasterChefV2(MASTER_CHEF).userInfo(
            _pid,
            _proxy
        );
        uint256 dB = (cA * lpBalance) / CA_PRECISION;
        // dB == 0 means lpBalance close to 0
        if (lpBalance == 0 || dB == 0) return BOOST_PRECISION;

        (
            ,
            ,
            ,
            ,
            uint256 lockStartTime,
            uint256 lockEndTime,
            ,
            ,
            uint256 userLockedAmount
        ) = IBullPool(BULL_POOL).userInfo(_user);
        if (userLockedAmount == 0 || block.timestamp >= lockEndTime)
            return BOOST_PRECISION;

        // userLockedAmount > 0 means totalLockedAmount > 0
        uint256 totalLockedAmount = IBullPool(BULL_POOL).totalLockedAmount();

        IERC20 lp = IERC20(IMasterChefV2(MASTER_CHEF).lpToken(_pid));
        uint256 userLockedDuration = (lockEndTime - lockStartTime) /
            (3600 * 24); // days

        uint256 aB = (((lp.balanceOf(MASTER_CHEF) *
            userLockedAmount *
            userLockedDuration) * BOOST_RATIO_PRECISION) / cB) /
            (totalLockedAmount * _duration);

        // should '*' BOOST_PRECISION
        return
            ((lpBalance < (dB + aB) ? lpBalance : (dB + aB)) *
                BOOST_PRECISION) / dB;
    }

    /// @notice Checks if address is a contract
    /// @dev It prevents contract from being targetted
    function _isContract(address addr) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(addr)
        }
        return size > 0;
    }
}