// SPDX-License-Identifier: MIT

/**
 * @title bahia nft purchase contract
*/

pragma solidity ^0.8.12;

import "Bahia.sol";
import "Strings.sol";
import "ReentrancyGuard.sol";
import "IERC721.sol";
import "ERC721Holder.sol";


error InsufficientFunds();
error ExceesReimbursementFailed();
error Expired();
error NFTNotApproved();
error NotOwner();
error NotBuyer();
error NotSeller();
error Completed();

contract BahiaNFTPurchase2 is
    Bahia,
    ERC721Holder,
    ReentrancyGuard
{
    // events
    event NFTPurchaseCreated(uint256 expirationTime, address collectionAddress, uint256 nftId, uint256 cost, address buyerAddress, uint256 purchaseId);
    event SetCost(uint256 transactionId, uint256 cost);
    event SetBuyer(uint256 transactionId, address buyerAddress);
    event CompleteTransaction(uint256 transactionId);

    // struct for purchases
    struct Transaction {
        // keep the id of the purchase, acts as a backlink, making it easy on the frontend
        uint256 purchaseId;

        // have an expiration time
        uint256 expirationTime;

        // keep track of the NFT is
        uint256 nftId;

        // keep track of the cost (in gwei)
        uint256 cost;

        // keep track of buyer, seller addresses
        address buyerAddress;
        address sellerAddress;

        // keep track of whether or not this have been completed
        bool completed;

        // keep track of the nft data
        IERC721 nftManager;
    }

    // track all purchases
    Transaction[] public transactions;

    // track each buyer
    mapping(address => uint256[]) public purchases;

    // track each seller
    mapping(address => uint256[]) public sales;

    // backtrack the constructor
    constructor(uint256 devRoyalty_) Bahia(devRoyalty_) {}

    /**
     * @notice a modifier that checks that the calling address is the buyer
     * @param transactionId for indicating which transaction it is
    */
    modifier onlyBuyer(uint256 transactionId)
    {
        if ((msg.sender != transactions[transactionId].buyerAddress) && (transactions[transactionId].buyerAddress != address(0))) revert NotBuyer();
        _;
    }

    /**
     * @notice a modifier that checks that the calling address is the seller
     * @param transactionId for indicating which transaction it is
    */
    modifier onlySeller(uint256 transactionId)
    {
        if (msg.sender != transactions[transactionId].sellerAddress) revert NotSeller();
        _;
    }

    /**
     * @notice a modifier to check transferrability
    */
    modifier transferrable(uint256 transactionId)
    {
        // only allow if it contains NFT, is not expired, and is not completed
        if (isExpired(transactionId)) revert Expired();

        if (transactions[transactionId].nftManager.getApproved(transactions[transactionId].nftId) != address(this)) revert NFTNotApproved();

        if (transactions[transactionId].nftManager.ownerOf(transactions[transactionId].nftId) != transactions[transactionId].sellerAddress) revert NotOwner();

        if (transactions[transactionId].completed) revert Completed();

        _;
    }

    /**
     * @notice a function to create a new transaction
     * @param expirationTime to set when the contract expires
     * @param collectionAddress to determine the nft collection
     * @param nftId to determine which nft is going to be traded
     * @param cost to determine how much to pay for the nft
     * @param buyerAddress to determine the buyer
    */
    function createTransaction(uint256 expirationTime, address collectionAddress, uint256 nftId, uint256 cost, address buyerAddress) external
    {
        // add the new nft purchase to the mapping (use the transactions array length)
        sales[msg.sender].push(transactions.length);

        if ((buyerAddress) != address(0))
        {
            sales[buyerAddress].push(transactions.length);
        }

        // check if the creator is the rightful owner
        IERC721 nftManager = IERC721(collectionAddress);
        if (nftManager.ownerOf(nftId) != msg.sender) revert NotOwner();

        // make a new transaction
        Transaction memory newTransaction = Transaction({
            purchaseId: transactions.length,
            expirationTime: expirationTime,
            nftId: nftId,
            cost: cost,
            buyerAddress: buyerAddress,
            sellerAddress: msg.sender,  // use the message sender as the seller
            completed: false,
            nftManager: nftManager
            });

        // create a new nft purchase
        transactions.push(newTransaction);

        // emit that a contract was created
        emit NFTPurchaseCreated(expirationTime, collectionAddress, nftId, cost, buyerAddress, transactions.length - 1);

    }

    /**
     * @notice count the purchases for frontend iteration
     * @param address_ to locate the address for which we are tracking purchases
    */
    function purchaseCount(address address_) external view returns (uint256)
    {
        return purchases[address_].length;
    }

    /**
     * @notice count the sales for frontend iteration
     * @param address_ to locate the address for which we are tracking sales
    */
    function saleCount(address address_) external view returns (uint256)
    {
        return sales[address_].length;
    }

    /**
     * @notice a function to return the amount of total transactions
    */
    function totalTransactions() external view returns (uint256)
    {
        return transactions.length;
    }

    /**
     * @notice a function to add a sale to the mapping
     * @param buyerAddress for who bought it
     * @param purchaseId for the purchase to be linked
    */
    function addPurchase(address buyerAddress, uint256 purchaseId) internal
    {
        // add the purchase to the buyer's list (in the mapping)
        purchases[buyerAddress].push(purchaseId);
    }

    /**
     * @notice a function to see if the contract is expired
    */
    function isExpired(uint256 transactionId) public view returns (bool)
    {
        return (block.timestamp > transactions[transactionId].expirationTime);
    }

    /**
     * @notice a function for the buyer to receive the nft
    */
    function buy(uint256 transactionId) external payable onlyBuyer(transactionId) nonReentrant
    {
        // cannot be expired  (other iterms will be checked in safe transfer)
        if (isExpired(transactionId)) revert Expired();

        // cannot be completed
        if (transactions[transactionId].completed) revert Completed();

        // now that the nft is transferrable, transfer it out of this wallet (will check other require statements)
        transactions[transactionId].nftManager.safeTransferFrom(transactions[transactionId].sellerAddress, msg.sender, transactions[transactionId].nftId);

        // pay the seller
        _paySeller(transactionId);

        // make sure that the message value exceeds the cost
        _refundExcess(transactionId);

        // log the sender as the buyer address
        transactions[transactionId].buyerAddress = msg.sender;

        // add the purchase to the parent contract
        addPurchase(transactions[transactionId].buyerAddress, transactionId);

        // set completed to true
        transactions[transactionId].completed = true;

        emit CompleteTransaction(transactionId);

    }

    /**
     * @notice a setter function for the cost
     * @param cost_ for the new cost
    */
    function setCost(uint256 transactionId, uint256 cost_) external onlySeller(transactionId) transferrable(transactionId)
    {
        transactions[transactionId].cost = cost_;

        emit SetCost(transactionId, transactions[transactionId].cost);
    }

    /**
     * @notice a setter function for the buyerAddress
     * @param buyerAddress_ for setting the buyer
    */
    function setBuyer(uint256 transactionId, address buyerAddress_) external onlySeller(transactionId) transferrable(transactionId)
    {
        transactions[transactionId].buyerAddress = buyerAddress_;

        emit SetBuyer(transactionId, transactions[transactionId].buyerAddress);
    }

    /**
     * @notice refund the rest of the funds if too many
    */
    function _refundExcess(uint256 transactionId) internal
    {
        // if the msg value is too much, refund it
        if (msg.value > transactions[transactionId].cost)
        {
            // refund the buyer the excess
            (bool sent, ) = transactions[transactionId].buyerAddress.call{value: msg.value - transactions[transactionId].cost}("");
            if (!sent) revert ExceesReimbursementFailed();
        }
    }

    /**
     * @notice a function to pay the seller
    */
    function _paySeller(uint256 transactionId) internal
    {
        uint256 devPayment = transactions[transactionId].cost * devRoyalty / 100000;

        (bool sent, ) = devAddress.call{value: devPayment}("");
        if (!sent) revert InsufficientFunds();

        (bool sent2, ) = transactions[transactionId].sellerAddress.call{value: transactions[transactionId].cost - devPayment}("");
        if (!sent2) revert InsufficientFunds();
    }

}

