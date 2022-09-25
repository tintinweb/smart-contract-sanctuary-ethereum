/**
 *Submitted for verification at Etherscan.io on 2022-09-25
*/

//SPDX-License-Identifier: Unlicense

// File contracts/interfaces/ICommon.sol

pragma solidity ^0.8.0;

interface ICommon {

    enum AssetType {
            undefined,
            ERC721,
            ERC1155
        }
    
    enum Status {
        undefined,
        CREATE,
        SOLD,
        CANCEL
    }
}


// File contracts/interfaces/IListing.sol

pragma solidity ^0.8.0;

interface IFixedPrice is ICommon {
    
    event ListedFixedPriceItem(address indexed account,uint256 fixedItemId);
    event BoughtFixedPriceItem(uint256 indexed fixedItemId,uint256 indexed tokenId,address buyer);
    event UnlistedFixedPriceItem(uint256 indexed fixedItemId,uint256 indexed tokenId);

    function listFixedPriceItem(address asset,uint96 price,uint128 tokenId,uint128 amount,AssetType assetType,uint128 getListingDuration) external;
    function buyFixedPriceItems(uint256[] memory itemIds) external;
    function unlistFixedPriceItem(uint256 itemId) external;
}


// File contracts/interfaces/IOffer.sol

pragma solidity ^0.8.0;

interface IBestOffer is ICommon {

    event OfferMade(address indexed account,uint256 offerItemId);
    event OfferAccepted(uint256 indexed offerItemId,uint256 indexed tokenId,address buyer,uint256 price);
    event OfferCancelled(uint256 indexed offerItemId, uint256 indexed tokenId);

    function makeOffer(address asset,uint96 startPrice,uint128 tokenId,uint128 amount,AssetType assetType,uint128 offerDuration) external;
    function acceptOffer(uint256 itemId) external;
    function cancelOffer(uint256 itemId) external;
}


// File contracts/interfaces/IAuction.sol

pragma solidity ^0.8.0;

interface IAuction is ICommon {

    event ListedAuction (address indexed account,uint256 auctionItemId);
    event FinishedAuction (uint256 indexed auctionItemId,uint256 indexed tokenId,uint256 indexed lastBid,address userFinished);
    event CanceledAuction (uint256 indexed auctionItemId,uint256 indexed tokenId);
    event BidMade(address indexed bidder, uint256 indexed auctionItemId, uint256 indexed bidPrice);

    event ListedDutchAuction (address indexed account,uint256 dutchItemId);
    event FinishedDutchAuction (uint256 indexed dutchItemId,uint256 indexed tokenId, uint256 currentPrice, address seller);
    event CanceledDutchAuction (uint256 indexed dutchItemId,uint256 indexed tokenId);

    function listAuction(address asset,uint96 startPrice,uint128 tokenId,uint128 amount,AssetType assetType,uint128 auctionDuration) external;
    function finishAuction(uint64 itemId) external;
    function cancelAuction(uint256 itemId) external;
    function makeBid(uint64 _auctionItmId,uint96 bidPrice) external;

    function listDutchAuction(
        address asset,
        uint96 startPrice, // per NFT pricing
        uint96 endPrice,
        uint128 tokenId,
        uint128 amount,
        AssetType assetType,
        uint128 auctionDuration
    ) external;

    function cancelDutchAuction(uint256 itemId) external;
    function buyDutchAuction(uint64 itemId) external;
    
}


// File @openzeppelin/contracts-upgradeable/token/ERC20/[email protected]

 // OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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


// File @openzeppelin/contracts-upgradeable/interfaces/[email protected]

 // OpenZeppelin Contracts v4.4.1 (interfaces/IERC20.sol)

pragma solidity ^0.8.0;


// File @openzeppelin/contracts-upgradeable/utils/introspection/[email protected]

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
interface IERC165Upgradeable {
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


// File @openzeppelin/contracts-upgradeable/token/ERC721/[email protected]

 // OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721Upgradeable is IERC165Upgradeable {
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


// File @openzeppelin/contracts-upgradeable/interfaces/[email protected]

 // OpenZeppelin Contracts v4.4.1 (interfaces/IERC721.sol)

pragma solidity ^0.8.0;


// File @openzeppelin/contracts-upgradeable/token/ERC1155/[email protected]

 // OpenZeppelin Contracts (last updated v4.7.0) (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155Upgradeable is IERC165Upgradeable {
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
     * - If the caller is not `from`, it must have been approved to spend ``from``'s tokens via {setApprovalForAll}.
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


// File @openzeppelin/contracts-upgradeable/interfaces/[email protected]

 // OpenZeppelin Contracts v4.4.1 (interfaces/IERC1155.sol)

pragma solidity ^0.8.0;


// File @openzeppelin/contracts-upgradeable/token/ERC721/[email protected]

 // OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721ReceiverUpgradeable {
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


// File @openzeppelin/contracts-upgradeable/interfaces/[email protected]

 // OpenZeppelin Contracts v4.4.1 (interfaces/IERC721Receiver.sol)

pragma solidity ^0.8.0;


// File @openzeppelin/contracts-upgradeable/token/ERC1155/[email protected]

 // OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/IERC1155Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @dev _Available since v3.1._
 */
interface IERC1155ReceiverUpgradeable is IERC165Upgradeable {
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


// File @openzeppelin/contracts-upgradeable/interfaces/[email protected]

 // OpenZeppelin Contracts v4.4.1 (interfaces/IERC1155Receiver.sol)

pragma solidity ^0.8.0;


// File @openzeppelin/contracts-upgradeable/interfaces/[email protected]

 // OpenZeppelin Contracts (last updated v4.6.0) (interfaces/IERC2981.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface for the NFT Royalty Standard.
 *
 * A standardized way to retrieve royalty payment information for non-fungible tokens (NFTs) to enable universal
 * support for royalty payments across all NFT marketplaces and ecosystem participants.
 *
 * _Available since v4.5._
 */
interface IERC2981Upgradeable is IERC165Upgradeable {
    /**
     * @dev Returns how much royalty is owed and to whom, based on a sale price that may be denominated in any unit of
     * exchange. The royalty amount is denominated and should be paid in that same unit of exchange.
     */
    function royaltyInfo(uint256 tokenId, uint256 salePrice)
        external
        view
        returns (address receiver, uint256 royaltyAmount);
}


// File @openzeppelin/contracts-upgradeable/interfaces/[email protected]

 // OpenZeppelin Contracts v4.4.1 (interfaces/IERC165.sol)

pragma solidity ^0.8.0;


// File @openzeppelin/contracts-upgradeable/utils/[email protected]

 // OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly
                /// @solidity memory-safe-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}


// File @openzeppelin/contracts-upgradeable/proxy/utils/[email protected]

