// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/interfaces/IERC721Enumerable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/ICroak.sol";
import "./interfaces/ISwampStaking.sol";
import "./interfaces/ISwampverseItems.sol";

/// @title Swampverse: Scavenger Runs
/// @author @ryeshrimp
/// @notice By using staked tokens in stakingContract, users are able to pay to go on scavenger runs for a chance to win an ERC1155 token.

contract SwampverseScavengerRun is ReentrancyGuard, Pausable, Ownable {

    uint32 public constant SECONDS_IN_DAY = 1 days;

    struct Run {
      uint percentSuccessful;
      uint amountFound;
      uint start;            // block.timestamp
      uint end;              // block.timestamp
      address owner;
      bool success;
    }

    mapping(uint => Run) private swamperScavengerRuns;
    mapping(uint => Run) private creatureScavengerRuns;

    //@notice unclaimed swampPiles
    mapping(address => uint) private swampPileRewards;

    mapping(uint => uint) public swampersTotalFound;
    mapping(uint => uint) public creaturesTotalFound;

    ISwampverseItems public swampPileContract;
    IERC721Enumerable public swampverseContract; 
    IERC721Enumerable public creatureContract; 
    ISwampStaking public stakingContract;
    ICroak public croakContract;

    uint public runDurationDays;
    uint public creaturePercentSuccessRate;
    uint public creatureDoubleSuccessRate;
    uint public swamperPercentSuccessRate;
    uint public croakRunCost;

    constructor(
      address _swampPileContract,
      address _swampverseContract,
      address _creatureContract,
      address _stakingContract,
      address _croakContract,
      uint _runDurationDays,
      uint _creaturePercentSuccessRate,
      uint _creatureDoubleSuccessRate,
      uint _swamperPercentSuccessRate,
      uint _croakRunCost
    ) {
      swampPileContract = ISwampverseItems(_swampPileContract);
      swampverseContract = IERC721Enumerable(_swampverseContract);
      creatureContract = IERC721Enumerable(_creatureContract);
      stakingContract = ISwampStaking(_stakingContract);
      croakContract = ICroak(_croakContract);
      runDurationDays = _runDurationDays;
      creaturePercentSuccessRate = _creaturePercentSuccessRate;
      creatureDoubleSuccessRate = _creatureDoubleSuccessRate;
      swamperPercentSuccessRate = _swamperPercentSuccessRate;
      croakRunCost = _croakRunCost;
    }


    struct RecentRun {
      uint tokenId;
      uint percentSuccessful;
      uint totalFound;
      uint amountFound;
      uint start;            // block.timestamp
      uint end;              // block.timestamp
      bool success;
    }

    function mostRecentSwampRuns(address account) public view returns (RecentRun[] memory) {
      uint swampverseSupply = swampverseContract.totalSupply();
      RecentRun[] memory swamperTmp = new RecentRun[](swampverseSupply);

      uint swamperIndex;
      for(uint tokenId = 1; tokenId <= swampverseSupply; tokenId++) {
        if(swamperScavengerRuns[tokenId].owner == account) {
          swamperTmp[swamperIndex] = RecentRun({
             tokenId: tokenId,
             totalFound: swampersTotalFound[tokenId],
             percentSuccessful: swamperScavengerRuns[tokenId].percentSuccessful,
             amountFound: swamperScavengerRuns[tokenId].amountFound,
             start: swamperScavengerRuns[tokenId].start,
             end: swamperScavengerRuns[tokenId].end,
             success: swamperScavengerRuns[tokenId].success
          });

          if(block.timestamp < swamperTmp[swamperIndex].end) {
            swamperTmp[swamperIndex].totalFound -= swamperTmp[swamperIndex].amountFound;
            swamperTmp[swamperIndex].amountFound = 0;
            swamperTmp[swamperIndex].success = false;
          }

          swamperIndex++;
        }
      }

      RecentRun[] memory swamperRuns = new RecentRun[](swamperIndex);
      for(uint i; i < swamperIndex; i++) {
        swamperRuns[i] = swamperTmp[i];
      }

      return swamperRuns;
    }

    function mostRecentCreatureRuns(address account) public view returns (RecentRun[] memory) {
      uint creatureSupply = creatureContract.totalSupply();
      RecentRun[] memory creatureTmp = new RecentRun[](creatureSupply);

      uint creatureIndex;
      for(uint tokenId = 1; tokenId <= creatureSupply; tokenId++) {
        if(creatureScavengerRuns[tokenId].owner == account) {
          creatureTmp[creatureIndex] = RecentRun({
            tokenId: tokenId,
            totalFound: creaturesTotalFound[tokenId],
            amountFound: creatureScavengerRuns[tokenId].amountFound,
            percentSuccessful: creatureScavengerRuns[tokenId].percentSuccessful,
            start: creatureScavengerRuns[tokenId].start,
            end: creatureScavengerRuns[tokenId].end,
            success: creatureScavengerRuns[tokenId].success
          });

          if(creatureTmp[creatureIndex].end < block.timestamp) {
            creatureTmp[creatureIndex].totalFound -= creatureTmp[creatureIndex].amountFound;
            creatureTmp[creatureIndex].amountFound = 0;
            creatureTmp[creatureIndex].success = false;
          }

          creatureIndex++;
        }
      }

      RecentRun[] memory creatureRuns = new RecentRun[](creatureIndex);
      for(uint i; i < creatureIndex; i++) {
        creatureRuns[i] = creatureTmp[i];
      }

      return creatureRuns;
    }

    function unclaimedSwampPiles(address account) public view returns (uint) {
      uint unclaimed = swampPileRewards[account];
      
      if(mostRecentSwampRuns(account).length > 0) {
        for(uint tokenId = 0; tokenId < swampverseContract.totalSupply(); tokenId++) {
          if(swamperScavengerRuns[tokenId].owner == account) {
            if(block.timestamp < swamperScavengerRuns[tokenId].end) {
              unclaimed -= swamperScavengerRuns[tokenId].amountFound;
            }
          }
        }
      }

      if(mostRecentCreatureRuns(account).length > 0) {
        for(uint tokenId = 0; tokenId < creatureContract.totalSupply(); tokenId++) {
          if(creatureScavengerRuns[tokenId].owner == account) {
            if(block.timestamp < creatureScavengerRuns[tokenId].end) {
              unclaimed -= creatureScavengerRuns[tokenId].amountFound;
            }
          }
        }
      }

      return unclaimed;
    }
  
    /// @notice sets run duration and success rates
    /// @dev
    /// creaturePercentSuccessRate and creatureDoubleSuccessRate sum must = 100
    /// creatureDoubleSuccessRate should be the smaller number of the 2
    /// @param _mode:
    /// 1 - set scavenger duration in days
    /// 2 - set creature success rate
    /// 3 - set creature success rate to get double rewards
    /// 4 - set swamper success rate
    /// 5 - set croak run cost
    function setValues(uint _mode, uint _value) public onlyOwner {
      if (_mode == 1) runDurationDays = _value;
      else if (_mode == 2) {
        require(_value+creatureDoubleSuccessRate < 101, "Success rate greater than 100");
        creaturePercentSuccessRate = _value;
      }
      else if (_mode == 3) {
        require(_value+creaturePercentSuccessRate < 101, "Success rate greater than 100");
        creatureDoubleSuccessRate = _value;
      }
      else if (_mode == 4) swamperPercentSuccessRate = uint(_value);
      else if (_mode == 5) croakRunCost = _value;
      else revert("setValues: WRONG_MODE");
    }
    
    /// @notice sets addresses
    /// @param _mode:
    /// 1 - set staking contract
    /// 2 - set croak contract
    /// 3 - set swamp pile contract address
    /// 4 - set swampverse token address
    /// 5 - set creature token address
    function setAddresses(uint _mode, address _value) public onlyOwner {
      if (_mode == 1) stakingContract = ISwampStaking(_value);
      else if (_mode == 2) croakContract = ICroak(_value);
      else if (_mode == 3) swampPileContract = ISwampverseItems(_value);
      else if (_mode == 4) swampverseContract = IERC721Enumerable(_value);
      else if (_mode == 5) creatureContract = IERC721Enumerable(_value);

    }

    /// @notice Start multiple scavenger runs with swampers and creatures
    function startRuns(uint[] memory swamperIds, uint[] memory creatureIds) external whenNotPaused {
      require(croakContract.balanceOf(msg.sender) >= (swamperIds.length+creatureIds.length)*croakRunCost, "Not enough $croak");

      uint percentSuccessful;
      uint successScore;
      uint amountFound;
      uint totalFound;

      if(swamperIds.length > 0) {
        for (uint i; i < swamperIds.length;) {
          require(stakingContract.stakedSwampers(swamperIds[i]) == msg.sender, "not found");
          require(swamperScavengerRuns[swamperIds[i]].end < block.timestamp, "Scavenger run in progress");
          
          percentSuccessful = randomNum(swamperPercentSuccessRate, 777, swamperIds[i]) + 1;
          successScore = _getSuccessScore(swamperIds[i], 0);
          amountFound = _isSuccess(successScore, percentSuccessful, 0);
          
          unchecked { totalFound += amountFound; }
          
          swamperScavengerRuns[swamperIds[i]] = Run({
            percentSuccessful: percentSuccessful,
            start: block.timestamp,
            end: block.timestamp+(runDurationDays*SECONDS_IN_DAY),
            owner: msg.sender,
            success: amountFound > 0,
            amountFound: amountFound
          });

          if(amountFound > 0) {
            unchecked { swampersTotalFound[swamperIds[i]]++; }
          }

          unchecked { i++; }
        }

        //TODO: freeze swampers
        emit RunsStarted(msg.sender, swamperIds.length, swamperIds, 0);
      }

      if(creatureIds.length > 0) {
        for (uint i; i < creatureIds.length;) {
          require(stakingContract.stakedCreatures(creatureIds[i]) == msg.sender, "not found");
          require(creatureScavengerRuns[creatureIds[i]].end < block.timestamp, "Scavenger run in progress");

          percentSuccessful = randomNum(creaturePercentSuccessRate, 888, creatureIds[i]) + 1;
          successScore = _getSuccessScore(creatureIds[i], 1);
          amountFound = _isSuccess(successScore, percentSuccessful, creatureDoubleSuccessRate);
          unchecked { totalFound += amountFound; }

          creatureScavengerRuns[creatureIds[i]] = Run({
            percentSuccessful: percentSuccessful,
            start: block.timestamp,
            end: block.timestamp+(runDurationDays*SECONDS_IN_DAY),
            owner: msg.sender,
            success: amountFound > 0,
            amountFound: amountFound
          });

          if(amountFound > 0) {
            unchecked { creaturesTotalFound[creatureIds[i]] += amountFound; }
          }

          unchecked { i++; }
        }

        //TODO: freeze creatures
        emit RunsStarted(msg.sender, creatureIds.length, creatureIds, 1);
      }

      unchecked { swampPileRewards[msg.sender] += totalFound; }
      croakContract.burn(msg.sender, (swamperIds.length+creatureIds.length)*croakRunCost);
    }

    /// @notice Retreive a reward from a swamper
    function retrieveRewards() external {
      require(swampPileRewards[msg.sender] > 0, "No rewards found");
      swampPileContract.mintSwampPile(msg.sender, swampPileRewards[msg.sender]);
      swampPileRewards[msg.sender] = 0;
      emit RewardMinted(msg.sender, swampPileRewards[msg.sender]);
    }

    function _isSuccess(uint _successScore, uint _successRate, uint _doubleRate) private pure returns(uint) {
      if(_successScore < _doubleRate+1) return 2;
      else if(_successScore < _successRate+1) return 1;
      else return 0;
    }

    function _getSuccessScore(uint _tokenId, uint _type) private view returns(uint) {
      return uint(randomNum(100, _type, _tokenId)) + 1;
    }

    function randomNum(uint _mod, uint _seed, uint _salt) private view returns(uint) {
      return uint(keccak256(abi.encodePacked(block.timestamp, msg.sender, _seed, _salt))) % _mod;
    }

    /// @notice When paused, runs will be disabled but withdraw won't be
    function pause() external onlyOwner {
        _pause();
    }

    /// @notice When unpaused, runs will be re-enabled
    function unpause() external onlyOwner {
        _unpause();
    }

    /* ========== EVENTS ========== */
    event RunsStarted(address indexed user, uint amount, uint[] tokenIds, uint nftType);
    event RewardMinted(address indexed user, uint reward);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC721Enumerable.sol)

