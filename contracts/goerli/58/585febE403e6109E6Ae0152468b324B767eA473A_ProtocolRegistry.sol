// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "./Registry.sol";
import "./interfaces/IERC4907.sol";

contract ProtocolRegistry is Registry {
    mapping(IERC4907 => IERC721) public override originalNftAddr; // wrapper -> original
    mapping(IERC721 => IERC4907) public override wrapperNftAddr;  // original -> wrapper

    function registerRentContract(
        string memory nodeName_,
        address owner_,
        IERC4907 contractAddr_,
        IERC721 originalNftAddr_
    ) external virtual override {
        require(address(contractAddr_) != address(0) && address(originalNftAddr_) != address(0), "ProtocolRegistry: Zero address");
        _setRecord(nodeName_, owner_, address(contractAddr_));
        originalNftAddr[contractAddr_] = originalNftAddr_;
        wrapperNftAddr[originalNftAddr_] = contractAddr_;
    }

    function _setContract(string memory nodeName_, address newWrapper_)
    internal
    virtual
    override
    {
        IERC4907 currentWrapper = IERC4907(records[keccak256(abi.encode(nodeName_))].addr);
        if (address(currentWrapper) != address(0)) {
            IERC721 original = originalNftAddr[currentWrapper];
            originalNftAddr[IERC4907(newWrapper_)] = original;
            delete originalNftAddr[currentWrapper];
            wrapperNftAddr[original] = IERC4907(newWrapper_);
        }
        return super._setContract(nodeName_, newWrapper_);
    }
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./interfaces/IRegistry.sol";

abstract contract Registry is IRegistry {
    struct Record {
        address owner;
        address addr;
    }

    mapping(bytes32 => Record) public records;

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyRecordOwner(string memory nodeName_) {
        require(
            records[keccak256(abi.encode(nodeName_))].owner == msg.sender,
            "Ownable: caller is not the record owner"
        );
        _;
    }

    /**
    * @dev Adds a new record for a node.
     * @param nodeName_ The node to create.
     * @param owner_ The address of the new owner.
     * @param contractAddr_ The address of the destination contract.
     */
    function _setRecord(
        string memory nodeName_,
        address owner_,
        address contractAddr_
    ) internal virtual {
        require(!recordExists(nodeName_), "Node already exists");
        _setOwner(nodeName_, owner_);
        _setContract(nodeName_, contractAddr_);
        emit NewRecord(nodeName_, owner_, contractAddr_);
    }

    /**
     * @dev Transfers ownership of a node to a new address. May only be called by the current owner of the node.
     * @param nodeName_ The node to transfer ownership of.
     * @param owner_ The address of the new owner.
     */
    function setOwner(string memory nodeName_, address owner_)
    public
    virtual
    override
    onlyRecordOwner(nodeName_)
    {
        _setOwner(nodeName_, owner_);
        emit Transfer(nodeName_, owner_);
    }

    /**
     * @dev Sets the resolver address for the specified node.
     * @param nodeName_ The node to update.
     * @param contractAddr_ The address of the resolver.
     */
    function setContract(string memory nodeName_, address contractAddr_)
    public
    virtual
    override
    onlyRecordOwner(nodeName_)
    {
        emit NewAddress(nodeName_, contractAddr_);
        records[keccak256(abi.encode(nodeName_))].addr = contractAddr_;
    }

    /**
     * @dev Returns the address that owns the specified node.
     * @param nodeName_ The specified node.
     * @return address of the owner.
     */
    function getOwner(string memory nodeName_)
    public
    view
    virtual
    override
    returns (address)
    {
        address addr = records[keccak256(abi.encode(nodeName_))].owner;
        if (addr == address(this)) {
            return address(0x0);
        }

        return addr;
    }

    /**
     * @dev Returns the address of the resolver for the specified node.
     * @param nodeName_ The specified node.
     * @return address of the resolver.
     */
    function getContract(string memory nodeName_)
    external
    view
    virtual
    override
    returns (address)
    {
        return records[keccak256(abi.encode(nodeName_))].addr;
    }

    /**
     * @dev Returns whether a record has been imported to the registry.
     * @param nodeName_ The specified node.
     * @return Bool if record exists
     */
    function recordExists(string memory nodeName_)
    public
    view
    virtual
    override
    returns (bool)
    {
        return records[keccak256(abi.encode(nodeName_))].owner != address(0x0);
    }

    function _setOwner(string memory nodeName_, address owner_) internal virtual {
        records[keccak256(abi.encode(nodeName_))].owner = owner_;
    }

    function _setContract(string memory nodeName_, address contractAddr_) internal virtual {
        records[keccak256(abi.encode(nodeName_))].addr = contractAddr_;
    }
}

// SPDX-License-Identifier: CC0-1.0

pragma solidity ^0.8.0;

interface IERC4907 {
  // Logged when the user of a token assigns a new user or updates expires
  /// @notice Emitted when the `user` of an NFT or the `expires` of the `user` is changed
  /// The zero address for user indicates that there is no user address
  event UpdateUser(uint256 indexed tokenId, address indexed user, uint64 expires);

  /// @notice set the user and expires of a NFT
  /// @dev The zero address indicates there is no user
  /// Throws if `tokenId` is not valid NFT
  /// @param user  The new user of the NFT
  /// @param expires  UNIX timestamp, The new user could use the NFT before expires
  function setUser(
    uint256 tokenId,
    address user,
    uint64 expires
  ) external;

  /// @notice Get the user address of an NFT
  /// @dev The zero address indicates that there is no user or the user is expired
  /// @param tokenId The NFT to get the user address for
  /// @return The user address for this NFT
  function userOf(uint256 tokenId) external view returns (address);

  /// @notice Get the user expires of an NFT
  /// @dev The zero value indicates that there is no user
  /// @param tokenId The NFT to get the user expires for
  /// @return The user expires for this NFT
  function userExpires(uint256 tokenId) external view returns (uint256);
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
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "./IERC4907.sol";

interface IRegistry {
    // Logged when new record is created.
    event NewRecord(string indexed nodeName, address owner, address contractAddr);

    // Logged when the owner of a node transfers ownership to a new account.
    event Transfer(string indexed nodeName, address owner);

    // Logged when the resolver for a node changes.
    event NewAddress(string indexed nodeName, address contractAddr);

    function setContract(string memory nodeName_, address contractAddr_) external;

    function setOwner(string memory nodeName_, address owner_) external;

    function getOwner(string memory nodeName_) external view returns (address);

    function getContract(string memory nodeName_) external view returns (address);

    function recordExists(string memory nodeName_) external view returns (bool);

    function registerRentContract(
        string memory nodeName_,
        address owner_,
        IERC4907 contractAddr_,
        IERC721 originalNftAddr_
    ) external;

    function originalNftAddr(IERC4907 wrapper_) external view returns(IERC721); // wrapper -> original
    function wrapperNftAddr(IERC721 original_) external view returns(IERC4907); // original -> wrapper
}