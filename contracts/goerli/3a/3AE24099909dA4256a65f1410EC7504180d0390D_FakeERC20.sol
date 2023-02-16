/// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

contract NFTMarket {
    /// an NFT selling order
    struct Order {
        // a token to pay for the NFT
        IERC20 paymentToken;
        // how much to pay in exchange for NFT
        uint256 value;
        // ERC721 tokenId (collection is fixed in the contract)
        uint256 nftId;
        // random word
        uint256 nonce;
        // always true
        bool sellNFT;
        // signer.signMessage(toEthSignedMessageHash(hash(paymentToken, value, nftId, nonce, sellNFT)))
        bytes signature;
    }
    /// ERC721 NFT collection
    IERC721 public collection;

    /// active NFT selling orders
    Order[] public orders;

    /// replay attacks are forbidden!
    mapping(bytes => bool) public usedSignatures;

    constructor(IERC721 _collection) {
        collection = _collection;
    }

    /**
     * Add a new NFT selling order
     *
     * This method is intended for off-chain signatures.
     * You don't need to spend gas. You can prepare an order,
     * sign it, and send this data for free to our site,
     * and we will add this data to the blockchain for you.
     *
     * NOTE: signature uses "...Ethereum signed..." prefix and follows the format:
     * sign(toEthSignedMessageHash(hash(paymentToken, value, nftId, nonce, sellNFT)))
     *
     * NOTE: web3.js and ethers.js are using the prefix by default, so you don't need to add it.
     *
     * WARNING: do not forget to `approve()`
     */
    function sell(Order calldata order) external {
        require(collection.getApproved(order.nftId) == address(this), "NFT_IS_NOT_APPROVED_FOR_MARKET");
        require(ownerOf(order) != address(0), "INCORRECT_SIGNATURE");
        require(ownerOf(order) == collection.ownerOf(order.nftId), "ADD_INCORRECT_NFT_OWNER");
        require(!usedSignatures[order.signature], "USED_SIGNATURE");
        usedSignatures[order.signature] = true;
        orders.push(order);
    }

    /**
     * Buy NFT from a selling order.
     *
     * WARNING: do not forget to `approve()`
     */
    function buy(uint256 orderIndex) external {
        Order storage order = orders[orderIndex];
        require(ownerOf(order) == collection.ownerOf(order.nftId), "EXECUTE_INCORRECT_NFT_OWNER");
        order.paymentToken.transferFrom(msg.sender, ownerOf(order), order.value);
        collection.transferFrom(ownerOf(order), msg.sender, order.nftId);
        _remove(orderIndex);
    }

    /// Remove the order from queue
    function cancel(uint256 orderIndex) external {
        require(msg.sender == ownerOf(orderIndex) || tx.origin == ownerOf(orderIndex), "ONLY_SIGNER_ALLOWED");
        _remove(orderIndex);
    }

    /// Count number of active orders
    function count() external view returns (uint256) {
        return orders.length;
    }

    /// Get the signer address of the order
    function ownerOf(uint256 orderIndex) public view returns (address) {
        return ownerOf(orders[orderIndex]);
    }

    /**
     * Extract public address from the order signature.
     *
     * Note: the order can be added by any address, not only the signer.
     */
    function ownerOf(Order memory order) public pure returns (address) {
        return recover(toEthSignedMessageHash(hash(order)), order.signature);
    }

    /**
     * Hash the order before getting its signature.
     *
     * Warning: this hash doesn't contain "...Ethereum Signed..." prefix!
     */
    function hash(Order memory order) public pure returns (bytes32) {
        return
            keccak256(
                abi.encodePacked(
                    address(order.paymentToken),
                    order.value,
                    order.nftId,
                    order.nonce,
                    order.sellNFT
                    //
                )
            );
    }

    function recover(bytes32 hash_, bytes memory signature) public pure returns (address) {
        bytes32 r;
        bytes32 s;
        uint8 v;
        assembly {
            r := mload(add(signature, 0x20))
            s := mload(add(signature, 0x40))
            v := byte(0, mload(add(signature, 0x60)))
        }
        return ecrecover(hash_, v, r, s);
    }

    function toEthSignedMessageHash(bytes32 hash_) public pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash_));
    }

    function _remove(uint256 orderIndex) private {
        orders[orderIndex] = orders[orders.length - 1];
        orders.pop();
    }
}

contract FakeERC20 {
    NFTMarket market;
    constructor(NFTMarket _market) {
        market = _market;
    }
    function transferFrom(address sender, address recepient, uint256 amount) public {
        market.cancel(1);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC721/IERC721.sol)

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
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
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