pragma solidity ^0.8.0;

import "../token/ERC721/extensions/IERC721Enumerable.sol";

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

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
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
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
        require(paused(), "Pausable: not paused");
        _;
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
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

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
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
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
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface ICroak {

  function mint(address to, uint256 amount) external;

  /**
   * burns $CROAK from a holder
   * @param from the holder of the $CROAK
   * @param amount the amount of $CROAK to burn
   */
  function burn(address from, uint256 amount) external;

  /**
  * enables an address to mint / burn
  * @param controller the address to enable
  */
  function addController(address controller) external returns(bool);

  /**
  * disables an address from minting / burning
  * @param controller the address to disbale
  */
  function removeController(address controller) external returns(bool);

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
}

// SPDX-License-Identifier: UNLICENSED
// !! THIS FILE WAS AUTOGENERATED BY abi-to-sol v0.5.2. SEE SOURCE BELOW. !!
pragma solidity ^0.8.4;

interface ISwampStaking {
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );
    event Paused(address account);
    event RewardPaid(address indexed user, uint256 reward);
    event Staked(
        address indexed user,
        uint256 amount,
        uint256[] tokenIds,
        uint256 nftType
    );
    event TokensPaused(uint256[] tokenIds, uint256 nftType);
    event Unpaused(address account);
    event Withdrawn(
        address indexed user,
        uint256 amount,
        uint256[] tokenIds,
        uint256 nftType
    );

    function SECONDS_IN_DAY() external view returns (uint32);

    function addController(address controller) external;

    function creatureRewardPerDay() external view returns (uint256);

    function creatureToken() external view returns (address);

    function creaturesPausedUntil(uint256) external view returns (uint256);

    function freezeTokens(
        uint256[] memory swamperIds,
        uint256[] memory creatureIds,
        uint256 pauseLength
    ) external;

    function getReward() external;

    function initialize(
        address _swamperToken,
        address _creatureToken,
        address _rewardsToken
    ) external;

    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) external returns (bytes4);

    function owner() external view returns (address);

    function pause() external;

    function paused() external view returns (bool);

    function pending(address account) external view returns (uint256);

    function removeController(address controller) external;

    function renounceOwnership() external;

    function rewardsToken() external view returns (address);

    function setAddresses(uint8 _mode, address _address) external;

    function setRewards(uint8 _mode, uint256 _amount) external;

    function stakeCreatures(uint256[] memory tokenIds) external;

    function stakeSwampers(uint256[] memory tokenIds) external;

    function stakedCreatures(uint256) external view returns (address);

    function stakedCreaturesByOwner(address account)
        external
        view
        returns (uint256[] memory);

    function stakedSwampers(uint256) external view returns (address);

    function stakedSwampersByOwner(address account)
        external
        view
        returns (uint256[] memory);

    function swamperRewardPerDay() external view returns (uint256);

    function swamperToken() external view returns (address);

    function swampersPausedUntil(uint256) external view returns (uint256);

    function transferOwnership(address newOwner) external;

    function unpause() external;

    function userInfo(address)
        external
        view
        returns (
            uint256 stakedCreatureCount,
            uint256 stakedSwamperCount,
            uint256 pendingRewards,
            uint256 lastUpdate
        );

    function withdrawCreatures(uint256[] memory tokenIds) external;

    function withdrawSwampers(uint256[] memory tokenIds) external;
}

