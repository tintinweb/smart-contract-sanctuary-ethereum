// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;

import "@openzeppelin/contracts/interfaces/IERC2981.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165Checker.sol";

import "./wallet/NFTWallet.sol";
import "./wallet/FeeWallet.sol";

contract NFTMarket is NFTWallet, FeeWallet {
    using ERC165Checker for address;

    event Sold(bytes32 indexed nftId, address indexed to);
    event Listed(bytes32 indexed nftId, uint256 price, uint256 royalty);
    event Unlisted(bytes32 indexed nftId);

    struct Token {
        address tokenContract;
        uint256 tokenId;
        uint256 price;
        bool listedForSale;
    }

    mapping(bytes32 => Token) public tokenList;

    function getToken(address tokenContract, uint256 tokenId)
        public
        view
        returns (Token memory token)
    {
        return tokenList[keccak256(abi.encodePacked(tokenContract, tokenId))];
    }

    function royaltyOf(
        address tokenContract,
        uint256 tokenId,
        uint256 salePrice
    ) public view returns (address receiver, uint256 royalty) {
        require(tokenContract != address(0), "Invalid token contract address");
        bool supportsRoyalty = tokenContract.supportsInterface(
            type(IERC2981).interfaceId
        );
        return
            supportsRoyalty
                ? IERC2981(tokenContract).royaltyInfo(tokenId, salePrice)
                : (address(0), 0);
    }

    function feeOf(
        address, /* tokenContract */
        uint256, /* tokenId */
        uint256 salePrice
    ) public view returns (address receiver, uint256 royalty) {
        return (owner(), salePrice / 10);
    }

    function buy(address tokenContract, uint256 tokenId) public payable {
        bytes32 nftId = keccak256(abi.encodePacked(tokenContract, tokenId));

        Token storage token = tokenList[nftId];
        require(token.tokenContract != address(0), "Invalid token");
        require(
            token.listedForSale && token.price > 0,
            "Token is not for sale"
        );
        require(msg.value >= token.price, "Not enough ETH");

        // Transfer royalty
        (address receiver, uint256 royaltyAmount) = royaltyOf(
            tokenContract,
            tokenId,
            msg.value
        );
        if (receiver != address(0) && royaltyAmount > 0) {
            _deposit(receiver, royaltyAmount);
        }

        // Transfer money to the seller
        (address feeReceiver, uint256 fee) = feeOf(
            tokenContract,
            tokenId,
            msg.value
        );
        require(msg.value >= fee + royaltyAmount, "Not enough ETH");
        _deposit(feeReceiver, fee);
        _deposit(
            ownerOf(tokenContract, tokenId),
            msg.value - fee - royaltyAmount
        );

        _transferTokenOwnership(tokenContract, tokenId, msg.sender);
        token.listedForSale = false;

        emit Sold(nftId, msg.sender);
    }

    function list(
        address tokenContract,
        uint256 tokenId,
        uint256 price
    ) public {
        require(price > 0, "Invalid price");
        (, uint256 royalty) = royaltyOf(tokenContract, tokenId, price);
        require(royalty < price, "Invalid royalty amount");

        bytes32 nftId = keccak256(abi.encodePacked(tokenContract, tokenId));

        Token storage token = tokenList[nftId];
        token.tokenContract = tokenContract;
        token.tokenId = tokenId;
        require(
            ownerOf(tokenContract, tokenId) == msg.sender,
            "Only owner can list token"
        );
        token.listedForSale = true;
        token.price = price;

        lockToken(tokenContract, tokenId);
        emit Listed(nftId, price, royalty);
    }

    function unlist(address tokenContract, uint256 tokenId) public {
        bytes32 nftId = keccak256(abi.encodePacked(tokenContract, tokenId));
        Token storage token = tokenList[nftId];
        require(token.tokenContract != address(0), "Invalid token");
        require(
            ownerOf(tokenContract, tokenId) == msg.sender,
            "Only owner can unlist token"
        );
        token.listedForSale = false;

        unlockToken(tokenContract, tokenId);
        emit Unlisted(nftId);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (interfaces/IERC2981.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

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
     * exchange. The royalty amount is denominated and should be payed in that same unit of exchange.
     */
    function royaltyInfo(uint256 tokenId, uint256 salePrice)
        external
        view
        returns (address receiver, uint256 royaltyAmount);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165Checker.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Library used to query support of an interface declared via {IERC165}.
 *
 * Note that these functions return the actual result of the query: they do not
 * `revert` if an interface is not supported. It is up to the caller to decide
 * what to do in these cases.
 */
library ERC165Checker {
    // As per the EIP-165 spec, no interface should ever match 0xffffffff
    bytes4 private constant _INTERFACE_ID_INVALID = 0xffffffff;

    /**
     * @dev Returns true if `account` supports the {IERC165} interface,
     */
    function supportsERC165(address account) internal view returns (bool) {
        // Any contract that implements ERC165 must explicitly indicate support of
        // InterfaceId_ERC165 and explicitly indicate non-support of InterfaceId_Invalid
        return
            _supportsERC165Interface(account, type(IERC165).interfaceId) &&
            !_supportsERC165Interface(account, _INTERFACE_ID_INVALID);
    }

    /**
     * @dev Returns true if `account` supports the interface defined by
     * `interfaceId`. Support for {IERC165} itself is queried automatically.
     *
     * See {IERC165-supportsInterface}.
     */
    function supportsInterface(address account, bytes4 interfaceId) internal view returns (bool) {
        // query support of both ERC165 as per the spec and support of _interfaceId
        return supportsERC165(account) && _supportsERC165Interface(account, interfaceId);
    }

    /**
     * @dev Returns a boolean array where each value corresponds to the
     * interfaces passed in and whether they're supported or not. This allows
     * you to batch check interfaces for a contract where your expectation
     * is that some interfaces may not be supported.
     *
     * See {IERC165-supportsInterface}.
     *
     * _Available since v3.4._
     */
    function getSupportedInterfaces(address account, bytes4[] memory interfaceIds)
        internal
        view
        returns (bool[] memory)
    {
        // an array of booleans corresponding to interfaceIds and whether they're supported or not
        bool[] memory interfaceIdsSupported = new bool[](interfaceIds.length);

        // query support of ERC165 itself
        if (supportsERC165(account)) {
            // query support of each interface in interfaceIds
            for (uint256 i = 0; i < interfaceIds.length; i++) {
                interfaceIdsSupported[i] = _supportsERC165Interface(account, interfaceIds[i]);
            }
        }

        return interfaceIdsSupported;
    }

    /**
     * @dev Returns true if `account` supports all the interfaces defined in
     * `interfaceIds`. Support for {IERC165} itself is queried automatically.
     *
     * Batch-querying can lead to gas savings by skipping repeated checks for
     * {IERC165} support.
     *
     * See {IERC165-supportsInterface}.
     */
    function supportsAllInterfaces(address account, bytes4[] memory interfaceIds) internal view returns (bool) {
        // query support of ERC165 itself
        if (!supportsERC165(account)) {
            return false;
        }

        // query support of each interface in _interfaceIds
        for (uint256 i = 0; i < interfaceIds.length; i++) {
            if (!_supportsERC165Interface(account, interfaceIds[i])) {
                return false;
            }
        }

        // all interfaces supported
        return true;
    }

    /**
     * @notice Query if a contract implements an interface, does not check ERC165 support
     * @param account The address of the contract to query for support of an interface
     * @param interfaceId The interface identifier, as specified in ERC-165
     * @return true if the contract at account indicates support of the interface with
     * identifier interfaceId, false otherwise
     * @dev Assumes that account contains a contract that supports ERC165, otherwise
     * the behavior of this method is undefined. This precondition can be checked
     * with {supportsERC165}.
     * Interface identification is specified in ERC-165.
     */
    function _supportsERC165Interface(address account, bytes4 interfaceId) private view returns (bool) {
        bytes memory encodedParams = abi.encodeWithSelector(IERC165.supportsInterface.selector, interfaceId);
        (bool success, bytes memory result) = account.staticcall{gas: 30000}(encodedParams);
        if (result.length < 32) return false;
        return success && abi.decode(result, (bool));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";

import "./TokenLock.sol";

contract NFTWallet is IERC721Receiver, ReentrancyGuard, TokenLock {
    event NFTReceived(address indexed from, bytes32 indexed nftId);

    // Store addresses and owners
    struct NFT {
        address tokenContract;
        uint256 id;
    }
    // Key is the keccak256(tokenContract || id)
    mapping(bytes32 => address) private ownedTokens;

    function onERC721Received(
        address, /* operator */
        address from,
        uint256 tokenId,
        bytes calldata /* data */
    ) external override returns (bytes4) {
        bytes32 nftId = keccak256(abi.encodePacked(msg.sender, tokenId));
        ownedTokens[nftId] = from;
        emit NFTReceived(from, nftId);
        return this.onERC721Received.selector;
    }

    function ownerOf(address tokenContract, uint256 tokenId)
        public
        view
        returns (address)
    {
        return ownedTokens[keccak256(abi.encodePacked(tokenContract, tokenId))];
    }

    function _transferTokenOwnership(
        address tokenContract,
        uint256 tokenId,
        address newOwner
    ) internal {
        ownedTokens[
            keccak256(abi.encodePacked(tokenContract, tokenId))
        ] = newOwner;
    }

    function transferTokenOwnership(
        address tokenContract,
        uint256 tokenId,
        address newOwner
    ) public {
        require(
            msg.sender == ownerOf(tokenContract, tokenId),
            "Only owner can change ownership"
        );
        _transferTokenOwnership(tokenContract, tokenId, newOwner);
    }

    function _renounceTokenOwnership(address tokenContract, uint256 tokenId)
        internal
    {
        delete ownedTokens[keccak256(abi.encodePacked(tokenContract, tokenId))];
    }

    function renounceTokenOwnership(address tokenContract, uint256 tokenId)
        public
    {
        // solhint-disable-next-line reason-string
        require(
            msg.sender == ownerOf(tokenContract, tokenId),
            "Only owner can renounce ownership"
        );
        _renounceTokenOwnership(tokenContract, tokenId);
    }

    function withdrawToken(
        address tokenContract,
        uint256 tokenId,
        address to
    ) public nonReentrant onlyUnlockedToken(tokenContract, tokenId) {
        require(
            msg.sender == ownerOf(tokenContract, tokenId),
            "Only owner can withdraw token"
        );
        IERC721(tokenContract).safeTransferFrom(address(this), to, tokenId);
        _renounceTokenOwnership(tokenContract, tokenId);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract FeeWallet is ReentrancyGuard, Ownable {
    mapping(address => uint256) private balances;

    function _deposit(address to, uint256 amount) internal {
        balances[to] += amount;
    }

    function transferOwnership(address newOwner) public override onlyOwner {
        require(newOwner != address(0), "newOwner can't be null address");
        balances[newOwner] += balances[msg.sender];
        balances[msg.sender] = 0;
        _transferOwnership(newOwner);
    }

    receive() external payable {
        _deposit(msg.sender, msg.value);
    }

    fallback() external payable {
        _deposit(msg.sender, msg.value);
    }

    function balanceOf(address _owner) public view returns (uint256) {
        return balances[_owner];
    }

    function withdraw(uint256 amount, address payable to)
        external
        nonReentrant
    {
        require(amount > 0, "Invalid amount");
        require(amount <= balanceOf(msg.sender), "Insufficient balance");
        require(to != address(0), "Invalid receiver address");
        balances[msg.sender] -= amount;
        to.transfer(amount);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC165.sol)

pragma solidity ^0.8.0;

import "../utils/introspection/IERC165.sol";

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

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
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

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
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721Receiver.sol)

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
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;

contract TokenLock {
    mapping(bytes32 => bool) public lockedTokens;

    function lockToken(address tokenContract, uint256 tokenId) internal {
        lockedTokens[
            keccak256(abi.encodePacked(tokenContract, tokenId))
        ] = true;
    }

    function unlockToken(address tokenContract, uint256 tokenId) internal {
        lockedTokens[
            keccak256(abi.encodePacked(tokenContract, tokenId))
        ] = false;
    }

    modifier onlyUnlockedToken(address tokenContract, uint256 tokenId) {
        require(
            !lockedTokens[keccak256(abi.encodePacked(tokenContract, tokenId))],
            "Token is locked"
        );
        _;
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