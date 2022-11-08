// SPDX-License-Identifier: MIT

/*

&_--~- ,_                     /""\      ,
{        ",       THE       <>^  L____/|
(  )_ ,{ ,[email protected]       FARM	     `) /`   , /
 |/  {|\{           GAME       \ `---' /
 ""   " "                       `'";\)`
W: https://thefarm.game           _/_Y
T: @The_Farm_Game

 * Howdy folks! Thanks for glancing over our contracts
 * If you're interested in working with us, you can email us at [email protected]
 * Found a broken egg in our contracts? We have a bug bounty program [email protected]
 * Y'all have a nice day

*/

pragma solidity ^0.8.17;

import './interfaces/IEGGToken.sol';
import './interfaces/IFarmAnimals.sol';
import './interfaces/IHenHouse.sol';
import './interfaces/IHenHouseAdvantage.sol';

contract HenHouseCalc {
  // Events
  event InitializedContract(address thisContract);

  // Interfaces
  IEGGToken public eggToken; // ref to the $EGG contract for minting $EGG earnings
  IFarmAnimals public farmAnimalsNFT; // ref to the FarmAnimals NFT contract
  IHenHouseAdvantage public henHouseAdvantage; // ref to HenHouseAdvantage contract
  IHenHouse public henHouse; // ref to Hen House contract

  mapping(address => bool) private controllers; // address => allowedToCallFunctions

  // Hens
  uint256 public constant DAILY_EGG_RATE = 10000 ether; // Hens earn 10000 $EGG per day
  uint256 public constant DAILY_ROOSTER_EGG_RATE = 1000 ether; // Rooster earn 1000 ether per day on guard duty

  // Recource tracking
  uint256 public constant MAXIMUM_GLOBAL_EGG = 2880000000 ether; // there will only ever be (roughly) 2.88 billion $EGG earned through staking

  /** MODIFIERS */

  /**
   * @dev Modifer to require msg.sender to be a controller
   */
  modifier onlyController() {
    _isController();
    _;
  }

  // Optimize for bytecode size
  function _isController() internal view {
    require(controllers[msg.sender], 'Only controllers');
  }

  constructor(
    IEGGToken _eggToken,
    IFarmAnimals _farmAnimalsNFT,
    IHenHouseAdvantage _henHouseAdvantage
  ) {
    eggToken = _eggToken;
    farmAnimalsNFT = _farmAnimalsNFT;
    henHouseAdvantage = _henHouseAdvantage;
    controllers[msg.sender] = true;

    emit InitializedContract(address(this));
  }

  /**
   * ██ ███    ██ ████████
   * ██ ████   ██    ██
   * ██ ██ ██  ██    ██
   * ██ ██  ██ ██    ██
   * ██ ██   ████    ██
   * This section has internal only functions
   */

  /** ACCOUNTING */

  /** READ ONLY */

  /**
   * @notice Get token kind (chicken, coyote, rooster)
   * @param tokenId the ID of the token to check
   * @return kind
   */
  function _getKind(uint256 tokenId) internal view returns (IFarmAnimals.Kind) {
    return farmAnimalsNFT.getTokenTraits(tokenId).kind;
  }

  /**
   * @notice Gets the rank score for a Coyote
   * @param tokenId the ID of the Coyote to get the rank score for
   * @return the rank score of the Coyote & Rooster(5-8)
   */
  function _rankForCoyoteRooster(uint256 tokenId) internal view returns (uint8) {
    IFarmAnimals.Traits memory s = farmAnimalsNFT.getTokenTraits(tokenId);
    return uint8(s.advantage + 1); // rank index is 0-5
  }

  /**
    @notice Get claim earning amount by tokenId
    @param tokenId the ID of the token to claim earnings from
   */
  function _calcDailyEggRateOfHen(uint256 tokenId) internal view returns (uint256) {
    IFarmAnimals.Traits memory s = farmAnimalsNFT.getTokenTraits(tokenId);
    return (s.advantage * 1000 ether + DAILY_EGG_RATE);
  }

  /**
    @notice Get claim earning amount by tokenId
    @param tokenId the ID of the token to claim earnings from
   */
  function _calcDailyEggRateOfRooster(uint256 tokenId) internal view returns (uint256) {
    IFarmAnimals.Traits memory s = farmAnimalsNFT.getTokenTraits(tokenId);
    return (s.advantage * 100 ether + DAILY_ROOSTER_EGG_RATE);
  }

  /**
   * @notice Calculate Reward $EGG owed to a Hen by tokenID
   * @dev External function
   * @param tokenId the ID of the staked Hen to calculate $EGG reward amount
   * @return owed - the $EGG amount earned
   */

  function calculateRewardsHen(uint256 tokenId, IHenHouse.Stake memory stake)
    external
    view
    onlyController
    returns (uint256 owed)
  {
    owed = _calculateRewardsHen(tokenId, stake);
  }

  /**
   * @notice Calculate Reward $EGG owed to a Hen by tokenID
   * @dev Internal function
   * @param tokenId the ID of the staked Hen to calculate $EGG reward amount
   * @return owed - the $EGG amount earned
   */

  function _calculateRewardsHen(uint256 tokenId, IHenHouse.Stake memory stake) internal view returns (uint256 owed) {
    /**
     * Hen: Daily yeild
     * Hen: Advantage applied to yeild
     * Hen: Pay Tax
     */
    require(stake.owner == tx.origin, 'Caller not owner');
    IHenHouse.HenHouseInfo memory henHouseInfo = henHouse.getHenHouseInfo();
    IHenHouse.GuardHouseInfo memory guardHouseInfo = henHouse.getGuardHouseInfo();
    uint256 globalEgg = henHouseInfo.totalEGGEarnedByHen + guardHouseInfo.totalEGGEarnedByRooster;

    if (globalEgg < MAXIMUM_GLOBAL_EGG) {
      owed = ((block.timestamp - stake.stakedTimestamp) * _calcDailyEggRateOfHen(tokenId)) / 1 days;
    } else if (stake.stakedTimestamp > henHouseInfo.lastClaimTimestampByHen) {
      owed = 0; // $EGG production stopped already
    } else {
      owed =
        ((henHouseInfo.lastClaimTimestampByHen - stake.stakedTimestamp) * _calcDailyEggRateOfHen(tokenId)) /
        1 days; // stop earning additional $EGG if it's all been earned
    }
    owed = henHouseAdvantage.calculateAdvantageBonus(tokenId, owed);
  }

  /**
   * @notice Calculate Reward $EGG owed to a Hen by tokenID
   * @dev External function
   * @param tokenId the ID of the staked Hen to calculate $EGG reward amount
   * @return owed - the $EGG amount earned
   */

  function calculateRewardsCoyote(uint256 tokenId, uint8 rank) external view onlyController returns (uint256 owed) {
    owed = _calculateRewardsCoyote(tokenId, rank);
  }

  /**
   * @notice Calculate Reward $EGG owed to a Coyote by tokenID
   * @dev Internal function
   * @param tokenId the ID of the staked Coyote to calculate $EGG reward amount
   * @return owed - the $EGG amount earned
   */

  function _calculateRewardsCoyote(uint256 tokenId, uint8 rank) internal view returns (uint256 owed) {
    /**
     * Coyote: Tax yeild
     * Coyote: Advantage applied to yeild
     */

    IHenHouse.Stake memory stake = henHouse.getStakeInfo(tokenId);
    require(stake.owner == tx.origin, 'Caller not owner');
    IHenHouse.DenInfo memory denInfo = henHouse.getDenInfo();
    owed = (rank) * (denInfo.eggPerCoyoteRank - stake.eggPerRank); // Calculate portion of tokens based on Rank
    owed = henHouseAdvantage.calculateAdvantageBonus(tokenId, owed);
  }

  /**
   * @notice Calculate Reward $EGG owed to a Hen by tokenID
   * @dev External function
   * @param tokenId the ID of the staked Hen to calculate $EGG reward amount
   * @return owed - the $EGG amount earned
   */

  function calculateRewardsRooster(
    uint256 tokenId,
    uint8 rank,
    IHenHouse.Stake memory stake
  ) external view onlyController returns (uint256 owed) {
    owed = _calculateRewardsRooster(tokenId, rank, stake);
  }

  /**
   * @notice Calculate Reward $EGG owed to a Rooster by tokenID
   * @dev Internal function
   * @param tokenId the ID of the staked Rooster to calculate $EGG reward amount
   * @return owed - the $EGG amount earned
   */

  function _calculateRewardsRooster(
    uint256 tokenId,
    uint8 rank,
    IHenHouse.Stake memory stake
  ) internal view returns (uint256 owed) {
    /**
     * Rooster: Daily yeild
     * Rooster: Advantage applied to yeild
     * Rooster: One Off Egg
     * Rooster: Rescue Pool
     * Rooster: Risk pay Coyote
     */
    require(stake.owner == tx.origin, 'Caller not owner');
    IHenHouse.HenHouseInfo memory henHouseInfo = henHouse.getHenHouseInfo();
    IHenHouse.GuardHouseInfo memory guardHouseInfo = henHouse.getGuardHouseInfo();
    uint256 globalEgg = henHouseInfo.totalEGGEarnedByHen + guardHouseInfo.totalEGGEarnedByRooster;
    owed = (rank) * (guardHouseInfo.eggPerRoosterRank - stake.eggPerRank); // Calculate portion of daily EGG tokens based on Rank

    if (globalEgg < MAXIMUM_GLOBAL_EGG) {
      owed += ((block.timestamp - stake.stakedTimestamp) * (_calcDailyEggRateOfRooster(tokenId))) / 1 days;
    } else if (stake.stakedTimestamp > guardHouseInfo.lastClaimTimestampByRooster) {
      owed += 0; // $EGG production stopped already
    } else {
      owed +=
        ((guardHouseInfo.lastClaimTimestampByRooster - stake.stakedTimestamp) * _calcDailyEggRateOfRooster(tokenId)) /
        1 days; // stop earning additional $EGG if it's all been earned
    }
    owed = henHouseAdvantage.calculateAdvantageBonus(tokenId, owed);
    owed += stake.oneOffEgg;
    owed += (rank) * (guardHouseInfo.rescueEggPerRank - stake.rescueEggPerRank); // Calculate portion of rescued EGG tokens based on Rank
  }

  /**
   * @notice Calculate Reward $EGG token amount of token Id
   * @dev Internal function
   * @param tokenId the ID of the staked NFT to calculate $EGG reward amount
   * @return owed - the $EGG amount earned
   */

  function _calculateRewards(uint256 tokenId) internal view returns (uint256 owed) {
    IFarmAnimals.Kind kind = _getKind(tokenId);
    if (kind == IFarmAnimals.Kind.HEN) {
      IHenHouse.Stake memory stake = henHouse.getStakeInfo(tokenId);
      owed = _calculateRewardsHen(tokenId, stake);
    } else if (kind == IFarmAnimals.Kind.COYOTE) {
      uint8 rank = _rankForCoyoteRooster(tokenId);
      owed = _calculateRewardsCoyote(tokenId, rank);
    } else if (kind == IFarmAnimals.Kind.ROOSTER) {
      uint8 rank = _rankForCoyoteRooster(tokenId);
      IHenHouse.Stake memory stake = henHouse.getStakeInfo(tokenId);
      owed = _calculateRewardsRooster(tokenId, rank, stake);
    }
  }

  /**
   * ███████ ██   ██ ████████
   * ██       ██ ██     ██
   * █████     ███      ██
   * ██       ██ ██     ██
   * ███████ ██   ██    ██
   * This section has external functions
   */

  /** STAKING */

  /**
   * @notice Calculate Reward $EGG token amount of token Id
   * @param tokenId the ID of the NFT to calculate $EGG reward amount
   * @return owed - the $EGG amount earned
   */

  function calculateRewards(uint256 tokenId) external view returns (uint256 owed) {
    owed = _calculateRewards(tokenId);
  }

  /**
   * @notice Calculate Reward $EGG token amount of token Id
   * @param tokenIds Array of the token IDs of the NFT to calculate $EGG reward amount
   * @return owed - the $EGG amount earned
   */

  function calculateAllRewards(uint256[] calldata tokenIds) external view returns (uint256 owed) {
    uint256 tokenId;
    for (uint256 i = 0; i < tokenIds.length; i++) {
      tokenId = tokenIds[i];
      owed = owed + (_calculateRewards(tokenId));
    }
  }

  /**
   *  ██████  ██████  ███    ██ ████████ ██████   ██████  ██      ██      ███████ ██████
   * ██      ██    ██ ████   ██    ██    ██   ██ ██    ██ ██      ██      ██      ██   ██
   * ██      ██    ██ ██ ██  ██    ██    ██████  ██    ██ ██      ██      █████   ██████
   * ██      ██    ██ ██  ██ ██    ██    ██   ██ ██    ██ ██      ██      ██      ██   ██
   *  ██████  ██████  ██   ████    ██    ██   ██  ██████  ███████ ███████ ███████ ██   ██
   * This section if for controllers (possibly Owner) only functions
   */

  /**
   * @notice Internal call to enable an address to call controller only functions
   * @param _address the address to enable
   */
  function _addController(address _address) internal {
    controllers[_address] = true;
  }

  /**
   * @notice enables multiple addresses to call controller only functions
   * @dev Only callable by an existing controller
   * @param _addresses array of the address to enable
   */
  function addManyControllers(address[] memory _addresses) external onlyController {
    for (uint256 i = 0; i < _addresses.length; i++) {
      _addController(_addresses[i]);
    }
  }

  /**
   * @notice removes an address from controller list and ability to call controller only functions
   * @dev Only callable by an existing controller
   * @param _address the address to disable
   */
  function removeController(address _address) external onlyController {
    controllers[_address] = false;
  }

  /**
   * @notice Set multiple contract addresses
   * @dev Only callable by an existing controller
   * @param _eggToken Address of eggToken contract
   * @param _farmAnimalsNFT Address of farmAnimals contract
   * @param _henHouseAdvantage Address of henHouseAdvantage contract
   * @param _henHouse Address of henHouse contract
   */

  function setExtContracts(
    address _eggToken,
    address _farmAnimalsNFT,
    address _henHouseAdvantage,
    address _henHouse
  ) external onlyController {
    eggToken = IEGGToken(_eggToken);
    farmAnimalsNFT = IFarmAnimals(_farmAnimalsNFT);
    henHouseAdvantage = IHenHouseAdvantage(_henHouseAdvantage);
    henHouse = IHenHouse(_henHouse);
  }

  /**
   * @notice Set the henHouseAdvantage contract address.
   * @dev Only callable by the owner.
   */
  function setHenHouseAdvantage(address _henHouseAdvantage) external onlyController {
    henHouseAdvantage = IHenHouseAdvantage(_henHouseAdvantage);
  }

  /**
   * @notice Set the henHouse contract address.
   * @dev Only callable by the owner.
   */
  function setHenHouse(address _henHouse) external onlyController {
    henHouse = IHenHouse(_henHouse);
  }
}

