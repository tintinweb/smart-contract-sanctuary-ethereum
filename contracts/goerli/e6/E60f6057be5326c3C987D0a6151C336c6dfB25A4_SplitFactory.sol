// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {INodeRegistry} from "./NodeRegistry.sol";
import {ISplitMain} from "@metalabel/splits-contracts/contracts/interfaces/ISplitMain.sol";

contract SplitFactory {
    // ---
    // Errors
    // ---

    /// @notice An unauthorized address attempted to create a split
    error NotAuthorized();

    // ---
    // Events
    // ---

    /// @notice A new split was deployed
    event SplitCreated(
        address indexed split,
        uint80 nodeId,
        address[] accounts,
        uint32[] percentAllocations,
        string metadata
    );

    // ---
    // Storage
    // ---

    /// @notice Reference to the catalog collection implementation that will be cloned.
    ISplitMain public immutable splits;

    /// @notice Reference to the node registry of the protocol.
    INodeRegistry public immutable nodeRegistry;

    /// @notice Mapping from a split address to its control node ID
    mapping(address => uint80) public deployedSplits;

    // ---
    // Constructor
    // ---

    constructor(INodeRegistry _nodeRegsitry, ISplitMain _splits) {
        splits = _splits;
        nodeRegistry = _nodeRegsitry;
    }

    // ---
    // Public funcionality
    // ---

    /// @notice Launch a new split
    function createSplit(
        address[] calldata accounts,
        uint32[] calldata percentAllocations,
        uint32 distributorFee,
        uint80 controlNodeId,
        string calldata metadata
    ) external returns (address split) {
        if (
            !nodeRegistry.isAuthorizedAddressForNode(controlNodeId, msg.sender)
        ) {
            /// msg.sender must be authorized to manage the control node of the
            /// catalog
            revert NotAuthorized();
        }

        split = splits.createSplit(
            accounts,
            percentAllocations,
            distributorFee,
            address(0)
        );
        deployedSplits[split] = controlNodeId;
        emit SplitCreated(
            split,
            controlNodeId,
            accounts,
            percentAllocations,
            metadata
        );
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
        uint80 accessNode,
        string metadata
    );

    /// @notice A node's owner was changed
    event NodeOwnerSet(uint80 indexed id, uint80 indexed owner);

    /// @notice A node's access node was changed
    event NodeAccessNodeSet(uint80 indexed id, uint80 indexed accessNode);

    /// @notice An arbitrary event was been emitted from a node
    event NodeBroadcast(uint80 indexed id, string topic, string message);

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
    // Node creation
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
            // msg.sender must have an account and be set as node owner
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
        emit NodeCreated(id, nodeType, owner, parent, accessNode, metadata);
    }

    // ---
    // Node management
    // ---

    // @notice Set node's owner. Can only be called by the existing node owner
    // if already set. If it's not yet set, it can be called by the access node
    function setNodeOwner(uint80 id, uint80 owner) external {
        uint80 currentOwner = nodes[id].owner;
        if (
            currentOwner == 0 || currentOwner != accounts.resolveId(msg.sender)
        ) {
            // If the node is invalid, or if the current owner is not the
            // msg.sender, do not allow owner change
            revert NotAuthorizedForNode();
        }

        nodes[id].owner = owner;
        emit NodeOwnerSet(id, owner);
    }

    /// @notice Modify a node's access node. Msg.sender must be authorized to
    /// manage the node
    function setNodeAccessNode(uint80 id, uint80 accessNode) external {
        if (!isAuthorizedAddressForNode(id, msg.sender)) {
            revert NotAuthorizedForNode();
        }
        nodes[id].accessNode = accessNode;
        emit NodeAccessNodeSet(id, accessNode);
    }

    /// @notice Broadcast an arbitrary event from a node. Msg.sender must be
    /// authorized to manage the node
    function broadcast(
        uint80 id,
        string calldata topic,
        string calldata message
    ) external {
        if (!isAuthorizedAddressForNode(id, msg.sender)) {
            revert NotAuthorizedForNode();
        }

        emit NodeBroadcast(id, topic, message);
    }

    /// @notice Set the authorized manager for a node. Msg.sender must have an
    /// account and be authorized to manage the node
    function setAuthorizedNodeManager(
        uint80 node,
        address manager,
        bool isAuthorized
    ) external {
        // only allow authorized accounts (only owner or access node owner, not
        // external managers) to set new authorized managers. This is done to
        // prevent external contracts from adding additional contracts as
        // managers, forcing a node owner to explictly set a manager
        if (!isAuthorizedAccountForNode(node, accounts.resolveId(msg.sender))) {
            revert NotAuthorizedForNode();
        }

        authorizedNodeManagers[node][manager] = isAuthorized;
        emit AuthorizedManagerSet(node, manager, isAuthorized);
    }

    // ---
    // Node views
    // ---

    /// @notice Resolve node owner account.
    function ownerOf(uint80 id) external view returns (uint80) {
        return nodes[id].owner;
    }

    /// @notice Resolve node access node
    function accessNodeOf(uint80 id) external view returns (uint80) {
        return nodes[id].accessNode;
    }

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

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.13;

