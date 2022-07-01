//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Context.sol";

error PurchaseQuantityExceeded();
error PurchaseNoQuantity();
error PurchaserOverpaid();
error PurchaserUnderpaid();
error NotPurchasable();

contract ZetaMembershipPaymentReceiver is
  Context,
  Ownable
{
  struct PurchaseData {
    uint256 purchaseId;
    uint256 purchaseDate;
    uint256 quantity;
    string memo;
  }

  bool public isPurchasable = true;
  uint256 public maxPurchasableQuantity;
  uint256 public price;
  uint256 public purchasesCounter;
  address[] public purchasers;
  mapping(address => PurchaseData[]) public purchases;

  // keep the event data unstructured to make serialization easier
  event Purchase(
    uint256 purchaseId,
    address purchaser,
    uint256 purchaseDate,
    uint256 quantity,
    uint256 price,
    string memo
  );

  constructor(uint256 _price, uint256 _maxPurchasableQuantity, uint256 _purchasesCounter) {
    price = _price;
    maxPurchasableQuantity = _maxPurchasableQuantity;
    purchasesCounter = _purchasesCounter;
  }

  // limit malicious attacks by calling non-existent functions
  fallback() external payable {
    // TODO Log event that someone was trying to call a non-existent function
  }

  // transfer funds if someone pays the contract directly
  // this is *not* a purchase operation
  receive() external payable {
    if (msg.value != 0) {
      payable(owner()).transfer(msg.value);
    }
  }

  function purchase(uint256 quantity, string calldata memo) public payable {
    if (!isPurchasable) {
      revert NotPurchasable();
    }

    if (quantity == 0) {
      revert PurchaseNoQuantity();
    }

    if (quantity > maxPurchasableQuantity) {
      revert PurchaseQuantityExceeded();
    }

    if (msg.value > price * quantity) {
      revert PurchaserOverpaid();
    }

    if (msg.value < price * quantity) {
      revert PurchaserUnderpaid();
    }

    PurchaseData memory data;
    // increment after save
    data.purchaseId = purchasesCounter++;
    // solhint-disable-next-line not-rely-on-time
    data.purchaseDate = block.timestamp;
    data.quantity = quantity;
    data.memo = memo;

    if (purchases[_msgSender()].length == 0) {
      purchasers.push(_msgSender());
    }
    purchases[_msgSender()].push(data);

    // solhint-disable-next-line not-rely-on-time
    emit Purchase(data.purchaseId, _msgSender(), block.timestamp, quantity, price, memo);
  }

  function getPurchasers()
    public
    view
    returns (address[] memory)
  {
    if (purchasers.length == 0) {
      return new address[](0);
    }
    return getPurchasers(0, purchasers.length - 1);
  }

  function getPurchasers(uint256 start)
    public
    view
    returns (address[] memory)
  {
    if (purchasers.length == 0) {
      return new address[](0);
    }
    return getPurchasers(start, purchasers.length - 1);
  }

  function getPurchasers(uint256 start, uint256 end)
    public
    view
    returns (address[] memory)
  {
    require(
      start <= end,
      "InvalidRange"
    );
    require(
      start < purchasers.length &&
      end < purchasers.length,
      "IndexOutOfBounds"
    );
    uint256 count = end - start + 1;
    address[] memory slice = new address[](count);
    for (uint i = 0; i < count; i++) {
      slice[i] = purchasers[start + i];
    }

    return slice;
  }

  function getPurchasersLength()
    public
    view
    returns (uint256)
  {
    return purchasers.length;
  }

  function getPurchaserPurchases(address _address)
    public
    view
    returns (PurchaseData[] memory)
  {
    if (purchases[_address].length == 0) {
      return new PurchaseData[](0);
    }
    return getPurchaserPurchases(_address, 0, purchases[_address].length - 1);
  }

  function getPurchaserPurchases(address _address, uint256 start)
    public
    view
    returns (PurchaseData[] memory)
  {
    if (purchases[_address].length == 0) {
      return new PurchaseData[](0);
    }
    return getPurchaserPurchases(_address, start, purchases[_address].length - 1);
  }

  function getPurchaserPurchases(address _address, uint256 start, uint256 end)
    public
    view
    returns (PurchaseData[] memory)
  {
    require(
      start <= end,
      "InvalidRange"
    );
    require(
      start < purchases[_address].length &&
      end < purchases[_address].length,
      "IndexOutOfBounds"
    );
    uint256 count = end - start + 1;
    PurchaseData[] memory slice = new PurchaseData[](count);
    for (uint i = 0; i < count; i++) {
      slice[i] = purchases[_address][start + i];
    }

    return slice;
  }

  function getPurchaserPurchasesLength(address _address)
    public
    view
    returns (uint256)
  {
    return purchases[_address].length;
  }

  function setPrice(uint256 _price) public onlyOwner {
    price = _price;
  }

  function setIsPurchasable(bool _isPurchasable) public onlyOwner {
    isPurchasable = _isPurchasable;
  }

  function setMaxPurchasableQuantity(uint256 _maxPurchasableQuantity) public onlyOwner {
    maxPurchasableQuantity = _maxPurchasableQuantity;
  }

  function withdraw() external onlyOwner {
    payable(owner()).transfer(address(this).balance);
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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