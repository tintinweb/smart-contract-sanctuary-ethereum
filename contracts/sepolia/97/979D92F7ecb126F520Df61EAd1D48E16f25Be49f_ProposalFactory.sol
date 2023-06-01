// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity ^0.8.13;

// External Libraries
import {Clones} from "@oz/proxy/Clones.sol";

// External Interfaces
import {IERC20} from "@oz/token/ERC20/IERC20.sol";

// Internal Interfaces
import {
    IProposalFactory,
    IProposal,
    IModule
} from "src/factories/IProposalFactory.sol";
import {IAuthorizer, IPaymentProcessor} from "src/proposal/IProposal.sol";
import {IModuleFactory} from "src/factories/IModuleFactory.sol";

/**
 * @title Proposal Factory
 *
 * @dev An immutable factory for deploying proposals.
 *
 * @author byterocket
 */
contract ProposalFactory is IProposalFactory {
    //--------------------------------------------------------------------------
    // Immutables

    /// @inheritdoc IProposalFactory
    address public immutable override target;

    /// @inheritdoc IProposalFactory
    address public immutable override moduleFactory;

    //--------------------------------------------------------------------------
    // Storage

    /// @dev Maps the id to the proposals
    mapping(uint => address) private _proposals;

    /// @dev The counter of the current proposal id.
    /// @dev Starts counting from 1.
    uint private _proposalIdCounter;

    //--------------------------------------------------------------------------------
    // Modifier

    /// @notice Modifier to guarantee that the given id is valid
    modifier validProposalId(uint id) {
        if (id > _proposalIdCounter) {
            revert ProposalFactory__InvalidId();
        }
        _;
    }

    //--------------------------------------------------------------------------
    // Constructor

    constructor(address target_, address moduleFactory_) {
        target = target_;
        moduleFactory = moduleFactory_;
    }

    //--------------------------------------------------------------------------
    // Public Mutating Functions

    /// @inheritdoc IProposalFactory
    function createProposal(
        ProposalConfig memory proposalConfig,
        ModuleConfig memory authorizerConfig,
        ModuleConfig memory paymentProcessorConfig,
        ModuleConfig[] memory moduleConfigs
    ) external returns (IProposal) {
        address clone = Clones.clone(target);

        //Map proposal clone
        _proposals[++_proposalIdCounter] = clone;

        // Deploy and cache {IAuthorizer} module.
        address authorizer = IModuleFactory(moduleFactory).createModule(
            authorizerConfig.metadata,
            IProposal(clone),
            authorizerConfig.configdata
        );

        // Deploy and cache {IPaymentProcessor} module.
        address paymentProcessor = IModuleFactory(moduleFactory).createModule(
            paymentProcessorConfig.metadata,
            IProposal(clone),
            paymentProcessorConfig.configdata
        );

        // Deploy and cache optional modules.
        uint modulesLen = moduleConfigs.length;
        address[] memory modules = new address[](modulesLen);
        for (uint i; i < modulesLen; ++i) {
            modules[i] = IModuleFactory(moduleFactory).createModule(
                moduleConfigs[i].metadata,
                IProposal(clone),
                moduleConfigs[i].configdata
            );
        }

        // Initialize proposal.
        IProposal(clone).init(
            _proposalIdCounter,
            proposalConfig.owner,
            proposalConfig.token,
            modules,
            IAuthorizer(authorizer),
            IPaymentProcessor(paymentProcessor)
        );

        return IProposal(clone);
    }

    /// @inheritdoc IProposalFactory
    function getProposalByID(uint id)
        external
        view
        validProposalId(id)
        returns (address)
    {
        return _proposals[id];
    }

    function getProposalIDCounter() external view returns (uint) {
        return _proposalIdCounter;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (proxy/Clones.sol)

pragma solidity ^0.8.0;

/**
 * @dev https://eips.ethereum.org/EIPS/eip-1167[EIP 1167] is a standard for
 * deploying minimal proxy contracts, also known as "clones".
 *
 * > To simply and cheaply clone contract functionality in an immutable way, this standard specifies
 * > a minimal bytecode implementation that delegates all calls to a known, fixed address.
 *
 * The library includes functions to deploy a proxy using either `create` (traditional deployment) or `create2`
 * (salted deterministic deployment). It also includes functions to predict the addresses of clones deployed using the
 * deterministic method.
 *
 * _Available since v3.4._
 */
library Clones {
    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create opcode, which should never revert.
     */
    function clone(address implementation) internal returns (address instance) {
        /// @solidity memory-safe-assembly
        assembly {
            // Cleans the upper 96 bits of the `implementation` word, then packs the first 3 bytes
            // of the `implementation` address with the bytecode before the address.
            mstore(0x00, or(shr(0xe8, shl(0x60, implementation)), 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000))
            // Packs the remaining 17 bytes of `implementation` with the bytecode after the address.
            mstore(0x20, or(shl(0x78, implementation), 0x5af43d82803e903d91602b57fd5bf3))
            instance := create(0, 0x09, 0x37)
        }
        require(instance != address(0), "ERC1167: create failed");
    }

    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create2 opcode and a `salt` to deterministically deploy
     * the clone. Using the same `implementation` and `salt` multiple time will revert, since
     * the clones cannot be deployed twice at the same address.
     */
    function cloneDeterministic(address implementation, bytes32 salt) internal returns (address instance) {
        /// @solidity memory-safe-assembly
        assembly {
            // Cleans the upper 96 bits of the `implementation` word, then packs the first 3 bytes
            // of the `implementation` address with the bytecode before the address.
            mstore(0x00, or(shr(0xe8, shl(0x60, implementation)), 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000))
            // Packs the remaining 17 bytes of `implementation` with the bytecode after the address.
            mstore(0x20, or(shl(0x78, implementation), 0x5af43d82803e903d91602b57fd5bf3))
            instance := create2(0, 0x09, 0x37, salt)
        }
        require(instance != address(0), "ERC1167: create2 failed");
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(
        address implementation,
        bytes32 salt,
        address deployer
    ) internal pure returns (address predicted) {
        /// @solidity memory-safe-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(add(ptr, 0x38), deployer)
            mstore(add(ptr, 0x24), 0x5af43d82803e903d91602b57fd5bf3ff)
            mstore(add(ptr, 0x14), implementation)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73)
            mstore(add(ptr, 0x58), salt)
            mstore(add(ptr, 0x78), keccak256(add(ptr, 0x0c), 0x37))
            predicted := keccak256(add(ptr, 0x43), 0x55)
        }
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(address implementation, bytes32 salt)
        internal
        view
        returns (address predicted)
    {
        return predictDeterministicAddress(implementation, salt, address(this));
    }
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

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity ^0.8.13;

// External Interfaces
import {IERC20} from "@oz/token/ERC20/IERC20.sol";

// Internal Interfaces
import {IModule, IProposal} from "src/modules/base/IModule.sol";

interface IProposalFactory {
    //--------------------------------------------------------------------------
    // Errors

    /// @notice Given id is invalid.
    error ProposalFactory__InvalidId();

    /// @notice The module's data arrays length mismatch.
    error ProposalFactory__ModuleDataLengthMismatch();

    //--------------------------------------------------------------------------
    // Structs

    struct ProposalConfig {
        address owner;
        IERC20 token;
    }

    struct ModuleConfig {
        IModule.Metadata metadata;
        bytes configdata;
    }

    //--------------------------------------------------------------------------
    // Functions

    /// @notice Creates a new proposal with caller being the proposal's owner.
    /// @param proposalConfig The proposal's config data.
    /// @param authorizerConfig The config data for the proposal's {IAuthorizer}
    ///                         instance.
    /// @param paymentProcessorConfig The config data for the proposal's
    ///                               {IPaymentProcessor} instance.
    /// @param moduleConfigs Variable length set of optional module's config
    ///                      data.
    function createProposal(
        ProposalConfig memory proposalConfig,
        ModuleConfig memory authorizerConfig,
        ModuleConfig memory paymentProcessorConfig,
        ModuleConfig[] memory moduleConfigs
    ) external returns (IProposal);

    /// @notice Returns the {IProposal} target implementation address.
    function target() external view returns (address);

    /// @notice Returns the {IModuleFactory} implementation address.
    function moduleFactory() external view returns (address);

    /// @notice Returns the {IProposal} address that corresponds to the given id.
    /// @param id The requested proposal's id.
    function getProposalByID(uint id) external view returns (address);

    /// @notice Returns the counter of the current proposal id
    function getProposalIDCounter() external view returns (uint);
}

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity ^0.8.13;

// External Interfaces
import {IERC20} from "@oz/token/ERC20/IERC20.sol";

// Internal Interfaces
import {IModuleManager} from "src/proposal/base/IModuleManager.sol";
import {IFundingManager} from "src/proposal/base/IFundingManager.sol";
import {IAuthorizer} from "src/modules/IAuthorizer.sol";
import {IPaymentProcessor} from "src/modules/IPaymentProcessor.sol";

interface IProposal is IModuleManager, IFundingManager {
    //--------------------------------------------------------------------------
    // Errors

    /// @notice Function is only callable by authorized caller.
    error Proposal__CallerNotAuthorized();

    /// @notice Execution of transaction failed.
    error Proposal__ExecuteTxFailed();

    //--------------------------------------------------------------------------
    // Functions

    /// @notice Initialization function.
    function init(
        uint proposalId,
        address owner,
        IERC20 token,
        address[] calldata modules,
        IAuthorizer authorizer,
        IPaymentProcessor paymentProcessor
    ) external;

    /// @notice Executes a call on target `target` with call data `data`.
    /// @dev Only callable by authorized caller.
    /// @param target The address to call.
    /// @param data The call data.
    /// @return The return data of the call.
    function executeTx(address target, bytes memory data)
        external
        returns (bytes memory);

    /// @notice Returns the proposal's id.
    /// @dev Unique id set by the {ProposalFactory} during initialization.
    function proposalId() external view returns (uint);

    /// @notice The {IAuthorizer} implementation used to authorize addresses.
    function authorizer() external view returns (IAuthorizer);

    /// @notice The {IPaymentProcessor} implementation used to process module
    ///         payments.
    function paymentProcessor() external view returns (IPaymentProcessor);

    /// @notice The proposal's {IERC20} token accepted for fundings and used
    ///         for payments.
    function token() external view returns (IERC20);

    /// @notice The proposal's non-rebasing receipt token.
    function receiptToken() external view returns (IERC20);

    /// @notice The version of the proposal instance.
    function version() external pure returns (string memory);

    function owner() external view returns (address);

    function manager() external view returns (address);
}

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity ^0.8.13;

// External Interfaces
import {IBeacon} from "@oz/proxy/beacon/IBeacon.sol";

// Internal Interfaces
import {IModule, IProposal} from "src/modules/base/IModule.sol";

interface IModuleFactory {
    //--------------------------------------------------------------------------
    // Errors

    /// @notice Given metadata invalid.
    error ModuleFactory__InvalidMetadata();

    /// @notice Given beacon invalid.
    error ModuleFactory__InvalidBeacon();

    /// @notice Given metadata unregistered.
    error ModuleFactory__UnregisteredMetadata();

    /// @notice Given metadata already registered.
    error ModuleFactory__MetadataAlreadyRegistered();

    //--------------------------------------------------------------------------
    // Events

    /// @notice Event emitted when new beacon registered for metadata.
    event MetadataRegistered(
        IModule.Metadata indexed metadata, IBeacon indexed beacon
    );

    /// @notice Event emitted when new module created for a proposal.
    event ModuleCreated(
        address indexed proposal, address indexed module, string moduleTitle
    );

    //--------------------------------------------------------------------------
    // Functions

    /// @notice Creates a module instance identified by given metadata.
    /// @param metadata The module's metadata.
    /// @param proposal The proposal's instance of the module.
    /// @param configdata The configdata of the module.
    function createModule(
        IModule.Metadata memory metadata,
        IProposal proposal,
        bytes memory configdata
    ) external returns (address);

    /// @notice Returns the {IBeacon} instance registered and the id for given
    ///         metadata.
    /// @param metadata The module's metadata.
    /// @return The module's {IBeacon} instance registered.
    /// @return The metadata's id.
    function getBeaconAndId(IModule.Metadata memory metadata)
        external
        view
        returns (IBeacon, bytes32);

    /// @notice Registers metadata `metadata` with {IBeacon} implementation
    ///         `beacon`.
    /// @dev Only callable by owner.
    /// @param metadata The module's metadata.
    /// @param beacon The module's {IBeacon} instance.
    function registerMetadata(IModule.Metadata memory metadata, IBeacon beacon)
        external;
}

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity ^0.8.13;

// Internal Interfaces
import {IProposal} from "src/proposal/IProposal.sol";

interface IModule {
    struct Metadata {
        uint majorVersion;
        uint minorVersion;
        string url;
        string title;
    }

    //--------------------------------------------------------------------------
    // Errors

    /// @notice Function is only callable by authorized caller.
    error Module__CallerNotAuthorized();

    /// @notice Function is only callable by the proposal.
    error Module__OnlyCallableByProposal();

    /// @notice Given proposal address invalid.
    error Module__InvalidProposalAddress();

    /// @notice Given metadata invalid.
    error Module__InvalidMetadata();

    /// @notice Proposal callback triggered failed.
    /// @param funcSig The signature of the function called.
    error Module_ProposalCallbackFailed(string funcSig);

    //--------------------------------------------------------------------------
    // Functions

    /// @notice The module's initializer function.
    /// @dev CAN be overriden by downstream contract.
    /// @dev MUST call `__Module_init()`.
    /// @param proposal The module's proposal instance.
    /// @param metadata The module's metadata.
    /// @param configdata Variable config data for specific module
    ///                   implementations.
    function init(
        IProposal proposal,
        Metadata memory metadata,
        bytes memory configdata
    ) external;

    /// @notice Returns the module's identifier.
    /// @dev The identifier is defined as the keccak256 hash of the module's
    ///      abi packed encoded major version, url and title.
    /// @return The module's identifier.
    function identifier() external view returns (bytes32);

    /// @notice Returns the module's version.
    /// @return The module's major version.
    /// @return The module's minor version.
    function version() external view returns (uint, uint);

    /// @notice Returns the module's URL.
    /// @return The module's URL.
    function url() external view returns (string memory);

    /// @notice Returns the module's title.
    /// @return The module's title.
    function title() external view returns (string memory);

    /// @notice Returns the module's {IProposal} proposal instance.
    /// @return The module's proposal.
    function proposal() external view returns (IProposal);

    /// @notice Pauses the module.
    /// @dev Only callable by authorized addresses.
    function pause() external;

    /// @notice Unpauses the module.
    /// @dev Only callable by authorized addresses.
    function unpause() external;
}

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity ^0.8.13;

interface IModuleManager {
    //--------------------------------------------------------------------------
    // Errors

    /// @notice Function is only callable by authorized address.
    error Proposal__ModuleManager__CallerNotAuthorized();

    /// @notice Function is only callable by modules.
    error Proposal__ModuleManager__OnlyCallableByModule();

    /// @notice Given module address invalid.
    error Proposal__ModuleManager__InvalidModuleAddress();

    /// @notice Given address is a module.
    error Proposal__ModuleManager__IsModule();

    /// @notice Given address is not a module.
    error Proposal__ModuleManager__IsNotModule();

    /// @notice The supplied modules are not consecutive.
    error Proposal__ModuleManager__ModulesNotConsecutive();

    /// @notice The Manager has reached the maximum amount of modules.
    error Proposal__ModuleManager__ModuleAmountOverLimits();

    //--------------------------------------------------------------------------
    // Events

    /// @notice Event emitted when module added.
    /// @param module The module's address.
    event ModuleAdded(address indexed module);

    /// @notice Event emitted when module removed.
    /// @param module The module's address.
    event ModuleRemoved(address indexed module);

    /// @notice Event emitted when account `account` is granted role `role` for
    ///         module `module`.
    /// @param module The module's address.
    /// @param role The access control role.
    /// @param account The account the role was granted to.
    event ModuleRoleGranted(
        address indexed module, bytes32 indexed role, address indexed account
    );

    /// @notice Event emitted when account `account` is revoked role `role` for
    ///         module `module`.
    /// @param module The module's address.
    /// @param role The access control role.
    /// @param account The account the role was revoked for.
    event ModuleRoleRevoked(
        address indexed module, bytes32 indexed role, address indexed account
    );

    //--------------------------------------------------------------------------
    // Functions

    /// @notice Executes a call to `to` with call data `data` either via call
    /// @dev Only callable by enabled modules.
    /// @param to The address to call.
    /// @param data The call data.
    /// @return Whether the call succeeded.
    /// @return The return data of the call.
    function executeTxFromModule(address to, bytes memory data)
        external
        returns (bool, bytes memory);

    /// @notice Adds address `module` as module.
    /// @dev Only callable by authorized address.
    /// @dev Fails if address invalid or address already added as module.
    /// @param module The module address to add.
    function addModule(address module) external;

    /// @notice Removes address `module` as module.
    /// @dev Only callable by authorized address.
    /// @dev Fails if address not added as module.
    /// @param module The module address to remove.
    function removeModule(address module) external;

    /// @notice Returns whether the address `module` is added as module.
    /// @param module The module to check.
    /// @return True if module added, false otherwise.
    function isModule(address module) external returns (bool);

    /// @notice Returns the list of all modules.
    /// @return List of all modules.
    function listModules() external view returns (address[] memory);

    /// @notice Returns the number of modules.
    function modulesSize() external view returns (uint8);

    /// @notice Grants role `role` to account `account` in caller's access
    ///         control context.
    /// @dev Only callable by enabled module.
    /// @param role The access control role.
    /// @param account The account to grant given role.
    function grantRole(bytes32 role, address account) external;

    /// @notice Revokes role `role` from account `account` in caller's access
    ///         control context.
    /// @dev Only callable by enabled module.
    /// @param role The access control role.
    /// @param account The account to revoke role for.
    function revokeRole(bytes32 role, address account) external;

    /// @notice Renounces the caller's role `role` in module's `module` access
    ///         control context.
    /// @param module The module in which's access control context the role
    ///               should be renounced.
    /// @param role The access control role.
    function renounceRole(address module, bytes32 role) external;

    /// @notice Returns whether the account `account` holds the role `role` in
    ///         the module's `module` access control context.
    /// @param module The module in which's access control context the role
    ///               is checked.
    /// @param role The access control role.
    /// @param account The account to check role for.
    /// @return True if account has role in module's access control context,
    ///         false otherwise.
    function hasRole(address module, bytes32 role, address account)
        external
        returns (bool);
}

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity ^0.8.13;

import {IRebasingERC20} from "src/proposal/token/IRebasingERC20.sol";

interface IFundingManager is IRebasingERC20 {
    //--------------------------------------------------------------------------
    // Errors

    /// @notice Function is only callable by authorized address.
    error Proposal__FundingManager__CannotSelfDeposit();

    /// @notice There is a cap on deposits.
    error Proposal__FundingManager__DepositCapReached();

    //--------------------------------------------------------------------------
    // Events

    /// @notice Event emitted when a deposit takes place.
    /// @param from The address depositing tokens.
    /// @param to The address that will receive the receipt tokens.
    /// @param amount The amount of tokens deposited.
    event Deposit(
        address indexed from, address indexed to, uint indexed amount
    );

    /// @notice Event emitted when a withdrawal takes place.
    /// @param from The address supplying the receipt tokens.
    /// @param to The address that will receive the underlying tokens.
    /// @param amount The amount of underlying tokens withdrawn.
    event Withdrawal(
        address indexed from, address indexed to, uint indexed amount
    );

    //--------------------------------------------------------------------------
    // Functions

    function deposit(uint amount) external;
    function depositFor(address to, uint amount) external;

    function withdraw(uint amount) external;
    function withdrawTo(address to, uint amount) external;
}

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity ^0.8.13;

interface IAuthorizer {
    function isAuthorized(address who) external view returns (bool);
}

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity ^0.8.13;

import {IERC20} from "@oz/token/ERC20/IERC20.sol";

import {IPaymentClient} from "src/modules/mixins/IPaymentClient.sol";

interface IPaymentProcessor {
    //--------------------------------------------------------------------------
    // Errors

    /// @notice invalid caller
    error Module__PaymentManager__OnlyCallableByModule();

    /// @notice a client can only execute on its own orders
    error Module__PaymentManager__CannotCallOnOtherClientsOrders();

    //--------------------------------------------------------------------------
    // Events

    /// @notice Emitted when a payment gets processed for execution.
    /// @param paymentClient The payment client that originated the order.
    /// @param recipient The address that will receive the payment.
    /// @param amount The amount of tokens the payment consists of.
    /// @param createdAt Timestamp at which the order was created.
    /// @param dueTo Timestamp at which the full amount should be payed out/claimable.
    event PaymentOrderProcessed(
        address indexed paymentClient,
        address indexed recipient,
        uint amount,
        uint createdAt,
        uint dueTo
    );

    /// @notice Emitted when an amount of ERC20 tokens gets sent out of the contract.
    /// @param recipient The address that will receive the payment.
    /// @param amount The amount of tokens the payment consists of.
    event TokensReleased(
        address indexed recipient, address indexed token, uint amount
    );

    //--------------------------------------------------------------------------
    // Functions

    /// @notice Processes all payments from an {IPaymentClient} instance.
    /// @dev It's up to the the implementation to keep up with what has been
    ///      paid out or not.
    /// @param client The {IPaymentClient} instance to process its to payments.
    function processPayments(IPaymentClient client) external;

    /// @notice Cancels all unfinished payments from an {IPaymentClient} instance.
    /// @dev It's up to the the implementation to keep up with what has been
    ///      paid out or not.
    /// @param client The {IPaymentClient} instance to process its to payments.
    function cancelRunningPayments(IPaymentClient client) external;

    /// @notice Returns the IERC20 token the payment processor can process.
    function token() external view returns (IERC20);
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

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.13;

import "./IERC20Metadata.sol";

/**
 * @title Rebasing ERC20 Interface
 *
 * @dev Interface definition for Rebasing ERC20 tokens which have an "elastic"
 *      external balance and "fixed" internal balance.
 *      Each user's external balance is represented as a product of a "scalar"
 *      and the user's internal balance.
 *
 *      In regular time intervals the rebase operation updates the scalar,
 *      which increases or decreases all user balances proportionally.
 *
 *      The standard ERC20 methods are denomintaed in the elastic balance.
 *
 * @author Buttonwood Foundation
 */
interface IRebasingERC20 is IERC20Metadata {
    /// @notice Returns the fixed balance of the specified address.
    /// @param who The address to query.
    function scaledBalanceOf(address who) external view returns (uint);

    /// @notice Returns the total fixed supply.
    function scaledTotalSupply() external view returns (uint);

    /// @notice Transfer all of the sender's balance to a specified address.
    /// @param to The address to transfer to.
    /// @return True on success, false otherwise.
    function transferAll(address to) external returns (bool);

    /// @notice Transfer all balance tokens from one address to another.
    /// @param from The address to send tokens from.
    /// @param to The address to transfer to.
    function transferAllFrom(address from, address to)
        external
        returns (bool);

    /// @notice Triggers the next rebase, if applicable.
    function rebase() external;

    /// @notice Event emitted when the balance scalar is updated.
    /// @param epoch The number of rebases since inception.
    /// @param newScalar The new scalar.
    event Rebase(uint indexed epoch, uint newScalar);
}

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity ^0.8.13;

// Internal Interfaces
import {IPaymentProcessor} from "src/modules/IPaymentProcessor.sol";

interface IPaymentClient {
    struct PaymentOrder {
        /// @dev The recipient of the payment.
        address recipient;
        /// @dev The amount of tokens to pay.
        uint amount;
        /// @dev Timestamp at which the order got created.
        uint createdAt;
        /// @dev Timestamp at which the payment SHOULD be fulfilled.
        uint dueTo;
    }

    //--------------------------------------------------------------------------
    // Errors

    /// @notice Function is only callable by authorized address.
    error Module__PaymentClient__CallerNotAuthorized();

    /// @notice ERC20 token transfer failed.
    error Module__PaymentClient__TokenTransferFailed();

    /// @notice Given recipient invalid.
    error Module__PaymentClient__InvalidRecipient();

    /// @notice Given amount invalid.
    error Module__PaymentClient__InvalidAmount();

    /// @notice Given dueTo invalid.
    error Module__PaymentClient__InvalidDueTo();

    /// @notice Given arrays' length mismatch.
    error Module__PaymentClient__ArrayLengthMismatch();

    //--------------------------------------------------------------------------
    // Events

    /// @notice Added a payment order.
    /// @param recipient The address that will receive the payment.
    /// @param amount The amount of tokens the payment consists of.
    event PaymentOrderAdded(address indexed recipient, uint amount);

    //--------------------------------------------------------------------------
    // Functions

    /// @notice Returns the list of outstanding payment orders.
    function paymentOrders() external view returns (PaymentOrder[] memory);

    /// @notice Returns the total outstanding token payment amount.
    function outstandingTokenAmount() external view returns (uint);

    /// @notice Collects outstanding payment orders.
    /// @dev Marks the orders as completed for the client.
    ///      The responsibility to fulfill the orders are now in the caller's
    ///      hand!
    /// @return list of payment orders
    /// @return total amount of token to pay
    function collectPaymentOrders()
        external
        returns (PaymentOrder[] memory, uint);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)
pragma solidity ^0.8.13;

import "./IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 *
 * @author OpenZeppelin
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)
pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 *
 * @author OpenZeppelin
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender)
        external
        view
        returns (uint);

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
    function approve(address spender, uint amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint amount)
        external
        returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint value);
}