import {ERC20} from '@rari-capital/solmate/src/tokens/ERC20.sol';

/**
 * @title ISplitMain
 * @author 0xSplits <[email protected]>
 */
interface ISplitMain {
  /**
   * FUNCTIONS
   */

  function walletImplementation() external returns (address);

  function createSplit(
    address[] calldata accounts,
    uint32[] calldata percentAllocations,
    uint32 distributorFee,
    address controller
  ) external returns (address);

  function predictImmutableSplitAddress(
    address[] calldata accounts,
    uint32[] calldata percentAllocations,
    uint32 distributorFee
  ) external view returns (address);

  function updateSplit(
    address split,
    address[] calldata accounts,
    uint32[] calldata percentAllocations,
    uint32 distributorFee
  ) external;

  function transferControl(address split, address newController) external;

  function cancelControlTransfer(address split) external;

  function acceptControl(address split) external;

  function makeSplitImmutable(address split) external;

  function distributeETH(
    address split,
    address[] calldata accounts,
    uint32[] calldata percentAllocations,
    uint32 distributorFee,
    address distributorAddress
  ) external;

  function updateAndDistributeETH(
    address split,
    address[] calldata accounts,
    uint32[] calldata percentAllocations,
    uint32 distributorFee,
    address distributorAddress
  ) external;

  function distributeERC20(
    address split,
    ERC20 token,
    address[] calldata accounts,
    uint32[] calldata percentAllocations,
    uint32 distributorFee,
    address distributorAddress
  ) external;

  function updateAndDistributeERC20(
    address split,
    ERC20 token,
    address[] calldata accounts,
    uint32[] calldata percentAllocations,
    uint32 distributorFee,
    address distributorAddress
  ) external;

  function withdraw(
    address account,
    uint256 withdrawETH,
    ERC20[] calldata tokens
  ) external;

  /**
   * EVENTS
   */

  /** @notice emitted after each successful split creation
   *  @param split Address of the created split
   */
  event CreateSplit(address indexed split);

  /** @notice emitted after each successful split update
   *  @param split Address of the updated split
   */
  event UpdateSplit(address indexed split);

  /** @notice emitted after each initiated split control transfer
   *  @param split Address of the split control transfer was initiated for
   *  @param newPotentialController Address of the split's new potential controller
   */
  event InitiateControlTransfer(
    address indexed split,
    address indexed newPotentialController
  );

  /** @notice emitted after each canceled split control transfer
   *  @param split Address of the split control transfer was canceled for
   */
  event CancelControlTransfer(address indexed split);

  /** @notice emitted after each successful split control transfer
   *  @param split Address of the split control was transferred for
   *  @param previousController Address of the split's previous controller
   *  @param newController Address of the split's new controller
   */
  event ControlTransfer(
    address indexed split,
    address indexed previousController,
    address indexed newController
  );

  /** @notice emitted after each successful ETH balance split
   *  @param split Address of the split that distributed its balance
   *  @param amount Amount of ETH distributed
   *  @param distributorAddress Address to credit distributor fee to
   */
  event DistributeETH(
    address indexed split,
    uint256 amount,
    address indexed distributorAddress
  );

