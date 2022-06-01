// SPDX-FileCopyrightText: 2021 Tenderize <[email protected]>

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "./Resolver.sol";

import "./interfaces/IGraph.sol";
import "./interfaces/IMatic.sol";
import "./interfaces/IAudius.sol";

contract MainnetResolver is Resolver {
    // Matic contstants
    uint256 constant EXCHANGE_RATE_PRECISION = 100; // For Validator ID < 8
    uint256 constant EXCHANGE_RATE_PRECISION_HIGH = 10**29; // For Validator ID >= 8

    bytes32 constant GRAPH = 0xf33f789e3939d11e1b15e7342d3161b39f98259904e8ebdc1da58ce84a17f509; // "Graph"
    bytes32 constant AUDIUS = 0xbf92ffa8d618cd090d960a5b3cb58c78332d37eedf59819530a17714aa2dc74c; // "Audius"
    bytes32 constant MATIC = 0xe0323cd44c3bff8ae1a6f6bb89d41ecaa34bcb9eab6e20fe02a77f37f7344b83; // "Matic"

    function rebaseChecker(address _tenderizer)
        external 
        override
    returns (bool canExec, bytes memory execPayload){
        Protocol storage protocol = protocols[_tenderizer];

        if(protocol.lastRebase + protocol.rebaseInterval > block.timestamp) {
            return (canExec, execPayload);
        }

        ITenderizer tenderizer = ITenderizer(_tenderizer);
        uint256 currentPrinciple = tenderizer.totalStakedTokens();
        uint256 stake;

        if (keccak256(bytes(protocol.name)) == GRAPH) {
            // Graph
            address node = tenderizer.node();
            IGraph graph = IGraph(protocol.stakingContract);
            IGraph.Delegation memory delegation = graph.getDelegation(node, address(this));
            IGraph.DelegationPool memory delPool = graph.delegationPools(node);

            uint256 delShares = delegation.shares;
            uint256 totalShares = delPool.shares;
            uint256 totalTokens = delPool.tokens;

            stake = (delShares * totalTokens) / totalShares;
        } else if (keccak256(bytes(protocol.name)) == AUDIUS) {
            // Audius
            IAudius audius = IAudius(protocol.stakingContract);
            stake = audius.getTotalDelegatorStake(address(this));
        } else if (keccak256(bytes(protocol.name)) == MATIC) {
            // Matic
            IMatic matic = IMatic(protocol.stakingContract);
            uint256 shares = matic.balanceOf(address(this));
            stake = (shares * _getExchangeRate(matic)) / _getExchangeRatePrecision(matic);
        }

        if (stake > currentPrinciple + protocol.rebaseThreshold){
            canExec = true;
            execPayload = abi.encodeWithSelector(ITenderizer.claimRewards.selector);
        }

        protocol.lastRebase = block.timestamp;
    }

    // Matic internal functions
    function _getExchangeRatePrecision(IMatic _matic) internal view returns (uint256) {
        return _matic.validatorId() < 8 ? EXCHANGE_RATE_PRECISION : EXCHANGE_RATE_PRECISION_HIGH;
    }

    function _getExchangeRate(IMatic _matic) internal view returns (uint256) {
        uint256 rate = _matic.exchangeRate();
        return rate == 0 ? 1 : rate;
    }
}

// SPDX-FileCopyrightText: 2021 Tenderize <[email protected]>

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "./IResolver.sol";
import "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";

import "./interfaces/ITenderizer.sol";

abstract contract Resolver is IResolver, ContextUpgradeable {

    struct Protocol {
        string name;
        IERC20 steak;
        address stakingContract;
        uint256 depositInterval;
        uint256 depositThreshold;
        uint256 lastDeposit;
        uint256 rebaseInterval;
        uint256 rebaseThreshold;
        uint256 lastRebase;
    }

    mapping(address => Protocol) protocols;
    address gov;

    modifier onlyGov() {
        require(msg.sender == gov);
        _;
    }

    function initialize() external initializer {
        __Context_init_unchained();
        gov = msg.sender;
    }

    function depositChecker(address _tenderizer)
        external
        override
    returns (bool canExec, bytes memory execPayload){
        Protocol storage protocol = protocols[_tenderizer];

        if (protocol.lastDeposit + protocol.depositInterval > block.timestamp) {
            return (canExec, execPayload);
        }

        uint256 tenderizerSteakBal = protocol.steak.balanceOf(_tenderizer);

        if (tenderizerSteakBal >= protocol.depositThreshold) {
            canExec = true;
            execPayload = abi.encodeWithSelector(ITenderizer.deposit.selector, tenderizerSteakBal);
        }

        protocol.lastDeposit = block.timestamp;
    }

    function rebaseChecker(address _tenderizer)
        external 
        override
        virtual
    returns (bool canExec, bytes memory execPayload);
    
    // Governance functions
    function register(
        string memory _name,
        address _tenderizer,
        IERC20 _steak,
        address _stakingContract,
        uint256 _depositInterval,
        uint256 _depositThreshold,
        uint256 _rebaseInterval,
        uint256 _rebaseThreshold
    ) onlyGov external override {
        protocols[_tenderizer] = Protocol({
            name: _name,
            steak: _steak,
            stakingContract: _stakingContract,
            depositInterval: _depositInterval,
            depositThreshold: _depositThreshold,
            lastDeposit: block.timestamp - _depositInterval, // initialize checkpoint
            rebaseInterval: _rebaseInterval,
            rebaseThreshold: _rebaseThreshold,
            lastRebase: block.timestamp - _rebaseInterval // initialize checkpoint
        });
    }

    function setGov(address _gov) onlyGov external override {
        gov = _gov;
    }
}

