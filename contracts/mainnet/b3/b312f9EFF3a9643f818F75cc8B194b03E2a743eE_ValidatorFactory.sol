// SPDX-FileCopyrightText: 2021 ShardLabs
// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.7;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "./ValidatorProxy.sol";
import "./interfaces/INodeOperatorRegistry.sol";
import "./interfaces/IValidatorProxy.sol";
import "./interfaces/IValidatorFactory.sol";

/// @title ValidatorFactory
/// @author 2021 ShardLabs.
/// @notice The validator Factory is the contract that allows creating new validatorProxies
// and managing them to update the operator and the validator implementation addresses.
contract ValidatorFactory is IValidatorFactory, OwnableUpgradeable {
    /// @notice the list of all the validatorProxies.
    address[] public validators;
    /// @notice the contract version.
    string public version;
    /// @notice the node operator address.
    address public operatorRegistry;
    /// @notice the validator implementation address.
    address public validatorImplementation;

    /// @notice Check if the operator contract is the msg.sender.
    modifier isOperatorRegistry() {
        require(operatorRegistry == msg.sender, "Caller is not the operator contract");
        _;
    }

    /// @notice Initialize the NodeOperator contract.
    function initialize(
        address _validatorImplementation,
        address _nodeOperatorRegistry
    ) external initializer {
        __Ownable_init();

        validatorImplementation = _validatorImplementation;
        setOperator(_nodeOperatorRegistry);
    }

    /// @notice Deploy a new validator contract
    /// @return return the address of the new validator contract deployed
    function create() external override isOperatorRegistry returns (address) {
        require(operatorRegistry != address(0), "Operator contract not set");

        // create a new validator proxy
        address proxy = address(
            new ValidatorProxy(validatorImplementation, operatorRegistry, address(this))
        );

        validators.push(proxy);

        return proxy;
    }

    /// @notice Remove a validator proxy from the list.
    /// @param _validatorProxy validator proxy address.
    function remove(address _validatorProxy) external override isOperatorRegistry {
        require(
            _validatorProxy != address(0),
            "Could not remove a zero address"
        );

        uint256 length = validators.length;
        for (uint256 idx = 0; idx < length; idx++) {
            if (_validatorProxy == validators[idx]) {
                validators[idx] = validators[length - 1];
                break;
            }
        }
        validators.pop();
    }

    /// @notice Allows to set the NodeOperatorRegistry address and update all the validatorProxies
    /// with the new address.
    /// @param _newOperator new operator address.
    function setOperator(address _newOperator) public override onlyOwner {
        operatorRegistry = _newOperator;

        uint256 length = validators.length;
        for (uint256 idx = 0; idx < length; idx++) {
            IValidatorProxy(validators[idx]).setOperator(_newOperator);
        }

        emit SetOperatorContract(_newOperator);
    }

    /// @notice Allows to set the validator implementation address and update all the
    /// validatorProxies with the new address.
    /// @param _validatorImplementation new validator implementation address.
    function setValidatorImplementation(address _validatorImplementation)
        external
        override
        onlyOwner
    {
        validatorImplementation = _validatorImplementation;

        uint256 length = validators.length;
        for (uint256 idx = 0; idx < length; idx++) {
            IValidatorProxy(validators[idx]).setValidatorImplementation(
                _validatorImplementation
            );
        }
        emit SetValidatorImplementation(_validatorImplementation);
    }

    /// @notice set contract version.
    function setVersion(string memory _version) external onlyOwner {
        version = _version;
    }

    /// @notice Get a list of all validatorProxy contracts deployed.
    /// @return return a list of deployed validatorProxy contracts.
    function getValidators() external view returns (address[] memory) {
        return validators;
    }

    event SetOperatorContract(address operator);
    event SetValidatorImplementation(address validatorImplementation);
}

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
        __Context_init_unchained();
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
    uint256[49] private __gap;
}

// SPDX-FileCopyrightText: 2021 ShardLabs
// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.7;

import "@openzeppelin/contracts/proxy/Proxy.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/IValidatorProxy.sol";

