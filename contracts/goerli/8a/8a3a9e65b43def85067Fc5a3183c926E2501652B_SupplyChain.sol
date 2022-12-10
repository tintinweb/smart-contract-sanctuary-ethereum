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
// OpenZeppelin Contracts (last updated v4.6.0) (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

// Errors
error NotListed();
error PriceMustNotZero();
error PriceNotMet();
error NotOwner();

contract SupplyChain {
    using Counters for Counters.Counter;
    using SafeMath for uint256;
    Counters.Counter private _tokenIDs;

    // State Variables
    struct Product {
        string productName;
        uint256 tokenId;
        uint256 productQuantity;
        uint256 productPrice;
        string cateory;
        address seller;
    }
    struct Owners {
        address farmerAddress;
        address distributerAddress;
        address retailerAddress;
    }

    // Mappings - To keep track of Products and it's owners
    // Farmers inventory - tokenId => Product
    mapping(uint256 => Product) public s_farmerInventory;
    // Distributer inventory - tokenId => Product
    mapping(uint256 => Product) public s_distributerInventory;
    // Total stock in distributer inventory - Poducts name => Product
    mapping(string => Product) public s_totalDistibuterInventory;
    // Token Id to all the owners
    mapping(uint256 => Owners) public s_productOwners;
    // Product Name => List of products in distributers inventory
    // Because retailer may not know the token id
    mapping(string => Product) public s_productDistributer;

    // Events - fire events on state changes
    event ItemListed(
        string indexed productName,
        uint256 indexed tokenId,
        uint256 productQuantity,
        uint256 productPrice,
        address indexed seller
    );
    event ItemBough(
        string indexed productName,
        uint256 indexed tokenId,
        uint256 productQuantity,
        uint256 productPrice,
        address indexed seller
    );
    event ItemCanceled(
        string indexed productName,
        uint256 indexed tokenId,
        address indexed seller
    );

    // Modifiers
    // Item not listed Yet
    modifier notListed(uint256 _tokenID) {
        Product memory product = s_farmerInventory[_tokenID];
        if (product.productPrice <= 0) {
            revert NotListed();
        }
        _;
    }

    // Can be called only by owner
    modifier isOwner(uint256 _tokenID) {
        Product memory product = s_farmerInventory[_tokenID];
        if (product.seller != msg.sender) {
            revert NotOwner();
        }
        _;
    }

    // Functions
    /// @notice List the product details on the marketplace
    /// @param _ProductName - Name of the product
    /// @param _quantity - Quantity of product to be sold
    /// @param _price price of the product to be sold
    function listItem(
        string memory _ProductName,
        uint256 _quantity,
        uint256 _price,
        string memory _category
    ) external {
        if (_price <= 0) {
            revert PriceMustNotZero();
        }
        _tokenIDs.increment();
        uint256 currentID = _tokenIDs.current();
        s_farmerInventory[currentID] = Product(
            _ProductName,
            currentID,
            _quantity,
            _price,
            _category,
            msg.sender
        );
        s_productOwners[currentID].farmerAddress = msg.sender;
        emit ItemListed(_ProductName, currentID, _quantity, _price, msg.sender);
    }

    /// @notice Update the price of an already listed product
    /// @param _tokenID - The token id of the product to be updated
    /// @param _newPrice - The price to which you want to update it.
    function updateListing(
        uint256 _tokenID,
        uint256 _newPrice
    ) external notListed(_tokenID) isOwner(_tokenID) {
        s_farmerInventory[_tokenID].productPrice = _newPrice;
    }

    /// @notice Cancel the listing of a product
    /// @param _tokenID - The token id of the product to be canceled
    function cancelItem(
        uint256 _tokenID
    ) external notListed(_tokenID) isOwner(_tokenID) {
        Product memory product = s_farmerInventory[_tokenID];
        delete (s_farmerInventory[_tokenID]);
        emit ItemCanceled(product.productName, _tokenID, product.seller);
    }

    // Distributer functions
    /// @notice Buy the product from farmer and add it into distributer's inventory
    /// @param _tokenID - The token id of the product to be bought
    function buyItem(uint256 _tokenID) external payable notListed(_tokenID) {
        Product memory product = s_farmerInventory[_tokenID];
        if (msg.value != product.productPrice) {
            revert PriceNotMet();
        }
        delete (s_farmerInventory[_tokenID]);
        uint256 newPrice = (product.productPrice +
            (product.productPrice * 20) /
            100);
        s_distributerInventory[_tokenID] = Product(
            product.productName,
            product.tokenId,
            product.productQuantity,
            newPrice,
            product.cateory,
            msg.sender
        );
        s_totalDistibuterInventory[product.productName] = Product(
            product.productName,
            product.tokenId,
            product.productQuantity,
            newPrice,
            product.cateory,
            msg.sender
        );
        s_productOwners[product.tokenId].distributerAddress = msg.sender;
        s_productDistributer[product.productName] = Product(
            product.productName,
            product.tokenId,
            product.productQuantity,
            newPrice,
            product.cateory,
            msg.sender
        );
        payable(product.seller).transfer(product.productPrice);

        // To keep track of total quantity of specific product
        if (
            keccak256(
                abi.encodePacked(
                    s_totalDistibuterInventory[product.productName].productName
                )
            ) == keccak256(abi.encodePacked(product.productName))
        ) {
            s_totalDistibuterInventory[product.productName].productQuantity =
                s_totalDistibuterInventory[product.productName]
                    .productQuantity +
                product.productQuantity;
        }
    }

    // Retailer's Functions
    /// @notice Purchase the item from distributer
    /// @param _tokenID - The token id of the product to be bought
    function purchaseItem(uint256 _tokenID) external payable {
        Product memory product = s_distributerInventory[_tokenID];
        if (product.productPrice < 0) {
            revert NotListed();
        }
        if (msg.value != product.productPrice) {
            revert PriceNotMet();
        }
        delete (s_distributerInventory[_tokenID]);
        s_totalDistibuterInventory[product.productName].productQuantity =
            s_totalDistibuterInventory[product.productName].productQuantity -
            product.productQuantity;
        delete (s_productDistributer[product.productName]);
        s_productOwners[product.tokenId].retailerAddress = msg.sender;
        payable(product.seller).transfer(product.productPrice);
    }

    // Getter functions

    function getFarmersListing(
        uint256 _tokenID
    ) external view returns (Product memory) {
        return s_farmerInventory[_tokenID];
    }

    function getDistributerInventory(
        uint256 _tokenID
    ) external view returns (Product memory) {
        return s_distributerInventory[_tokenID];
    }

    function getTotalQuantity(
        string memory _ProductName
    ) external view returns (Product memory) {
        return s_totalDistibuterInventory[_ProductName];
    }

    function getAllOwners(
        uint256 _tokenID
    ) external view returns (Owners memory) {
        return s_productOwners[_tokenID];
    }

    function searchDistributer(
        string memory _productName
    ) external view returns (Product memory) {
        return s_productDistributer[_productName];
    }
}