/**
 *Submitted for verification at Etherscan.io on 2022-11-12
*/

// SPDX-License-Identifier: MIT

// File: contracts\Context.sol

// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.13;

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

// File: contracts\Ownable.sol

// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.13;
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

// File: contracts\Escrow.sol


pragma solidity ^0.8.13;
contract Escrow is Ownable {
  enum STATUS { CREATED, ACCEPTED, MILESTONE_SET, RELEASED, REFUNDED }  // enum for various status of transaction.

  struct Transaction {
    uint256 itemId;
    address buyer;
    address seller;
    address arbiter;
    uint256 price;
    uint256 milestone;
    uint256 approveReleaseCount;
    uint256 approveRefundCount;
    mapping(address => bool) approvedRelease;
    mapping(address => bool) approvedRefund;
    STATUS status;
  } // Transaction struct

  mapping(address => bool) creatorList;   // Address list in which each address will be the creator of transactions.
                                          // This list is set by the owner of this smart contract.
  mapping(uint256 => Transaction) txList; // All transaction lists.

  // Events.
  event Creat(uint256 itemId, address creator, address seller, uint256 price);
  event Accept(uint256 itemId, address buyer);
  event MilestoneSet(uint256 itemId, uint256 amount);
  event Released(uint256 itemId, uint256 amount);
  event Refunded(uint256 itemId, uint256 amount);

  constructor() {}

  /*
  * @Modifier to check if the current account has permission to create a new transaction.
  */
  modifier isCreator() {
    require(creatorList[msg.sender], "You don't have permission to create a new transaction.");
    _;
  }

  /*
  * @Modifier to check if the current account is the creator of a certain transaction.
  */
  modifier onlyCreator(uint256 itemId) {
    require(txList[itemId].arbiter == msg.sender, "You are not a creator of this transaction.");
    _;
  }

  /*
  * @Modifier to check if the current account is buyer or seller or arbiter of a certain transaction.
  */
  modifier onlyTxAccounts(uint256 itemId) {
    require(
      txList[itemId].buyer == msg.sender ||
      txList[itemId].seller == msg.sender ||
      txList[itemId].arbiter == msg.sender,
      "You are not an account who is related to this transaction."
    );
    _;
  }

  /*
  * @Modifier to check if the current account is buyer of transaction.
  */
  modifier onlyBuyer(uint256 itemId) {
    require(msg.sender == txList[itemId].buyer, "You are not the buyer of this transaction");
    _;
  }

  /*
  * @Function to add a creator. This should be done only by owner of this smart contract.
  */
  function addCreator(address account) external onlyOwner {
    creatorList[account] = true;
  }

  /*
  * @Function to remove a creator.
  */
  function removeCreator(address account) external onlyOwner {
    creatorList[account] = false;
  }

  /*
  * @Function to get transaction information.
  */
  function getTxInformation(uint256 itemId) external view returns (address, address, address, uint256, uint256, STATUS, bool, bool, bool, bool, bool, bool) {
    Transaction storage temp = txList[itemId];
    return (
      temp.buyer,
      temp.seller,
      temp.arbiter,
      temp.price,
      temp.milestone,
      temp.status,
      temp.approvedRelease[temp.buyer],
      temp.approvedRelease[temp.seller],
      temp.approvedRelease[temp.arbiter],
      temp.approvedRefund[temp.buyer],
      temp.approvedRefund[temp.seller],
      temp.approvedRefund[temp.arbiter]
    );
  }

  /*
  * @Function to create a new transaction. Creator of this transaction will be the arbiter of this tx.
  */
  function addTx(uint256 itemId, address seller, uint256 price) external isCreator {
    require(price > 0, "Product price should be bigger than 0.");
    txList[itemId].itemId = itemId;
    txList[itemId].seller = seller;
    txList[itemId].price = price;
    txList[itemId].arbiter = msg.sender;

    emit Creat(itemId, msg.sender, seller, price);
  }

  /*
  * @Function to set buyer of transaction.
  */
  function setBuyer(uint256 itemId, address buyer, uint256 price) external onlyCreator(itemId) {
    txList[itemId].buyer = buyer;
    txList[itemId].price = price;
    txList[itemId].status = STATUS.ACCEPTED;

    emit Accept(itemId, buyer);
  }

  /*
  * @Function to set arbiter of transaction.
  */
  function setArbiter(uint256 itemId, address arbiter) external onlyCreator(itemId) {
    txList[itemId].arbiter = arbiter;
  }

  /*
  * @Function to set seller of transaction.
  */
  function setSeller(uint256 itemId, address seller) external onlyCreator(itemId) {
    txList[itemId].seller = seller;
  }

  /*
  * @Function to set price of transaction.
  */
  function setPrice(uint256 itemId, uint256 price) external onlyCreator(itemId) {
    txList[itemId].price = price;
  }

  /*
  * @Function to set a milestone for a transaction.
  * @Only buyer can create a milestone.
  */
  function setMilestone(uint256 itemId) external payable onlyBuyer(itemId) {
    require(msg.value >= txList[itemId].price, "Milestone amount should be bigger than the price");
    txList[itemId].milestone = msg.value;
    txList[itemId].status = STATUS.MILESTONE_SET;

    emit MilestoneSet(itemId, msg.value);
  }

  /*
  * @Function to increase the release count of transaction.
  * @If the release count reaches 2, seller can withdraw money from contract for his product.
  */
  function increaseReleaseCount(uint256 itemId) external onlyTxAccounts(itemId) {
    require(txList[itemId].status == STATUS.MILESTONE_SET, "There should be a milestone to increase release count.");
    require(!txList[itemId].approvedRelease[msg.sender] && !txList[itemId].approvedRefund[msg.sender], "Every account can increase only once.");
    txList[itemId].approveReleaseCount ++;
    txList[itemId].approvedRelease[msg.sender] = true;
  }

  /*
  * @Function to increase the refund count of transaction.
  * @If the refund count reaches 2, buyer can withdraw money from contract because the product is not valuable.
  */
  function increaseRefundCount(uint256 itemId) external onlyTxAccounts(itemId) {
    require(txList[itemId].status == STATUS.MILESTONE_SET, "There should be a milestone to increase refund count.");
    require(!txList[itemId].approvedRelease[msg.sender] && !txList[itemId].approvedRefund[msg.sender], "Every account can increase only once.");
    txList[itemId].approveRefundCount ++;
    txList[itemId].approvedRefund[msg.sender] = true;
  }

  /*
  * @Function to release.
  */
  function release(uint256 itemId) external onlyCreator(itemId) {
    require(txList[itemId].status == STATUS.MILESTONE_SET, "There should be a milestone to release it.");
    require(txList[itemId].approveReleaseCount >= 2, "At least 2 people should agree to release the milestone.");
    payable(txList[itemId].seller).transfer(txList[itemId].milestone);
    txList[itemId].status = STATUS.RELEASED;

    emit Released(itemId, txList[itemId].milestone);
  }

  /*
  * @Function to refund.
  */
  function refund(uint256 itemId) external onlyCreator(itemId) {
    require(txList[itemId].status == STATUS.MILESTONE_SET, "There should be a milestone to refund it.");
    require(txList[itemId].approveRefundCount >= 2, "At least 2 people should agree to refund the milestone.");
    payable(txList[itemId].buyer).transfer(txList[itemId].milestone);
    txList[itemId].status = STATUS.REFUNDED;

    emit Refunded(itemId, txList[itemId].milestone);
  }
}