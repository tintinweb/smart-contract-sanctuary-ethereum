// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "./Ownable.sol";
import "./IERC721.sol";
import "./IERC20.sol";
import "./ECDSA.sol";
import "./ReentrancyGuard.sol";

contract NFTStaking is Ownable, ReentrancyGuard {
  uint256 public constant SECONDS_IN_DAY = 24 * 60 * 60;

  bool public stakingLaunched;
  bool public depositPaused;
  address[3] public tokenAddresses;
  bool[3] public tokenTypeSeeded;   // To indicate that the categories have been seeded

  uint256 private constant TOKEN1 = 0;
  uint256 private constant TOKEN2 = 1;
  uint256 private constant BOOSTER = 2;

  enum ContractTypes {
    Token1,
    Token2,
    Booster
  }

  struct Staker {
    uint256 claimedRewards;
    uint256 lastCheckpoint;
    uint256[] stakedToken1;
    uint256[] stakedToken2;
    uint256[] stakedBoosters;
  }
  uint256 constant private NUMBER_OF_TOKEN_TYPES = 3;
  uint256 constant private MAX_NUMBER_OF_CATEGORIES_PER_TOKEN_TYPE= 5;
  uint256[NUMBER_OF_TOKEN_TYPES] public numberOfCategoryPerType = [5, 5, 3];
  uint256[MAX_NUMBER_OF_CATEGORIES_PER_TOKEN_TYPE][NUMBER_OF_TOKEN_TYPES] public yieldsPerCategoryPerTokenType;  // When defining matrices, the indexes are reversed

  // token1Categories is a byte array of NFT collection's size
  // each byte at index `tokenId` contains the number that represent the categories of the tokenId
  bytes private _token1Categories;
  bytes private _token2Categories;
  bytes private _boosterCategories;
  //bytes[][3] private _tokenCategories; // This doesn't work yet

  mapping(address => Staker) public stakers;
  mapping(uint256 => mapping(uint256 => address)) private _ownerOfToken;

  event Deposit(address indexed staker, address nftContract, uint256 tokensAmount);
  event Withdraw(address indexed staker, address nftContract, uint256 tokensAmount);
  event WithdrawStuckERC721(address indexed receiver, address indexed tokenAddress, uint256 indexed tokenId);

  constructor(
    // declare a base NFT contract for staking
    address _token1
  ) {
    tokenAddresses[TOKEN1] = _token1;
    yieldsPerCategoryPerTokenType[0][0] = 100 ether;
    yieldsPerCategoryPerTokenType[0][1] = 120 ether;
    yieldsPerCategoryPerTokenType[0][2] = 140 ether;
    yieldsPerCategoryPerTokenType[0][3] = 150 ether;
    yieldsPerCategoryPerTokenType[0][4] = 200 ether;
  }

  function setTokenAddresses(address token1, address token2, address booster) external onlyOwner {
    tokenAddresses[TOKEN1] = token1;
    tokenAddresses[TOKEN2] = token2;
    tokenAddresses[BOOSTER] = booster;
  }

  // function massUpdateCategories(ContractTypes contractType, bytes calldata categoryInBytes) external onlyOwner onlyValidContract(nftContract) {
  //   _tokenCategories[uint(contractType)] = categoryInBytes;
  // }

   function setCategoriesBatch(ContractTypes contractType, bytes calldata categoryInBytes) external onlyOwner {
    tokenTypeSeeded[uint(contractType)] = true;
    if (contractType == ContractTypes.Token1) {
      _token1Categories = categoryInBytes;
    } else if (contractType == ContractTypes.Token2) {
      _token2Categories = categoryInBytes;
    } else if (contractType == ContractTypes.Booster) {
      _boosterCategories = categoryInBytes;
    }
  }

  function setCategoryYield(
    ContractTypes contractType,
    uint8 category,
    uint256 yield
  ) external onlyOwner {
    require(category <= numberOfCategoryPerType[uint(contractType)], "Invalid category number");
    yieldsPerCategoryPerTokenType[uint(contractType)][category] = yield;
  }

  function setCategoryYieldsBatch(ContractTypes contractType, uint256[] memory yields) external onlyOwner {
    require(yields.length == numberOfCategoryPerType[uint(contractType)], "Length not match");
    for (uint256 i; i < yields.length; i++) {
      yieldsPerCategoryPerTokenType[uint(contractType)][i] = yields[i];
    }
  }

  // function getCategoryOfToken(ContractTypes contractType, uint256 tokenId) public view returns (uint8) {
  //   return uint8(_tokenCategories[uint(contractType)][tokenId]);
  // }

 function getCategoryOfToken(ContractTypes contractType, uint256 tokenId) public view returns (uint8) {
    if (tokenTypeSeeded[uint(contractType)] == false) {
      return 0;
    }
    if (contractType == ContractTypes.Token1) {
      return uint8(_token1Categories[tokenId]);
    } else if (contractType == ContractTypes.Token2) {
      return uint8(_token2Categories[tokenId]);
    } else if (contractType == ContractTypes.Booster) {
      return uint8(_boosterCategories[tokenId]);
    }
    return 0;
  }

  function getCategoriesForTokens(ContractTypes contractType, uint256[] memory tokenIds) external view returns (uint8[] memory) {
    uint8[] memory categories = new uint8[](tokenIds.length);
    for (uint256 i; i < tokenIds.length; i++) {
      categories[i] = getCategoryOfToken(contractType, tokenIds[i]);
    }
    return categories;
  }

  function getTokenYield(ContractTypes contractType, uint256 tokenId) public view returns (uint256) {
    uint8 category = getCategoryOfToken(contractType, tokenId);
    return yieldsPerCategoryPerTokenType[uint(contractType)][category];
  }

  function getYieldsForTokens(ContractTypes contractType, uint256[] memory tokenIds) external view returns (uint256[] memory) {
    uint256[] memory yields = new uint256[](tokenIds.length);
    for (uint256 i; i < tokenIds.length; i++) {
      yields[i] = getTokenYield(contractType, tokenIds[i]);
    }
    return yields;
  }

  function calculateBoostersYield(address userAddress) public view returns (uint256) {
    uint256 numberToken1Staked = stakers[userAddress].stakedToken1.length;
    uint256[] memory boosters = stakers[userAddress].stakedBoosters;

    // Maximum of 2 boosters can be applied to each token
    uint256 maximumApplicableBoosters = numberToken1Staked * 2;
    uint256 applicableBoosters = boosters.length < maximumApplicableBoosters ? boosters.length : maximumApplicableBoosters;

    uint256 totalBoosterYield;
    for (uint256 i; i < applicableBoosters; i++) {
      uint256 tokenId = boosters[i];
      totalBoosterYield += getTokenYield(ContractTypes.Booster, tokenId);
    }

    return totalBoosterYield;
  }

  function getCurrentYield(address userAddress) public view returns (uint256) {
    uint256 numberToken1Staked = stakers[userAddress].stakedToken1.length;
    uint256 numberToken2Staked = stakers[userAddress].stakedToken2.length;
    uint currentYield = 0;
    for (uint256 i; i < numberToken1Staked; i++) {
      currentYield += getTokenYield(ContractTypes.Token1, stakers[userAddress].stakedToken1[i]);
    }
    for (uint256 i; i < numberToken2Staked; i++) {
      currentYield += getTokenYield(ContractTypes.Token2, stakers[userAddress].stakedToken2[i]);
    }
    currentYield += calculateBoostersYield(userAddress);
    return currentYield;
  }

  function deposit(ContractTypes contractType, uint256[] memory tokenIds) external nonReentrant {
    require(uint(contractType) < tokenAddresses.length, "Not a valid contract");
    require(!depositPaused, "Deposit paused");
    require(stakingLaunched, "Staking is disabled");
    require(tokenIds.length > 0, "No token Ids specified");
    address tokenAddress = tokenAddresses[uint(contractType)];

    _claimRewards(_msgSender());

    Staker storage user = stakers[_msgSender()];

    if (contractType == ContractTypes.Booster) {
      // If a user tries to stake a Booster but does not have any Collection1 NFTs staked, the stake is prohibited
      require(user.stakedBoosters.length + tokenIds.length <= user.stakedToken1.length * 2, "Maximum num of boosters reached");
    }

    for (uint256 i; i < tokenIds.length; i++) {
      require(IERC721(tokenAddress).ownerOf(tokenIds[i]) == _msgSender(), "Not the owner");
      IERC721(tokenAddress).safeTransferFrom(_msgSender(), address(this), tokenIds[i]);
      _ownerOfToken[uint(contractType)][tokenIds[i]] = _msgSender();

      if (contractType == ContractTypes.Token1) {
        user.stakedToken1.push(tokenIds[i]);
      } else if (contractType == ContractTypes.Token2) {
        user.stakedToken2.push(tokenIds[i]);
      } else if (contractType == ContractTypes.Booster) {
        user.stakedBoosters.push(tokenIds[i]);
      }
    }
    emit Deposit(_msgSender(), tokenAddress, tokenIds.length);
  }

  function withdraw(ContractTypes contractType, uint256[] memory tokenIds) external nonReentrant {
    require(uint(contractType) < tokenAddresses.length, "Not a valid contract");
    require(tokenIds.length > 0, "No token Ids specified");
    address tokenAddress = tokenAddresses[uint(contractType)];

    _claimRewards(_msgSender());

    Staker storage user = stakers[_msgSender()];

    for (uint256 i; i < tokenIds.length; i++) {
      uint256 tokenId = tokenIds[i];
      require(IERC721(tokenAddress).ownerOf(tokenId) == address(this), "Invalid tokenIds provided");
      require(_ownerOfToken[uint(contractType)][tokenId] == _msgSender(), "Not token owner");
      _ownerOfToken[uint(contractType)][tokenId] = address(0);

      if (contractType == ContractTypes.Token1) {
        user.stakedToken1 = _moveTokenToLast(user.stakedToken1, tokenId);
        user.stakedToken1.pop();
      } else if (contractType == ContractTypes.Token2) {
        user.stakedToken2 = _moveTokenToLast(user.stakedToken2, tokenId);
        user.stakedToken2.pop();
      } else if (contractType == ContractTypes.Booster) {
        user.stakedBoosters = _moveTokenToLast(user.stakedBoosters, tokenId);
        user.stakedBoosters.pop();
      }

      IERC721(tokenAddress).safeTransferFrom(address(this), _msgSender(), tokenId);
    }

    emit Withdraw(_msgSender(), tokenAddress, tokenIds.length);
  }

  function getTotalRewards(address staker) external view returns (uint256) {
    return stakers[staker].claimedRewards + getUnclaimedRewards(staker); // Claimed is before lastCheckout, unclaimed is after
  }

  function getStakerTokens(ContractTypes contractType, address staker) public view returns (uint256[] memory) {
    uint256[] memory tokens;
    if (contractType == ContractTypes.Token1) {
      tokens = stakers[staker].stakedToken1;
    } else if (contractType == ContractTypes.Token2) {
      tokens = stakers[staker].stakedToken2;
    } else if (contractType == ContractTypes.Booster) {
      tokens = stakers[staker].stakedBoosters;
    }
    return tokens;
  }

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

  function getUnclaimedRewards(address staker) public view returns (uint256) {
    if (stakers[staker].lastCheckpoint == 0) {
      return 0;
    }
    return ((block.timestamp - stakers[staker].lastCheckpoint) * getCurrentYield(staker)) / SECONDS_IN_DAY;
  }

  function _claimRewards(address staker) internal {
    stakers[staker].claimedRewards += getUnclaimedRewards(staker);
    stakers[staker].lastCheckpoint = block.timestamp;
  }

  /**
   * @dev Returns token owner address (returns address(0) if token is not inside the gateway)
   */
  function ownerOf(ContractTypes contractType, uint256 tokenId) public view returns (address) {
    return _ownerOfToken[uint(contractType)][tokenId];
  }

  /**
   * @dev Function allows admin withdraw ERC721 in case of emergency.
   */
  function emergencyWithdraw(ContractTypes contractType, uint256[] memory tokenIds) public onlyOwner {
    require(tokenIds.length <= 50, "50 is max per tx");
    require(uint(contractType) < tokenAddresses.length, "Not a valid contract");
    address tokenAddress = tokenAddresses[uint(contractType)];
    pauseDeposit(true);
    for (uint256 i; i < tokenIds.length; i++) {
      address receiver = _ownerOfToken[uint(contractType)][tokenIds[i]];
      if (receiver != address(0) && IERC721(tokenAddress).ownerOf(tokenIds[i]) == address(this)) {
        IERC721(tokenAddress).transferFrom(address(this), receiver, tokenIds[i]);
        emit WithdrawStuckERC721(receiver, tokenAddress, tokenIds[i]);
      }
    }
  }

  /**
   * @dev Function allows to pause deposits if needed. Withdraw remains active.
   */
  function pauseDeposit(bool _pause) public onlyOwner {
    depositPaused = _pause;
  }

  function launchStaking() public onlyOwner {
    require(!stakingLaunched, "Staking was enabled");
    stakingLaunched = true;
  }

  function onERC721Received(
    address,
    address,
    uint256,
    bytes calldata
  ) external pure returns (bytes4) {
    return bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"));
  }
}