// SPDX-License-Identifier: MIT

/*

&_--~- ,_                     /""\      ,
{        ",       THE       <>^  L____/|
(  )_ ,{ ,[email protected]       FARM	     `) /`   , /
 |/  {|\{           GAME       \ `---' /
 ""   " "                       `'";\)`
W: https://thefarm.game           _/_Y
T: @The_Farm_Game

 * Howdy folks! Thanks for glancing over our contracts
 * If you're interested in working with us, you can email us at [email protected]
 * Found a broken egg in our contracts? We have a bug bounty program [email protected]
 * Y'all have a nice day

*/

pragma solidity ^0.8.17;

interface IEGGToken {
  function balanceOf(address account) external view returns (uint256);

  function mint(address to, uint256 amount) external;

  function burn(address from, uint256 amount) external;

  function transferFrom(
    address sender,
    address recipient,
    uint256 amount
  ) external returns (bool);

  function addLiquidityETH(uint256 tokenAmount, uint256 ethAmount)
    external
    payable
    returns (
      uint256 amountToken,
      uint256 amountETH,
      uint256 liquidity
    );
}

// SPDX-License-Identifier: MIT

/*

&_--~- ,_                     /""\      ,
{        ",       THE       <>^  L____/|
(  )_ ,{ ,[email protected]       FARM	     `) /`   , /
 |/  {|\{           GAME       \ `---' /
 ""   " "                       `'";\)`
W: https://thefarm.game           _/_Y
T: @The_Farm_Game

 * Howdy folks! Thanks for glancing over our contracts
 * If you're interested in working with us, you can email us at [email protected]
 * Found a broken egg in our contracts? We have a bug bounty program [email protected]
 * Y'all have a nice day

*/

