// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/utils/Counters.sol";
// import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";

import "./interfaces/ITreasury.sol";
import "./interfaces/IFactory.sol";
import "./interfaces/IERC721.sol";

contract NFTMarket is ERC1155Holder {
    using Counters for Counters.Counter;
    Counters.Counter private _itemIds;
    uint256 listingPrice = 250;
    uint256 creatorFee = 250;
    ITreasury treasury;
    IFactory factory;

    struct MarketItem {
        uint256 itemId;
        address nftAddress;
        uint256 ercType;
        uint256 tokenId;
        address payable seller;
        uint256 price;
        uint256 amount;
    }
    uint256 private nextSaleId;
    mapping(uint256 => MarketItem) public idToMarketItem;

    event PriceChange(uint256 indexed saleId, uint256 price);
    event SaleCanceled(uint256 indexed saleId);
    event MarketItemCreated(
        uint256 indexed itemId,
        address indexed nftAddress,
        uint256 ercType,
        uint256 indexed tokenId,
        address seller,
        uint256 price,
        uint256 amount
    );
    event TokenBought(
        uint256 indexed saleId,
        address indexed seller,
        address indexed buyer,
        uint256 price
    );

    modifier onlyAdmin() {
        require(treasury.isAdmin(msg.sender), "Restricted method");
        _;
    }

    constructor(ITreasury _tresury) {
        treasury = _tresury;
    }

    function init(IFactory _factory) public onlyAdmin {
        factory = _factory;
    }

    function getListingPrice() public view returns (uint256) {
        return listingPrice;
    }

    function setListingPrice(uint256 commission) public onlyAdmin {
        listingPrice = commission;
    }

    function setCreatorFee(uint256 fee) public onlyAdmin {
        creatorFee = fee;
    }

    function getMarketItem(uint256 marketItemId)
        public
        view
        returns (MarketItem memory)
    {
        return idToMarketItem[marketItemId];
    }

    function _getNextAndIncrementSaleId() internal returns (uint256) {
        return nextSaleId++;
    }

    function createSale(
        uint256 tokenId,
        address nftAddress,
        uint256 price
    ) public {
        _itemIds.increment();
        uint256 itemId = _itemIds.current();

        IERC721col(nftAddress).transferFrom(tx.origin, address(this), tokenId);

        idToMarketItem[itemId] = MarketItem(
            itemId,
            nftAddress,
            721,
            tokenId,
            payable(tx.origin),
            price,
            1
        );

        emit MarketItemCreated(
            itemId,
            nftAddress,
            721,
            tokenId,
            tx.origin,
            price,
            1
        );
    }

    function createSale(
        uint256 tokenId,
        address nftAddress,
        uint256 price,
        uint256 amount
    ) public {
        _itemIds.increment();
        uint256 itemId = _itemIds.current();

        IERC1155(nftAddress).safeTransferFrom(
            tx.origin,
            address(this),
            tokenId,
            amount,
            ""
        );

        idToMarketItem[itemId] = MarketItem(
            itemId,
            nftAddress,
            1155,
            tokenId,
            payable(tx.origin),
            price,
            amount
        );

        emit MarketItemCreated(
            itemId,
            nftAddress,
            1155,
            tokenId,
            tx.origin,
            price,
            amount
        );
    }

    function _buyToken(MarketItem memory sale, uint256 saleId) internal {
        if (sale.ercType == 721) {
            IERC721col(sale.nftAddress).transferFrom(
                address(this),
                msg.sender,
                sale.tokenId
            );
            delete idToMarketItem[saleId];
        } else {
            IERC1155(sale.nftAddress).safeTransferFrom(
                address(this),
                msg.sender,
                sale.tokenId,
                1,
                ""
            );
            if (sale.amount == 1) {
                delete idToMarketItem[saleId];
            } else {
                sale.amount--;
            }
        }
    }

    function distributeFunds(
        address payable seller,
        uint256 price,
        address nft,
        uint256 tokenId
    ) internal {
        uint256 commission = (price * listingPrice) / 10000;
        uint256 sellerEarning = price - commission;
        if (factory.isCollection(nft)) {
            uint256 crFee = (price * creatorFee) / 10000;
            sellerEarning -= crFee;
            address creator = IERC721col(nft).creatorOf(tokenId);
            payable(creator).transfer(crFee);
        }

        seller.transfer(sellerEarning);
        (bool success, ) = address(treasury).call{value: commission}("");
        require(
            success,
            "Address: unable to send value, recipient may have reverted"
        );
    }

    function buyToken(uint256 itemId) public payable {
        MarketItem memory sale = idToMarketItem[itemId];
        require(msg.sender != sale.seller, "Market: Can't buy your own sale");
        require(msg.value == sale.price, "Market: incorrect transacion value");

        _buyToken(sale, itemId);
        distributeFunds(sale.seller, sale.price, sale.nftAddress, sale.tokenId);

        emit TokenBought(itemId, sale.seller, msg.sender, sale.price);
    }

    function changeSalePrice(uint256 saleId, uint256 _newPrice) public {
        MarketItem memory sale = idToMarketItem[saleId];
        require(sale.seller == msg.sender, "Market: Not your sale");
        sale.price = _newPrice;
        emit PriceChange(saleId, _newPrice);
    }

    function cancelSale(uint256 saleId) public {
        MarketItem memory sale = idToMarketItem[saleId];
        require(sale.seller == msg.sender, "Market: Not your sale");
        if (sale.ercType == 721) {
            IERC721col(sale.nftAddress).transferFrom(
                address(this),
                sale.seller,
                sale.tokenId
            );
        } else {
            IERC1155(sale.nftAddress).safeTransferFrom(
                address(this),
                sale.seller,
                sale.tokenId,
                sale.amount,
                ""
            );
        }

        delete idToMarketItem[saleId];
        emit SaleCanceled(saleId);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
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
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/utils/ERC1155Holder.sol)

pragma solidity ^0.8.0;

import "./ERC1155Receiver.sol";

/**
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

// SPDX-License-Identifier: MIT OR Apache-2.0
// solhint-disable
pragma experimental ABIEncoderV2;
pragma solidity ^0.8.0;

interface ITreasury {

function isAdmin(address who) external returns (bool);

function isOperator(address who) external returns (bool);

}

// SPDX-License-Identifier: MIT OR Apache-2.0
// solhint-disable
pragma experimental ABIEncoderV2;
pragma solidity ^0.8.0;

interface IFactory {

function isCollection(address col) external returns (bool);

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

interface IERC721col {

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function creatorOf(uint256 _tokenId) external returns(address);
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
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/IERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev _Available since v3.1._
 */
interface IERC1155Receiver is IERC165 {
    /**
        @dev Handles the receipt of a single ERC1155 token type. This function is
        called at the end of a `safeTransferFrom` after the balance has been updated.
        To accept the transfer, this must return
        `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
        (i.e. 0xf23a6e61, or its own function selector).
        @param operator The address which initiated the transfer (i.e. msg.sender)
        @param from The address which previously owned the token
        @param id The ID of the token being transferred
        @param value The amount of tokens being transferred
        @param data Additional data with no specified format
        @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
    */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    /**
        @dev Handles the receipt of a multiple ERC1155 token types. This function
        is called at the end of a `safeBatchTransferFrom` after the balances have
        been updated. To accept the transfer(s), this must return
        `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
        (i.e. 0xbc197c81, or its own function selector).
        @param operator The address which initiated the batch transfer (i.e. msg.sender)
        @param from The address which previously owned the token
        @param ids An array containing ids of each token being transferred (order and length must match values array)
        @param values An array containing amounts of each token being transferred (order and length must match ids array)
        @param data Additional data with no specified format
        @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
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