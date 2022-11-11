import "../registry/ENS.sol";
import "./IBaseRegistrar.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

interface IBaseRegistrar is IERC721 {
    event ControllerAdded(address indexed controller);
    event ControllerRemoved(address indexed controller);
    event NameMigrated(
        uint256 indexed id,
        address indexed owner,
        uint256 expires
    );
    event NameRegistered(
        uint256 indexed id,
        address indexed owner,
        uint256 expires
    );
    event NameRenewed(uint256 indexed id, uint256 expires);

    // Authorises a controller, who can register and renew domains.
    function addController(address controller) external;

    // Revoke controller permission for an address.
    function removeController(address controller) external;

    // Set the resolver for the TLD this registrar manages.
    function setResolver(address resolver) external;

    // Returns the expiration timestamp of the specified label hash.
    function nameExpires(uint256 id) external view returns (uint256);

    // Returns true iff the specified name is available for registration.
    function available(uint256 id) external view returns (bool);

    /**
     * @dev Register a name.
     */
    function register(
        uint256 id,
        address owner,
        uint256 duration
    ) external returns (uint256);

    function renew(uint256 id, uint256 duration) external returns (uint256);

    /**
     * @dev Reclaim ownership of a name in ENS, if you own it in the registrar.
     */
    function reclaim(uint256 id, address owner) external;
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
    event ApprovalForAll(
        address indexed owner,
        address indexed operator,
        bool approved
    );

    function setRecord(
        bytes32 node,
        address owner,
        address resolver,
        uint64 ttl
    ) external;

    function setSubnodeRecord(
        bytes32 node,
        bytes32 label,
        address owner,
        address resolver,
        uint64 ttl
    ) external;

    function setSubnodeOwner(
        bytes32 node,
        bytes32 label,
        address owner
    ) external returns (bytes32);

    function setResolver(bytes32 node, address resolver) external;

    function setOwner(bytes32 node, address owner) external;

    function setTTL(bytes32 node, uint64 ttl) external;

    function setApprovalForAll(address operator, bool approved) external;

    function owner(bytes32 node) external view returns (address);

    function resolver(bytes32 node) external view returns (address);

    function ttl(bytes32 node) external view returns (uint64);

    function recordExists(bytes32 node) external view returns (bool);

