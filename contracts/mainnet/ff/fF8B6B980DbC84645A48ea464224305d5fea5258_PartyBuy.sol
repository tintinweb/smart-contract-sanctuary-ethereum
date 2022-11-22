// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.16;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

// import "hardhat/console.sol";

contract PartyBuy is Ownable, Pausable, ReentrancyGuard {
  string public constant VERSION = "1.0.0";

  event CreatePlan(uint256 indexed planIndex);

  event Own(uint256 indexed planIndex, address indexed account, uint256 amount, string email);

  struct PartyBuyPlan {
    address payable receiverWallet;
    uint48 totalAmount;
    uint48 amount;
    uint256 price;
    /// @notice startTime unit second
    /// @return startTime unit second
    uint64 startTime;
    /// @notice endTime unit second
    /// @return endTime unit second
    uint64 endTime;
    address[] ownerArr;
    mapping(address => uint48) amountByAddressMapping;
  }

  uint256 public totalPlan;

  mapping(uint256 => PartyBuyPlan) private _partyBuyPlans;

  constructor() {}

  /************************
   * @dev for pause
   */

  function pause() public onlyOwner {
    _pause();
  }

  function unpause() public onlyOwner {
    _unpause();
  }

  /********************
   *
   */

  /// @notice Create new party buy plan
  /// @dev Explain to a developer any extra details
  /// @param receiverWallet_ :
  function createPlan(
    address payable receiverWallet_,
    uint48 totalAmount_,
    uint256 price_,
    uint64 startTime_,
    uint64 endTime_
  ) external onlyOwner {
    require(receiverWallet_ != address(0));

    uint256 currentPlanIndex = totalPlan;

    _partyBuyPlans[currentPlanIndex].receiverWallet = receiverWallet_;
    _partyBuyPlans[currentPlanIndex].totalAmount = totalAmount_;
    _partyBuyPlans[currentPlanIndex].amount = totalAmount_;
    _partyBuyPlans[currentPlanIndex].price = price_;
    _partyBuyPlans[currentPlanIndex].startTime = startTime_;
    _partyBuyPlans[currentPlanIndex].endTime = endTime_;

    totalPlan += 1;

    emit CreatePlan(currentPlanIndex);
  }

  function updatePlanTime(
    uint256 planIndex,
    uint64 startTime_,
    uint64 endTime_
  ) external onlyOwner {
    require(planIndex < totalPlan, "Plan is not existed");

    _partyBuyPlans[planIndex].startTime = startTime_;
    _partyBuyPlans[planIndex].endTime = endTime_;
  }

  function updatePlanReceiverWallet(uint256 planIndex, address payable receiverWallet_) external onlyOwner {
    require(planIndex < totalPlan, "Plan is not existed");
    require(receiverWallet_ != address(0));

    _partyBuyPlans[planIndex].receiverWallet = receiverWallet_;
  }

  function getPlanInfo(uint256 planIndex)
    external
    view
    returns (
      address receiverWallet,
      uint48 totalAmount,
      uint48 amount,
      uint256 price,
      uint64 startTime,
      uint64 endTime,
      uint256 totalOwner
    )
  {
    require(planIndex < totalPlan, "Plan is not existed");
    receiverWallet = _partyBuyPlans[planIndex].receiverWallet;
    totalAmount = _partyBuyPlans[planIndex].totalAmount;
    amount = _partyBuyPlans[planIndex].amount;
    price = _partyBuyPlans[planIndex].price;
    startTime = _partyBuyPlans[planIndex].startTime;
    endTime = _partyBuyPlans[planIndex].endTime;
    totalOwner = _partyBuyPlans[planIndex].ownerArr.length;
  }

  function getOwnersOfPlan(
    uint256 planIndex,
    uint256 skip,
    uint256 limit
  ) external view returns (address[] memory ownerArr, uint48[] memory ownAmountArr) {
    require(planIndex < totalPlan, "Plan is not existed");

    uint256 totalOwner = _partyBuyPlans[planIndex].ownerArr.length;
    uint256 endIndex = totalOwner;
    if (limit > 0 && (skip + limit) < endIndex) {
      endIndex = skip + limit;
    }

    ownerArr = new address[](endIndex - skip);
    ownAmountArr = new uint48[](endIndex - skip);

    for (uint256 index = skip; index < endIndex; index++) {
      ownerArr[index - skip] = _partyBuyPlans[planIndex].ownerArr[index];
      address currentOwner = ownerArr[index - skip];
      ownAmountArr[index - skip] = _partyBuyPlans[planIndex].amountByAddressMapping[currentOwner];
    }
  }

  function getAmountOfOwner(uint256 planIndex, address ownerAddress) external view returns (uint48) {
    require(planIndex < totalPlan, "Plan is not existed");
    return _partyBuyPlans[planIndex].amountByAddressMapping[ownerAddress];
  }

  /// @notice User buy amount in plan
  /// @param planIndex (unit256) :
  /// @param amount (uin48) :
  /// @param email (string) :
  function buy(
    uint256 planIndex,
    uint48 amount,
    string memory email
  ) external payable nonReentrant whenNotPaused {
    require(planIndex < totalPlan, "Plan is not existed");
    require(
      block.timestamp >= _partyBuyPlans[planIndex].startTime && block.timestamp <= _partyBuyPlans[planIndex].endTime,
      "Not active"
    );
    require(amount > 0, "Amount must greater than 0");
    require(amount <= _partyBuyPlans[planIndex].amount, "Do not have enough amount left");
    require(msg.value == (_partyBuyPlans[planIndex].price * amount), "Money is not correct");

    uint48 currentOwn = _partyBuyPlans[planIndex].amountByAddressMapping[msg.sender];

    if (currentOwn == 0) {
      _partyBuyPlans[planIndex].ownerArr.push(msg.sender);
    }

    _partyBuyPlans[planIndex].amountByAddressMapping[msg.sender] += amount;
    _partyBuyPlans[planIndex].amount -= amount;

    // emit event
    emit Own(planIndex, msg.sender, _partyBuyPlans[planIndex].amountByAddressMapping[msg.sender], email);

    // transfer balance to tkxWallet
    // solhint-disable-next-line avoid-low-level-calls
    (bool sent, ) = payable(_partyBuyPlans[planIndex].receiverWallet).call{value: msg.value}("");
    require(sent, "Failed to send Ether");
  }
}

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
// OpenZeppelin Contracts (last updated v4.8.0) (security/ReentrancyGuard.sol)

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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
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