pragma solidity ^0.8.13;

import 'erc721a/contracts/extensions/IERC721AQueryable.sol';

interface IFarmAnimals is IERC721AQueryable {
  // Kind of Character
  enum Kind {
    HEN,
    COYOTE,
    ROOSTER
  }

  // NFT Traits
  struct Traits {
    Kind kind;
    uint8 advantage;
    uint8[8] traits;
  }

  function burn(uint256 tokenId) external;

  function maxGen0Supply() external view returns (uint256);

  function maxSupply() external view returns (uint256);

  function getTokenTraits(uint256 tokenId) external view returns (Traits memory);

  function mintSeeds(address recipient, uint256[] calldata seeds) external;

  function mintTwins(
    uint256 seed,
    address recipient1,
    address recipient2
  ) external;

  function minted() external view returns (uint256);

  function mintedRoosters() external returns (uint256);

  function pickKind(uint256 seed, uint16 specificKind) external view returns (Kind k);

  function specialMint(
    address recipient,
    uint256 seed,
    uint16 specificKind,
    bool twinHen,
    uint16 quantity
  ) external;

  function updateAdvantage(
    uint256 tokenId,
    uint8 score,
    bool decrement
  ) external;
}

// SPDX-License-Identifier: MIT

/*

&_--~- ,_                     /""\      ,
{        ",       THE       <>^  L____/|
(  )_ ,{ ,[email protected]       FARM	     `) /`   , /
 |/  {|\{           GAME       \ `---' /
 ""   " "                       `'";\)`
W: https://thefarm.game           _/_Y
T: @The_Farm_Game

 * Howdy folks! Thanks for glancing over our contracts
 * If you're interested in working with us, you can email us at [email protected]
 * Found a broken egg in our contracts? We have a bug bounty program [email protected]
 * Y'all have a nice day

*/

