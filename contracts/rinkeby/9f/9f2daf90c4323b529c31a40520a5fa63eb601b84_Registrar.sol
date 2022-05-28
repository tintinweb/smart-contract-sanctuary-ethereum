// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.10;

import "ens-contracts/registry/ENS.sol";
import { Owned } from  "solmate/auth/Owned.sol";

import "./IAuthoriser.sol";
import { Utilities } from "./Utils.sol";

interface IRegistrar {
  function register (bytes32 node, string memory label, address owner, bytes[] memory additionalData) external;
  function valid (bytes32 node, string memory label) external view returns (bool);
  function available (bytes32 node, string memory label) external view returns (bool);

  function addRootNode (bytes32 node, IAuthoriser authoriser, IRulesEngine rules) external;
}

/// @title Me3 Subdomain Registrar
/// @author charchar.eth
/// @notice Provides third-party projects with a common subdomain registration function
/// @dev 0.1.0
contract Registrar is IRegistrar, Owned(msg.sender) {
  ENS private ens;

  address public me3Resolver;
  mapping(bytes32 => bool) public nodeEnabled;
  mapping(bytes32 => IAuthoriser) public nodeAuthorisers;
  mapping(bytes32 => IRulesEngine) public nodeRules;

  event Me3ResolverUpdated (address indexed resolverAddr);
  event ProjectStateChanged (bytes32 indexed node, bool enabled);

  modifier isAuthorised (bytes32 node, address user, bytes[] memory blob) {
    IAuthoriser authoriser = nodeAuthorisers[node];

    require(authoriser.canRegister(node, user, blob), "User is not authorised");
    _;
  }

  modifier registeredNode (bytes32 node) {
    require(nodeEnabled[node], "Node is not enabled");
    _;
  }

  constructor (ENS _registry, address _resolver) {
    ens = _registry;
    me3Resolver = _resolver;
  }

  /// @notice Add a new project to the directory
  /// @param node The project node that subdomains will be based on
  /// @param _authoriser The authorisation contract
  /// @param _rules The rules around availability, validity, and usage
  function addRootNode (bytes32 node, IAuthoriser _authoriser, IRulesEngine _rules) external onlyOwner {
    nodeAuthorisers[node] = _authoriser;
    nodeRules[node] = _rules;
    nodeEnabled[node] = true;
  }

  /// @notice Enable or disable a root node
  /// @param node The project node
  /// @param enabled True for enabled, false for disabled
  function setRootNodeState (bytes32 node, bool enabled) external onlyOwner {
    require(
      address(nodeAuthorisers[node]) != address(0x0)
        && address(nodeRules[node]) != address(0x0),
      "Project must be initialized");

    emit ProjectStateChanged(node, enabled);
    nodeEnabled[node] = enabled;
  }

  function updateMe3Resolver (address newResolver) external onlyOwner {
    require(newResolver != address(0x0), "Resolver must be a real contract");

    me3Resolver = newResolver;
    emit Me3ResolverUpdated(newResolver);
  }

  /// @notice Register a subdomain under node
  /// @param node The project node to use
  /// @param label The subdomain text, eg the 'hopeless' in hopeless.abc.eth
  /// @param owner Who will own the subdomain
  function register (bytes32 node, string memory label, address owner, bytes[] memory blob)
    public
    registeredNode(node)
    isAuthorised(node, msg.sender, blob)
  {
    require(valid(node, label), "Check with project for valid subdomain");
    // require(available(node, label), "Subdomain is not available");

    ens.setSubnodeRecord(node, Utilities.namehash(label), owner, me3Resolver, 86400);
  }

  /// @notice Check if a label is valid for a project
  /// @param node The project node
  /// @param label The subdomain label to validate
  /// @return bool True if the label is valid, according to the project rules, false otherwise
  function valid (bytes32 node, string memory label) public view returns (bool) {
    return nodeRules[node].isLabelValid(label);
  }

  function available (bytes32 node, string memory label) public view returns (bool) {
    // should check with node rules first
    // then check against registry
    return false;
  }
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

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.10;

interface IAuthoriser {
  // function forEditing(address, string memory) external view returns (bool);
  function canRegister(bytes32 node, address sender, bytes[] memory blob) external view returns (bool);
}

interface IRulesEngine {
  function isLabelValid (string memory) external view returns (bool);
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.10;

library Utilities {
  function namehash (string memory node) internal pure returns(bytes32) {
    return keccak256(bytes(node));
  }
}