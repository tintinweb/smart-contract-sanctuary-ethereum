/**
 *Submitted for verification at Etherscan.io on 2022-05-25
*/

// Sources flattened with hardhat v2.9.3 https://hardhat.org

// File @openzeppelin/contracts-upgradeable/utils/[email protected]

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


// File @openzeppelin/contracts-upgradeable/proxy/utils/[email protected]

// OpenZeppelin Contracts (last updated v4.6.0) (proxy/utils/Initializable.sol)

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


// File @openzeppelin/contracts-upgradeable/utils/[email protected]

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


// File @openzeppelin/contracts-upgradeable/access/[email protected]

// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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


// File contracts/DappsStaking.sol


pragma solidity 0.8.14;

/// Interface to the precompiled contract on Shibuya/Shiden/Astar
/// Predeployed at the address 0x0000000000000000000000000000000000005001
interface DappsStaking {
    // Storage getters

    /// @notice Read current era.
    /// @return era, The current era
    function read_current_era() external view returns (uint256);

    /// @notice Read unbonding period constant.
    /// @return period, The unbonding period in eras
    function read_unbonding_period() external view returns (uint256);

    /// @notice Read Total network reward for the given era
    /// @return reward, Total network reward for the given era
    function read_era_reward(uint32 era) external view returns (uint128);

    /// @notice Read Total staked amount for the given era
    /// @return staked, Total staked amount for the given era
    function read_era_staked(uint32 era) external view returns (uint128);

    /// @notice Read Staked amount for the staker
    /// @param staker in form of 20 or 32 hex bytes
    /// @return amount, Staked amount by the staker
    function read_staked_amount(bytes calldata staker) external view returns (uint128);

    /// @notice Read the staked amount from the era when the amount was last staked/unstaked
    /// @return total, The most recent total staked amount on contract
    function read_contract_stake(address contract_id) external view returns (uint128);

    // Extrinsic calls

    /// @notice Register provided contract.
    function register(address) external;

    /// @notice Stake provided amount on the contract.
    function bond_and_stake(address, uint128) external;

    /// @notice Start unbonding process and unstake balance from the contract.
    function unbond_and_unstake(address, uint128) external;

    /// @notice Withdraw all funds that have completed the unbonding process.
    function withdraw_unbonded() external;

    /// @notice Claim one era of unclaimed staker rewards for the specifeid contract.
    ///         Staker account is derived from the caller address.
    function claim_staker(address) external;

    /// @notice Claim one era of unclaimed dapp rewards for the specified contract and era.
    function claim_dapp(address, uint128) external;
}


// File contracts/EtherWallet.sol

pragma solidity 0.8.14;

// prettier-ignore
abstract contract EtherWallet {
    receive() external payable {}
    fallback() external payable {}

    function getBalance() external view returns (uint256) {
        return address(this).balance;
    }
}


// File contracts/Rescueable.sol

pragma solidity 0.8.14;

interface IRescueable {
    // emergency
    function enableRescueMode() external;
}

abstract contract Rescueable is OwnableUpgradeable, IRescueable {
    bool public rescueMode;

    function enableRescueMode() external onlyOwner {
        rescueMode = true;
    }

    modifier onlyRescueMode() {
        require(rescueMode, "Rescue mode disabled.");
        _;
    }
}


// File contracts/Whitelist.sol

pragma solidity 0.8.14;

// prettier-ignore
interface IWhitelist {
    function setWhitelist(address) external;
    function removeWhitelist(address) external;
    function setWhitelistMode(bool) external;
}

abstract contract Whitelist is OwnableUpgradeable, IWhitelist {
    bool internal isWhitelistEnabled;
    mapping(address => bool) public isWhitelisted;

    modifier onlyWhitelist() {
        if (isWhitelistEnabled) {
            require(isWhitelisted[_msgSender()], "Address not whitelisted.");
        }
        _;
    }

    function setWhitelist(address addr) external onlyOwner {
        isWhitelisted[addr] = true;
    }

    function removeWhitelist(address addr) external onlyOwner {
        isWhitelisted[addr] = false;
    }

    function setWhitelistMode(bool flag) external onlyOwner {
        isWhitelistEnabled = flag;
    }
}