pragma solidity ^0.8.17;

interface IHenHouse {
  // struct to store a stake's token, owner, and earning values
  struct Stake {
    uint16 tokenId;
    address owner;
    uint80 eggPerRank; // This is the value of EggPerRank (Coyote/Rooster)
    uint80 rescueEggPerRank; // Value per rank of rescued $EGG
    uint256 oneOffEgg; // One off per staker
    uint256 stakedTimestamp;
    uint256 unstakeTimestamp;
  }

  struct HenHouseInfo {
    uint256 numHensStaked; // Track staked hens
    uint256 totalEGGEarnedByHen; // Amount of $EGG earned so far
    uint256 lastClaimTimestampByHen; // The last time $EGG was claimed
  }

  struct DenInfo {
    uint256 numCoyotesStaked;
    uint256 totalCoyoteRankStaked;
    uint256 eggPerCoyoteRank; // Amount of tax $EGG due per Wily rank point staked
  }

  struct GuardHouseInfo {
    uint256 numRoostersStaked;
    uint256 totalRoosterRankStaked;
    uint256 totalEGGEarnedByRooster;
    uint256 lastClaimTimestampByRooster;
    uint256 eggPerRoosterRank; // Amount of dialy $EGG due per Guard rank point staked
    uint256 rescueEggPerRank; // Amunt of rescued $EGG due per Guard rank staked
  }