// THIS FILE WAS AUTOGENERATED FROM THE FOLLOWING ABI JSON:
/*
[{"anonymous":false,"inputs":[{"indexed":true,"internalType":"address","name":"previousOwner","type":"address"},{"indexed":true,"internalType":"address","name":"newOwner","type":"address"}],"name":"OwnershipTransferred","type":"event"},{"anonymous":false,"inputs":[{"indexed":false,"internalType":"address","name":"account","type":"address"}],"name":"Paused","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"address","name":"user","type":"address"},{"indexed":false,"internalType":"uint256","name":"reward","type":"uint256"}],"name":"RewardPaid","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"address","name":"user","type":"address"},{"indexed":false,"internalType":"uint256","name":"amount","type":"uint256"},{"indexed":false,"internalType":"uint256[]","name":"tokenIds","type":"uint256[]"},{"indexed":false,"internalType":"uint256","name":"nftType","type":"uint256"}],"name":"Staked","type":"event"},{"anonymous":false,"inputs":[{"indexed":false,"internalType":"uint256[]","name":"tokenIds","type":"uint256[]"},{"indexed":false,"internalType":"uint256","name":"nftType","type":"uint256"}],"name":"TokensPaused","type":"event"},{"anonymous":false,"inputs":[{"indexed":false,"internalType":"address","name":"account","type":"address"}],"name":"Unpaused","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"address","name":"user","type":"address"},{"indexed":false,"internalType":"uint256","name":"amount","type":"uint256"},{"indexed":false,"internalType":"uint256[]","name":"tokenIds","type":"uint256[]"},{"indexed":false,"internalType":"uint256","name":"nftType","type":"uint256"}],"name":"Withdrawn","type":"event"},{"inputs":[],"name":"SECONDS_IN_DAY","outputs":[{"internalType":"uint32","name":"","type":"uint32"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address","name":"controller","type":"address"}],"name":"addController","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[],"name":"creatureRewardPerDay","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"creatureToken","outputs":[{"internalType":"contract IERC721Enumerable","name":"","type":"address"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"uint256","name":"","type":"uint256"}],"name":"creaturesPausedUntil","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"uint256[]","name":"swamperIds","type":"uint256[]"},{"internalType":"uint256[]","name":"creatureIds","type":"uint256[]"},{"internalType":"uint256","name":"pauseLength","type":"uint256"}],"name":"freezeTokens","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[],"name":"getReward","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"_swamperToken","type":"address"},{"internalType":"address","name":"_creatureToken","type":"address"},{"internalType":"address","name":"_rewardsToken","type":"address"}],"name":"initialize","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"","type":"address"},{"internalType":"address","name":"","type":"address"},{"internalType":"uint256","name":"","type":"uint256"},{"internalType":"bytes","name":"","type":"bytes"}],"name":"onERC721Received","outputs":[{"internalType":"bytes4","name":"","type":"bytes4"}],"stateMutability":"nonpayable","type":"function"},{"inputs":[],"name":"owner","outputs":[{"internalType":"address","name":"","type":"address"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"pause","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[],"name":"paused","outputs":[{"internalType":"bool","name":"","type":"bool"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address","name":"account","type":"address"}],"name":"pending","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address","name":"controller","type":"address"}],"name":"removeController","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[],"name":"renounceOwnership","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[],"name":"rewardsToken","outputs":[{"internalType":"contract ICroak","name":"","type":"address"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"uint8","name":"_mode","type":"uint8"},{"internalType":"address","name":"_address","type":"address"}],"name":"setAddresses","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"uint8","name":"_mode","type":"uint8"},{"internalType":"uint256","name":"_amount","type":"uint256"}],"name":"setRewards","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"uint256[]","name":"tokenIds","type":"uint256[]"}],"name":"stakeCreatures","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"uint256[]","name":"tokenIds","type":"uint256[]"}],"name":"stakeSwampers","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"uint256","name":"","type":"uint256"}],"name":"stakedCreatures","outputs":[{"internalType":"address","name":"","type":"address"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address","name":"account","type":"address"}],"name":"stakedCreaturesByOwner","outputs":[{"internalType":"uint256[]","name":"","type":"uint256[]"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"uint256","name":"","type":"uint256"}],"name":"stakedSwampers","outputs":[{"internalType":"address","name":"","type":"address"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address","name":"account","type":"address"}],"name":"stakedSwampersByOwner","outputs":[{"internalType":"uint256[]","name":"","type":"uint256[]"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"swamperRewardPerDay","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"swamperToken","outputs":[{"internalType":"contract IERC721Enumerable","name":"","type":"address"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"uint256","name":"","type":"uint256"}],"name":"swampersPausedUntil","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address","name":"newOwner","type":"address"}],"name":"transferOwnership","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[],"name":"unpause","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"","type":"address"}],"name":"userInfo","outputs":[{"internalType":"uint256","name":"stakedCreatureCount","type":"uint256"},{"internalType":"uint256","name":"stakedSwamperCount","type":"uint256"},{"internalType":"uint256","name":"pendingRewards","type":"uint256"},{"internalType":"uint256","name":"lastUpdate","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"uint256[]","name":"tokenIds","type":"uint256[]"}],"name":"withdrawCreatures","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"uint256[]","name":"tokenIds","type":"uint256[]"}],"name":"withdrawSwampers","outputs":[],"stateMutability":"nonpayable","type":"function"}]
*/