/// @title ValidatorProxy
/// @author 2021 ShardLabs.
/// @notice The validator proxy contract is a proxy used as a validator owner in the
/// stakeManager. Each time a new operator is added a new validator proxy is created
/// by the validator factory and assigned to the operator. Later we can use it to
/// stake the validator on the stakeManager and manage it.
contract ValidatorProxy is IValidatorProxy, Proxy {
    /// @notice the validator implementation address.
    address public implementation;
    /// @notice the operator address.
    address public operator;
    /// @notice validator factory address.
    address public validatorFactory;

    constructor(
        address _newImplementation,
        address _operator,
        address _validatorFactory
    ) {
        implementation = _newImplementation;
        operator = _operator;
        validatorFactory = _validatorFactory;
    }

    /// @notice check if the msg.sender is the validator factory.
    modifier isValidatorFactory() {
        require(
            msg.sender == validatorFactory,
            "Caller is not the validator factory"
        );
        _;
    }

    /// @notice Allows the validatorFactory to set the validator implementation.
    /// @param _newValidatorImplementation set a new implementation
    function setValidatorImplementation(address _newValidatorImplementation)
        external
        override
        isValidatorFactory
    {
        implementation = _newValidatorImplementation;
    }

    /// @notice Allows the validatorFactory to set the operator implementation.
    /// @param _newOperator set a new operator.
    function setOperator(address _newOperator)
        external
        override
        isValidatorFactory
    {
        operator = _newOperator;
    }

    /// @notice Allows to get the contract implementation address.
    /// @return Returns the address of the implementation
    function _implementation()
        internal
        view
        virtual
        override
        returns (address)
    {
        return implementation;
    }
}

// SPDX-FileCopyrightText: 2021 ShardLabs
// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.7;

import "../lib/Operator.sol";

/// @title INodeOperatorRegistry
/// @author 2021 ShardLabs
/// @notice Node operator registry interface
interface INodeOperatorRegistry {
    /// @notice Allows to add a new node operator to the system.
    /// @param _name the node operator name.
    /// @param _rewardAddress public address used for ACL and receive rewards.
    /// @param _signerPubkey public key used on heimdall len 64 bytes.
    function addOperator(
        string memory _name,
        address _rewardAddress,
        bytes memory _signerPubkey
    ) external;

    /// @notice Allows to stop a node operator.
    /// @param _operatorId node operator id.
    function stopOperator(uint256 _operatorId) external;

    /// @notice Allows to remove a node operator from the system.
    /// @param _operatorId node operator id.
    function removeOperator(uint256 _operatorId) external;

    /// @notice Allows a staked validator to join the system.
    function joinOperator() external;

    /// @notice Allows to stake an operator on the Polygon stakeManager.
    /// This function calls Polygon transferFrom so the totalAmount(_amount + _heimdallFee)
    /// has to be approved first.
    /// @param _amount amount to stake.
    /// @param _heimdallFee heimdallFee to stake.
    function stake(uint256 _amount, uint256 _heimdallFee) external;

    /// @notice Restake Matics for a validator on polygon stake manager.
    /// @param _amount amount to stake.
    /// @param _restakeRewards restake rewards.
    function restake(uint256 _amount, bool _restakeRewards) external;

    /// @notice Allows the operator's owner to migrate the NFT. This can be done only
    /// if the DAO stopped the operator.
    function migrate() external;

    /// @notice Allows to unstake an operator from the stakeManager. After the withdraw_delay
    /// the operator owner can call claimStake func to withdraw the staked tokens.
    function unstake() external;

    /// @notice Allows to topup heimdall fees on polygon stakeManager.
    /// @param _heimdallFee amount to topup.
    function topUpForFee(uint256 _heimdallFee) external;

    /// @notice Allows to claim staked tokens on the stake Manager after the end of the
    /// withdraw delay
    function unstakeClaim() external;

    /// @notice Allows an owner to withdraw rewards from the stakeManager.
    function withdrawRewards() external;

    /// @notice Allows to update the signer pubkey
    /// @param _signerPubkey update signer public key
    function updateSigner(bytes memory _signerPubkey) external;

    /// @notice Allows to claim the heimdall fees staked by the owner of the operator
    /// @param _accumFeeAmount accumulated fees amount
    /// @param _index index
    /// @param _proof proof
    function claimFee(
        uint256 _accumFeeAmount,
        uint256 _index,
        bytes memory _proof
    ) external;

    /// @notice Allows to unjail a validator and switch from UNSTAKE status to STAKED
    function unjail() external;

    /// @notice Allows an operator's owner to set the operator name.
    function setOperatorName(string memory _name) external;

    /// @notice Allows an operator's owner to set the operator rewardAddress.
    function setOperatorRewardAddress(address _rewardAddress) external;