  function addManyToHenHouse(address account, uint16[] calldata tokenIds) external;

  function addGenericEggPool(uint256 _amount) external;

  function addRescuedEggPool(uint256 _amount) external;

  function canUnstake(uint16 tokenId) external view returns (bool);

  function claimManyFromHenHouseAndDen(uint16[] calldata tokenIds, bool unstake) external;

  function getDenInfo() external view returns (DenInfo memory);

  function getGuardHouseInfo() external view returns (GuardHouseInfo memory);

  function getHenHouseInfo() external view returns (HenHouseInfo memory);

  function getStakeInfo(uint256 tokenId) external view returns (Stake memory);

  function randomCoyoteOwner(uint256 seed) external view returns (address);

  function randomRoosterOwner(uint256 seed) external view returns (address);

  function rescue(uint16[] calldata tokenIds) external;
}

// SPDX-License-Identifier: MIT

/*

&_--~- ,_                     /""\      ,
{        ",       THE       <>^  L____/|
(  )_ ,{ ,[email protected]       FARM	     `) /`   , /
 |/  {|\{           GAME       \ `---' /
 ""   " "                       `'";\)`
W: https://thefarm.game           _/_Y
T: @The_Farm_Game

 * Howdy folks! Thanks for glancing over our contracts
 * If you're interested in working with us, you can email us at [email protected]
 * Found a broken egg in our contracts? We have a bug bounty program [email protected]
 * Y'all have a nice day

*/

