// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC1155.sol)

pragma solidity ^0.8.0;

import "../token/ERC1155/IERC1155.sol";

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../token/ERC1155/IERC1155Receiver.sol";

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC165.sol)

pragma solidity ^0.8.0;

import "../utils/introspection/IERC165.sol";

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

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.1;

import {IERC1155} from "openzeppelin-contracts/contracts/interfaces/IERC1155.sol";
import {IERC165} from "openzeppelin-contracts/contracts/interfaces/IERC165.sol";
import {IDirectSale} from "./IDirectSale.sol";

contract DirectSale is IDirectSale {
    mapping(uint256 => Listing) public listings;
    uint256 public saleId;

    function list(address _contract, uint256 _assetId, uint256 _amount, uint256 _price) external returns (uint256) {
        require(_amount > 0, "DirectSale: Amount needs to be atleast 1");

        IERC1155(_contract).safeTransferFrom(msg.sender, address(this), _assetId, _amount, "");

        uint256 currentId = saleId;

        Listing memory listing = Listing(msg.sender, _contract, _assetId, _amount, _price, false);
        listings[currentId] = listing;

        emit List(currentId, msg.sender, _contract, _assetId, _amount, _price);

        return currentId;
    }

    function buy(uint256 _saleId) external payable {
        Listing storage listing = listings[_saleId];
        require(msg.value >= listing.price, "DirectSale: Insuficient Amount");
        require(!listing.ended, "DirectSale: Listing ended");

        IERC1155(listing._contract).safeTransferFrom(address(this), msg.sender, listing.assetId, listing.amount, "");

        payable(listing.seller).transfer(listing.price);
        listing.ended = true;

        emit Buy(_saleId, listing.seller, msg.sender, listing._contract, listing.assetId, listing.amount, listing.price);
    }

    function cancel(uint256 _saleId) external {
        Listing storage listing = listings[_saleId];
        require(listing.seller == msg.sender, "DirectSale: Not the owner");

        IERC1155(listing._contract).safeTransferFrom(address(this), listing.seller, listing.assetId, listing.amount, "");

        listing.ended = true;

        emit Cancel(_saleId, listing.seller, listing._contract, listing.assetId, listing.amount);
    }

    function getListing(uint256 _saleId) external view returns (Listing memory){
        return listings[_saleId];
    }

    function onERC1155Received(address _operator, address, uint256, uint256, bytes calldata)
        external
        view
        override
        returns (bytes4)
    {
        if (_operator == address(this)) {
            return this.onERC1155Received.selector;
        }

        return 0x0;
    }

    function onERC1155BatchReceived(address _operator, address, uint256[] calldata, uint256[] calldata, bytes calldata)
        external
        view
        override
        returns (bytes4)
    {
        if (_operator == address(this)) {
            return this.onERC1155BatchReceived.selector;
        }

        return 0x0;
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.1;

import "openzeppelin-contracts/contracts/interfaces/IERC1155.sol";
import "openzeppelin-contracts/contracts/interfaces/IERC1155Receiver.sol";
import "openzeppelin-contracts/contracts/interfaces/IERC165.sol";

interface IDirectSale is IERC165, IERC1155Receiver {
    struct Listing {
        address seller;
        address _contract;
        uint256 assetId;
        uint256 amount;
        uint256 price;
        bool ended;
    }

    event List(
        uint256 saleId, address indexed seller, address _contract, uint256 assetId, uint256 amount, uint256 price
    );

    event Buy(
        uint256 saleId,
        address indexed seller,
        address indexed buyer,
        address _contract,
        uint256 assetId,
        uint256 amount,
        uint256 price
    );

    event Cancel(uint256 saleId, address indexed seller, address _contract, uint256 assetId, uint256 amount);

    function list(address _contract, uint256 _assetId, uint256 _amount, uint256 _price) external returns (uint256);

    function buy(uint256 _saleId) external payable;

    function cancel(uint256 _saleId) external;

    function getListing(uint256 _saleId) external view returns (Listing memory);
}