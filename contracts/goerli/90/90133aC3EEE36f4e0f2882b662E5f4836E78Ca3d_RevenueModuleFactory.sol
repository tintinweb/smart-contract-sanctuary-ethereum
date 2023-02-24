// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

enum NodeType {
    INVALID_NODE_TYPE,
    METALABEL,
    RELEASE
}

/// @notice Data stored per node.
struct NodeData {
    NodeType nodeType;
    uint64 owner;
    uint64 parent;
    uint64 groupNode;
    // 7 bytes remaining
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
        NodeType nodeType,
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

    /// @notice Resolve node owner account.
    function ownerOf(uint64 id) external view returns (uint64);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

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

    /// @notice Emit an on-chain message for a given resource. msg.sender must
    /// be authorized to manage the resource's control node.
    function broadcast(
        address resource,
        string calldata topic,
        string calldata message
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

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

    /// @notice Unauthorized msg.sender attempted to interact with this
    /// collection
    error NotAuthorized();

    // ---
    // Storage
    // ---

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

    /// @dev Make a function only callable by a msg.sender that is authorized to
    /// manage the control node of this resource
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
        address resource,
        string calldata topic,
        string calldata message
    ) external onlyAuthorized(resource) {
        emit ResourceBroadcast(resource, topic, message);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

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

/// @dev Minimal needed interface from 0xSplits
/// https://github.com/0xSplits/splits-waterfall/blob/master/src/WaterfallModuleFactory.sol
interface IWaterfallModuleFactory {
    function createWaterfallModule(
        address token,
        address nonWaterfallRecipient,
        address[] calldata recipients,
        uint256[] calldata thresholds
    ) external returns (address wm);
}

/// @notice Configuration data required when deploying a revenue module.
struct DeployRevenueModuleConfig {
    address token;
    address[] waterfallRecipients;
    uint256[] waterfallThresholds;
    address[] splitRecipients;
    uint32[] splitPercentAllocations;
    uint32 splitDistributorFee;
    uint64 controlNodeId;
    string metadata;
}

/// @notice Deploy a waterfall that flows into a split from 0xSplits that can be
/// cataloged as composite resource in the Metalabel protocol.
contract RevenueModuleFactory is ResourceFactory {
    // ---
    // Events
    // ---

    /// @notice A new revenue module was deployed.
    event RevenueModuleDeployed(
        address indexed waterfall,
        address indexed split,
        DeployRevenueModuleConfig config
    );

    // ---
    // Errors
    // ---

    /// @notice The provided configuration does not specify a split or waterfall
    error InvalidConfiguration();

    // ---
    // Storage
    // ---

    /// @notice The 0xSplit factory contract.
    ISplitMain public immutable splits;

    /// @notice The 0xSplit factory contract for waterfalls.
    IWaterfallModuleFactory public immutable waterfallFactory;

    // ---
    // Constructor
    // ---

    constructor(
        INodeRegistry _nodeRegistry,
        ISplitMain _splits,
        IWaterfallModuleFactory _waterfallFactory
    ) ResourceFactory(_nodeRegistry) {
        splits = _splits;
        waterfallFactory = _waterfallFactory;
    }

    // ---
    // Public functionality
    // ---

    /// @notice Deploy a waterfall, a split, or a waterfall + split combo. If
    /// waterfallRecipients or splitRecipients has a length of 0, the respective
    /// module will not be deployed. If both are deployed, the split will be the
    /// last recipient in the waterfall.
    function deployRevenueModule(DeployRevenueModuleConfig calldata config)
        external
        returns (address waterfall, address split)
    {
        bool isSplit = config.splitRecipients.length > 0;
        bool isWaterfall = config.waterfallRecipients.length > 0;

        if (!isSplit && !isWaterfall) {
            revert InvalidConfiguration();
        }

        // Ensure msg.sender is authorized to manage the control node. Splits
        // and waterfalls are immutable - the control node only determines
        // access control around resource broadcasts (eg, metadata updates).
        if (
            !nodeRegistry.isAuthorizedAddressForNode(
                config.controlNodeId,
                msg.sender
            )
        ) {
            revert NotAuthorized();
        }

        // Deploy the split first
        if (isSplit) {
            split = splits.createSplit(
                config.splitRecipients,
                config.splitPercentAllocations,
                config.splitDistributorFee,
                address(0) // No admin = immutable split
            );
        }

        // if no waterfall - we're done
        if (!isWaterfall) {
            // waterfall is zero address since it's never assigned
            return (split, waterfall);
        }

        address[] memory recipients = config.waterfallRecipients;

        // If we deployed a split first, create a new array that is one longer
        // than the waterfall recipients list and add the split as the last
        // element
        if (isSplit) {
            recipients = new address[](config.waterfallRecipients.length + 1);
            for (uint256 i = 0; i < config.waterfallRecipients.length; i++) {
                recipients[i] = config.waterfallRecipients[i];
            }
            recipients[recipients.length - 1] = split;
        }

        // Deploy the waterfall
        waterfall = waterfallFactory.createWaterfallModule(
            config.token,
            // Setting the non-waterfall recipient to the final tranche
            // recipient that gets all final overflow, if a split was also
            // deploy it will be the split, else it will be whoever the caller
            // set as the final waterfall recipient
            recipients[recipients.length - 1],
            recipients,
            config.waterfallThresholds
        );

        // Mark this "composite" resource by the waterfall if one was deployed
        // (since it comes first), otherwise use the split
        controlNode[waterfall != address(0) ? waterfall : split] = config
            .controlNodeId;

        emit RevenueModuleDeployed(waterfall, split, config);
    }
}