    /// @notice Allows the DAO to set _defaultMaxDelegateLimit.
    function setDefaultMaxDelegateLimit(uint256 _defaultMaxDelegateLimit)
        external;

    /// @notice Allows the DAO to set _maxDelegateLimit for an operator.
    function setMaxDelegateLimit(uint256 _operatorId, uint256 _maxDelegateLimit)
        external;

    /// @notice Allows the DAO to set _commissionRate.
    function setCommissionRate(uint256 _commissionRate) external;

    /// @notice Allows the DAO to set _commissionRate for an operator.
    /// @param _operatorId id of the operator
    /// @param _newCommissionRate new commission rate
    function updateOperatorCommissionRate(
        uint256 _operatorId,
        uint256 _newCommissionRate
    ) external;

    /// @notice Allows the DAO to set _minAmountStake and _minHeimdallFees.
    function setStakeAmountAndFees(
        uint256 _minAmountStake,
        uint256 _minHeimdallFees
    ) external;

    /// @notice Allows to pause/unpause the node operator contract.
    function togglePause() external;

    /// @notice Allows the DAO to enable/disable restake.
    function setRestake(bool _restake) external;

    /// @notice Allows the DAO to set stMATIC contract.
    function setStMATIC(address _stMATIC) external;

    /// @notice Allows the DAO to set validator factory contract.
    function setValidatorFactory(address _validatorFactory) external;

    /// @notice Allows the DAO to set stake manager contract.
    function setStakeManager(address _stakeManager) external;

    /// @notice Allows to set contract version.
    function setVersion(string memory _version) external;

    /// @notice Get the stMATIC contract addresses
    function getContracts()
        external
        view
        returns (
            address _validatorFactory,
            address _stakeManager,
            address _polygonERC20,
            address _stMATIC
        );

    /// @notice Allows to get stats.
    function getState()
        external
        view
        returns (
            uint256 _totalNodeOperator,
            uint256 _totalInactiveNodeOperator,
            uint256 _totalActiveNodeOperator,
            uint256 _totalStoppedNodeOperator,
            uint256 _totalUnstakedNodeOperator,
            uint256 _totalClaimedNodeOperator,
            uint256 _totalExitNodeOperator,
            uint256 _totalSlashedNodeOperator,
            uint256 _totalEjectedNodeOperator
        );

    /// @notice Allows to get a list of operatorInfo.
    function getOperatorInfos(bool _delegation, bool _allActive)
        external
        view
        returns (Operator.OperatorInfo[] memory);


    /// @notice Allows to get all the operator ids.
    function getOperatorIds() external view returns (uint256[] memory);
}

// SPDX-FileCopyrightText: 2021 ShardLabs
// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.7;

interface IValidatorProxy {
    /// @notice Allows to set a new validator implementation.
    /// @param _newImplementation new address.
    function setValidatorImplementation(address _newImplementation) external;

    /// @notice Allows to set a new operator.
    /// @param _newOperator new address.
    function setOperator(address _newOperator) external;
}

// SPDX-FileCopyrightText: 2021 ShardLabs
// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.7;

import "../Validator.sol";

/// @title IValidatorFactory.
/// @author 2021 ShardLabs
interface IValidatorFactory {
    /// @notice Deploy a new validator proxy contract.
    /// @return return the address of the deployed contract.
    function create() external returns (address);

    /// @notice Remove a validator proxy from the validators.
    function remove(address _validatorProxy) external;

    /// @notice Set the node operator contract address.
    function setOperator(address _operator) external;

    /// @notice Set validator implementation contract address.
    function setValidatorImplementation(address _validatorImplementation)
        external;
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
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/utils/Initializable.sol)

pragma solidity ^0.8.0;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
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
 * contract, which may impact the proxy. To initialize the implementation contract, you can either invoke the
 * initializer manually, or you can include a constructor to automatically mark it as initialized when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() initializer {}
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, because in other contexts the
        // contract may have been reentered.
        require(_initializing ? _isConstructor() : !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} modifier, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    function _isConstructor() private view returns (bool) {
        return !AddressUpgradeable.isContract(address(this));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Address.sol)

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
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
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
// OpenZeppelin Contracts v4.4.1 (proxy/Proxy.sol)

pragma solidity ^0.8.0;

/**
 * @dev This abstract contract provides a fallback function that delegates all calls to another contract using the EVM
 * instruction `delegatecall`. We refer to the second contract as the _implementation_ behind the proxy, and it has to
 * be specified by overriding the virtual {_implementation} function.
 *
 * Additionally, delegation to the implementation can be triggered manually through the {_fallback} function, or to a
 * different contract through the {_delegate} function.
 *
 * The success and return data of the delegated call will be returned back to the caller of the proxy.
 */
