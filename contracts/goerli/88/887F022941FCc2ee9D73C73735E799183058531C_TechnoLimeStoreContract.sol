// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";

error LimeTechStore__BlankField();
error LimeTechStore__IllegalQuantityInput();
error LimeTechStore__OutOfStock();
error LimeTechStore__AlreadyOwnedProduct();
error LimeTechStore__ExpiredWarrantyProduct();
error LimeTechStore__NotBoughtProductFromUser();

contract TechnoLimeStoreContract is Ownable {
    struct Product {
        string name;
        uint32 quantity;
    }
    bytes32[] public productIds;

    mapping(bytes32 => Product) public productLedger;
    // productName => id relation
    mapping(string => bytes32) private isProductNameId;
    // productId => block.number product validity date timespan
    mapping(address => mapping(bytes32 => uint256)) public productValidity;
    // msg.sender => id relation if product is owned
    mapping(address => mapping(bytes32 => bool))
        private isProductCurrentlyOwned;
    mapping(bytes32 => address[]) public productUsers;

    event LogTechnoProductAdded(string indexed name, uint32 indexed quantity);
    event LogTechnoProductBought(
        bytes32 productId,
        uint256 indexed datePurchased,
        address user
    );
    event LogTechnoProductReturned(bytes32 productId);

    /**
     * @dev Function for add new product permissioned only to admin/owner of the contract.
     * When product name is already present and it is provided productId the quantity only increases.
     */
    function addNewProduct(string calldata _name, uint32 _quantity)
        external
        onlyOwner
    {
        if (bytes(_name).length == 0) {
            revert LimeTechStore__BlankField();
        }
        if (_quantity <= 0) {
            revert LimeTechStore__IllegalQuantityInput();
        }
        if (isProductNameId[_name] == 0) {
            Product memory newProduct = Product(_name, _quantity);
            bytes32 productId = keccak256(abi.encodePacked(_name, _quantity));
            productLedger[productId] = newProduct;
            productIds.push(productId);
            isProductNameId[_name] = productId;
            emit LogTechnoProductAdded(_name, _quantity);
        } else {
            bytes32 savedproductId = isProductNameId[_name];
            Product memory storedProduct = productLedger[savedproductId];
            storedProduct.quantity += _quantity;
            productLedger[savedproductId] = storedProduct;
        }
    }

    function buyProduct(bytes32 productId) external {
        if (isProductCurrentlyOwned[msg.sender][productId] == true) {
            revert LimeTechStore__AlreadyOwnedProduct();
        }
        Product storage product = productLedger[productId];
        if (product.quantity < 1) {
            revert LimeTechStore__OutOfStock();
        }
        productValidity[msg.sender][productId] = block.number;
        isProductCurrentlyOwned[msg.sender][productId] = true;
        productUsers[productId].push(msg.sender);
        product.quantity -= 1;
        emit LogTechnoProductBought(
            productId,
            productValidity[msg.sender][productId],
            msg.sender
        );
    }

    function returnProduct(bytes32 productId) external {
        if (isProductCurrentlyOwned[msg.sender][productId] == false) {
            revert LimeTechStore__NotBoughtProductFromUser();
        }
        if ((block.number - productValidity[msg.sender][productId]) > 100) {
            revert LimeTechStore__ExpiredWarrantyProduct();
        }
        Product storage product = productLedger[productId];
        product.quantity += 1;
        isProductCurrentlyOwned[msg.sender][productId] = false;
        emit LogTechnoProductReturned(productId);
    }

    /**
     * @dev This is the function for get all ids for the input product.
     * It is a better to have getting of ids and then retrieving all data by id
     * insead of iterating with foreach in the smart contract
     */
    function getAllAvailableProductIds()
        external
        view
        returns (bytes32[] memory)
    {
        return productIds;
    }

    function getProductDetail(bytes32 _id)
        external
        view
        returns (string memory, uint32)
    {
        return (productLedger[_id].name, productLedger[_id].quantity);
    }

    function getProductUsers(bytes32 uid)
        external
        view
        returns (address[] memory)
    {
        return productUsers[uid];
    }

    function getProductValidity(bytes32 uid) external view returns (uint256) {
        return productValidity[msg.sender][uid];
    }

    function isProductAlreadyOwned(bytes32 uid) external view returns (bool) {
        return isProductCurrentlyOwned[msg.sender][uid];
    }
}