    function isApprovedForAll(address owner, address operator)
        external
        view
        returns (bool);
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
     * WARNING: Note that the caller is responsible to confirm that the recipient is capable of receiving ERC721
     * or else they may be permanently lost. Usage of {safeTransferFrom} prevents loss, though the caller must
     * understand this adds an external call which potentially creates a reentrancy vulnerability.
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

import {MerkleBase} from "../utils/MerkleBase.sol";
import {Protoform} from "../protoforms/Protoform.sol";
import {TNSRegistrar} from "./modules/TNSRegistrar.sol";
import {TNSReverse} from "./modules/TNSReverse.sol";

import {IBaseRegistrar} from "@ensdomains/contracts/ethregistrar/IBaseRegistrar.sol";
import {IENS} from "./interfaces/IENS.sol";
import {IPublicResolver} from "./interfaces/IPublicResolver.sol";
import {ITNSProtoform, InitInfo, Plugin} from "./interfaces/ITNSProtoform.sol";
import {ITNSRegistrar} from "./interfaces/ITNSRegistrar.sol";
import {IVaultRegistry} from "../interfaces/IVaultRegistry.sol";

/// @title TNSProtoform
/// @author Tessera
/// @notice Protoform contract for deploymening new vaults with a fixed supply and distribution mechanism
contract TNSProtoform is ITNSProtoform, MerkleBase, Protoform, TNSReverse {
    /// @notice Address of VaultRegistry contract
    address public immutable registry;
    /// @notice Address of ENSRegistry contract
    address public immutable ens;
    /// @notice Address of BaseRegistrar contract
    address public immutable base;
    /// @notice Address of TNSRegistrar contract
    address public immutable registrar;
    /// @notice Minimum expiration time of ENS registration
    uint256 public constant EXPIRATION = 365 days;
    /// @notice Base node derived from keccak(bytes('eth'))
    bytes32 public constant BASE_NODE =
        0x93cdeb708b7545dc668eb9280176169d1c33cfd8ed6f04690a0bcc88a93fc4ae;

    /// @notice Initializes registry, registrar and ENS contracts
    constructor(
        address _registrar,
        address _base,
        address _register
    ) TNSReverse(_register) {
        registrar = _registrar;
        base = _base;
        ens = ITNSRegistrar(registrar).ens();
        registry = ITNSRegistrar(registrar).registry();
    }

    /// @notice Deploys a new vault, transfers ownership of ENS registration and mints supply of Raes
    /// @param _label Individual component of a name
    /// @param _duration Length of time for the auction
    /// @param _initData Initialization data to be executed on deployment
    /// @param _modules List of module contracts activated on the vault
    /// @param _plugins List of plugin contracts installed on the vault
    /// @return vault Address of the deployed vault
    function deployVault(
        string memory _label,
        uint256 _duration,
        bytes memory _initData,
        address[] memory _modules,
        Plugin[] memory _plugins
    ) external returns (address vault) {
        // Concatenates label with top level domain to create ENS identifier
        string memory name = string.concat(_label, ".eth");
        // Derives tokenId from cryptographic hash of label
        bytes32 labelHash = keccak256(bytes(_label));
        uint256 tokenId = uint256(labelHash);
        // Generates cryptographic hash that uniquely identifies the name
        bytes32 node = keccak256(abi.encodePacked(BASE_NODE, labelHash));

        // Creates new vault and retrieves merkle proof for setName
        bytes32[] memory setNameProof;
        (vault, setNameProof) = _create(_initData, _modules, _plugins);

        // Transfers ENS to vault
        _transfer(vault, node, tokenId, _duration);

        // Sets ENS identifier as primary name of vault
        _setPrimaryName(vault, name, setNameProof);

        // Registers vault with node on TNSRegistrar contract
        ITNSRegistrar(registrar).registerNode(vault, node);
    }

    /// @dev Creates new vault and initializes data on deployment
    function _create(
        bytes memory _initData,
        address[] memory _modules,
        Plugin[] memory _plugins
    ) internal returns (address vault, bytes32[] memory setNameProof) {
        // Decodes target contract and execution data from bytecode
        (address target, bytes memory data) = abi.decode(
            _initData,
            (address, bytes)
        );

        // Generates merkle root from list of modules
        bytes32[] memory leafNodes = generateMerkleTree(_modules);
        bytes32 merkleRoot = getRoot(leafNodes);

        // Sets up merkle proofs and initialization data for vault deployment
        bytes32[] memory vrgdaProof = getProof(leafNodes, 0);
        setNameProof = getProof(leafNodes, 2);
        InitInfo[] memory _calls = new InitInfo[](1);
        _calls[0] = InitInfo(target, data, vrgdaProof);

        // Creates new vault through the registry
        vault = IVaultRegistry(registry).create(merkleRoot, _plugins, _calls);

        // Emits event for list of modules activated on the vault
        emit ActiveModules(vault, _modules);
    }

    /// @dev Transfers ownership of the ENS registration
    function _transfer(
        address _vault,
        bytes32 _node,
        uint256 _tokenId,
        uint256 _duration
    ) internal {
        // Calculates threshold time for ENS expiration
        uint256 threshold = block.timestamp + EXPIRATION + _duration;
        // Reverts if expiration of ENS token is less than threshold period
        uint256 nameExpires = IBaseRegistrar(base).nameExpires(_tokenId);
        if (nameExpires < threshold)
            revert InvalidExpiration(nameExpires, threshold);

        // Sets vault as address record through resolver
        address resolver = IENS(ens).resolver(_node);
        IPublicResolver(resolver).setAddr(_node, _vault);

        // Sets vault as owner of the ENS record
        IENS(ens).setOwner(_node, _vault);

        // Transfers ENS registration to the vault
        IBaseRegistrar(base).safeTransferFrom(msg.sender, _vault, _tokenId);
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

    function setApprovalForAll(address _operator, bool _approved) external;

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

/// @dev Interface for PublicResolver contract
interface IPublicResolver {
    function setAddr(bytes32 node, address a) external;

    function setApprovalForAll(address _operator, bool _approved) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import {Plugin, InitInfo} from "../../interfaces/IVault.sol";
import {Permission} from "../../interfaces/IVaultRegistry.sol";

/// @dev Interface for TNSProtoform contract
interface ITNSProtoform {
    error InvalidExpiration(uint256 _current, uint256 _required);

    function BASE_NODE() external view returns (bytes32);

    function EXPIRATION() external view returns (uint256);

    function base() external view returns (address);

    function deployVault(
        string memory _label,
        uint256 _duration,
        bytes memory _initData,
        address[] memory _modules,
        Plugin[] memory _plugins
    ) external returns (address vault);

    function ens() external view returns (address);

    function registrar() external view returns (address);

    function registry() external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

// @dev Interface for TNSRegister target contract
interface ITNSRegister {
    function setSubnode(
        bytes32 _node,
        bytes32 _label,
        address _owner,
        address _resolver
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

import {Permission} from "../../interfaces/IVaultRegistry.sol";
import {IModule} from "../../interfaces/IModule.sol";

/// @dev Interface for TNSMinter module contract
interface ITNSReverse is IModule {
    function getPermissions()
        external
        view
        returns (Permission[] memory permissions);

    function register() external view returns (address);
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
            (parentNode, labelHash, _owner, resolver)
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

import {Module} from "../../modules/Module.sol";
import {Permission} from "../../interfaces/IVaultRegistry.sol";

import {ITNSRegister} from "../interfaces/ITNSRegister.sol";
import {ITNSReverse} from "../interfaces/ITNSReverse.sol";
import {IVault} from "../../interfaces/IVault.sol";

/// @title TNSReverse
/// @author Tessera
/// @notice Module contract for setting the ENS primary name
contract TNSReverse is ITNSReverse, Module {
    /// @notice Address of the TNSRegister target contract
    address public immutable register;

    /// @notice Initializes register contract
    constructor(address _register) {
        register = _register;
    }

    /// @notice Gets the list of permissions installed on a vault
    /// @dev Permissions consist of a module contract, target contract, and function selector
    /// @return permissions A list of Permission Structs
    function getPermissions()
        public
        view
        override(ITNSReverse, Module)
        returns (Permission[] memory permissions)
    {
        permissions = new Permission[](1);
        // setName function selector from TNSRegister contract
        permissions[0] = Permission(
            address(this),
            register,
            ITNSRegister.setName.selector
        );
    }

    /// @dev Sets the primary name of the vault as the ENS identifier
    function _setPrimaryName(
        address _vault,
        string memory _name,
        bytes32[] memory _setNameProof
    ) internal {
        bytes memory data = abi.encodeCall(ITNSRegister.setName, (_name));
        IVault(payable(_vault)).execute(register, data, _setNameProof);
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

/// @dev Interface for generic Protoform contract
interface IProtoform {
    /// @dev Event log for modules that are enabled on a vault
    /// @param _vault The vault deployed
    /// @param _modules The modules being activated on deployed vault
    event ActiveModules(address indexed _vault, address[] _modules);

    function generateMerkleTree(address[] memory _modules)
        external
        view
        returns (bytes32[] memory tree);

    function generateUnhashedMerkleTree(address[] memory _modules)
        external
        view
        returns (bytes[] memory tree);
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

import {IModule} from "../interfaces/IModule.sol";
import {IProtoform} from "../interfaces/IProtoform.sol";
import "../utils/MerkleBase.sol";

/// @title Protoform
/// @author Fractional Art
/// @notice Base protoform contract for generating merkle trees
contract Protoform is IProtoform, MerkleBase {
    /// @notice Generates a merkle tree from the hashed permissions of the given modules
    /// @param _modules List of module contracts
    /// @return tree Merkle tree of hashed leaf nodes
    function generateMerkleTree(address[] memory _modules)
        public
        view
        returns (bytes32[] memory tree)
    {
        uint256 counter;
        uint256 modulesLength = _modules.length;
        uint256 treeSize = _getTreeSize(_modules, modulesLength);
        tree = new bytes32[](treeSize);
        unchecked {
            /* _sortList(_modules, modulesLength); */
            for (uint256 i; i < modulesLength; ++i) {
                bytes32[] memory leaves = IModule(_modules[i]).getLeaves();
                uint256 leavesLength = leaves.length;
                for (uint256 j; j < leavesLength; ++j) {
                    tree[counter++] = leaves[j];
                }
            }
        }
    }

    /// @notice Generates a merkle tree from the unhashed permissions of the given modules
    /// @dev Only used for third party APIs (Lanyard) that require unhashed leaves
    /// @param _modules List of module contracts
    /// @return tree Merkle tree of unhashed leaf nodes
    function generateUnhashedMerkleTree(address[] memory _modules)
        public
        view
        returns (bytes[] memory tree)
    {
        uint256 counter;
        uint256 modulesLength = _modules.length;
        uint256 treeSize = _getTreeSize(_modules, modulesLength);
        tree = new bytes[](treeSize);
        unchecked {
            /* _sortList(_modules, modulesLength); */
            for (uint256 i; i < modulesLength; ++i) {
                bytes[] memory leaves = IModule(_modules[i])
                    .getUnhashedLeaves();
                uint256 leavesLength = leaves.length;
                for (uint256 j; j < leavesLength; ++j) {
                    tree[counter++] = leaves[j];
                }
            }
        }
    }

    /// @dev Gets the size of a merkle tree based on the total permissions across all modules
    /// @param _modules List of module contracts
    /// @param _length Size of modules array
    /// @return size Total size of the merkle tree
    function _getTreeSize(address[] memory _modules, uint256 _length)
        internal
        view
        returns (uint256 size)
    {
        unchecked {
            for (uint256 i; i < _length; ++i) {
                size += IModule(_modules[i]).getLeaves().length;
            }
        }
    }

    /// @dev Sorts the list of modules in ascending order
    function _sortList(address[] memory _modules, uint256 _length)
        internal
        pure
    {
        for (uint256 i; i < _length; ++i) {
            for (uint256 j = i + 1; j < _length; ++j) {
                if (_modules[i] > _modules[j]) {
                    (_modules[i], _modules[j]) = (_modules[j], _modules[i]);
                }
            }
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

/// @title Merkle Base
/// @author Modified from Murky (https://github.com/dmfxyz/murky/blob/main/src/common/MurkyBase.sol)
/// @notice Utility contract for generating merkle roots and verifying proofs
abstract contract MerkleBase {
    constructor() {}

    /// @notice Hashes two leaf pairs
    /// @param _left Node on left side of tree level
    /// @param _right Node on right side of tree level
    /// @return data Result hash of node params
    function hashLeafPairs(bytes32 _left, bytes32 _right)
        public
        pure
        returns (bytes32 data)
    {
        // Return opposite node if checked node is of bytes zero value
        if (_left == bytes32(0)) return _right;
        if (_right == bytes32(0)) return _left;

        assembly {
            // TODO: This can be aesthetically simplified with a switch. Not sure it will
            // save much gas but there are other optimizations to be had in here.
            if or(lt(_left, _right), eq(_left, _right)) {
                mstore(0x0, _left)
                mstore(0x20, _right)
            }
            if gt(_left, _right) {
                mstore(0x0, _right)
                mstore(0x20, _left)
            }
            data := keccak256(0x0, 0x40)
        }
    }

    /// @notice Verifies the merkle proof of a given value
    /// @param _root Hash of merkle root
    /// @param _proof Merkle proof
    /// @param _valueToProve Leaf node being proven
    /// @return Status of proof verification
    function verifyProof(
        bytes32 _root,
        bytes32[] memory _proof,
        bytes32 _valueToProve
    ) public pure returns (bool) {
        // proof length must be less than max array size
        bytes32 rollingHash = _valueToProve;
        unchecked {
            for (uint256 i = 0; i < _proof.length; ++i) {
                rollingHash = hashLeafPairs(rollingHash, _proof[i]);
            }
        }
        return _root == rollingHash;
    }

    /// @notice Generates the merkle root of a tree
    /// @param _data Leaf nodes of the merkle tree
    /// @return Hash of merkle root
    function getRoot(bytes32[] memory _data) public pure returns (bytes32) {
        require(_data.length > 1, "wont generate root for single leaf");
        while (_data.length > 1) {
            _data = hashLevel(_data);
        }
        return _data[0];
    }

    /// @notice Generates the merkle proof for a leaf node in a given tree
    /// @param _data Leaf nodes of the merkle tree
    /// @param _node Index of the node in the tree
    /// @return proof Merkle proof
    function getProof(bytes32[] memory _data, uint256 _node)
        public
        pure
        returns (bytes32[] memory proof)
    {
        require(_data.length > 1, "wont generate proof for single leaf");
        // The size of the proof is equal to the ceiling of log2(numLeaves)
        uint256 size = log2ceil_naive(_data.length);
        bytes32[] memory result = new bytes32[](size);
        uint256 pos;
        uint256 counter;

        // Two overflow risks: node, pos
        // node: max array size is 2**256-1. Largest index in the array will be 1 less than that. Also,
        // for dynamic arrays, size is limited to 2**64-1
        // pos: pos is bounded by log2(data.length), which should be less than type(uint256).max
        while (_data.length > 1) {
            unchecked {
                if (_node % 2 == 1) {
                    result[pos] = _data[_node - 1];
                } else if (_node + 1 == _data.length) {
                    result[pos] = bytes32(0);
                    ++counter;
                } else {
                    result[pos] = _data[_node + 1];
                }
                ++pos;
                _node = _node / 2;
            }
            _data = hashLevel(_data);
        }

        // Dynamic array to filter out address(0) since proof size is rounded up
        // This is done to return the actual proof size of the indexed node
        uint256 offset;
        proof = new bytes32[](size - counter);
        unchecked {
            for (uint256 i; i < size; ++i) {
                if (result[i] != bytes32(0)) {
                    proof[i - offset] = result[i];
                } else {
                    ++offset;
                }
            }
        }
    }

    /// @dev Hashes nodes at the given tree level
    /// @param _data Nodes at the current level
    /// @return result Hashes of nodes at the next level
    function hashLevel(bytes32[] memory _data)
        private
        pure
        returns (bytes32[] memory result)
    {
        // Function is private, and all internal callers check that data.length >=2.
        // Underflow is not possible as lowest possible value for data/result index is 1
        // overflow should be safe as length is / 2 always.
        unchecked {
            uint256 length = _data.length;
            if (length & 0x1 == 1) {
                result = new bytes32[]((length >> 1) + 1);
                result[result.length - 1] = hashLeafPairs(
                    _data[length - 1],
                    bytes32(0)
                );
            } else {
                result = new bytes32[](length >> 1);
            }

            // pos is upper bounded by data.length / 2, so safe even if array is at max size
            uint256 pos;
            for (uint256 i; i < length - 1; i += 2) {
                result[pos] = hashLeafPairs(_data[i], _data[i + 1]);
                ++pos;
            }
        }
    }

    /// @notice Calculates proof size based on size of tree
    /// @dev Note that x is assumed > 0 and proof size is not precise
    /// @param x Size of the merkle tree
    /// @return ceil Rounded value of proof size
    function log2ceil_naive(uint256 x) public pure returns (uint256 ceil) {
        uint256 pOf2;
        // If x is a power of 2, then this function will return a ceiling
        // that is 1 greater than the actual ceiling. So we need to check if
        // x is a power of 2, and subtract one from ceil if so.
        assembly {
            // we check by seeing if x == (~x + 1) & x. This applies a mask
            // to find the lowest set bit of x and then checks it for equality
            // with x. If they are equal, then x is a power of 2.

            /* Example
                x has single bit set
                x := 0000_1000
                (~x + 1) = (1111_0111) + 1 = 1111_1000
                (1111_1000 & 0000_1000) = 0000_1000 == x
                x has multiple bits set
                x := 1001_0010
                (~x + 1) = (0110_1101 + 1) = 0110_1110
                (0110_1110 & x) = 0000_0010 != x
            */

            // we do some assembly magic to treat the bool as an integer later on
            pOf2 := eq(and(add(not(x), 1), x), x)
        }

        // if x == type(uint256).max, than ceil is capped at 256
        // if x == 0, then pO2 == 0, so ceil won't underflow
        unchecked {
            while (x > 0) {
                x >>= 1;
                ceil++;
            }
            ceil -= pOf2;
        }
    }
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