//SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./ICollection.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract Shop is ReentrancyGuard {
  struct ProductOrder {
    uint256 productId;
    uint256 amount;
  }

  function purchase(
    address collectionAddress,
    ProductOrder[] memory productOrders
  ) external payable nonReentrant {
    ICollection collection = ICollection(collectionAddress);
    uint256 total = calculateTotal(collection, productOrders);
    require(msg.value == total, "ERROR_INCORRECT_PAYMENT");

    for (uint256 i = 0; i < productOrders.length; i++) {
      ProductOrder memory productOrder = productOrders[i];
      collection.mint(msg.sender, productOrder.productId, productOrder.amount);
    }
  }

  function calculateTotal(
    ICollection collection,
    ProductOrder[] memory productOrders
  ) private view returns (uint256 totalPrice) {
    for (uint256 i = 0; i < productOrders.length; i++) {
      ProductOrder memory productOrder = productOrders[i];
      totalPrice +=
        collection.products(productOrder.productId).price *
        productOrder.amount;
    }
    return totalPrice;
  }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./Product.sol";
import "./Item.sol";

interface ICollection {
  function itemsCreated() external view returns (uint256);

  function getAllProducts() external view returns (Product[] memory);

  function products(uint256 productId) external view returns (Product memory);

  function getProducts(uint256 startProductId, uint256 endProductId)
    external
    view
    returns (Product[] memory);

  function items(uint256 itemId) external view returns (Item memory);

  function newProduct(
    uint256 stock,
    uint256 price,
    string memory URI
  ) external returns (uint256 productId);

  function mint(
    address to,
    uint256 productId,
    uint256 amount
  ) external;

  function mintWithItemMetadata(
    address to,
    uint256 productId,
    uint256 amount,
    string memory URI
  ) external;

  function addProductMetadata(uint256 productId, string memory URI) external;

  function addItemMetadata(uint256 itemId, string memory URI) external;

  function updateCustomMetadata(uint256 itemId, string memory URI) external;

  function getCustomMetadata(address creator, uint256 itemId)
    external
    view
    returns (string memory);

  function setStock(uint256 productId, uint256 stock) external;

  function productsCreated() external view returns (uint256);
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
pragma solidity ^0.8.9;

struct Item {
  uint256 id;
  string URI;
  bool frozen;
  uint256 productId;
  string[] additionalURIs;
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

struct Product {
  uint256 id;
  string URI;
  bool frozen;
  uint256 stockLimit;
  uint256 mintedItems;
  uint256 price;
  string[] additionalURIs;
}