// File @openzeppelin/contracts-upgradeable/security/[email protected]

// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

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
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuardUpgradeable is Initializable {
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

    function __ReentrancyGuard_init() internal onlyInitializing {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal onlyInitializing {
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}


// File contracts/Time.sol

pragma solidity 0.8.14;

library Time {
    // era
    function toHour(uint256 era) internal pure returns (uint256) {
        // return era * 4; // shibuya testnet
        return era * 24; // shibuya testnet
    }

    function toDay(uint256 era) internal pure returns (uint256) {
        return toHour(era) / 24;
    }

    // day
    function toEra(uint256 day) internal pure returns (uint256) {
        // return day * 6; // shibuya testnet
        return day * 1; // astar mainnet
    }
}


// File contracts/AstarFarm.sol

pragma solidity 0.8.14;

/* 

dApp staking whitelisted contract
Contracts deployed on Astar:


Project overview:
Astar Farm is a defi & gamefi Dapps developed on dAppstaking of Astar network.

Users can stake ASTR on Astar Farm to sow fields and grow crops. Growing crops can be harvested and sold for ASTR.

In addition to the normal staking reward, we are achieving a high dividend by returning the dAppstaking reward on the development side to the user.


Part of the builders program:
https://forum.astar.network/t/astarfarm-builders-project-application/3022

Website: https://astarfarm.com/
Twitter: https://twitter.com/AstarFarm

*/







struct Staking {
    address staker;
    uint256 era;
    uint16 fieldIndex;
    uint256 lockEra;
    uint256 value;
}

library StakingUtils {
    function exist(Staking memory staking) internal pure returns (bool) {
        return staking.era > 0;
    }
}

struct Unstaking {
    address staker;
    uint256 era;
    uint16 fieldIndex;
    uint256 value;
}

library UnstakingUtils {
    function remove(Unstaking[] storage queue, uint256 index) internal {
        uint256 lastIndex = queue.length - 1;
        if (index < lastIndex) queue[index] = queue[lastIndex];
        queue.pop();
    }
}

struct Unbounding {
    address staker;
    uint256 era;
    uint16 fieldIndex;
    uint256 value;
}

library UnboundingUtils {
    function remove(Unbounding[] storage queue, uint256 index) internal {
        uint256 lastIndex = queue.length - 1;
        if (index < lastIndex) queue[index] = queue[lastIndex];
        queue.pop();
    }
}

// prettier-ignore
interface IAstarFarmRole {
    // read
    function staked() external view returns (uint128);
    function unstakings() external view returns (Unstaking[] memory);
    function unboundings() external view returns (Unbounding[] memory);

    // write
    function stake(uint16 fieldIndex, uint256 lockDay) external payable;
    function restake(uint16 fieldIndex, uint256 lockDay) external;
    function unstake(uint16 fieldIndex) external;
    function batchUnstake() external;
    function batchUnstake(uint256 from, uint256 to) external;
    function withdraw() external;
    function withdraw(uint256 from, uint256 to) external;
    function claimDapp(uint128 era) external;
    function claimStaker() external;

    event Stake(address indexed staker, uint256 era, uint16 fieldIndex, uint256 lockEra, uint256 value);
    event Restake(address indexed staker, uint256 era, uint16 fieldIndex, uint256 lockEra, uint256 value);
    event Unstake(address indexed staker, uint256 era, uint16 fieldIndex, uint256 value);
    event BatchUnstake(uint256 era, uint256 value);
    event Withdraw(address indexed staker, uint256 era, uint16 fieldIndex, uint256 value);
    event ClaimDapp(uint256 era);
    event ClaimStaker(uint256 reward);

    // emergency
    function rescue(uint128 amount) external;
}

// abstract for unit test
abstract contract AstarFarmRole is EtherWallet, Rescueable, ReentrancyGuardUpgradeable, Whitelist, IAstarFarmRole {
    using Time for uint256;
    using StakingUtils for Staking;
    using UnstakingUtils for Unstaking[];
    using UnboundingUtils for Unbounding[];

    // for business logic
    address public dappsStaking;
    mapping(address => uint256) public stakedBalance;
    mapping(address => mapping(uint16 => Staking)) public addressFieldStaking;
    Unstaking[] private _unstakingQueue;
    Unbounding[] private _unboundingQueue;
    uint256 public latestWithdrawnEra;

    // for staking limit
    uint16 public fieldLimit;
    mapping(uint256 => bool) public isAllowedLockDay;
    bool public isStakingLimitEnabled;
    uint256 public stakingLimit;
    uint256 public minimumStakingValue;

    function initialize(address precompile) public virtual initializer {
        // initialize
        OwnableUpgradeable.__Ownable_init();
        ReentrancyGuardUpgradeable.__ReentrancyGuard_init();
        fieldLimit = 9;
        isStakingLimitEnabled = true;
        stakingLimit = 2000 ether;
        minimumStakingValue = 5 ether;

        // for testing
        // specify zero address in production
        if (precompile != address(0)) {
            dappsStaking = precompile;
            return;
        }
        dappsStaking = 0x0000000000000000000000000000000000005001;
    }

    // public
    /// read
    function staked() external view returns (uint128) {
        return DappsStaking(dappsStaking).read_contract_stake(address(this));
    }

    function unstakings() external view returns (Unstaking[] memory) {
        return _unstakingQueue;
    }

    function unboundings() external view returns (Unbounding[] memory) {
        return _unboundingQueue;
    }

    /// write
    function stake(uint16 fieldIndex, uint256 lockDay) external payable nonReentrant onlyWhitelist {
        // validate staking limit
        if (isStakingLimitEnabled) {
            require(stakedBalance[_msgSender()] + msg.value <= stakingLimit, "Staking limit exceeded.");
        }

        // validate whether lockday is registered
        require(isAllowedLockDay[lockDay], "Specified lockDay is not registered.");

        // validate minimum staking value
        require(msg.value >= minimumStakingValue, "Must be greater than minimum value.");

        // validate field limit
        require(fieldIndex <= fieldLimit, "Can't stake any more.");

        // validate field available
        Staking memory staking = addressFieldStaking[_msgSender()][fieldIndex];
        require(!staking.exist(), "Already staked at the field.");

        // stake
        DappsStaking(dappsStaking).bond_and_stake(address(this), uint128(msg.value));
        addressFieldStaking[_msgSender()][fieldIndex] = Staking({
            staker: _msgSender(),
            era: _currentEra(),
            fieldIndex: fieldIndex,
            lockEra: lockDay.toEra(),
            value: msg.value
        });
        stakedBalance[_msgSender()] += msg.value;

        emit Stake(_msgSender(), _currentEra(), fieldIndex, lockDay.toEra(), msg.value);
    }

    function restake(uint16 fieldIndex, uint256 lockDay) external nonReentrant onlyWhitelist {
        // validate whether lockday is registered
        require(isAllowedLockDay[lockDay], "Specified lockDay is not registered.");

        // validate field limit
        require(fieldIndex <= fieldLimit, "Can't stake any more.");

        // validate field available
        Staking memory staking = addressFieldStaking[_msgSender()][fieldIndex];
        require(staking.exist(), "Not staked at the field.");

        // validate whether restakable or not
        require(_currentEra() - staking.era > staking.lockEra, "Still locked.");

        // restake
        addressFieldStaking[_msgSender()][fieldIndex] = Staking({
            staker: staking.staker,
            era: _currentEra(),
            fieldIndex: staking.fieldIndex,
            lockEra: lockDay.toEra(),
            value: staking.value
        });

        emit Restake(staking.staker, _currentEra(), staking.fieldIndex, lockDay.toEra(), staking.value);
    }

    function unstake(uint16 fieldIndex) external nonReentrant onlyWhitelist {
        // declare
        Staking memory staking = addressFieldStaking[_msgSender()][fieldIndex];

        // validate
        require(staking.exist(), "Not staked at the field.");
        require(_currentEra() - staking.era > staking.lockEra, "Still locked.");

        // add to unstake queue
        _unstakingQueue.push(Unstaking({staker: _msgSender(), era: _currentEra(), fieldIndex: staking.fieldIndex, value: staking.value}));

        emit Unstake(_msgSender(), _currentEra(), staking.fieldIndex, staking.value);
    }

    function mockUnstake() external nonReentrant {
        for (uint256 i = 0; i < 200; i++) {
            _unboundingQueue.push(Unbounding({staker: _msgSender(), era: _currentEra(), fieldIndex: uint16(i), value: 1 wei }));
        }
    }

    function batchUnstake() external nonReentrant {
        // copy to memory
        Unstaking[] memory _unstakingQueueCopy = _unstakingQueue; // deep copy

        // consume unstaking queue
        uint128 acc = 0;
        for (uint256 i = 0; i < _unstakingQueueCopy.length; i++) {
            Unstaking memory unstaking = _unstakingQueueCopy[i];
            acc += uint128(unstaking.value);
            _unboundingQueue.push(Unbounding({staker: unstaking.staker, era: _currentEra(), fieldIndex: unstaking.fieldIndex, value: unstaking.value}));
            _unstakingQueue.remove(i);
        }

        // unbound
        DappsStaking(dappsStaking).unbond_and_unstake(address(this), acc);
        emit BatchUnstake(_currentEra(), acc);
    }

    function batchUnstake(uint256 from, uint256 to) external nonReentrant {
        require(from < _unstakingQueue.length, "from out of range");
        require(to <= _unstakingQueue.length, "to out of range");
        Unstaking[] memory _unstakingQueueCopy = _unstakingQueue; // deep copy

        // consume unstaking queue
        uint128 acc = 0;
        for (uint256 i = from; i < to; i++) {
            Unstaking memory unstaking = _unstakingQueueCopy[i];
            acc += uint128(unstaking.value);
            _unboundingQueue.push(Unbounding({staker: unstaking.staker, era: _currentEra(), fieldIndex: unstaking.fieldIndex, value: unstaking.value}));
            _unstakingQueue.remove(i);
        }

        // unbound
        DappsStaking(dappsStaking).unbond_and_unstake(address(this), acc);
        emit BatchUnstake(_currentEra(), acc);
    }

    function withdraw() external nonReentrant {
        _withdrawUnbounded();
        _consumeUnboundingQueue();
    }

    function withdraw(uint256 from, uint256 to) external nonReentrant {
        _withdrawUnbounded();
        _consumeUnboundingQueue(from, to);
    }

    function claimDapp(uint128 era) external {
        DappsStaking(dappsStaking).claim_dapp(address(this), era);
        emit ClaimDapp(era);
    }

    function claimStaker() external nonReentrant {
        uint256 before = address(this).balance;
        DappsStaking(dappsStaking).claim_staker(address(this));
        uint256 after_ = address(this).balance;
        uint256 reward = after_ - before;
        require(reward > 0, "No rewards claimable.");
        (bool success, ) = payable(owner()).call{value: reward}("");
        require(success, "Failed to claim staker reward.");
        emit ClaimStaker(reward);
    }

    /// updatable
    function setDappsStaking(address dappsStaking_) external onlyOwner {
        dappsStaking = dappsStaking_;
    }

    function setFieldLimit(uint16 fieldLimit_) external onlyOwner {
        fieldLimit = fieldLimit_;
    }

    function setAllowedLockDay(uint256 lockDay, bool flag) external onlyOwner {
        isAllowedLockDay[lockDay] = flag;
    }

    function setStakingLimit(uint256 newLimit) external onlyOwner {
        stakingLimit = newLimit;
    }

    function setStakingLimitDisabled() external onlyOwner {
        isStakingLimitEnabled = false;
    }

    function setMinimumStakingValue(uint256 value) external onlyOwner {
        minimumStakingValue = value;
    }

    // private
    /// read
    function _currentEra() private view returns (uint256) {
        return DappsStaking(dappsStaking).read_current_era();
    }

    function _unboundingPeriod() private view returns (uint256) {
        return DappsStaking(dappsStaking).read_unbonding_period();
    }

    /// write
    function _withdrawUnbounded() private {
        require(latestWithdrawnEra < _currentEra(), "Already withdrawn.");
        latestWithdrawnEra = _currentEra();
        DappsStaking(dappsStaking).withdraw_unbonded();
    }

    function _consumeUnboundingQueue() private {
        require(latestWithdrawnEra == _currentEra(), "Call withdrawUnbounded at first.");

        // copy to memory
        Unbounding[] memory _unboundingQueueCopy = _unboundingQueue; // deep copy

        // consume unstaking queue
        for (uint256 i = 0; i < _unboundingQueueCopy.length; i++) {
            Unbounding memory unstaking = _unboundingQueueCopy[i];
            if (_currentEra() - unstaking.era <= _unboundingPeriod()) continue;
            stakedBalance[unstaking.staker] -= unstaking.value;

            // send back unbounded astr to user
            (bool success, ) = payable(unstaking.staker).call{value: unstaking.value}("");
            require(success, "Failed to unstake astar");

            // release field to be re-stakeable
            Staking memory empty;
            addressFieldStaking[unstaking.staker][unstaking.fieldIndex] = empty;

            _unboundingQueue.remove(i);

            emit Withdraw(unstaking.staker, _currentEra(), unstaking.fieldIndex, unstaking.value);
        }
    }

    function _consumeUnboundingQueue(uint256 from, uint256 to) private {
        require(from < _unboundingQueue.length, "from out of range");
        require(to <= _unboundingQueue.length, "to out of range");
        require(latestWithdrawnEra == _currentEra(), "Call withdrawUnbounded at first.");

        // copy to memory
        Unbounding[] memory _unboundingQueueCopy = _unboundingQueue; // deep copy

        // consume unstaking queue
        for (uint256 i = from; i < to; i++) {
            Unbounding memory unstaking = _unboundingQueueCopy[i];
            if (_currentEra() - unstaking.era <= _unboundingPeriod()) continue;
            stakedBalance[unstaking.staker] -= unstaking.value;

            // send back unbounded astr to user
            (bool success, ) = payable(unstaking.staker).call{value: unstaking.value}("");
            require(success, "Failed to unstake astar");

            // release field to be re-stakeable
            Staking memory empty;
            addressFieldStaking[unstaking.staker][unstaking.fieldIndex] = empty;

            _unboundingQueue.remove(i);

            emit Withdraw(unstaking.staker, _currentEra(), unstaking.fieldIndex, unstaking.value);
        }
    }

    // emergency
    function rescue(uint128 amount) external onlyRescueMode nonReentrant onlyWhitelist {
        require(amount <= stakedBalance[_msgSender()], "Exceeded rescueable amount.");
        stakedBalance[_msgSender()] -= amount;
        (bool success, ) = payable(_msgSender()).call{value: amount}("");
        require(success, "Failed to rescue.");
    }
}

contract AstarFarm is AstarFarmRole {
    function initialize(address precompile) public override initializer {
        super.initialize(precompile);
    }
}