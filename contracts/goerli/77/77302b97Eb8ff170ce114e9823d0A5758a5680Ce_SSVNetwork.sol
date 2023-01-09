// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (proxy/utils/Initializable.sol)

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

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
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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
// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}

// File: contracts/ISSVNetwork.sol
// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.2;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface ISSVNetwork {

    struct Cluster {
        uint32 validatorCount;
        uint64 networkFee;
        uint64 networkFeeIndex;
        uint64 index;
        uint64 balance;
        bool disabled;
    }

    /**********/
    /* Events */
    /**********/

    /**
     * @dev Emitted when a new operator has been added.
     * @param id operator's ID.
     * @param owner Operator's ethereum address that can collect fees.
     * @param publicKey Operator's public key. Will be used to encrypt secret shares of validators keys.
     * @param fee Operator's fee.
     */
    event OperatorAdded(
        uint64 id,
        address indexed owner,
        bytes publicKey,
        uint256 fee
    );

    /**
     * @dev Emitted when operator has been removed.
     * @param id operator's ID.
     */
    event OperatorRemoved(uint64 id);

    /**
     * @dev Emitted when the validator has been added.
     * @param publicKey The public key of a validator.
     * @param operatorIds The operator ids list.
     * @param shares snappy compressed shares(a set of encrypted and public shares).
     * @param cluster All the cluster data.
     */
    event ValidatorAdded(
        address indexed owner,
        uint64[] indexed operatorIds,
        bytes publicKey,
        bytes shares,
        Cluster cluster
    );

    /**
     * @dev Emitted when the validator is removed.
     * @param publicKey The public key of a validator.
     * @param operatorIds The operator ids list.
     * @param cluster All the cluster data.
     */
    event ValidatorRemoved(
        address indexed owner,
        uint64[] indexed operatorIds,
        bytes publicKey,
        Cluster cluster
    );

    event OperatorFeeDeclaration(
        address indexed owner,
        uint64 operatorId,
        uint256 blockNumber,
        uint256 fee
    );

    /**
     * @dev Emitted when operator changed fee.
     * @param id operator's ID.
     * @param fee operator's new fee.
     */
    event OperatorFeeSet(uint64 id, uint64 fee);

    event OperatorFeeCancelationDeclared(address indexed owner, uint64 operatorId);

    /**
     * @dev Emitted when an operator's fee is updated.
     * @param owner Operator's owner.
     * @param blockNumber from which block number.
     * @param fee updated fee value.
     */
    event OperatorFeeExecution(
        address indexed owner,
        uint64 operatorId,
        uint256 blockNumber,
        uint256 fee
    );

    event ClusterLiquidated(address indexed owner, uint64[] indexed operatorIds, Cluster cluster);

    event ClusterReactivated(address indexed owner, uint64[] indexed operatorIds, Cluster cluster);

    event OperatorFeeIncreaseLimitUpdate(uint64 value);

    event DeclareOperatorFeePeriodUpdate(uint64 value);

    event ExecuteOperatorFeePeriodUpdate(uint64 value);

    event LiquidationThresholdPeriodUpdate(uint64 value);

    event ValidatorsPerOperatorLimitUpdate(uint64 value);

    /**
     * @dev Emitted when the network fee is updated.
     * @param oldFee The old fee
     * @param newFee The new fee
     */
    event NetworkFeeUpdate(uint256 oldFee, uint256 newFee);

    /**
     * @dev Emitted when transfer fees are withdrawn.
     * @param value The amount of tokens withdrawn.
     * @param recipient The recipient address.
     */
    event NetworkEarningsWithdrawn(uint256 value, address recipient);

    event ClusterWithdrawn(address indexed owner, uint64[] indexed operatorIds, uint256 value, Cluster cluster);
    event OperatorWithdrawn(uint256 value, uint64 operatorId, address owner);

    event ClusterDeposit(
        address indexed owner,
        uint64[] indexed operatorIds,
        uint256 value,
        Cluster cluster
    );

    event FeeRecipientAddressUpdated(
        address owner,
        address recipientAddress
    );

    /**********/
    /* Errors */
    /**********/

    error CallerNotOwner();
    error FeeTooLow();
    error FeeExceedsIncreaseLimit();
    error NoFeeDelcared();
    error ApprovalNotWithinTimeframe();
    error OperatorDoesNotExist();
    error InsufficientBalance();
    error ValidatorAlreadyExists();
    error ClusterLiquidatable();
    error ClusterNotLiquidatable();
    error InvalidPublicKeyLength();
    error InvalidOperatorIdsLengthuctureInvalid();
    error NoValidatorOwnership();
    error ParametersMismatch();
    error InsufficientFunds();
    error ClusterAlreadyEnabled();
    error ClusterIsLiquidated();
    error ClusterDoesNotExists();
    error BurnRatePositive();
    error IncorrectClusterState();
    error UnsortedOperatorsList();
    error NewBlockPeriodIsBelowMinimum();
    error ExceedValidatorLimit();

    /****************/
    /* Initializers */
    /****************/

    /**
     * @dev Initializes the contract.
     * @param token_ The network token.
     * @param operatorMaxFeeIncrease_ The step limit to increase the operator fee
     * @param declareOperatorFeePeriod_ The period an operator needs to wait before they can approve their fee.
     * @param executeOperatorFeePeriod_ The length of the period in which an operator can approve their fee.
     * @param validatorsPerOperatorLimit_ The limit of validators per operator
     */
    function initialize(
        IERC20 token_,
        uint64 operatorMaxFeeIncrease_,
        uint64 declareOperatorFeePeriod_,
        uint64 executeOperatorFeePeriod_,
        uint64 minimumBlocksBeforeLiquidation_,
        uint64 validatorsPerOperatorLimit_
    ) external;

    /*******************************/
    /* Operator External Functions */
    /*******************************/

    /**
     * @dev Registers a new operator.
     * @param publicKey Operator's public key. Used to encrypt secret shares of validators keys.
     * @param fee operator's fee.
     */
    function registerOperator(
        bytes calldata publicKey,
        uint256 fee
    ) external returns (uint64);

    /**
     * @dev Removes an operator.
     * @param id Operator's id.
     */
    function removeOperator(uint64 id) external;

    function declareOperatorFee(uint64 operatorId, uint256 fee) external;

    function executeOperatorFee(uint64 operatorId) external;

    function cancelDeclaredOperatorFee(uint64 operatorId) external;

    function setFeeRecipientAddress(address feeRecipientAddress) external;

    /********************************/
    /* Validator External Functions */
    /********************************/

    function registerValidator(
        bytes calldata publicKey,
        uint64[] memory operatorIds,
        bytes calldata sharesEncrypted,
        uint256 amount,
        Cluster memory cluster
    ) external;

    function removeValidator(
        bytes calldata publicKey,
        uint64[] memory operatorIds,
        Cluster memory cluster
    ) external;

    /**************************/
    /* Cluster External Functions */
    /**************************/

    function liquidate(
        address owner,
        uint64[] memory operatorIds,
        Cluster memory cluster
    ) external;

    function reactivate(
        uint64[] memory operatorIds,
        uint256 amount,
        Cluster memory cluster
    ) external;

    /******************************/
    /* Balance External Functions */
    /******************************/

    function deposit(
        address owner,
        uint64[] memory operatorIds,
        uint256 amount,
        Cluster memory cluster
    ) external;

    function deposit(
        uint64[] memory operatorIds,
        uint256 amount,
        Cluster memory cluster
    ) external;

    function withdrawOperatorEarnings(uint64 operatorId, uint256 tokenAmount) external;

    function withdrawOperatorEarnings(uint64 operatorId) external;

    function withdraw(
        uint64[] memory operatorIds,
        uint256 tokenAmount,
        Cluster memory cluster
    ) external;

    /**************************/
    /* DAO External Functions */
    /**************************/

    function updateNetworkFee(uint256 fee) external;

    function withdrawNetworkEarnings(uint256 amount) external;

    function updateOperatorFeeIncreaseLimit(
        uint64 newOperatorMaxFeeIncrease
    ) external;

    function updateDeclareOperatorFeePeriod(
        uint64 newDeclareOperatorFeePeriod
    ) external;

    function updateExecuteOperatorFeePeriod(
        uint64 newExecuteOperatorFeePeriod
    ) external;

    function updateLiquidationThresholdPeriod(uint64 blocks) external;

    function updateValidatorsPerOperatorLimit(uint64 limit) external;

    /************************************/
    /* Operator External View Functions */
    /************************************/

    function getOperatorFee(uint64 operatorId) external view returns (uint256);

    function getOperatorDeclaredFee(
        uint64 operatorId
    ) external view returns (uint256, uint256, uint256);

    function getOperatorById(
        uint64 operatorId
    ) external view returns (address owner, uint256 fee, uint32 validatorCount);

    /*******************************/
    /* Cluster External View Functions */
    /*******************************/

    function isLiquidatable(
        address owner,
        uint64[] memory operatorIds,
        Cluster memory cluster
    ) external view returns(bool);

    function isLiquidated(
        address owner,
        uint64[] memory operatorIds,
        Cluster memory cluster
    ) external view returns(bool);

    function getClusterBurnRate(uint64[] memory operatorIds) external view returns (uint256);

    /***********************************/
    /* Balance External View Functions */
    /***********************************/

    /**
     * @dev Gets the operators current snapshot.
     * @param id Operator's id.
     * @return currentBlock the block that the snapshot is updated to.
     * @return index the index of the operator.
     * @return balance the current balance of the operator.
     */
    function getOperatorEarnings(uint64 id) external view returns (uint64 currentBlock, uint64 index, uint256 balance);

    function getBalance(
        address owner,
        uint64[] memory operatorIds,
        Cluster memory cluster
    ) external view returns (uint256);

    /*******************************/
    /* DAO External View Functions */
    /*******************************/

    function getNetworkFee() external view returns (uint256);

    function getNetworkEarnings() external view returns (uint256);

    function getOperatorFeeIncreaseLimit() external view returns (uint64);

    function getExecuteOperatorFeePeriod() external view returns (uint64);

    function getDeclaredOperatorFeePeriod() external view returns (uint64);

    function getLiquidationThresholdPeriod() external view returns (uint64);

    function getValidatorsPerOperatorLimit() external view returns (uint64);
}

