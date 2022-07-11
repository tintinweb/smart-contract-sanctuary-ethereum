// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Samsara is Ownable {

  struct Tier {
    bool isActive;
    uint80 amount;
    uint32 period;
  }

  struct Subscription {
    uint16 tierIndex;
    uint40 startDate;
    uint8 failedClaims;
    address donator;
  }

  struct Project {
    uint32 id;
    bool isActive;
    uint16 fee;
    uint40 lastClaimDate;
    uint32 lastClaimedIndex;
    address claimAddress;
    address tokenAddress;
    Tier[] tiers;
    Subscription[] subscriptions;
  }

  struct ClaimableAmount {
    uint96 amount;
    address contractAddress;
  }

  uint256 constant MAX_FEE = 10_000;
  uint256 constant MAX_PROJECT_FEE = 1000;
  uint256 constant DEFAULT_FEE = 50; // 0.5%
  uint256 constant MAX_FAILED_CLAIMS = 3;

  uint32 public projectCounter;
  uint32 public maxSubscribers = 5_000;

  mapping(uint256 => Project) public projects;
  mapping(address => bool) public tokenStatus;

  event Subscribed(uint256 indexed projectId, address indexed donator, uint256 timestamp);
  event Unsubscribed(uint256 indexed projectId, address indexed donator, uint256 timestamp);
  event Claimed(uint256 indexed projectId, uint256 timestamp);
  event ClaimFailed(uint256 indexed projectId, address indexed donator, uint256 timestamp);

  function setMaxSubscribers(uint32 _maxSubscribers) public onlyOwner {
    maxSubscribers = _maxSubscribers;
  }

  function registerProject(address claimAddress, address tokenAddress, Tier[] calldata tiers) public onlyOwner {
    uint32 projectId = projectCounter++;
    Project storage project = projects[projectId];

    require(claimAddress != address(0), 'Zero claim address');
    require(tokenStatus[tokenAddress], 'Token is not active');

    project.id = projectId;
    project.isActive = true;
    project.fee = uint16(DEFAULT_FEE);
    project.claimAddress = claimAddress;
    project.tokenAddress = tokenAddress;

    for (uint256 i; i < tiers.length; ++i) {
      Tier calldata tier = tiers[i];
      project.tiers.push(tier);
    }
  }

  function enableProject(uint256 projectId) public onlyOwner {
    Project storage project = projects[projectId];
    require(tokenStatus[project.tokenAddress], 'Token is not active');
    projects[projectId].isActive = true;
  }

  function disableProject(uint256 projectId) public onlyOwner {
    projects[projectId].isActive = false;
  }

  function addTiers(uint256 projectId, Tier[] calldata newTiers) public onlyOwner {
    Project storage project = projects[projectId];
    require(project.isActive, 'Project is not active'); 

    for (uint256 i; i < newTiers.length; ++i) {
      Tier calldata tier = newTiers[i];
      project.tiers.push(tier);
    }
  }

  function enableTiers(uint256 projectId, uint256[] calldata tierIndices) public onlyOwner {
    Project storage project = projects[projectId];
    require(project.isActive, 'Project is not active'); 

    for (uint256 i; i < tierIndices.length; ++i) {
      project.tiers[tierIndices[i]].isActive = true;
    }
  }

  function disableTiers(uint256 projectId, uint256[] calldata tierIndices) public onlyOwner {
    Project storage project = projects[projectId];
    require(project.isActive, 'Project is not active'); 

    for (uint256 i; i < tierIndices.length; ++i) {
      project.tiers[tierIndices[i]].isActive = false;
    }
  }

  function changeProjectClaimAddress(uint256 projectId, address newClaimAddress) public onlyOwner {
    Project storage project = projects[projectId];
    require(project.isActive, 'Project is not active'); 
    project.claimAddress = newClaimAddress;
  }

  function changeProjectFee(uint256 projectId, uint16 fee) public onlyOwner {
    Project storage project = projects[projectId];
    require(project.isActive, 'Project is not active');
    require(fee < MAX_PROJECT_FEE, 'Fee is too high');
    project.fee = fee;
  }

  function enableTokens(address[] calldata contractAddresses) public onlyOwner {
    for (uint256 i; i < contractAddresses.length; ++i) {
      tokenStatus[contractAddresses[i]] = true;
    }
  }

  function disableTokens(address[] calldata contractAddresses) public onlyOwner {
    for (uint256 i; i < contractAddresses.length; ++i) {
      tokenStatus[contractAddresses[i]] = false;
    }
  }

  function subscribe(uint256 projectId, uint16 tierIndex) public {
    require(projectId < projectCounter, 'Invalid project id');
    Project storage project = projects[projectId];

    require(project.isActive, 'Project is not active'); 
    require(project.tiers[tierIndex].isActive, 'Tier is not active');
    require(tokenStatus[project.tokenAddress], 'Token is not active');
    require(project.subscriptions.length < maxSubscribers, 'Maximum number of subscribers reached');

    Subscription memory newSubscription = Subscription({tierIndex: tierIndex, startDate: uint40(block.timestamp), failedClaims: 0, donator: msg.sender});
    project.subscriptions.push(newSubscription);
    
    emit Subscribed(projectId, msg.sender, block.timestamp);
  }

  function isSubscribedForTier(uint256 projectId, uint16 tierIndex, address donator) view public returns (bool) {
    require(tierIndex < projects[projectId].tiers.length, 'Invalid tier index');
    return subscriptionIndexForTier(projectId, tierIndex, donator) < projects[projectId].subscriptions.length;
  }

  function subscriptionIndexForTier(uint256 projectId, uint32 tierIndex, address donator) public view returns (uint256 result) {
    require(projectId < projectCounter, 'Invalid project id');
    Subscription[] storage subscriptions = projects[projectId].subscriptions;

    for (uint256 i; i < projects[projectId].subscriptions.length; ++i) {
      if (subscriptions[i].donator == donator && subscriptions[i].tierIndex == tierIndex) {
        return i;
      }
    }

    return type(uint256).max;
  }

  function unsubscribe(uint256 projectId, address donator, uint256 subscriptionIndex) public {
    require(msg.sender == donator || msg.sender == owner(), 'Not authorized to unsubscribe');

    Project storage project = projects[projectId];
    Subscription storage subscription = project.subscriptions[subscriptionIndex];
    require(subscription.donator == donator, 'Donator does not match');

    project.subscriptions[subscriptionIndex] = project.subscriptions[project.subscriptions.length - 1];
    project.subscriptions.pop();

    emit Unsubscribed(projectId, donator, block.timestamp);
  }

  function claim(uint256 projectId) public {
    Project storage project = projects[projectId];

    require(project.isActive, 'Project is not active'); 
    require(project.claimAddress != address(0), 'Claim address is zero');

    uint40 lastClaimDate = project.lastClaimDate;
    project.lastClaimDate = uint40(block.timestamp);

    claimIn(projectId, lastClaimDate, project.tokenAddress);
    emit Claimed(projectId, block.timestamp);
  }

  function claimIn(uint256 projectId, uint40 lastClaimDate, address tokenAddress) internal {
    Project storage project = projects[projectId];
    Subscription[] storage subscriptions = project.subscriptions;

    uint256 totalAmount;
    IERC20 token = IERC20(tokenAddress);

    for (uint256 i; i < subscriptions.length; ++i) {
      Subscription storage subscription = subscriptions[i];
      Tier storage tier = project.tiers[subscription.tierIndex];

      uint256 donatorLastClaim = lastClaimDate;
      if (subscription.startDate > lastClaimDate || subscription.failedClaims > 0) {
        donatorLastClaim = subscription.startDate;
      }
      uint256 chargeAmount = tier.amount * (block.timestamp - donatorLastClaim) / tier.period;

      try token.transferFrom(subscription.donator, address(this), chargeAmount) returns (bool success) {
        if (success) {
          totalAmount += chargeAmount;
          if (subscription.failedClaims > 0) {
            subscription.failedClaims = 0;
          }
        } else {
          failedClaim(project, subscription.donator, tier, i);
        }
      } catch {
        failedClaim(project, subscription.donator, tier, i);
      }
    }

    uint256 totalFee = totalAmount * project.fee / MAX_FEE;
    require(token.transfer(project.claimAddress, totalAmount - totalFee), 'Transfer failed');
  }

  function numberOfSubscribers(uint32 projectId) public view returns (uint256 result) {
    require(projectId < projectCounter, 'Invalid project id');
    return projects[projectId].subscriptions.length;
  }

  function numberOfSubscribersInTier(uint32 projectId, uint32 tierIndex) public view returns (uint256 result) {
    require(projectId < projectCounter, 'Invalid project id');
    Project storage project = projects[projectId];
    require(tierIndex < project.tiers.length, 'Invalid tier index');

    for(uint256 i; i < project.subscriptions.length; ++i) {
      Subscription storage subscription = project.subscriptions[i];
      if (subscription.tierIndex == tierIndex) {
        result += 1;
      }
    }
  }

  function claimableAmount(uint32 projectId) public view returns (ClaimableAmount memory result) {
    require(projectId < projectCounter, 'Invalid project id');
    
    Project storage project = projects[projectId];
    Subscription[] storage subscriptions = project.subscriptions;

    result.contractAddress = project.tokenAddress;

    for (uint256 i = 0; i < subscriptions.length; ++i) {
      Subscription storage subscription = subscriptions[i];
      Tier storage tier = project.tiers[subscription.tierIndex];

      uint256 donatorLastClaim = project.lastClaimDate;
      if (subscription.startDate > project.lastClaimDate || subscription.failedClaims > 0) {
        donatorLastClaim = subscription.startDate;
      }

      result.amount += uint96(tier.amount * (block.timestamp - donatorLastClaim) / tier.period);
    }
  }
  
  function failedClaim(Project storage project, address donator, Tier storage tier, uint256 subscriptionIndex) internal {
    IERC20 token = IERC20(project.tokenAddress);
    uint256 allowance = token.allowance(donator, address(this));
    Subscription storage subscription = project.subscriptions[subscriptionIndex];

    if (allowance < tier.amount || subscription.failedClaims + 1 >= MAX_FAILED_CLAIMS) {
      unsubscribe(project.id, donator, subscriptionIndex);
    } else {
      subscription.failedClaims += 1;
      if (subscription.failedClaims == 1) {
        subscription.startDate = uint40(block.timestamp);
      }

      emit ClaimFailed(project.id, donator, block.timestamp);
    }
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
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