  /** @notice emitted after each successful ERC20 balance split
   *  @param split Address of the split that distributed its balance
   *  @param token Address of ERC20 distributed
   *  @param amount Amount of ERC20 distributed
   *  @param distributorAddress Address to credit distributor fee to
   */
  event DistributeERC20(
    address indexed split,
    ERC20 indexed token,
    uint256 amount,
    address indexed distributorAddress
  );

  /** @notice emitted after each successful withdrawal
   *  @param account Address that funds were withdrawn to
   *  @param ethAmount Amount of ETH withdrawn
   *  @param tokens Addresses of ERC20s withdrawn
   *  @param tokenAmounts Amounts of corresponding ERC20s withdrawn
   */
  event Withdrawal(
    address indexed account,
    uint256 ethAmount,
    ERC20[] tokens,
    uint256[] tokenAmounts
  );
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

    function createAccount(address subject, string calldata metadata)
        external
        returns (uint80 id);
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

    /// @notice Broadcast a message from an account
    event AccountBroadcast(uint80 indexed id, string topic, string message);

    /// @notice An account's address has changed
    event AccountTransfered(uint80 indexed id, address newOwner);

    /// @notice An account's recovery address has changed
    event AccountRecoverySet(uint80 indexed id, address newRecoveryAddress);

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

    // ---
    // Storage
    // ---

    /// @notice Total number of created accounts
    uint80 public totalAccountCount;

    /// @notice Mapping of addresses to account IDs.
    mapping(address => AccountData) public accounts;

    // ---
    // Account creation functionality
    // ---

    /// @notice Create an account with no recovery address.
    function createAccount(address subject, string calldata metadata)
        external
        returns (uint80 id)
    {
        id = _createAccount(subject, address(0), metadata);
    }

    /// @notice Create a new account with a recovery address. Can only be called
    /// if subject is msg.sender
    function createAccountWithRecovery(
        address subject,
        address recovery,
        string calldata metadata
    ) external returns (uint80 id) {
        if (msg.sender != subject) revert InvalidRegistration();
        id = _createAccount(subject, recovery, metadata);
    }

    /// @notice Internal create logic
    function _createAccount(
        address subject,
        address recovery,
        string memory metadata
    ) internal returns (uint80 id) {
        if (accounts[subject].id != 0) revert AccountAlreadyExists();
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
        uint80 id = accounts[msg.sender].id;
        if (id == 0) revert NoAccount();
        emit AccountBroadcast(id, topic, message);
    }

    /// @notice Transfer the account to another address.
    function transferAccount(address newOwner) external {
        AccountData memory maccount = accounts[msg.sender];
        if (maccount.id == 0) revert NoAccount();
        if (accounts[newOwner].id != 0) revert AccountAlreadyExists();

        accounts[newOwner] = maccount;
        delete accounts[msg.sender];
        emit AccountTransfered(maccount.id, newOwner);
    }

    /// @notice Transfer the account to another address as the recovery address.
    function recoverAccount(address oldOwner, address newOwner) external {
        AccountData memory maccount = accounts[oldOwner];
        if (maccount.recovery != msg.sender) revert InvalidRecovery();
        if (accounts[newOwner].id != 0) revert AccountAlreadyExists();

        accounts[newOwner] = maccount;
        delete accounts[oldOwner];
        emit AccountTransfered(maccount.id, newOwner);
    }

    /// @notice Set the recovery address for an account.
    function setRecovery(address recovery) external {
        AccountData memory maccount = accounts[msg.sender];
        if (maccount.id == 0) revert NoAccount();
        accounts[msg.sender].recovery = recovery;
        emit AccountRecoverySet(maccount.id, recovery);
    }

    // ---
    // Views
    // ---

