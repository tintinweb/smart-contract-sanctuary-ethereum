// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.10;

import "ens-contracts/registry/ENS.sol";
import {Owned} from "solmate/auth/Owned.sol";

import {IAuthoriser} from "./IAuthoriser.sol";
import {IRulesEngine} from "./IRulesEngine.sol";
import {Utilities} from "./Utils.sol";

/// @title Subdomain Registrar Interface
/// @author charchar.eth
/// @notice Define the minimum methods needed for a subdomain registrar
interface IRegistrar {
    /// @notice Register a subdomain under node
    /// @param node The project node to use
    /// @param label The subdomain text, eg the 'hopeless' in hopeless.abc.eth
    /// @param authData Additional data to help the authoriser authorise
    function register(
        bytes32 node,
        string memory label,
        bytes memory authData
    ) external;

    /// @notice Check if a label is valid for a project
    /// @param node The project node
    /// @param label The subdomain label to validate
    /// @return True if the label is valid, according to the project rules, false otherwise
    function valid(bytes32 node, string memory label)
        external
        view
        returns (bool);

    /// @notice Register a project as a subdomain provider
    /// @param node The fully qualified, namehashed ENS name
    /// @param authoriser The contract that will perform authorisation
    /// @param rules The contract that will provide rules and validation
    /// @param enable Allow project auth and rules to run
    function setProjectNode(
        bytes32 node,
        IAuthoriser authoriser,
        IRulesEngine rules,
        bool enable
    ) external;
}

/// @title me3 Subdomain Registrar
/// @author charchar.eth
/// @notice Provides third-party projects with a common subdomain registration function
/// @dev 0.1.0
contract Registrar is IRegistrar, Owned(msg.sender) {
    ENS private ens;

    /// @notice Address of the default resolver used when registering a subdomain
    address public fallbackResolver;

    /// @notice Lookup enabled/disabled state by project node
    mapping(bytes32 => bool) public nodeEnabled;

    /// @notice Lookup authoriser contract by project node
    mapping(bytes32 => IAuthoriser) public nodeAuthorisers;

    /// @notice Lookup rules contract by project node
    mapping(bytes32 => IRulesEngine) public nodeRules;

    /// @notice The default resolver has changed
    /// @param resolverAddr The new address of the resolver
    event FallbackResolverUpdated(address indexed resolverAddr);

    /// @notice A project has been enabled/disabled
    /// @param node The fully qualified, namehashed ENS name for the project
    /// @param authoriser The address of the authorising contract
    /// @param rules The address of the rules engine contract
    /// @param enabled True if the project is now enabled, false if now disabled
    event ProjectStateChanged(
        bytes32 indexed node,
        address authoriser,
        address rules,
        bool enabled
    );

    /// @notice A subnode has been registered
    /// @param node The fully qualified, namehashed ENS name for the project
    /// @param label The registered label as keccack256
    /// @param owner The registered owner
    /// @param registrant The address that requested registration
    event SubnodeRegistered(
        bytes32 indexed node,
        bytes32 indexed label,
        address owner,
        address registrant
    );

    modifier isAuthorised(
        bytes32 node,
        address user,
        bytes memory authData
    ) {
        IAuthoriser authoriser = nodeAuthorisers[node];

        require(authoriser.canRegister(node, user, authData), "User is not authorised");
        _;
    }

    modifier registeredNode(bytes32 node) {
        require(nodeEnabled[node], "Node is not enabled");
        _;
    }

    constructor(ENS _registry, address _resolver) {
        ens = _registry;
        fallbackResolver = _resolver;
    }

    /// @notice Add a new project to the directory
    /// @param node The project node that subdomains will be based on
    /// @param authoriser The authorisation contract
    /// @param rules The rules around availability, validity, and usage
    /// @param enable Turn the project on or off
    function setProjectNode(
        bytes32 node,
        IAuthoriser authoriser,
        IRulesEngine rules,
        bool enable
    ) external onlyOwner {
        emit ProjectStateChanged(node, address(authoriser), address(rules), enable);

        nodeAuthorisers[node] = authoriser;
        nodeRules[node] = rules;
        nodeEnabled[node] = enable;
    }

    /// @notice Change the default resolver to a new contract
    /// @param newResolver Address of the new resolver contract
    function changeFallbackResolver(address newResolver) external onlyOwner {
        require(newResolver != address(0x0), "Resolver must be a real contract");

        fallbackResolver = newResolver;
        emit FallbackResolverUpdated(newResolver);
    }

    /// @inheritdoc IRegistrar
    function register(
        bytes32 node,
        string memory label,
        bytes memory authData
    ) external registeredNode(node) isAuthorised(node, msg.sender, authData) {
        require(valid(node, label), "Check with project for valid subdomain requirements");
        require(available(node, label), "Label must be available to register");

        bytes32 hashedLabel = Utilities.labelhash(label);
        address owner = nodeRules[node].subnodeOwner(msg.sender);
        address resolver = nodeRules[node].profileResolver(node, label, msg.sender);
        if (resolver == address(0x0)) {
          resolver = fallbackResolver;
        }

        emit SubnodeRegistered(node, hashedLabel, owner, msg.sender);
        ens.setSubnodeRecord(node, hashedLabel, owner, resolver, 86400);
    }

    /// @inheritdoc IRegistrar
    function valid(bytes32 node, string memory label)
        public
        view
        registeredNode(node)
        returns (bool)
    {
        return nodeRules[node].isLabelValid(node, label);
    }

    function available(bytes32 node, string memory label)
        internal
        view
        returns (bool)
    {
        bytes32 fullNode = Utilities.namehash(node, Utilities.labelhash(label));
        return ens.owner(fullNode) == address(0x0);
    }

    /**
      No fallback or receive functions are implemented on purpose
      */
}

