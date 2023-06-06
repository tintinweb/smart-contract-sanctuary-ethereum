// SPDX-License-Identifier: BSD-3-Clause
/*
 *                          88  88                                   88
 *                          88  88                            ,d     ""
 *                          88  88                            88
 *  ,adPPYba,   ,adPPYba,   88  88   ,adPPYba,   ,adPPYba,  MM88MMM  88  8b       d8   ,adPPYba,
 * a8"     ""  a8"     "8a  88  88  a8P_____88  a8"     ""    88     88  `8b     d8'  a8P_____88
 * 8b          8b       d8  88  88  8PP"""""""  8b            88     88   `8b   d8'   8PP"""""""
 * "8a,   ,aa  "8a,   ,a8"  88  88  "8b,   ,aa  "8a,   ,aa    88,    88    `8b,d8'    "8b,   ,aa
 *  `"Ybbd8"'   `"YbbdP"'   88  88   `"Ybbd8"'   `"Ybbd8"'    "Y888  88      "8"       `"Ybbd8"'
 *
 */
/*
 * BSD 3-Clause License
 *
 * Copyright (c) 2023, collective
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 *
 * 1. Redistributions of source code must retain the above copyright notice, this
 *    list of conditions and the following disclaimer.
 *
 * 2. Redistributions in binary form must reproduce the above copyright notice,
 *    this list of conditions and the following disclaimer in the documentation
 *    and/or other materials provided with the distribution.
 *
 * 3. Neither the name of the copyright holder nor the names of its
 *    contributors may be used to endorse or promote products derived from
 *    this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
 * AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 * DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
 * FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 * DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
 * CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
 * OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 * OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */
pragma solidity ^0.8.15;

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { Initializable } from "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import { UUPSUpgradeable } from "@openzeppelin/contracts/proxy/utils/UUPSUpgradeable.sol";
import { IERC165 } from "@openzeppelin/contracts/interfaces/IERC165.sol";
import { ERC165 } from "@openzeppelin/contracts/utils/introspection/ERC165.sol";

import { OwnableInitializable } from "../../contracts/access/OwnableInitializable.sol";
import { Versioned } from "../../contracts/access/Versioned.sol";
import { VersionedContract } from "../../contracts/access/VersionedContract.sol";
import { Constant } from "../../contracts/Constant.sol";
import { AddressCollection } from "../../contracts/collection/AddressSet.sol";
import { Treasury } from "../../contracts/treasury/Treasury.sol";

/**
 * @notice TreasuryBuilder is designed to help building up an on-chain treasury.
 */
