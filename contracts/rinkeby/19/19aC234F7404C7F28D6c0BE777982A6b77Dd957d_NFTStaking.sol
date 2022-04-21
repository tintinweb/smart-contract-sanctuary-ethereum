//SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.12;

// Imports
import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./IERC20.sol";
import "./IERC721.sol";

// MOD Interface
interface MODToken {
  function mint(address recipient, uint256 amount) external;
}

/// @title MOD - Staking Contract
contract NFTStaking is Ownable, ReentrancyGuard {
  // Staker details
  struct Staker {
    uint256[] tokenIds;
    uint256 currentYield;
    uint256 numberOfTokensStaked;
    uint256 lastCheckpoint;
  }

  uint256 public constant SECONDS_IN_DAY = 24 * 60 * 60;
  IERC721 public immutable nftContract;
  MODToken public immutable rewardToken;
  bool public stakingLaunched;
  mapping(address => Staker) public stakers;
  uint256 public lowYieldEndBound = 4;
  uint256 public mediumYieldEndBound = 9;
  uint256 public highYieldStartBound = 10;
  uint256 public lowYieldPerSecond;
  uint256 public mediumYieldPerSecond;
  uint256 public highYieldPerSecond;
  bytes4 private constant _ERC721_RECEIVED = 0x150b7a02;
  mapping(uint256 => address) private _ownerOfToken;

  event Deposit(address indexed staker, uint256 amount);
  event Withdraw(address indexed staker, uint256 amount);
  event Claim(address indexed staker, uint256 tokenAmount);

  /// @dev The contract constructor
  constructor(
    IERC721 _nftContract,
    MODToken _rewardToken,
    uint256 _lowYieldPerDay,
    uint256 _mediumYieldPerDay,
    uint256 _highYieldPerDay
  ) {
    rewardToken = _rewardToken;
    nftContract = _nftContract;

    lowYieldPerSecond = _lowYieldPerDay / SECONDS_IN_DAY;
    mediumYieldPerSecond = _mediumYieldPerDay / SECONDS_IN_DAY;
    highYieldPerSecond = _highYieldPerDay / SECONDS_IN_DAY;
  }

  /**
   * @param _lowYieldEndBound The upper bound of the lowest range that produces low yield
   * @param _lowYieldPerDay The amount of tokens in Wei that a user earns for each token in the lowest range per day
   * @param _mediumYieldEndBound The upper bound of the medium range that produces medium yield
   * @param _mediumYieldPerDay The amount of tokens in Wei that a user earns for each token in the medium range per day
   * @param _highYieldStartBound The lower bound of the highest range that produces high yield
   * @param _highYieldPerDay The amount of tokens in Wei that a user earns for each token in the highest range per day
   * @dev Sets yield parameters
   */
  function setYieldParams(
    uint256 _lowYieldEndBound,
    uint256 _lowYieldPerDay,
    uint256 _mediumYieldEndBound,
    uint256 _mediumYieldPerDay,
    uint256 _highYieldStartBound,
    uint256 _highYieldPerDay
  ) external onlyOwner {
    lowYieldEndBound = _lowYieldEndBound;
    lowYieldPerSecond = _lowYieldPerDay / SECONDS_IN_DAY;

    mediumYieldEndBound = _mediumYieldEndBound;
    mediumYieldPerSecond = _mediumYieldPerDay / SECONDS_IN_DAY;

    highYieldStartBound = _highYieldStartBound;
    highYieldPerSecond = _highYieldPerDay / SECONDS_IN_DAY;
  }

  /**
   * @param tokenIds The list of token IDs to stake
   * @dev Stakes NFTs
   */
  function deposit(uint256[] memory tokenIds) external nonReentrant {
    require(stakingLaunched, "Staking is not launched yet");
    Staker storage staker = stakers[_msgSender()];
    if (staker.numberOfTokensStaked > 0) {
      uint256 rewards = getUnclaimedRewards(_msgSender());
      _claimReward(_msgSender(), rewards);
    }

    for (uint256 i; i < tokenIds.length; i++) {
      require(nftContract.ownerOf(tokenIds[i]) == _msgSender(), "Not the owner");
      nftContract.safeTransferFrom(_msgSender(), address(this), tokenIds[i]);
      _ownerOfToken[tokenIds[i]] = _msgSender();
      staker.tokenIds.push(tokenIds[i]);
      staker.numberOfTokensStaked += 1;
    }

    staker.currentYield = getTotalYieldPerSecond(staker.numberOfTokensStaked);
    staker.lastCheckpoint = block.timestamp;
    emit Deposit(_msgSender(), tokenIds.length);
  }

  /**
   * @param tokenIds The list of token IDs to unstake
   * @dev Withdraws NFTs
   */
  function withdraw(uint256[] memory tokenIds) external nonReentrant {
    Staker storage staker = stakers[_msgSender()];
    if (staker.numberOfTokensStaked > 0) {
      uint256 rewards = getUnclaimedRewards(_msgSender());
      _claimReward(_msgSender(), rewards);
    }

    for (uint256 i; i < tokenIds.length; i++) {
      require(nftContract.ownerOf(tokenIds[i]) == address(this), "Invalid tokenIds provided");
      require(_ownerOfToken[tokenIds[i]] == _msgSender(), "Not the owner of one ore more provided tokens");
      _ownerOfToken[tokenIds[i]] = address(0);

      staker.tokenIds = _moveTokenToLast(staker.tokenIds, tokenIds[i]);
      staker.tokenIds.pop();
      staker.numberOfTokensStaked -= 1;

      nftContract.safeTransferFrom(address(this), _msgSender(), tokenIds[i]);
    }

    staker.currentYield = getTotalYieldPerSecond(staker.numberOfTokensStaked);
    staker.lastCheckpoint = block.timestamp;

    emit Withdraw(_msgSender(), tokenIds.length);
  }

  /// @dev Transfers reward to a user
  function claimReward() external nonReentrant {
    Staker storage staker = stakers[_msgSender()];
    if (staker.numberOfTokensStaked > 0) {
      uint256 rewards = getUnclaimedRewards(_msgSender());
      _claimReward(_msgSender(), rewards);
    }

    staker.lastCheckpoint = block.timestamp;
  }

  /**
   * @param tokenIds The list of token IDs to withdraw
   * @dev Withdraws ERC721 in case of emergency
   */
  function emergencyWithdraw(uint256[] memory tokenIds) external onlyOwner {
    require(tokenIds.length <= 50, "50 is max per tx");
    for (uint256 i; i < tokenIds.length; i++) {
      address receiver = _ownerOfToken[tokenIds[i]];
      if (receiver != address(0) && nftContract.ownerOf(tokenIds[i]) == address(this)) {
        nftContract.transferFrom(address(this), receiver, tokenIds[i]);
      }
    }
  }

  /// @dev Starts NFT staking program
  function launchStaking() external onlyOwner {
    require(!stakingLaunched, "Staking has been launched already");
    stakingLaunched = true;
  }

  /**
   * @param balance The balance of a user
   * @dev Gets total yield per second of all staked tokens of a user
   */
  function getTotalYieldPerSecond(uint256 balance) public view returns (uint256) {
    if (balance == 0) {
      return 0;
    }

    if (balance <= lowYieldEndBound) {
      return balance * lowYieldPerSecond;
    } else if (balance <= mediumYieldEndBound) {
      return lowYieldEndBound * lowYieldPerSecond + (balance - lowYieldEndBound) * mediumYieldPerSecond;
    } else if (balance >= highYieldStartBound) {
      uint256 lowYieldAmount = lowYieldEndBound;
      uint256 mediumYieldAmount = mediumYieldEndBound - lowYieldEndBound;
      uint256 highYieldAmount = balance - lowYieldAmount - mediumYieldAmount;
      return lowYieldAmount * lowYieldPerSecond + mediumYieldAmount * mediumYieldPerSecond + highYieldAmount * highYieldPerSecond;
    }

    return 0;
  }

  /**
   * @param staker The address of a user
   * @dev Calculates unclaimed reward of a user
   */
  function getUnclaimedRewards(address staker) public view returns (uint256) {
    if (stakers[staker].lastCheckpoint == 0) {
      return 0;
    }

    return (block.timestamp - stakers[staker].lastCheckpoint) * stakers[staker].currentYield;
  }

  /**
   * @param staker The address of a user
   * @dev Returns all token IDs staked by a user
   */
  function getStakedTokens(address staker) public view returns (uint256[] memory) {
    return stakers[staker].tokenIds;
  }

  /**
   * @param staker The address of a user
   * @dev Returns the number of tokens staked by a user
   */
  function getTotalStakedAmount(address staker) public view returns (uint256) {
    return stakers[staker].numberOfTokensStaked;
  }

  /// @dev Gets called whenever an IERC721 tokenId token is transferred to this contract via IERC721.safeTransferFrom
  function onERC721Received(
    address,
    address,
    uint256,
    bytes calldata data
  ) public returns (bytes4) {
    return _ERC721_RECEIVED;
  }

  /**
   * @param list The array of token IDs
   * @param tokenId The token ID to move to the end of the array
   * @dev Moves the element that matches tokenId to the end of the array
   */
  function _moveTokenToLast(uint256[] memory list, uint256 tokenId) internal pure returns (uint256[] memory) {
    uint256 tokenIndex = 0;
    uint256 lastTokenIndex = list.length - 1;
    uint256 length = list.length;

    for (uint256 i = 0; i < length; i++) {
      if (list[i] == tokenId) {
        tokenIndex = i + 1;
        break;
      }
    }
    require(tokenIndex != 0, "msg.sender is not the owner");

    tokenIndex -= 1;

    if (tokenIndex != lastTokenIndex) {
      list[tokenIndex] = list[lastTokenIndex];
      list[lastTokenIndex] = tokenId;
    }

    return list;
  }

  /**
   * @param staker The user address
   * @param amount The amount of tokens to claim
   * @dev Transfers reward to a user
   */
  function _claimReward(address staker, uint256 amount) private {
    rewardToken.mint(staker, amount);
    emit Claim(staker, amount);
  }
}