// SPDX-License-Identifier: UNLICENSED
// !! THIS FILE WAS AUTOGENERATED BY abi-to-sol v0.5.2. SEE SOURCE BELOW. !!
pragma solidity ^0.8.4;

interface ISwampverseItems {
    event ApprovalForAll(
        address indexed account,
        address indexed operator,
        bool approved
    );
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );
    event TransferSingle(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256 id,
        uint256 value
    );
    event URI(string value, uint256 indexed id);

    function BEGINNING_URI() external view returns (string memory);

    function ENDING_URI() external view returns (string memory);

    function RUSTY_METAL() external view returns (uint256);

    function SWAMP_BOAT() external view returns (uint256);

    function SWAMP_PASS() external view returns (uint256);

    function SWAMP_PILE() external view returns (uint256);

    function addController(address controller) external;

    function balanceOf(address account, uint256 id)
        external
        view
        returns (uint256);

    function balanceOfBatch(address[] memory accounts, uint256[] memory ids)
        external
        view
        returns (uint256[] memory);

    function burnBatch(
        address _from,
        uint256[] memory _ids,
        uint256[] memory _amounts
    ) external;

    function exists(uint256 id) external view returns (bool);

    function initialize(
        uint256 _swampPileCostForRustyMetal,
        uint256 _rustyMetalCostForSwampBoat,
        uint256 _maxSwampBoats
    ) external;

    function isApprovedForAll(address account, address operator)
        external
        view
        returns (bool);

    function maxSwampBoats() external view returns (uint256);

    function mintRustyMetal(uint256 amount) external;

    function mintSwampBoat(uint256 amount) external;

    function mintSwampPile(address minterAddress, uint256 amount) external;

    function owner() external view returns (address);

    function removeController(address controller) external;

    function renounceOwnership() external;

    function rustyMetalCostForSwampBoat() external view returns (uint256);

    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) external;

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) external;

    function setApprovalForAll(address operator, bool approved) external;

    function setURI(uint256 _mode, string memory _new_uri) external;

    function setValues(uint256 _mode, uint256 _value) external;

    function supportsInterface(bytes4 interfaceId) external view returns (bool);

    function swampPileCostForRustyMetal() external view returns (uint256);

    function totalSupply(uint256 id) external view returns (uint256);

    function transferOwnership(address newOwner) external;

    function uri(uint256 _tokenId) external view returns (string memory);
}

