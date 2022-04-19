// SPDX-License-Identifier: UNLICENSED

// ███████╗███╗   ██╗███████╗ █████╗ ██╗  ██╗██╗   ██╗     ██████╗  ██████╗ ██████╗ ██╗     ██╗███╗   ██╗███████╗
// ██╔════╝████╗  ██║██╔════╝██╔══██╗██║ ██╔╝╚██╗ ██╔╝    ██╔════╝ ██╔═══██╗██╔══██╗██║     ██║████╗  ██║██╔════╝
// ███████╗██╔██╗ ██║█████╗  ███████║█████╔╝  ╚████╔╝     ██║  ███╗██║   ██║██████╔╝██║     ██║██╔██╗ ██║███████╗
// ╚════██║██║╚██╗██║██╔══╝  ██╔══██║██╔═██╗   ╚██╔╝      ██║   ██║██║   ██║██╔══██╗██║     ██║██║╚██╗██║╚════██║
// ███████║██║ ╚████║███████╗██║  ██║██║  ██╗   ██║       ╚██████╔╝╚██████╔╝██████╔╝███████╗██║██║ ╚████║███████║
// ╚══════╝╚═╝  ╚═══╝╚══════╝╚═╝  ╚═╝╚═╝  ╚═╝   ╚═╝        ╚═════╝  ╚═════╝ ╚═════╝ ╚══════╝╚═╝╚═╝  ╚═══╝╚══════╝

pragma solidity 0.8.13;

// Imports
import "./Ownable.sol";
import "./IERC721.sol";
import "./IERC20.sol";
import "./ECDSA.sol";
import "./ReentrancyGuard.sol";

/**
 * @title The staking smart contract.
 */
