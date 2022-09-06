// SPDX-License-Identifier: MIT
// Nomos Marketplace
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract NomosAuctionMarket is ERC1155Holder {
    error AttemptWithdrawNoRewards(address sender);
    event NftClaimed(
        string auctionId,
        address minterContract,
        uint256 tokenId,
        address claimer
    );
    event SellerClaimed(
        string auctionId,
        uint256 priceInWei,
        address claimer
    );
    event BidderWithdrawal(
        string auctionId,
        uint256 receivable,
        address claimer
    );
    event WinnerRemainingWithdrawal(
        string auctionId,
        uint256 receivable,
        address claimer
    );
    struct NomosAuction {
        string auctionId;
        uint256 tokenId;
        uint256 amount;
        uint256 priceInWei;
        address collectionContract;
        address paymentTokenContract;
        address seller;
        address lastAcceptedBidder;
        uint256 auctionStart;
        uint256 auctionEnd;
        bool sold;
        bool started;
        bool winnerClaimed;
        bool sellerClaimed;
    }

    mapping(string => NomosAuction) auctions;
    mapping(string => mapping(address => uint256)) bids;
    address public _admin;
    constructor() {
        _admin = msg.sender;
    }

    modifier onlyAdmin() {
        require(msg.sender == _admin, "Only admin");
        _;
    }

    function getAuctionDetails(string memory auctionId) public view returns (NomosAuction memory) {
        return auctions[auctionId];
    }

    function auctionNft(
        string memory auctionId,
        uint256 tokenId,
        uint256 priceInWei,
        address collectionContract,
        uint256 auctionStart,
        uint256 auctionEnd
    ) public {
        auctionNft(
            auctionId,
            tokenId,
            priceInWei,
            collectionContract,
            auctionStart,
            auctionEnd,
            1
        );
    }

    function auctionNftWithToken(
        string memory auctionId,
        uint256 tokenId,
        uint256 priceInWei,
        address collectionContract,
        uint256 auctionStart,
        uint256 auctionEnd,
        uint256 amount,
        address paymentAddress
    ) public {
        require(auctions[auctionId].tokenId == 0, "Existing auction ID");
        IERC1155 minter = IERC1155(collectionContract);

        require(
            minter.balanceOf(msg.sender, tokenId) > 0,
            "Not enough balance"
        );

        NomosAuction memory auction = NomosAuction(
            auctionId,
            tokenId,
            1,
            priceInWei,
            collectionContract,
            paymentAddress, //paymentContract
            msg.sender, //seller
            address(0), //lastAcceptedBidder
            auctionStart,
            auctionEnd,
            false, //sold
            false, // started
            false,
            false
        );
        minter.safeTransferFrom(msg.sender, address(this), tokenId, amount, "");
        auctions[auctionId] = auction;
    }

    function auctionNft(
        string memory auctionId,
        uint256 tokenId,
        uint256 priceInWei,
        address collectionContract,
        uint256 auctionStart,
        uint256 auctionEnd,
        uint256 amount
    ) public {
        require(auctions[auctionId].tokenId == 0, "Existing auction ID");
        IERC1155 minter = IERC1155(collectionContract);

        require(
            minter.balanceOf(msg.sender, tokenId) > 0,
            "Not enough balance"
        );

        NomosAuction memory auction = NomosAuction(
            auctionId,
            tokenId,
            1,
            priceInWei,
            collectionContract,
            address(0), //paymentContract
            msg.sender, //seller
            address(0), //lastAcceptedBidder
            auctionStart,
            auctionEnd,
            false, //sold
            false, // started
            false,
            false
        );
        minter.safeTransferFrom(msg.sender, address(this), tokenId, amount, "");
        auctions[auctionId] = auction;
    }

    // TODO: add onlyAdmin
    function startAuction(string memory auctionId) public onlyAdmin {
        auctions[auctionId].started = true;
    }

    function submitBid(string memory auctionId) public payable {
        // require(block.timestamp < auctions[auctionId].auctionEnd, "Auction ended");
        // require(block.timestamp > auctions[auctionId].auctionStart, "Not yet started");
        // require(auctions[auctionId].started, "Not started");
        require(auctions[auctionId].lastAcceptedBidder != msg.sender, "Cannot resubmit if already accepted");
        require(!auctions[auctionId].sold, "Already sold");
        require(auctions[auctionId].amount > 0, "Not enough supply");
        require(
            auctions[auctionId].seller != msg.sender,
            "Cannot buy own item"
        );

        require(
            msg.value > auctions[auctionId].priceInWei,
            "Bid should be higher"
        );

        bids[auctionId][msg.sender] += msg.value;
        auctions[auctionId].lastAcceptedBidder = msg.sender;
        auctions[auctionId].priceInWei = msg.value;
    }

    // Token bids, Should be approved first by the ERC20 contract
    function submitBidWithToken(string memory auctionId, uint256 amount) public {
        // require(block.timestamp < auctions[auctionId].auctionEnd, "Auction ended");
        // require(block.timestamp > auctions[auctionId].auctionStart, "Not yet started");
        // require(auctions[auctionId].started, "Not started");
        require(auctions[auctionId].lastAcceptedBidder != msg.sender, "Cannot resubmit if already accepted");
        require(!auctions[auctionId].sold, "Already sold");
        require(auctions[auctionId].amount > 0, "Not enough supply");
        require(
            auctions[auctionId].seller != msg.sender,
            "Cannot buy own item"
        );
        require(amount > auctions[auctionId].priceInWei, "Bid should be higher");

        IERC20 erc20 = IERC20(auctions[auctionId].paymentTokenContract);
        erc20.transferFrom(msg.sender, address(this), amount);

        bids[auctionId][msg.sender] += amount;
        auctions[auctionId].lastAcceptedBidder = msg.sender;
        auctions[auctionId].priceInWei = amount;
    }

    function getClaimableForAuction(string memory auctionId) public view returns (uint256) {
        return bids[auctionId][msg.sender];
    }

    // will send the NFT to the winning bid
    function claimNft(string memory auctionId) public {
        // require(block.timestamp > auctions[auctionId].auctionEnd, "Auction not yet ended");
        require(auctions[auctionId].lastAcceptedBidder == msg.sender, "Only winning bidder");
        require(!auctions[auctionId].winnerClaimed, "Winner already claimed");

        IERC1155 minter = IERC1155(auctions[auctionId].collectionContract);
        minter.safeTransferFrom(address(this), msg.sender, auctions[auctionId].tokenId, 1, "");
        auctions[auctionId].winnerClaimed = true;
        auctions[auctionId].sold = true;
        emit NftClaimed(auctionId, auctions[auctionId].collectionContract, auctions[auctionId].tokenId, msg.sender);
    }

    function sellerRewards(string memory auctionId) public {
        // require(block.timestamp > auctions[auctionId].auctionEnd, "Auction not yet ended");
        require(auctions[auctionId].seller == msg.sender, "Only seller can claim");
        require(!auctions[auctionId].sellerClaimed, "Seller already claimed");

        if (auctions[auctionId].paymentTokenContract == address(0)) {
            payable(msg.sender).transfer(auctions[auctionId].priceInWei);
        } else {
            IERC20 erc20 = IERC20(auctions[auctionId].paymentTokenContract);
            erc20.approve(address(this), auctions[auctionId].priceInWei);
            erc20.transferFrom(address(this), msg.sender, auctions[auctionId].priceInWei);
        }

        auctions[auctionId].sellerClaimed = true;
        auctions[auctionId].sold = true;
        emit SellerClaimed(auctionId, auctions[auctionId].priceInWei, msg.sender);
    }

    // TODO: re-entrancy guard
    function withdraw(string memory auctionId) public {
        // require(block.timestamp > auctions[auctionId].auctionEnd, "Auction not yet ended");
        require(getClaimableForAuction(auctionId) > 0, "No withdrawable amount");

        // if you are the winning bid but also have losing bids
        uint256 receivable = 0;

        // check if the sender is the accepted bidder for the auction
        // if yes, then we will subtract the value of bid from the total bids
        if (auctions[auctionId].lastAcceptedBidder == msg.sender) {

            // if there are 2 or more bids, the bids[auctionId][msg.sender] will have
            // the 'losing' bids as well, so we set the receivable to the total of 'losing' bids only
            // somce the value in auctions will be sent to the seller
            if (getClaimableForAuction(auctionId) - auctions[auctionId].priceInWei > 0) {
                receivable = getClaimableForAuction(auctionId) - auctions[auctionId].priceInWei;
            }
        } else {
            // these are for everyone else that has bids
            receivable = getClaimableForAuction(auctionId);
        }

        if (receivable > 0) {
            if (auctions[auctionId].paymentTokenContract == address(0)) {
                payable(msg.sender).transfer(receivable);
            } else {
                IERC20 erc20 = IERC20(auctions[auctionId].paymentTokenContract);
                erc20.transferFrom(address(this), msg.sender, receivable);
            }

            bids[auctionId][msg.sender] = 0;

            if (auctions[auctionId].lastAcceptedBidder == msg.sender) {
                emit WinnerRemainingWithdrawal(auctionId, receivable, msg.sender);
            } else {
                emit BidderWithdrawal(auctionId, receivable, msg.sender);
            }
        } else{
            revert AttemptWithdrawNoRewards(msg.sender);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC1155/IERC1155.sol)

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

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

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/utils/ERC1155Holder.sol)

pragma solidity ^0.8.0;

import "./ERC1155Receiver.sol";

/**
 * Simple implementation of `ERC1155Receiver` that will allow a contract to hold ERC1155 tokens.
 *
 * IMPORTANT: When inheriting this contract, you must include a way to use the received tokens, otherwise they will be
 * stuck.
 *
 * @dev _Available since v3.1._
 */
contract ERC1155Holder is ERC1155Receiver {
    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] memory,
        uint256[] memory,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/utils/ERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../IERC1155Receiver.sol";
import "../../../utils/introspection/ERC165.sol";

/**
 * @dev _Available since v3.1._
 */
abstract contract ERC1155Receiver is ERC165, IERC1155Receiver {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return interfaceId == type(IERC1155Receiver).interfaceId || super.supportsInterface(interfaceId);
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
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}