abstract contract Proxy {
    /**
     * @dev Delegates the current call to `implementation`.
     *
     * This function does not return to its internall call site, it will return directly to the external caller.
     */
    function _delegate(address implementation) internal virtual {
        assembly {
            // Copy msg.data. We take full control of memory in this inline assembly
            // block because it will not return to Solidity code. We overwrite the
            // Solidity scratch pad at memory position 0.
            calldatacopy(0, 0, calldatasize())

            // Call the implementation.
            // out and outsize are 0 because we don't know the size yet.
            let result := delegatecall(gas(), implementation, 0, calldatasize(), 0, 0)

            // Copy the returned data.
            returndatacopy(0, 0, returndatasize())

            switch result
            // delegatecall returns 0 on error.
            case 0 {
                revert(0, returndatasize())
            }
            default {
                return(0, returndatasize())
            }
        }
    }

    /**
     * @dev This is a virtual function that should be overriden so it returns the address to which the fallback function
     * and {_fallback} should delegate.
     */
    function _implementation() internal view virtual returns (address);

    /**
     * @dev Delegates the current call to the address returned by `_implementation()`.
     *
     * This function does not return to its internall call site, it will return directly to the external caller.
     */
    function _fallback() internal virtual {
        _beforeFallback();
        _delegate(_implementation());
    }

    /**
     * @dev Fallback function that delegates calls to the address returned by `_implementation()`. Will run if no other
     * function in the contract matches the call data.
     */
    fallback() external payable virtual {
        _fallback();
    }

    /**
     * @dev Fallback function that delegates calls to the address returned by `_implementation()`. Will run if call data
     * is empty.
     */
    receive() external payable virtual {
        _fallback();
    }

    /**
     * @dev Hook that is called before falling back to the implementation. Can happen as part of a manual `_fallback`
     * call, or as part of the Solidity `fallback` or `receive` functions.
     *
     * If overriden should call `super._beforeFallback()`.
     */
    function _beforeFallback() internal virtual {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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

// SPDX-License-Identifier: MIT
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
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-FileCopyrightText: 2021 ShardLabs
// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.7;

library Operator {
    struct OperatorInfo {
        uint256 operatorId;
        address validatorShare;
        uint256 maxDelegateLimit;
        address rewardAddress;
    }
}

// SPDX-FileCopyrightText: 2021 ShardLabs
// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.7;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";

import "./interfaces/IStakeManager.sol";
import "./interfaces/IValidator.sol";
import "./interfaces/INodeOperatorRegistry.sol";

/// @title ValidatorImplementation
/// @author 2021 ShardLabs.
/// @notice The validator contract is a simple implementation of the stakeManager API, the
/// ValidatorProxies use this contract to interact with the stakeManager.
/// When a ValidatorProxy calls this implementation the state is copied
/// (owner, implementation, operatorRegistry), then they are used to check if the msg-sender is the
/// node operator contract, and if the validatorProxy implementation match with the current
/// validator contract.
contract Validator is IERC721Receiver, IValidator {
    using SafeERC20 for IERC20;

    address private implementation;
    address private operatorRegistry;
    address private validatorFactory;

    /// @notice Check if the operator contract is the msg.sender.
    modifier isOperatorRegistry() {
        require(
            msg.sender == operatorRegistry,
            "Caller should be the operator contract"
        );
        _;
    }

    /// @notice Allows to stake on the Polygon stakeManager contract by
    /// calling stakeFor function and set the user as the equal to this validator proxy
    /// address.
    /// @param _sender the address of the operator-owner that approved Matics.
    /// @param _amount the amount to stake with.
    /// @param _heimdallFee the heimdall fees.
    /// @param _acceptDelegation accept delegation.
    /// @param _signerPubkey signer public key used on the heimdall node.
    /// @param _commissionRate validator commision rate
    /// @return Returns the validatorId and the validatorShare contract address.
    function stake(
        address _sender,
        uint256 _amount,
        uint256 _heimdallFee,
        bool _acceptDelegation,
        bytes memory _signerPubkey,
        uint256 _commissionRate,
        address _stakeManager,
        address _polygonERC20
    ) external override isOperatorRegistry returns (uint256, address) {
        IStakeManager stakeManager = IStakeManager(_stakeManager);
        IERC20 polygonERC20 = IERC20(_polygonERC20);

        uint256 totalAmount = _amount + _heimdallFee;
        polygonERC20.safeTransferFrom(_sender, address(this), totalAmount);
        polygonERC20.safeApprove(address(stakeManager), totalAmount);
        stakeManager.stakeFor(
            address(this),
            _amount,
            _heimdallFee,
            _acceptDelegation,
            _signerPubkey
        );

        uint256 validatorId = stakeManager.getValidatorId(address(this));
        address validatorShare = stakeManager.getValidatorContract(validatorId);
        if (_commissionRate > 0) {
            stakeManager.updateCommissionRate(validatorId, _commissionRate);
        }

        return (validatorId, validatorShare);
    }

    /// @notice Restake validator rewards or new Matics validator on stake manager.
    /// @param _sender operator's owner that approved tokens to the validator contract.
    /// @param _validatorId validator id.
    /// @param _amount amount to stake.
    /// @param _stakeRewards restake rewards.
    /// @param _stakeManager stake manager address
    /// @param _polygonERC20 address of the MATIC token
    function restake(
        address _sender,
        uint256 _validatorId,
        uint256 _amount,
        bool _stakeRewards,
        address _stakeManager,
        address _polygonERC20
    ) external override isOperatorRegistry {
        if (_amount > 0) {
            IERC20 polygonERC20 = IERC20(_polygonERC20);
            polygonERC20.safeTransferFrom(_sender, address(this), _amount);
            polygonERC20.safeApprove(address(_stakeManager), _amount);
        }
        IStakeManager(_stakeManager).restake(_validatorId, _amount, _stakeRewards);
    }

    /// @notice Unstake a validator from the Polygon stakeManager contract.
    /// @param _validatorId validatorId.
    /// @param _stakeManager address of the stake manager
    function unstake(uint256 _validatorId, address _stakeManager)
        external
        override
        isOperatorRegistry
    {
        // stakeManager
        IStakeManager(_stakeManager).unstake(_validatorId);
    }

    /// @notice Allows a validator to top-up the heimdall fees.
    /// @param _sender address that approved the _heimdallFee amount.
    /// @param _heimdallFee amount.
    /// @param _stakeManager stake manager address
    /// @param _polygonERC20 address of the MATIC token
    function topUpForFee(
        address _sender,
        uint256 _heimdallFee,
        address _stakeManager,
        address _polygonERC20
    ) external override isOperatorRegistry {
        IStakeManager stakeManager = IStakeManager(_stakeManager);
        IERC20 polygonERC20 = IERC20(_polygonERC20);

        polygonERC20.safeTransferFrom(_sender, address(this), _heimdallFee);
        polygonERC20.safeApprove(address(stakeManager), _heimdallFee);
        stakeManager.topUpForFee(address(this), _heimdallFee);
    }

    /// @notice Allows to withdraw rewards from the validator using the _validatorId. Only the
    /// owner can request withdraw. The rewards are transfered to the _rewardAddress.
    /// @param _validatorId validator id.
    /// @param _rewardAddress reward address.
    /// @param _stakeManager stake manager address
    /// @param _polygonERC20 address of the MATIC token
    function withdrawRewards(
        uint256 _validatorId,
        address _rewardAddress,
        address _stakeManager,
        address _polygonERC20
    ) external override isOperatorRegistry returns (uint256) {
        IStakeManager(_stakeManager).withdrawRewards(_validatorId);

        IERC20 polygonERC20 = IERC20(_polygonERC20);
        uint256 balance = polygonERC20.balanceOf(address(this));
        polygonERC20.safeTransfer(_rewardAddress, balance);

        return balance;
    }

    /// @notice Allows to unstake the staked tokens (+rewards) and transfer them
    /// to the owner rewardAddress.
    /// @param _validatorId validator id.
    /// @param _rewardAddress rewardAddress address.
    /// @param _stakeManager stake manager address
    /// @param _polygonERC20 address of the MATIC token
    function unstakeClaim(
        uint256 _validatorId,
        address _rewardAddress,
        address _stakeManager,
        address _polygonERC20
    ) external override isOperatorRegistry returns (uint256) {
        IStakeManager stakeManager = IStakeManager(_stakeManager);
        stakeManager.unstakeClaim(_validatorId);
        // polygonERC20
        // stakeManager
        IERC20 polygonERC20 = IERC20(_polygonERC20);
        uint256 balance = polygonERC20.balanceOf(address(this));
        polygonERC20.safeTransfer(_rewardAddress, balance);

        return balance;
    }

    /// @notice Allows to update signer publickey.
    /// @param _validatorId validator id.
    /// @param _signerPubkey new publickey.
    /// @param _stakeManager stake manager address
    function updateSigner(
        uint256 _validatorId,
        bytes memory _signerPubkey,
        address _stakeManager
    ) external override isOperatorRegistry {
        IStakeManager(_stakeManager).updateSigner(_validatorId, _signerPubkey);
    }

    /// @notice Allows withdraw heimdall fees.
    /// @param _accumFeeAmount accumulated heimdall fees.
    /// @param _index index.
    /// @param _proof proof.
    function claimFee(
        uint256 _accumFeeAmount,
        uint256 _index,
        bytes memory _proof,
        address _rewardAddress,
        address _stakeManager,
        address _polygonERC20
    ) external override isOperatorRegistry {
        IStakeManager stakeManager = IStakeManager(_stakeManager);
        stakeManager.claimFee(_accumFeeAmount, _index, _proof);

        IERC20 polygonERC20 = IERC20(_polygonERC20);
        uint256 balance = polygonERC20.balanceOf(address(this));
        polygonERC20.safeTransfer(_rewardAddress, balance);
    }

    /// @notice Allows to update commission rate of a validator.
    /// @param _validatorId validator id.
    /// @param _newCommissionRate new commission rate.
    /// @param _stakeManager stake manager address
    function updateCommissionRate(
        uint256 _validatorId,
        uint256 _newCommissionRate,
        address _stakeManager
    ) public override isOperatorRegistry {
        IStakeManager(_stakeManager).updateCommissionRate(
            _validatorId,
            _newCommissionRate
        );
    }

    /// @notice Allows to unjail a validator.
    /// @param _validatorId validator id
    function unjail(uint256 _validatorId, address _stakeManager)
        external
        override
        isOperatorRegistry
    {
        IStakeManager(_stakeManager).unjail(_validatorId);
    }

    /// @notice Allows to transfer the validator nft token to the reward address a validator.
    /// @param _validatorId operator id.
    /// @param _stakeManagerNFT stake manager nft contract.
    /// @param _rewardAddress reward address.
    function migrate(
        uint256 _validatorId,
        address _stakeManagerNFT,
        address _rewardAddress
    ) external override isOperatorRegistry {
        IERC721 erc721 = IERC721(_stakeManagerNFT);
        erc721.approve(_rewardAddress, _validatorId);
        erc721.safeTransferFrom(address(this), _rewardAddress, _validatorId);
    }

    /// @notice Allows a validator that was already staked on the polygon stake manager
    /// to join the PoLido protocol.
    /// @param _validatorId validator id
    /// @param _stakeManagerNFT address of the staking NFT
    /// @param _rewardAddress address that will receive the rewards from staking
    /// @param _newCommissionRate commission rate
    /// @param _stakeManager address of the stake manager
    function join(
        uint256 _validatorId,
        address _stakeManagerNFT,
        address _rewardAddress,
        uint256 _newCommissionRate,
        address _stakeManager
    ) external override isOperatorRegistry {
        IERC721 erc721 = IERC721(_stakeManagerNFT);
        erc721.safeTransferFrom(_rewardAddress, address(this), _validatorId);
        updateCommissionRate(_validatorId, _newCommissionRate, _stakeManager);
    }

    /// @notice Allows to get the version of the validator implementation.
    /// @return Returns the version.
    function version() external pure returns (string memory) {
        return "1.0.0";
    }

    /// @notice Implement @openzeppelin/contracts/token/ERC721/IERC721Receiver.sol interface.
    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external pure override returns (bytes4) {
        return
            bytes4(
                keccak256("onERC721Received(address,address,uint256,bytes)")
            );
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-FileCopyrightText: 2021 ShardLabs
// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.7;

/// @title polygon stake manager interface.
/// @author 2021 ShardLabs
/// @notice User to interact with the polygon stake manager.
interface IStakeManager {
    /// @notice Stake a validator on polygon stake manager.
    /// @param user user that own the validator in our case the validator contract.
    /// @param amount amount to stake.
    /// @param heimdallFee heimdall fees.
    /// @param acceptDelegation accept delegation.
    /// @param signerPubkey signer publickey used in heimdall node.
    function stakeFor(
        address user,
        uint256 amount,
        uint256 heimdallFee,
        bool acceptDelegation,
        bytes memory signerPubkey
    ) external;

    /// @notice Restake Matics for a validator on polygon stake manager.
    /// @param validatorId validator id.
    /// @param amount amount to stake.
    /// @param stakeRewards restake rewards.
    function restake(
        uint256 validatorId,
        uint256 amount,
        bool stakeRewards
    ) external;

    /// @notice Request unstake a validator.
    /// @param validatorId validator id.
    function unstake(uint256 validatorId) external;

    /// @notice Increase the heimdall fees.
    /// @param user user that own the validator in our case the validator contract.
    /// @param heimdallFee heimdall fees.
    function topUpForFee(address user, uint256 heimdallFee) external;

    /// @notice Get the validator id using the user address.
    /// @param user user that own the validator in our case the validator contract.
    /// @return return the validator id
    function getValidatorId(address user) external view returns (uint256);

    /// @notice get the validator contract used for delegation.
    /// @param validatorId validator id.
    /// @return return the address of the validator contract.
    function getValidatorContract(uint256 validatorId)
        external
        view
        returns (address);

    /// @notice Withdraw accumulated rewards
    /// @param validatorId validator id.
    function withdrawRewards(uint256 validatorId) external;

    /// @notice Get validator total staked.
    /// @param validatorId validator id.
    function validatorStake(uint256 validatorId)
        external
        view
        returns (uint256);

    /// @notice Allows to unstake the staked tokens on the stakeManager.
    /// @param validatorId validator id.
    function unstakeClaim(uint256 validatorId) external;

    /// @notice Allows to update the signer pubkey
    /// @param _validatorId validator id
    /// @param _signerPubkey update signer public key
    function updateSigner(uint256 _validatorId, bytes memory _signerPubkey)
        external;

    /// @notice Allows to claim the heimdall fees.
    /// @param _accumFeeAmount accumulated fees amount
    /// @param _index index
    /// @param _proof proof
    function claimFee(
        uint256 _accumFeeAmount,
        uint256 _index,
        bytes memory _proof
    ) external;

    /// @notice Allows to update the commision rate of a validator
    /// @param _validatorId operator id
    /// @param _newCommissionRate commission rate
    function updateCommissionRate(
        uint256 _validatorId,
        uint256 _newCommissionRate
    ) external;

    /// @notice Allows to unjail a validator.
    /// @param _validatorId id of the validator that is to be unjailed
    function unjail(uint256 _validatorId) external;

    /// @notice Returns a withdrawal delay.
    function withdrawalDelay() external view returns (uint256);

    /// @notice Transfers amount from delegator
    function delegationDeposit(
        uint256 validatorId,
        uint256 amount,
        address delegator
    ) external returns (bool);

    function epoch() external view returns (uint256);

    enum Status {
        Inactive,
        Active,
        Locked,
        Unstaked
    }

    struct Validator {
        uint256 amount;
        uint256 reward;
        uint256 activationEpoch;
        uint256 deactivationEpoch;
        uint256 jailTime;
        address signer;
        address contractAddress;
        Status status;
        uint256 commissionRate;
        uint256 lastCommissionUpdate;
        uint256 delegatorsReward;
        uint256 delegatedAmount;
        uint256 initialRewardPerStake;
    }

    function validators(uint256 _index)
        external
        view
        returns (Validator memory);

    /// @notice Returns the address of the nft contract
    function NFTContract() external view returns (address);

    /// @notice Returns the validator accumulated rewards on stake manager.
    function validatorReward(uint256 validatorId)
        external
        view
        returns (uint256);
}

// SPDX-FileCopyrightText: 2021 ShardLabs
// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.7;

import "../Validator.sol";

/// @title IValidator.
/// @author 2021 ShardLabs
/// @notice Validator interface.
interface IValidator {
    /// @notice Allows to stake a validator on the Polygon stakeManager contract.
    /// @dev Stake a validator on the Polygon stakeManager contract.
    /// @param _sender msg.sender.
    /// @param _amount amount to stake.
    /// @param _heimdallFee herimdall fees.
    /// @param _acceptDelegation accept delegation.
    /// @param _signerPubkey signer public key used on the heimdall.
    /// @param _commisionRate commision rate of a validator
    function stake(
        address _sender,
        uint256 _amount,
        uint256 _heimdallFee,
        bool _acceptDelegation,
        bytes memory _signerPubkey,
        uint256 _commisionRate,
        address stakeManager,
        address polygonERC20
    ) external returns (uint256, address);

    /// @notice Restake Matics for a validator on polygon stake manager.
    /// @param sender operator owner which approved tokens to the validato contract.
    /// @param validatorId validator id.
    /// @param amount amount to stake.
    /// @param stakeRewards restake rewards.
    /// @param stakeManager stake manager address
    /// @param polygonERC20 address of the MATIC token
    function restake(
        address sender,
        uint256 validatorId,
        uint256 amount,
        bool stakeRewards,
        address stakeManager,
        address polygonERC20
    ) external;

    /// @notice Unstake a validator from the Polygon stakeManager contract.
    /// @dev Unstake a validator from the Polygon stakeManager contract by passing the validatorId
    /// @param _validatorId validatorId.
    /// @param _stakeManager address of the stake manager
    function unstake(uint256 _validatorId, address _stakeManager) external;

    /// @notice Allows to top up heimdall fees.
    /// @param _heimdallFee amount
    /// @param _sender msg.sender
    /// @param _stakeManager stake manager address
    /// @param _polygonERC20 address of the MATIC token
    function topUpForFee(
        address _sender,
        uint256 _heimdallFee,
        address _stakeManager,
        address _polygonERC20
    ) external;

    /// @notice Allows to withdraw rewards from the validator.
    /// @dev Allows to withdraw rewards from the validator using the _validatorId. Only the
    /// owner can request withdraw in this the owner is this contract.
    /// @param _validatorId validator id.
    /// @param _rewardAddress user address used to transfer the staked tokens.
    /// @param _stakeManager stake manager address
    /// @param _polygonERC20 address of the MATIC token
    /// @return Returns the amount transfered to the user.
    function withdrawRewards(
        uint256 _validatorId,
        address _rewardAddress,
        address _stakeManager,
        address _polygonERC20
    ) external returns (uint256);

    /// @notice Allows to claim staked tokens on the stake Manager after the end of the
    /// withdraw delay
    /// @param _validatorId validator id.
    /// @param _rewardAddress user address used to transfer the staked tokens.
    /// @return Returns the amount transfered to the user.
    function unstakeClaim(
        uint256 _validatorId,
        address _rewardAddress,
        address _stakeManager,
        address _polygonERC20
    ) external returns (uint256);

    /// @notice Allows to update the signer pubkey
    /// @param _validatorId validator id
    /// @param _signerPubkey update signer public key
    /// @param _stakeManager stake manager address
    function updateSigner(
        uint256 _validatorId,
        bytes memory _signerPubkey,
        address _stakeManager
    ) external;

    /// @notice Allows to claim the heimdall fees.
    /// @param _accumFeeAmount accumulated fees amount
    /// @param _index index
    /// @param _proof proof
    /// @param _ownerRecipient owner recipient
    /// @param _stakeManager stake manager address
    /// @param _polygonERC20 address of the MATIC token
    function claimFee(
        uint256 _accumFeeAmount,
        uint256 _index,
        bytes memory _proof,
        address _ownerRecipient,
        address _stakeManager,
        address _polygonERC20
    ) external;

    /// @notice Allows to update the commision rate of a validator
    /// @param _validatorId operator id
    /// @param _newCommissionRate commission rate
    /// @param _stakeManager stake manager address
    function updateCommissionRate(
        uint256 _validatorId,
        uint256 _newCommissionRate,
        address _stakeManager
    ) external;

    /// @notice Allows to unjail a validator.
    /// @param _validatorId operator id
    function unjail(uint256 _validatorId, address _stakeManager) external;

    /// @notice Allows to migrate the ownership to an other user.
    /// @param _validatorId operator id.
    /// @param _stakeManagerNFT stake manager nft contract.
    /// @param _rewardAddress reward address.
    function migrate(
        uint256 _validatorId,
        address _stakeManagerNFT,
        address _rewardAddress
    ) external;

    /// @notice Allows a validator that was already staked on the polygon stake manager
    /// to join the PoLido protocol.
    /// @param _validatorId validator id
    /// @param _stakeManagerNFT address of the staking NFT
    /// @param _rewardAddress address that will receive the rewards from staking
    /// @param _newCommissionRate commission rate
    /// @param _stakeManager address of the stake manager
    function join(
        uint256 _validatorId,
        address _stakeManagerNFT,
        address _rewardAddress,
        uint256 _newCommissionRate,
        address _stakeManager
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Address.sol)

pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
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
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
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
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
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