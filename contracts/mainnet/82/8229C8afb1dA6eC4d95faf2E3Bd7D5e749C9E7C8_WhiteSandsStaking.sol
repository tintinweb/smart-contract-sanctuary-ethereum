//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.14;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";

contract WhiteSandsStaking is IERC721Receiver, Ownable {
    struct TokenInfo {
        uint32 collectionId;
        uint32 id;
        uint32 timestamp;
        address owner;
    }

    mapping(IERC721 => bool) public _acceptedCollections;
    mapping(IERC721 => uint32) public _collectionToId;
    mapping(IERC721 => mapping(uint256 => mapping(address => uint256)))
        public _indexOfTokens;
    mapping(IERC721 => mapping(uint256 => mapping(address => uint256)))
        public _indexOfTokensByOwners;
    mapping(IERC721 => mapping(uint256 => mapping(address => bool)))
        public _isStaked;
    mapping(address => TokenInfo[]) public _stakedByOwners;
    TokenInfo[] public _staked;
    IERC721[] public _collections;

    constructor(address[] memory collections) {
        for (uint256 i = 0; i < collections.length; i++) {
            acceptCollection(collections[i]);
        }
    }

    function acceptCollection(address collection_) public onlyOwner {
        IERC721 collection = IERC721(collection_);
        _collections.push(collection);
        _collectionToId[collection] = uint32(_collections.length) - 1;
        _acceptedCollections[collection] = true;
    }

    function removeCollection(address collection) external onlyOwner {
        delete _acceptedCollections[IERC721(collection)];
    }

    function stake(address[] calldata collections, uint256[] calldata ids)
        external
    {
        require(collections.length == ids.length, "!params");
        for (uint256 i = 0; i < collections.length; i++) {
            IERC721 collection = IERC721(collections[i]);
            uint256 id = ids[i];
            require(_acceptedCollections[collection], "!collection");
            _isStaked[collection][id][msg.sender] = true;
            TokenInfo memory ti = TokenInfo(
                _collectionToId[collection],
                uint32(id),
                // solhint-disable-next-line not-rely-on-time
                uint32(block.timestamp),
                msg.sender
            );
            _staked.push(ti);
            _indexOfTokens[collection][id][msg.sender] = _staked.length - 1;
            _stakedByOwners[msg.sender].push(ti);
            _indexOfTokensByOwners[collection][id][msg.sender] =
                _stakedByOwners[msg.sender].length -
                1;
            collection.safeTransferFrom(
                msg.sender,
                address(this),
                id,
                abi.encodePacked(WhiteSandsStaking.stake.selector)
            );
        }
    }

    function unstake(address[] calldata collections, uint256[] calldata ids)
        external
    {
        require(collections.length == ids.length, "!params");
        for (uint256 i = 0; i < collections.length; i++) {
            IERC721 collection = IERC721(collections[i]);
            uint256 id = ids[i];
            require(_isStaked[collection][id][msg.sender], "!staked");
            if (_stakedByOwners[msg.sender].length > 1) {
                uint256 index = _indexOfTokensByOwners[collection][id][
                    msg.sender
                ];
                TokenInfo memory last = _stakedByOwners[msg.sender][
                    _stakedByOwners[msg.sender].length - 1
                ];
                _stakedByOwners[msg.sender][index] = last;
                _indexOfTokensByOwners[_collections[last.collectionId]][
                    last.id
                ][msg.sender] = index;
            }
            _stakedByOwners[msg.sender].pop();
            if (_staked.length > 1) {
                uint256 index = _indexOfTokens[collection][id][msg.sender];
                TokenInfo memory last = _staked[_staked.length - 1];
                _staked[index] = last;
                _indexOfTokens[_collections[last.collectionId]][last.id][
                    last.owner
                ] = index;
            }
            _staked.pop();
            delete _indexOfTokens[collection][id][msg.sender];
            delete _indexOfTokensByOwners[collection][id][msg.sender];
            delete _isStaked[collection][id][msg.sender];
            collection.safeTransferFrom(address(this), msg.sender, id);
        }
    }

    function getStakedByOwner(address owner)
        external
        view
        returns (
            address[] memory,
            uint256[] memory,
            uint256[] memory
        )
    {
        uint256 count = _stakedByOwners[owner].length;
        address[] memory collections = new address[](count);
        uint256[] memory ids = new uint256[](count);
        uint256[] memory timestamps = new uint256[](count);
        for (uint256 i = 0; i < count; i++) {
            TokenInfo memory ti = _stakedByOwners[owner][i];
            collections[i] = address(_collections[ti.collectionId]);
            ids[i] = ti.id;
            timestamps[i] = ti.timestamp;
        }
        return (collections, ids, timestamps);
    }

    function getStaked()
        external
        view
        returns (
            address[] memory,
            uint256[] memory,
            address[] memory,
            uint256[] memory
        )
    {
        return getStakedFrom(0, _staked.length);
    }

    function getStakedFrom(uint256 from, uint256 count)
        public
        view
        returns (
            address[] memory,
            uint256[] memory,
            address[] memory,
            uint256[] memory
        )
    {
        address[] memory collections = new address[](count);
        uint256[] memory ids = new uint256[](count);
        address[] memory owners = new address[](count);
        uint256[] memory timestamps = new uint256[](count);
        for (uint256 i = from; i < count; i++) {
            TokenInfo memory ti = _staked[i];
            collections[i] = address(_collections[ti.collectionId]);
            ids[i] = ti.id;
            owners[i] = ti.owner;
            timestamps[i] = ti.timestamp;
        }
        return (collections, ids, owners, timestamps);
    }

    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata data
    ) external pure override returns (bytes4) {
        require(
            keccak256(data) ==
                keccak256(abi.encodePacked(WhiteSandsStaking.stake.selector)),
            "!invalid"
        );
        return IERC721Receiver.onERC721Received.selector;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721.sol)

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
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
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
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
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