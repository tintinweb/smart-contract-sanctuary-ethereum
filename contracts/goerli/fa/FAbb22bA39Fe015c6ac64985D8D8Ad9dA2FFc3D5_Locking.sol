// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "./INextVersionLock.sol";
import "./LockingBase.sol";
import "./LockingRelock.sol";
import "./LockingVotes.sol";
import "./ILocking.sol";

contract Locking is ILocking, LockingBase, LockingRelock, LockingVotes {
    using LibBrokenLine for LibBrokenLine.BrokenLine;

    function __Locking_init(IERC20Upgradeable _token, uint32 _startingPointWeek, uint32 _minCliffPeriod, uint32 _minSlopePeriod) external initializer {
        __LockingBase_init_unchained(_token, _startingPointWeek, _minCliffPeriod, _minSlopePeriod);
        __Ownable_init_unchained();
        __Context_init_unchained();
    }

    function stop() external onlyOwner notStopped {
        stopped = true;
        emit StopLocking(msg.sender);
    }

    function start() external onlyOwner isStopped {
        stopped = false;
        emit StartLocking(msg.sender);
    }

    function startMigration(address to) external onlyOwner {
        migrateTo = to;
        emit StartMigration(msg.sender, to);
    }

    function lock(address account, address _delegate, uint96 amount, uint32 slopePeriod, uint32 cliff) external notStopped notMigrating override returns (uint) {
        require(amount > 0, "zero amount");
        require(cliff <= MAX_CLIFF_PERIOD, "cliff too big");
        require(slopePeriod <= MAX_SLOPE_PERIOD, "period too big");

        counter++;

        uint32 currentBlock = getBlockNumber();
        uint32 time = roundTimestamp(currentBlock);
        addLines(account, _delegate, amount, slopePeriod, cliff, time, currentBlock);
        accounts[account].amount = accounts[account].amount + (amount);

        require(token.transferFrom(msg.sender, address(this), amount), "transfer failed");

        emit LockCreate(counter, account, _delegate, time, amount, slopePeriod, cliff);
        return counter;
    }

    function withdraw() external {
        uint96 value = getAvailableForWithdraw(msg.sender);
        if (value > 0) {
            accounts[msg.sender].amount = accounts[msg.sender].amount - (value);
            require(token.transfer(msg.sender, value), "transfer failed");
        }
        emit Withdraw(msg.sender, value);
    }

    // Amount available for withdrawal
    function getAvailableForWithdraw(address account) public view returns (uint96) {
        uint96 value = accounts[account].amount;
        if (!stopped) {
            uint32 currentBlock = getBlockNumber();
            uint32 time = roundTimestamp(currentBlock);
            uint96 bias = accounts[account].locked.actualValue(time, currentBlock);
            value = value - (bias);
        }
        return value;
    }

    //Remaining locked amount
    function locked(address account) external view returns (uint) {
        return accounts[account].amount;
    }

    //For a given Line id, the owner and delegate addresses.
    function getAccountAndDelegate(uint id) external view returns (address _account, address _delegate) {
        _account = locks[id].account;
        _delegate = locks[id].delegate;
    }

    //Getting "current week" of the contract.
    function getWeek() external view returns (uint) {
        return roundTimestamp(getBlockNumber());
    }

    function delegateTo(uint id, address newDelegate) external notStopped notMigrating {
        address account = verifyLockOwner(id);
        address _delegate = locks[id].delegate;
        uint32 currentBlock = getBlockNumber();
        uint32 time = roundTimestamp(currentBlock);
        accounts[_delegate].balance.update(time);
        (uint96 bias, uint96 slope, uint32 cliff) = accounts[_delegate].balance.remove(id, time, currentBlock);
        LibBrokenLine.Line memory line = LibBrokenLine.Line(time, bias, slope, cliff);
        accounts[newDelegate].balance.update(time);
        accounts[newDelegate].balance.addOneLine(id, line, currentBlock);
        locks[id].delegate = newDelegate;
        emit Delegate(id, account, newDelegate, time);

    }

    function totalSupply() external view returns (uint) {
        if ((totalSupplyLine.initial.bias == 0) || (stopped)) {
            return 0;
        }
        uint32 currentBlock = getBlockNumber();
        uint32 time = roundTimestamp(currentBlock);
        return totalSupplyLine.actualValue(time, currentBlock);
    }

    function balanceOf(address account) external view returns (uint) {
        if ((accounts[account].balance.initial.bias == 0) || (stopped)) {
            return 0;
        }
        uint32 currentBlock = getBlockNumber();
        uint32 time = roundTimestamp(currentBlock);
        return accounts[account].balance.actualValue(time, currentBlock);
    }

    function migrate(uint[] memory id) external {
        if (migrateTo == address(0)) {
            return;
        }
        uint32 currentBlock = getBlockNumber();
        uint32 time = roundTimestamp(currentBlock);
        INextVersionLock nextVersionLock = INextVersionLock(migrateTo);
        for (uint256 i = 0; i < id.length; ++i) {
            address account = verifyLockOwner(id[i]);
            address _delegate = locks[id[i]].delegate;
            updateLines(account, _delegate, time);
            //save data Line before remove
            LibBrokenLine.Line memory line = accounts[account].locked.initiatedLines[id[i]];
            (uint96 residue,,) = accounts[account].locked.remove(id[i], time, currentBlock);

            accounts[account].amount = accounts[account].amount - (residue);

            accounts[_delegate].balance.remove(id[i], time, currentBlock);
            totalSupplyLine.remove(id[i], time, currentBlock);
            nextVersionLock.initiateData(id[i], line, account, _delegate);

            require(token.transfer(migrateTo, residue), "transfer failed");
        }
        emit Migrate(msg.sender, id);
    }

    function name() public view virtual returns (string memory) {
        return "Rarible Vote-Escrow";
    }

    function symbol() public view virtual returns (string memory) {
        return "veRARI";
    }

    function decimals() public view virtual returns (uint8) {
        return 18;
    }

    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.1) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "../../utils/AddressUpgradeable.sol";

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
        if (_initialized < type(uint8).max) {
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

interface ILocking {
    function lock(
        address account,
        address delegate,
        uint96 amount,
        uint32 slope,
        uint32 cliff
    ) external returns (uint);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "./libs/LibBrokenLine.sol";

interface INextVersionLock {
    function initiateData(uint idLock, LibBrokenLine.Line memory line, address locker, address delegate) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

/**
 * @dev Common interface for {ERC20Votes}, {ERC721Votes}, and other {Votes}-enabled contracts.
 *
 * _Available since v4.5._
 */
interface IVotesUpgradeable {
    /**
     * @dev Emitted when an account changes their delegate.
     */
    event DelegateChanged(address indexed delegator, address indexed fromDelegate, address indexed toDelegate);

    /**
     * @dev Emitted when a token transfer or delegate change results in changes to a delegate's number of votes.
     */
    event DelegateVotesChanged(address indexed delegate, uint256 previousBalance, uint256 newBalance);

    /**
     * @dev Returns the current amount of votes that `account` has.
     */
    function getVotes(address account) external view returns (uint256);

    /**
     * @dev Returns the amount of votes that `account` had at the end of a past block (`blockNumber`).
     */
    function getPastVotes(address account, uint256 blockNumber) external view returns (uint256);

    /**
     * @dev Returns the total supply of votes available at the end of a past block (`blockNumber`).
     *
     * NOTE: This value is the sum of all available votes, which is not necessarily the sum of all delegated votes.
     * Votes that have not been delegated are still part of total supply, even though they would not participate in a
     * vote.
     */
    function getPastTotalSupply(uint256 blockNumber) external view returns (uint256);

    /**
     * @dev Returns the delegate that `account` has chosen.
     */
    function delegates(address account) external view returns (address);

    /**
     * @dev Delegates votes from the sender to `delegatee`.
     */
    function delegate(address delegatee) external;

    /**
     * @dev Delegates votes from signer to `delegatee`.
     */
    function delegateBySig(
        address delegatee,
        uint256 nonce,
        uint256 expiry,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "./LibIntMapping.sol";
/**
  * Line describes a linear function, how the user's voice decreases from point (start, bias) with speed slope
  * BrokenLine - a curve that describes the curve of the change in the sum of votes of several users
  * This curve starts with a line (Line) and then, at any time, the slope can be changed.
  * All slope changes are stored in slopeChanges. The slope can always be reduced only, it cannot increase,
  * because users can only run out of lockup periods.
  **/

library LibBrokenLine {
    using LibIntMapping for mapping(uint => int96);

    // OldStructs
    struct LineOld {
        uint start;
        uint bias;
        uint slope;
    }

    struct LineDataOld {//all data about line
        LineOld line;
        uint cliff;
    }

    struct BrokenLineOld {
        mapping(uint => int) slopeChanges;          //change of slope applies to the next time point
        mapping(uint => int) biasChanges;           //change of bias applies to the next time point
        mapping(uint => LineDataOld) initiatedLines;   //initiated (successfully added) Lines
        LineOld initial;
    }
    // end of the old structs

    struct Line {
        uint32 start;
        uint96 bias;
        uint96 slope;
        uint32 cliff;
    }

    struct Point {
        uint32 blockNumber;
        uint96 bias;
        uint96 slope;
        uint32 epoch;
    }

    struct BrokenLine {
        mapping(uint => int96) slopeChanges;          //change of slope applies to the next time point
        mapping(uint => Line) initiatedLines;   //initiated (successfully added) Lines
        Point[] history;
        Line initial;
    }

    /**
     * @dev Add Line, save data in LineData. Run update BrokenLine, require:
     *      1. slope != 0, slope <= bias
     *      2. line not exists
     **/
    function _addOneLine(BrokenLine storage brokenLine, uint id, Line memory line) internal {
        require(line.slope != 0, "Slope == 0, unacceptable value for slope");
        require(line.slope <= line.bias, "Slope > bias, unacceptable value for slope");
        require(brokenLine.initiatedLines[id].bias == 0, "Line with given id is already exist");
        brokenLine.initiatedLines[id] = line;

        update(brokenLine, line.start);
        brokenLine.initial.bias = brokenLine.initial.bias + (line.bias);
        //save bias for history in line.start minus one
        uint32 lineStartMinusOne = line.start - 1;
        //period is time without tail
        uint32 period = uint32(line.bias / (line.slope));

        if (line.cliff == 0) {
            //no cliff, need to increase brokenLine.initial.slope write now
            brokenLine.initial.slope = brokenLine.initial.slope + (line.slope);
            //no cliff, save slope in history in time minus one
            brokenLine.slopeChanges.addToItem(lineStartMinusOne, safeInt(line.slope));
        } else {
            //cliffEnd finish in lineStart minus one plus cliff
            uint32 cliffEnd = lineStartMinusOne + (line.cliff);
            //save slope in history in cliffEnd 
            brokenLine.slopeChanges.addToItem(cliffEnd, safeInt(line.slope));
            period = period + (line.cliff);
        }

        int96 mod = safeInt(line.bias % (line.slope));
        uint32 endPeriod = line.start + (period);
        uint32 endPeriodMinus1 = endPeriod - 1;
        brokenLine.slopeChanges.subFromItem(endPeriodMinus1, safeInt(line.slope) - (mod));
        brokenLine.slopeChanges.subFromItem(endPeriod, mod);
    }

    /**
     * @dev adding a line and saving snapshot
     */
    function addOneLine(BrokenLine storage brokenLine, uint id, Line memory line, uint32 blockNumber) internal {
        _addOneLine(brokenLine, id, line);
        saveSnapshot(brokenLine, line.start, blockNumber);
    }

    /**
     * @dev Remove Line from BrokenLine, return bias, slope, cliff. Run update BrokenLine.
     **/
    function _remove(BrokenLine storage brokenLine, uint id, uint32 toTime) internal returns (uint96 bias, uint96 slope, uint32 cliff) {
        Line memory line = brokenLine.initiatedLines[id];
        require(line.bias != 0, "Removing Line, which not exists");

        update(brokenLine, toTime);
        //check time Line is over
        bias = line.bias;
        slope = line.slope;
        cliff = 0;
        //for information: bias / (slope) - this`s period while slope works
        uint32 finishTime = line.start + (uint32(bias / (slope))) + (line.cliff);
        if (toTime > finishTime) {
            bias = 0;
            slope = 0;
            return (bias, slope, cliff);
        }
        uint32 finishTimeMinusOne = finishTime - 1;
        uint32 toTimeMinusOne = toTime - 1;
        int96 mod = safeInt(bias % slope);
        uint32 cliffEnd = line.start + (line.cliff) - 1;
        if (toTime <= cliffEnd) {//cliff works
            cliff = cliffEnd - (toTime) + 1;
            //in cliff finish time compensate change slope by oldLine.slope
            brokenLine.slopeChanges.subFromItem(cliffEnd, safeInt(slope));
            //in new Line finish point use oldLine.slope
            brokenLine.slopeChanges.addToItem(finishTimeMinusOne, safeInt(slope) - (mod));
        } else if (toTime <= finishTimeMinusOne) {//slope works
            //now compensate change slope by oldLine.slope
            brokenLine.initial.slope = brokenLine.initial.slope - (slope);
            //in new Line finish point use oldLine.slope
            brokenLine.slopeChanges.addToItem(finishTimeMinusOne, safeInt(slope) - (mod));
            bias = (uint96(finishTime - (toTime)) * slope) + (uint96(mod));
            //save slope for history
            brokenLine.slopeChanges.subFromItem(toTimeMinusOne, safeInt(slope));
        } else {//tail works
            //now compensate change slope by tail
            brokenLine.initial.slope = brokenLine.initial.slope - (uint96(mod));
            bias = uint96(mod);
            slope = bias;
            //save slope for history
            brokenLine.slopeChanges.subFromItem(toTimeMinusOne, safeInt(slope));
        }
        brokenLine.slopeChanges.addToItem(finishTime, mod);
        brokenLine.initial.bias = brokenLine.initial.bias - (bias);
        brokenLine.initiatedLines[id].bias = 0;
    }

    /**
     * @dev removing a line and saving snapshot
     */
    function remove(BrokenLine storage brokenLine, uint id, uint32 toTime, uint32 blockNumber) internal returns (uint96 bias, uint96 slope, uint32 cliff) {
        (bias, slope, cliff) = _remove(brokenLine, id, toTime);
        saveSnapshot(brokenLine, toTime, blockNumber);
    }

    /**
     * @dev Update initial Line by parameter toTime. Calculate and set all changes
     **/
    function update(BrokenLine storage brokenLine, uint32 toTime) internal {
        uint32 time = brokenLine.initial.start;
        if (time == toTime) {
            return;
        }
        uint96 slope = brokenLine.initial.slope;
        uint96 bias = brokenLine.initial.bias;
        if (bias != 0) {
            require(toTime > time, "can't update BrokenLine for past time");
            while (time < toTime) {
                bias = bias - (slope);

                int96 newSlope = safeInt(slope) + (brokenLine.slopeChanges[time]);
                require(newSlope >= 0, "slope < 0, something wrong with slope");
                slope = uint96(newSlope);

                time = time + 1;
            }
        }
        brokenLine.initial.start = toTime;
        brokenLine.initial.bias = bias;
        brokenLine.initial.slope = slope;
    }

    function actualValue(BrokenLine storage brokenLine, uint32 toTime, uint32 toBlock) internal view returns (uint96) {
        uint32 fromTime = brokenLine.initial.start;
        if (fromTime == toTime) {
            if (brokenLine.history[brokenLine.history.length - 1].blockNumber < toBlock) {
                return (brokenLine.initial.bias);
            } else {
                return actualValueBack(brokenLine, toTime, toBlock);
            }
        }
        if (toTime > fromTime) {
            return actualValueForward(brokenLine, fromTime, toTime, brokenLine.initial.bias, brokenLine.initial.slope, toBlock);
        }
        return actualValueBack(brokenLine, toTime, toBlock);
    }

    function actualValueForward(BrokenLine storage brokenLine, uint32 fromTime, uint32 toTime, uint96 bias, uint96 slope, uint32 toBlock) internal view returns (uint96) {
        if ((bias == 0)){
            return (bias);
        }
        uint32 time = fromTime;

        while (time < toTime) {
            bias = bias - (slope);

            int96 newSlope = safeInt(slope) + (brokenLine.slopeChanges[time]);
            require(newSlope >= 0, "slope < 0, something wrong with slope");
            slope = uint96(newSlope);

            time = time + 1;
        }
        return bias;
    }

    function actualValueBack(BrokenLine storage brokenLine, uint32 toTime, uint32 toBlock) internal view returns (uint96) {
        (uint96 bias, uint96 slope, uint32 fromTime) = binarySearch(brokenLine.history, toBlock);
        return actualValueForward(brokenLine, fromTime, toTime, bias, slope, toBlock);
    }

    function safeInt(uint96 value) pure internal returns (int96 result) {
        require(value < 2**95, "int cast error");
        result = int96(value);
    }

    function saveSnapshot(BrokenLine storage brokenLine, uint32 epoch, uint32 blockNumber) internal {
        brokenLine.history.push(Point({
            blockNumber: blockNumber,
            bias: brokenLine.initial.bias,
            slope: brokenLine.initial.slope,
            epoch: epoch
        }));
    }

    function binarySearch(Point[] memory history, uint32 toBlock) internal pure returns(uint96, uint96, uint32) {
        uint len = history.length;
        if (len == 0 || history[0].blockNumber > toBlock) {
            return (0,0,0);
        }
        uint min = 0;
        uint max = len - 1;
        
        for (uint i = 0; i < 128; i++) {
            if (min >= max) {
                break;
            }
            uint mid = (min + max + 1) / 2;
            if (history[mid].blockNumber <= toBlock) {
                min = mid; 
            } else {
                max = mid - 1;
            }
        }
        return (history[min].bias, history[min].slope, history[min].epoch);
    }

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

library LibIntMapping {

    function addToItem(mapping(uint => int96) storage map, uint key, int96 value) internal {
        map[key] = map[key] + (value);
    }

    function subFromItem(mapping(uint => int96) storage map, uint key, int96 value) internal {
        map[key] = map[key] - (value);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

import "./libs/LibBrokenLine.sol";

import "./IVotesUpgradeable.sol";

abstract contract LockingBase is OwnableUpgradeable, IVotesUpgradeable {
    using LibBrokenLine for LibBrokenLine.BrokenLine;

    uint32 constant public WEEK = 50400; //blocks one week = 50400, day = 7200, goerli = 50
    
    uint32 constant MAX_CLIFF_PERIOD = 103;
    uint32 constant MAX_SLOPE_PERIOD = 104;

    uint32 constant ST_FORMULA_DIVIDER =  1 * (10 ** 8);           //stFormula divider          100000000
    uint32 constant ST_FORMULA_CONST_MULTIPLIER = 2 * (10 ** 7);   //stFormula const multiplier  20000000
    uint32 constant ST_FORMULA_CLIFF_MULTIPLIER = 8 * (10 ** 7);   //stFormula cliff multiplier  80000000
    uint32 constant ST_FORMULA_SLOPE_MULTIPLIER = 4 * (10 ** 7);   //stFormula slope multiplier  40000000

    /**
     * @dev ERC20 token to lock
     */
    IERC20Upgradeable public token;
    /**
     * @dev counter for Lock identifiers
     */
    uint public counter;

    /**
     * @dev true if contract entered stopped state
     */
    bool public stopped;

    /**
     * @dev address to migrate Locks to (zero if not in migration state)
     */
    address public migrateTo;

    /**
     * @dev minimal cliff period in weeks, minCliffPeriod < MAX_CLIFF_PERIOD
     */

    uint public minCliffPeriod;

    /**
     * @dev minimal slope period in weeks, minSlopePeriod < MAX_SLOPE_PERIOD
     */
    uint public minSlopePeriod;

    /**
     * @dev locking epoch start in weeks
     */
    uint public startingPointWeek;

    /**
     * @dev represents one user Lock
     */
    struct Lock {
        address account;
        address delegate;
    }

    /**
     * @dev describes state of accounts's balance.
     *      balance - broken line describes lock
     *      locked - broken line describes how many tokens are locked
     *      amount - total currently locked tokens (including tokens which can be withdrawed)
     */
    struct AccountOld {
        LibBrokenLine.BrokenLineOld balance;
        LibBrokenLine.BrokenLineOld locked;
        uint amount;
    }

    mapping(address => AccountOld) accountsOld;
    mapping(uint => Lock) locks;
    LibBrokenLine.BrokenLineOld public totalSupplyLineOld;

    struct Account {
        LibBrokenLine.BrokenLine balance;
        LibBrokenLine.BrokenLine locked;
        uint96 amount;
    }

    mapping(address => Account) accounts;
    LibBrokenLine.BrokenLine public totalSupplyLine;

    /**
     * @dev Emitted when create Lock with parameters (account, delegate, amount, slopePeriod, cliff)
     */
    event LockCreate(uint indexed id, address indexed account, address indexed delegate, uint time, uint amount, uint slopePeriod, uint cliff);
    /**
     * @dev Emitted when change Lock parameters (newDelegate, newAmount, newSlopePeriod, newCliff) for Lock with given id
     */
    event Relock(uint indexed id, address indexed account, address indexed delegate, uint counter, uint time, uint amount, uint slopePeriod, uint cliff);
    /**
     * @dev Emitted when to set newDelegate address for Lock with given id
     */
    event Delegate(uint indexed id, address indexed account, address indexed delegate, uint time);
    /**
     * @dev Emitted when withdraw amount of Rari, account - msg.sender, amount - amount Rari
     */
    event Withdraw(address indexed account, uint amount);
    /**
     * @dev Emitted when migrate Locks with given id, account - msg.sender
     */
    event Migrate(address indexed account, uint[] id);
    /**
     * @dev Stop run contract functions, accept withdraw, account - msg.sender
     */
    event StopLocking(address indexed account);
    /**
     * @dev Start run contract functions, accept withdraw, account - msg.sender
     */
    event StartLocking(address indexed account);
    /**
     * @dev StartMigration initiate migration to another contract, account - msg.sender, to - address delegate to
     */
    event StartMigration(address indexed account, address indexed to);
    /**
     * @dev set newMinCliffPeriod
     */
    event SetMinCliffPeriod(uint indexed newMinCliffPeriod);
    /**
     * @dev set newMinSlopePeriod
     */
    event SetMinSlopePeriod(uint indexed newMinSlopePeriod);
    /**
     * @dev set startingPointWeek
     */
    event SetStartingPointWeek(uint indexed newStartingPointWeek);

    function __LockingBase_init_unchained(IERC20Upgradeable _token, uint32 _startingPointWeek, uint32 _minCliffPeriod, uint32 _minSlopePeriod) internal onlyInitializing {
        token = _token;
        startingPointWeek = _startingPointWeek;

        //setting min cliff and slope
        require(_minCliffPeriod <= MAX_CLIFF_PERIOD, "cliff too big");
        require(_minSlopePeriod <= MAX_SLOPE_PERIOD, "period too big");
        minCliffPeriod = _minCliffPeriod;
        minSlopePeriod = _minSlopePeriod;
    }

    function addLines(address account, address _delegate, uint96 amount, uint32 slopePeriod, uint32 cliff, uint32 time, uint32 currentBlock) internal {
        require(slopePeriod <= amount, "Wrong value slopePeriod");
        updateLines(account, _delegate, time);
        (uint96 stAmount, uint96 stSlope) = getLock(amount, slopePeriod, cliff);
        LibBrokenLine.Line memory line = LibBrokenLine.Line(time, stAmount, stSlope, cliff);
        totalSupplyLine.addOneLine(counter, line, currentBlock);
        accounts[_delegate].balance.addOneLine(counter, line, currentBlock);
        {
            uint96 slope = divUp(amount, slopePeriod);
            line = LibBrokenLine.Line(time, amount, slope, cliff);
        }
        accounts[account].locked.addOneLine(counter, line, currentBlock);
        locks[counter].account = account;
        locks[counter].delegate = _delegate;
    }

    function updateLines(address account, address _delegate, uint32 time) internal {
        totalSupplyLine.update(time);
        accounts[_delegate].balance.update(time);
        accounts[account].locked.update(time);
    }

    /**
     * Сalculate and return (newAmount, newSlope), using formula:
     * locking = (tokens * (
     *      ST_FORMULA_CONST_MULTIPLIER
     *      + ST_FORMULA_CLIFF_MULTIPLIER * (cliffPeriod - minCliffPeriod))/(MAX_CLIFF_PERIOD - minCliffPeriod)
     *      + ST_FORMULA_SLOPE_MULTIPLIER * (slopePeriod - minSlopePeriod))/(MAX_SLOPE_PERIOD - minSlopePeriod)
     *      )) / ST_FORMULA_DIVIDER
     **/
    function getLock(uint96 amount, uint32 slopePeriod, uint32 cliff) public view returns (uint96 lockAmount, uint96 lockSlope) {
        require(cliff >= minCliffPeriod, "cliff period < minimal lock period");
        require(slopePeriod >= minSlopePeriod, "slope period < minimal lock period");

        uint96 cliffSide = (uint96(cliff - uint32(minCliffPeriod)) * (ST_FORMULA_CLIFF_MULTIPLIER)) / (MAX_CLIFF_PERIOD - uint32(minCliffPeriod));
        uint96 slopeSide = (uint96((slopePeriod - uint32(minSlopePeriod))) * (ST_FORMULA_SLOPE_MULTIPLIER)) / (MAX_SLOPE_PERIOD - uint32(minSlopePeriod));
        uint96 multiplier = cliffSide + (slopeSide) + (ST_FORMULA_CONST_MULTIPLIER);
        
        uint256 amountMultiplied = uint256(amount) * uint256(multiplier);
        lockAmount = uint96(amountMultiplied / (ST_FORMULA_DIVIDER));
        lockSlope = divUp(lockAmount, slopePeriod);
    }

    function divUp(uint96 a, uint96 b) internal pure returns (uint96) {
        return ((a - 1) / b) + 1;
    }
    
    function roundTimestamp(uint32 ts) view public returns (uint32) {
        if (ts < getEpochShift()) {
            return 0;
        }
        uint32 shifted = ts - (getEpochShift());
        return shifted / WEEK - uint32(startingPointWeek);
    }

    /**
    * @notice method returns the amount of blocks to shift locking epoch to.
    * By the time of development, the default weekly-epoch calculated by main-net block number
    * would start at about 11-35 UTC on Tuesday
    * we move it to 00-00 UTC Thursday by adding 10800 blocks (approx)
    */
    function getEpochShift() internal view virtual returns (uint32) {
        return 10800;
    }

    function verifyLockOwner(uint id) internal view returns (address account) {
        account = locks[id].account;
        require(account == msg.sender, "caller not a lock owner");
    }

    function getBlockNumber() internal virtual view returns (uint32) {
        return uint32(block.number);
    }

    function setStartingPointWeek(uint32 newStartingPointWeek) public notStopped notMigrating onlyOwner {
        require(newStartingPointWeek < roundTimestamp(getBlockNumber()) , "wrong newStartingPointWeek");
        startingPointWeek = newStartingPointWeek;

        emit SetStartingPointWeek(newStartingPointWeek);
    } 

    function setMinCliffPeriod(uint32 newMinCliffPeriod) external  notStopped notMigrating onlyOwner {
        require(newMinCliffPeriod < MAX_CLIFF_PERIOD, "new cliff period > 2 years");
        minCliffPeriod = newMinCliffPeriod;

        emit SetMinCliffPeriod(newMinCliffPeriod);
    }

    function setMinSlopePeriod(uint32 newMinSlopePeriod) external  notStopped notMigrating onlyOwner {
        require(newMinSlopePeriod < MAX_SLOPE_PERIOD, "new slope period > 2 years");
        minSlopePeriod = newMinSlopePeriod;

        emit SetMinSlopePeriod(newMinSlopePeriod);
    }

    /**
        @notice checks if the line is relevant and needs to be copied to the new data structure
     */
    function isRelevant(uint id) external view returns(bool, uint, address, uint, address) {
        uint32 currentBlock = getBlockNumber();
        uint32 currentEpoch = roundTimestamp(currentBlock);

        address delegate = locks[id].delegate;
        LibBrokenLine.LineDataOld storage oldLineBalance = accountsOld[delegate].balance.initiatedLines[id];

        address account = locks[id].account;
        LibBrokenLine.LineDataOld storage oldLineLocked = accountsOld[account].locked.initiatedLines[id];

        //line adds at time start + cliff + slopePeriod + 1(mod)
        uint slopeLocked = (oldLineLocked.line.bias / oldLineLocked.line.slope);
        uint slopeBalance = (oldLineBalance.line.bias / oldLineBalance.line.slope);
        uint slope = slopeLocked > slopeBalance ? slopeLocked : slopeBalance;
        
        uint finishTime = oldLineLocked.line.start + oldLineLocked.cliff + slope + 1;

        return ((finishTime < currentEpoch) ? false : true, oldLineBalance.line.start, delegate, oldLineLocked.line.start, account);
    }

    /**
     * @dev Throws if stopped
     */
    modifier notStopped() {
        require(!stopped, "stopped");
        _;
    }

    /**
     * @dev Throws if not stopped
     */
    modifier isStopped() {
        require(stopped, "not stopped");
        _;
    }

    modifier notMigrating() {
        require(migrateTo == address(0), "migrating");
        _;
    }

    function updateAccountLines(address account, uint32 time) public notStopped notMigrating onlyOwner {
        accounts[account].balance.update(time);
        accounts[account].locked.update(time);
    }

    function updateTotalSupplyLine(uint32 time) public notStopped notMigrating onlyOwner {
        totalSupplyLine.update(time);
    }

    function updateAccountLinesBlockNumber(address account, uint32 blockNumber) external notStopped notMigrating onlyOwner {
        uint32 time = roundTimestamp(blockNumber);
        updateAccountLines(account, time);
    }
    
    function updateTotalSupplyLineBlockNumber(uint32 blockNumber) external notStopped notMigrating onlyOwner {
        uint32 time = roundTimestamp(blockNumber);
        updateTotalSupplyLine(time);
    }

    function migrateBalanceLines(uint[] calldata ids) external onlyOwner {
        uint len = ids.length;
        for (uint i = 0; i < len; i++) {
            uint id = ids[i];
            Lock storage lock = locks[id];
            address user = lock.delegate;
            LibBrokenLine.LineDataOld storage oldLine = accountsOld[user].balance.initiatedLines[id];

             LibBrokenLine.Line memory line = LibBrokenLine.Line({
                start: uint32(oldLine.line.start),
                bias: uint96(oldLine.line.bias),
                slope: uint96(oldLine.line.slope),
                cliff: uint32(oldLine.cliff)
            });

            //adding the line to balance broken line
            accounts[user].balance._addOneLine(id, line);
            //adding the line to totalSupply broken line
            totalSupplyLine._addOneLine(id, line);
        }
    }

    function migrateLockedLines(uint[] calldata ids) external onlyOwner {
        uint len = ids.length;
        for (uint i = 0; i < len; i++) {
            uint id = ids[i];
            Lock storage lock = locks[id];
            address user = lock.account;
            LibBrokenLine.LineDataOld storage oldLine = accountsOld[user].locked.initiatedLines[id];

             LibBrokenLine.Line memory line = LibBrokenLine.Line({
                start: uint32(oldLine.line.start),
                bias: uint96(oldLine.line.bias),
                slope: uint96(oldLine.line.slope),
                cliff: uint32(oldLine.cliff)
            });

            //adding the line to balance broken line
            accounts[user].locked._addOneLine(id, line);
        }
    }


    function copyAmountMakeSnapshots(address[] calldata users) external onlyOwner {
        uint32 currentBlock = getBlockNumber();
        uint32 currentEpoch = roundTimestamp(currentBlock);
        uint len = users.length;
        for (uint i = 0; i < len; i++) {
            Account storage newData = accounts[users[i]];
            AccountOld storage oldData = accountsOld[users[i]];

            //copy amount
            newData.amount = uint96(oldData.amount);

            if (newData.balance.initial.bias > 0) {
                newData.balance.update(currentEpoch);
                newData.balance.saveSnapshot(currentEpoch, currentBlock);
            }

            if (newData.locked.initial.bias > 0) {
                newData.locked.update(currentEpoch);
                newData.locked.saveSnapshot(currentEpoch, currentBlock);
            }
        }

        totalSupplyLine.saveSnapshot(currentEpoch, currentBlock);

    }

    //48 => 43 add new accounts and totalSupplyLine
    uint256[43] private __gap;

}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "./LockingBase.sol";

abstract contract LockingRelock is LockingBase {
    using LibBrokenLine for LibBrokenLine.BrokenLine;

    function relock(uint id, address newDelegate, uint96 newAmount, uint32 newSlopePeriod, uint32 newCliff) external notStopped notMigrating returns (uint) {
        address account = verifyLockOwner(id);
        uint32 currentBlock = getBlockNumber();
        uint32 time = roundTimestamp(currentBlock);
        verification(account, id, newAmount, newSlopePeriod, newCliff, time);

        address _delegate = locks[id].delegate;
        accounts[account].locked.update(time);

        rebalance(id, account, accounts[account].locked.initial.bias, removeLines(id, account, _delegate, time), newAmount);

        counter++;

        addLines(account, newDelegate, newAmount, newSlopePeriod, newCliff, time, currentBlock);
        emit Relock(id, account, newDelegate, counter, time, newAmount, newSlopePeriod, newCliff);

        return counter;
    }

    /**
     * @dev Verification parameters:
     *      1. amount > 0, slope > 0
     *      2. cliff period and slope period less or equal two years
     *      3. newFinishTime more or equal oldFinishTime
     */
    function verification(address account, uint id, uint96 newAmount, uint32 newSlopePeriod, uint32 newCliff, uint32 toTime) internal view {
        require(newAmount > 0, "zero amount");
        require(newCliff <= MAX_CLIFF_PERIOD, "cliff too big");
        require(newSlopePeriod <= MAX_SLOPE_PERIOD, "slope period too big");
        require(newSlopePeriod > 0, "slope period equal 0");

        //check Line with new parameters don`t finish earlier than old Line
        uint32 newEnd = toTime + (newCliff) + (newSlopePeriod);
        LibBrokenLine.Line memory line = accounts[account].locked.initiatedLines[id];
        uint32 oldSlopePeriod = uint32(divUp(line.bias, line.slope));
        uint32 oldEnd = line.start + (line.cliff) + (oldSlopePeriod);
        require(oldEnd <= newEnd, "new line period lock too short");

        //check Line with new parameters don`t cut corner old Line
        uint32 oldCliffEnd = line.start + (line.cliff);
        uint32 newCliffEnd = toTime + (newCliff);
        if (oldCliffEnd > newCliffEnd) {
            uint32 balance = oldCliffEnd - (newCliffEnd);
            uint32 newSlope = uint32(divUp(newAmount, newSlopePeriod));
            uint96 newBias = newAmount - (balance * (newSlope));
            require(newBias >= line.bias, "detect cut deposit corner");
        }
    }

    function removeLines(uint id, address account, address delegate, uint32 toTime) internal returns (uint96 residue) {
        updateLines(account, delegate, toTime);
        uint32 currentBlock = getBlockNumber();
        accounts[delegate].balance.remove(id, toTime, currentBlock);
        totalSupplyLine.remove(id, toTime, currentBlock);
        (residue,,) = accounts[account].locked.remove(id, toTime, currentBlock);
    }

    function rebalance(uint id, address account, uint96 bias, uint96 residue, uint96 newAmount) internal {
        require(residue <= newAmount, "Impossible to relock: less amount, then now is");
        uint96 addAmount = newAmount - (residue);
        uint96 amount = accounts[account].amount;
        uint96 balance = amount - (bias);
        if (addAmount > balance) {
            //need more, than balance, so need transfer tokens to this
            uint96 transferAmount = addAmount - (balance);
            accounts[account].amount = accounts[account].amount + (transferAmount);
            require(token.transferFrom(locks[id].account, address(this), transferAmount), "transfer failed");
        }
    }

    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "./LockingBase.sol";

contract LockingVotes is LockingBase {
    using LibBrokenLine for LibBrokenLine.BrokenLine;

    /**
     * @dev Returns the current amount of votes that `account` has.
     */
    function getVotes(address account) external override view returns (uint256) {
        uint32 currentBlock = getBlockNumber();
        uint32 currentWeek = roundTimestamp(currentBlock);
        return accounts[account].balance.actualValue(currentWeek, currentBlock);
    }

    /**
     * @dev Returns the amount of votes that `account` had
     * at the end of the last period
     */
    function getPastVotes(address account, uint256 blockNumber) external override view returns (uint256) {
        uint32 currentWeek = roundTimestamp(uint32(blockNumber));
        require(blockNumber < getBlockNumber() && currentWeek > 0, "block not yet mined");

        return accounts[account].balance.actualValue(currentWeek, uint32(blockNumber));
    }

    /**
     * @dev Returns the total supply of votes available 
     * at the end of the last period
     */
    function getPastTotalSupply(uint256 blockNumber) external override view returns (uint256) {
        uint32 currentWeek = roundTimestamp(uint32(blockNumber));
        require(blockNumber < getBlockNumber() && currentWeek > 0, "block not yet mined");

        return totalSupplyLine.actualValue(currentWeek, uint32(blockNumber));
    }

    /**
     * @dev Returns the delegate that `account` has chosen.
     */
    function delegates(address account) external override view returns (address) {
        revert("not implemented");
    }

    /**
     * @dev Delegates votes from the sender to `delegatee`.
     */
    function delegate(address delegatee) external override {
        revert("not implemented");
    }

    /**
     * @dev Delegates votes from signer to `delegatee`.
     */
    function delegateBySig(
        address delegatee,
        uint256 nonce,
        uint256 expiry,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external override {
        revert("not implemented");
    }

    uint256[50] private __gap;
}