    /// @notice Determine the account ID for an address.
    function resolveId(address subject) external view returns (uint80 id) {
        id = accounts[subject].id;
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Modern and gas efficient ERC20 + EIP-2612 implementation.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/tokens/ERC20.sol)
/// @author Modified from Uniswap (https://github.com/Uniswap/uniswap-v2-core/blob/master/contracts/UniswapV2ERC20.sol)
/// @dev Do not manually set balances without updating totalSupply, as the sum of all user balances must not exceed it.
abstract contract ERC20 {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event Transfer(address indexed from, address indexed to, uint256 amount);

    event Approval(address indexed owner, address indexed spender, uint256 amount);

    /*//////////////////////////////////////////////////////////////
                            METADATA STORAGE
    //////////////////////////////////////////////////////////////*/

    string public name;

    string public symbol;

    uint8 public immutable decimals;

    /*//////////////////////////////////////////////////////////////
                              ERC20 STORAGE
    //////////////////////////////////////////////////////////////*/

    uint256 public totalSupply;

    mapping(address => uint256) public balanceOf;

    mapping(address => mapping(address => uint256)) public allowance;

    /*//////////////////////////////////////////////////////////////
                            EIP-2612 STORAGE
    //////////////////////////////////////////////////////////////*/

    uint256 internal immutable INITIAL_CHAIN_ID;

    bytes32 internal immutable INITIAL_DOMAIN_SEPARATOR;

    mapping(address => uint256) public nonces;

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(
        string memory _name,
        string memory _symbol,
        uint8 _decimals
    ) {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;

        INITIAL_CHAIN_ID = block.chainid;
        INITIAL_DOMAIN_SEPARATOR = computeDomainSeparator();
    }

    /*//////////////////////////////////////////////////////////////
                               ERC20 LOGIC
    //////////////////////////////////////////////////////////////*/

    function approve(address spender, uint256 amount) public virtual returns (bool) {
        allowance[msg.sender][spender] = amount;

        emit Approval(msg.sender, spender, amount);

        return true;
    }

    function transfer(address to, uint256 amount) public virtual returns (bool) {
        balanceOf[msg.sender] -= amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(msg.sender, to, amount);

        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual returns (bool) {
        uint256 allowed = allowance[from][msg.sender]; // Saves gas for limited approvals.

        if (allowed != type(uint256).max) allowance[from][msg.sender] = allowed - amount;

        balanceOf[from] -= amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(from, to, amount);

        return true;
    }

    /*//////////////////////////////////////////////////////////////
                             EIP-2612 LOGIC
    //////////////////////////////////////////////////////////////*/

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public virtual {
        require(deadline >= block.timestamp, "PERMIT_DEADLINE_EXPIRED");

        // Unchecked because the only math done is incrementing
        // the owner's nonce which cannot realistically overflow.
        unchecked {
            address recoveredAddress = ecrecover(
                keccak256(
                    abi.encodePacked(
                        "\x19\x01",
                        DOMAIN_SEPARATOR(),
                        keccak256(
                            abi.encode(
                                keccak256(
                                    "Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"
                                ),
                                owner,
                                spender,
                                value,
                                nonces[owner]++,
                                deadline
                            )
                        )
                    )
                ),
                v,
                r,
                s
            );

            require(recoveredAddress != address(0) && recoveredAddress == owner, "INVALID_SIGNER");

            allowance[recoveredAddress][spender] = value;
        }

        emit Approval(owner, spender, value);
    }

    function DOMAIN_SEPARATOR() public view virtual returns (bytes32) {
        return block.chainid == INITIAL_CHAIN_ID ? INITIAL_DOMAIN_SEPARATOR : computeDomainSeparator();
    }

    function computeDomainSeparator() internal view virtual returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                    keccak256(bytes(name)),
                    keccak256("1"),
                    block.chainid,
                    address(this)
                )
            );
    }

    /*//////////////////////////////////////////////////////////////
                        INTERNAL MINT/BURN LOGIC
    //////////////////////////////////////////////////////////////*/

    function _mint(address to, uint256 amount) internal virtual {
        totalSupply += amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(address(0), to, amount);
    }

    function _burn(address from, uint256 amount) internal virtual {
        balanceOf[from] -= amount;

        // Cannot underflow because a user's balance
        // will never be larger than the total supply.
        unchecked {
            totalSupply -= amount;
        }

        emit Transfer(from, address(0), amount);
    }
}