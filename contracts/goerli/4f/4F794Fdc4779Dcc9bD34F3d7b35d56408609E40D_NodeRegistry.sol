// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {AccountRegistry} from "./AccountRegistry.sol";
import {INodeRegistry, NodeData} from "./interfaces/INodeRegistry.sol";

/// @notice The node registry maintains a tree of ownable nodes that are used to
/// catalog logical entities and manage access control in the Metalabel
/// universe.
/// - Nodes anchor metadata for logical entites
/// - Nodes express a logical hierarchy between entities
/// - Nodes have access control semantics that can be used to determine
///     authorization around various actions
contract NodeRegistry is INodeRegistry {
    // ---
    // Events
    // ---

    /// @notice A new node was created.
    event NodeCreated(
        uint64 indexed id,
        uint16 indexed nodeType,
        uint64 indexed owner,
        uint64 parent,
        uint64 groupNode,
        string metadata
    );

    /// @notice A node's owner was updated.
    event NodeOwnerSet(uint64 indexed id, uint64 indexed owner);

    /// @notice A node's group node was updated.
    event NodeGroupNodeSet(uint64 indexed id, uint64 indexed groupNode);

    /// @notice An arbitrary event was been emitted from a node.
    event NodeBroadcast(uint64 indexed id, string topic, string message);

    /// @notice A node controller was authorized or unauthorized.
    event NodeControllerSet(
        uint64 indexed id,
        address indexed controller,
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
    uint64 public totalNodeCount;

    /// @notice Mapping from node IDs to node data.
    mapping(uint64 => NodeData) public nodes;

    /// @notice The account registry.
    AccountRegistry public immutable accounts;

    /// @notice Flags for allowed external addresses that can create new child
    /// nodes or manage existing nodes.
    /// - nodeId => address => isAuthorized
    mapping(uint64 => mapping(address => bool)) public controllers;

    // ---
    // Constructor
    // ---

    constructor(AccountRegistry _accounts) {
        accounts = _accounts;
    }

    // ---
    // Node creation
    // ---

    /// @notice Create a new node. Child nodes can specify an group node that
    /// will be used to determine ownership, and a separate logical parent that
    /// expresses the entity relationship.  Child nodes can only be created if
    /// msg.sender is an authorized manager of the parent node.
    function createNode(
        uint16 nodeType,
        uint64 owner,
        uint64 parent,
        uint64 groupNode,
        string memory metadata
    ) public returns (uint64 id) {
        // if this is a root node, msg.sender must have an account and be set as
        // node owner.
        if (parent == 0) {
            if (owner == 0 || accounts.resolveId(msg.sender) != owner) {
                revert NotAuthorizedForNode();
            }
        }
        // Else if this is a child node, ensure msg.sender is authorized to manage
        // the parent node.
        else if (!isAuthorizedAddressForNode(parent, msg.sender)) {
            revert NotAuthorizedForNode();
        }

        // If an group node is specified, ensure it actually exists.
        if (groupNode != 0 && nodes[groupNode].nodeType == 0) {
            revert NotAuthorizedForNode();
        }

        // Create the node.
        id = ++totalNodeCount;
        nodes[id] = NodeData({
            nodeType: nodeType,
            owner: owner,
            parent: parent,
            groupNode: groupNode
        });
        emit NodeCreated(id, nodeType, owner, parent, groupNode, metadata);
    }

    // ---
    // Node management
    // ---

    /// @notice Set node's owner. Can only be called by the existing node owner
    // if already set. If it's not yet set, it can be called by the group node
    function setNodeOwner(uint64 id, uint64 newOwner) external {
        NodeData memory mnode = nodes[id];
        uint64 accountId = accounts.resolveId(msg.sender);

        // If this node has an owner, msg.sender must be current owner
        if (mnode.owner != 0 && mnode.owner != accountId) {
            revert NotAuthorizedForNode();
        }
        // Else if this node has no owner, node must have a group node and
        // msg.sender must be group node owner
        else if (
            mnode.owner == 0 &&
            (mnode.groupNode == 0 || nodes[mnode.groupNode].owner != accountId)
        ) {
            revert NotAuthorizedForNode();
        }

        nodes[id].owner = newOwner;
        emit NodeOwnerSet(id, newOwner);
    }

    /// @notice Modify a node's group node. Msg.sender must be authorized to
    /// manage the node.
    function setNodeGroupNode(uint64 id, uint64 groupNode) external {
        if (!isAuthorizedAddressForNode(id, msg.sender)) {
            revert NotAuthorizedForNode();
        }

        nodes[id].groupNode = groupNode;
        emit NodeGroupNodeSet(id, groupNode);
    }

    /// @notice Broadcast an arbitrary event from a node. Msg.sender must be
    /// authorized to manage the node
    function broadcast(
        uint64 id,
        string calldata topic,
        string calldata message
    ) external {
        if (!isAuthorizedAddressForNode(id, msg.sender)) {
            revert NotAuthorizedForNode();
        }

        emit NodeBroadcast(id, topic, message);
    }

    /// @notice Set or remove an address as a node controller. Msg.sender must
    /// be the node owner or group node owner, controllers cannot add additional
    /// controllers
    function setController(
        uint64 node,
        address controller,
        bool isAuthorized
    ) external {
        // using isAuthorizedAddressForNode here instead of
        // isAuthorizedAddressForNode, we dont want controllers to be able to
        // add additional controllers
        if (!isAuthorizedAccountForNode(node, accounts.resolveId(msg.sender))) {
            revert NotAuthorizedForNode();
        }

        controllers[node][controller] = isAuthorized;
        emit NodeControllerSet(node, controller, isAuthorized);
    }

    // ---
    // Node views
    // ---

    /// @notice Resolve node owner account.
    function ownerOf(uint64 id) external view returns (uint64) {
        return nodes[id].owner;
    }

    /// @notice Resolve node group node.
    function groupNodeOf(uint64 id) external view returns (uint64) {
        return nodes[id].groupNode;
    }

    /// @notice Determine if an account is authorized to manage a node. Account
    /// must own the node, or own the group node of this node
    function isAuthorizedAccountForNode(uint64 node, uint64 account)
        public
        view
        returns (bool isAuthorized)
    {
        NodeData memory mnode = nodes[node];

        // Ensure invalid account or invalid node is always NOT authorized.
        if (account == 0 || mnode.nodeType == 0) {
            isAuthorized = false;
        }
        // If this node is directly owned by the account, then it's authorized.
        else if (mnode.owner == account) {
            isAuthorized = true;
        }
        // If this node's group node is owned by the account, then its
        // authorized. Not checking if groupNode or groupNode owner is zero,
        // since we know account is non-zero
        else if (nodes[mnode.groupNode].owner == account) {
            isAuthorized = true;
        }

        // Otherwise, not authorized.
    }

    /// @notice Determine if an address is authorized to manage a node. If the
    /// address's account is authorized to manage a node, or the address has been approved to
    /// manage the node's group node, then they are allowed
    function isAuthorizedAddressForNode(uint64 node, address subject)
        public
        view
        returns (bool isAuthorized)
    {
        NodeData memory mnode = nodes[node];
        uint64 account = accounts.resolveId(subject);

        // If this node is directly owned by the resolved account, then it's
        // authorized.
        if (mnode.owner == account && account != 0) {
            isAuthorized = true;
        }
        // Else, if this node's group node is owned by the resolved
        // account, then it's authorized.
        else if (nodes[mnode.groupNode].owner == account && account != 0) {
            isAuthorized = true;
        }
        // Else, if the address is authorized to manage the node, then it's
        // authorized
        else if (controllers[node][subject]) {
            isAuthorized = true;
        }
        // Else, if the address is authorized to manage the group node,
        // then it's authorized
        else if (controllers[mnode.groupNode][subject]) {
            isAuthorized = true;
        }

        // Otherise, not authorized.
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Owned} from "@metalabel/solmate/src/auth/Owned.sol";
import {IAccountRegistry, AccountData} from "./interfaces/IAccountRegistry.sol";

/// @notice The account registry manages mappings from an address to an account
/// ID.
/// - Accounts are identified by a uint64 ID
/// - Accounts are owned by an address
/// - Accounts can be recovered by a recovery address
/// - Accounts can broadcast arbitrary strings, keyed by a topic, as blockchain events
contract AccountRegistry is IAccountRegistry, Owned {
    // ---
    // Events
    // ---

    /// @notice A new account was created
    event AccountCreated(
        uint64 indexed id,
        address indexed subject,
        address recovery,
        string metadata
    );

    /// @notice Broadcast a message from an account
    event AccountBroadcast(uint64 indexed id, string topic, string message);

    /// @notice An account's address has changed
    event AccountTransfered(uint64 indexed id, address newOwner);

    /// @notice An account's recovery address has changed
    event AccountRecoverySet(uint64 indexed id, address newRecoveryAddress);

    /// @notice A new address has be authorized or un-authorized to issue accounts
    event AccountIssuerSet(address indexed issuer, bool authorized);

    // ---
    // Errors
    // ---

    /// @notice An account was created for an address that already has one.
    error AccountAlreadyExists();

    /// @notice Recovery address cannot be provided if msg.sender is not the
    /// account address
    error InvalidRegistration();

    /// @notice Recovery was attempted from an invalid address
    error InvalidRecovery();

    /// @notice No account exists for msg.sender
    error NoAccount();

    /// @notice Account issuance is not yet public and a non-issuer attempted to
    /// create an account.
    error NotAuthorizedAccountIssuer();

    // ---
    // Storage
    // ---

    /// @notice Total number of created accounts
    uint64 public totalAccountCount;

    /// @notice Mapping of addresses to account IDs.
    mapping(address => AccountData) public accounts;

    /// @notice Mapping from an address to a boolean indicating whether it is
    /// authorized to issue accounts.
    mapping(address => bool) public isAccountIssuer;

    // ---
    // Constructor
    // ---

    constructor(address _contractOwner) Owned(_contractOwner) {}

    // ---
    // Owner functionality
    // ---

    /// @notice Authorize or unauthorize an address to issue accounts
    function setAccountIssuer(address issuer, bool authorized)
        external
        onlyOwner
    {
        isAccountIssuer[issuer] = authorized;
        emit AccountIssuerSet(issuer, authorized);
    }

    // ---
    // Account creation functionality
    // ---

    /// @notice Permissionlessly create an account with no recovery address.
    /// msg.sender can be any address. Subject must not yet have an account
    function createAccount(address subject, string calldata metadata)
        external
        returns (uint64 id)
    {
        id = _createAccount(subject, address(0), metadata);
    }

    /// @notice Create a new account with a recovery address. Can only be called
    /// if subject is msg.sender
    function createAccountWithRecovery(
        address subject,
        address recovery,
        string calldata metadata
    ) external returns (uint64 id) {
        if (msg.sender != subject) revert InvalidRegistration();

        id = _createAccount(subject, recovery, metadata);
    }

    /// @notice Internal create logic
    function _createAccount(
        address subject,
        address recovery,
        string memory metadata
    ) internal returns (uint64 id) {
        if (accounts[subject].id != 0) revert AccountAlreadyExists();
        if (owner != address(0) && !isAccountIssuer[msg.sender]) {
            revert NotAuthorizedAccountIssuer();
        }

        id = ++totalAccountCount;
        accounts[subject] = AccountData({id: id, recovery: recovery});
        emit AccountCreated(id, subject, recovery, metadata);
    }

    // ---
    // Account functionality
    // ---

    /// @notice Broadcast a message as an account.
    function broadcast(string calldata topic, string calldata message)
        external
    {
        uint64 id = accounts[msg.sender].id;
        if (id == 0) revert NoAccount();

        emit AccountBroadcast(id, topic, message);
    }

    /// @notice Transfer the account to another address. Other address must not
    /// have an account, and msg.sender must currently own the account
    function transferAccount(address newOwner) external {
        AccountData memory maccount = accounts[msg.sender];
        if (maccount.id == 0) revert NoAccount();
        if (accounts[newOwner].id != 0) revert AccountAlreadyExists();

        accounts[newOwner] = maccount;
        delete accounts[msg.sender];
        emit AccountTransfered(maccount.id, newOwner);
    }

    /// @notice Transfer the account to another address as the recovery address.
    /// New address must not have an account, and msg.sender must be the
    /// account's recovery address
    function recoverAccount(address oldOwner, address newOwner) external {
        AccountData memory maccount = accounts[oldOwner];
        if (maccount.recovery != msg.sender) revert InvalidRecovery();
        if (accounts[newOwner].id != 0) revert AccountAlreadyExists();

        accounts[newOwner] = maccount;
        delete accounts[oldOwner];
        emit AccountTransfered(maccount.id, newOwner);
    }

    /// @notice Set the recovery address for an account. msg.sender must be the
    /// account owner
    function setRecovery(address recovery) external {
        AccountData memory maccount = accounts[msg.sender];
        if (maccount.id == 0) revert NoAccount();

        accounts[msg.sender].recovery = recovery;
        emit AccountRecoverySet(maccount.id, recovery);
    }

    // ---
    // Views
    // ---

    /// @notice Get the account ID for an address.
    function resolveId(address subject) external view returns (uint64 id) {
        id = accounts[subject].id;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

/// @notice Data stored per node
struct NodeData {
    /// @notice The type of node.
    uint16 nodeType;
    /// @notice The account that owns this node. Node owner can update node
    /// metadata or create logical child nodes.
    uint64 owner;
    /// @notice The logical parent of this node.
    uint64 parent;
    /// @notice If set, the owner of the group node can also update this node's
    /// metadata or create child nodes.
    uint64 groupNode;
}

/// @notice The node registry maintains a tree of ownable nodes that are used to
/// catalog logical entities and manage access control in the Metalabel
/// universe.
interface INodeRegistry {
    /// @notice Determine if an address is authorized to manage a node. If the
    /// address's account is authorized to manage a node, or the address has
    /// been approved to manage the node's group node, then they are allowed.
    function isAuthorizedAddressForNode(uint64 node, address subject)
        external
        view
        returns (bool isAuthorized);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

/// @notice Data stored per account.
struct AccountData {
    uint64 id;
    address recovery;
}

/// @notice The account registry manages mappings from an address to an account
/// ID.
interface IAccountRegistry {
    /// @notice Permissionlessly create an account with no recovery address.
    /// msg.sender can be any address. Subject must not yet have an account
    function createAccount(address subject, string calldata metadata)
        external
        returns (uint64 id);

    /// @notice Get the account ID for an address.
    function resolveId(address subject) external view returns (uint64 id);
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Simple single owner authorization mixin.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/auth/Owned.sol)
abstract contract Owned {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event OwnershipTransferred(address indexed user, address indexed newOwner);

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

        emit OwnershipTransferred(address(0), _owner);
    }

    /*//////////////////////////////////////////////////////////////
                             OWNERSHIP LOGIC
    //////////////////////////////////////////////////////////////*/

    function transferOwnership(address newOwner) public virtual onlyOwner {
        owner = newOwner;

        emit OwnershipTransferred(msg.sender, newOwner);
    }
}