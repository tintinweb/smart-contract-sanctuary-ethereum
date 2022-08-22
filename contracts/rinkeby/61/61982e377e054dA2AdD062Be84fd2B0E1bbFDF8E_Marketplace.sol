//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./IMarketplace.sol";
import "../wrappers/WrapperFactory.sol";

contract Marketplace is IMarketplace, WrapperFactory, ReentrancyGuard {
    mapping (address => mapping (uint256 => Listing)) private _listings;
    mapping (address => uint256) private _proceeds;

    modifier isNotListed(address tokenAddress, uint256 tokenId) {
        Listing memory listing = _listings[tokenAddress][tokenId];
        if (listing.price != 0) revert AlreadyListed(tokenAddress, tokenId);
        _;
    }

    modifier isListed(address tokenAddress, uint256 tokenId) {
        Listing memory listing = _listings[tokenAddress][tokenId];
        if (listing.price == 0) revert NotListed(tokenAddress, tokenId);
        _;
    }

    modifier isOwner(address tokenAddress, uint256 tokenId, address spender) {
        Listing memory listing = _listings[tokenAddress][tokenId];
        if (listing.seller != spender) revert NotOwner();
        _;
    }

    function getListing(address tokenAddress, uint256 tokenId) external override view returns (Listing memory) {
        return _listings[tokenAddress][tokenId];
    }

    function getProcees(address seller) external override view returns (uint256) {
        return _proceeds[seller];
    }

    function list(address tokenAddress, uint256 tokenId, uint256 price) external override isNotListed(tokenAddress, tokenId) {
        if (price == 0) revert PriceIsZero();

        IWrapper wrapper = _createWrapper(tokenAddress, tokenId, msg.sender);
        _listings[tokenAddress][tokenId] = Listing(price, msg.sender, wrapper);
        emit Listed(msg.sender, tokenAddress, tokenId, price);
    }

    function update(address tokenAddress, uint256 tokenId, uint256 price) external override isListed(tokenAddress, tokenId) isOwner(tokenAddress, tokenId, msg.sender) {
        if (price == 0) revert PriceIsZero();

        _listings[tokenAddress][tokenId].price = price;
        emit Listed(msg.sender, tokenAddress, tokenId, price);
    }

    function remove(address tokenAddress, uint256 tokenId) external override {
        Listing memory listing = _listings[tokenAddress][tokenId];
        if (msg.sender != address(listing.wrapper)) revert NotWrapper();

        delete _listings[tokenAddress][tokenId];
    }

    function cancel(address tokenAddress, uint256 tokenId) external override isListed(tokenAddress, tokenId) isOwner(tokenAddress, tokenId, msg.sender) {
        Listing memory listing = _listings[tokenAddress][tokenId];
        listing.wrapper.unwrap(msg.sender);
        emit Canceled(msg.sender, tokenAddress, tokenId);
    }

    function buy(address tokenAddress, uint256 tokenId) external payable override isListed(tokenAddress, tokenId) nonReentrant {
        Listing memory listing = _listings[tokenAddress][tokenId];
        if (msg.value < listing.price) revert NotEnoughFunds();

        _proceeds[listing.seller] += msg.value;
        listing.wrapper.unwrap(msg.sender);
        emit Bought(msg.sender, tokenAddress, tokenId);
    }

    function withdraw() external override {
        uint256 proceed = _proceeds[msg.sender];
        if (proceed == 0) revert NotEnoughFunds();

        _proceeds[msg.sender] = 0;
        (bool success, ) = payable(msg.sender).call{value: proceed}("");
        require(success);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "../wrappers/IWrapper.sol";

interface IMarketplace {
    struct Listing {
        uint256 price;
        address seller;
        IWrapper wrapper;
    }

    error PriceIsZero();
    error NotEnoughFunds();
    error NotOwner();
    error NotWrapper();
    error AlreadyListed(address tokenAddress, uint256 tokenId);
    error NotListed(address tokenAddress, uint256 tokenId);

    event Listed(address indexed seller, address indexed tokenAddress, uint256 indexed tokenId, uint256 price);
    event Canceled(address indexed seller, address indexed tokenAddress, uint256 indexed tokenId);
    event Bought(address indexed buyer, address indexed tokenAddress, uint256 indexed tokenId);

    function getListing(address tokenAddress, uint256 tokenId) external view returns (Listing memory);

    function getProcees(address seller) external view returns (uint256);

    function list(address tokenAddress, uint256 tokenId, uint256 price) external;

    function update(address tokenAddress, uint256 tokenId, uint256 price) external;

    function remove(address tokenAddress, uint256 tokenId) external;

    function cancel(address tokenAddress, uint256 tokenId) external;

    function buy(address tokenAddress, uint256 tokenId) external payable;

    function withdraw() external;

}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import { Clones } from "@openzeppelin/contracts/proxy/Clones.sol";
import "./IWrapper.sol";
import "./ERC721Wrapper.sol";
import "./ERC1155Wrapper.sol";

abstract contract WrapperFactory {
    error NotApproved();
    error UnsupportedInterface();

    bytes4 private constant ERC721_INTERFACE_ID = 0x80ac58cd;
    address private immutable erc721WrapperAddress;
    bytes4 private constant ERC1155_INTERFACE_ID = 0xd9b67a26;
    address private immutable erc1155WrapperAddress;

    constructor() {
        erc721WrapperAddress = address(new ERC721Wrapper());
        erc1155WrapperAddress = address(new ERC1155Wrapper());
    }

    function _createERC721Wrapper(address tokenAddress, uint256 tokenId, address owner) private returns (IWrapper wrapper) {
        IERC721 token = IERC721(tokenAddress);
        if (!token.isApprovedForAll(owner, address(this))) revert NotApproved();

        wrapper = IWrapper(Clones.clone(erc721WrapperAddress));
        wrapper.initialize(tokenAddress, tokenId, owner);
        token.safeTransferFrom(owner, address(wrapper), tokenId);
    }

    function _createERC1155Wrapper(address tokenAddress, uint256 tokenId, address owner) private returns (IWrapper wrapper) {
        IERC1155 token = IERC1155(tokenAddress);
        if (!token.isApprovedForAll(owner, address(this))) revert NotApproved();

        wrapper = IWrapper(Clones.clone(erc1155WrapperAddress));
        wrapper.initialize(tokenAddress, tokenId, owner);
        token.safeTransferFrom(owner, address(wrapper), tokenId, 1, "");
    }

    function _createWrapper(address tokenAddress, uint256 tokenId, address owner) internal returns (IWrapper) {
        IERC165 token = IERC165(tokenAddress);
        if (token.supportsInterface(ERC721_INTERFACE_ID)) {
            return _createERC721Wrapper(tokenAddress, tokenId, owner);
        } else if (token.supportsInterface(ERC1155_INTERFACE_ID)) {
            return _createERC1155Wrapper(tokenAddress, tokenId, owner);
        }

        revert UnsupportedInterface();
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";

interface IWrapper is IERC721Metadata {
    error NotInitializer();
    error NotInitialized();
    error AlreadyInitialized();
    error ZeroAddress();
    error NonExistingToken();
    error NonExistingOwner();
    error ApproveForOwner();
    error NotOwner();
    error NotOwnerOrApproved();
    error NotOwnerOrInitializer();
    error NotERC721Receiver();
    error IncorrectToken();

    function tokenAddress() external view returns (address);

    function tokenId() external view returns (uint256);

    function owner() external view returns (address);

    function initialize(address tokenAddress_, uint256 tokenId_, address owner_) external;

    function unwrap(address to) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {
    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
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
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165 {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must be have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/Clones.sol)

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

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import "./BaseWrapper.sol";

contract ERC721Wrapper is BaseWrapper, IERC721Receiver {
    function tokenURI(uint256 tokenId_) external view override isInitialized isExistingToken(tokenId_) returns (string memory) {
        return IERC721Metadata(_tokenAddress).tokenURI(tokenId_);
    }

    function onERC721Received(address operator, address from, uint256 tokenId_, bytes memory) external view override isInitialized returns (bytes4) {
        if (operator != _initializer || from != _owner || tokenId_ != _tokenId) revert IncorrectToken();

        return this.onERC721Received.selector;
    }

    function _transfer(address to) internal override {
        IERC721Metadata(_tokenAddress).safeTransferFrom(address(this), to, _tokenId);
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/IERC1155MetadataURI.sol";
import "./BaseWrapper.sol";

contract ERC1155Wrapper is BaseWrapper, IERC1155Receiver {
    error BatchUnsupported();

    function tokenURI(uint256 tokenId_) external view override isInitialized isExistingToken(tokenId_) returns (string memory) {
        return IERC1155MetadataURI(_tokenAddress).uri(tokenId_);
    }

    function supportsInterface(bytes4 interfaceId) public view override(BaseWrapper, IERC165) returns (bool) {
        return interfaceId == type(IERC1155Receiver).interfaceId || super.supportsInterface(interfaceId);
    }

    function onERC1155Received(address operator, address from, uint256 tokenId_, uint256, bytes memory) external view override isInitialized returns (bytes4) {
        if (operator != _initializer || from != _owner || tokenId_ != _tokenId) revert IncorrectToken();

        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(address, address, uint256[] memory, uint256[] memory, bytes memory) external view override isInitialized returns (bytes4) {
        revert BatchUnsupported();
    }

    function _transfer(address to) internal override {
        IERC1155(_tokenAddress).safeTransferFrom(address(this), to, _tokenId, 1, "");
    }
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

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "./IWrapper.sol";
import "../marketplace/IMarketplace.sol";

abstract contract BaseWrapper is IWrapper {
    string private constant NAME = "Wrapper";
    string private constant SYMBOL = "WRAPPER";
    address internal immutable _initializer;
    address internal _tokenAddress;
    uint256 internal _tokenId;
    address  internal _owner;
    address private _approvedTo;
    mapping(address => mapping(address => bool)) private _operatos;

    constructor() {
        _initializer = msg.sender;
    }

    modifier isExistingToken(uint256 tokenId_) {
        if (tokenId_ != _tokenId) revert NonExistingToken();
        _;
    }

    modifier isInitialized() {
        if (_tokenAddress == address(0)) revert NotInitialized();
        _;
    }

    function initialize(address tokenAddress_, uint256 tokenId_, address owner_) external override {
        if (msg.sender != _initializer) revert NotInitializer();
        if (_tokenAddress != address(0)) revert AlreadyInitialized();

        _tokenAddress = tokenAddress_;
        _tokenId = tokenId_;
        _owner = owner_;
    }

    function tokenAddress() external view override isInitialized returns (address) {
        return _tokenAddress;
    }

    function tokenId() external view override isInitialized returns (uint256) {
        return _tokenId;
    }

    function owner() external view override isInitialized returns (address) {
        return _owner;
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return
        interfaceId == type(IERC721Metadata).interfaceId ||
        interfaceId == type(IERC721).interfaceId ||
        interfaceId == type(IERC165).interfaceId;
    }

    function name() external view override isInitialized returns (string memory) {
        return NAME;
    }

    function symbol() external view override isInitialized returns (string memory) {
        return SYMBOL;
    }

    function balanceOf(address owner_) external view override isInitialized returns (uint256) {
        if (owner_ == address(0)) revert ZeroAddress();

        return owner_ == _owner ? 1 : 0;
    }

    function ownerOf(uint256 tokenId_) external view override isInitialized isExistingToken(tokenId_) returns (address) {
        return _owner;
    }

    function getApproved(uint256 tokenId_) external view override isInitialized isExistingToken(tokenId_) returns (address) {
        return _approvedTo;
    }

    function approve(address to, uint256 tokenId_) external override isInitialized isExistingToken(tokenId_) {
        if (to == _owner) revert ApproveForOwner();
        if (msg.sender != _owner && !_operatos[_owner][msg.sender]) revert NotOwnerOrApproved();

        _approvedTo = to;

        emit Approval(_owner, to, tokenId_);
    }

    function isApprovedForAll(address owner_, address operator) external view override isInitialized returns (bool) {
        return _operatos[owner_][operator];
    }

    function setApprovalForAll(address operator, bool approved) external override isInitialized {
        if (msg.sender != _owner) revert NotOwner();
        if (operator == _owner) revert ApproveForOwner();

        _operatos[_owner][operator] = approved;

        emit ApprovalForAll(_owner, operator, approved);
    }

    function transferFrom(address from, address to, uint256 tokenId_) public override isInitialized isExistingToken(tokenId_) {
        if (msg.sender != _owner && msg.sender != _approvedTo && !_operatos[_owner][msg.sender]) revert NotOwnerOrApproved();
        if (from != _owner) revert NonExistingOwner();
        if (to == address(0)) revert ZeroAddress();

        _approvedTo = address(0);
        _owner = to;

        emit Transfer(from, to, tokenId_);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId_) external override isInitialized {
        safeTransferFrom(from, to, tokenId_, "");
    }

    function safeTransferFrom(address from, address to, uint256 tokenId_, bytes memory data) public override isInitialized {
        transferFrom(from, to, tokenId_);
        if (to.code.length > 0) {
            try IERC721Receiver(to).onERC721Received(msg.sender, from, tokenId_, data) returns (bytes4 retval) {
                if (retval != IERC721Receiver.onERC721Received.selector) revert NotERC721Receiver();
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert NotERC721Receiver();
                } else {
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        }
    }

    function _transfer(address to) internal virtual;

    function unwrap(address to) external override {
        if (msg.sender != _owner || msg.sender != _initializer) revert NotOwnerOrInitializer();

        IMarketplace(_initializer).remove(_tokenAddress, _tokenId);
        _transfer(to);
        selfdestruct(payable(_owner));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/IERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev _Available since v3.1._
 */
interface IERC1155Receiver is IERC165 {
    /**
     * @dev Handles the receipt of a single ERC1155 token type. This function is
     * called at the end of a `safeTransferFrom` after the balance has been updated.
     *
     * NOTE: To accept the transfer, this must return
     * `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
     * (i.e. 0xf23a6e61, or its own function selector).
     *
     * @param operator The address which initiated the transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param id The ID of the token being transferred
     * @param value The amount of tokens being transferred
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
     */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    /**
     * @dev Handles the receipt of a multiple ERC1155 token types. This function
     * is called at the end of a `safeBatchTransferFrom` after the balances have
     * been updated.
     *
     * NOTE: To accept the transfer(s), this must return
     * `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
     * (i.e. 0xbc197c81, or its own function selector).
     *
     * @param operator The address which initiated the batch transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param ids An array containing ids of each token being transferred (order and length must match values array)
     * @param values An array containing amounts of each token being transferred (order and length must match ids array)
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
     */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/extensions/IERC1155MetadataURI.sol)

pragma solidity ^0.8.0;

import "../IERC1155.sol";

/**
 * @dev Interface of the optional ERC1155MetadataExtension interface, as defined
 * in the https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155MetadataURI is IERC1155 {
    /**
     * @dev Returns the URI for token type `id`.
     *
     * If the `\{id\}` substring is present in the URI, it must be replaced by
     * clients with the actual token type ID.
     */
    function uri(uint256 id) external view returns (string memory);
}