pragma solidity ^0.8.17;

interface IHenHouseAdvantage {
  // struct to store the production bonus info of all nfts
  struct AdvantageBonus {
    uint256 tokenId;
    uint256 bonusPercentage;
    uint256 bonusDurationMins;
    uint256 startTime;
  }

  function addAdvantageBonus(
    uint256 tokenId,
    uint256 _durationMins,
    uint256 _percentage
  ) external;

  function removeAdvantageBonus(uint256 tokenId) external;

  function getAdvantageBonus(uint256 tokenId) external view returns (AdvantageBonus memory);

  function updateAdvantageBonus(uint256 tokenId) external;

  function calculateAdvantageBonus(uint256 tokenId, uint256 owed) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// ERC721A Contracts v4.2.3
// Creator: Chiru Labs

pragma solidity ^0.8.4;

/**
 * @dev Interface of ERC721A.
 */
interface IERC721A {
    /**
     * The caller must own the token or be an approved operator.
     */
    error ApprovalCallerNotOwnerNorApproved();

    /**
     * The token does not exist.
     */
    error ApprovalQueryForNonexistentToken();

    /**
     * Cannot query the balance for the zero address.
     */
    error BalanceQueryForZeroAddress();

    /**
     * Cannot mint to the zero address.
     */
    error MintToZeroAddress();

    /**
     * The quantity of tokens minted must be more than zero.
     */
    error MintZeroQuantity();

    /**
     * The token does not exist.
     */
    error OwnerQueryForNonexistentToken();

    /**
     * The caller must own the token or be an approved operator.
     */
    error TransferCallerNotOwnerNorApproved();

    /**
     * The token must be owned by `from`.
     */
    error TransferFromIncorrectOwner();

    /**
     * Cannot safely transfer to a contract that does not implement the
     * ERC721Receiver interface.
     */
    error TransferToNonERC721ReceiverImplementer();

    /**
     * Cannot transfer to the zero address.
     */
    error TransferToZeroAddress();

    /**
     * The token does not exist.
     */
    error URIQueryForNonexistentToken();

    /**
     * The `quantity` minted with ERC2309 exceeds the safety limit.
     */
    error MintERC2309QuantityExceedsLimit();

    /**
     * The `extraData` cannot be set on an unintialized ownership slot.
     */
    error OwnershipNotInitializedForExtraData();

    // =============================================================
    //                            STRUCTS
    // =============================================================

    struct TokenOwnership {
        // The address of the owner.
        address addr;
        // Stores the start time of ownership with minimal overhead for tokenomics.
        uint64 startTimestamp;
        // Whether the token has been burned.
        bool burned;
        // Arbitrary data similar to `startTimestamp` that can be set via {_extraData}.
        uint24 extraData;
    }

