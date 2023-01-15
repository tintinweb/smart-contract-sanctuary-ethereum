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

error foodTrusty__NotRegistered();

contract foodTrusty is Ownable {
    mapping(address => bool) public restaurant;
    mapping(address => bool) public manufacturer;
    mapping(address => bool) public grower;
    mapping(address => bool) public slaughter;
    mapping(address => bool) public wholesaler;
    mapping(address => bool) public admin;

    uint256 productID = 1;

    struct product {
        string ipfsHash;
        uint256 addingTime;
        uint256 productId;
    }
    product[] public products;

    event productAdd(
        address indexed adder,
        uint256 indexed productId,
        product indexed _product
    );

    constructor() {
        manufacturer[0xb636C663De47df7cf95F1E87C86745dd7f7E3d67] = true;
        manufacturer[0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266] = true;
    }

    modifier isRegistered(address _addresss) {
        if (
            restaurant[_addresss] ||
            manufacturer[_addresss] ||
            grower[_addresss] ||
            slaughter[_addresss] ||
            wholesaler[_addresss] ||
            admin[_addresss]
        ) {
            _;
        } else revert foodTrusty__NotRegistered();
    }

    function addProduct(
        string memory _ipfsHash
    ) public isRegistered(msg.sender) {
        products.push(product(_ipfsHash, block.timestamp, productID));
        emit productAdd(
            msg.sender,
            productID,
            product(_ipfsHash, block.timestamp, productID)
        );

        productID++;
    }

    function addRestaurant(address _restaurant) public onlyOwner {
        restaurant[_restaurant] = true;
    }

    function addGrower(address _grower) public onlyOwner {
        grower[_grower] = true;
    }

    function addSlaughter(address _slaughter) public onlyOwner {
        slaughter[_slaughter] = true;
    }

    function addManufacturer(address _manufacturer) public onlyOwner {
        manufacturer[_manufacturer] = true;
    }

    function addWholesaler(address _wholesaler) public onlyOwner {
        wholesaler[_wholesaler] = true;
    }

    function getProductById(
        uint256 _productId
    ) public view returns (string memory, uint256, uint256) {
        product memory _product = products[_productId - 1];
        return (_product.ipfsHash, _product.addingTime, _product.productId);
    }

    function getManufacturer(address _manufacturer) public view returns (bool) {
        return manufacturer[_manufacturer];
    }

    function getRestaurant(address _restaurant) public view returns (bool) {
        return restaurant[_restaurant];
    }

    function getGrower(address _grower) public view returns (bool) {
        return grower[_grower];
    }

    function getSlaughter(address _slaughter) public view returns (bool) {
        return slaughter[_slaughter];
    }

    function getWholesaler(address _wholesaler) public view returns (bool) {
        return wholesaler[_wholesaler];
    }

    function getAdmin(address _admin) public view returns (bool) {
        return admin[_admin];
    }
}