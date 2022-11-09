// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Minimalist and gas efficient standard ERC1155 implementation.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/tokens/ERC1155.sol)
abstract contract ERC1155 {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event TransferSingle(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256 id,
        uint256 amount
    );

    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] amounts
    );

    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    event URI(string value, uint256 indexed id);

    /*//////////////////////////////////////////////////////////////
                             ERC1155 STORAGE
    //////////////////////////////////////////////////////////////*/

    mapping(address => mapping(uint256 => uint256)) public balanceOf;

    mapping(address => mapping(address => bool)) public isApprovedForAll;

    /*//////////////////////////////////////////////////////////////
                             METADATA LOGIC
    //////////////////////////////////////////////////////////////*/

    function uri(uint256 id) public view virtual returns (string memory);

    /*//////////////////////////////////////////////////////////////
                              ERC1155 LOGIC
    //////////////////////////////////////////////////////////////*/

    function setApprovalForAll(address operator, bool approved) public virtual {
        isApprovedForAll[msg.sender][operator] = approved;

        emit ApprovalForAll(msg.sender, operator, approved);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) public virtual {
        require(msg.sender == from || isApprovedForAll[from][msg.sender], "NOT_AUTHORIZED");

        balanceOf[from][id] -= amount;
        balanceOf[to][id] += amount;

        emit TransferSingle(msg.sender, from, to, id, amount);

        require(
            to.code.length == 0
                ? to != address(0)
                : ERC1155TokenReceiver(to).onERC1155Received(msg.sender, from, id, amount, data) ==
                    ERC1155TokenReceiver.onERC1155Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) public virtual {
        require(ids.length == amounts.length, "LENGTH_MISMATCH");

        require(msg.sender == from || isApprovedForAll[from][msg.sender], "NOT_AUTHORIZED");

        // Storing these outside the loop saves ~15 gas per iteration.
        uint256 id;
        uint256 amount;

        for (uint256 i = 0; i < ids.length; ) {
            id = ids[i];
            amount = amounts[i];

            balanceOf[from][id] -= amount;
            balanceOf[to][id] += amount;

            // An array can't have a total length
            // larger than the max uint256 value.
            unchecked {
                ++i;
            }
        }

        emit TransferBatch(msg.sender, from, to, ids, amounts);

        require(
            to.code.length == 0
                ? to != address(0)
                : ERC1155TokenReceiver(to).onERC1155BatchReceived(msg.sender, from, ids, amounts, data) ==
                    ERC1155TokenReceiver.onERC1155BatchReceived.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    function balanceOfBatch(address[] calldata owners, uint256[] calldata ids)
        public
        view
        virtual
        returns (uint256[] memory balances)
    {
        require(owners.length == ids.length, "LENGTH_MISMATCH");

        balances = new uint256[](owners.length);

        // Unchecked because the only math done is incrementing
        // the array index counter which cannot possibly overflow.
        unchecked {
            for (uint256 i = 0; i < owners.length; ++i) {
                balances[i] = balanceOf[owners[i]][ids[i]];
            }
        }
    }

    /*//////////////////////////////////////////////////////////////
                              ERC165 LOGIC
    //////////////////////////////////////////////////////////////*/

    function supportsInterface(bytes4 interfaceId) public view virtual returns (bool) {
        return
            interfaceId == 0x01ffc9a7 || // ERC165 Interface ID for ERC165
            interfaceId == 0xd9b67a26 || // ERC165 Interface ID for ERC1155
            interfaceId == 0x0e89341c; // ERC165 Interface ID for ERC1155MetadataURI
    }

    /*//////////////////////////////////////////////////////////////
                        INTERNAL MINT/BURN LOGIC
    //////////////////////////////////////////////////////////////*/

    function _mint(
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        balanceOf[to][id] += amount;

        emit TransferSingle(msg.sender, address(0), to, id, amount);

        require(
            to.code.length == 0
                ? to != address(0)
                : ERC1155TokenReceiver(to).onERC1155Received(msg.sender, address(0), id, amount, data) ==
                    ERC1155TokenReceiver.onERC1155Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    function _batchMint(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        uint256 idsLength = ids.length; // Saves MLOADs.

        require(idsLength == amounts.length, "LENGTH_MISMATCH");

        for (uint256 i = 0; i < idsLength; ) {
            balanceOf[to][ids[i]] += amounts[i];

            // An array can't have a total length
            // larger than the max uint256 value.
            unchecked {
                ++i;
            }
        }

        emit TransferBatch(msg.sender, address(0), to, ids, amounts);

        require(
            to.code.length == 0
                ? to != address(0)
                : ERC1155TokenReceiver(to).onERC1155BatchReceived(msg.sender, address(0), ids, amounts, data) ==
                    ERC1155TokenReceiver.onERC1155BatchReceived.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    function _batchBurn(
        address from,
        uint256[] memory ids,
        uint256[] memory amounts
    ) internal virtual {
        uint256 idsLength = ids.length; // Saves MLOADs.

        require(idsLength == amounts.length, "LENGTH_MISMATCH");

        for (uint256 i = 0; i < idsLength; ) {
            balanceOf[from][ids[i]] -= amounts[i];

            // An array can't have a total length
            // larger than the max uint256 value.
            unchecked {
                ++i;
            }
        }

        emit TransferBatch(msg.sender, from, address(0), ids, amounts);
    }

    function _burn(
        address from,
        uint256 id,
        uint256 amount
    ) internal virtual {
        balanceOf[from][id] -= amount;

        emit TransferSingle(msg.sender, from, address(0), id, amount);
    }
}

/// @notice A generic interface for a contract which properly accepts ERC1155 tokens.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/tokens/ERC1155.sol)
abstract contract ERC1155TokenReceiver {
    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes calldata
    ) external virtual returns (bytes4) {
        return ERC1155TokenReceiver.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] calldata,
        uint256[] calldata,
        bytes calldata
    ) external virtual returns (bytes4) {
        return ERC1155TokenReceiver.onERC1155BatchReceived.selector;
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

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

    mapping(uint256 => address) internal _ownerOf;

    mapping(address => uint256) internal _balanceOf;

    function ownerOf(uint256 id) public view virtual returns (address owner) {
        require((owner = _ownerOf[id]) != address(0), "NOT_MINTED");
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
        address owner = _ownerOf[id];

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
        require(from == _ownerOf[id], "WRONG_FROM");

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

        _ownerOf[id] = to;

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
        require(to != address(0), "INVALID_RECIPIENT");

        require(_ownerOf[id] == address(0), "ALREADY_MINTED");

        // Counter overflow is incredibly unrealistic.
        unchecked {
            _balanceOf[to]++;
        }

        _ownerOf[id] = to;

        emit Transfer(address(0), to, id);
    }

    function _burn(uint256 id) internal virtual {
        address owner = _ownerOf[id];

        require(owner != address(0), "NOT_MINTED");

        // Ownership check above ensures no underflow.
        unchecked {
            _balanceOf[owner]--;
        }

        delete _ownerOf[id];

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
pragma solidity 0.8.13;

interface IENS {
    struct Record {
        address owner;
        address resolver;
        uint64 ttl;
    }

    function owner(bytes32 _node) external view returns (address);

    function resolver(bytes32 _node) external view returns (address);

    function ttl(bytes32 _node) external view returns (uint64);

    function setOwner(bytes32 _node, address _owner) external;

    function setSubnodeRecord(
        bytes32 _node,
        bytes32 _label,
        address _owner,
        address _resolver,
        uint64 _ttl
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

// @dev Interface for TNSRegister target contract
interface ITNSRegister {
    function setSubnode(
        bytes32 _node,
        bytes32 _label,
        address _owner,
        address _resolver,
        uint64 _ttl
    ) external;

    function setName(string memory _name) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import {Permission} from "../../interfaces/IVaultRegistry.sol";

// @dev Interface for TNSRegistrar module contract
interface ITNSRegistrar {
    /// @dev Emitted when the vault is already registered with a parent node
    error AlreadyRegistered();
    /// @dev Emitted when the claim allowance is insufficent
    error InsufficientAllowance();
    /// @dev Emitted when the token balance is insufficient
    error InsufficientBalance();
    /// @dev Emitted when the caller is not the owner of the subdomain
    error NotOwner();
    /// @dev Emitted when the vault is not registered through the VaultRegistry
    error NotVault(address _vault);
    /// @dev Emitted when the ENS node is not registered
    error UnregisteredNode();

    event Claim(
        address indexed _vault,
        bytes32 indexed _parentNode,
        string _label
    );

    event Unclaim(
        address indexed _vault,
        bytes32 indexed _parentNode,
        string _label
    );

    function allowances(address, address) external view returns (uint256);

    function claim(
        address _vault,
        address _owner,
        string calldata _label,
        bytes32[] calldata _setSubnodeProof
    ) external;

    function ens() external view returns (address);

    function getPermissions()
        external
        view
        returns (Permission[] memory permissions);

    function parentNodes(address) external view returns (bytes32);

    function register() external view returns (address);

    function registerNode(address _vault, bytes32 _parentNode) external;

    function registry() external view returns (address);

    function supply() external view returns (address);

    function unclaim(
        address _vault,
        string calldata _label,
        bytes32[] calldata _setSubnodeProof
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import {ERC1155} from "@rari-capital/solmate/src/tokens/ERC1155.sol";
import {Module} from "../../modules/Module.sol";
import {NFTReceiver} from "../../utils/NFTReceiver.sol";
import {Permission} from "../../interfaces/IModule.sol";

import {IENS} from "../interfaces/IENS.sol";
import {IERC1155} from "../../interfaces/IERC1155.sol";
import {ITNSRegister} from "../interfaces/ITNSRegister.sol";
import {ITNSRegistrar} from "../interfaces/ITNSRegistrar.sol";
import {IVault} from "../../interfaces/IVault.sol";
import {IVaultRegistry} from "../../interfaces/IVaultRegistry.sol";

/// @title TNSRegistrar
/// @author Tessera
/// @notice Module contract for registering subdomain records
contract TNSRegistrar is ITNSRegistrar, ERC1155, Module, NFTReceiver {
    /// @notice Address of VaultRegistry contract
    address public immutable registry;
    /// @notice Address of the TNSSupply target contract
    address public immutable supply;
    /// @notice Address of the TNSRegister target contract
    address public immutable register;
    /// @notice Address of the ENSRegistry contract
    address public immutable ens;
    /// @notice Mapping of vault address to ENS parent node
    mapping(address => bytes32) public parentNodes;
    /// @notice Mapping of vault address to user address to claim allowance
    mapping(address => mapping(address => uint256)) public allowances;

    /// @dev Initializes registry, supply, register and ENS contracts
    constructor(
        address _registry,
        address _supply,
        address _register,
        address _ens
    ) {
        registry = _registry;
        supply = _supply;
        register = _register;
        ens = _ens;
    }

    /// @notice Registers a vault with an ENS node
    /// @dev Only callable once through the protoform
    /// @param _vault Address of the vault
    /// @param _parentNode Hash of the parent node
    function registerNode(address _vault, bytes32 _parentNode) external {
        // Reverts if vault is not registered through the VaultRegistry
        _verifyVault(_vault);
        // Reverts if vault and parent nodea are already registered
        if (parentNodes[_vault] != bytes32(0)) revert AlreadyRegistered();
        parentNodes[_vault] = _parentNode;
    }

    /// @notice Claims a subdomain and deposits single Rae
    /// @param _vault Address of the vault
    /// @param _owner Address of the subdomain owner
    /// @param _label Individual component of the name
    /// @param _setSubnodeProof Merkle proof for executing creation of subnode record
    function claim(
        address _vault,
        address _owner,
        string calldata _label,
        bytes32[] calldata _setSubnodeProof
    ) external {
        // Reverts if vault is not registered with VaultRegistry
        (address token, uint256 id) = _verifyVault(_vault);
        // Reverts if parent node is not registered with vault
        bytes32 parentNode = _verifyNode(_vault);
        address resolver = IENS(ens).resolver(parentNode);
        // Reverts if caller has insufficient token balance
        uint256 tokenBalance = IERC1155(token).balanceOf(msg.sender, id);
        if (tokenBalance < 1) revert InsufficientBalance();

        // Generates subnode components from parent node
        (bytes32 labelHash, uint256 tokenId, ) = _generateSubnode(
            parentNode,
            _label
        );

        // Increments caller allowance
        ++allowances[_vault][msg.sender];

        // Transfers single Rae token to this contract
        IERC1155(token).safeTransferFrom(msg.sender, address(this), id, 1, "");

        // Initializes vault transaction for setting subnode record
        bytes memory data = abi.encodeCall(
            ITNSRegister.setSubnode,
            (parentNode, labelHash, _owner, resolver, 0)
        );
        // Executes the setting of a subnode record
        IVault(payable(_vault)).execute(register, data, _setSubnodeProof);

        // Mints subdomain token to caller
        _mint(_owner, tokenId, 1, "");

        // Emits event for claiming subdomain
        emit Claim(_vault, parentNode, _label);
    }

    /// @notice Burns an existing subdomain and withdraws single Rae
    /// @param _vault Address of the vault
    /// @param _label Individual component of the name
    /// @param _setSubnodeProof Merkle proof for executing update of subnode record
    function unclaim(
        address _vault,
        string calldata _label,
        bytes32[] calldata _setSubnodeProof
    ) external {
        // Reverts if vault is not registered with VaultRegistry
        (address token, uint256 id) = _verifyVault(_vault);
        // Reverts if parent node is not registered with vault
        bytes32 parentNode = _verifyNode(_vault);
        // Generates subnode components from parent node
        (, uint256 tokenId, bytes32 subnode) = _generateSubnode(
            parentNode,
            _label
        );
        // Reverts if caller is not owner of subdomain
        if (msg.sender != IENS(ens).owner(subnode)) revert NotOwner();
        // Reverts if caller has insufficient allowance
        if (allowances[_vault][msg.sender] < 1) revert InsufficientAllowance();

        // Decrements caller allowance
        --allowances[_vault][msg.sender];

        // Transfers single Rae token back to caller
        IERC1155(token).safeTransferFrom(address(this), msg.sender, id, 1, "");

        // Burns subdomain token from caller
        _burn(msg.sender, tokenId, 1);

        // Emits event for unclaiming subdomain
        emit Unclaim(_vault, parentNode, _label);
    }

    /// @notice Gets the list of permissions installed on a vault
    /// @dev Permissions consist of a module contract, target contract, and function selector
    /// @return permissions List of vault permissions
    function getPermissions()
        public
        view
        override(ITNSRegistrar, Module)
        returns (Permission[] memory permissions)
    {
        permissions = new Permission[](1);
        // setSubnode function selector from TNSRegister contract
        permissions[0] = Permission(
            address(this),
            register,
            ITNSRegister.setSubnode.selector
        );
    }

    /// @notice Gets the URI of a given ID
    function uri(uint256 _id) public view override returns (string memory) {
        return "";
    }

    /// @dev Checks if vault is registered through the VaultRegistry
    function _verifyVault(address _vault)
        internal
        returns (address token, uint256 id)
    {
        (token, id) = IVaultRegistry(registry).vaultToToken(_vault);
        if (id == 0) revert NotVault(_vault);
    }

    /// @dev Checks if parent node is registered with vault
    function _verifyNode(address _vault) internal returns (bytes32 parentNode) {
        parentNode = parentNodes[_vault];
        if (parentNode == bytes32(0)) revert UnregisteredNode();
    }

    /// @dev Generates the subnode of a parent node and label component
    function _generateSubnode(bytes32 _parentNode, string memory _label)
        internal
        returns (
            bytes32 labelHash,
            uint256 tokenId,
            bytes32 subnode
        )
    {
        labelHash = keccak256(bytes(_label));
        tokenId = uint256(labelHash);
        subnode = keccak256(abi.encodePacked(_parentNode, labelHash));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

/// @dev Interface for ERC-1155 token contract
interface IERC1155 {
    event ApprovalForAll(
        address indexed _owner,
        address indexed _operator,
        bool _approved
    );
    event TransferBatch(
        address indexed _operator,
        address indexed _from,
        address indexed _to,
        uint256[] _ids,
        uint256[] _amounts
    );
    event TransferSingle(
        address indexed _operator,
        address indexed _from,
        address indexed _to,
        uint256 _id,
        uint256 _amount
    );
    event URI(string _value, uint256 indexed _id);

    function balanceOf(address, uint256) external view returns (uint256);

    function balanceOfBatch(address[] memory _owners, uint256[] memory ids)
        external
        view
        returns (uint256[] memory balances);

    function isApprovedForAll(address, address) external view returns (bool);

    function safeBatchTransferFrom(
        address _from,
        address _to,
        uint256[] memory _ids,
        uint256[] memory _amounts,
        bytes memory _data
    ) external;

    function safeTransferFrom(
        address _from,
        address _to,
        uint256 _id,
        uint256 _amount,
        bytes memory _data
    ) external;

    function setApprovalForAll(address _operator, bool _approved) external;

    function supportsInterface(bytes4 _interfaceId)
        external
        view
        returns (bool);

    function uri(uint256 _id) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import {Permission} from "./IVaultRegistry.sol";

/// @dev Interface for generic Module contract
interface IModule {
    function getLeaves() external view returns (bytes32[] memory leaves);

    function getUnhashedLeaves() external view returns (bytes[] memory leaves);

    function getPermissions()
        external
        view
        returns (Permission[] memory permissions);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

/// @dev Initialization call information
struct InitInfo {
    // Address of target contract
    address target;
    // Initialization data
    bytes data;
    // Merkle proof for call
    bytes32[] proof;
}

struct Plugin {
    //Address of plugin
    address target;
    //Function selector of plugin
    bytes4 selector;
}

/// @dev Interface for Vault proxy contract
interface IVault {
    /// @dev Emitted when execution reverted with no reason
    error ExecutionReverted();
    /// @dev Emitted when there is no implementation stored in methods for a function signature
    error MethodNotFound();
    /// @dev Emitted when a plugin selector would overwrite an existing plugin
    error InvalidSelector(bytes4 _selector);
    /// @dev Emitted when the caller is not the owner
    error NotAuthorized(address _caller, address _target, bytes4 _selector);
    /// @dev Emitted when the caller is not the owner
    error NotOwner(address _owner, address _caller);
    /// @dev Emitted when the caller is not the factory
    error NotFactory(address _factory, address _caller);
    /// @dev Emitted when passing an EOA or an undeployed contract as the target
    error TargetInvalid(address _target);

    /// @dev Event log for executing transactions
    /// @param _target Address of target contract
    /// @param _data Transaction data being executed
    /// @param _response Return data of delegatecall
    event Execute(address indexed _target, bytes _data, bytes _response);
    /// @dev Event log for installing plugins
    /// @param _plugins List of plugin contracts
    event UpdatedPlugins(Plugin[] _plugins);

    function execute(
        address _target,
        bytes memory _data,
        bytes32[] memory _proof
    ) external payable returns (bool success, bytes memory response);

    function setPlugins(Plugin[] memory _plugins) external;

    function methods(bytes4) external view returns (address);

    function MERKLE_ROOT() external view returns (bytes32);

    function OWNER() external view returns (address);

    function FACTORY() external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import {InitInfo, Plugin} from "./IVault.sol";

/// @dev Vault permissions
struct Permission {
    // Address of module contract
    address module;
    // Address of target contract
    address target;
    // Function selector from target contract
    bytes4 selector;
}

/// @dev Vault information
struct VaultInfo {
    // Address of FERC1155 token contract
    address token;
    // ID of the token type
    uint256 id;
}

/// @dev Interface for VaultRegistry contract
interface IVaultRegistry {
    /// @dev Emitted when the caller is not the controller
    error InvalidController(address _controller, address _sender);
    /// @dev Emitted when the caller is not a registered vault
    error UnregisteredVault(address _sender);

    /// @dev Event log for deploying vault
    /// @param _vault Address of the vault
    /// @param _token Address of the token
    /// @param _id Id of the token
    event VaultDeployed(
        address indexed _vault,
        address indexed _token,
        uint256 indexed _id
    );

    function createFor(
        bytes32 _merkleRoot,
        address _owner,
        Plugin[] calldata _plugins,
        InitInfo[] calldata _calls
    ) external returns (address vault);

    function createFor(
        bytes32 _merkleRoot,
        address _owner,
        Plugin[] calldata _plugins
    ) external returns (address vault);

    function create(
        bytes32 _merkleRoot,
        Plugin[] calldata _plugins,
        InitInfo[] calldata _calls
    ) external returns (address vault);

    function create(bytes32 _merkleRoot, Plugin[] calldata _plugins)
        external
        returns (address vault);

    function createCollectionFor(
        bytes32 _merkleRoot,
        address _controller,
        Plugin[] calldata _plugins,
        InitInfo[] calldata _calls
    ) external returns (address vault, address token);

    function createCollection(
        bytes32 _merkleRoot,
        Plugin[] calldata _plugins,
        InitInfo[] calldata _calls
    ) external returns (address vault, address token);

    function createInCollection(
        bytes32 _merkleRoot,
        address _token,
        Plugin[] calldata _plugins,
        InitInfo[] calldata _calls
    ) external returns (address vault);

    function factory() external view returns (address);

    function fNFT() external view returns (address);

    function fNFTImplementation() external view returns (address);

    function burn(address _from, uint256 _value) external;

    function mint(address _to, uint256 _value) external;

    function nextId(address) external view returns (uint256);

    function totalSupply(address _vault) external view returns (uint256);

    function uri(address _vault) external view returns (string memory);

    function vaultToToken(address)
        external
        view
        returns (address token, uint256 id);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import {IModule} from "../interfaces/IModule.sol";
import {Permission} from "../interfaces/IVaultRegistry.sol";

/// @title Module
/// @author Fractional Art
/// @notice Base module contract for converting vault permissions into leaf nodes
contract Module is IModule {
    /// @notice Gets the list of hashed leaf nodes used to generate a merkle tree
    /// @dev Leaf nodes are hashed permissions of the merkle tree
    /// @return leaves Hashed leaf nodes
    function getLeaves() external view returns (bytes32[] memory leaves) {
        Permission[] memory permissions = getPermissions();
        uint256 length = permissions.length;
        leaves = new bytes32[](length);
        unchecked {
            for (uint256 i; i < length; ++i) {
                leaves[i] = keccak256(abi.encode(permissions[i]));
            }
        }
    }

    /// @notice Gets the list of unhashed leaf nodes used to generate a merkle tree
    /// @dev Only used for third party APIs (Lanyard) that require unhashed leaves
    /// @return leaves Unhashed leaf nodes
    function getUnhashedLeaves() external view returns (bytes[] memory leaves) {
        Permission[] memory permissions = getPermissions();
        uint256 length = permissions.length;
        leaves = new bytes[](length);
        unchecked {
            for (uint256 i; i < length; ++i) {
                leaves[i] = abi.encode(permissions[i]);
            }
        }
    }

    /// @notice Gets the list of permissions installed on a vault
    /// @dev Intentionally left empty to be overridden by the module inheriting from this contract
    /// @return permissions List of vault permissions
    function getPermissions()
        public
        view
        virtual
        returns (Permission[] memory permissions)
    {}
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import {ERC721TokenReceiver} from "@rari-capital/solmate/src/tokens/ERC721.sol";
import {ERC1155TokenReceiver} from "@rari-capital/solmate/src/tokens/ERC1155.sol";

/// @title NFT Receiver
/// @author Fractional Art
/// @notice Plugin contract for handling receipts of non-fungible tokens
contract NFTReceiver is ERC721TokenReceiver, ERC1155TokenReceiver {
    /// @notice Handles the receipt of a single ERC721 token
    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external virtual override returns (bytes4) {
        return ERC721TokenReceiver.onERC721Received.selector;
    }

    /// @notice Handles the receipt of a single ERC1155 token type
    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes calldata
    ) external virtual override returns (bytes4) {
        return ERC1155TokenReceiver.onERC1155Received.selector;
    }

    /// @notice Handles the receipt of multiple ERC1155 token types
    function onERC1155BatchReceived(
        address,
        address,
        uint256[] calldata,
        uint256[] calldata,
        bytes calldata
    ) external virtual override returns (bytes4) {
        return ERC1155TokenReceiver.onERC1155BatchReceived.selector;
    }
}