// File: contracts/SSVRegistry.sol
// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.2;

import "./ISSVNetwork.sol";

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "./utils/Types.sol";

// import "hardhat/console.sol";

contract SSVNetwork is OwnableUpgradeable, ISSVNetwork {
    /*************/
    /* Libraries */
    /*************/

    using Types256 for uint256;
    using Types64 for uint64;

    using Counters for Counters.Counter;

    /***********/
    /* Structs */
    /***********/

    struct Snapshot {
        /// @dev block is the last block in which last index was set
        uint64 block;
        /// @dev index is the last index calculated by index += (currentBlock - block) * fee
        uint64 index;
        /// @dev accumulated is all the accumulated earnings, calculated by accumulated + lastIndex * validatorCount
        uint64 balance;
    }

    struct Operator {
        address owner;
        uint64 fee;
        uint32 validatorCount;
        Snapshot snapshot;
    }

    struct OperatorFeeChangeRequest {
        uint64 fee;
        uint64 approvalBeginTime;
        uint64 approvalEndTime;
    }

    struct DAO {
        uint32 validatorCount;
        uint64 withdrawn;
        Snapshot earnings;
    }
    /*
    struct Cluster {
        uint64[] operatorIds;
    }
    */

    struct Validator {
        address owner;
        bool active;
    }

    /*************/
    /* Constants */
    /*************/

    uint64 constant MINIMAL_LIQUIDATION_THRESHOLD = 6570;
    uint64 constant MINIMAL_OPERATOR_FEE = 100000000;

    /********************/
    /* Global Variables */
    /********************/

    Counters.Counter private lastOperatorId;

    /*************/
    /* Variables */
    /*************/

    mapping(uint64 => Operator) private _operators;
    mapping(uint64 => OperatorFeeChangeRequest)
        private _operatorFeeChangeRequests;
    // mapping(bytes32 => Cluster) private _clusters;
    mapping(bytes32 => bytes32) private _clusters;
    mapping(bytes32 => Validator) _validatorPKs;

    uint64 private _networkFee;
    uint64 private _networkFeeIndex;
    uint64 private _networkFeeIndexBlockNumber;

    uint64 private _declareOperatorFeePeriod;
    uint64 private _executeOperatorFeePeriod;
    uint64 private _operatorMaxFeeIncrease;
    uint64 private _minimumBlocksBeforeLiquidation;
    uint64 private _validatorsPerOperatorLimit;

    DAO private _dao;
    IERC20 private _token;

    /*************/
    /* Modifiers */
    /*************/

    modifier onlyOperatorOwnerOrContractOwner(uint64 operatorId) {
        _onlyOperatorOwnerOrContractOwner(operatorId);
        _;
    }

    /****************/
    /* Initializers */
    /****************/

    function initialize(
        IERC20 token_,
        uint64 operatorMaxFeeIncrease_,
        uint64 declareOperatorFeePeriod_,
        uint64 executeOperatorFeePeriod_,
        uint64 minimumBlocksBeforeLiquidation_,
        uint64 validatorsPerOperatorLimit_
    ) external override {
        __SSVNetwork_init(
            token_,
            operatorMaxFeeIncrease_,
            declareOperatorFeePeriod_,
            executeOperatorFeePeriod_,
            minimumBlocksBeforeLiquidation_,
            validatorsPerOperatorLimit_
        );
    }

    /*******************************/
    /* Operator External Functions */
    /*******************************/

    function registerOperator(
        bytes calldata publicKey,
        uint256 fee
    ) external override returns (uint64 id) {
        if (fee < MINIMAL_OPERATOR_FEE) {
            revert FeeTooLow();
        }

        lastOperatorId.increment();
        id = uint64(lastOperatorId.current());
        _operators[id] = Operator({ owner: msg.sender, snapshot: Snapshot({ block: uint64(block.number), index: 0, balance: 0}), validatorCount: 0, fee: fee.shrink()});
        emit OperatorAdded(id, msg.sender, publicKey, fee);
    }

    function removeOperator(uint64 id) external override {
        Operator memory operator = _operators[id];
        if (operator.owner != msg.sender) revert CallerNotOwner();

        operator.snapshot = _getSnapshot(operator, uint64(block.number));

        if (operator.snapshot.balance > 0) {
            _transferOperatorBalanceUnsafe(id, operator.snapshot.balance.expand());
        }

        operator.snapshot.block = 0;
        operator.snapshot.balance = 0;
        operator.validatorCount = 0;
        operator.fee = 0;

        _operators[id] = operator;
        emit OperatorRemoved(id);
    }

    function declareOperatorFee(
        uint64 operatorId,
        uint256 fee
    ) external override onlyOperatorOwnerOrContractOwner(operatorId) {
        if (fee < MINIMAL_OPERATOR_FEE) revert FeeTooLow();

        uint64 shrunkFee = fee.shrink();

        // @dev 100%  =  10000, 10% = 1000 - using 10000 to represent 2 digit precision
        uint64 maxAllowedFee = (_operators[operatorId].fee *
            (10000 + _operatorMaxFeeIncrease)) / 10000;

        if (shrunkFee > maxAllowedFee) revert FeeExceedsIncreaseLimit();

        _operatorFeeChangeRequests[operatorId] = OperatorFeeChangeRequest(
            shrunkFee,
            uint64(block.timestamp) + _declareOperatorFeePeriod,
            uint64(block.timestamp) +
                _declareOperatorFeePeriod +
                _executeOperatorFeePeriod
        );
        emit OperatorFeeDeclaration(msg.sender, operatorId, block.number, fee);
    }

    function executeOperatorFee(
        uint64 operatorId
    ) external override onlyOperatorOwnerOrContractOwner(operatorId) {
        OperatorFeeChangeRequest
            memory feeChangeRequest = _operatorFeeChangeRequests[operatorId];

        if(feeChangeRequest.fee == 0) revert NoFeeDelcared();

        if (
            block.timestamp < feeChangeRequest.approvalBeginTime ||
            block.timestamp > feeChangeRequest.approvalEndTime
        ) {
            revert ApprovalNotWithinTimeframe();
        }

        _updateOperatorFeeUnsafe(operatorId, feeChangeRequest.fee);

        delete _operatorFeeChangeRequests[operatorId];
    }

    function cancelDeclaredOperatorFee(uint64 operatorId) onlyOperatorOwnerOrContractOwner(operatorId) external override {
        if(_operatorFeeChangeRequests[operatorId].fee == 0) revert NoFeeDelcared();

        delete _operatorFeeChangeRequests[operatorId];

        emit OperatorFeeCancelationDeclared(msg.sender, operatorId);
    }

    function setFeeRecipientAddress(address recipientAddress) external override {
        emit FeeRecipientAddressUpdated(msg.sender, recipientAddress);
    }

    /********************************/
    /* Validator External Functions */
    /********************************/
    function registerValidator(
        bytes calldata publicKey,
        uint64[] memory operatorIds,
        bytes calldata sharesEncrypted,
        uint256 amount,
        Cluster memory cluster
    ) external override {
        uint operatorsLength = operatorIds.length;

        {
            _validateOperatorIds(operatorsLength);
            _validatePublicKey(publicKey);
        }

        {
            if (_validatorPKs[keccak256(publicKey)].owner != address(0)) {
                revert ValidatorAlreadyExists();
            }
            _validatorPKs[keccak256(publicKey)] = Validator({
                owner: msg.sender,
                active: true
            });
        }

        uint64 clusterIndex;
        uint64 burnRate;
        {
            if (!cluster.disabled) {
                for (uint i; i < operatorsLength;) {
                    if (i+1 < operatorsLength) {
                        if (operatorIds[i] > operatorIds[i+1]) {
                            revert UnsortedOperatorsList();
                        }
                    }
                    Operator memory operator = _operators[operatorIds[i]];
                    if (operator.snapshot.block == 0) {
                        revert OperatorDoesNotExist();
                    }
                    operator.snapshot = _getSnapshot(operator, uint64(block.number));

                    if (++operator.validatorCount > _validatorsPerOperatorLimit) {
                        revert ExceedValidatorLimit();
                    }
                    clusterIndex += operator.snapshot.index;
                    burnRate += operator.fee;
                    _operators[operatorIds[i]] = operator;
                    unchecked {
                        ++i;
                    }
                }
            }
        }

        bytes32 hashedCluster = keccak256(abi.encodePacked(msg.sender, operatorIds));
        {
            bytes32 hashedClusterData = keccak256(abi.encodePacked(cluster.validatorCount, cluster.networkFee, cluster.networkFeeIndex, cluster.index, cluster.balance, cluster.disabled ));
            if (_clusters[hashedCluster] == bytes32(0)) {
                cluster = Cluster({ validatorCount: 0, networkFee: 0, networkFeeIndex: 0, index: 0, balance: 0, disabled: false });
            } else if (_clusters[hashedCluster] != hashedClusterData) {
                revert IncorrectClusterState();
            }
        }

        cluster.balance += amount.shrink();
        cluster = _updateClusterData(cluster, clusterIndex, 1);

        if (_liquidatable(_clusterBalance(cluster, clusterIndex), cluster.validatorCount, burnRate)) {
            revert InsufficientBalance();
        }

        {
            if (!cluster.disabled) {
                DAO memory dao = _dao;
                dao = _updateDAOEarnings(dao);
                ++dao.validatorCount;
                _dao = dao;
            }
        }

        _clusters[hashedCluster] = keccak256(abi.encodePacked(cluster.validatorCount, cluster.networkFee, cluster.networkFeeIndex, cluster.index, cluster.balance, cluster.disabled ));

        if (amount > 0) {
            _deposit(msg.sender, operatorIds, amount.shrink());
        }

        emit ValidatorAdded(msg.sender, operatorIds, publicKey, sharesEncrypted, cluster);
    }

    function removeValidator(
        bytes calldata publicKey,
        uint64[] memory operatorIds,
        Cluster memory cluster
    ) external override {
        uint operatorsLength = operatorIds.length;

        {
            _validateOperatorIds(operatorsLength);
            _validatePublicKey(publicKey);
        }

        bytes32 hashedValidator = keccak256(publicKey);
        if (_validatorPKs[hashedValidator].owner != msg.sender) {
            revert NoValidatorOwnership();
        }

        uint64 clusterIndex;
        {
            if (!cluster.disabled) {
                for (uint i; i < operatorsLength;) {
                    Operator memory operator = _operators[operatorIds[i]];
                    if (operator.snapshot.block != 0) {
                        operator.snapshot = _getSnapshot(
                            operator,
                            uint64(block.number)
                        );
                        --operator.validatorCount;
                        _operators[operatorIds[i]] = operator;
                    }
                    
                    clusterIndex += operator.snapshot.index;
                    unchecked { ++i; }
                }
            }
        }

        bytes32 hashedCluster = _validateHashedCluster(msg.sender, operatorIds, cluster);

        cluster = _updateClusterData(cluster, clusterIndex, -1);

        {
            if (!cluster.disabled) {
                DAO memory dao = _dao;
                dao = _updateDAOEarnings(dao);
                --dao.validatorCount;
                _dao = dao;
            }
        }
        delete _validatorPKs[hashedValidator];

        _clusters[hashedCluster] = keccak256(abi.encodePacked(cluster.validatorCount, cluster.networkFee, cluster.networkFeeIndex, cluster.index, cluster.balance, cluster.disabled ));

        emit ValidatorRemoved(msg.sender, operatorIds, publicKey, cluster);
    }

    function liquidate(
        address owner,
        uint64[] memory operatorIds,
        Cluster memory cluster
    ) external override {
        _validateClusterIsNotLiquidated(cluster);

        bytes32 hashedCluster = _validateHashedCluster(owner, operatorIds, cluster);

        uint64 clusterIndex;
        uint64 burnRate;
        {
            uint operatorsLength = operatorIds.length;
            for (uint i; i < operatorsLength; ) {
                Operator memory operator = _operators[operatorIds[i]];
                uint64 currentBlock = uint64(block.number);
                if (operator.snapshot.block != 0) {
                    operator.snapshot = _getSnapshot(operator, currentBlock);
                    operator.validatorCount -= cluster.validatorCount;
                    burnRate += operator.fee;
                    _operators[operatorIds[i]] = operator;
                }
                
                clusterIndex += operator.snapshot.index;
                unchecked { ++i; }
            }
        }

        {
            uint64 clusterBalance = _clusterBalance(cluster, clusterIndex);
            if (!_liquidatable(clusterBalance, cluster.validatorCount, burnRate)) {
                revert ClusterNotLiquidatable();
            }

            _token.transfer(msg.sender, clusterBalance.expand());

            cluster.disabled = true;
            cluster.balance = 0;
            cluster.index = 0;
        }

        {
            DAO memory dao = _dao;
            dao = _updateDAOEarnings(dao);
            dao.validatorCount -= cluster.validatorCount;
            _dao = dao;
        }

        _clusters[hashedCluster] = keccak256(abi.encodePacked(cluster.validatorCount, cluster.networkFee, cluster.networkFeeIndex, cluster.index, cluster.balance, cluster.disabled ));

        emit ClusterLiquidated(owner, operatorIds, cluster);
    }

    function reactivate(
        uint64[] memory operatorIds,
        uint256 amount,
        Cluster memory cluster
    ) external override {

        if (!cluster.disabled) {
            revert ClusterAlreadyEnabled();
        }

        uint64 clusterIndex;
        uint64 burnRate;
        {
            uint operatorsLength = operatorIds.length;
            for (uint i; i < operatorsLength; ) {
                Operator memory operator = _operators[operatorIds[i]];
                if (operator.snapshot.block != 0) {
                    operator.snapshot = _getSnapshot(operator, uint64(block.number));
                    operator.validatorCount += cluster.validatorCount;
                    burnRate += operator.fee;
                    _operators[operatorIds[i]] = operator;
                }

                clusterIndex += operator.snapshot.index;
                unchecked { ++i; }
            }
        }

        bytes32 hashedCluster = _validateHashedCluster(msg.sender, operatorIds, cluster);

        cluster.balance += amount.shrink();
        cluster.disabled = false;
        cluster.index = clusterIndex;

        cluster = _updateClusterData(cluster, clusterIndex, 0);

        {
            DAO memory dao = _dao;
            dao = _updateDAOEarnings(dao);
            dao.validatorCount += cluster.validatorCount;
            _dao = dao;
        }

        if (_liquidatable(_clusterBalance(cluster, clusterIndex), cluster.validatorCount, burnRate)) {
            revert InsufficientBalance();
        }

        _clusters[hashedCluster] = keccak256(abi.encodePacked(cluster.validatorCount, cluster.networkFee, cluster.networkFeeIndex, cluster.index, cluster.balance, cluster.disabled ));

        if (amount > 0) {
            _deposit(msg.sender, operatorIds, amount.shrink());
        }

        emit ClusterReactivated(msg.sender, operatorIds, cluster);
    }

    /******************************/
    /* Balance External Functions */
    /******************************/

    function deposit(
        address owner,
        uint64[] calldata operatorIds,
        uint256 amount,
        Cluster memory cluster
    ) external override {
        _validateClusterIsNotLiquidated(cluster);

        uint64 shrunkAmount = amount.shrink();

        bytes32 hashedCluster = _validateHashedCluster(owner, operatorIds, cluster);

        cluster.balance += shrunkAmount;

        _clusters[hashedCluster] = keccak256(abi.encodePacked(cluster.validatorCount, cluster.networkFee, cluster.networkFeeIndex, cluster.index, cluster.balance, cluster.disabled ));

        _deposit(owner, operatorIds, shrunkAmount);

        emit ClusterDeposit(owner, operatorIds, amount, cluster);
    }

    function deposit(
        uint64[] calldata operatorIds,
        uint256 amount,
        Cluster memory cluster
    ) external override {
        _validateClusterIsNotLiquidated(cluster);

        uint64 shrunkAmount = amount.shrink();

        bytes32 hashedCluster = _validateHashedCluster(msg.sender, operatorIds, cluster);

        cluster.balance += shrunkAmount;

        _deposit(msg.sender, operatorIds, shrunkAmount);

        _clusters[hashedCluster] = keccak256(abi.encodePacked(cluster.validatorCount, cluster.networkFee, cluster.networkFeeIndex, cluster.index, cluster.balance, cluster.disabled ));

        emit ClusterDeposit(msg.sender, operatorIds, amount, cluster);
    }

    function withdrawOperatorEarnings(uint64 operatorId, uint256 amount) external override {
        Operator memory operator = _operators[operatorId];

        if (operator.owner != msg.sender) revert CallerNotOwner();

        operator.snapshot = _getSnapshot(operator, uint64(block.number));

        uint64 shrunkAmount = amount.shrink();

        if (operator.snapshot.balance < shrunkAmount) {
            revert InsufficientBalance();
        }

        operator.snapshot.balance -= shrunkAmount;

        _operators[operatorId] = operator;

        _transferOperatorBalanceUnsafe(operatorId, amount);
    }

    function withdrawOperatorEarnings(uint64 operatorId) external override {
        Operator memory operator = _operators[operatorId];

        if (operator.owner != msg.sender) revert CallerNotOwner();

        operator.snapshot = _getSnapshot(operator, uint64(block.number));

        uint64 operatorBalance = operator.snapshot.balance;

        if (operatorBalance <= 0) {
            revert InsufficientBalance();
        }

        operator.snapshot.balance -= operatorBalance;

        _operators[operatorId] = operator;

        _transferOperatorBalanceUnsafe(operatorId, operatorBalance.expand());
    }

    function withdraw(
        uint64[] memory operatorIds,
        uint256 amount,
        Cluster memory cluster
    ) external override {
        _validateClusterIsNotLiquidated(cluster);

        uint64 shrunkAmount = amount.shrink();

        uint64 clusterIndex;
        uint64 burnRate;
        {
            uint operatorsLength = operatorIds.length;
            for (uint i; i < operatorsLength; ) {
                Operator memory operator = _operators[operatorIds[i]];
                clusterIndex += operator.snapshot.index + (uint64(block.number) - operator.snapshot.block) * operator.fee;
                burnRate += operator.fee;
                unchecked {
                    ++i;
                }
            }
        }

        bytes32 hashedCluster = _validateHashedCluster(msg.sender, operatorIds, cluster);

        uint64 clusterBalance = _clusterBalance(cluster, clusterIndex);

        if (clusterBalance < shrunkAmount || _liquidatable(clusterBalance, cluster.validatorCount, burnRate)) {
            revert InsufficientBalance();
        }

        cluster.balance -= shrunkAmount;

        _clusters[hashedCluster] = keccak256(abi.encodePacked(cluster.validatorCount, cluster.networkFee, cluster.networkFeeIndex, cluster.index, cluster.balance, cluster.disabled ));

        _token.transfer(msg.sender, amount);

        emit ClusterWithdrawn(msg.sender, operatorIds, amount, cluster);
    }

    /**************************/
    /* DAO External Functions */
    /**************************/

    function updateNetworkFee(uint256 fee) external override onlyOwner {
        DAO memory dao = _dao;
        dao = _updateDAOEarnings(dao);
        _dao = dao;

        _updateNetworkFeeIndex();

        emit NetworkFeeUpdate(_networkFee.expand(), fee);

        _networkFee = fee.shrink();
    }

    function withdrawNetworkEarnings(
        uint256 amount
    ) external override onlyOwner {
        DAO memory dao = _dao;

        uint64 shrunkAmount = amount.shrink();

        if(shrunkAmount > _networkBalance(dao)) {
            revert InsufficientBalance();
        }

        dao.withdrawn += shrunkAmount;
        _dao = dao;

        _token.transfer(msg.sender, amount);

        emit NetworkEarningsWithdrawn(amount, msg.sender);
    }

    function updateOperatorFeeIncreaseLimit(
        uint64 newOperatorMaxFeeIncrease
    ) external override onlyOwner {
        _operatorMaxFeeIncrease = newOperatorMaxFeeIncrease;
        emit OperatorFeeIncreaseLimitUpdate(_operatorMaxFeeIncrease);
    }

    function updateDeclareOperatorFeePeriod(
        uint64 newDeclareOperatorFeePeriod
    ) external override onlyOwner {
        _declareOperatorFeePeriod = newDeclareOperatorFeePeriod;
        emit DeclareOperatorFeePeriodUpdate(newDeclareOperatorFeePeriod);
    }

    function updateExecuteOperatorFeePeriod(
        uint64 newExecuteOperatorFeePeriod
    ) external override onlyOwner {
        _executeOperatorFeePeriod = newExecuteOperatorFeePeriod;
        emit ExecuteOperatorFeePeriodUpdate(newExecuteOperatorFeePeriod);
    }

    function updateLiquidationThresholdPeriod(uint64 blocks) external onlyOwner override {
        if(blocks < MINIMAL_LIQUIDATION_THRESHOLD) {
            revert NewBlockPeriodIsBelowMinimum();
        }

        _minimumBlocksBeforeLiquidation = blocks;
        emit LiquidationThresholdPeriodUpdate(blocks);
    }

    function updateValidatorsPerOperatorLimit(uint64 limit) external onlyOwner override {
        _validatorsPerOperatorLimit = limit;
        emit ValidatorsPerOperatorLimitUpdate(limit);
    }

    /************************************/
    /* Operator External View Functions */
    /************************************/

    function getOperatorFee(uint64 operatorId) external view override returns (uint256) {
        if (_operators[operatorId].snapshot.block == 0) revert OperatorDoesNotExist();

        return _operators[operatorId].fee.expand();
    }

    function getOperatorDeclaredFee(
        uint64 operatorId
    ) external view override returns (uint256, uint256, uint256) {
        OperatorFeeChangeRequest
            memory feeChangeRequest = _operatorFeeChangeRequests[operatorId];

        if(feeChangeRequest.fee == 0) {
            revert NoFeeDelcared();
        }

        return (
            feeChangeRequest.fee.expand(),
            feeChangeRequest.approvalBeginTime,
            feeChangeRequest.approvalEndTime
        );
    }

    function getOperatorById(uint64 operatorId) external view override returns (address owner, uint256 fee, uint32 validatorCount) {
        if (_operators[operatorId].owner == address(0)) revert OperatorDoesNotExist();

        return (
            _operators[operatorId].owner,
            _operators[operatorId].fee.expand(),
            _operators[operatorId].validatorCount
        );
    }

    /***********************************/
    /* Cluster External View Functions */
    /***********************************/

    function isLiquidatable(
        address owner,
        uint64[] calldata operatorIds,
        Cluster memory cluster
    ) external view override returns (bool) {
        uint64 clusterIndex;
        uint64 burnRate;
        uint operatorsLength = operatorIds.length;
        for (uint i; i < operatorsLength; ) {
            Operator memory operator = _operators[operatorIds[i]];
            clusterIndex += operator.snapshot.index + (uint64(block.number) - operator.snapshot.block) * operator.fee;
            burnRate += operator.fee;
            unchecked {
                ++i;
            }
        }

        _validateHashedCluster(owner, operatorIds, cluster);

        return _liquidatable(_clusterBalance(cluster, clusterIndex), cluster.validatorCount, burnRate);
    }

    function isLiquidated(
        address owner,
        uint64[] calldata operatorIds,
        Cluster memory cluster
    ) external view override returns (bool) {
        _validateHashedCluster(owner, operatorIds, cluster);

        return cluster.disabled;
    }

    function getClusterBurnRate(uint64[] calldata operatorIds) external view override returns (uint256) {
        uint64 burnRate;
        uint operatorsLength = operatorIds.length;
        for (uint i; i < operatorsLength; ) {
            Operator memory operator = _operators[operatorIds[i]];
            if (operator.owner != address(0)) {
                burnRate += operator.fee;
            }
            unchecked {
                ++i;
            }
        }
        return burnRate.expand();
    }

    /***********************************/
    /* Balance External View Functions */
    /***********************************/

    function getOperatorEarnings(uint64 id) external view override returns (uint64 currentBlock, uint64 index, uint256 balance) {
        Snapshot memory s = _getSnapshot(_operators[id], uint64(block.number));
        return (s.block, s.index, s.balance.expand());
    }

    function getBalance(
        address owner,
        uint64[] calldata operatorIds,
        Cluster memory cluster
    ) external view override returns (uint256) {
        _validateClusterIsNotLiquidated(cluster);

        uint64 clusterIndex;
        {
            uint operatorsLength = operatorIds.length;
            for (uint i; i < operatorsLength; ) {
                Operator memory operator = _operators[operatorIds[i]];
                clusterIndex += operator.snapshot.index + (uint64(block.number) - operator.snapshot.block) * operator.fee;
                unchecked { ++i; }
            }
        }

        _validateHashedCluster(owner, operatorIds, cluster);

        return _clusterBalance(cluster, clusterIndex).expand();
    }

    /*******************************/
    /* DAO External View Functions */
    /*******************************/

    function getNetworkFee() external view override returns (uint256) {
        return _networkFee.expand();
    }

    function getNetworkEarnings() external view override returns (uint256) {
        DAO memory dao = _dao;
        return _networkBalance(dao).expand();
    }

    function getOperatorFeeIncreaseLimit()
        external
        view
        override
        returns (uint64)
    {
        return _operatorMaxFeeIncrease;
    }

    function getExecuteOperatorFeePeriod()
        external
        view
        override
        returns (uint64)
    {
        return _executeOperatorFeePeriod;
    }

    function getDeclaredOperatorFeePeriod()
        external
        view
        override
        returns (uint64)
    {
        return _declareOperatorFeePeriod;
    }

    function getLiquidationThresholdPeriod()
        external
        view
        override
        returns (uint64)
    {
        return _minimumBlocksBeforeLiquidation;
    }

    function getValidatorsPerOperatorLimit()
        external
        view
        override
        returns (uint64)
    {
        return _validatorsPerOperatorLimit;
    }

    /**********************/
    /* Internal Functions */
    /**********************/

    // solhint-disable-next-line func-name-mixedcase
    function __SSVNetwork_init(
        IERC20 token_,
        uint64 operatorMaxFeeIncrease_,
        uint64 declareOperatorFeePeriod_,
        uint64 executeOperatorFeePeriod_,
        uint64 minimumBlocksBeforeLiquidation_,
        uint64 validatorsPerOperatorLimit_
    ) internal initializer {
        __Ownable_init_unchained();
        __SSVNetwork_init_unchained(
            token_,
            operatorMaxFeeIncrease_,
            declareOperatorFeePeriod_,
            executeOperatorFeePeriod_,
            minimumBlocksBeforeLiquidation_,
            validatorsPerOperatorLimit_
        );
    }

    // solhint-disable-next-line func-name-mixedcase
    function __SSVNetwork_init_unchained(
        IERC20 token_,
        uint64 operatorMaxFeeIncrease_,
        uint64 declareOperatorFeePeriod_,
        uint64 executeOperatorFeePeriod_,
        uint64 minimumBlocksBeforeLiquidation_,
        uint64 validatorsPerOperatorLimit_
    ) internal onlyInitializing {
        _token = token_;
        _operatorMaxFeeIncrease = operatorMaxFeeIncrease_;
        _declareOperatorFeePeriod = declareOperatorFeePeriod_;
        _executeOperatorFeePeriod = executeOperatorFeePeriod_;
        _minimumBlocksBeforeLiquidation = minimumBlocksBeforeLiquidation_;
        _validatorsPerOperatorLimit = validatorsPerOperatorLimit_;
    }

    /********************************/
    /* Validation Private Functions */
    /********************************/

    function _onlyOperatorOwnerOrContractOwner(uint64 operatorId) private view {
        Operator memory operator = _operators[operatorId];

        if(operator.snapshot.block == 0) {
            revert OperatorDoesNotExist();
        }

        if (msg.sender != operator.owner && msg.sender != owner()) {
            revert CallerNotOwner();
        }
    }

    function _validatePublicKey(bytes calldata publicKey) private pure {
        if (publicKey.length != 48) {
            revert InvalidPublicKeyLength();
        }
    }

    function _validateOperatorIds(uint operatorsLength) private pure {
        if (operatorsLength < 4 || operatorsLength > 13 || operatorsLength % 3 != 1) {
            revert InvalidOperatorIdsLengthuctureInvalid();
        }
    }

    function _validateClusterIsNotLiquidated(Cluster memory cluster) private pure {
        if (cluster.disabled) {
            revert ClusterIsLiquidated();
        }
    }

    /******************************/
    /* Operator Private Functions */
    /******************************/

    function _setFee(
        Operator memory operator,
        uint64 fee
    ) private view returns (Operator memory) {
        operator.snapshot = _getSnapshot(operator, uint64(block.number));
        operator.fee = fee;

        return operator;
    }

    function _updateOperatorFeeUnsafe(uint64 operatorId, uint64 fee) private {
        Operator memory operator = _operators[operatorId];

        _operators[operatorId] = _setFee(operator, fee);

        emit OperatorFeeExecution(
            msg.sender,
            operatorId,
            block.number,
            fee.expand()
        );
    }

    function _getSnapshot(
        Operator memory operator,
        uint64 currentBlock
    ) private pure returns (Snapshot memory) {
        uint64 blockDiffFee = (currentBlock - operator.snapshot.block) *
            operator.fee;

        operator.snapshot.index += blockDiffFee;
        operator.snapshot.balance += blockDiffFee * operator.validatorCount;
        operator.snapshot.block = currentBlock;

        return operator.snapshot;
    }

    function _transferOperatorBalanceUnsafe(
        uint64 operatorId,
        uint256 amount
    ) private {
        _token.transfer(msg.sender, amount);
        emit OperatorWithdrawn(amount, operatorId, msg.sender);
    }

    /*****************************/
    /* Cluster Private Functions */
    /*****************************/

    function _validateHashedCluster(address owner, uint64[] memory operatorIds, Cluster memory cluster) private view returns (bytes32) {
        bytes32 hashedCluster = keccak256(abi.encodePacked(owner, operatorIds));
        {
            bytes32 hashedClusterData = keccak256(abi.encodePacked(cluster.validatorCount, cluster.networkFee, cluster.networkFeeIndex, cluster.index, cluster.balance, cluster.disabled ));
            if (_clusters[hashedCluster] == bytes32(0)) {
                revert ClusterDoesNotExists();
            } else if (_clusters[hashedCluster] != hashedClusterData) {
                revert IncorrectClusterState();
            }
        }

        return hashedCluster;
    }

    function _updateClusterData(Cluster memory cluster, uint64 clusterIndex, int8 changedTo) private view returns (Cluster memory) {
        if (!cluster.disabled) {
            cluster.balance = _clusterBalance(cluster, clusterIndex);
            cluster.index = clusterIndex;

            cluster.networkFee = _clusterNetworkFee(cluster.networkFee, cluster.networkFeeIndex, cluster.validatorCount);
            cluster.networkFeeIndex = _currentNetworkFeeIndex();
        }

        if (changedTo == 1) {
            ++cluster.validatorCount;
        } else if (changedTo == -1) {
            --cluster.validatorCount;
        }

        return cluster;
    }

    function _liquidatable(
        uint64 balance,
        uint64 validatorCount,
        uint64 burnRate
    ) private view returns (bool) {
        return
            balance <
            _minimumBlocksBeforeLiquidation *
                (burnRate + _networkFee) *
                validatorCount;
    }

    /*****************************/
    /* Balance Private Functions */
    /*****************************/

    function _deposit(
        address owner,
        uint64[] memory operatorIds,
        uint64 amount
    ) private {
        _token.transferFrom(msg.sender, address(this), amount.expand());
    }

    function _updateNetworkFeeIndex() private {
        _networkFeeIndex = _currentNetworkFeeIndex();
        _networkFeeIndexBlockNumber = uint64(block.number);
    }

    function _updateDAOEarnings(
        DAO memory dao
    ) private view returns (DAO memory) {
        dao.earnings.balance = _networkTotalEarnings(dao);
        dao.earnings.block = uint64(block.number);

        return dao;
    }

    function _currentNetworkFeeIndex() private view returns (uint64) {
        return
            _networkFeeIndex +
            uint64(block.number - _networkFeeIndexBlockNumber) *
            _networkFee;
    }

    function _networkTotalEarnings(
        DAO memory dao
    ) private view returns (uint64) {
        return
            dao.earnings.balance +
            (uint64(block.number) - dao.earnings.block) *
            _networkFee *
            dao.validatorCount;
    }

    function _networkBalance(DAO memory dao) private view returns (uint64) {
        return _networkTotalEarnings(dao) - dao.withdrawn;
    }

    function _clusterBalance(Cluster memory cluster, uint64 newIndex) private view returns (uint64) {
        uint64 usage = (newIndex - cluster.index) * cluster.validatorCount + _clusterNetworkFee(cluster.networkFee, cluster.networkFeeIndex, cluster.validatorCount);

        if (usage > cluster.balance) {
            revert InsufficientFunds();
        }

        return cluster.balance - usage;
    }

    function _clusterNetworkFee(uint64 networkFee, uint64 networkFeeIndex, uint32 validatorCount) private view returns (uint64) {
        return networkFee + uint64(_currentNetworkFeeIndex() - networkFeeIndex) * validatorCount;
    }
}

// File: contracts/SSVNetwork.sol
// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.2;

uint256 constant DEDUCTED_DIGITS = 10000000;

library Types64 {
    function expand(uint64 value) internal pure returns (uint256) {
        return value * DEDUCTED_DIGITS;
    }
}

library Types256 {
    function shrink(uint256 value) internal pure returns (uint64) {
        return uint64(shrinkable(value) / DEDUCTED_DIGITS);
    }

    function shrinkable(uint256 value) internal pure returns (uint256) {
        require(
            value % DEDUCTED_DIGITS == 0,
            "Max precision exceeded"
        );
        return value;
    }
}