// SPDX-FileCopyrightText: 2021 Tenderize <[email protected]>

// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

interface IGraph {
    // -- Delegation Data --

    /**
     * @dev Delegation pool information. One per indexer.
     */
    struct DelegationPool {
        uint32 cooldownBlocks; // Blocks to wait before updating parameters
        uint32 indexingRewardCut; // in PPM
        uint32 queryFeeCut; // in PPM
        uint256 updatedAtBlock; // Block when the pool was last updated
        uint256 tokens; // Total tokens as pool reserves
        uint256 shares; // Total shares minted in the pool
        // mapping(address => Delegation) delegators; // Mapping of delegator => Delegation
    }

    /**
     * @dev Individual delegation data of a delegator in a pool.
     */
    struct Delegation {
        uint256 shares; // Shares owned by a delegator in the pool
        uint256 tokensLocked; // Tokens locked for undelegation
        uint256 tokensLockedUntil; // Block when locked tokens can be withdrawn
    }

    function delegate(address _indexer, uint256 _tokens) external returns (uint256);

    function undelegate(address _indexer, uint256 _shares) external returns (uint256);

    function withdrawDelegated(address _indexer, address _newIndexer) external returns (uint256);

    function getDelegation(address _indexer, address _delegator) external view returns (Delegation memory);

    function delegationPools(address _indexer) external view returns (DelegationPool memory);

    function getWithdraweableDelegatedTokens(Delegation memory _delegation) external view returns (uint256);

    function thawingPeriod() external view returns (uint256);

    function delegationTaxPercentage() external view returns (uint32);
}

// SPDX-FileCopyrightText: 2021 Tenderize <[email protected]>

// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

// note this contract interface is only for stakeManager use
interface IMatic {
    function exchangeRate() external view returns (uint256);

    function balanceOf(address) external view returns (uint256);

    function validatorId() external view returns (uint256);
}

// SPDX-FileCopyrightText: 2021 Tenderize <[email protected]>

// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

interface IAudius {
    /**
     * @notice Get total delegation from a given address
     * @param _delegator - delegator address
     */
    function getTotalDelegatorStake(address _delegator) external view returns (uint256);

    /**
     * @notice Allow a delegator to delegate stake to a service provider
     * @param _targetSP - address of service provider to delegate to
     * @param _amount - amount in wei to delegate
     * @return Updated total amount delegated to the service provider by delegator
     */
    function delegateStake(address _targetSP, uint256 _amount) external returns (uint256);

    /**
     * @notice Submit request for undelegation
     * @param _target - address of service provider to undelegate stake from
     * @param _amount - amount in wei to undelegate
     * @return Updated total amount delegated to the service provider by delegator
     */
    function requestUndelegateStake(address _target, uint256 _amount) external returns (uint256);

    /**
     * @notice Cancel undelegation request
     */
    function cancelUndelegateStakeRequest() external;

    /**
     * @notice Finalize undelegation request and withdraw stake
     * @return New total amount currently staked after stake has been undelegated
     */
    function undelegateStake() external returns (uint256);

    /**
     * @notice Claim and distribute rewards to delegators and service provider as necessary
     * @param _serviceProvider - Provider for which rewards are being distributed
     * @dev Factors in service provider rewards from delegator and transfers deployer cut
     */
    function claimRewards(address _serviceProvider) external;

    /// @notice Get the Staking address
    function getStakingAddress() external view returns (address);
}

// SPDX-FileCopyrightText: 2021 Tenderize <[email protected]>

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IResolver {
    function depositChecker(address _tenderizer)
        external
    returns (bool canExec, bytes memory execPayload);

     function rebaseChecker (address _tenderizer) 
        external
    returns (bool canExec, bytes memory execPayload);

    function register(
        string memory _name,
        address _tenderizer,
        IERC20 _steak,
        address _stakingContract,
        uint256 _depositInterval,
        uint256 _depositThreshold,
        uint256 _rebaseInternval,
        uint256 _rebaseThreshold
    ) external;

    function setGov(address _gov) external;
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

// SPDX-FileCopyrightText: 2021 Tenderize <[email protected]>

// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface ITenderizer {
    function deposit(uint256 _amount) external;
    function claimRewards() external;
    function node() external view returns (address);
    function totalStakedTokens() external view returns (uint256 totalStaked);
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