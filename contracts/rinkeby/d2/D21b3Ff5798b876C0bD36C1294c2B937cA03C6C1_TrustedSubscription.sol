pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract TrustedSubscription is Ownable {

  uint256 constant MAX_FEE = 10_000;
  uint256 constant DEFAULT_FEE = 500; // 0.5%
  uint256 constant MAX_FAILED_CLAIMS = 3;

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
    uint16 fee;
    address claimAddress;
    uint40 lastClaimDate;
    Tier[] tiers;
    uint32[] activeTokenIds;
    mapping(uint256 => SubscriptionGroup) tokenSubsGroups;
  }

  struct SubscriptionDetails {
    bool isActive;
    uint40 startDate;
    uint8 failedClaims;
  }

  struct TokenDetails {
    address contractAddress;
  }

  event Subscribed(uint256 indexed projectId, address indexed donator, uint256 timestamp);
  event Unsubscribed(uint256 indexed projectId, address indexed donator, uint256 timestamp);
  event ClaimFailed(uint256 indexed projectId, address indexed donator, uint256 timestamp);

  uint32 projectCounter;

  mapping(uint256 => Project) projects;
  mapping(address => mapping(uint256 => SubscriptionDetails)) donators;
  mapping(uint256 => TokenDetails) tokens;

  function registerProject(address claimAddress, Tier[] calldata tiers) public onlyOwner {
    uint32 projectId = ++projectCounter;
    Project storage project = projects[projectId];

    require(project.claimAddress == address(0), 'Project already registered');
    require(claimAddress != address(0), 'Zero claim address');

    project.id = projectId;
    project.isActive = true;
    project.fee = uint16(DEFAULT_FEE);
    project.claimAddress = claimAddress;

    for (uint256 i; i < tiers.length; ++i) {
      project.tiers.push(tiers[i]);
    }
  }

  function enableProject(uint256 projectId) public onlyOwner {
    projects[projectId].isActive = true;
  }

  function disableProject(uint256 projectId) public onlyOwner {
    projects[projectId].isActive = false;
  }

  function addTiers(uint256 projectId, Tier[] calldata newTiers) public onlyOwner {
    Project storage project = projects[projectId];
    require(project.isActive, 'Project is not active'); 

    for (uint256 i; i < newTiers.length; ++i) {
      project.tiers.push(newTiers[i]);
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

  function subscribe(uint256 projectId, uint16 tierIndex) public {
    Project storage project = projects[projectId];
    Tier storage tier = project.tiers[tierIndex];

    require(project.isActive, 'Project is not active'); 
    require(tier.isActive, 'Subscription tier is not active');

    if (project.lastClaimDate == 0) {
      project.lastClaimDate = uint40(block.timestamp);
    }

    addTokenIdIfNeeded(project.activeTokenIds, tier.tokenId);

    SubscriptionGroup storage subsGroup = project.tokenSubsGroups[tier.tokenId];
    Subscription memory newSub = Subscription({tierIndex: tierIndex, donator: msg.sender});

    subsGroup.subscriptions.push(newSub);
    subsGroup.subscriptionIndices[msg.sender] = subsGroup.subscriptions.length - 1;
    
    SubscriptionDetails storage details = donators[msg.sender][projectId];
    details.isActive = true;
    details.startDate = uint40(block.timestamp);

    emit Subscribed(projectId, msg.sender, block.timestamp);
  }

  function unsubscribe(uint256 projectId, address donator, uint32 tokenId) public {
    require(msg.sender == donator || msg.sender == owner(), 'Not authorized to unsubscribe');

    SubscriptionGroup storage subsGroup = projects[projectId].tokenSubsGroups[tokenId];

    uint256 totalGroupSubs = subsGroup.subscriptions.length;
    uint256 index = subsGroup.subscriptionIndices[donator];
    
    Subscription storage sub = subsGroup.subscriptions[index];
    require(sub.donator == donator, 'Donator does not match');

    subsGroup.subscriptions[index] = subsGroup.subscriptions[totalGroupSubs - 1];
    subsGroup.subscriptions.pop();

    if (totalGroupSubs == 1) {
      removeTokenId(projects[projectId].activeTokenIds, tokenId);
    }

    delete subsGroup.subscriptionIndices[donator];
    delete donators[donator][projectId];

    emit Unsubscribed(projectId, donator, block.timestamp);
  }

  function claim(uint256 projectId) public {
    uint32[] storage activeTokenIds = projects[projectId].activeTokenIds;

    for (uint256 i; i < activeTokenIds.length; ++i) {
      claim(projectId, activeTokenIds[i]);
    }
  }

  function claim(uint256 projectId, uint32 tokenId) public {
    Project storage project = projects[projectId];
    SubscriptionGroup storage subsGroup = project.tokenSubsGroups[tokenId];
    claimIn(projectId, tokenId, 0, subsGroup.subscriptions.length);
  }

  function claimIn(uint256 projectId, uint32 tokenId, uint256 start, uint256 end) public {
    Project storage project = projects[projectId];
    SubscriptionGroup storage subsGroup = project.tokenSubsGroups[tokenId];

    require(project.isActive, 'Project is not active'); 
    require(project.claimAddress != address(0), 'Claim address is zero');

    uint256 totalAmount;
    uint256 totalFee;
    IERC20 token = IERC20(tokens[tokenId].contractAddress);

    for (uint256 i = start; i < end; ++i) {
      Subscription storage sub = subsGroup.subscriptions[i];
      Tier storage tier = project.tiers[sub.tierIndex];

      uint256 chargeAmount = tier.amount * (block.timestamp - project.lastClaimDate) / tier.period;
      uint256 fee = totalAmount * project.fee / MAX_FEE;

      totalAmount += chargeAmount;
      totalFee += fee;

      try token.transferFrom(sub.donator, address(this), chargeAmount) returns (bool success) {
        if (!success) {
          failedClaim(project, sub.donator, tier);
        }
      } catch {
        failedClaim(project, sub.donator, tier);
      }
    }

    token.transferFrom(address(this), project.claimAddress, totalAmount - totalFee);
    project.lastClaimDate = uint40(block.timestamp);
  }

  function failedClaim(Project storage project, address donator, Tier storage tier) internal {
    SubscriptionDetails storage subDetails = donators[donator][project.id];

    IERC20 token = IERC20(tokens[tier.tokenId].contractAddress);
    uint256 allowance = token.allowance(donator, address(this));

    if (allowance < tier.amount || subDetails.failedClaims + 1 >= MAX_FAILED_CLAIMS) {
      unsubscribe(project.id, donator, tier.tokenId);
    } else {
      subDetails.failedClaims += 1;

      if (subDetails.isActive) {
        subDetails.isActive = false;
      }

      emit ClaimFailed(project.id, donator, block.timestamp);
    }
  }

  function addTokenIdIfNeeded(uint32[] storage activeTokenIds, uint32 tokenId) internal {
      for (uint256 i; i < activeTokenIds.length; ++i) {
        if (tokenId == activeTokenIds[i]) {
          return;
        }
      }

      activeTokenIds.push(tokenId);
  }

  function removeTokenId(uint32[] storage activeTokenIds, uint32 tokenId) internal {
    uint256 length = activeTokenIds.length;

    for (uint256 i; i < length; ++i) {
      if (tokenId == activeTokenIds[i]) {
        activeTokenIds[i] = activeTokenIds[length - 1];
        activeTokenIds.pop();
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