// SPDX-License-Identifier: MIT

/**
 * @title bahia base contract
*/

pragma solidity ^0.8.4;

error NotDev();
error NotAllowed();

contract Bahia
{
    address public devAddress;
    uint256 public devRoyalty;  // out of 100,000

    // allow certain contracts
    mapping(address => bool) internal allowedContracts;

    constructor (uint256 devRoyalty_)
    {
        // set the dev royalty
        devRoyalty = devRoyalty_;

        // set the dev address to that in the constructor
        devAddress = msg.sender;
    }

    /**
     * @notice a modifier to mark functions that only the dev can touch
    */
    modifier onlyDev()
    {
        if (tx.origin != devAddress) revert NotDev();
        _;
    }

    /**
     * @notice a modified that only allowed contracts can access
    */
    modifier onlyAllowed()
    {
        if (!allowedContracts[msg.sender]) revert NotAllowed();
        _;
    }

    /**
     * @notice allow the devs to change their address
     * @param devAddress_ for the new dev address
    */
    function changeDevAddress(address devAddress_) external onlyDev
    {
        devAddress = devAddress_;
    }

    /**
     * @notice allow the devs to change their royalty
     * @param devRoyalty_ for the new royalty
    */
    function changeDevRoyalty(uint256 devRoyalty_) external onlyDev
    {
        devRoyalty = devRoyalty_;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "IERC165.sol";

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
// OpenZeppelin Contracts v4.4.1 (token/ERC721/utils/ERC721Holder.sol)

pragma solidity ^0.8.0;

import "IERC721Receiver.sol";

/**
 * @dev Implementation of the {IERC721Receiver} interface.
 *
 * Accepts all token transfers.
 * Make sure the contract is able to use its token with {IERC721-safeTransferFrom}, {IERC721-approve} or {IERC721-setApprovalForAll}.
 */
contract ERC721Holder is IERC721Receiver {
    /**
     * @dev See {IERC721Receiver-onERC721Received}.
     *
     * Always returns `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }
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