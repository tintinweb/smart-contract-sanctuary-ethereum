// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../../policy/Policy.sol";
import "../../policy/Policed.sol";
import "./Proposal.sol";

/** @title VoteCheckpointsUpgrade
 *
 * A proposal to upgrade the ECO and ECOxStaking contract.
 */
contract VoteCheckpointsUpgrade is Policy, Proposal {
    /** The address of the contract to denote as ECOxStaking.
     */
    address public immutable newStaking;

    /** The address of the updated ECO implementation contract
     */
    address public immutable newECOImpl;

    /** The address of the updating contract
     */
    address public immutable implementationUpdatingTarget;

    // The ID hash for the ECO contract
    bytes32 public constant ECOIdentifier = keccak256("ECO");

    // The ID hash for the ECOxStaking contract
    bytes32 public constant ECOxStakingIdentifier = keccak256("ECOxStaking");

    // The ID hash for the PolicyVotes contract
    // this is used for cluing in the use of setPolicy
    bytes32 public constant PolicyVotesIdentifier = keccak256("PolicyVotes");

    /** Instantiate a new proposal.
     *
     * @param _newStaking The address of the contract to mark as ECOxStaking.
     */
    constructor(
        address _newStaking,
        address _newECOImpl,
        address _implementationUpdatingTarget
    ) {
        newStaking = _newStaking;
        newECOImpl = _newECOImpl;
        implementationUpdatingTarget = _implementationUpdatingTarget;
    }

    /** The name of the proposal.
     */
    function name() public pure override returns (string memory) {
        return "Update to VoteCheckpoints";
    }

    /** A short description of the proposal.
     */
    function description() public pure override returns (string memory) {
        return
            "Updating ECOxStaking and ECO contracts to patch the voting snapshot and delegation during self-transfers";
    }

    /** A URL where further details can be found.
     */
    function url() public pure override returns (string memory) {
        return "none";
    }

    /** Enact the proposal.
     *
     * This is run in the storage context of the root policy contract.
     */
    function enacted(address) public override {
        // because ECOxStaking isn't proxied yet, we have to move over the identifier
        setPolicy(ECOxStakingIdentifier, newStaking, PolicyVotesIdentifier);

        address _ecoProxyAddr = policyFor(ECOIdentifier);

        Policed(_ecoProxyAddr).policyCommand(
            implementationUpdatingTarget,
            abi.encodeWithSignature("updateImplementation(address)", newECOImpl)
        );
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/introspection/IERC1820Registry.sol";
import "../proxy/ForwardTarget.sol";
import "./ERC1820Client.sol";

/** @title The policy contract that oversees other contracts
 *
 * Policy contracts provide a mechanism for building pluggable (after deploy)
 * governance systems for other contracts.
 */
contract Policy is ForwardTarget, ERC1820Client {
    mapping(bytes32 => bool) public setters;

    modifier onlySetter(bytes32 _identifier) {
        require(
            setters[_identifier],
            "Identifier hash is not authorized for this action"
        );

        require(
            ERC1820REGISTRY.getInterfaceImplementer(
                address(this),
                _identifier
            ) == msg.sender,
            "Caller is not the authorized address for identifier"
        );

        _;
    }

    /** Remove the specified role from the contract calling this function.
     * This is for cleanup only, so if another contract has taken the
     * role, this does nothing.
     *
     * @param _interfaceIdentifierHash The interface identifier to remove from
     *                                 the registry.
     */
    function removeSelf(bytes32 _interfaceIdentifierHash) external {
        address old = ERC1820REGISTRY.getInterfaceImplementer(
            address(this),
            _interfaceIdentifierHash
        );

        if (old == msg.sender) {
            ERC1820REGISTRY.setInterfaceImplementer(
                address(this),
                _interfaceIdentifierHash,
                address(0)
            );
        }
    }

    /** Find the policy contract for a particular identifier.
     *
     * @param _interfaceIdentifierHash The hash of the interface identifier
     *                                 look up.
     */
    function policyFor(bytes32 _interfaceIdentifierHash)
        public
        view
        returns (address)
    {
        return
            ERC1820REGISTRY.getInterfaceImplementer(
                address(this),
                _interfaceIdentifierHash
            );
    }

    /** Set the policy label for a contract
     *
     * @param _key The label to apply to the contract.
     *
     * @param _implementer The contract to assume the label.
     */
    function setPolicy(
        bytes32 _key,
        address _implementer,
        bytes32 _authKey
    ) public onlySetter(_authKey) {
        ERC1820REGISTRY.setInterfaceImplementer(
            address(this),
            _key,
            _implementer
        );
    }

    /** Enact the code of one of the governance contracts.
     *
     * @param _delegate The contract code to delegate execution to.
     */
    function internalCommand(address _delegate, bytes32 _authKey)
        public
        onlySetter(_authKey)
    {
        // solhint-disable-next-line avoid-low-level-calls
        (bool _success, ) = _delegate.delegatecall(
            abi.encodeWithSignature("enacted(address)", _delegate)
        );
        require(_success, "Command failed during delegatecall");
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/introspection/IERC1820Implementer.sol";
import "../proxy/ForwardTarget.sol";
import "./Policy.sol";

/** @title Policed Contracts
 *
 * A policed contract is any contract managed by a policy.
 */
abstract contract Policed is ForwardTarget, IERC1820Implementer, ERC1820Client {
    bytes32 internal constant ERC1820_ACCEPT_MAGIC =
        keccak256("ERC1820_ACCEPT_MAGIC");

    /** The address of the root policy instance overseeing this instance.
     *
     * This address can be used for ERC1820 lookup of other components, ERC1820
     * lookup of role policies, and interaction with the policy hierarchy.
     */
    Policy public immutable policy;

    /** Restrict method access to the root policy instance only.
     */
    modifier onlyPolicy() {
        require(
            msg.sender == address(policy),
            "Only the policy contract may call this method"
        );
        _;
    }

    constructor(Policy _policy) {
        require(
            address(_policy) != address(0),
            "Unrecoverable: do not set the policy as the zero address"
        );
        policy = _policy;
        ERC1820REGISTRY.setManager(address(this), address(_policy));
    }

    /** ERC1820 permissioning interface
     *
     * @param _addr The address of the contract this might act on behalf of.
     */
    function canImplementInterfaceForAddress(bytes32, address _addr)
        external
        view
        virtual
        override
        returns (bytes32)
    {
        require(
            _addr == address(policy),
            "This contract only implements interfaces for the policy contract"
        );
        return ERC1820_ACCEPT_MAGIC;
    }

    /** Initialize the contract (replaces constructor)
     *
     * Policed contracts are often the targets of proxies, and therefore need a
     * mechanism to initialize internal state when adopted by a new proxy. This
     * replaces the constructor.
     *
     * @param _self The address of the original contract deployment (as opposed
     *              to the address of the proxy contract, which takes the place
     *              of `this`).
     */
    function initialize(address _self)
        public
        virtual
        override
        onlyConstruction
    {
        super.initialize(_self);
        ERC1820REGISTRY.setManager(address(this), address(policy));
    }

    /** Execute code as indicated by the managing policy contract
     *
     * Governance allows the managing policy contract to execute arbitrary code in this
     * contract's context by allowing it to specify an implementation address and
     * some message data, and then using delegatecall to execute the code at the
     * implementation address, passing in the message data, all within the protocol's
     * address space.
     *
     * @param _delegate The address of the contract to delegate execution to.
     * @param _data The call message/data to execute on.
     */
    function policyCommand(address _delegate, bytes memory _data)
        public
        onlyPolicy
    {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            /* Call the address indicated by _delegate passing the data in _data
             * as the call message using delegatecall. This allows the calling
             * of arbitrary functions on _delegate (by encoding the call message
             * into _data) in the context of the current contract's storage.
             */
            let result := delegatecall(
                gas(),
                _delegate,
                add(_data, 0x20),
                mload(_data),
                0,
                0
            )
            /* Collect up the return data from delegatecall and prepare it for
             * returning to the caller of policyCommand.
             */
            let size := returndatasize()
            returndatacopy(0x0, 0, size)
            /* If the delegated call reverted then revert here too. Otherwise
             * forward the return data prepared above.
             */
            switch result
            case 0 {
                revert(0x0, size)
            }
            default {
                return(0x0, size)
            }
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/** @title Proposal
 * Interface specification for proposals. Any proposal submitted in the
 * policy decision process must implement this interface.
 */
interface Proposal {
    /** The name of the proposal.
     *
     * This should be relatively unique and descriptive.
     */
    function name() external view returns (string memory);

    /** A longer description of what this proposal achieves.
     */
    function description() external view returns (string memory);

    /** A URL where voters can go to see the case in favour of this proposal,
     * and learn more about it.
     */
    function url() external view returns (string memory);

    /** Called to enact the proposal.
     *
     * This will be called from the root policy contract using delegatecall,
     * with the direct proposal address passed in as _self so that storage
     * data can be accessed if needed.
     *
     * @param _self The address of the proposal contract.
     */
    function enacted(address _self) external;
}

/* -*- c-basic-offset: 4 -*- */
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/* solhint-disable no-inline-assembly */

/** @title Target for ForwardProxy and EcoInitializable */
abstract contract ForwardTarget {
    // Must match definition in ForwardProxy
    // keccak256("com.eco.ForwardProxy.target")
    uint256 private constant IMPLEMENTATION_SLOT =
        0xf86c915dad5894faca0dfa067c58fdf4307406d255ed0a65db394f82b77f53d4;

    modifier onlyConstruction() {
        require(
            implementation() == address(0),
            "Can only be called during initialization"
        );
        _;
    }

    constructor() {
        setImplementation(address(this));
    }

    /** @notice Storage initialization of cloned contract
     *
     * This is used to initialize the storage of the forwarded contract, and
     * should (typically) copy or repeat any work that would normally be
     * done in the constructor of the proxied contract.
     *
     * Implementations of ForwardTarget should override this function,
     * and chain to super.initialize(_self).
     *
     * @param _self The address of the original contract instance (the one being
     *              forwarded to).
     */
    function initialize(address _self) public virtual onlyConstruction {
        address _implAddress = address(ForwardTarget(_self).implementation());
        require(
            _implAddress != address(0),
            "initialization failure: nothing to implement"
        );
        setImplementation(_implAddress);
    }

    /** Get the address of the proxy target contract.
     */
    function implementation() public view returns (address _impl) {
        assembly {
            _impl := sload(IMPLEMENTATION_SLOT)
        }
    }

    /** @notice Set new implementation */
    function setImplementation(address _impl) internal {
        require(implementation() != _impl, "Implementation already matching");
        assembly {
            sstore(IMPLEMENTATION_SLOT, _impl)
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/introspection/IERC1820Registry.sol";

/** @title Utilities for interfacing with ERC1820
 */
abstract contract ERC1820Client {
    IERC1820Registry internal constant ERC1820REGISTRY =
        IERC1820Registry(0x1820a4B7618BdE71Dce8cdc73aAB6C95905faD24);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (utils/introspection/IERC1820Registry.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the global ERC1820 Registry, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1820[EIP]. Accounts may register
 * implementers for interfaces in this registry, as well as query support.
 *
 * Implementers may be shared by multiple accounts, and can also implement more
 * than a single interface for each account. Contracts can implement interfaces
 * for themselves, but externally-owned accounts (EOA) must delegate this to a
 * contract.
 *
 * {IERC165} interfaces can also be queried via the registry.
 *
 * For an in-depth explanation and source code analysis, see the EIP text.
 */
interface IERC1820Registry {
    event InterfaceImplementerSet(address indexed account, bytes32 indexed interfaceHash, address indexed implementer);

    event ManagerChanged(address indexed account, address indexed newManager);

    /**
     * @dev Sets `newManager` as the manager for `account`. A manager of an
     * account is able to set interface implementers for it.
     *
     * By default, each account is its own manager. Passing a value of `0x0` in
     * `newManager` will reset the manager to this initial state.
     *
     * Emits a {ManagerChanged} event.
     *
     * Requirements:
     *
     * - the caller must be the current manager for `account`.
     */
    function setManager(address account, address newManager) external;

    /**
     * @dev Returns the manager for `account`.
     *
     * See {setManager}.
     */
    function getManager(address account) external view returns (address);

    /**
     * @dev Sets the `implementer` contract as ``account``'s implementer for
     * `interfaceHash`.
     *
     * `account` being the zero address is an alias for the caller's address.
     * The zero address can also be used in `implementer` to remove an old one.
     *
     * See {interfaceHash} to learn how these are created.
     *
     * Emits an {InterfaceImplementerSet} event.
     *
     * Requirements:
     *
     * - the caller must be the current manager for `account`.
     * - `interfaceHash` must not be an {IERC165} interface id (i.e. it must not
     * end in 28 zeroes).
     * - `implementer` must implement {IERC1820Implementer} and return true when
     * queried for support, unless `implementer` is the caller. See
     * {IERC1820Implementer-canImplementInterfaceForAddress}.
     */
    function setInterfaceImplementer(
        address account,
        bytes32 _interfaceHash,
        address implementer
    ) external;

    /**
     * @dev Returns the implementer of `interfaceHash` for `account`. If no such
     * implementer is registered, returns the zero address.
     *
     * If `interfaceHash` is an {IERC165} interface id (i.e. it ends with 28
     * zeroes), `account` will be queried for support of it.
     *
     * `account` being the zero address is an alias for the caller's address.
     */
    function getInterfaceImplementer(address account, bytes32 _interfaceHash) external view returns (address);

    /**
     * @dev Returns the interface hash for an `interfaceName`, as defined in the
     * corresponding
     * https://eips.ethereum.org/EIPS/eip-1820#interface-name[section of the EIP].
     */
    function interfaceHash(string calldata interfaceName) external pure returns (bytes32);

    /**
     * @notice Updates the cache with whether the contract implements an ERC165 interface or not.
     * @param account Address of the contract for which to update the cache.
     * @param interfaceId ERC165 interface for which to update the cache.
     */
    function updateERC165Cache(address account, bytes4 interfaceId) external;

    /**
     * @notice Checks whether a contract implements an ERC165 interface or not.
     * If the result is not cached a direct lookup on the contract address is performed.
     * If the result is not cached or the cached value is out-of-date, the cache MUST be updated manually by calling
     * {updateERC165Cache} with the contract address.
     * @param account Address of the contract to check.
     * @param interfaceId ERC165 interface to check.
     * @return True if `account` implements `interfaceId`, false otherwise.
     */
    function implementsERC165Interface(address account, bytes4 interfaceId) external view returns (bool);

    /**
     * @notice Checks whether a contract implements an ERC165 interface or not without using nor updating the cache.
     * @param account Address of the contract to check.
     * @param interfaceId ERC165 interface to check.
     * @return True if `account` implements `interfaceId`, false otherwise.
     */
    function implementsERC165InterfaceNoCache(address account, bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC1820Implementer.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface for an ERC1820 implementer, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1820#interface-implementation-erc1820implementerinterface[EIP].
 * Used by contracts that will be registered as implementers in the
 * {IERC1820Registry}.
 */
interface IERC1820Implementer {
    /**
     * @dev Returns a special value (`ERC1820_ACCEPT_MAGIC`) if this contract
     * implements `interfaceHash` for `account`.
     *
     * See {IERC1820Registry-setInterfaceImplementer}.
     */
    function canImplementInterfaceForAddress(bytes32 interfaceHash, address account) external view returns (bytes32);
}