contract TreasuryBuilder is VersionedContract, ERC165, OwnableInitializable, UUPSUpgradeable, Initializable {
    string public constant NAME = "treasury builder";

    error AtLeastOneApprovalIsRequired(address sender);
    error TimeLockDelayIsNotPermitted(address sender, uint256 timeLockTime, uint256 timeLockMinimum);
    error RequiresAdditionalApprovers(address sender, uint256 numberOfApprovers, uint256 requiredNumber);

    event Initialized();
    event Upgraded(uint8 version);
    
    /// settings initialized
    event TreasuryInitialized(address sender);
    /// approver added
    event TreasuryApprover(address sender, address approver);
    /// required approvers set
    event TreasuryMinimumRequirement(address sender, uint256 requirement);
    /// timelock time is set
    event TreasuryTimeLock(address sender, uint256 timelockDelay);
    /// build successful
    event TreasuryCreated(address sender, address treasury);

    /// UUPS authorization
    event UpgradeAuthorized(address caller, address owner);

    /// @notice the properties of a treasury as it is being built
    struct TreasuryProperties {
        /// @notice the number of approvers required for a transaction
        uint256 approvalRequirement;
        /// @notice the minumum timelock time
        uint256 timeLockTime;
        /// @notice the set of all allowed approvers
        AddressCollection approver;
    }

    mapping(address => TreasuryProperties) private _treasuryMap;

    constructor() {
        _disableInitializers();
    }

    function initialize() public initializer {
        ownerInitialize(msg.sender);
        emit Initialized();
    }

    function upgrade(uint8 _version) public reinitializer(_version) {
        emit Upgraded(_version);
    }

    /**
     * @notice begin the process of building the treasury by
     * creating a new mapping for sender
     * @return TreasuryBuilder this contract
     */
    function aTreasury() external returns (TreasuryBuilder) {
        clear();
        emit TreasuryInitialized(msg.sender);
        return this;
    }

    /**
     * @notice set the approval requirement
     * @param _requirement The minimum requirement
     * @return TreasuryBuilder this contract
     */
    function withMinimumApprovalRequirement(uint256 _requirement) external returns (TreasuryBuilder) {
        TreasuryProperties storage _properties = _treasuryMap[msg.sender];
        _properties.approvalRequirement = _requirement;
        emit TreasuryMinimumRequirement(msg.sender, _requirement);
        return this;
    }

    /**
     * @notice set the minimum timelock delay
     * @param _timelockDelay the minimum delay
     * @return TreasuryBuilder this contract
     */
    function withTimeLockDelay(uint256 _timelockDelay) external returns (TreasuryBuilder) {
        TreasuryProperties storage _properties = _treasuryMap[msg.sender];
        _properties.timeLockTime = _timelockDelay;
        emit TreasuryTimeLock(msg.sender, _timelockDelay);
        return this;
    }

    /**
     * @notice add an approver
     * @param _approver the approver address
     */
    function withApprover(address _approver) external returns (TreasuryBuilder) {
        TreasuryProperties storage _properties = _treasuryMap[msg.sender];
        _properties.approver.add(_approver);
        emit TreasuryApprover(msg.sender, _approver);
        return this;
    }

    function build() external returns (address payable) {
        TreasuryProperties memory _properties = _treasuryMap[msg.sender];
        if (_properties.approvalRequirement < 1) revert AtLeastOneApprovalIsRequired(msg.sender);
        if (_properties.timeLockTime < Constant.TIMELOCK_MINIMUM_DELAY)
            revert TimeLockDelayIsNotPermitted(msg.sender, _properties.timeLockTime, Constant.TIMELOCK_MINIMUM_DELAY);
        if (_properties.timeLockTime > Constant.TIMELOCK_MAXIMUM_DELAY)
            revert TimeLockDelayIsNotPermitted(msg.sender, _properties.timeLockTime, Constant.TIMELOCK_MAXIMUM_DELAY);
        if (_properties.approver.size() < _properties.approvalRequirement)
            revert RequiresAdditionalApprovers(msg.sender, _properties.approver.size(), _properties.approvalRequirement);
        Treasury _instance = new Treasury(_properties.approvalRequirement, _properties.timeLockTime, _properties.approver);
        emit TreasuryCreated(msg.sender, address(_instance));
        return payable(address(_instance));
    }

    // @notice return the name of this implementation
    /// @return string memory representation of name
    function name() external pure virtual returns (string memory) {
        return NAME;
    }

    /// @notice see ERC-165
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165) returns (bool) {
        return
            interfaceId == type(Ownable).interfaceId ||
            interfaceId == type(Versioned).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    function clear() public {
        TreasuryProperties storage _properties = _treasuryMap[msg.sender];

        _properties.approvalRequirement = 0;
        _properties.timeLockTime = Constant.TIMELOCK_MINIMUM_DELAY;
        _properties.approver = Constant.createAddressSet();
    }

    function reset() external {
        clear();
        delete _treasuryMap[msg.sender];
    }

    /// see UUPSUpgradeable
    function _authorizeUpgrade(address _caller) internal virtual override(UUPSUpgradeable) onlyOwner {
        emit UpgradeAuthorized(_caller, owner());
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.1) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "../../utils/Address.sol";

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
            (isTopLevelCall && _initialized < 1) || (!Address.isContract(address(this)) && _initialized == 1),
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
// OpenZeppelin Contracts (last updated v4.8.0) (proxy/utils/UUPSUpgradeable.sol)

pragma solidity ^0.8.0;

import "../../interfaces/draft-IERC1822.sol";
import "../ERC1967/ERC1967Upgrade.sol";

/**
 * @dev An upgradeability mechanism designed for UUPS proxies. The functions included here can perform an upgrade of an
 * {ERC1967Proxy}, when this contract is set as the implementation behind such a proxy.
 *
 * A security mechanism ensures that an upgrade does not turn off upgradeability accidentally, although this risk is
 * reinstated if the upgrade retains upgradeability but removes the security mechanism, e.g. by replacing
 * `UUPSUpgradeable` with a custom implementation of upgrades.
 *
 * The {_authorizeUpgrade} function must be overridden to include access restriction to the upgrade mechanism.
 *
 * _Available since v4.1._
 */
abstract contract UUPSUpgradeable is IERC1822Proxiable, ERC1967Upgrade {
    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable state-variable-assignment
    address private immutable __self = address(this);

    /**
     * @dev Check that the execution is being performed through a delegatecall call and that the execution context is
     * a proxy contract with an implementation (as defined in ERC1967) pointing to self. This should only be the case
     * for UUPS and transparent proxies that are using the current contract as their implementation. Execution of a
     * function through ERC1167 minimal proxies (clones) would not normally pass this test, but is not guaranteed to
     * fail.
     */
    modifier onlyProxy() {
        require(address(this) != __self, "Function must be called through delegatecall");
        require(_getImplementation() == __self, "Function must be called through active proxy");
        _;
    }

    /**
     * @dev Check that the execution is not being performed through a delegate call. This allows a function to be
     * callable on the implementing contract but not through proxies.
     */
    modifier notDelegated() {
        require(address(this) == __self, "UUPSUpgradeable: must not be called through delegatecall");
        _;
    }

    /**
     * @dev Implementation of the ERC1822 {proxiableUUID} function. This returns the storage slot used by the
     * implementation. It is used to validate the implementation's compatibility when performing an upgrade.
     *
     * IMPORTANT: A proxy pointing at a proxiable contract should not be considered proxiable itself, because this risks
     * bricking a proxy that upgrades to it, by delegating to itself until out of gas. Thus it is critical that this
     * function revert if invoked through a proxy. This is guaranteed by the `notDelegated` modifier.
     */
    function proxiableUUID() external view virtual override notDelegated returns (bytes32) {
        return _IMPLEMENTATION_SLOT;
    }

    /**
     * @dev Upgrade the implementation of the proxy to `newImplementation`.
     *
     * Calls {_authorizeUpgrade}.
     *
     * Emits an {Upgraded} event.
     */
    function upgradeTo(address newImplementation) external virtual onlyProxy {
        _authorizeUpgrade(newImplementation);
        _upgradeToAndCallUUPS(newImplementation, new bytes(0), false);
    }

    /**
     * @dev Upgrade the implementation of the proxy to `newImplementation`, and subsequently execute the function call
     * encoded in `data`.
     *
     * Calls {_authorizeUpgrade}.
     *
     * Emits an {Upgraded} event.
     */
    function upgradeToAndCall(address newImplementation, bytes memory data) external payable virtual onlyProxy {
        _authorizeUpgrade(newImplementation);
        _upgradeToAndCallUUPS(newImplementation, data, true);
    }

    /**
     * @dev Function that should revert when `msg.sender` is not authorized to upgrade the contract. Called by
     * {upgradeTo} and {upgradeToAndCall}.
     *
     * Normally, this function will use an xref:access.adoc[access control] modifier such as {Ownable-onlyOwner}.
     *
     * ```solidity
     * function _authorizeUpgrade(address) internal override onlyOwner {}
     * ```
     */
    function _authorizeUpgrade(address newImplementation) internal virtual;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC165.sol)

pragma solidity ^0.8.0;

import "../utils/introspection/IERC165.sol";

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: BSD-3-Clause
/*
 *                          88  88                                   88
 *                          88  88                            ,d     ""
 *                          88  88                            88
 *  ,adPPYba,   ,adPPYba,   88  88   ,adPPYba,   ,adPPYba,  MM88MMM  88  8b       d8   ,adPPYba,
 * a8"     ""  a8"     "8a  88  88  a8P_____88  a8"     ""    88     88  `8b     d8'  a8P_____88
 * 8b          8b       d8  88  88  8PP"""""""  8b            88     88   `8b   d8'   8PP"""""""
 * "8a,   ,aa  "8a,   ,a8"  88  88  "8b,   ,aa  "8a,   ,aa    88,    88    `8b,d8'    "8b,   ,aa
 *  `"Ybbd8"'   `"YbbdP"'   88  88   `"Ybbd8"'   `"Ybbd8"'    "Y888  88      "8"       `"Ybbd8"'
 *
 */
/*
 * BSD 3-Clause License
 *
 * Copyright (c) 2022, collective
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 *
 * 1. Redistributions of source code must retain the above copyright notice, this
 *    list of conditions and the following disclaimer.
 *
 * 2. Redistributions in binary form must reproduce the above copyright notice,
 *    this list of conditions and the following disclaimer in the documentation
 *    and/or other materials provided with the distribution.
 *
 * 3. Neither the name of the copyright holder nor the names of its
 *    contributors may be used to endorse or promote products derived from
 *    this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
 * AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 * DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
 * FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 * DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
 * CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
 * OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 * OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */
pragma solidity ^0.8.15;

abstract contract OwnableInitializable {
    error NotInitialized();
    error OwnerInitialized(address owner);
    error NotOwner(address sender);

    event OwnershipTransferred(address _from, address _to);

    address internal _owner;

    modifier onlyInitialized() {
        if (_owner == address(0x0)) revert NotInitialized();
        _;
    }

    modifier notInitialized() {
        if (_owner != address(0x0)) revert OwnerInitialized(_owner);
        _;
    }

    modifier onlyOwner() {
        if (owner() != msg.sender) revert NotOwner(msg.sender);
        _;
    }

    function ownerInitialize(address _delegateOwner) internal notInitialized {
        _owner = _delegateOwner;
        emit OwnershipTransferred(address(0x0), _owner);
    }

    function owner() public view onlyInitialized returns (address) {
        return _owner;
    }

    function transferOwnership(address _delegateOwner) public onlyOwner {
        address _current = _owner;
        _owner = _delegateOwner;
        emit OwnershipTransferred(_current, _owner);
    }
}

// SPDX-License-Identifier: BSD-3-Clause
/*
 *                          88  88                                   88
 *                          88  88                            ,d     ""
 *                          88  88                            88
 *  ,adPPYba,   ,adPPYba,   88  88   ,adPPYba,   ,adPPYba,  MM88MMM  88  8b       d8   ,adPPYba,
 * a8"     ""  a8"     "8a  88  88  a8P_____88  a8"     ""    88     88  `8b     d8'  a8P_____88
 * 8b          8b       d8  88  88  8PP"""""""  8b            88     88   `8b   d8'   8PP"""""""
 * "8a,   ,aa  "8a,   ,a8"  88  88  "8b,   ,aa  "8a,   ,aa    88,    88    `8b,d8'    "8b,   ,aa
 *  `"Ybbd8"'   `"YbbdP"'   88  88   `"Ybbd8"'   `"Ybbd8"'    "Y888  88      "8"       `"Ybbd8"'
 *
 */
/*
 * BSD 3-Clause License
 *
 * Copyright (c) 2022, collective
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 *
 * 1. Redistributions of source code must retain the above copyright notice, this
 *    list of conditions and the following disclaimer.
 *
 * 2. Redistributions in binary form must reproduce the above copyright notice,
 *    this list of conditions and the following disclaimer in the documentation
 *    and/or other materials provided with the distribution.
 *
 * 3. Neither the name of the copyright holder nor the names of its
 *    contributors may be used to endorse or promote products derived from
 *    this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
 * AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 * DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
 * FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 * DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
 * CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
 * OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 * OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */
pragma solidity ^0.8.15;

/// @title requirement for Versioned contract
/// @custom:type interface
interface Versioned {
    function version() external pure returns (uint32);
}

// SPDX-License-Identifier: BSD-3-Clause
/*
 *                          88  88                                   88
 *                          88  88                            ,d     ""
 *                          88  88                            88
 *  ,adPPYba,   ,adPPYba,   88  88   ,adPPYba,   ,adPPYba,  MM88MMM  88  8b       d8   ,adPPYba,
 * a8"     ""  a8"     "8a  88  88  a8P_____88  a8"     ""    88     88  `8b     d8'  a8P_____88
 * 8b          8b       d8  88  88  8PP"""""""  8b            88     88   `8b   d8'   8PP"""""""
 * "8a,   ,aa  "8a,   ,a8"  88  88  "8b,   ,aa  "8a,   ,aa    88,    88    `8b,d8'    "8b,   ,aa
 *  `"Ybbd8"'   `"YbbdP"'   88  88   `"Ybbd8"'   `"Ybbd8"'    "Y888  88      "8"       `"Ybbd8"'
 *
 */
/*
 * BSD 3-Clause License
 *
 * Copyright (c) 2022, collective
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 *
 * 1. Redistributions of source code must retain the above copyright notice, this
 *    list of conditions and the following disclaimer.
 *
 * 2. Redistributions in binary form must reproduce the above copyright notice,
 *    this list of conditions and the following disclaimer in the documentation
 *    and/or other materials provided with the distribution.
 *
 * 3. Neither the name of the copyright holder nor the names of its
 *    contributors may be used to endorse or promote products derived from
 *    this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
 * AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 * DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
 * FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 * DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
 * CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
 * OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 * OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */
pragma solidity ^0.8.15;

import { Constant } from "../../contracts/Constant.sol";
import { Versioned } from "../../contracts/access/Versioned.sol";

/// @title Versioned contract
abstract contract VersionedContract is Versioned {
    /// @notice return the version number of this contract
    /// @return uint32 the version number
    function version() external pure returns (uint32) {
        return Constant.CURRENT_VERSION;
    }
}

// SPDX-License-Identifier: BSD-3-Clause
/*
 *                          88  88                                   88
 *                          88  88                            ,d     ""
 *                          88  88                            88
 *  ,adPPYba,   ,adPPYba,   88  88   ,adPPYba,   ,adPPYba,  MM88MMM  88  8b       d8   ,adPPYba,
 * a8"     ""  a8"     "8a  88  88  a8P_____88  a8"     ""    88     88  `8b     d8'  a8P_____88
 * 8b          8b       d8  88  88  8PP"""""""  8b            88     88   `8b   d8'   8PP"""""""
 * "8a,   ,aa  "8a,   ,a8"  88  88  "8b,   ,aa  "8a,   ,aa    88,    88    `8b,d8'    "8b,   ,aa
 *  `"Ybbd8"'   `"YbbdP"'   88  88   `"Ybbd8"'   `"Ybbd8"'    "Y888  88      "8"       `"Ybbd8"'
 *
 */
/*
 * BSD 3-Clause License
 *
 * Copyright (c) 2022, collective
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 *
 * 1. Redistributions of source code must retain the above copyright notice, this
 *    list of conditions and the following disclaimer.
 *
 * 2. Redistributions in binary form must reproduce the above copyright notice,
 *    this list of conditions and the following disclaimer in the documentation
 *    and/or other materials provided with the distribution.
 *
 * 3. Neither the name of the copyright holder nor the names of its
 *    contributors may be used to endorse or promote products derived from
 *    this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
 * AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 * DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
 * FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 * DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
 * CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
 * OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 * OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */
pragma solidity ^0.8.15;

import { AddressCollection, AddressSet } from "../contracts/collection/AddressSet.sol";
import { MetaCollection, MetaSet } from "../contracts/collection/MetaSet.sol";
import { TransactionCollection, TransactionSet } from "../contracts/collection/TransactionSet.sol";
import { ChoiceCollection, ChoiceSet } from "../contracts/collection/ChoiceSet.sol";

/**
 * @notice extract global manifest constants
 */
library Constant {
    uint256 public constant UINT_MAX = type(uint256).max;

    /// @notice minimum quorum
    uint256 public constant MINIMUM_PROJECT_QUORUM = 1;

    /// @notice minimum vote delay
    /// @dev A vote delay is recommended to support cancellation of votes, however it is not
    ///      required
    uint256 public constant MINIMUM_VOTE_DELAY = 0 days;

    /// @notice maximum vote delay
    /// @dev default of unlimited is recommended
    uint256 public constant MAXIMUM_VOTE_DELAY = UINT_MAX;

    /// @notice minimum vote duration
    /// @dev For security reasons this must be a relatively long time compared to seconds
    uint256 public constant MINIMUM_VOTE_DURATION = 1 hours;

    /// @notice maximum vote duration
    /// @dev default of unlimited is recommended
    uint256 public constant MAXIMUM_VOTE_DURATION = UINT_MAX;

    // timelock setup

    /// @notice maximum time allowed after the nonce to successfully execute the time lock
    uint256 public constant TIMELOCK_GRACE_PERIOD = 14 days;
    /// @notice the minimum lock period
    uint256 public constant TIMELOCK_MINIMUM_DELAY = MINIMUM_VOTE_DURATION;
    /// @notice the maximum lock period
    uint256 public constant TIMELOCK_MAXIMUM_DELAY = 30 days;

    /// @notice limit for string information in meta data
    uint256 public constant STRING_DATA_LIMIT = 1024;

    /// @notice The maximum priority fee
    uint256 public constant MAXIMUM_REBATE_PRIORITY_FEE = 2 gwei;
    /// @notice The vote rebate gas overhead, including 7K for ETH transfer and 29K for general transaction overhead
    uint256 public constant REBATE_BASE_GAS = 36000;
    /// @notice The maximum refundable gas used
    uint256 public constant MAXIMUM_REBATE_GAS_USED = 200_000;
    /// @notice the maximum allowed gas fee for rebate
    uint256 public constant MAXIMUM_REBATE_BASE_FEE = 200 gwei;

    /// software versions
    uint32 public constant CURRENT_VERSION = 3;

    /// @notice Compute the length of any string in solidity
    /// @dev This method is expensive and is used only for validating
    ///      inputs on the creation of new Governance contract
    ///      or upon the configuration of a new vote
    function len(string memory str) public pure returns (uint256) {
        uint256 bytelength = bytes(str).length;
        uint256 i = 0;
        uint256 length;
        for (length = 0; i < bytelength; length++) {
            bytes1 b = bytes(str)[i];
            if (b < 0x80) {
                i += 1;
            } else if (b < 0xE0) {
                i += 2;
            } else if (b < 0xF0) {
                i += 3;
            } else if (b < 0xF8) {
                i += 4;
            } else if (b < 0xFC) {
                i += 5;
            } else {
                i += 6;
            }
        }
        return length;
    }

    /// @return bool True if empty string
    function empty(string memory str) external pure returns (bool) {
        return len(str) == 0;
    }

    /// factory  implementation
    /**
     * @notice create an AddressSet
     * @return AddressSet the created set
     */
    function createAddressSet() public returns (AddressCollection) {
        return new AddressSet();
    }

    /**
     * create address set from provided collection
     */
    function from(AddressCollection _set) external returns (AddressCollection) {
        AddressCollection _collection = createAddressSet();
        for (uint i = 1; i <= _set.size(); ++i) {
            _collection.add(_set.get(i));
        }
        return _collection;
    }

    /**
     * create from array
     */
    function from(address[] memory addrList) external returns (AddressCollection) {
        AddressCollection _collection = createAddressSet();
        for (uint i = 0; i < addrList.length; ++i) {
            _collection.add(addrList[i]);
        }
        return _collection;
    }

    /**
     * @notice create an MetaSet
     * @return MetaSet the created set
     */
    function createMetaSet() external returns (MetaCollection) {
        return new MetaSet();
    }

    /**
     * @notice create an TransactionSet
     * @return TransactionSet the created set
     */
    function createTransactionSet() external returns (TransactionCollection) {
        return new TransactionSet();
    }

    /**
     * @notice create an ChoiceSet
     * @return ChoiceSet the created set
     */
    function createChoiceSet() external returns (ChoiceCollection) {
        return new ChoiceSet();
    }
}

// SPDX-License-Identifier: BSD-3-Clause
/*
 *                          88  88                                   88
 *                          88  88                            ,d     ""
 *                          88  88                            88
 *  ,adPPYba,   ,adPPYba,   88  88   ,adPPYba,   ,adPPYba,  MM88MMM  88  8b       d8   ,adPPYba,
 * a8"     ""  a8"     "8a  88  88  a8P_____88  a8"     ""    88     88  `8b     d8'  a8P_____88
 * 8b          8b       d8  88  88  8PP"""""""  8b            88     88   `8b   d8'   8PP"""""""
 * "8a,   ,aa  "8a,   ,a8"  88  88  "8b,   ,aa  "8a,   ,aa    88,    88    `8b,d8'    "8b,   ,aa
 *  `"Ybbd8"'   `"YbbdP"'   88  88   `"Ybbd8"'   `"Ybbd8"'    "Y888  88      "8"       `"Ybbd8"'
 *
 */
/*
 * BSD 3-Clause License
 *
 * Copyright (c) 2023, collective
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 *
 * 1. Redistributions of source code must retain the above copyright notice, this
 *    list of conditions and the following disclaimer.
 *
 * 2. Redistributions in binary form must reproduce the above copyright notice,
 *    this list of conditions and the following disclaimer in the documentation
 *    and/or other materials provided with the distribution.
 *
 * 3. Neither the name of the copyright holder nor the names of its
 *    contributors may be used to endorse or promote products derived from
 *    this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
 * AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 * DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
 * FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 * DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
 * CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
 * OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 * OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */
pragma solidity ^0.8.15;

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";

interface AddressCollection {
    error IndexInvalid(uint256 index);
    error DuplicateAddress(address _address);

    event AddressAdded(address element);
    event AddressRemoved(address element);

    function add(address _element) external returns (uint256);

    function set(address _element) external returns (bool);

    function size() external view returns (uint256);

    function get(uint256 index) external view returns (address);

    function contains(address _element) external view returns (bool);

    function erase(address _element) external returns (bool);
}

/// @title dynamic collection of addresses
contract AddressSet is Ownable, AddressCollection {
    uint256 private _elementCount;

    mapping(uint256 => address) private _elementMap;

    mapping(address => uint256) private _elementPresent;

    constructor() {
        _elementCount = 0;
    }

    modifier requireValidIndex(uint256 index) {
        if (index == 0 || index > _elementCount) revert IndexInvalid(index);
        _;
    }

    /// @notice add an element
    /// @param _element the address
    /// @return uint256 the elementId of the transaction
    function add(address _element) public onlyOwner returns (uint256) {
        uint256 elementIndex = ++_elementCount;
        _elementMap[elementIndex] = _element;
        if (_elementPresent[_element] > 0) revert DuplicateAddress(_element);
        _elementPresent[_element] = elementIndex;
        emit AddressAdded(_element);
        return elementIndex;
    }

    /// @notice set value
    /// @param _element the address
    /// @return bool true if added false otherwise
    function set(address _element) external onlyOwner returns (bool) {
        if (_elementPresent[_element] > 0) return false;
        add(_element);
        return true;
    }

    /// @notice erase an element
    /// @dev swaps element to end and deletes the end
    /// @param _index The address to erase
    /// @return bool True if element was removed
    function erase(uint256 _index) external onlyOwner returns (bool) {
        address _element = _elementMap[_index];
        return erase(_element);
    }

    /// @notice erase an element
    /// @dev swaps element to end and deletes the end
    /// @param _element The address to erase
    /// @return bool True if element was removed
    function erase(address _element) public onlyOwner returns (bool) {
        uint256 elementIndex = _elementPresent[_element];
        if (elementIndex > 0) {
            address _lastElement = _elementMap[_elementCount];
            _elementMap[elementIndex] = _lastElement;
            _elementPresent[_lastElement] = elementIndex;
            _elementMap[_elementCount] = address(0x0);
            _elementPresent[_element] = 0;
            delete _elementMap[_elementCount];
            delete _elementPresent[_element];
            _elementCount--;
            emit AddressRemoved(_element);
            return true;
        }
        return false;
    }

    /// @return uint256 The size of the set
    function size() external view returns (uint256) {
        return _elementCount;
    }

    /// @param index The index to return
    /// @return address The requested address
    function get(uint256 index) external view requireValidIndex(index) returns (address) {
        return _elementMap[index];
    }

    /// @param _element The element to test
    /// @return bool True if address is contained
    function contains(address _element) external view returns (bool) {
        return find(_element) > 0;
    }

    /// @param _element The element to find
    /// @return uint256 The index associated with element
    function find(address _element) public view returns (uint256) {
        return _elementPresent[_element];
    }
}

// SPDX-License-Identifier: BSD-3-Clause
/*
 *                          88  88                                   88
 *                          88  88                            ,d     ""
 *                          88  88                            88
 *  ,adPPYba,   ,adPPYba,   88  88   ,adPPYba,   ,adPPYba,  MM88MMM  88  8b       d8   ,adPPYba,
 * a8"     ""  a8"     "8a  88  88  a8P_____88  a8"     ""    88     88  `8b     d8'  a8P_____88
 * 8b          8b       d8  88  88  8PP"""""""  8b            88     88   `8b   d8'   8PP"""""""
 * "8a,   ,aa  "8a,   ,a8"  88  88  "8b,   ,aa  "8a,   ,aa    88,    88    `8b,d8'    "8b,   ,aa
 *  `"Ybbd8"'   `"YbbdP"'   88  88   `"Ybbd8"'   `"Ybbd8"'    "Y888  88      "8"       `"Ybbd8"'
 *
 */
/*
 * BSD 3-Clause License
 *
 * Copyright (c) 2023, collective
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 *
 * 1. Redistributions of source code must retain the above copyright notice, this
 *    list of conditions and the following disclaimer.
 *
 * 2. Redistributions in binary form must reproduce the above copyright notice,
 *    this list of conditions and the following disclaimer in the documentation
 *    and/or other materials provided with the distribution.
 *
 * 3. Neither the name of the copyright holder nor the names of its
 *    contributors may be used to endorse or promote products derived from
 *    this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
 * AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 * DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
 * FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 * DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
 * CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
 * OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 * OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

pragma solidity ^0.8.15;

import { ECDSA } from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

import { Constant } from "../../contracts/Constant.sol";
import { TimeLock } from "../../contracts/treasury/TimeLock.sol";
import { Vault } from "../../contracts/treasury/Vault.sol";
import { AddressCollection } from "../../contracts/collection/AddressSet.sol";
import { Transaction, getHash } from "../../contracts/collection/TransactionSet.sol";

/**
 * @notice Custom multisig treasury for ETH
 */
contract Treasury is Vault {
    mapping(address => Payment) private _payment;

    TimeLock private immutable _timeLock;
    AddressCollection public immutable _approverSet;
    uint256 public immutable _minimumApprovalCount;

    /**
     * construct the Treasury
     * @param _minimumApprovalRequirement The number number of approvers before a transaction can be pending
     * @param _minimumTimeLock The minimum time for any transaction to be processed
     * @param _approver A set of addresses to be used as approvers
     */
    constructor(uint256 _minimumApprovalRequirement, uint256 _minimumTimeLock, AddressCollection _approver) {
        _timeLock = new TimeLock(_minimumTimeLock);
        _approverSet = Constant.from(_approver);
        _minimumApprovalCount = _minimumApprovalRequirement;
    }

    modifier requireApprover() {
        if (!_approverSet.contains(msg.sender)) revert NotApprover(msg.sender);
        _;
    }

    modifier requireNotPending(address _to) {
        Payment memory _pay = _payment[_to];
        if (_pay.scheduleTime > 0) revert TransactionInProgress(_to);
        _;
    }

    modifier requirePayee(address _to) {
        Payment memory _pay = _payment[_to];
        if (_pay.approvalCount < _minimumApprovalCount) revert NotPending(_to);
        _;
    }

    modifier requireSufficientBalance(uint256 _quantity) {
        uint256 availableQty = address(this).balance;
        if (availableQty < _quantity) {
            revert InsufficientBalance(_quantity, availableQty);
        }
        _;
    }

    receive() external payable {
        deposit();
    }

    // solhint-disable-next-line payable-fallback
    fallback() external {
        pay();
    }

    /// @notice deposit msg.value in the vault
    /// @dev payable
    function deposit() public payable {
        uint256 _quantity = msg.value;
        if (_quantity == 0) revert NoDeposit(msg.sender);
        emit Deposit(_quantity);
    }

    /// @notice approve transfer of _quantity
    /// @param _to the address approved to withdraw the amount
    /// @param _quantity the amount of the approved transfer
    function approve(
        address _to,
        uint256 _quantity
    ) public requireApprover requireNotPending(_to) requireSufficientBalance(_quantity) {
        Payment storage _pay = _payment[_to];
        if (_pay.approvalCount == 0) {
            _pay.approvalSet = Constant.createAddressSet();
        }
        if (!_pay.approvalSet.set(msg.sender)) {
            revert DuplicateApproval(msg.sender);
        }
        _pay.approvalCount += 1;
        if (_pay.approvalCount == 1 && _pay.quantity == 0) {
            _pay.quantity = _quantity;
        } else if (_pay.quantity != _quantity) {
            revert ApprovalNotMatched(msg.sender, _quantity, _pay.quantity);
        }

        if (_pay.approvalCount == _minimumApprovalCount) {
            uint256 scheduleTime = getBlockTimestamp() + _timeLock._lockTime();
            _pay.scheduleTime = scheduleTime;
            // transfer to timelock for execution
            address payable _lockBalance = payable(address(_timeLock));
            _timeLock.queueTransaction(_to, _pay.quantity, "", "", _pay.scheduleTime);
            _lockBalance.transfer(_quantity);
            emit Withdraw(_pay.quantity, _to, _pay.scheduleTime);
        }
    }

    /**
     * @notice Approve and schedule a payment to recipient in one transaction.
     *
     * Each required approver must individually sign a message that
     * represents the standardized transaction for the payment transfer
     * as follows
     *
     * keccak256(abi.encode(_to, _quantity, "", "", _scheduleTime))
     *
     * Each approver must sign off chain and the signatures passed to this function.
     *
     * @dev _scheduleTime is subject to timelock constraints
     *
     * @param _to the address of the recipient
     * @param _quantity to approve
     * @param _scheduleTime the scheduled time
     * @param _signature array of signature as bytes
     */
    function approveMulti(
        address _to,
        uint256 _quantity,
        uint256 _scheduleTime,
        bytes[] memory _signature
    ) external requireApprover requireNotPending(_to) requireSufficientBalance(_quantity) {
        Transaction memory agreement = Transaction(_to, _quantity, "", "", _scheduleTime);
        bytes32 agreementHash = getHash(agreement);
        Payment storage _pay = _payment[_to];
        if (_pay.approvalCount == 0) {
            _pay.approvalSet = Constant.createAddressSet();
        }
        for (uint i = 0; i < _signature.length; ++i) {
            bytes memory signature = _signature[i];
            address signer = verifySignature(agreementHash, _approverSet, signature);
            if (!_pay.approvalSet.set(signer)) {
                revert DuplicateApproval(signer);
            }
            _pay.approvalCount += 1;
            if (_pay.approvalCount == 1 && _pay.quantity == 0) {
                _pay.quantity = _quantity;
            } else if (_pay.quantity != _quantity) {
                revert ApprovalNotMatched(msg.sender, _quantity, _pay.quantity);
            }

            if (_pay.approvalCount == _minimumApprovalCount) {
                _pay.scheduleTime = _scheduleTime;
                // transfer to timelock for execution
                address payable _lockBalance = payable(address(_timeLock));
                _timeLock.queueTransaction(_to, _pay.quantity, "", "", _pay.scheduleTime);
                _lockBalance.transfer(_quantity);
                emit Withdraw(_pay.quantity, _to, _pay.scheduleTime);
            }
        }
    }

    /// @notice pay quantity to msg.sender
    function pay() public {
        transferTo(msg.sender);
    }

    /// @notice transfer approved quantity to
    /// @dev requires approval
    /// @param _to the address to pay
    function transferTo(address _to) public requirePayee(_to) {
        Payment storage _pay = _payment[_to];
        uint256 scheduleTime = _pay.scheduleTime;
        uint256 quantity = _pay.quantity;
        _timeLock.executeTransaction(_to, quantity, "", "", scheduleTime);
        emit PaymentSent(quantity, _to);
        clear(_to);
    }

    /// @notice cancel the approved payment
    /// @param _to the approved recipient
    function cancel(address _to) public requireApprover {
        Payment memory _pay = _payment[_to];
        if (_pay.scheduleTime == 0) {
            revert NotPending(_to);
        }
        _timeLock.cancelTransaction(_to, _pay.quantity, "", "", _pay.scheduleTime);
        clear(_to);
    }

    /// @notice balance approved for the specified address
    /// @param _from the address of the wallet to check
    function balance(address _from) public view returns (uint256) {
        Payment memory _pay = _payment[_from];
        if (_pay.approvalCount >= _minimumApprovalCount) {
            return _pay.quantity;
        }
        return 0;
    }

    /// @notice total balance on treasury
    function balance() public view override(Vault) returns (uint256) {
        return address(_timeLock).balance + address(this).balance;
    }

    function verifySignature(
        bytes32 _agreementHash,
        AddressCollection _approvedSet,
        bytes memory _signature
    ) private view returns (address) {
        address signatureAddress = ECDSA.recover(_agreementHash, _signature);
        if (!_approvedSet.contains(signatureAddress)) revert SignatureNotValid(signatureAddress);
        return signatureAddress;
    }

    function clear(address _to) private {
        Payment storage _pay = _payment[_to];
        _pay.quantity = 0;
        _pay.scheduleTime = 0;
        _pay.approvalCount = 0;
        delete _payment[_to];
    }

    function getBlockTimestamp() private view returns (uint256) {
        // solhint-disable-next-line not-rely-on-time
        return block.timestamp;
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

pragma solidity ^0.8.1;

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (interfaces/draft-IERC1822.sol)

pragma solidity ^0.8.0;

/**
 * @dev ERC1822: Universal Upgradeable Proxy Standard (UUPS) documents a method for upgradeability through a simplified
 * proxy whose upgrades are fully controlled by the current implementation.
 */
interface IERC1822Proxiable {
    /**
     * @dev Returns the storage slot that the proxiable contract assumes is being used to store the implementation
     * address.
     *
     * IMPORTANT: A proxy pointing at a proxiable contract should not be considered proxiable itself, because this risks
     * bricking a proxy that upgrades to it, by delegating to itself until out of gas. Thus it is critical that this
     * function revert if invoked through a proxy.
     */
    function proxiableUUID() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.3) (proxy/ERC1967/ERC1967Upgrade.sol)

pragma solidity ^0.8.2;

import "../beacon/IBeacon.sol";
import "../../interfaces/IERC1967.sol";
import "../../interfaces/draft-IERC1822.sol";
import "../../utils/Address.sol";
import "../../utils/StorageSlot.sol";

/**
 * @dev This abstract contract provides getters and event emitting update functions for
 * https://eips.ethereum.org/EIPS/eip-1967[EIP1967] slots.
 *
 * _Available since v4.1._
 *
 * @custom:oz-upgrades-unsafe-allow delegatecall
 */
abstract contract ERC1967Upgrade is IERC1967 {
    // This is the keccak-256 hash of "eip1967.proxy.rollback" subtracted by 1
    bytes32 private constant _ROLLBACK_SLOT = 0x4910fdfa16fed3260ed0e7147f7cc6da11a60208b5b9406d12a635614ffd9143;

    /**
     * @dev Storage slot with the address of the current implementation.
     * This is the keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    /**
     * @dev Returns the current implementation address.
     */
    function _getImplementation() internal view returns (address) {
        return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 implementation slot.
     */
    function _setImplementation(address newImplementation) private {
        require(Address.isContract(newImplementation), "ERC1967: new implementation is not a contract");
        StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
    }

    /**
     * @dev Perform implementation upgrade
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeTo(address newImplementation) internal {
        _setImplementation(newImplementation);
        emit Upgraded(newImplementation);
    }

    /**
     * @dev Perform implementation upgrade with additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCall(
        address newImplementation,
        bytes memory data,
        bool forceCall
    ) internal {
        _upgradeTo(newImplementation);
        if (data.length > 0 || forceCall) {
            Address.functionDelegateCall(newImplementation, data);
        }
    }

    /**
     * @dev Perform implementation upgrade with security checks for UUPS proxies, and additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCallUUPS(
        address newImplementation,
        bytes memory data,
        bool forceCall
    ) internal {
        // Upgrades from old implementations will perform a rollback test. This test requires the new
        // implementation to upgrade back to the old, non-ERC1822 compliant, implementation. Removing
        // this special case will break upgrade paths from old UUPS implementation to new ones.
        if (StorageSlot.getBooleanSlot(_ROLLBACK_SLOT).value) {
            _setImplementation(newImplementation);
        } else {
            try IERC1822Proxiable(newImplementation).proxiableUUID() returns (bytes32 slot) {
                require(slot == _IMPLEMENTATION_SLOT, "ERC1967Upgrade: unsupported proxiableUUID");
            } catch {
                revert("ERC1967Upgrade: new implementation is not UUPS");
            }
            _upgradeToAndCall(newImplementation, data, forceCall);
        }
    }

    /**
     * @dev Storage slot with the admin of the contract.
     * This is the keccak-256 hash of "eip1967.proxy.admin" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _ADMIN_SLOT = 0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;

    /**
     * @dev Returns the current admin.
     */
    function _getAdmin() internal view returns (address) {
        return StorageSlot.getAddressSlot(_ADMIN_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 admin slot.
     */
    function _setAdmin(address newAdmin) private {
        require(newAdmin != address(0), "ERC1967: new admin is the zero address");
        StorageSlot.getAddressSlot(_ADMIN_SLOT).value = newAdmin;
    }

    /**
     * @dev Changes the admin of the proxy.
     *
     * Emits an {AdminChanged} event.
     */
    function _changeAdmin(address newAdmin) internal {
        emit AdminChanged(_getAdmin(), newAdmin);
        _setAdmin(newAdmin);
    }

    /**
     * @dev The storage slot of the UpgradeableBeacon contract which defines the implementation for this proxy.
     * This is bytes32(uint256(keccak256('eip1967.proxy.beacon')) - 1)) and is validated in the constructor.
     */
    bytes32 internal constant _BEACON_SLOT = 0xa3f0ad74e5423aebfd80d3ef4346578335a9a72aeaee59ff6cb3582b35133d50;

    /**
     * @dev Returns the current beacon.
     */
    function _getBeacon() internal view returns (address) {
        return StorageSlot.getAddressSlot(_BEACON_SLOT).value;
    }

    /**
     * @dev Stores a new beacon in the EIP1967 beacon slot.
     */
    function _setBeacon(address newBeacon) private {
        require(Address.isContract(newBeacon), "ERC1967: new beacon is not a contract");
        require(
            Address.isContract(IBeacon(newBeacon).implementation()),
            "ERC1967: beacon implementation is not a contract"
        );
        StorageSlot.getAddressSlot(_BEACON_SLOT).value = newBeacon;
    }

    /**
     * @dev Perform beacon upgrade with additional setup call. Note: This upgrades the address of the beacon, it does
     * not upgrade the implementation contained in the beacon (see {UpgradeableBeacon-_setImplementation} for that).
     *
     * Emits a {BeaconUpgraded} event.
     */
    function _upgradeBeaconToAndCall(
        address newBeacon,
        bytes memory data,
        bool forceCall
    ) internal {
        _setBeacon(newBeacon);
        emit BeaconUpgraded(newBeacon);
        if (data.length > 0 || forceCall) {
            Address.functionDelegateCall(IBeacon(newBeacon).implementation(), data);
        }
    }
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

// SPDX-License-Identifier: BSD-3-Clause
/*
 *                          88  88                                   88
 *                          88  88                            ,d     ""
 *                          88  88                            88
 *  ,adPPYba,   ,adPPYba,   88  88   ,adPPYba,   ,adPPYba,  MM88MMM  88  8b       d8   ,adPPYba,
 * a8"     ""  a8"     "8a  88  88  a8P_____88  a8"     ""    88     88  `8b     d8'  a8P_____88
 * 8b          8b       d8  88  88  8PP"""""""  8b            88     88   `8b   d8'   8PP"""""""
 * "8a,   ,aa  "8a,   ,a8"  88  88  "8b,   ,aa  "8a,   ,aa    88,    88    `8b,d8'    "8b,   ,aa
 *  `"Ybbd8"'   `"YbbdP"'   88  88   `"Ybbd8"'   `"Ybbd8"'    "Y888  88      "8"       `"Ybbd8"'
 *
 */
/*
 * BSD 3-Clause License
 *
 * Copyright (c) 2023, collective
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 *
 * 1. Redistributions of source code must retain the above copyright notice, this
 *    list of conditions and the following disclaimer.
 *
 * 2. Redistributions in binary form must reproduce the above copyright notice,
 *    this list of conditions and the following disclaimer in the documentation
 *    and/or other materials provided with the distribution.
 *
 * 3. Neither the name of the copyright holder nor the names of its
 *    contributors may be used to endorse or promote products derived from
 *    this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
 * AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 * DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
 * FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 * DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
 * CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
 * OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 * OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */
pragma solidity ^0.8.15;

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";

/// @notice User defined metadata
struct Meta {
    /// @notice metadata key or name
    bytes32 name;
    /// @notice metadata value
    string value;
}

// solhint-disable-next-line func-visibility
function getHash(Meta memory meta) pure returns (bytes32) {
    return keccak256(abi.encode(meta));
}

interface MetaCollection {
    error IndexInvalid(uint256 index);
    error HashCollision(bytes32 txId);

    event MetaAdded(bytes32 metaHash);
    event MetaRemoved(bytes32 metaHash);

    function add(Meta memory meta) external returns (uint256);

    function size() external view returns (uint256);

    function get(uint256 index) external view returns (Meta memory);
}

/// @title dynamic collection of metadata
contract MetaSet is Ownable, MetaCollection {
    uint256 private _elementCount;

    mapping(uint256 => Meta) private _elementMap;

    mapping(bytes32 => uint256) private _elementPresent;

    constructor() {
        _elementCount = 0;
    }

    modifier requireValidIndex(uint256 index) {
        if (index == 0 || index > _elementCount) revert IndexInvalid(index);
        _;
    }

    /// @notice add meta
    /// @param _element the meta
    /// @return uint256 the elementId of the meta
    function add(Meta memory _element) external onlyOwner returns (uint256) {
        uint256 elementIndex = ++_elementCount;
        _elementMap[elementIndex] = _element;
        bytes32 _elementHash = getHash(_element);
        if (_elementPresent[_elementHash] > 0) revert HashCollision(_elementHash);
        _elementPresent[_elementHash] = elementIndex;
        emit MetaAdded(_elementHash);
        return elementIndex;
    }

    function erase(Meta memory _meta) public onlyOwner returns (bool) {
        bytes32 metaHash = getHash(_meta);
        uint256 index = _elementPresent[metaHash];
        return erase(index);
    }

    /// @notice erase a meta
    /// @param _index the index to remove
    /// @return bool True if element was removed
    function erase(uint256 _index) public onlyOwner returns (bool) {
        Meta memory meta = _elementMap[_index];
        bytes32 metaHash = getHash(meta);
        uint256 elementIndex = _elementPresent[metaHash];
        if (elementIndex > 0 && elementIndex == _index) {
            Meta memory _lastMeta = _elementMap[_elementCount];
            _elementMap[elementIndex] = _lastMeta;
            bytes32 _lastMetaHash = getHash(_lastMeta);
            _elementPresent[_lastMetaHash] = elementIndex;
            _elementMap[_elementCount] = Meta("", "");
            _elementPresent[metaHash] = 0;
            delete _elementMap[_elementCount];
            delete _elementPresent[metaHash];
            _elementCount--;
            emit MetaRemoved(metaHash);
            return true;
        }
        return false;
    }

    /// @return uint256 The size of the set
    function size() external view returns (uint256) {
        return _elementCount;
    }

    /// @param index The index to return
    /// @return address The requested address
    function get(uint256 index) external view requireValidIndex(index) returns (Meta memory) {
        return _elementMap[index];
    }

    /// @param _meta The element to test
    /// @return bool True if address is contained
    function contains(Meta memory _meta) external view returns (bool) {
        return find(_meta) > 0;
    }

    /// @param _meta The element to find
    /// @return uint256 The index associated with element
    function find(Meta memory _meta) public view returns (uint256) {
        bytes32 metaHash = getHash(_meta);
        return _elementPresent[metaHash];
    }
}

// SPDX-License-Identifier: BSD-3-Clause
/*
 *                          88  88                                   88
 *                          88  88                            ,d     ""
 *                          88  88                            88
 *  ,adPPYba,   ,adPPYba,   88  88   ,adPPYba,   ,adPPYba,  MM88MMM  88  8b       d8   ,adPPYba,
 * a8"     ""  a8"     "8a  88  88  a8P_____88  a8"     ""    88     88  `8b     d8'  a8P_____88
 * 8b          8b       d8  88  88  8PP"""""""  8b            88     88   `8b   d8'   8PP"""""""
 * "8a,   ,aa  "8a,   ,a8"  88  88  "8b,   ,aa  "8a,   ,aa    88,    88    `8b,d8'    "8b,   ,aa
 *  `"Ybbd8"'   `"YbbdP"'   88  88   `"Ybbd8"'   `"Ybbd8"'    "Y888  88      "8"       `"Ybbd8"'
 *
 */
/*
 * BSD 3-Clause License
 *
 * Copyright (c) 2023, collective
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 *
 * 1. Redistributions of source code must retain the above copyright notice, this
 *    list of conditions and the following disclaimer.
 *
 * 2. Redistributions in binary form must reproduce the above copyright notice,
 *    this list of conditions and the following disclaimer in the documentation
 *    and/or other materials provided with the distribution.
 *
 * 3. Neither the name of the copyright holder nor the names of its
 *    contributors may be used to endorse or promote products derived from
 *    this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
 * AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 * DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
 * FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 * DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
 * CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
 * OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 * OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */
pragma solidity ^0.8.15;

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";

/// @notice The executable transaction
struct Transaction {
    /// @notice target for call instruction
    address target;
    /// @notice value to pass
    uint256 value;
    /// @notice signature for call
    string signature;
    /// @notice call data of the call
    bytes _calldata;
    /// @notice future dated start time for call within the TimeLocked grace period
    uint256 scheduleTime;
}

// solhint-disable-next-line func-visibility
function getHash(Transaction memory transaction) pure returns (bytes32) {
    return keccak256(abi.encode(transaction));
}

interface TransactionCollection {
    error InvalidTransaction(uint256 index);
    error HashCollision(bytes32 txId);

    event TransactionAdded(bytes32 transactionHash);
    event TransactionRemoved(bytes32 transactionHash);

    function add(Transaction memory transaction) external returns (uint256);

    function size() external view returns (uint256);

    function get(uint256 index) external view returns (Transaction memory);

    function erase(uint256 _index) external returns (bool);
}

/// @title dynamic collection of transaction
contract TransactionSet is Ownable, TransactionCollection {
    uint256 private _elementCount;

    mapping(uint256 => Transaction) private _elementMap;
    mapping(bytes32 => uint256) private _elementPresent;

    constructor() {
        _elementCount = 0;
    }

    modifier requireValidIndex(uint256 index) {
        if (index == 0 || index > _elementCount) revert InvalidTransaction(index);
        _;
    }

    /// @notice add transaction
    /// @param _element the transaction
    /// @return uint256 the elementId of the transaction
    function add(Transaction memory _element) external onlyOwner returns (uint256) {
        uint256 elementIndex = ++_elementCount;
        _elementMap[elementIndex] = _element;
        bytes32 _elementHash = getHash(_element);
        if (_elementPresent[_elementHash] > 0) revert HashCollision(_elementHash);
        _elementPresent[_elementHash] = elementIndex;
        emit TransactionAdded(_elementHash);
        return elementIndex;
    }

    function erase(Transaction memory _transaction) public onlyOwner returns (bool) {
        bytes32 transactionHash = getHash(_transaction);
        uint256 index = _elementPresent[transactionHash];
        return erase(index);
    }

    /// @notice erase a transaction
    /// @param _index the index to remove
    /// @return bool True if element was removed
    function erase(uint256 _index) public onlyOwner returns (bool) {
        Transaction memory transaction = _elementMap[_index];
        bytes32 transactionHash = getHash(transaction);
        uint256 elementIndex = _elementPresent[transactionHash];
        if (elementIndex > 0 && elementIndex == _index) {
            Transaction memory _lastTransaction = _elementMap[_elementCount];
            _elementMap[elementIndex] = _lastTransaction;
            bytes32 _lastTransactionHash = getHash(_lastTransaction);
            _elementPresent[_lastTransactionHash] = elementIndex;
            _elementMap[_elementCount] = Transaction(address(0x0), 0, "", "", 0);
            _elementPresent[transactionHash] = 0;
            delete _elementMap[_elementCount];
            delete _elementPresent[transactionHash];
            _elementCount--;
            emit TransactionRemoved(transactionHash);
            return true;
        }
        return false;
    }

    /// @return uint256 The size of the set
    function size() external view returns (uint256) {
        return _elementCount;
    }

    /// @param index The index to return
    /// @return address The requested address
    function get(uint256 index) external view requireValidIndex(index) returns (Transaction memory) {
        return _elementMap[index];
    }

    /// @param _transaction The element to test
    /// @return bool True if address is contained
    function contains(Transaction memory _transaction) external view returns (bool) {
        return find(_transaction) > 0;
    }

    /// @param _transaction The element to find
    /// @return uint256 The index associated with element
    function find(Transaction memory _transaction) public view returns (uint256) {
        bytes32 transactionHash = getHash(_transaction);
        return _elementPresent[transactionHash];
    }
}

// SPDX-License-Identifier: BSD-3-Clause
/*
 *                          88  88                                   88
 *                          88  88                            ,d     ""
 *                          88  88                            88
 *  ,adPPYba,   ,adPPYba,   88  88   ,adPPYba,   ,adPPYba,  MM88MMM  88  8b       d8   ,adPPYba,
 * a8"     ""  a8"     "8a  88  88  a8P_____88  a8"     ""    88     88  `8b     d8'  a8P_____88
 * 8b          8b       d8  88  88  8PP"""""""  8b            88     88   `8b   d8'   8PP"""""""
 * "8a,   ,aa  "8a,   ,a8"  88  88  "8b,   ,aa  "8a,   ,aa    88,    88    `8b,d8'    "8b,   ,aa
 *  `"Ybbd8"'   `"YbbdP"'   88  88   `"Ybbd8"'   `"Ybbd8"'    "Y888  88      "8"       `"Ybbd8"'
 *
 */
/*
 * BSD 3-Clause License
 *
 * Copyright (c) 2023, collective
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 *
 * 1. Redistributions of source code must retain the above copyright notice, this
 *    list of conditions and the following disclaimer.
 *
 * 2. Redistributions in binary form must reproduce the above copyright notice,
 *    this list of conditions and the following disclaimer in the documentation
 *    and/or other materials provided with the distribution.
 *
 * 3. Neither the name of the copyright holder nor the names of its
 *    contributors may be used to endorse or promote products derived from
 *    this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
 * AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 * DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
 * FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 * DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
 * CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
 * OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 * OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */
pragma solidity ^0.8.15;

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";

/// @notice choice for multiple choice voting
/// @dev choice voting is enabled by initializing the number of choices when the proposal is created
struct Choice {
    bytes32 name;
    string description;
    uint256 transactionId;
    bytes32 txHash;
    uint256 voteCount;
}

// solhint-disable-next-line func-visibility
function getHash(Choice memory choice) pure returns (bytes32) {
    return keccak256(abi.encode(choice));
}

interface ChoiceCollection {
    error IndexInvalid(uint256 index);
    error HashCollision(bytes32 txId);

    event ChoiceAdded(bytes32 choiceHash);
    event ChoiceRemoved(bytes32 choiceHash);
    event ChoiceIncrement(uint256 index, uint256 voteCount);

    function add(Choice memory choice) external returns (uint256);

    function size() external view returns (uint256);

    function get(uint256 index) external view returns (Choice memory);

    function contains(uint256 _choiceId) external view returns (bool);

    function incrementVoteCount(uint256 index) external returns (uint256);
}

/// @title dynamic collection of choicedata
contract ChoiceSet is Ownable, ChoiceCollection {
    uint256 private _elementCount;

    mapping(uint256 => Choice) private _elementMap;

    mapping(bytes32 => uint256) private _elementPresent;

    constructor() {
        _elementCount = 0;
    }

    modifier requireValidIndex(uint256 index) {
        if (index == 0 || index > _elementCount) revert IndexInvalid(index);
        _;
    }

    /// @notice add choice
    /// @param _element the choice
    /// @return uint256 the elementId of the choice
    function add(Choice memory _element) external onlyOwner returns (uint256) {
        uint256 elementIndex = ++_elementCount;
        _elementMap[elementIndex] = _element;
        bytes32 _elementHash = getHash(_element);
        if (_elementPresent[_elementHash] > 0) revert HashCollision(_elementHash);
        _elementPresent[_elementHash] = elementIndex;
        emit ChoiceAdded(_elementHash);
        return elementIndex;
    }

    function erase(Choice memory _choice) public onlyOwner returns (bool) {
        bytes32 choiceHash = getHash(_choice);
        uint256 index = _elementPresent[choiceHash];
        return erase(index);
    }

    /// @notice erase a choice
    /// @param _index the index to remove
    /// @return bool True if element was removed
    function erase(uint256 _index) public onlyOwner returns (bool) {
        Choice memory choice = _elementMap[_index];
        bytes32 choiceHash = getHash(choice);
        uint256 elementIndex = _elementPresent[choiceHash];
        if (elementIndex > 0 && elementIndex == _index) {
            Choice memory _lastChoice = _elementMap[_elementCount];
            _elementMap[elementIndex] = _lastChoice;
            bytes32 _lastChoiceHash = getHash(_lastChoice);
            _elementPresent[_lastChoiceHash] = elementIndex;
            _elementMap[_elementCount] = Choice("", "", 0, "", 0);
            _elementPresent[choiceHash] = 0;
            delete _elementMap[_elementCount];
            delete _elementPresent[choiceHash];
            _elementCount--;
            emit ChoiceRemoved(choiceHash);
            return true;
        }
        return false;
    }

    /// @return uint256 The size of the set
    function size() external view returns (uint256) {
        return _elementCount;
    }

    /// @param index The index to return
    /// @return address The requested address
    function get(uint256 index) external view requireValidIndex(index) returns (Choice memory) {
        return _elementMap[index];
    }

    /// increment the votecount choice parameter
    /// @param index The index to increment
    /// @return uint256 The updated count
    function incrementVoteCount(uint256 index) external requireValidIndex(index) returns (uint256) {
        Choice storage choice = _elementMap[index];
        choice.voteCount += 1;
        emit ChoiceIncrement(index, choice.voteCount);
        return choice.voteCount;
    }

    /// @param _choice The element to test
    /// @return bool True if address is contained
    function contains(Choice memory _choice) external view returns (bool) {
        return find(_choice) > 0;
    }

    /// @param _choiceId The element to test
    /// @return bool True if address is contained
    function contains(uint256 _choiceId) external view returns (bool) {
        return _choiceId > 0 && _choiceId <= _elementCount;
    }

    /// @param _choice The element to find
    /// @return uint256 The index associated with element
    function find(Choice memory _choice) public view returns (uint256) {
        bytes32 choiceHash = getHash(_choice);
        return _elementPresent[choiceHash];
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/cryptography/ECDSA.sol)

pragma solidity ^0.8.0;

import "../Strings.sol";

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSA {
    enum RecoverError {
        NoError,
        InvalidSignature,
        InvalidSignatureLength,
        InvalidSignatureS,
        InvalidSignatureV // Deprecated in v4.8
    }

    function _throwError(RecoverError error) private pure {
        if (error == RecoverError.NoError) {
            return; // no error: do nothing
        } else if (error == RecoverError.InvalidSignature) {
            revert("ECDSA: invalid signature");
        } else if (error == RecoverError.InvalidSignatureLength) {
            revert("ECDSA: invalid signature length");
        } else if (error == RecoverError.InvalidSignatureS) {
            revert("ECDSA: invalid signature 's' value");
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature` or error string. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     *
     * Documentation for signature generation:
     * - with https://web3js.readthedocs.io/en/v1.3.4/web3-eth-accounts.html#sign[Web3.js]
     * - with https://docs.ethers.io/v5/api/signer/#Signer-signMessage[ethers]
     *
     * _Available since v4.3._
     */
    function tryRecover(bytes32 hash, bytes memory signature) internal pure returns (address, RecoverError) {
        if (signature.length == 65) {
            bytes32 r;
            bytes32 s;
            uint8 v;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            /// @solidity memory-safe-assembly
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
            return tryRecover(hash, v, r, s);
        } else {
            return (address(0), RecoverError.InvalidSignatureLength);
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, signature);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `r` and `vs` short-signature fields separately.
     *
     * See https://eips.ethereum.org/EIPS/eip-2098[EIP-2098 short signatures]
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address, RecoverError) {
        bytes32 s = vs & bytes32(0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff);
        uint8 v = uint8((uint256(vs) >> 255) + 27);
        return tryRecover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `r and `vs` short-signature fields separately.
     *
     * _Available since v4.2._
     */
    function recover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, r, vs);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `v`,
     * `r` and `s` signature fields separately.
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address, RecoverError) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (301): 0 < s < secp256k1n ÷ 2 + 1, and for v in (302): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            return (address(0), RecoverError.InvalidSignatureS);
        }

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        if (signer == address(0)) {
            return (address(0), RecoverError.InvalidSignature);
        }

        return (signer, RecoverError.NoError);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, v, r, s);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from `s`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes memory s) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n", Strings.toString(s.length), s));
    }

    /**
     * @dev Returns an Ethereum Signed Typed Data, created from a
     * `domainSeparator` and a `structHash`. This produces hash corresponding
     * to the one signed with the
     * https://eips.ethereum.org/EIPS/eip-712[`eth_signTypedData`]
     * JSON-RPC method as part of EIP-712.
     *
     * See {recover}.
     */
    function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
    }
}

// SPDX-License-Identifier: BSD-3-Clause
/*
 *                          88  88                                   88
 *                          88  88                            ,d     ""
 *                          88  88                            88
 *  ,adPPYba,   ,adPPYba,   88  88   ,adPPYba,   ,adPPYba,  MM88MMM  88  8b       d8   ,adPPYba,
 * a8"     ""  a8"     "8a  88  88  a8P_____88  a8"     ""    88     88  `8b     d8'  a8P_____88
 * 8b          8b       d8  88  88  8PP"""""""  8b            88     88   `8b   d8'   8PP"""""""
 * "8a,   ,aa  "8a,   ,a8"  88  88  "8b,   ,aa  "8a,   ,aa    88,    88    `8b,d8'    "8b,   ,aa
 *  `"Ybbd8"'   `"YbbdP"'   88  88   `"Ybbd8"'   `"Ybbd8"'    "Y888  88      "8"       `"Ybbd8"'
 *
 */
/*
 * BSD 3-Clause License
 *
 * Copyright (c) 2022, collective
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 *
 * 1. Redistributions of source code must retain the above copyright notice, this
 *    list of conditions and the following disclaimer.
 *
 * 2. Redistributions in binary form must reproduce the above copyright notice,
 *    this list of conditions and the following disclaimer in the documentation
 *    and/or other materials provided with the distribution.
 *
 * 3. Neither the name of the copyright holder nor the names of its
 *    contributors may be used to endorse or promote products derived from
 *    this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
 * AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 * DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
 * FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 * DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
 * CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
 * OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 * OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

pragma solidity ^0.8.15;

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";

import { Constant } from "../../contracts/Constant.sol";
import { getHash, Transaction, TransactionSet } from "../../contracts/collection/TransactionSet.sol";
import { TimeLocker } from "../../contracts/treasury/TimeLocker.sol";

/**
 * @notice TimeLock transactions until a future time.   This is useful to guarantee that a Transaction
 * is specified in advance of a vote and to make it impossible to execute before the end of voting.
 *
 * @dev This is a modified version of Compound Finance TimeLock.
 *
 * https://github.com/compound-finance/compound-protocol/blob/a3214f67b73310d547e00fc578e8355911c9d376/contracts/Timelock.sol
 *
 * Implements Ownable and requires owner for all operations.
 */
contract TimeLock is TimeLocker, Ownable {
    uint256 public immutable _lockTime;

    /// @notice table of transaction hashes, map to true if seen by the queueTransaction operation
    mapping(bytes32 => bool) public _queuedTransaction;

    /**
     * @param _lockDuration The time delay required for the time lock
     */
    constructor(uint256 _lockDuration) {
        if (_lockDuration < Constant.TIMELOCK_MINIMUM_DELAY || _lockDuration > Constant.TIMELOCK_MAXIMUM_DELAY) {
            revert RequiredDelayNotInRange(_lockDuration, Constant.TIMELOCK_MINIMUM_DELAY, Constant.TIMELOCK_MAXIMUM_DELAY);
        }
        _lockTime = _lockDuration;
    }

    receive() external payable {
        emit TimelockEth(msg.sender, msg.value);
    }

    // solhint-disable-next-line payable-fallback
    fallback() external {
        revert NotPermitted(msg.sender);
    }

    /**
     * @notice Mark a transaction as queued for this time lock
     * @dev It is only possible to execute a queued transaction.   Queueing in the context of a TimeLock is
     * the process of identifying in advance or naming the transaction to be executed.  Nothing is actually queued.
     * @param _target the target address for this transaction
     * @param _value the value to pass to the call
     * @param _signature the tranaction signature
     * @param _calldata the call data to pass to the call
     * @param _scheduleTime the expected time when the _target should be available to call
     * @return bytes32 the hash value for the transaction used for the internal index
     */
    function queueTransaction(
        address _target,
        uint256 _value,
        string calldata _signature,
        bytes calldata _calldata,
        uint256 _scheduleTime
    ) external onlyOwner returns (bytes32) {
        Transaction memory transaction = Transaction(_target, _value, _signature, _calldata, _scheduleTime);
        bytes32 txHash = getHash(transaction);
        uint256 blockTime = getBlockTimestamp();
        uint256 startLock = blockTime + _lockTime;
        uint256 endLock = startLock + Constant.TIMELOCK_GRACE_PERIOD;
        if (_scheduleTime < startLock || _scheduleTime > endLock) {
            revert TimestampNotInLockRange(txHash, blockTime, _scheduleTime, startLock, endLock);
        }
        if (_queuedTransaction[txHash]) revert QueueCollision(txHash);
        setQueue(txHash);
        emit QueueTransaction(txHash, _target, _value, _signature, _calldata, _scheduleTime);
        return txHash;
    }

    /**
     * @notice cancel a queued transaction from the timelock
     * @param _target the target address for this transaction
     * @param _value the value to pass to the call
     * @param _signature the tranaction signature
     * @param _calldata the call data to pass to the call
     * @param _scheduleTime the expected time when the _target should be available to call
     */
    function cancelTransaction(
        address _target,
        uint256 _value,
        string calldata _signature,
        bytes calldata _calldata,
        uint256 _scheduleTime
    ) external onlyOwner returns (bytes32) {
        Transaction memory transaction = Transaction(_target, _value, _signature, _calldata, _scheduleTime);
        bytes32 txHash = getHash(transaction);
        if (!_queuedTransaction[txHash]) revert NotInQueue(txHash);
        clearQueue(txHash);
        emit CancelTransaction(txHash, _target, _value, _signature, _calldata, _scheduleTime);
        return txHash;
    }

    /**
     * @notice If the time lock is concluded, execute the scheduled transaction.
     * @dev It is only possible to execute a queued transaction therefore anyone may initiate the call
     * @param _target the target address for this transaction
     * @param _value the value to pass to the call
     * @param _signature the tranaction signature
     * @param _calldata the call data to pass to the call
     * @param _scheduleTime the expected time when the _target should be available to call
     * @return bytes The return data from the executed call
     */
    function executeTransaction(
        address _target,
        uint256 _value,
        string calldata _signature,
        bytes calldata _calldata,
        uint256 _scheduleTime
    ) external payable returns (bytes memory) {
        Transaction memory transaction = Transaction(_target, _value, _signature, _calldata, _scheduleTime);
        bytes32 txHash = getHash(transaction);
        if (!_queuedTransaction[txHash]) {
            revert NotInQueue(txHash);
        }
        uint256 blockTime = getBlockTimestamp();
        if (blockTime < _scheduleTime) {
            revert TransactionLocked(txHash, _scheduleTime);
        }
        if (blockTime > (_scheduleTime + Constant.TIMELOCK_GRACE_PERIOD)) {
            revert TransactionStale(txHash);
        }

        clearQueue(txHash);
        bytes memory callData;
        if (bytes(_signature).length == 0) {
            callData = _calldata;
        } else {
            callData = abi.encodePacked(bytes4(keccak256(bytes(_signature))), _calldata);
        }

        // solhint-disable-next-line avoid-low-level-calls
        (bool ok, bytes memory returnData) = _target.call{ value: _value }(callData);
        if (!ok) revert ExecutionFailed(txHash);
        emit ExecuteTransaction(txHash, _target, _value, _signature, _calldata, _scheduleTime);
        return returnData;
    }

    /**
     * @notice get a queued transaction
     * @param _txHash Transaction hash to check
     * @return bool True if transaction is queued and false otherwise
     */
    function queuedTransaction(bytes32 _txHash) external view returns (bool) {
        return _queuedTransaction[_txHash];
    }

    function setQueue(bytes32 _txHash) private {
        _queuedTransaction[_txHash] = true;
    }

    function clearQueue(bytes32 _txHash) private {
        // overwrite memory to protect against value rebinding
        _queuedTransaction[_txHash] = false;
        delete _queuedTransaction[_txHash];
    }

    function getBlockTimestamp() internal view returns (uint256) {
        // solhint-disable-next-line not-rely-on-time
        return block.timestamp;
    }
}

// SPDX-License-Identifier: BSD-3-Clause
/*
 *                          88  88                                   88
 *                          88  88                            ,d     ""
 *                          88  88                            88
 *  ,adPPYba,   ,adPPYba,   88  88   ,adPPYba,   ,adPPYba,  MM88MMM  88  8b       d8   ,adPPYba,
 * a8"     ""  a8"     "8a  88  88  a8P_____88  a8"     ""    88     88  `8b     d8'  a8P_____88
 * 8b          8b       d8  88  88  8PP"""""""  8b            88     88   `8b   d8'   8PP"""""""
 * "8a,   ,aa  "8a,   ,a8"  88  88  "8b,   ,aa  "8a,   ,aa    88,    88    `8b,d8'    "8b,   ,aa
 *  `"Ybbd8"'   `"YbbdP"'   88  88   `"Ybbd8"'   `"Ybbd8"'    "Y888  88      "8"       `"Ybbd8"'
 *
 */
/*
 * BSD 3-Clause License
 *
 * Copyright (c) 2023, collective
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 *
 * 1. Redistributions of source code must retain the above copyright notice, this
 *    list of conditions and the following disclaimer.
 *
 * 2. Redistributions in binary form must reproduce the above copyright notice,
 *    this list of conditions and the following disclaimer in the documentation
 *    and/or other materials provided with the distribution.
 *
 * 3. Neither the name of the copyright holder nor the names of its
 *    contributors may be used to endorse or promote products derived from
 *    this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
 * AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 * DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
 * FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 * DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
 * CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
 * OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 * OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

pragma solidity ^0.8.15;

import { AddressCollection } from "../../contracts/collection/AddressSet.sol";

/**
 * @notice Vault interface for treasury implementation
 */
/// @custom:type interface
interface Vault {
    /// when signature was not confirmed
    error SignatureNotValid(address signer);
    /// Please deposit or withdraw instead
    error FallbackNotPermitted();
    /// deposit sent but value was nil
    error NoDeposit(address sender);
    /// An approver is required for this operation
    error NotApprover(address sender);
    /// attempt to approve transaction when a transaction is already in progress
    error TransactionInProgress(address sender);
    /// no transaction is pending, approve first
    error NotPending(address payee);
    /// approved quantity disagreement
    error ApprovalNotMatched(address sender, uint256 quantity, uint256 expected);
    /// quantity not available for approval
    error InsufficientBalance(uint256 quantity, uint256 available);
    /// attempt to approve twice from same signature
    error DuplicateApproval(address signer);

    /// a deposit has been recieved
    event Deposit(uint256 quantity);
    /// withdraw completed
    event Withdraw(uint256 quantity, address _to, uint256 timeAvailable);
    /// payment completed
    event PaymentSent(uint256 quantity, address _to);

    struct Payment {
        uint256 quantity;
        uint256 scheduleTime;
        uint256 approvalCount;
        AddressCollection approvalSet;
    }

    /// @notice deposit msg.value in the vault
    /// @dev payable
    function deposit() external payable;

    /// @notice approve transfer of _quantity
    /// @param _to the address approved to withdraw the amount
    /// @param _quantity the amount of the approved transfer
    function approve(address _to, uint256 _quantity) external;

    /**
     * @notice Approve and schedule a payment to recipient in one transaction.
     *
     * Each required approver must individually sign a message that
     * represents the standardized transaction for the payment transfer
     * as follows
     *
     * keccak256(abi.encode(_to, _quantity, "", "", _scheduleTime))
     *
     * Each approver must sign off chain and the signatures passed to this function.
     *
     * @dev _scheduleTime is subject to timelock constraints
     *
     * @param _to the address of the recipient
     * @param _quantity to approve
     * @param _scheduleTime the scheduled time
     * @param _signature array of signature as bytes
     */
    function approveMulti(address _to, uint256 _quantity, uint256 _scheduleTime, bytes[] memory _signature) external;

    /// @notice pay quantity to msg.sender
    function pay() external;

    /// @notice transfer approved quantity to
    /// @dev requires approval
    /// @param _to the address to pay
    function transferTo(address _to) external;

    /// @notice cancel the approved payment
    /// @param _to the approved recipient
    function cancel(address _to) external;

    /// @notice balance approved for the specified address
    /// @param _from the address of the wallet to check
    function balance(address _from) external view returns (uint256);

    /// @notice total balance on treasury
    function balance() external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/beacon/IBeacon.sol)

pragma solidity ^0.8.0;

/**
 * @dev This is the interface that {BeaconProxy} expects of its beacon.
 */
interface IBeacon {
    /**
     * @dev Must return an address that can be used as a delegate call target.
     *
     * {BeaconProxy} will check that this address is a contract.
     */
    function implementation() external view returns (address);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.3) (interfaces/IERC1967.sol)

pragma solidity ^0.8.0;

/**
 * @dev ERC-1967: Proxy Storage Slots. This interface contains the events defined in the ERC.
 *
 * _Available since v4.9._
 */
interface IERC1967 {
    /**
     * @dev Emitted when the implementation is upgraded.
     */
    event Upgraded(address indexed implementation);

    /**
     * @dev Emitted when the admin account has changed.
     */
    event AdminChanged(address previousAdmin, address newAdmin);

    /**
     * @dev Emitted when the beacon is changed.
     */
    event BeaconUpgraded(address indexed beacon);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/StorageSlot.sol)

pragma solidity ^0.8.0;

/**
 * @dev Library for reading and writing primitive types to specific storage slots.
 *
 * Storage slots are often used to avoid storage conflict when dealing with upgradeable contracts.
 * This library helps with reading and writing to such slots without the need for inline assembly.
 *
 * The functions in this library return Slot structs that contain a `value` member that can be used to read or write.
 *
 * Example usage to set ERC1967 implementation slot:
 * ```
 * contract ERC1967 {
 *     bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
 *
 *     function _getImplementation() internal view returns (address) {
 *         return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
 *     }
 *
 *     function _setImplementation(address newImplementation) internal {
 *         require(Address.isContract(newImplementation), "ERC1967: new implementation is not a contract");
 *         StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
 *     }
 * }
 * ```
 *
 * _Available since v4.1 for `address`, `bool`, `bytes32`, and `uint256`._
 */
library StorageSlot {
    struct AddressSlot {
        address value;
    }

    struct BooleanSlot {
        bool value;
    }

    struct Bytes32Slot {
        bytes32 value;
    }

    struct Uint256Slot {
        uint256 value;
    }

    /**
     * @dev Returns an `AddressSlot` with member `value` located at `slot`.
     */
    function getAddressSlot(bytes32 slot) internal pure returns (AddressSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `BooleanSlot` with member `value` located at `slot`.
     */
    function getBooleanSlot(bytes32 slot) internal pure returns (BooleanSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Bytes32Slot` with member `value` located at `slot`.
     */
    function getBytes32Slot(bytes32 slot) internal pure returns (Bytes32Slot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Uint256Slot` with member `value` located at `slot`.
     */
    function getUint256Slot(bytes32 slot) internal pure returns (Uint256Slot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

import "./math/Math.sol";

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        unchecked {
            uint256 length = Math.log10(value) + 1;
            string memory buffer = new string(length);
            uint256 ptr;
            /// @solidity memory-safe-assembly
            assembly {
                ptr := add(buffer, add(32, length))
            }
            while (true) {
                ptr--;
                /// @solidity memory-safe-assembly
                assembly {
                    mstore8(ptr, byte(mod(value, 10), _SYMBOLS))
                }
                value /= 10;
                if (value == 0) break;
            }
            return buffer;
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        unchecked {
            return toHexString(value, Math.log256(value) + 1);
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }
}

// SPDX-License-Identifier: BSD-3-Clause
/*
 *                          88  88                                   88
 *                          88  88                            ,d     ""
 *                          88  88                            88
 *  ,adPPYba,   ,adPPYba,   88  88   ,adPPYba,   ,adPPYba,  MM88MMM  88  8b       d8   ,adPPYba,
 * a8"     ""  a8"     "8a  88  88  a8P_____88  a8"     ""    88     88  `8b     d8'  a8P_____88
 * 8b          8b       d8  88  88  8PP"""""""  8b            88     88   `8b   d8'   8PP"""""""
 * "8a,   ,aa  "8a,   ,a8"  88  88  "8b,   ,aa  "8a,   ,aa    88,    88    `8b,d8'    "8b,   ,aa
 *  `"Ybbd8"'   `"YbbdP"'   88  88   `"Ybbd8"'   `"Ybbd8"'    "Y888  88      "8"       `"Ybbd8"'
 *
 */
/*
 * BSD 3-Clause License
 *
 * Copyright (c) 2022, collective
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 *
 * 1. Redistributions of source code must retain the above copyright notice, this
 *    list of conditions and the following disclaimer.
 *
 * 2. Redistributions in binary form must reproduce the above copyright notice,
 *    this list of conditions and the following disclaimer in the documentation
 *    and/or other materials provided with the distribution.
 *
 * 3. Neither the name of the copyright holder nor the names of its
 *    contributors may be used to endorse or promote products derived from
 *    this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
 * AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 * DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
 * FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 * DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
 * CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
 * OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 * OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

pragma solidity ^0.8.15;

/**
 * @notice TimeLock transactions until a future time.   This is useful to guarantee that a Transaction
 * is specified in advance of a vote and to make it impossible to execute before the end of voting.
 */
/// @custom:type interface
interface TimeLocker {
    /// @notice operation is not used or forbidden
    error NotPermitted(address sender);
    /// @notice A transaction has been queued previously
    error QueueCollision(bytes32 txHash);
    /// @notice The timestamp or nonce specified does not meet the requirements for the timelock
    error TimestampNotInLockRange(bytes32 txHash, uint256 timestamp, uint256 scheduleTime, uint256 lockStart, uint256 lockEnd);
    /// @notice The provided delay does not meet the requirements for the TimeLock
    error RequiredDelayNotInRange(uint256 lockDelay, uint256 minDelay, uint256 maxDelay);
    /// @notice It is impossible to execute a call which is not in the queue already
    error NotInQueue(bytes32 txHash);
    /// @notice The specified transaction is currently locked.  Caller must wait to scheduleTime
    error TransactionLocked(bytes32 txHash, uint256 untilTime);
    /// @notice The grace period is past and the transaction is lost
    error TransactionStale(bytes32 txHash);
    /// @notice Call failed
    error ExecutionFailed(bytes32 txHash);

    /// @notice logs the receipt of eth in the Timelock for purposes of depensing later
    event TimelockEth(address sender, uint256 amount);

    /// @notice named transaction was cancelled
    event CancelTransaction(
        bytes32 indexed txHash,
        address indexed target,
        uint256 value,
        string signature,
        bytes data,
        uint256 scheduleTime
    );

    /// @notice named transaction was executed
    event ExecuteTransaction(
        bytes32 indexed txHash,
        address indexed target,
        uint256 value,
        string signature,
        bytes data,
        uint256 scheduleTime
    );

    /// @notice specified transaction was queued
    event QueueTransaction(
        bytes32 indexed txHash,
        address indexed target,
        uint256 value,
        string signature,
        bytes data,
        uint256 scheduleTime
    );

    /**
     * @notice Mark a transaction as queued for this time lock
     * @dev It is only possible to execute a queued transaction.   Queueing in the context of a TimeLock is
     * the process of identifying in advance or naming the transaction to be executed.  Nothing is actually queued.
     * @param _target the target address for this transaction
     * @param _value the value to pass to the call
     * @param _signature the tranaction signature
     * @param _calldata the call data to pass to the call
     * @param _scheduleTime the expected time when the _target should be available to call
     * @return bytes32 the hash value for the transaction used for the internal index
     */
    function queueTransaction(
        address _target,
        uint256 _value,
        string calldata _signature,
        bytes calldata _calldata,
        uint256 _scheduleTime
    ) external returns (bytes32);

    /**
     * @notice cancel a queued transaction from the timelock
     *
     * @dev this method unmarks the named transaction so that it may not be executed
     *
     * @param _target the target address for this transaction
     * @param _value the value to pass to the call
     * @param _signature the tranaction signature
     * @param _calldata the call data to pass to the call
     * @param _scheduleTime the expected time when the _target should be available to call
     */
    function cancelTransaction(
        address _target,
        uint256 _value,
        string calldata _signature,
        bytes calldata _calldata,
        uint256 _scheduleTime
    ) external returns (bytes32);

    /**
     * @notice Execute the scheduled transaction at the end of the time lock or scheduled time.
     * @dev It is only possible to execute a queued transaction.
     * @param _target the target address for this transaction
     * @param _value the value to pass to the call
     * @param _signature the tranaction signature
     * @param _calldata the call data to pass to the call
     * @param _scheduleTime the expected time when the _target should be available to call
     * @return bytes The return data from the executed call
     */
    function executeTransaction(
        address _target,
        uint256 _value,
        string calldata _signature,
        bytes calldata _calldata,
        uint256 _scheduleTime
    ) external payable returns (bytes memory);

    /**
     * @notice get a queued transaction
     * @param _txHash Transaction hash to check
     * @return bool True if transaction is queued and false otherwise
     */
    function queuedTransaction(bytes32 _txHash) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    enum Rounding {
        Down, // Toward negative infinity
        Up, // Toward infinity
        Zero // Toward zero
    }

    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a == 0 ? 0 : (a - 1) / b + 1;
    }

    /**
     * @notice Calculates floor(x * y / denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
     * @dev Original credit to Remco Bloemen under MIT license (https://xn--2-umb.com/21/muldiv)
     * with further edits by Uniswap Labs also under MIT license.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        unchecked {
            // 512-bit multiply [prod1 prod0] = x * y. Compute the product mod 2^256 and mod 2^256 - 1, then use
            // use the Chinese Remainder Theorem to reconstruct the 512 bit result. The result is stored in two 256
            // variables such that product = prod1 * 2^256 + prod0.
            uint256 prod0; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(x, y, not(0))
                prod0 := mul(x, y)
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }

            // Handle non-overflow cases, 256 by 256 division.
            if (prod1 == 0) {
                return prod0 / denominator;
            }

            // Make sure the result is less than 2^256. Also prevents denominator == 0.
            require(denominator > prod1);

            ///////////////////////////////////////////////
            // 512 by 256 division.
            ///////////////////////////////////////////////

            // Make division exact by subtracting the remainder from [prod1 prod0].
            uint256 remainder;
            assembly {
                // Compute remainder using mulmod.
                remainder := mulmod(x, y, denominator)

                // Subtract 256 bit number from 512 bit number.
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
            }

            // Factor powers of two out of denominator and compute largest power of two divisor of denominator. Always >= 1.
            // See https://cs.stackexchange.com/q/138556/92363.

            // Does not overflow because the denominator cannot be zero at this stage in the function.
            uint256 twos = denominator & (~denominator + 1);
            assembly {
                // Divide denominator by twos.
                denominator := div(denominator, twos)

                // Divide [prod1 prod0] by twos.
                prod0 := div(prod0, twos)

                // Flip twos such that it is 2^256 / twos. If twos is zero, then it becomes one.
                twos := add(div(sub(0, twos), twos), 1)
            }

            // Shift in bits from prod1 into prod0.
            prod0 |= prod1 * twos;

            // Invert denominator mod 2^256. Now that denominator is an odd number, it has an inverse modulo 2^256 such
            // that denominator * inv = 1 mod 2^256. Compute the inverse by starting with a seed that is correct for
            // four bits. That is, denominator * inv = 1 mod 2^4.
            uint256 inverse = (3 * denominator) ^ 2;

            // Use the Newton-Raphson iteration to improve the precision. Thanks to Hensel's lifting lemma, this also works
            // in modular arithmetic, doubling the correct bits in each step.
            inverse *= 2 - denominator * inverse; // inverse mod 2^8
            inverse *= 2 - denominator * inverse; // inverse mod 2^16
            inverse *= 2 - denominator * inverse; // inverse mod 2^32
            inverse *= 2 - denominator * inverse; // inverse mod 2^64
            inverse *= 2 - denominator * inverse; // inverse mod 2^128
            inverse *= 2 - denominator * inverse; // inverse mod 2^256

            // Because the division is now exact we can divide by multiplying with the modular inverse of denominator.
            // This will give us the correct result modulo 2^256. Since the preconditions guarantee that the outcome is
            // less than 2^256, this is the final result. We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inverse;
            return result;
        }
    }

    /**
     * @notice Calculates x * y / denominator with full precision, following the selected rounding direction.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator,
        Rounding rounding
    ) internal pure returns (uint256) {
        uint256 result = mulDiv(x, y, denominator);
        if (rounding == Rounding.Up && mulmod(x, y, denominator) > 0) {
            result += 1;
        }
        return result;
    }

    /**
     * @dev Returns the square root of a number. If the number is not a perfect square, the value is rounded down.
     *
     * Inspired by Henry S. Warren, Jr.'s "Hacker's Delight" (Chapter 11).
     */
    function sqrt(uint256 a) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        // For our first guess, we get the biggest power of 2 which is smaller than the square root of the target.
        //
        // We know that the "msb" (most significant bit) of our target number `a` is a power of 2 such that we have
        // `msb(a) <= a < 2*msb(a)`. This value can be written `msb(a)=2**k` with `k=log2(a)`.
        //
        // This can be rewritten `2**log2(a) <= a < 2**(log2(a) + 1)`
        // → `sqrt(2**k) <= sqrt(a) < sqrt(2**(k+1))`
        // → `2**(k/2) <= sqrt(a) < 2**((k+1)/2) <= 2**(k/2 + 1)`
        //
        // Consequently, `2**(log2(a) / 2)` is a good first approximation of `sqrt(a)` with at least 1 correct bit.
        uint256 result = 1 << (log2(a) >> 1);

        // At this point `result` is an estimation with one bit of precision. We know the true value is a uint128,
        // since it is the square root of a uint256. Newton's method converges quadratically (precision doubles at
        // every iteration). We thus need at most 7 iteration to turn our partial result with one bit of precision
        // into the expected uint128 result.
        unchecked {
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            return min(result, a / result);
        }
    }

    /**
     * @notice Calculates sqrt(a), following the selected rounding direction.
     */
    function sqrt(uint256 a, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = sqrt(a);
            return result + (rounding == Rounding.Up && result * result < a ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 2, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 128;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 64;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 32;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 16;
            }
            if (value >> 8 > 0) {
                value >>= 8;
                result += 8;
            }
            if (value >> 4 > 0) {
                value >>= 4;
                result += 4;
            }
            if (value >> 2 > 0) {
                value >>= 2;
                result += 2;
            }
            if (value >> 1 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 2, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log2(value);
            return result + (rounding == Rounding.Up && 1 << result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 10, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >= 10**64) {
                value /= 10**64;
                result += 64;
            }
            if (value >= 10**32) {
                value /= 10**32;
                result += 32;
            }
            if (value >= 10**16) {
                value /= 10**16;
                result += 16;
            }
            if (value >= 10**8) {
                value /= 10**8;
                result += 8;
            }
            if (value >= 10**4) {
                value /= 10**4;
                result += 4;
            }
            if (value >= 10**2) {
                value /= 10**2;
                result += 2;
            }
            if (value >= 10**1) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log10(value);
            return result + (rounding == Rounding.Up && 10**result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 256, rounded down, of a positive value.
     * Returns 0 if given 0.
     *
     * Adding one to the result gives the number of pairs of hex symbols needed to represent `value` as a hex string.
     */
    function log256(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 16;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 8;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 4;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 2;
            }
            if (value >> 8 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log256(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log256(value);
            return result + (rounding == Rounding.Up && 1 << (result * 8) < value ? 1 : 0);
        }
    }
}