pragma solidity >=0.8.4;

interface ENS {

    // Logged when the owner of a node assigns a new owner to a subnode.
    event NewOwner(bytes32 indexed node, bytes32 indexed label, address owner);

    // Logged when the owner of a node transfers ownership to a new account.
    event Transfer(bytes32 indexed node, address owner);

    // Logged when the resolver for a node changes.
    event NewResolver(bytes32 indexed node, address resolver);

    // Logged when the TTL of a node changes
    event NewTTL(bytes32 indexed node, uint64 ttl);

    // Logged when an operator is added or removed.
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    function setRecord(bytes32 node, address owner, address resolver, uint64 ttl) external virtual;
    function setSubnodeRecord(bytes32 node, bytes32 label, address owner, address resolver, uint64 ttl) external virtual;
    function setSubnodeOwner(bytes32 node, bytes32 label, address owner) external virtual returns(bytes32);
    function setResolver(bytes32 node, address resolver) external virtual;
    function setOwner(bytes32 node, address owner) external virtual;
    function setTTL(bytes32 node, uint64 ttl) external virtual;
    function setApprovalForAll(address operator, bool approved) external virtual;
    function owner(bytes32 node) external virtual view returns (address);
    function resolver(bytes32 node) external virtual view returns (address);
    function ttl(bytes32 node) external virtual view returns (uint64);
    function recordExists(bytes32 node) external virtual view returns (bool);
    function isApprovedForAll(address owner, address operator) external virtual view returns (bool);
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Simple single owner authorization mixin.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/auth/Owned.sol)
abstract contract Owned {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event OwnerUpdated(address indexed user, address indexed newOwner);

    /*//////////////////////////////////////////////////////////////
                            OWNERSHIP STORAGE
    //////////////////////////////////////////////////////////////*/

    address public owner;

    modifier onlyOwner() virtual {
        require(msg.sender == owner, "UNAUTHORIZED");

        _;
    }

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(address _owner) {
        owner = _owner;

        emit OwnerUpdated(address(0), _owner);
    }

    /*//////////////////////////////////////////////////////////////
                             OWNERSHIP LOGIC
    //////////////////////////////////////////////////////////////*/

    function setOwner(address newOwner) public virtual onlyOwner {
        owner = newOwner;

        emit OwnerUpdated(msg.sender, newOwner);
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.10;

/// @title Authoriser interface
/// @author charchar.eth
/// @notice Defines the API which a valid Authorising contract must meet
/// @custom:docs-example iauthoriser.md
interface IAuthoriser {
    /// @notice Determine if a node can be registered by a sender
    /// @dev See example for authData packing
    /// @param node Fully qualified, namehashed ENS name
    /// @param registrant Address of the user who is attempting to register
    /// @param authData Additional data used for authorising the request
    /// @return True if the sender can register, false otherwise
    /// @custom:docs-example authdata.md
    function canRegister(
        bytes32 node,
        address registrant,
        bytes memory authData
    ) external view returns (bool);

    /// @notice Determine if a node can be edited by sender
    /// @dev See example for authData packing
    /// @param node Fully qualified, namehashed ENS name
    /// @param registrant Address of the user who is attempting to register
    /// @param authData Additional data used for authorising the request
    /// @return True if the sender can edit, false otherwise
    /// @custom:docs-example authdata.md
    function canEdit(
        bytes32 node,
        address registrant,
        bytes memory authData
    ) external view returns (bool);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.10;

/// @title Rules Engine Interface
/// @author charchar.eth
/// @notice Functions that a RulesEngine contract should support
interface IRulesEngine {
    /// @notice Determine if a label meets a projects minimum requirements
    /// @param node Fully qualified, namehashed ENS name
    /// @param label The 'best' in 'best.bob.eth'
    /// @return True if label is valid, false otherwise
    function isLabelValid(bytes32 node, string memory label)
        external
        view
        returns (bool);

    /// @notice Determine who should own the subnode
    /// @param registrant The address that is registereing a subnode
    /// @return The address that should own the subnode
    function subnodeOwner(address registrant) external view returns (address);

    /// @notice Determine the resolver contract to use for project profiles
    /// @dev If this returns address(0x0), the Registrar will use its default resolver
    /// @param node Fully qualified, namehashed ENS name
    /// @param label The 'best' in 'best.bob.eth'
    /// @param registrant The address that is registereing a subnode
    /// @return The address of the resolver
    function profileResolver(
        bytes32 node,
        string memory label,
        address registrant
    ) external view returns (address);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.10;

/// @title Utilities
/// @author charchar.eth
/// @notice Central location for shared functions in me3
library Utilities {
    /// @notice Hash a label for ENS use
    /// @param label The 'oops' in 'oops.bob.eth', or the 'bob' in 'bob.eth'
    /// @return Hashed label
    function labelhash(string memory label) internal pure returns (bytes32) {
        return keccak256(bytes(label));
    }

    /// @notice Create a namehash, the combination of a namehashed node and a hashed label
    /// @param node Fully qualified, namehashed ENS name ('bob.eth')
    /// @param label The 'oops' in 'oops.bob.eth', or the 'bob' in 'bob.eth'
    /// @return Hashed ENS name
    function namehash(bytes32 node, bytes32 label)
        internal
        pure
        returns (bytes32)
    {
        return keccak256(abi.encodePacked(node, label));
    }
}