    // =============================================================
    //                         TOKEN COUNTERS
    // =============================================================

    /**
     * @dev Returns the total number of tokens in existence.
     * Burned tokens will reduce the count.
     * To get the total number of tokens minted, please see {_totalMinted}.
     */
    function totalSupply() external view returns (uint256);

    // =============================================================
    //                            IERC165
    // =============================================================

    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * [EIP section](https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified)
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);

    // =============================================================
    //                            IERC721
    // =============================================================

    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables
     * (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in `owner`'s account.
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
     * @dev Safely transfers `tokenId` token from `from` to `to`,
     * checking first that contract recipients are aware of the ERC721 protocol
     * to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move
     * this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement
     * {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external payable;

    /**
     * @dev Equivalent to `safeTransferFrom(from, to, tokenId, '')`.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external payable;

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom}
     * whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token
     * by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external payable;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the
     * zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external payable;

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom}
     * for any token owned by the caller.
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
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    // =============================================================
    //                        IERC721Metadata
    // =============================================================

    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);

    // =============================================================
    //                           IERC2309
    // =============================================================

    /**
     * @dev Emitted when tokens in `fromTokenId` to `toTokenId`
     * (inclusive) is transferred from `from` to `to`, as defined in the
     * [ERC2309](https://eips.ethereum.org/EIPS/eip-2309) standard.
     *
     * See {_mintERC2309} for more details.
     */
    event ConsecutiveTransfer(uint256 indexed fromTokenId, uint256 toTokenId, address indexed from, address indexed to);
}

// SPDX-License-Identifier: MIT
// ERC721A Contracts v4.2.3
// Creator: Chiru Labs

pragma solidity ^0.8.4;

import '../IERC721A.sol';

/**
 * @dev Interface of ERC721AQueryable.
 */
interface IERC721AQueryable is IERC721A {
    /**
     * Invalid query range (`start` >= `stop`).
     */
    error InvalidQueryRange();

    /**
     * @dev Returns the `TokenOwnership` struct at `tokenId` without reverting.
     *
     * If the `tokenId` is out of bounds:
     *
     * - `addr = address(0)`
     * - `startTimestamp = 0`
     * - `burned = false`
     * - `extraData = 0`
     *
     * If the `tokenId` is burned:
     *
     * - `addr = <Address of owner before token was burned>`
     * - `startTimestamp = <Timestamp when token was burned>`
     * - `burned = true`
     * - `extraData = <Extra data when token was burned>`
     *
     * Otherwise:
     *
     * - `addr = <Address of owner>`
     * - `startTimestamp = <Timestamp of start of ownership>`
     * - `burned = false`
     * - `extraData = <Extra data at start of ownership>`
     */
    function explicitOwnershipOf(uint256 tokenId) external view returns (TokenOwnership memory);

    /**
     * @dev Returns an array of `TokenOwnership` structs at `tokenIds` in order.
     * See {ERC721AQueryable-explicitOwnershipOf}
     */
    function explicitOwnershipsOf(uint256[] memory tokenIds) external view returns (TokenOwnership[] memory);

    /**
     * @dev Returns an array of token IDs owned by `owner`,
     * in the range [`start`, `stop`)
     * (i.e. `start <= tokenId < stop`).
     *
     * This function allows for tokens to be queried if the collection
     * grows too big for a single call of {ERC721AQueryable-tokensOfOwner}.
     *
     * Requirements:
     *
     * - `start < stop`
     */
    function tokensOfOwnerIn(
        address owner,
        uint256 start,
        uint256 stop
    ) external view returns (uint256[] memory);

    /**
     * @dev Returns an array of token IDs owned by `owner`.
     *
     * This function scans the ownership mapping and is O(`totalSupply`) in complexity.
     * It is meant to be called off-chain.
     *
     * See {ERC721AQueryable-tokensOfOwnerIn} for splitting the scan into
     * multiple smaller scans if the collection is large enough to cause
     * an out-of-gas error (10K collections should be fine).
     */
    function tokensOfOwner(address owner) external view returns (uint256[] memory);
}