 // OpenZeppelin Contracts (last updated v4.7.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * The initialization functions use a version number. Once a version number is used, it is consumed and cannot be
 * reused. This mechanism prevents re-execution of each "step" but allows the creation of new initialization steps in
 * case an upgrade adds a module that needs to be initialized.
 *
 * For example:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
 * contract MyTokenV2 is MyToken, ERC20PermitUpgradeable {
 *     function initializeV2() reinitializer(2) public {
 *         __ERC20Permit_init("MyToken");
 *     }
 * }
 * ```
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To prevent the implementation contract from being used, you should invoke
 * the {_disableInitializers} function in the constructor to automatically lock it when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() {
 *     _disableInitializers();
 * }
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     * @custom:oz-retyped-from bool
     */
    uint8 private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Triggered when the contract has been initialized or reinitialized.
     */
    event Initialized(uint8 version);

    /**
     * @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
     * `onlyInitializing` functions can be used to initialize parent contracts. Equivalent to `reinitializer(1)`.
     */
    modifier initializer() {
        bool isTopLevelCall = !_initializing;
        require(
            (isTopLevelCall && _initialized < 1) || (!AddressUpgradeable.isContract(address(this)) && _initialized == 1),
            "Initializable: contract is already initialized"
        );
        _initialized = 1;
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(1);
        }
    }

    /**
     * @dev A modifier that defines a protected reinitializer function that can be invoked at most once, and only if the
     * contract hasn't been initialized to a greater version before. In its scope, `onlyInitializing` functions can be
     * used to initialize parent contracts.
     *
     * `initializer` is equivalent to `reinitializer(1)`, so a reinitializer may be used after the original
     * initialization step. This is essential to configure modules that are added through upgrades and that require
     * initialization.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     */
    modifier reinitializer(uint8 version) {
        require(!_initializing && _initialized < version, "Initializable: contract is already initialized");
        _initialized = version;
        _initializing = true;
        _;
        _initializing = false;
        emit Initialized(version);
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} and {reinitializer} modifiers, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    /**
     * @dev Locks the contract, preventing any future reinitialization. This cannot be part of an initializer call.
     * Calling this in the constructor of a contract will prevent that contract from being initialized or reinitialized
     * to any version. It is recommended to use this to lock implementation contracts that are designed to be called
     * through proxies.
     */
    function _disableInitializers() internal virtual {
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized < type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }
}


// File @openzeppelin/contracts-upgradeable/utils/[email protected]

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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal onlyInitializing {
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}


// File @openzeppelin/contracts-upgradeable/access/[email protected]

 // OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;


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
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal onlyInitializing {
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal onlyInitializing {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}


// File contracts/GenshardsMarketplace.sol

pragma solidity ^0.8.0;










contract GSMarketplace is
    IAuction,
    IBestOffer,
    IFixedPrice,
    IERC721ReceiverUpgradeable,
    IERC1155ReceiverUpgradeable,
    OwnableUpgradeable
{
    struct FixedPriceItem {
        uint256 sellTime;
        uint256 asset_price;
        uint256 tokenId_amount;
        uint256 seller_type_status;
        uint256 time_duration;
    }

    struct OfferItem {
        uint256 sellTime;
        uint256 asset_price;
        uint256 tokenId_amount;
        uint256 buyer_type_status;
        uint256 time_duration;
    }

    struct AuctionItem {
        uint256 sellTime;
        uint256 asset_price;
        uint256 tokenId_amount;
        uint256 seller_type_status;
        uint256 time_duration;
    }

    struct DutchItem {
        uint256 sellTime;
        uint256 asset_price;
        uint256 tokenId_amount;
        uint256 seller_type_status;
        uint256 time_duration;
        uint256 endPrice;
    }

    struct BidInfo {
        uint64 auctionItemId;
        address bidder;
        uint128 bidPrice;
        uint128 bidTime;
        Status status;
    }

    //itemId mapping to respective structs
    mapping(uint256 => FixedPriceItem) private fixedPriceItems;
    mapping(uint256 => OfferItem) private offerItems;
    mapping(uint256 => AuctionItem) private auctionItems;
    mapping(uint256 => DutchItem) private dutchItems;


    // auctionItemId => returns bidCount
    mapping(uint64 => uint32) public bidCount;
    // auctionItemId => currentBidCounter => returns BidInfo
    mapping(uint64 => mapping(uint32 => BidInfo)) public bidInfo;

    bytes4 private constant _INTERFACE_ID_ERC2981 = 0x2a55205a;   //royalty

    IERC20Upgradeable private _WETH;
        // IERC20(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);//eth
        // IERC20(0xc778417E063141139Fce010982780140Aa0cD5Ab);//rinkeby


    uint64 private _fixedItemId;
    uint64 private _offerItemId;
    uint64 private _auctionItemId;
    uint64 private _dutchItemId;

    uint256 private _totalComissions;
    uint96 private _comission;

    struct AllItemIds{

        uint256[] _listedItemIds;
        uint256[] _offeredItemIds;
        uint256[] _auctionedItemIds;
        uint256[] _dutchItemIds;

    }

    //nft => tokenId => status(0,1,2,3)
    mapping(address => mapping(uint256 => mapping(Status => AllItemIds))) private getAllItemIds;

    // mandatory to call before perfoming any actions on this contrat
    function initialize(
        uint96 comission_, address weth_)
        external
        initializer
    {
        _comission = comission_;//5 // 5%// input as it is
        _WETH = IERC20Upgradeable(weth_);
        __Ownable_init();
    }

    function getComissionsInfo() external view returns (uint256 _totalComissionsEarned, uint96 _comissionSet) {
        return (_totalComissions, _comission);
    }

    function allItemIdCounts() external view returns (uint256 fixedItemId, uint256 offerItemId, uint256 auctionItemId, uint256 dutchItemId) {
        return (_fixedItemId, _offerItemId, _auctionItemId, _dutchItemId);
    }

    function listFixedPriceItem(
        address asset,
        uint96 price,
        uint128 tokenId,
        uint128 amount,
        AssetType assetType,
        uint128 getListingDuration
    ) external override {
        require(price > 0, "Price too low");
        require(getListingDuration >= 900, "Duration should be >= to 15 minutes");//End date must be at least 15 minutes after the start date

        if (assetType == AssetType.ERC721) {
            require(IERC721Upgradeable(asset).supportsInterface(0x80ac58cd) == true, "GMP: Invalid Asset");
            require(amount == 1, "ERC721: Invalid amount");
            require(IERC721Upgradeable(asset).ownerOf(tokenId) == msg.sender, "GMP: Not owner");
            require(IERC721Upgradeable(asset).getApproved(tokenId) == address(this), "GMP: NFT Unapproved");
        } else if(assetType == AssetType.ERC1155) {
            require(IERC1155Upgradeable(asset).supportsInterface(0xd9b67a26) == true, "GMP: Invalid Asset");
            require(IERC1155Upgradeable(asset).balanceOf(msg.sender, tokenId) >= amount, "GMP: Invalid amount");
            require(IERC1155Upgradeable(asset).isApprovedForAll(msg.sender, address(this)) == true, "GMP: NFT Unapproved");
        } else{
            revert("Asset type is not supported");
        }

        fixedPriceItems[++_fixedItemId]=FixedPriceItem(0, _encodeAssetPrice(asset, price),  _encodeTokenIdAmount(tokenId, amount), _encodeBuyerSellerTypeStatus(msg.sender, assetType), _encodeTimeDuration(uint128(block.timestamp), getListingDuration));

        getAllItemIds[asset][tokenId][Status.CREATE]._listedItemIds.push(_fixedItemId);

        emit ListedFixedPriceItem(msg.sender, _fixedItemId);
    }

    function getFixedPriceItem(uint256 itemId)
        public
        view
        returns (
            address asset,
            uint96 startPrice,
            uint128 tokenId,
            uint128 amount,
            address seller,
            AssetType assetType,
            uint128 listingTime,
            uint128 listingDuration,
            uint256 sellTime,
            Status status
        )
    {
        FixedPriceItem memory item = fixedPriceItems[itemId];
        (listingTime, listingDuration) = _decodeTimeDuration(item.time_duration);
        (asset, startPrice) = _decodeAssetPrice(item.asset_price);
        (tokenId, amount) = _decodeTokenIdAmount(item.tokenId_amount);
        (seller, assetType, status) = _decodeBuyerSellerTypeStatus(
            item.seller_type_status
        );
        sellTime = item.sellTime;
    }

    function unlistFixedPriceItem(uint256 itemId) external override{
        FixedPriceItem memory item = fixedPriceItems[itemId];

        (address asset,) = _decodeAssetPrice(item.asset_price);
        (address seller, , Status status) = _decodeBuyerSellerTypeStatus(item.seller_type_status);
        (uint128 tokenId, ) = _decodeTokenIdAmount(item.tokenId_amount);

        _onlyCreatedItem(status);
        _onlyOwner(seller, msg.sender);
        
        getAllItemIds[asset][tokenId][Status.CANCEL]._listedItemIds.push(itemId);
        item.seller_type_status = _setStatus(Status.CANCEL, item.seller_type_status);
        fixedPriceItems[itemId]=item;

        emit UnlistedFixedPriceItem(itemId, tokenId);
    }

    function buyFixedPriceItem(uint256 itemId) private {
        FixedPriceItem memory item = fixedPriceItems[itemId];
        (address asset, uint256 price) = _decodeAssetPrice(item.asset_price);
        (uint128 tokenId, uint128 amount) = _decodeTokenIdAmount(item.tokenId_amount);
        (address seller,
            AssetType assetType,
            Status status) = _decodeBuyerSellerTypeStatus(item.seller_type_status);
        (uint128 listingTime, uint128 listingDuration) = _decodeTimeDuration(item.time_duration);

        require(block.timestamp > listingTime && (block.timestamp < listingTime + listingDuration), "GMP: Listing is invalid or expired");

        _onlyCreatedItem(status);//to check if the status is CREATE
        _safePayment(price*amount, msg.sender, seller, asset, tokenId);
        _safeTransfer(tokenId, asset, seller, msg.sender, amount, assetType);

        getAllItemIds[asset][tokenId][Status.SOLD]._listedItemIds.push(itemId);
        item.seller_type_status = _setStatus(
            Status.SOLD,
            item.seller_type_status
        );
        item.sellTime = block.timestamp;

        fixedPriceItems[itemId]=item;

        emit BoughtFixedPriceItem(itemId, tokenId, msg.sender);
    }

    function buyFixedPriceItems(uint256[] memory _itemIds) external override{
        for (uint i=0; i< _itemIds.length; i++){
            buyFixedPriceItem(_itemIds[i]);
        }
    }

    function makeOffer(
        address asset,
        uint96 offerPrice,
        uint128 tokenId,
        uint128 amount,
        AssetType assetType,
        uint128 offerDuration
    ) external override {

        require(offerPrice > 0, "Price must be at least 1 wei");
        require(_WETH.allowance(msg.sender, address(this)) >= offerPrice, "Please approve offer price to WETH");
        
        if (assetType == AssetType.ERC721) {
            require(IERC721Upgradeable(asset).supportsInterface(0x80ac58cd) == true, "Asset type is invalid");
            require(amount == 1, "GMP: invalid amount passed, 1 required for ERC721");
        } else if(assetType == AssetType.ERC1155) {
            require(IERC1155Upgradeable(asset).supportsInterface(0xd9b67a26) == true, "Asset type is invalid");
        } else{
            revert("Asset type is not supported");
        }
        require(offerDuration >= 900, "Duration should be >= to 15 minutes");//End date must be at least 15 minutes after the start date

        offerItems[++_offerItemId]=OfferItem(0, _encodeAssetPrice(asset, offerPrice),  _encodeTokenIdAmount(tokenId, amount), _encodeBuyerSellerTypeStatus(msg.sender, assetType), _encodeTimeDuration(uint128(block.timestamp), offerDuration) );

        getAllItemIds[asset][tokenId][Status.CREATE]._offeredItemIds.push(_offerItemId);

        emit OfferMade(msg.sender, _offerItemId);

    }

    function getOfferItem(uint256 itemId)
        external
        view
        returns (
            address asset,
            uint96 offerPrice,
            uint128 tokenId,
            uint128 amount,
            address buyer,
            AssetType assetType,
            uint128 offerTime,
            uint128 offerDuration,
            uint256 sellTime,
            Status status
        )
    {
        OfferItem memory item = offerItems[itemId];
        (offerTime, offerDuration) = _decodeTimeDuration(item.time_duration);
        (buyer, assetType, status) = _decodeBuyerSellerTypeStatus(
            item.buyer_type_status
        );
        (tokenId, amount) = _decodeTokenIdAmount(item.tokenId_amount);
        (asset, offerPrice) = _decodeAssetPrice(item.asset_price);
        sellTime = item.sellTime;

    }

    function cancelOffer(uint256 itemId) external override{
        OfferItem memory item = offerItems[itemId];

        (address asset,) = _decodeAssetPrice(item.asset_price);
        (address buyer,,Status status) = _decodeBuyerSellerTypeStatus(item.buyer_type_status);
        (uint128 tokenId,) = _decodeTokenIdAmount(item.tokenId_amount);

        _onlyCreatedItem(status);
        _onlyOwner(buyer, msg.sender);

        getAllItemIds[asset][tokenId][Status.CANCEL]._offeredItemIds.push(itemId);
        item.buyer_type_status = _setStatus(
            Status.CANCEL,
            item.buyer_type_status
        );
        offerItems[itemId]=item;

        emit OfferCancelled(itemId, tokenId);
    }

    function acceptOffer(
        uint256 itemId
    ) external override{
        OfferItem memory item = offerItems[itemId];
        (uint128 tokenId, uint128 amount) = _decodeTokenIdAmount(
            item.tokenId_amount
        );
        (address asset, uint256 price) = _decodeAssetPrice(item.asset_price);

        (
            address buyer,
            AssetType assetType,
            Status status
        ) = _decodeBuyerSellerTypeStatus(item.buyer_type_status);
        
        (uint128 offerTime, uint128 offerDuration) = _decodeTimeDuration(item.time_duration);
        require(block.timestamp > offerTime && (block.timestamp < offerTime + offerDuration), "GMP: Offer invalid or expired");

        _onlyCreatedItem(status);
        // _onlyOwner(seller, msg.sender);
        _safePayment(price*amount, buyer, msg.sender, asset, tokenId);
        _safeTransfer(
            tokenId,
            asset,
            msg.sender,
            buyer,
            amount,
            assetType
        );

        getAllItemIds[asset][tokenId][Status.SOLD]._offeredItemIds.push(itemId);

        item.buyer_type_status = _setStatus(
            Status.SOLD,
            item.buyer_type_status
        );

        item.sellTime = block.timestamp;

        offerItems[itemId]=item;

        emit OfferAccepted(itemId, tokenId, buyer, price);
    }

    function listAuction(
        address asset,
        uint96 startPrice, // per NFT pricing
        uint128 tokenId,
        uint128 amount,
        AssetType assetType,
        uint128 auctionDuration
    ) external override {

        _safeTransfer(
            tokenId,
            asset,
            msg.sender,
            address(this),
            amount,
            assetType
        );

        auctionItems[++_auctionItemId]=AuctionItem(0, _encodeAssetPrice(asset, startPrice),  _encodeTokenIdAmount(tokenId, amount), _encodeBuyerSellerTypeStatus(msg.sender, assetType), _encodeTimeDuration(uint128(block.timestamp), auctionDuration) );
        
        getAllItemIds[asset][tokenId][Status.CREATE]._auctionedItemIds.push(_auctionItemId);
        
        emit ListedAuction(msg.sender, _auctionItemId);

    }

    function makeBid(
        uint64 _auctionItmId,
        uint96 bidPrice //per NFT pricing
    ) external override{

        AuctionItem memory item = auctionItems[_auctionItmId];
        
        (uint128 auctionTime, uint128 auctionDuration) = _decodeTimeDuration(item.time_duration);
        (, uint96 minimumAuctionPrice) = _decodeAssetPrice(item.asset_price);
        (, uint128 amount) = _decodeTokenIdAmount(item.tokenId_amount);
        (,, Status status) = _decodeBuyerSellerTypeStatus(item.seller_type_status);

        _onlyCreatedItem(status);
        require(bidPrice >= minimumAuctionPrice, "GMP: bid be more than min amount");

        bidCount[_auctionItmId] +=1;//1
        uint32 currentBidCounter = bidCount[_auctionItmId];//1

        require(bidPrice > bidInfo[_auctionItmId][currentBidCounter - 1].bidPrice, "GMP: Bid be more than top bidder");
        require(block.timestamp > auctionTime  && (block.timestamp < auctionTime + auctionDuration), "GMP: Auction is invalid or expired");
        require(_WETH.allowance(msg.sender, address(this)) >= bidPrice*amount, "GMP: Approve txnprice");
        
        bidInfo[_auctionItemId][currentBidCounter]=BidInfo(_auctionItemId, msg.sender, bidPrice, uint128(block.timestamp), status);

        emit BidMade(msg.sender, _auctionItemId, bidPrice);
    }

    function getAuctionItem(uint256 itemId)
        external
        view
        returns (
            address asset,
            uint96 offerPrice,
            uint128 tokenId,
            uint128 amount,
            address seller,
            AssetType assetType,
            uint128 auctionTime,
            uint128 auctionDuration,
            uint256 sellTime,
            Status status
        )
    {
        AuctionItem memory item = auctionItems[itemId];
        (auctionTime, auctionDuration) = _decodeTimeDuration(item.time_duration);
        (asset, offerPrice) = _decodeAssetPrice(item.asset_price);
        (tokenId, amount) = _decodeTokenIdAmount(item.tokenId_amount);
        (seller, assetType, status) = _decodeBuyerSellerTypeStatus(
            item.seller_type_status
        );
        sellTime = item.sellTime;
    }

    function cancelAuction(uint256 itemId) external override{
        AuctionItem memory item = auctionItems[itemId];
        (address seller,AssetType assetType,Status status) = _decodeBuyerSellerTypeStatus(item.seller_type_status);
        (uint128 tokenId, uint128 amount) = _decodeTokenIdAmount(item.tokenId_amount);
        (address asset, ) = _decodeAssetPrice(item.asset_price);

        _onlyCreatedItem(status);
        _onlyOwner(seller, msg.sender);
        _safeTransfer(tokenId, asset, address(this), seller, amount, assetType);

        getAllItemIds[asset][tokenId][Status.CANCEL]._auctionedItemIds.push(itemId);

        item.seller_type_status = _setStatus(
            Status.CANCEL,
            item.seller_type_status
        );
        auctionItems[itemId]=item;
        emit CanceledAuction(itemId, tokenId);
    }

    function finishAuction(
        uint64 itemId
    ) external override {
        AuctionItem memory item = auctionItems[itemId];
        (address asset, ) = _decodeAssetPrice(item.asset_price);
        (uint128 tokenId, uint128 amount) = _decodeTokenIdAmount(item.tokenId_amount);
        (address seller, AssetType assetType, Status status) = _decodeBuyerSellerTypeStatus(item.seller_type_status);

        uint32 hightestBidCounter = bidCount[itemId];
        BidInfo memory curBidInfo=bidInfo[itemId][hightestBidCounter];
        address buyer = curBidInfo.bidder;
        uint256 bid = curBidInfo.bidPrice*amount;

        _onlyCreatedItem(status);
        _onlyOwner(seller, msg.sender);
        _safePayment(bid, buyer, seller, asset, tokenId);
        _safeTransfer(tokenId, asset, address(this), buyer, amount, assetType);

        bidInfo[_auctionItemId][hightestBidCounter].status = Status.SOLD;

        getAllItemIds[asset][tokenId][Status.SOLD]._auctionedItemIds.push(itemId);

        item.seller_type_status = _setStatus(Status.SOLD, item.seller_type_status);
        item.sellTime = block.timestamp;
        auctionItems[itemId]=item;

        emit FinishedAuction(itemId, tokenId, bid, seller);
    }

    function listDutchAuction(
        address asset,
        uint96 startPrice, // per NFT pricing
        uint96 endPrice,
        uint128 tokenId,
        uint128 amount,
        AssetType assetType,
        uint128 auctionDuration
    ) external override{

        _safeTransfer(
            tokenId,
            asset,
            msg.sender,
            address(this),
            amount,
            assetType
        );

        dutchItems[++_dutchItemId]=DutchItem(0, _encodeAssetPrice(asset, startPrice),  _encodeTokenIdAmount(tokenId, amount), _encodeBuyerSellerTypeStatus(msg.sender, assetType), _encodeTimeDuration(uint128(block.timestamp), auctionDuration), endPrice);
            
        getAllItemIds[asset][tokenId][Status.CREATE]._dutchItemIds.push(_dutchItemId);
        
        emit ListedDutchAuction(msg.sender, _dutchItemId);

    }

     function cancelDutchAuction(uint256 itemId) external override{
        DutchItem memory item = dutchItems[itemId];
        (address seller,AssetType assetType,Status status) = _decodeBuyerSellerTypeStatus(item.seller_type_status);
        (uint128 tokenId, uint128 amount) = _decodeTokenIdAmount(item.tokenId_amount);
        (address asset, ) = _decodeAssetPrice(item.asset_price);

        _onlyCreatedItem(status);
        _onlyOwner(seller, msg.sender);
        _safeTransfer(tokenId, asset, address(this), seller, amount, assetType);

        getAllItemIds[asset][tokenId][Status.CANCEL]._dutchItemIds.push(itemId);

        item.seller_type_status = _setStatus(
            Status.CANCEL,
            item.seller_type_status
        );

        dutchItems[itemId]=item;
        emit CanceledDutchAuction(itemId, tokenId);
    }

    function buyDutchAuction(
        uint64 itemId
    ) external override {
        DutchItem memory item = dutchItems[itemId];
        (address asset,uint256 price ) = _decodeAssetPrice(item.asset_price);
        (uint128 tokenId, uint128 amount) = _decodeTokenIdAmount(item.tokenId_amount);
        (address seller, AssetType assetType, Status status) = _decodeBuyerSellerTypeStatus(item.seller_type_status); 
        (uint128 auctionTime, uint128 auctionDuration) = _decodeTimeDuration(item.time_duration);

        uint256 decreasingRate=(price-item.endPrice)/auctionDuration;
        uint256 currentPrice = price - (block.timestamp-auctionTime)*decreasingRate;

        _onlyCreatedItem(status);
        _safePayment(currentPrice*amount, msg.sender, seller, asset, tokenId);
        _safeTransfer(tokenId, asset, address(this), msg.sender, amount, assetType);

        getAllItemIds[asset][tokenId][Status.SOLD]._dutchItemIds.push(itemId);

        item.seller_type_status = _setStatus(Status.SOLD, item.seller_type_status);
        item.sellTime = block.timestamp;
        dutchItems[itemId]=item;

        emit FinishedDutchAuction(itemId, tokenId, currentPrice, seller);
    }

    function getDutchAuctionItem(uint256 itemId)
        external
        view
        returns (
            address asset,
            uint96 startPrice,
            uint96 endPrice,
            uint128 tokenId,
            uint128 amount,
            address seller,
            AssetType assetType,
            uint128 auctionTime,
            uint128 auctionDuration,
            uint256 sellTime,
            Status status,
            uint256 currentPrice
        )
    {
        DutchItem memory item = dutchItems[itemId];
        (auctionTime, auctionDuration) = _decodeTimeDuration(item.time_duration);
        (asset, startPrice) = _decodeAssetPrice(item.asset_price);
        (tokenId, amount) = _decodeTokenIdAmount(item.tokenId_amount);
        (seller, assetType, status) = _decodeBuyerSellerTypeStatus(
            item.seller_type_status
        );
        sellTime = item.sellTime; 
        endPrice=uint96(item.endPrice);
        uint256 decreasingRate=(startPrice-item.endPrice)/auctionDuration;
        currentPrice = startPrice - (block.timestamp-auctionTime)*decreasingRate;
    } 

    function setComission(uint8 amount) external onlyOwner {
        _comission = amount;
    }
    function withdrawComission() external onlyOwner {
        _WETH.transferFrom(address(this), msg.sender, _totalComissions);
    }

    function _safePayment(
        uint256 txnPrice,
        address buyer,
        address seller,
        address asset,
        uint256 tokenId
    ) internal {

        require(_WETH.allowance(buyer, address(this)) >= txnPrice, "GMP: Approve txnPrice");//for Dutch Auction Approve for more amount than what actual comes because until transaction happens the price will decline.
        require(_WETH.balanceOf(buyer) >= txnPrice, "GMP: Buyer out of balance");

        if((IERC165Upgradeable(asset).supportsInterface(_INTERFACE_ID_ERC2981))){
            (address receiver, uint256 royalty) = IERC2981Upgradeable(address(asset)).royaltyInfo(tokenId, txnPrice);
            uint256 comission_ = (txnPrice * _comission) / 100;

            _WETH.transferFrom(buyer, seller, txnPrice - royalty - comission_);
            _WETH.transferFrom(buyer, receiver, royalty);
            _WETH.transferFrom(buyer, address(this), comission_);

            _totalComissions += comission_;
        } else{
            uint256 comission_ = (txnPrice * _comission) / 100;
            _WETH.transferFrom(buyer, seller, txnPrice - comission_);
            _WETH.transferFrom(buyer, address(this), comission_);
            _totalComissions += comission_;
        }

    }

    function _safeTransfer(
        uint256 _tokenId,
        address _asset,
        address _from,
        address _to,
        uint256 _amount,
        AssetType _type
    ) internal {

        if (AssetType(_type) == AssetType.ERC721) {
            
            require(_amount == 1, "GMP: 1 required for ERC721");
            require(IERC721Upgradeable(_asset).supportsInterface(0x80ac58cd) == true, "GMP: Ivalid Asset");
            require(IERC721Upgradeable(_asset).ownerOf(_tokenId) == _from, "GMP: Not owned");
            if (_from != address(this))
                require(IERC721Upgradeable(_asset).getApproved(_tokenId) == address(this), "GMP: NFT Unapproved");
            IERC721Upgradeable(_asset).safeTransferFrom(_from, _to, _tokenId);
        } else if (AssetType(_type) == AssetType.ERC1155){
            require(IERC1155Upgradeable(_asset).supportsInterface(0xd9b67a26) == true, "GMP: Invalid Asset");
            require(IERC1155Upgradeable(_asset).balanceOf(_from, _tokenId) >= _amount, "GMP:: Not owned");
            if (_from != address(this))
                require(IERC1155Upgradeable(_asset).isApprovedForAll(_from, address(this)) == true, "GMP:: NFT Unapproved");
            IERC1155Upgradeable(_asset).safeTransferFrom(
                _from,
                _to,
                _tokenId,
                _amount,
                ""
            );
        } else{
            revert("GMP: Asset type is not supported");
        }
    }

        // this method can be used to return all itemIds // list/ oofer/auction
    function getAllItemIdss(address _nft, uint128 _tokenId, Status status) public view returns (uint256[] memory allListedItemIds, uint256[] memory allOfferedItemIds, uint256[] memory allAuctionedItemIds, uint256[] memory  allDutchItemIds) {
        allListedItemIds = getAllItemIds[_nft][_tokenId][status]._listedItemIds;
        allOfferedItemIds = getAllItemIds[_nft][_tokenId][status]._offeredItemIds;
        allAuctionedItemIds = getAllItemIds[_nft][_tokenId][status]._auctionedItemIds; 
        allDutchItemIds = getAllItemIds[_nft][_tokenId][status]._dutchItemIds;
    }

    function _setStatus(Status status, uint256 buyerSellerTypeStatus) internal pure returns (uint256 updatedBuyerSellerTypeStatus){
        return ( buyerSellerTypeStatus - uint256(uint8(buyerSellerTypeStatus)) + (uint256(status)) );
    }

    function _encodeAssetPrice(address asset, uint96 price) internal pure returns (uint256 assetPrice){
        assetPrice = (uint256(uint160(asset)) << 96) + uint256(price);
    }

    function _encodeTokenIdAmount(uint128 tokenId, uint128 amount) internal pure returns (uint256 tokenIdAMount){
        tokenIdAMount = (uint256(tokenId) << 128) + uint256(amount);
    }

    function _encodeTimeDuration(uint128 time, uint128 duration) internal pure returns (uint256 timeDuration){
        timeDuration = (uint256(time) << 128) + uint256(duration);
    }

    function _encodeBuyerSellerTypeStatus(address seller, AssetType assetType) internal pure returns (uint256 buyerSellerTypeStatus){
        buyerSellerTypeStatus =
            (uint256(uint160(seller)) << 96) +
            (uint256(assetType) << 88) +
            (uint256(Status.CREATE));
    }

    function _decodeAssetPrice(uint256 assetPrice)internal pure returns (address asset, uint96 price){
        asset = address(uint160(assetPrice >> 96));
        price = uint96(assetPrice);
    }

    function _decodeTokenIdAmount(uint256 tokenIdAmount)internal pure returns (uint128 tokenId, uint128 amount){
        tokenId = uint128(tokenIdAmount >> 128);
        amount = uint128(tokenIdAmount);
    }

    function _decodeTimeDuration(uint256 timeDuration)internal pure returns (uint128 time, uint128 duration){
        time = uint128(timeDuration >> 128);
        duration = uint128(timeDuration);
    }

    function _decodeBuyerSellerTypeStatus(uint256 buyerSellerTypeStatus) internal pure returns (address seller, AssetType assetType, Status status){
        seller = address(uint160(buyerSellerTypeStatus >> 96));
        assetType = AssetType(uint8(buyerSellerTypeStatus >> 88));
        status = Status(uint8(buyerSellerTypeStatus));
    }

    function _onlyOwner(address _addr, address sender) internal pure {
        if (_addr != sender) {
            revert ("GMP: Only creator access!");
        }
    }

    function _onlyCreatedItem(Status status) internal pure {
        if (status != Status.CREATE) {
            revert ("GMP: Only item with created status allowed");
        }
    }

    function onERC721Received(address,address,uint256,bytes calldata) external pure override returns (bytes4) {
        return IERC721ReceiverUpgradeable.onERC721Received.selector;
    }
    function onERC1155Received(address,address,uint256,uint256,bytes calldata) external pure override returns (bytes4) {
        return IERC1155ReceiverUpgradeable.onERC1155Received.selector;
    }
    function onERC1155BatchReceived(address,address,uint256[] calldata,uint256[] calldata,bytes calldata) external pure override returns (bytes4) {
        return IERC1155ReceiverUpgradeable.onERC1155BatchReceived.selector;
    }
    function supportsInterface(bytes4 interfaceId)external pure override returns (bool)
    {
        return interfaceId == IERC165Upgradeable.supportsInterface.selector;
    }

}