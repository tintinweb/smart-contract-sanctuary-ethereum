// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./DataStructures.sol";

contract TrustedSubscription is Ownable {

  uint256 constant MAX_FEE = 10_000;
  uint256 constant DEFAULT_FEE = 500; // 0.5%
  uint256 constant MAX_FAILED_CLAIMS = 3;

  uint32 projectCounter;
  uint32 tokenCounter;

  mapping(uint256 => Project) public projects;
  mapping(address => mapping(uint256 => SubscriptionDetails)) public subscriptionDetails;
  mapping(uint256 => Token) public tokens;

  event Subscribed(uint256 indexed projectId, address indexed donator, uint256 timestamp);
  event Unsubscribed(uint256 indexed projectId, address indexed donator, uint256 timestamp);
  event Claimed(uint256 indexed projectId, uint256 timestamp);
  event ClaimFailed(uint256 indexed projectId, address indexed donator, uint256 timestamp);

  function registerProject(address claimAddress, Tier[] calldata tiers) public onlyOwner {
    uint32 projectId = ++projectCounter;
    Project storage project = projects[projectId];

    require(claimAddress != address(0), 'Zero claim address');

    project.id = projectId;
    project.isActive = true;
    project.fee = uint16(DEFAULT_FEE);
    project.claimAddress = claimAddress;

    for (uint256 i; i < tiers.length; ++i) {
      Tier calldata tier = tiers[i];
      require(tokens[tier.tokenId].isActive, 'Token is not active');
      project.tiers.push(tier);
    }
  }

  function enableProject(uint256 projectId) public onlyOwner {
    Project storage project = projects[projectId];
    for (uint256 i; i < project.tiers.length; ++i) {
      uint32 tokenId = project.tiers[i].tokenId;
      require(tokens[tokenId].isActive, 'Token is not active');
    }
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
      require(tokens[tier.tokenId].isActive, 'Token is not active');
      project.tiers.push(tier);
    }
  }

  function enableTiers(uint256 projectId, uint256[] calldata tierIndices) public onlyOwner {
    Project storage project = projects[projectId];
    require(project.isActive, 'Project is not active'); 

    for (uint256 i; i < tierIndices.length; ++i) {
      Tier storage tier = project.tiers[tierIndices[i]];
      require(tokens[tier.tokenId].isActive, 'Token is not active');
      tier.isActive = true;
    }
  }

  function disableTiers(uint256 projectId, uint256[] calldata tierIndices) public onlyOwner {
    Project storage project = projects[projectId];
    require(project.isActive, 'Project is not active'); 

    for (uint256 i; i < tierIndices.length; ++i) {
      project.tiers[tierIndices[i]].isActive = false;
    }
  }

  function addTokens(address[] calldata contractAddresses) public onlyOwner {
    for (uint256 i; i < contractAddresses.length; ++i) {
      tokens[++tokenCounter] = Token({isActive: true, contractAddress: contractAddresses[i]});
    }
  }

  function enableTokens(uint32[] calldata tokenIds) public onlyOwner {
    for (uint256 i; i < tokenIds.length; ++i) {
      uint256 tokenId = tokenIds[i];
      require(tokenId <= tokenCounter, 'Invalid token id');
      tokens[tokenId].isActive = true;
    }
  }

  function disableTokens(uint32[] calldata tokenIds) public onlyOwner {
    for (uint256 i; i < tokenIds.length; ++i) {
      uint256 tokenId = tokenIds[i];
      require(tokenId <= tokenCounter, 'Invalid token id');
      tokens[tokenId].isActive = false;
    }
  }

  function subscribe(uint256 projectId, uint16 tierIndex) public {
    Project storage project = projects[projectId];
    Tier storage tier = project.tiers[tierIndex];
    SubscriptionDetails storage details = subscriptionDetails[msg.sender][projectId];

    require(project.isActive, 'Project is not active'); 
    require(tier.isActive, 'Tier is not active');
    require(tokens[tier.tokenId].isActive, 'Token is not active');
    require(details.startDate == 0, 'Already subscribed');

    if (project.lastClaimDate == 0) {
      project.lastClaimDate = uint40(block.timestamp);
    }

    addActiveToken(project.activeTokens, tier.tokenId);

    SubscriptionGroup storage tokenSubscriptions = project.tokenSubscriptions[tier.tokenId];
    Subscription memory newSubscription = Subscription({tierIndex: tierIndex, donator: msg.sender});

    tokenSubscriptions.subscriptions.push(newSubscription);
    tokenSubscriptions.subscriptionIndices[msg.sender] = tokenSubscriptions.subscriptions.length - 1;
    
    details.isActive = true;
    details.tokenId = tier.tokenId;
    details.startDate = uint40(block.timestamp);

    emit Subscribed(projectId, msg.sender, block.timestamp);
  }

  function isSubscribed(uint256 projectId, uint16 tierIndex, address donator) view public returns (bool) {
    require(projectId <= projectCounter, 'Invalid project id');

    Project storage project = projects[projectId];
    Tier storage tier = project.tiers[tierIndex];

    require(tier.isActive, 'Tier is not active');

    SubscriptionGroup storage tokenSubscriptions = project.tokenSubscriptions[tier.tokenId];
    for(uint256 i; i < tokenSubscriptions.subscriptions.length; i++) {
      Subscription memory sub = tokenSubscriptions.subscriptions[i];
      if ((sub.donator == donator) && (sub.tierIndex == tierIndex)) {
        return true;
      }
    }
    return false;
  }

  function unsubscribe(uint256 projectId, address donator) public {
    require(msg.sender == donator || msg.sender == owner(), 'Not authorized to unsubscribe');

    SubscriptionDetails storage details = subscriptionDetails[donator][projectId];
    SubscriptionGroup storage tokenSubscriptions = projects[projectId].tokenSubscriptions[details.tokenId];

    uint256 totalTokenSubs = tokenSubscriptions.subscriptions.length;
    uint256 index = tokenSubscriptions.subscriptionIndices[donator];
    
    Subscription storage subscription = tokenSubscriptions.subscriptions[index];
    require(subscription.donator == donator, 'Donator does not match');

    tokenSubscriptions.subscriptions[index] = tokenSubscriptions.subscriptions[totalTokenSubs - 1];
    tokenSubscriptions.subscriptions.pop();

    if (totalTokenSubs == 1) {
      removeActiveToken(projects[projectId].activeTokens, details.tokenId);
    }

    delete tokenSubscriptions.subscriptionIndices[donator];
    delete subscriptionDetails[donator][projectId];

    emit Unsubscribed(projectId, donator, block.timestamp);
  }

  function claim(uint256 projectId) public {
    Project storage project = projects[projectId];
    uint32[] storage activeTokens = project.activeTokens;

    for (uint256 i; i < activeTokens.length; ++i) {
      claim(projectId, activeTokens[i]);
    }

    project.lastClaimDate = uint40(block.timestamp);
    emit Claimed(projectId, block.timestamp);
  }

  function claim(uint256 projectId, uint32 tokenId) internal {
    SubscriptionGroup storage tokenSubscriptions = projects[projectId].tokenSubscriptions[tokenId];
    claimIn(projectId, tokenId, 0, tokenSubscriptions.subscriptions.length);
  }

  function claimIn(uint256 projectId, uint32 tokenId, uint256 start, uint256 end) internal {
    Project storage project = projects[projectId];
    Subscription[] storage subscriptions = project.tokenSubscriptions[tokenId].subscriptions;

    require(project.isActive, 'Project is not active'); 
    require(project.claimAddress != address(0), 'Claim address is zero');

    uint256 totalAmount;
    IERC20 token = IERC20(tokens[tokenId].contractAddress);

    for (uint256 i = start; i < end; ++i) {
      Subscription storage subscription = subscriptions[i];
      Tier storage tier = project.tiers[subscription.tierIndex];

      uint256 chargeAmount = tier.amount * (block.timestamp - project.lastClaimDate) / tier.period;

      try token.transferFrom(subscription.donator, address(this), chargeAmount) returns (bool success) {
        if (success) {
          totalAmount += chargeAmount;
        } else {
          failedClaim(project, subscription.donator, tier);
        }
      } catch {
        failedClaim(project, subscription.donator, tier);
      }
    }

    uint256 totalFee = totalAmount * project.fee / MAX_FEE;
    token.transfer(project.claimAddress, totalAmount - totalFee);
  }

  function getSubscriptionDetails(address donator, uint32 projectId) public view returns (SubscriptionDetails memory) {
    require(donator != address(0), 'Invalid donator address');
    require(projectId <= projectCounter, 'Invalid project id');

    return subscriptionDetails[donator][projectId];
  }

  function numberOfSubscribers(uint32 projectId) public view returns (uint256 result) {
    require(projectId <= projectCounter, 'Invalid project id');

    Project storage project = projects[projectId];

    for (uint256 i; i < project.activeTokens.length; ++i) {
      uint32 tokenId = project.activeTokens[i];
      result += numberOfSubscribersInToken(projectId, tokenId);
    }
  }

  function numberOfSubscribersInTier(uint32 projectId, uint32 tierIndex) public view returns (uint256 result) {
    require(projectId <= projectCounter, 'Invalid project id');

    Project storage project = projects[projectId];
    Tier storage tier = project.tiers[tierIndex];

    require(tier.isActive, 'Tier is not active');

    SubscriptionGroup storage tokenSubscriptions = project.tokenSubscriptions[tier.tokenId];

    for(uint256 i; i < tokenSubscriptions.subscriptions.length; i++) {
      Subscription memory sub = tokenSubscriptions.subscriptions[i];
      if (sub.tierIndex == tierIndex) {
        result += 1;
      }
    }

    return result;
  }

  function numberOfSubscribersInToken(uint32 projectId, uint32 tokenId) public view returns (uint256) {
    require(projectId <= projectCounter, 'Invalid project id');
    require(tokenId <= tokenCounter, 'Invalid token id');

    return projects[projectId].tokenSubscriptions[tokenId].subscriptions.length;
  }

  function claimableAmounts(uint32 projectId) public view returns (ClaimableAmount[] memory amounts) {
    require(projectId <= projectCounter, 'Invalid project id');

    uint32[] storage activeTokens = projects[projectId].activeTokens;
    amounts = new ClaimableAmount[](activeTokens.length);

    for (uint256 i; i < activeTokens.length; ++i) {
      amounts[i] = claimableAmountOfTokens(projectId, activeTokens[i]);
    }

    return amounts;
  }

  function claimableAmountOfTokens(uint32 projectId, uint32 tokenId) public view returns (ClaimableAmount memory result) {
    require(projectId <= projectCounter, 'Invalid project id');
    require(tokenId <= tokenCounter, 'Invalid token id');
    
    Project storage project = projects[projectId];
    Subscription[] storage subscriptions = project.tokenSubscriptions[tokenId].subscriptions;

    result.contractAddress = tokens[tokenId].contractAddress;

    for (uint256 i = 0; i < subscriptions.length; ++i) {
      Tier storage tier = project.tiers[subscriptions[i].tierIndex];
      result.amount += uint96(tier.amount * (block.timestamp - project.lastClaimDate) / tier.period);
    }
  }
  
  function failedClaim(Project storage project, address donator, Tier storage tier) internal {
    SubscriptionDetails storage subDetails = subscriptionDetails[donator][project.id];

    IERC20 token = IERC20(tokens[tier.tokenId].contractAddress);
    uint256 allowance = token.allowance(donator, address(this));

    if (allowance < tier.amount || subDetails.failedClaims + 1 >= MAX_FAILED_CLAIMS) {
      unsubscribe(project.id, donator);
    } else {
      subDetails.failedClaims += 1;

      if (subDetails.isActive) {
        subDetails.isActive = false;
        subDetails.failedClaimDate = uint40(block.timestamp);
      }

      emit ClaimFailed(project.id, donator, block.timestamp);
    }
  }

  function addActiveToken(uint32[] storage activeTokens, uint32 tokenId) internal {
      for (uint256 i; i < activeTokens.length; ++i) {
        if (tokenId == activeTokens[i]) {
          return;
        }
      }

      activeTokens.push(tokenId);
  }

  function removeActiveToken(uint32[] storage activeTokens, uint32 tokenId) internal {
    uint256 length = activeTokens.length;

    for (uint256 i; i < length; ++i) {
      if (tokenId == activeTokens[i]) {
        activeTokens[i] = activeTokens[length - 1];
        activeTokens.pop();
        break;
      }
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

// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.9;

struct Tier {
  bool isActive;
  uint80 amount;
  uint32 period;
  uint32 tokenId;
}

struct Subscription {
  uint16 tierIndex;
  address donator;
}

struct SubscriptionGroup {
  Subscription[] subscriptions;
  mapping(address => uint256) subscriptionIndices;
}

struct Project {
  uint32 id;
  bool isActive;
  address claimAddress;
  uint40 lastClaimDate;
  uint16 fee;
  Tier[] tiers;
  uint32[] activeTokens;
  mapping(uint256 => SubscriptionGroup) tokenSubscriptions;
}

struct SubscriptionDetails {
  bool isActive;
  uint32 tokenId;
  uint40 startDate;
  uint40 failedClaimDate;
  uint8 failedClaims;
}

struct Token {
  bool isActive;
  address contractAddress;
}

struct ClaimableAmount {
  uint96 amount;
  address contractAddress;
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