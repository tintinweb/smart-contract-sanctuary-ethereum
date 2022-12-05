// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

/// @notice Data stored per node.
struct NodeData {
    uint16 nodeType;
    uint64 owner;
    uint64 parent;
    uint64 groupNode;
    // 6 bytes remaining
}

/// @notice The node registry maintains a tree of ownable nodes that are used to
/// catalog logical entities and manage access control in the Metalabel
/// universe.
interface INodeRegistry {
    /// @notice Create a new node. Child nodes can specify an group node that
    /// will be used to determine ownership, and a separate logical parent that
    /// expresses the entity relationship.  Child nodes can only be created if
    /// msg.sender is an authorized manager of the parent node.
    function createNode(
        uint16 nodeType,
        uint64 owner,
        uint64 parent,
        uint64 groupNode,
        address[] memory initialControllers,
        string memory metadata
    ) external returns (uint64 id);

    /// @notice Determine if an address is authorized to manage a node.
    /// A node can be managed by an address if any of the following conditions
    /// are true:
    ///   - The address's account is the owner of the node
    ///   - The address's account is the owner of the node's group node
    ///   - The address is an authorized controller of the node
    ///   - The address is an authorized controller of the node's group node
    function isAuthorizedAddressForNode(uint64 node, address subject)
        external
        view
        returns (bool isAuthorized);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {INodeRegistry} from "./INodeRegistry.sol";

/// @notice Factory that launches on-chain resources, keyed by an address, that
/// are intended to be cataloged within the Metalabel universe.
interface IResourceFactory {
    /// @notice Broadcast an arbitrary message associated with the resource.
    event ResourceBroadcast(
        address indexed resource,
        string topic,
        string message
    );

    /// @notice Return the node registry contract address.
    function nodeRegistry() external view returns (INodeRegistry);

    /// @notice Return the control node ID for a given resource.
    function controlNode(address resource)
        external
        view
        returns (uint64 nodeId);

    /// @notice Return any stored broadcasts for a given resource and topic.
    function messageStorage(address resource, string calldata topic)
        external
        view
        returns (string memory message);

    /// @notice Emit an on-chain message for a given resource. msg.sender must
    /// be authorized to manage the resource's control node.
    function broadcast(
        address resource,
        string calldata topic,
        string calldata message
    ) external;

