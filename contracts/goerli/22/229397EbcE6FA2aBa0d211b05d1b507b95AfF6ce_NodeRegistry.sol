// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {IAccountRegistry} from "./AccountRegistry.sol";

struct NodeData {
    /// @notice The type of node.
    uint16 nodeType;
    /// @notice The account that owns this node. Node owner can update node
    /// metadata or create logical child nodes.
    uint80 owner;
    /// @notice The logical parent of this node.
    uint80 parent;
    /// @notice If set, the owner of the access node can also update this node's
    /// metadata or create child nodes.
    uint80 accessNode;
}

/// @notice A registry of ownable nodes and their metadata
contract NodeRegistry {
    // ---
    // Events
    // ---

    /// @notice A new node was created
    event NodeCreated(
        uint80 indexed id,
        uint16 indexed nodeType,
        uint80 indexed owner,
        uint80 parent,
        uint80 accessNode
    );

    /// @notice Announce the metadata string for a node.
    event NodeMetadata(uint80 indexed id, string metadata);

    /// @notice A node manage was authorized or unauthorized.
    event AuthorizedManagerSet(
        uint80 indexed id,
        address indexed manager,
        bool isAuthorized
    );

    // ---
    // Errors
    // ---

    /// @notice An unauthorized agent attempted to modify or create a child node
    error NotAuthorizedForNode();

    // ---
    // Storage
    // ---

    /// @notice Total number of registered nodes.
    uint80 public totalNodeCount;

    /// @notice Mapping from node IDs to node data.
    mapping(uint80 => NodeData) public nodes;

    /// @notice The account registry.
    IAccountRegistry public immutable accounts;

    /// @notice Flags for allowed external addresses that can create new child
    /// nodes or manage existing nodes.
    mapping(uint80 => mapping(address => bool)) public authorizedNodeManagers;

    // ---
    // Constructor
    // ---

    constructor(IAccountRegistry _accounts) {
        accounts = _accounts;
    }

    // ---
    // Node management
    // ---

    /// @notice Create a new node. Child nodes can specify an access parent that
    /// will be used to determine ownership, and a separate logical parent that
    /// expresses the entity relationship.
    /// Child nodes can only be created if msg.sender is an authorized manager of
    /// the node
    function createNode(
        uint16 nodeType,
        uint80 owner,
        uint80 parent,
        uint80 accessNode,
        string memory metadata
    ) public returns (uint80 id) {
        if (parent == 0) {
            // if this is a root node...
            // owner must be msg.sender and have an account
            if (owner == 0 || accounts.resolveId(msg.sender) != owner) {
                revert NotAuthorizedForNode();
            }
        } else if (!isAuthorizedAddressForNode(parent, msg.sender)) {
            // else if this is a child node, ensure msg.sender is authorized to manage
            // the parent node
            revert NotAuthorizedForNode();
        }

        // if an access node is specified, ensure it actually exists
        if (accessNode != 0 && nodes[accessNode].nodeType == 0) {
            revert NotAuthorizedForNode();
        }

        id = ++totalNodeCount;
        nodes[id] = NodeData({
            nodeType: nodeType,
            owner: owner,
            parent: parent,
            accessNode: accessNode
        });
        emit NodeCreated(id, nodeType, owner, parent, accessNode);

        if (bytes(metadata).length > 0) {
            emit NodeMetadata(id, metadata);
        }
    }

    /// @notice Update the metadata for a node. Msg.sender must be authorized for
    /// the node
    function broadcastMetadata(uint80 id, string memory metadata) external {
        if (!isAuthorizedAddressForNode(id, msg.sender)) {
            revert NotAuthorizedForNode();
        }

        emit NodeMetadata(id, metadata);
    }

    /// @notice Set the authorized manager for a node. Msg.sender must have an
    /// account and be authorized to manage the node
    function setAuthorizedNodeManager(
        uint80 node,
        address manager,
        bool isAuthorized
    ) external {
        // only allow authorized accounts (and not external managers) to set new
        // authorized managers. This is done to prevent external contracts from
        // adding additional contracts as managers, forcing a node owner to
        // explictly set a manager
        if (!isAuthorizedAccountForNode(node, accounts.resolveId(msg.sender))) {
            revert NotAuthorizedForNode();
        }

        authorizedNodeManagers[node][manager] = isAuthorized;
        emit AuthorizedManagerSet(node, manager, isAuthorized);
    }

    // ---
    // Node views
    // ---

    /// @notice Determine if an account is authorized to manage a node. Account
    /// must own the node, or own the access node of this node
    function isAuthorizedAccountForNode(uint80 node, uint80 account)
        public
        view
        returns (bool isAuthorized)
    {
        NodeData memory mnode = nodes[node];

        if (account == 0 || mnode.nodeType == 0) {
            // ensure invalid account or invalid node is always false
            isAuthorized = false;
        } else if (mnode.owner == account) {
            // if this node is directly owned by the account, then it's authorized
            isAuthorized = true;
        } else if (nodes[mnode.accessNode].owner == account) {
            // if this node's access node is owned by the account, then its authorized
            isAuthorized = true;
        }
    }

    /// @notice Determine if an address is authorized to manage a node. If the
    /// address's account is authorized to manage a node, or the address has been approved to
    /// manage the node's access node, then they are allowed
    function isAuthorizedAddressForNode(uint80 node, address subject)
        public
        view
        returns (bool isAuthorized)
    {
        NodeData memory mnode = nodes[node];
        uint80 account = accounts.resolveId(subject);

        if (mnode.owner == account && account != 0) {
            // if this node is directly owned by the resolved account, then it's
            // authorized
            isAuthorized = true;
        } else if (nodes[mnode.accessNode].owner == account && account != 0) {
            // else, if this node's access node is owned by the resolved
            // account, then its authorized
            isAuthorized = true;
        } else if (authorizedNodeManagers[mnode.accessNode][subject]) {
            // else, if the address is authorized to manage the access node,
            // then it's authorized
            isAuthorized = true;
        } else {
            // else, if the address is authorized to manage the node, then it's
            // authorized
            isAuthorized = authorizedNodeManagers[node][subject];
        }
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

/// @notice Data stored per-account.
struct AccountData {
    uint80 id;
    address recovery;
}

/// @notice Interface for the account registry.
interface IAccountRegistry {
    function resolveId(address subject) external view returns (uint80 id);
}

/// @notice Account registry that allows an address to create/claim their account
contract AccountRegistry is IAccountRegistry {
    // ---
    // Events
    // ---

    /// @notice A new account was created
    event AccountCreated(
        uint80 indexed id,
        address indexed subject,
        address recovery
    );

    // ---
    // Errors
    // ---

    /// @notice An account was created for an address that already has one.
    error AccountAlreadyExists(address subject);

    // ---
    // Storage
    // ---

    /// @notice Total number of created accounts
    uint80 public totalAccountCount;

    /// @notice Mapping of addresses to account IDs.
    mapping(address => AccountData) public accounts;

    // ---
    // Account functionality
    // ---

    /// @notice Create a new account for an address.
    function createAccount(address subject, address recovery)
        external
        returns (uint80 id)
    {
        if (accounts[subject].id != 0) revert AccountAlreadyExists(subject);
        id = ++totalAccountCount;
        accounts[subject] = AccountData({id: id, recovery: recovery});
        emit AccountCreated(id, subject, recovery);
    }

    // ---
    // Views
    // ---

    /// @notice Determine the account ID for an address.
    function resolveId(address subject) external view returns (uint80 id) {
        id = accounts[subject].id;
    }
}