contract NFTStaking is Ownable, ReentrancyGuard {
  /// @notice The staker details.
  struct Staker {
    uint256 claimedRewards;
    uint256 lastCheckpoint;
    uint256[] stakedToken1;
    uint256[] stakedToken2;
    uint256[] stakedBoosters;
  }
  // @notice The available contract types.
  enum ContractTypes {
    Token1,
    Token2,
    Booster
  }
  /// @notice The number of seconds in a day.
  uint256 public constant SECONDS_IN_DAY = 24 * 60 * 60;
  /// @notice The flag that indicates if staking is launched.
  bool public stakingLaunched;
  /// @notice The flag that indicates if deposit is paused.
  bool public depositPaused;
  /// @notice The addresses of the token contracts.
  address[3] public tokenAddresses;
  /// @notice The flag indicates if the categories have been seeded.
  bool[3] public tokenTypeSeeded;
  /// @notice The index of the first NFT smart contract.
  uint256 private constant TOKEN1 = 0;
  /// @notice The index of the second NFT smart contract.
  uint256 private constant TOKEN2 = 1;
  /// @notice The index of the booster NFT smart contract.
  uint256 private constant BOOSTER = 2;
  /// @notice The number of types of tokens available.
  uint256 constant private NUMBER_OF_TOKEN_TYPES = 3;
  /// @notice The max number of token categories.
  uint256 constant private MAX_NUMBER_OF_CATEGORIES_PER_TOKEN_TYPE = 5;
  /// @notice The numbers of categories of each token type.
  uint256[NUMBER_OF_TOKEN_TYPES] public numberOfCategoryPerType = [5, 5, 3];
  /// @notice The yields for categories per token types.
  uint256[MAX_NUMBER_OF_CATEGORIES_PER_TOKEN_TYPE][NUMBER_OF_TOKEN_TYPES] public yieldsPerCategoryPerTokenType;
  /// @notice The categories of the first NFT smart contract tokens.
  bytes private _token1Categories;
  /// @notice The categories of the second NFT smart contract tokens.
  bytes private _token2Categories;
  /// @notice The categories of the booster NFT smart contract tokens.
  bytes private _boosterCategories;
  /// @notice The mapping of stakers.
  mapping(address => Staker) public stakers;
  /// @notice The mapping of token owners.
  mapping(uint256 => mapping(uint256 => address)) private _ownerOfToken;
  /// @notice The stake event.
  event Deposit(address indexed staker, address nftContract, uint256 tokensAmount);
  /// @notice The unstake event.
  event Withdraw(address indexed staker, address nftContract, uint256 tokensAmount);
  /// @notice The event fires during emergency funds withdrawal process.
  event WithdrawStuckERC721(address indexed receiver, address indexed tokenAddress, uint256 indexed tokenId);

  /**
   * @notice The smart contract constructor that initializes the contract.
   * @param _token1 The address of the first NFT smart contract.
   */
  constructor(
  // declare a base NFT contract for staking
    address _token1
  ) {
    // Set the variables.
    tokenAddresses[TOKEN1] = _token1;
    yieldsPerCategoryPerTokenType[0][0] = 100 ether;
    yieldsPerCategoryPerTokenType[0][1] = 120 ether;
    yieldsPerCategoryPerTokenType[0][2] = 140 ether;
    yieldsPerCategoryPerTokenType[0][3] = 150 ether;
    yieldsPerCategoryPerTokenType[0][4] = 200 ether;
  }

  /*
   * @notice Sets the addresses of the NFT collections.
   * @param token1 The address of the first collection.
   * @param token2 The address of the second collection.
   * @param booster The address of the booster collection.
   */
  function setTokenAddresses(address token1, address token2, address booster) external onlyOwner {
    tokenAddresses[TOKEN1] = token1;
    tokenAddresses[TOKEN2] = token2;
    tokenAddresses[BOOSTER] = booster;
  }

  /*
   * @notice Sets the categories of a specific collection.
   * @param contractType The type of the collection.
   * @param categoryInBytes The categories as an array of bytes.
   */
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

  /*
   * @notice Sets the yields of a specific collection category.
   * @param contractType The type of the collection.
   * @param category The category.
   * @param yield The yield value.
   */
  function setCategoryYield(
    ContractTypes contractType,
    uint8 category,
    uint256 yield
  ) external onlyOwner {
    require(category <= numberOfCategoryPerType[uint(contractType)], "Invalid category number");
    yieldsPerCategoryPerTokenType[uint(contractType)][category] = yield;
  }

  /*
   * @notice Sets the yields of collection categories.
   * @param contractType The type of the collection.
   * @param category The category.
   * @param yields The yield values.
   */
  function setCategoryYieldsBatch(ContractTypes contractType, uint256[] memory yields) external onlyOwner {
    require(yields.length == numberOfCategoryPerType[uint(contractType)], "Length not match");
    for (uint256 i; i < yields.length; i++) {
      yieldsPerCategoryPerTokenType[uint(contractType)][i] = yields[i];
    }
  }
  
  /*
   * @notice Returns the categories of the tokens.
   * @param contractType The type of the collection.
   * @param tokenIds The IDs of the tokens to get categories of.
   * @return The categories of the provided tokens.
   */
  function getCategoriesOfTokens(ContractTypes contractType, uint256[] memory tokenIds) external view returns (uint8[] memory) {
    uint8[] memory categories = new uint8[](tokenIds.length);
    for (uint256 i; i < tokenIds.length; i++) {
      categories[i] = getCategoryOfToken(contractType, tokenIds[i]);
    }
    return categories;
  }

  /*
   * @notice Stakes the NFTs.
   * @param contractType The type of the collection.
   * @param tokenIds The IDs of the tokens to stake.
   */
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

  /*
   * @notice Unstakes the NFTs.
   * @param contractType The type of the collection.
   * @param tokenIds The IDs of the tokens to unstake.
   */
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

  /*
   * @notice Calculates the total reward of a staker.
   * @param staker The address of the staker.
   * @return The total reward of the staker.
   */
  function getTotalRewards(address staker) external view returns (uint256) {
    return stakers[staker].claimedRewards + getUnclaimedRewards(staker);
  }

  /*
   * @notice Gets yields of tokens of a specific collection.
   * @param contractType The type of the collection.
   * @param tokenIds The IDs of the tokens to get the yields of.
   * @return The yields of the tokens provided.
   */
  function getYieldsForTokens(ContractTypes contractType, uint256[] memory tokenIds) external view returns (uint256[] memory) {
    uint256[] memory yields = new uint256[](tokenIds.length);
    for (uint256 i; i < tokenIds.length; i++) {
      yields[i] = getTokenYield(contractType, tokenIds[i]);
    }
    return yields;
  }

  /*
   * @notice Gets called whenever an IERC721 tokenId token is transferred to this contract via IERC721.safeTransferFrom.
   */
  function onERC721Received(
    address,
    address,
    uint256,
    bytes calldata
  ) external pure returns (bytes4) {
    return bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"));
  }

  /**
   * @notice Pauses the deposit process.
   * @param _pause The deposit state value.
   */
  function pauseDeposit(bool _pause) public onlyOwner {
    depositPaused = _pause;
  }

  /**
   * @notice Launches staking.
   */
  function launchStaking() public onlyOwner {
    require(!stakingLaunched, "Staking was enabled");
    stakingLaunched = true;
  }

  /**
   * @notice Allows the owner to withdraw ERC721 in case of an emergency.
   * @param contractType The type of the collection.
   * @param tokenIds The IDs of the tokens to withdraw.
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

  /*
   * @notice Gets a category of a token of a specific collection.
   * @param contractType The type of the collection.
   * @param tokenId The ID of the token to get the category of.
   * @return The category of the token provided.
   */
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

  /*
   * @notice Gets a yield of a token of a specific collection.
   * @param contractType The type of the collection.
   * @param tokenId The ID of the token to get the yield of.
   * @return The yield of the token provided.
   */
  function getTokenYield(ContractTypes contractType, uint256 tokenId) public view returns (uint256) {
    uint8 category = getCategoryOfToken(contractType, tokenId);
    return yieldsPerCategoryPerTokenType[uint(contractType)][category];
  }

  /*
   * @notice Calculates the yields produced by staked boosters.
   * @param userAddress The address of a user to calculate the booster yield for.
   * @return The booster yield produced for the users.
   */
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

  /*
   * @notice Calculates the yields produced by staked boosters.
   * @param userAddress The address of a user to calculate the booster yield for.
   * @return The booster yield produced for the users.
   */
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

  /*
   * @notice Calculates unclaimed reward of a staker.
   * @param staker The address of the staker.
   * @return The unclaimed reward of the staker.
   */
  function getUnclaimedRewards(address staker) public view returns (uint256) {
    if (stakers[staker].lastCheckpoint == 0) {
      return 0;
    }
    return ((block.timestamp - stakers[staker].lastCheckpoint) * getCurrentYield(staker)) / SECONDS_IN_DAY;
  }

  /*
   * @notice Gets tokens of a staker.
   * @param contractType The type of the collection.
   * @param staker The address of the staker.
   * @return The tokens of the staker.
   */
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

  /**
   * @notice Returns the address of a token owner.
   * @param contractType The type of the collection.
   * @param tokenId The token ID to get the owner of.
   * @return The owner address.
   */
  function ownerOf(ContractTypes contractType, uint256 tokenId) public view returns (address) {
    return _ownerOfToken[uint(contractType)][tokenId];
  }

  /*
   * @notice Moves a token to the last position in an array.
   * @param list The array of token IDs.
   * @param tokenId The ID of the token to move.
   * @return The updated array.
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

  /*
   * @notice Transfers the reward to a staker.
   * @param staker The address of the staker.
   */
  function _claimRewards(address staker) internal {
    stakers[staker].claimedRewards += getUnclaimedRewards(staker);
    stakers[staker].lastCheckpoint = block.timestamp;
  }
}