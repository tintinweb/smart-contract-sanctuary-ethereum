// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Clones} from "@openzeppelin/contracts/proxy/Clones.sol";
import {Catalog, INodeRegistry} from "./Catalog.sol";

contract CatalogFactory {
    // ---
    // Errors
    // ---

    /// @notice An unauthorized address attempted to create a catalog.
    error NotAuthorized();

    // ---
    // Events
    // ---

    /// @notice A new catalog was deployed
    event CatalogCreated(address indexed catalog, string name, string symbol);

    // ---
    // Storage
    // ---

    /// @notice Reference to the catalog collection implementation that will be cloned.
    Catalog public immutable implementation;

    /// @notice Reference to the node registry of the protocol.
    INodeRegistry public immutable nodeRegistry;

    // ---
    // Constructor
    // ---

    constructor(INodeRegistry _nodeRegsitry, Catalog _implementation) {
        implementation = _implementation;
        nodeRegistry = _nodeRegsitry;
    }

    // ---
    // Public funcionality
    // ---

    /// @notice Deploy a new catalog
    function createCatalog(
        string calldata name,
        string calldata symbol,
        uint80 controlNode,
        address owner
    ) external returns (Catalog catalog) {
        if (!nodeRegistry.isAuthorizedAddressForNode(controlNode, msg.sender)) {
            /// msg.sender must be authorized to manage the control node of the
            /// catalog
            revert NotAuthorized();
        }

        catalog = Catalog(Clones.clone(address(implementation)));
        catalog.init(name, symbol, controlNode, nodeRegistry, owner);
        emit CatalogCreated(address(catalog), name, symbol);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {INodeRegistry} from "./NodeRegistry.sol";
import {ERC721} from "@metalabel/solmate/src/tokens/ERC721.sol";
import {IERC165} from "@openzeppelin/contracts/interfaces/IERC165.sol";
import {IERC721} from "@openzeppelin/contracts/interfaces/IERC721.sol";
import {IERC2981} from "@openzeppelin/contracts/interfaces/IERC2981.sol";

/// @notice Interface a sequence engine must implement.
interface IEngine {
    function getTokenURI(address collection, uint256 tokenId)
        external
        view
        returns (string memory);

    function getRoyaltyInfo(
        address collection,
        uint256 tokenId,
        uint256 salePrice
    ) external view returns (address receiver, uint256 royaltyAmount);
}

struct SequenceData {
    uint80 dropId;
    IEngine engine;
}

contract Catalog is ERC721, IERC2981 {
    // ---
    // Errors
    // ---

    /// @notice The init function was called more than once.
    error AlreadyInitialized();

    /// @notice Invalid msg.sender for admin or engine function.
    error NotAuthorized();

    // ---
    // Events
    // ---

    /// @notice A new record was minted.
    event RecordCreated(
        uint256 indexed tokenId,
        uint16 indexed sequenceId,
        uint80 data,
        string etching
    );

    /// @notice A sequence has been set or updated.
    event SequenceConfigured(
        uint16 indexed sequenceId,
        uint80 indexed dropId,
        IEngine engine
    );

    /// @notice The control node of the catalog was updated.
    event ControlNodeSet(uint80 indexed controlNode);

    /// @notice The owner address of this catalog was updated.
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    // ---
    // Storage
    // ---

    /// @notice Total number of records minted in this catalog.
    uint256 public totalSupply;

    /// @notice The node used to determine control of this catalog. If an agent
    /// is authorized to manage the control node, it can manage this catalog.
    uint80 public controlNode;

    /// @notice Mostly for marketplace interop, can be set by owner of the
    /// control node.
    address public owner;

    /// @notice Node registry contract.
    INodeRegistry public nodeRegistry;

    /// @notice Information about each sequence
    mapping(uint16 => SequenceData) public sequences;

    /// @notice
    bool private initialized;

    // ---
    // Constructor
    // ---

    constructor() ERC721("Catalog", "CATALOG") {
        // constructor only called during deployment of the implementation, all
        // storage should be set up in init function which is called atomically
        // after clone deployment
        initialized = true;
    }

    // ---
    // Clone init
    // ---

    /// @notice Initialize contract state. Should be called immediately after clone deployment
    function init(
        string calldata _name,
        string calldata _symbol,
        uint80 _controlNode,
        INodeRegistry _nodeRegistry,
        address _owner
    ) external {
        if (initialized) revert AlreadyInitialized();

        name = _name;
        symbol = _symbol;
        controlNode = _controlNode;
        nodeRegistry = _nodeRegistry;
        owner = _owner;
        initialized = true;

        emit ControlNodeSet(controlNode);
        emit OwnershipTransferred(address(0), owner);
    }

    // ---
    // Admin functionality
    // ---

    modifier onlyAdmin() {
        if (!nodeRegistry.isAuthorizedAddressForNode(controlNode, msg.sender)) {
            revert NotAuthorized();
        }
        _;
    }

    /// @notice Change the owner address of this catalog.
    function setOwner(address _owner) external onlyAdmin {
        address previousOwner = owner;
        owner = _owner;
        emit OwnershipTransferred(previousOwner, _owner);
    }

    /// @notice Create or update the configuration for a sequence of records.
    function configureSequence(
        uint16 sequenceId,
        uint80 dropId,
        IEngine engine
    ) external onlyAdmin {
        if (!nodeRegistry.isAuthorizedAddressForNode(dropId, msg.sender)) {
            // The drop this sequence is associated with must be managaeable by
            // msg.sender
            revert NotAuthorized();
        }

        // TODO: call an init function on the engine, forwarding arbitrary bytes
        // calldata to set up any engine-side config needed for this sequence

        sequences[sequenceId] = SequenceData({dropId: dropId, engine: engine});
        emit SequenceConfigured(sequenceId, dropId, engine);
    }

    // ---
    // Engine functionality
    // ---

    /// @notice Mint a new record. Only callable by the sequence-specific engine
    function mintRecord(
        address to,
        uint16 sequenceId,
        uint80 data,
        string calldata etching
    ) external returns (uint256 tokenId) {
        if (sequences[sequenceId].engine != IEngine(msg.sender)) {
            // ensure that only the engine for this sequence can mint records
            revert NotAuthorized();
        }

        tokenId = ++totalSupply;
        _mint(to, tokenId, sequenceId, data);
        emit RecordCreated(tokenId, sequenceId, data, etching);
    }

    // ---
    // ERC721 functionality
    // ---

    /// @notice Resolve token URI from the engine powering the sequence.
    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        SequenceData memory sinfo = sequences[_tokenData[tokenId].sequenceId];
        return sinfo.engine.getTokenURI(address(this), tokenId);
    }

    // ---
    // ERC2981 functionality
    // ---

    /// @notice Resolve royalty info from the engine powering the sequence.
    function royaltyInfo(uint256 tokenId, uint256 salePrice)
        external
        view
        returns (address receiver, uint256 royaltyAmount)
    {
        SequenceData memory sinfo = sequences[_tokenData[tokenId].sequenceId];
        return sinfo.engine.getRoyaltyInfo(address(this), tokenId, salePrice);
    }

    // ---
    // Introspection
    // ---

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721, IERC165)
        returns (bool)
    {
        return
            interfaceId == type(IERC2981).interfaceId ||
            super.supportsInterface(interfaceId);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (proxy/Clones.sol)

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
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            instance := create(0, ptr, 0x37)
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
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            instance := create2(0, ptr, 0x37, salt)
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
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf3ff00000000000000000000000000000000)
            mstore(add(ptr, 0x38), shl(0x60, deployer))
            mstore(add(ptr, 0x4c), salt)
            mstore(add(ptr, 0x6c), keccak256(ptr, 0x37))
            predicted := keccak256(add(ptr, 0x37), 0x55)
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

/// @notice Minimal interface of the node registry.
interface INodeRegistry {
    function isAuthorizedAddressForNode(uint80 node, address subject)
        external
        view
        returns (bool);
}

/// @notice A registry of ownable nodes and their metadata
contract NodeRegistry is INodeRegistry {
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

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Data stored per-token, fits into a single storage word
struct TokenData {
    address owner;
    uint16 sequenceId;
    uint80 data;
}

/// @notice Modern, minimalist, and gas efficient ERC-721 implementation.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/tokens/ERC721.sol)
abstract contract ERC721 {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event Transfer(address indexed from, address indexed to, uint256 indexed id);

    event Approval(address indexed owner, address indexed spender, uint256 indexed id);

    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /*//////////////////////////////////////////////////////////////
                         METADATA STORAGE/LOGIC
    //////////////////////////////////////////////////////////////*/

    string public name;

    string public symbol;

    function tokenURI(uint256 id) public view virtual returns (string memory);

    /*//////////////////////////////////////////////////////////////
                      ERC721 BALANCE/OWNER STORAGE
    //////////////////////////////////////////////////////////////*/

    mapping(uint256 => TokenData) internal _tokenData;

    mapping(address => uint256) internal _balanceOf;

    function ownerOf(uint256 id) public view virtual returns (address owner) {
        require((owner = _tokenData[id].owner) != address(0), "NOT_MINTED");
    }

    function balanceOf(address owner) public view virtual returns (uint256) {
        require(owner != address(0), "ZERO_ADDRESS");

        return _balanceOf[owner];
    }

    /*//////////////////////////////////////////////////////////////
                         ERC721 APPROVAL STORAGE
    //////////////////////////////////////////////////////////////*/

    mapping(uint256 => address) public getApproved;

    mapping(address => mapping(address => bool)) public isApprovedForAll;

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(string memory _name, string memory _symbol) {
        name = _name;
        symbol = _symbol;
    }

    /*//////////////////////////////////////////////////////////////
                              ERC721 LOGIC
    //////////////////////////////////////////////////////////////*/

    function approve(address spender, uint256 id) public virtual {
        address owner = _tokenData[id].owner;

        require(msg.sender == owner || isApprovedForAll[owner][msg.sender], "NOT_AUTHORIZED");

        getApproved[id] = spender;

        emit Approval(owner, spender, id);
    }

    function setApprovalForAll(address operator, bool approved) public virtual {
        isApprovedForAll[msg.sender][operator] = approved;

        emit ApprovalForAll(msg.sender, operator, approved);
    }

    function transferFrom(
        address from,
        address to,
        uint256 id
    ) public virtual {
        require(from == _tokenData[id].owner, "WRONG_FROM");

        require(to != address(0), "INVALID_RECIPIENT");

        require(
            msg.sender == from || isApprovedForAll[from][msg.sender] || msg.sender == getApproved[id],
            "NOT_AUTHORIZED"
        );

        // Underflow of the sender's balance is impossible because we check for
        // ownership above and the recipient's balance can't realistically overflow.
        unchecked {
            _balanceOf[from]--;

            _balanceOf[to]++;
        }

        _tokenData[id].owner = to;

        delete getApproved[id];

        emit Transfer(from, to, id);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 id
    ) public virtual {
        transferFrom(from, to, id);

        require(
            to.code.length == 0 ||
                ERC721TokenReceiver(to).onERC721Received(msg.sender, from, id, "") ==
                ERC721TokenReceiver.onERC721Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        bytes calldata data
    ) public virtual {
        transferFrom(from, to, id);

        require(
            to.code.length == 0 ||
                ERC721TokenReceiver(to).onERC721Received(msg.sender, from, id, data) ==
                ERC721TokenReceiver.onERC721Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    /*//////////////////////////////////////////////////////////////
                              ERC165 LOGIC
    //////////////////////////////////////////////////////////////*/

    function supportsInterface(bytes4 interfaceId) public view virtual returns (bool) {
        return
            interfaceId == 0x01ffc9a7 || // ERC165 Interface ID for ERC165
            interfaceId == 0x80ac58cd || // ERC165 Interface ID for ERC721
            interfaceId == 0x5b5e139f; // ERC165 Interface ID for ERC721Metadata
    }

    /*//////////////////////////////////////////////////////////////
                        INTERNAL MINT/BURN LOGIC
    //////////////////////////////////////////////////////////////*/

    function _mint(address to, uint256 id) internal virtual {
        return _mint(to, id, 0, 0);
    }

    function _mint(address to, uint256 id, uint16 sequenceId, uint80 data) internal virtual {
        require(to != address(0), "INVALID_RECIPIENT");

        require(_tokenData[id].owner == address(0), "ALREADY_MINTED");

        // Counter overflow is incredibly unrealistic.
        unchecked {
            _balanceOf[to]++;
        }

        _tokenData[id] = TokenData({
            owner: to,
            sequenceId: sequenceId,
            data: data
        });

        emit Transfer(address(0), to, id);
    }

    function _burn(uint256 id) internal virtual {
        address owner = _tokenData[id].owner;

        require(owner != address(0), "NOT_MINTED");

        // Ownership check above ensures no underflow.
        unchecked {
            _balanceOf[owner]--;
        }

        delete _tokenData[id];

        delete getApproved[id];

        emit Transfer(owner, address(0), id);
    }

    /*//////////////////////////////////////////////////////////////
                        INTERNAL SAFE MINT LOGIC
    //////////////////////////////////////////////////////////////*/

    function _safeMint(address to, uint256 id) internal virtual {
        _mint(to, id);

        require(
            to.code.length == 0 ||
                ERC721TokenReceiver(to).onERC721Received(msg.sender, address(0), id, "") ==
                ERC721TokenReceiver.onERC721Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    function _safeMint(
        address to,
        uint256 id,
        bytes memory data
    ) internal virtual {
        _mint(to, id);

        require(
            to.code.length == 0 ||
                ERC721TokenReceiver(to).onERC721Received(msg.sender, address(0), id, data) ==
                ERC721TokenReceiver.onERC721Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    /*//////////////////////////////////////////////////////////////
                    METALABEL ADDED FUNCTIONALITY
    //////////////////////////////////////////////////////////////*/

    function getTokenData(uint256 id) external view virtual returns (TokenData memory) {
        TokenData memory data = _tokenData[id];
        require(data.owner != address(0), "NOT_MINTED");
        return data;
    }
}

/// @notice A generic interface for a contract which properly accepts ERC721 tokens.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/tokens/ERC721.sol)
abstract contract ERC721TokenReceiver {
    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external virtual returns (bytes4) {
        return ERC721TokenReceiver.onERC721Received.selector;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC165.sol)

pragma solidity ^0.8.0;

import "../utils/introspection/IERC165.sol";

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (interfaces/IERC2981.sol)

pragma solidity ^0.8.0;

import "../utils/introspection/IERC165.sol";

/**
 * @dev Interface for the NFT Royalty Standard.
 *
 * A standardized way to retrieve royalty payment information for non-fungible tokens (NFTs) to enable universal
 * support for royalty payments across all NFT marketplaces and ecosystem participants.
 *
 * _Available since v4.5._
 */
interface IERC2981 is IERC165 {
    /**
     * @dev Returns how much royalty is owed and to whom, based on a sale price that may be denominated in any unit of
     * exchange. The royalty amount is denominated and should be paid in that same unit of exchange.
     */
    function royaltyInfo(uint256 tokenId, uint256 salePrice)
        external
        view
        returns (address receiver, uint256 royaltyAmount);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC721.sol)

pragma solidity ^0.8.0;

import "../token/ERC721/IERC721.sol";

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
    function createAccount(address subject, string calldata metadata) external returns (uint80 id);
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
        address recovery,
        string metadata
    );

    /// @notice Announce the metadata for an account.
    event AccountMetadata(uint80 indexed id, string metadata);

    // ---
    // Errors
    // ---

    /// @notice An account was created for an address that already has one.
    error AccountAlreadyExists();

    /// @notice Recovery address cannot be provided if msg.sender is not the
    /// account address
    error InvalidRegistration();

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

    /// @notice Create an account with no recovery address.
    function createAccount(address subject, string calldata metadata) external returns (uint80 id) {
        id = _createAccount(subject, address(0), metadata);
    }

    /// @notice Create a new account with a recovery address. Can only be called
    /// if subject is msg.sender
    function createAccountWithRecovery(address subject, address recovery, string calldata metadata)
        external
        returns (uint80 id)
    {
        if (msg.sender != subject) revert InvalidRegistration();
        id = _createAccount(subject, recovery, metadata);
    }

    /// @notice Internal create logic
    function _createAccount(address subject, address recovery, string memory metadata)
        internal
        returns (uint80 id)
    {
        if (accounts[subject].id != 0) revert AccountAlreadyExists();
        id = ++totalAccountCount;
        accounts[subject] = AccountData({id: id, recovery: recovery});
        emit AccountCreated(id, subject, recovery, metadata);
    }

    // ---
    // Views
    // ---

    /// @notice Determine the account ID for an address.
    function resolveId(address subject) external view returns (uint80 id) {
        id = accounts[subject].id;
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/IERC721.sol)

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

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
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
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}