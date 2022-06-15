// SPDX-FileCopyrightText: © Courtyard Inc. (https://courtyard.io)
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../minting-factory/IOrderBook.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";

/**
 * @title a mock of {CourtyardOrderBook} that has an infinite supply for each order Ids.
 */
contract InfiniteSupplyOrderBookMock is ERC165, IOrderBook {

    /* Constructor */
    constructor() {}

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return interfaceId == type(IOrderBook).interfaceId || super.supportsInterface(interfaceId);
    }

    function hasBeenPlaced(string memory) external override pure returns (bool) {
        return false;
    }

    function placeOrder(string memory, address) external pure override {
    }
    
}

// SPDX-FileCopyrightText: © Courtyard Inc. (https://courtyard.io)
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

/**
 * @title {IOrderBook} is the interface for an on-chain order book to record orders, so that an order with the same
 * id cannot be placed twice by accident, even when paying with a different currency (i.e. via a different checkout
 * contract)
 *  
 * While the long term solution would be to use a custom Oracle to perform checks and prevent concurrent orders,
 * The scope of the Courtyard "Minting Factory" MVP is limited enough for us to use a simple on-chain contract,
 * and have an off-chain listener to update the inventory when an event is submitted after a successful order.
 */
interface IOrderBook is IERC165 {

    /**
     * @dev check if an order for {id} has already been placed.
     */
    function hasBeenPlaced(string memory id) external view returns (bool);

    /**
     * @dev place and lock an order so that it cannot be placed again.
     * Requirement: the order has not been already placed.
     */
    function placeOrder(string memory id, address forAccount) external;

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