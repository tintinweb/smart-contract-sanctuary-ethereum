/**
 *Submitted for verification at Etherscan.io on 2022-04-16
*/

// File: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/Context.sol


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

// File: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable.sol


// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
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

// File: BoombShop.sol


// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity 0.8.7;

// INTERFACES
interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}


contract BoombShop is Ownable {

// STRUCTS

      struct ProductInfo {
        address currency;    // ERC20 required to purchase a product.
        uint256 productQty;  // Quantity available of product.
        uint256 productCost; // Cost of product in Tokens or ETH.
        bytes32 productName; // Name of Product.
        bool    buyWithEth;  // Require product to be bought with ETH?
        bool    isActive;    // Product can be set to inactive or active to stop or start sales.
        bool    isSoldOut;   // Product must be in stock to be purchased.
    }
  
   mapping(uint256 => ProductInfo) private productInfo;
   uint256 public totalProducts;

// EVENTS
  event Buy(address indexed user, uint256 indexed productID);

// ADMIN FUNCTIONS

  function addProduct(address _currency, uint256 _productQty, uint256 _productCost, bytes32 _productName, bool _buyWithEth, bool _isActive) public onlyOwner { 
    require(_productQty >= 1 || _isActive == false, "Quantity must be greater than zero for the product to be active!");     
        ProductInfo storage product = productInfo[++totalProducts];
        product.currency     =   _currency;
        product.productQty   =   _productQty;
        product.productCost  =   _productCost;
        product.productName  =   _productName;
        product.buyWithEth   =   _buyWithEth;
        product.isActive     =   _isActive;
    }

  function editProduct(uint256 _productID, address _currency, uint256 _productQty, uint256 _productCost, bytes32 _productName, bool _buyWithEth, bool _isActive, bool _isSoldOut) public onlyOwner {
    require(_productID <= totalProducts, "Invalid product id!");
    require(_productQty >= 1 || _isActive == false, "Quantity must be greater than zero to be active!");
        productInfo[_productID].currency     =   _currency;
        productInfo[_productID].productQty   =   _productQty;
        productInfo[_productID].productCost  =   _productCost;
        productInfo[_productID].productName  =   _productName;
        productInfo[_productID].buyWithEth   =   _buyWithEth;
        productInfo[_productID].isActive     =   _isActive;
        productInfo[_productID].isSoldOut    =   _isSoldOut;
    }

  function withdraw() public onlyOwner {
    (bool os, ) = payable(owner()).call{value: address(this).balance}("");
    require(os);
    }

  function withdrawTokens (address _address, uint256 _amount) public onlyOwner {           
    IERC20(_address).transfer(msg.sender, _amount);
   }

// USER FUNCTIONS

  function buyProduct(uint256 _productID) payable public {
    ProductInfo storage product = productInfo[_productID];

    require (product.isActive, "Product is not active!");
    require (product.isSoldOut == false, "Product is sold out!");
    require (IERC20(product.currency).balanceOf(msg.sender) >= product.productCost, "You do not have enough BOOMB Tokens!");

    if (product.buyWithEth == true) {
    require(msg.value == product.productCost, "Insufficient funds!");
    }

    else {
    IERC20(product.currency).transferFrom(msg.sender, address(this), product.productCost);
    }
    product.productQty = product.productQty - 1;

    if (product.productQty == 0) {
      product.isSoldOut = true;
    }

    emit Buy(msg.sender, _productID);

  }

// VIEW FUNCTIONS

   function getProductInfo(uint256 _productID) public view returns(address currency, uint256 productQty, uint256 productCost, bytes32 productName, bool buyWithEth, bool isActive, bool isSoldOut) {
        ProductInfo storage product = productInfo[_productID];
        return (address(product.currency), product.productQty, product.productCost, product.productName, product.buyWithEth, product.isActive, product.isSoldOut);
    }

}