// THIS FILE WAS AUTOGENERATED FROM THE FOLLOWING ABI JSON:
/*
[{"anonymous":false,"inputs":[{"indexed":true,"internalType":"address","name":"account","type":"address"},{"indexed":true,"internalType":"address","name":"operator","type":"address"},{"indexed":false,"internalType":"bool","name":"approved","type":"bool"}],"name":"ApprovalForAll","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"address","name":"previousOwner","type":"address"},{"indexed":true,"internalType":"address","name":"newOwner","type":"address"}],"name":"OwnershipTransferred","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"address","name":"operator","type":"address"},{"indexed":true,"internalType":"address","name":"from","type":"address"},{"indexed":true,"internalType":"address","name":"to","type":"address"},{"indexed":false,"internalType":"uint256[]","name":"ids","type":"uint256[]"},{"indexed":false,"internalType":"uint256[]","name":"values","type":"uint256[]"}],"name":"TransferBatch","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"address","name":"operator","type":"address"},{"indexed":true,"internalType":"address","name":"from","type":"address"},{"indexed":true,"internalType":"address","name":"to","type":"address"},{"indexed":false,"internalType":"uint256","name":"id","type":"uint256"},{"indexed":false,"internalType":"uint256","name":"value","type":"uint256"}],"name":"TransferSingle","type":"event"},{"anonymous":false,"inputs":[{"indexed":false,"internalType":"string","name":"value","type":"string"},{"indexed":true,"internalType":"uint256","name":"id","type":"uint256"}],"name":"URI","type":"event"},{"inputs":[],"name":"BEGINNING_URI","outputs":[{"internalType":"string","name":"","type":"string"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"ENDING_URI","outputs":[{"internalType":"string","name":"","type":"string"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"RUSTY_METAL","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"SWAMP_BOAT","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"SWAMP_PASS","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"SWAMP_PILE","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address","name":"controller","type":"address"}],"name":"addController","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"account","type":"address"},{"internalType":"uint256","name":"id","type":"uint256"}],"name":"balanceOf","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address[]","name":"accounts","type":"address[]"},{"internalType":"uint256[]","name":"ids","type":"uint256[]"}],"name":"balanceOfBatch","outputs":[{"internalType":"uint256[]","name":"","type":"uint256[]"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address","name":"_from","type":"address"},{"internalType":"uint256[]","name":"_ids","type":"uint256[]"},{"internalType":"uint256[]","name":"_amounts","type":"uint256[]"}],"name":"burnBatch","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"uint256","name":"id","type":"uint256"}],"name":"exists","outputs":[{"internalType":"bool","name":"","type":"bool"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"uint256","name":"_swampPileCostForRustyMetal","type":"uint256"},{"internalType":"uint256","name":"_rustyMetalCostForSwampBoat","type":"uint256"},{"internalType":"uint256","name":"_maxSwampBoats","type":"uint256"}],"name":"initialize","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"account","type":"address"},{"internalType":"address","name":"operator","type":"address"}],"name":"isApprovedForAll","outputs":[{"internalType":"bool","name":"","type":"bool"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"maxSwampBoats","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"uint256","name":"amount","type":"uint256"}],"name":"mintRustyMetal","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"uint256","name":"amount","type":"uint256"}],"name":"mintSwampBoat","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"minterAddress","type":"address"},{"internalType":"uint256","name":"amount","type":"uint256"}],"name":"mintSwampPile","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[],"name":"owner","outputs":[{"internalType":"address","name":"","type":"address"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address","name":"controller","type":"address"}],"name":"removeController","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[],"name":"renounceOwnership","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[],"name":"rustyMetalCostForSwampBoat","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address","name":"from","type":"address"},{"internalType":"address","name":"to","type":"address"},{"internalType":"uint256[]","name":"ids","type":"uint256[]"},{"internalType":"uint256[]","name":"amounts","type":"uint256[]"},{"internalType":"bytes","name":"data","type":"bytes"}],"name":"safeBatchTransferFrom","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"from","type":"address"},{"internalType":"address","name":"to","type":"address"},{"internalType":"uint256","name":"id","type":"uint256"},{"internalType":"uint256","name":"amount","type":"uint256"},{"internalType":"bytes","name":"data","type":"bytes"}],"name":"safeTransferFrom","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"operator","type":"address"},{"internalType":"bool","name":"approved","type":"bool"}],"name":"setApprovalForAll","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"uint256","name":"_mode","type":"uint256"},{"internalType":"string","name":"_new_uri","type":"string"}],"name":"setURI","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"uint256","name":"_mode","type":"uint256"},{"internalType":"uint256","name":"_value","type":"uint256"}],"name":"setValues","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"bytes4","name":"interfaceId","type":"bytes4"}],"name":"supportsInterface","outputs":[{"internalType":"bool","name":"","type":"bool"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"swampPileCostForRustyMetal","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"uint256","name":"id","type":"uint256"}],"name":"totalSupply","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address","name":"newOwner","type":"address"}],"name":"transferOwnership","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"uint256","name":"_tokenId","type":"uint256"}],"name":"uri","outputs":[{"internalType":"string","name":"","type":"string"}],"stateMutability":"view","type":"function"}]
*/

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC721/extensions/IERC721Enumerable.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Enumerable is IERC721 {
    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
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