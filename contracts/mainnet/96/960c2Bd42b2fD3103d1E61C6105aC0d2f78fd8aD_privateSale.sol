// SPDX-License-Identifier: MIT

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
    _nonReentrantBefore();
    _;
    _nonReentrantAfter();
  }

  function _nonReentrantBefore() private {
    // On the first call to nonReentrant, _status will be _NOT_ENTERED
    require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

    // Any calls to nonReentrant after this point will fail
    _status = _ENTERED;
  }

  function _nonReentrantAfter() private {
    // By storing the original value once again, a refund is triggered (see
    // https://eips.ethereum.org/EIPS/eip-2200)
    _status = _NOT_ENTERED;
  }

  /**
   * @dev Returns true if the reentrancy guard is currently set to "entered", which indicates there is a
   * `nonReentrant` function in the call stack.
   */
  function _reentrancyGuardEntered() internal view returns (bool) {
    return _status == _ENTERED;
  }
}

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

pragma solidity ^0.8.0;

contract privateSale is Ownable, ReentrancyGuard {
  constructor(uint _hardCap, uint _minDeposit, uint _maxDeposit, bool _isHardCap, bool _isWhitelist, bool _depRestriction, uint _startDate, uint _endDate) {
    hardCap = _hardCap;
    minDeposit = _minDeposit;
    maxDeposit = _maxDeposit;
    isHardCap = _isHardCap;
    isWhitelist = _isWhitelist;
    depRestriction = _depRestriction;
    startDate = _startDate;
    endDate = _endDate;
  }

  /*|| === STRUCTS === ||*/
  struct depositItem {
    address senderAddress;
    uint depositAmount;
    bool whitelist;
  }

  /*|| === GLOBAL VARIABLES === ||*/
  uint public index;
  uint public hardCap;
  uint public minDeposit;
  uint public maxDeposit;
  uint public totalDeposits;
  bool public isHardCap; // Is hardcap enabled
  bool public isWhitelist; // Is whitelist in effect
  bool public depRestriction; // Is min/max deposit amount in effect
  address[] private whitelistAddr; // Array of whitelisted addresses
  uint public startDate;
  uint public endDate;

  /*|| === MAPPINGS === ||*/
  mapping(address => uint[]) private depositToAddress;
  mapping(uint => depositItem) private depositToIndex;

  /*|| === EVENT EMMITER === ||*/
  event LogDeposit(address depAddress, uint256 amountDeposited);

  /*|| === PUBLIC FUNCTIONS === ||*/
  // Check if address is whitelisted
  function getIsWhitelisted(address _addr) public view returns (bool) {
    for (uint i = 0; i < whitelistAddr.length; i++) {
      if (whitelistAddr[i] == _addr) {
        return true;
      }
    }
    return false;
  }

  // Get list of whitelisted addresses
  function getWhitelistAddresses() public view returns (address[] memory) {
    return whitelistAddr;
  }

  // Get depositItem by index
  function getDepositInfoByIndex(uint _index) public view returns (depositItem memory) {
    return depositToIndex[_index];
  }

  // Get depositItem index by address
  function getDepositIndexByAddress(address _addr) public view returns (uint[] memory) {
    return depositToAddress[_addr];
  }

  function getDepositAmountByAddress(address _addr) public view returns (uint) {
    uint[] memory deposits = getDepositIndexByAddress(_addr);
    uint total;
    for (uint i = 0; i < deposits.length; i++) {
      total += getDepositInfoByIndex(deposits[i]).depositAmount;
    }
    return total;
  }

  // Get remaining deposit amount
  function getRemainingDeposit(address _addr) public view returns (int) {
    if (depRestriction == true) {
      uint[] memory deposits = getDepositIndexByAddress(_addr);
      uint total;
      for (uint i = 0; i < deposits.length; i++) {
        total += getDepositInfoByIndex(deposits[i]).depositAmount;
      }
      if (total >= maxDeposit) {
        return 0;
      }
      return int(maxDeposit - total);
    }
    return -1;
  }

  function depositETH() public payable nonReentrant {
    if (isWhitelist) {
      // If whitelist mode is on
      require(getIsWhitelisted(msg.sender) == true, "Sender is not whitelisted");
    }
    if (depRestriction) {
      // If min/max deposit restrictions are on
      require(msg.value + getDepositAmountByAddress(msg.sender) >= minDeposit && msg.value <= maxDeposit, "Deposit amount not within min/max boundaries");
      require(getRemainingDeposit(msg.sender) - int(msg.value) >= 0, "Current deposit exceeds max deposit amount per address");
    }
    if (isHardCap) {
      // If hardcap mode is enabled
      require(totalDeposits + msg.value <= hardCap, "Deposit amount exceeds hardcap");
    }
    require(startDate <= block.timestamp, "Private sale has not started");
    require(endDate >= block.timestamp, "Private sale has ended");
    depositToIndex[index].senderAddress = msg.sender;
    depositToIndex[index].depositAmount = msg.value;
    depositToIndex[index].whitelist = isWhitelist;

    depositToAddress[msg.sender].push(index);
    totalDeposits += msg.value;
    index++;

    emit LogDeposit(msg.sender, msg.value);
  }

  // Add addresses to whitelist via array
  function addToWhitelist(address[] calldata _addr) public onlyOwner {
    for (uint i = 0; i < _addr.length; i++) {
      if (getIsWhitelisted(_addr[i]) == false) {
        whitelistAddr.push(_addr[i]);
      }
    }
  }

  // Remove whitelisted address from the array
  function removeFromWhitelist(address _addr) public onlyOwner {
    require(getIsWhitelisted(_addr) == true, "Address is not whitelisted");
    for (uint i = 0; i < whitelistAddr.length; i++) {
      if (whitelistAddr[i] == _addr) {
        whitelistAddr[i] = whitelistAddr[whitelistAddr.length - 1];
        whitelistAddr.pop();
      }
    }
  }

  // Set hardcap value
  function setHardCap(uint _hardCap) public onlyOwner {
    hardCap = _hardCap;
  }

  // Set the min deposit
  function setMinDeposit(uint _minDeposit) public onlyOwner {
    require(_minDeposit <= maxDeposit, "Min deposit must be less than max deposit");
    minDeposit = _minDeposit;
  }

  // Set the max deposit
  function setMaxDeposit(uint _maxDeposit) public onlyOwner {
    require(_maxDeposit >= minDeposit, "Max deposit must be greater than min deposit");
    maxDeposit = _maxDeposit;
  }

  // Set if hardcap enabled
  function setHardcapMode(bool _isHardCap) public onlyOwner {
    isHardCap = _isHardCap;
  }

  // Set if whitelist mode enabled
  function setWhitelist(bool _isWhitelist) public onlyOwner {
    isWhitelist = _isWhitelist;
  }

  // Set if deposits have restrictions
  function setDepositRestrictions(bool _depRestriction) public onlyOwner {
    depRestriction = _depRestriction;
  }

  // Set start date
  function setStartDate(uint _startDate) public onlyOwner {
    startDate = _startDate;
  }

  // Set end date
  function setEndDate(uint _endDate) public onlyOwner {
    endDate = _endDate;
  }

  /*|| === EXTERNAL FUNCTIONS === ||*/
  // Claim ETH in contract
  function claimETH() external onlyOwner {
    address payable to = payable(msg.sender);
    to.transfer(address(this).balance);
  }
}