    /// @notice Emit an on-chain message and write to contract storage for a
    /// given resource. msg.sender must be authorized to manage the resource's
    /// control node.
    function broadcastAndStore(
        address resource,
        string calldata topic,
        string calldata message
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

/*

███╗   ███╗███████╗████████╗ █████╗ ██╗      █████╗ ██████╗ ███████╗██╗
████╗ ████║██╔════╝╚══██╔══╝██╔══██╗██║     ██╔══██╗██╔══██╗██╔════╝██║
██╔████╔██║█████╗     ██║   ███████║██║     ███████║██████╔╝█████╗  ██║
██║╚██╔╝██║██╔══╝     ██║   ██╔══██║██║     ██╔══██║██╔══██╗██╔══╝  ██║
██║ ╚═╝ ██║███████╗   ██║   ██║  ██║███████╗██║  ██║██████╔╝███████╗███████╗
╚═╝     ╚═╝╚══════╝   ╚═╝   ╚═╝  ╚═╝╚══════╝╚═╝  ╚═╝╚═════╝ ╚══════╝╚══════╝


Deployed by Metalabel with 💖 as a permanent application on the Ethereum blockchain.

Metalabel is a growing universe of tools, knowledge, and resources for
metalabels and cultural collectives.

Our purpose is to establish the metalabel as key infrastructure for creative
collectives and to inspire a new culture of creative collaboration and mutual
support.

OUR SQUAD

Anna Bulbrook (Curator)
Austin Robey (Community)
Brandon Valosek (Engineer)
Ilya Yudanov (Designer)
Lauren Dorman (Engineer)
Rob Kalin (Board)
Yancey Strickler (Director)

https://metalabel.xyz

*/

import {IResourceFactory} from "./interfaces/IResourceFactory.sol";
import {INodeRegistry} from "./interfaces/INodeRegistry.sol";

/// @notice Minimal abstract implementation of a resource factory that deploys
/// on-chain resources that can be cataloged on the Metalabel protocol.
abstract contract ResourceFactory is IResourceFactory {
    // ---
    // Errors
    // ---

    /// @notice Unauthorized msg.sender attempted to interact with this collection
    error NotAuthorized();

    // ---
    // Storage
    // ---

    /// @inheritdoc IResourceFactory
    mapping(address => mapping(string => string)) public messageStorage;

    /// @inheritdoc IResourceFactory
    INodeRegistry public immutable nodeRegistry;

    /// @inheritdoc IResourceFactory
    mapping(address => uint64) public controlNode;

    // ---
    // Constructor
    // ---

    constructor(INodeRegistry _nodeRegistry) {
        nodeRegistry = _nodeRegistry;
    }

    // ---
    // Modifiers
    // ---

    /// @dev Make a function only callable by a msg.sender that is authorized
    /// to manage the control node of this resource
    modifier onlyAuthorized(address resource) {
        if (
            !nodeRegistry.isAuthorizedAddressForNode(
                controlNode[resource],
                msg.sender
            )
        ) {
            revert NotAuthorized();
        }
        _;
    }

    // ---
    // Permissioned functionality
    // ---

    /// @inheritdoc IResourceFactory
    function broadcast(
        address waterfall,
        string calldata topic,
        string calldata message
    ) external onlyAuthorized(waterfall) {
        emit ResourceBroadcast(waterfall, topic, message);
    }

    /// @inheritdoc IResourceFactory
    function broadcastAndStore(
        address waterfall,
        string calldata topic,
        string calldata message
    ) external onlyAuthorized(waterfall) {
        messageStorage[waterfall][topic] = message;
        emit ResourceBroadcast(waterfall, topic, message);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

/*

███╗   ███╗███████╗████████╗ █████╗ ██╗      █████╗ ██████╗ ███████╗██╗
████╗ ████║██╔════╝╚══██╔══╝██╔══██╗██║     ██╔══██╗██╔══██╗██╔════╝██║
██╔████╔██║█████╗     ██║   ███████║██║     ███████║██████╔╝█████╗  ██║
██║╚██╔╝██║██╔══╝     ██║   ██╔══██║██║     ██╔══██║██╔══██╗██╔══╝  ██║
██║ ╚═╝ ██║███████╗   ██║   ██║  ██║███████╗██║  ██║██████╔╝███████╗███████╗
╚═╝     ╚═╝╚══════╝   ╚═╝   ╚═╝  ╚═╝╚══════╝╚═╝  ╚═╝╚═════╝ ╚══════╝╚══════╝


Deployed by Metalabel with 💖 as a permanent application on the Ethereum blockchain.

Metalabel is a growing universe of tools, knowledge, and resources for
metalabels and cultural collectives.

Our purpose is to establish the metalabel as key infrastructure for creative
collectives and to inspire a new culture of creative collaboration and mutual
support.

OUR SQUAD

Anna Bulbrook (Curator)
Austin Robey (Community)
Brandon Valosek (Engineer)
Ilya Yudanov (Designer)
Lauren Dorman (Engineer)
Rob Kalin (Board)
Yancey Strickler (Director)

https://metalabel.xyz

*/

import {INodeRegistry} from "./interfaces/INodeRegistry.sol";
import {ResourceFactory} from "./ResourceFactory.sol";

/// @dev Minimal needed interface from 0xSplits
/// https://github.com/0xSplits/splits-contracts/blob/main/contracts/interfaces/ISplitMain.sol
interface ISplitMain {
    function createSplit(
        address[] calldata accounts,
        uint32[] calldata percentAllocations,
        uint32 distributorFee,
        address controller
    ) external returns (address);
}

/// @notice Deploy splits from 0xSplits that can be cataloged as resources in the
/// Metalabel protocol.
contract SplitFactory is ResourceFactory {
    // ---
    // Events
    // ---

    /// @notice A new split was deployed.
    event SplitCreated(
        address indexed split,
        uint64 nodeId,
        address[] accounts,
        uint32[] percentAllocations,
        string metadata
    );

    // ---
    // Storage
    // ---

    /// @notice The 0xSplit factory contract.
    ISplitMain public immutable splits;

    // ---
    // Constructor
    // ---

    constructor(INodeRegistry _nodeRegistry, ISplitMain _splits)
        ResourceFactory(_nodeRegistry)
    {
        splits = _splits;
    }

    // ---
    // Public funcionality
    // ---

    /// @notice Launch a new split
    function createSplit(
        address[] calldata accounts,
        uint32[] calldata percentAllocations,
        uint32 distributorFee,
        uint64 controlNodeId,
        string calldata metadata
    ) external returns (address split) {
        // Ensure msg.sender is authorized to manage the control node.
        if (
            !nodeRegistry.isAuthorizedAddressForNode(controlNodeId, msg.sender)
        ) {
            revert NotAuthorized();
        }

        // Deploy and store the split.
        split = splits.createSplit(
            accounts,
            percentAllocations,
            distributorFee,
            address(0)
        );
        controlNode[split] = controlNodeId;
        emit SplitCreated(
            split,
            controlNodeId,
            accounts,
            percentAllocations,
            metadata
        );
    }
}