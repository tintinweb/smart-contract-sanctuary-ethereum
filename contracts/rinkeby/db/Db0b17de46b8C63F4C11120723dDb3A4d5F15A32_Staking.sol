// SPDX-License-Identifier: MIT
/* solhint-disable not-rely-on-time */

pragma solidity ^0.8.13;

import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol";
import "@openzeppelin/contracts/utils/math/SafeCast.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/math/SignedSafeMath.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

import "./interfaces/IStakable.sol";
import "./interfaces/ICoin.sol";

/**
 * @title NFT Staking
 * Distribute ERC20 rewards over discrete-time schedules for the staking of NFTs.
 * This contract is designed on a self-service model, where users will stake NFTs, unstake NFTs and claim rewards through their own transactions only.
 */
contract Staking is ERC165, Pausable, AccessControl, IERC721Receiver, IERC1155Receiver {
  using SafeCast for uint256;
  using SafeMath for uint256;
  using SignedSafeMath for int256;

  event Started();
  event Disabled();
  event OwnershipChanged(address from, address to, address nft, uint256 tokenId);
  event RewardsAdded(uint256 startPeriod, uint256 endPeriod, uint256 rewardsPerCycle);
  event RewardsClaimed(address staker, uint256 cycle, uint256 startPeriod, uint256 periods, uint256 amount);
  event NftStaked(address staker, uint256 cycle, address nft, uint256 tokenId, uint256 weight);
  event NftUnstaked(address staker, uint256 cycle, address nft, uint256 tokenId, uint256 weight);
  event NftsBatchStaked(address staker, uint256 cycle, address nft, uint256[] tokenIds, uint256[] weights);
  event NftsBatchUnstaked(address staker, uint256 cycle, address nft, uint256[] tokenIds, uint256[] weights);
  event HistoriesUpdated(address staker, uint256 startCycle, uint256 stakerStake, uint256 globalStake);

  /**
   * Used as a historical record of change of stake.
   * Stake represents an aggregation of staked token weights.
   * Optimised for use in storage.
   */
  struct Snapshot {
    uint128 stake;
    uint128 startCycle;
  }

  /**
   * Used to represent a staker's information about the next claim.
   * Optimised for use in storage.
   */
  struct NextClaim {
    uint16 period;
    uint64 globalSnapshotIndex;
    uint64 stakerSnapshotIndex;
  }

  /**
   * Used as a container to hold result values from computing rewards.
   */
  struct ComputedClaim {
    uint16 startPeriod;
    uint16 periods;
    uint256 amount;
  }

  /**
   * Used to represent the current staking status of an NFT.
   * Optimised for use in storage.
   */
  struct TokenInfo {
    address owner;
    uint128 weight;
    uint256 amount;
    uint16 depositCycle;
    uint16 withdrawCycle;
  }

  /**
   * The ERC1155-compliant (optional ERC721-compliance) contract from which staking is accepted.
   */
  struct ContractStaking {
    IStakable nft;
    mapping(uint256 => TokenInfo) tokens;
    bool enabled;
  }

  uint256 public totalRewardsPool;

  uint256 public startTimestamp;

  IDistributor public coin;

  uint32 public immutable cycleLengthInSeconds;
  uint16 public immutable periodLengthInCycles;

  Snapshot[] public globalHistory;

  /* staker => snapshots*/
  mapping(address => Snapshot[]) public stakerHistories;

  /* staker => next claim */
  mapping(address => NextClaim) public nextClaims;

  /* period => rewardsPerCycle */
  mapping(uint256 => uint256) public rewardsSchedule;

  /* lost cycle => withdrawn? */
  mapping(uint256 => bool) public withdrawnLostCycles;

  /* staking => hold info on staking */
  mapping(address => ContractStaking) public stakingContracts;

  modifier hasStarted() {
    require(startTimestamp != 0, "staking not started");
    _;
  }

  modifier hasNotStarted() {
    require(startTimestamp == 0, "staking has started");
    _;
  }

  bytes32 public constant ADMIN = keccak256("ADMIN");

  bytes32 public constant REWARDER = keccak256("REWARDER");

  bytes32 public constant SLUSHER = keccak256("SLUSHER");

  /**
   * Constructor.
   * @dev Reverts if the period length value is zero.
   * @dev Reverts if the cycle length value is zero.
   * @dev Warning: cycles and periods need to be calibrated carefully. Small values will increase computation load while estimating and claiming rewards. Big values will increase the time to wait before a new period becomes claimable.
   * @param _cycleLengthInSeconds The length of a cycle, in seconds.
   * @param _periodLengthInCycles The length of a period, in cycles.
   * @param _coin The ERC20-based token used as staking rewards.
   */
  constructor(
    uint32 _cycleLengthInSeconds,
    uint16 _periodLengthInCycles,
    address _coin
  ) {
    require(_cycleLengthInSeconds >= 1 minutes, "invalid cycle length");
    require(_periodLengthInCycles >= 2, "invalid period length");

    _setRoleAdmin(REWARDER, ADMIN);
    _setRoleAdmin(SLUSHER, ADMIN);

    _setupRole(ADMIN, _msgSender());
    _setupRole(SLUSHER, _msgSender());

    cycleLengthInSeconds = _cycleLengthInSeconds;
    periodLengthInCycles = _periodLengthInCycles;

    setCoinContract(_coin);
  }

  /**
   * @dev Will pause the contract.
   */
  function pause() public onlyRole(ADMIN) {
    _pause();
  }

  /**
   * @dev Will unpause the contract.
   */
  function unpause() public onlyRole(ADMIN) {
    _unpause();
  }

  /**
   * @dev will set the coin contract
   */
  function setCoinContract(address _coin) public onlyRole(ADMIN) {
    require(_coin != address(0), "invalid address");
    coin = ICoin(_coin);
  }

  /**
   * Starts the first cycle of staking, enabling users to stake NFTs.
   * @dev Reverts if not called by the owner.
   * @dev Reverts if the staking has already started.
   * @dev Emits a Started event.
   */
  function start() public onlyRole(ADMIN) hasNotStarted {
    startTimestamp = block.timestamp;
    emit Started();
  }

  /**
   * Adds `rewardsPerCycle` reward amount for the period range from `startPeriod` to `endPeriod`, inclusive, to the rewards schedule.
   * The necessary amount of reward tokens is transferred to the contract. Cannot be used for past periods.
   * Can only be used to add rewards and not to remove them.
   * @dev Reverts if not called by the owner.
   * @dev Reverts if the start period is zero.
   * @dev Reverts if the end period precedes the start period.
   * @dev Reverts if attempting to add rewards for a period earlier than the current, after staking has started.
   * @dev Reverts if the reward tokens transfer fails.
   * @dev The rewards token contract emits an ERC20 Transfer event for the reward tokens transfer.
   * @dev Emits a RewardsAdded event.
   * @param startPeriod The starting period (inclusive).
   * @param endPeriod The ending period (inclusive).
   * @param rewardsPerCycle The reward amount to add for each cycle within range.
   */
  function addRewardsForPeriods(
    uint16 startPeriod,
    uint16 endPeriod,
    uint256 rewardsPerCycle
  ) public onlyRole(REWARDER) {
    require(startPeriod != 0 && startPeriod <= endPeriod, "wrong period range");

    if (startTimestamp != 0) {
      // solhint-disable-next-line
      require(startPeriod >= _getCurrentPeriod(periodLengthInCycles), "already committed reward schedule");
    }

    for (uint256 period = startPeriod; period <= endPeriod; ++period) {
      rewardsSchedule[period] = rewardsSchedule[period].add(rewardsPerCycle);
    }

    uint256 addedRewards = rewardsPerCycle.mul(periodLengthInCycles).mul(endPeriod - startPeriod + 1);
    totalRewardsPool = totalRewardsPool.add(addedRewards);

    emit RewardsAdded(startPeriod, endPeriod, rewardsPerCycle);
  }

  /**
   * Will enable contract and staking for give contract
   */
  function addContract(address nft) public onlyRole(ADMIN) {
    stakingContracts[nft].nft = IStakable(nft);
    stakingContracts[nft].enabled = true;
  }

  /**
   * Will enable contract and staking for give contract
   */
  function removeContract(address nft) public onlyRole(ADMIN) {
    stakingContracts[nft].enabled = false;
  }

  /**
   * I would almost consider this being case of absuing
   * ownership. But this will be handout to the community via DAO.
   */
  function transferTokenOwnership(
    address nft,
    uint256 tokenId,
    address _owner
  ) public onlyRole(ADMIN) {
    ContractStaking storage staker = stakingContracts[nft];
    TokenInfo storage tokenInfo = staker.tokens[tokenId];
    require(tokenInfo.owner == address(0), "do not own this token");
    emit OwnershipChanged(tokenInfo.owner, _owner, nft, tokenId);
    tokenInfo.owner = _owner;
  }

  /**
   * This would transfer token owner by contract
   */
  function transferToken(
    address nft,
    uint256 tokenId,
    address recipient
  ) public onlyRole(ADMIN) {
    ContractStaking storage staker = stakingContracts[nft];
    TokenInfo storage tokenInfo = staker.tokens[tokenId];
    require(tokenInfo.owner == address(this), "do not own this token");
    staker.nft.safeTransferFrom(address(this), recipient, tokenId, tokenInfo.amount, "");
  }

  /**
   * I would almost consider this being case of absuing
   * ownership. But this will be handout to the community via DAO.
   * mainpurpose of slushing will be to pnush cheaters.
   */
  function slush(address nft, uint256 tokenId) public onlyRole(SLUSHER) {
    transferTokenOwnership(nft, tokenId, address(this));
  }

  /**
   * ERC1155Receiver hook for single transfer.
   * @dev Reverts if the caller is not the whitelisted NFT contract.
   */
  function onERC1155Received(
    address, /*operator*/
    address from,
    uint256 id,
    uint256 amount,
    bytes calldata /*data*/
  ) external returns (bytes4) {
    _stake(id, from, amount);
    return this.onERC1155Received.selector;
  }

  /**
   * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
   * by `operator` from `from`, this function is called.
   *
   * It must return its Solidity selector to confirm the token transfer.
   * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
   *
   * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
   */
  function onERC721Received(
    address, /*operator*/
    address from,
    uint256 id,
    bytes calldata /*data*/
  ) external returns (bytes4) {
    _stake(id, from, 1);
    return this.onERC721Received.selector;
  }

  /**
   * ERC1155Receiver hook for batch transfer.
   * @dev Reverts if the caller is not the whitelisted NFT contract.
   */
  function onERC1155BatchReceived(
    address, /*operator*/
    address from,
    uint256[] calldata ids,
    uint256[] calldata amounts,
    bytes calldata /*data*/
  ) external returns (bytes4) {
    _batchStake(ids, from, amounts);
    return this.onERC1155BatchReceived.selector;
  }

  /**
   * Stakes the NFT received by the contract for its owner. The NFT's weight will count for the current cycle.
   * @dev Reverts if `tokenId` is still on cooldown.
   * @dev Emits an HistoriesUpdated event.
   * @dev Emits an NftStaked event.
   * @param tokenId Identifier of the staked NFT.
   * @param owner Owner of the staked NFT.
   */
  function _stake(
    uint256 tokenId,
    address owner,
    uint256 amount
  ) internal whenNotPaused hasStarted {
    ContractStaking storage staker = stakingContracts[_msgSender()];
    require(staker.enabled, "contract not enabled");

    uint16 periodLengthInCycles_ = periodLengthInCycles;
    uint16 currentCycle = _getCycle(block.timestamp);
    uint128 weight = uint128(staker.nft.getStakingWeight(tokenId) * amount);

    _updateHistories(owner, int128(weight), currentCycle);

    // initialise the next claim if it was the first stake for this staker or if
    // the next claim was re-initialised (ie. rewards were claimed until the last
    // staker snapshot and the last staker snapshot has no stake)
    if (nextClaims[owner].period == 0) {
      uint16 currentPeriod = _getPeriod(currentCycle, periodLengthInCycles_);
      nextClaims[owner] = NextClaim(currentPeriod, uint64(globalHistory.length - 1), 0);
    }

    uint16 withdrawCycle = staker.tokens[tokenId].withdrawCycle;
    require(currentCycle != withdrawCycle, "unstaked token cooldown");

    // set the staked token's info
    staker.tokens[tokenId] = TokenInfo(owner, weight, amount, currentCycle, 0);

    emit NftStaked(owner, currentCycle, address(staker.nft), tokenId, weight);
  }

  /**
   * Stakes the NFT received by the contract for its owner. The NFT's weight will count for the current cycle.
   * @dev Reverts if `tokenIds` is empty.
   * @dev Reverts if one of `tokenIds` is still on cooldown.
   * @dev Emits an HistoriesUpdated event.
   * @dev Emits an NftStaked event.
   * @param tokenIds Identifiers of the staked NFTs.
   * @param owner Owner of the staked NFTs.
   */
  function _batchStake(
    uint256[] memory tokenIds,
    address owner,
    uint256[] memory amounts
  ) internal whenNotPaused hasStarted {
    ContractStaking storage staker = stakingContracts[_msgSender()];
    require(staker.enabled, "contract not enabled");

    uint256 numTokens = tokenIds.length;
    require(numTokens != 0, "no tokens");

    uint16 currentCycle = _getCycle(block.timestamp);
    uint128 totalStakedWeight = 0;
    uint256[] memory weights = new uint256[](numTokens);

    for (uint256 index = 0; index < numTokens; ++index) {
      uint256 tokenId = tokenIds[index];
      uint256 amount = amounts[index];
      require(currentCycle != staker.tokens[tokenId].withdrawCycle, "unstaked token cooldown");
      uint128 weight = uint128(staker.nft.getStakingWeight(tokenId) * amount);
      totalStakedWeight += weight; // This is safe
      weights[index] = weight;
      staker.tokens[tokenId] = TokenInfo(owner, weight, amount, currentCycle, 0);
    }

    _updateHistories(owner, int128(totalStakedWeight), currentCycle);

    // initialise the next claim if it was the first stake for this staker or if
    // the next claim was re-initialised (ie. rewards were claimed until the last
    // staker snapshot and the last staker snapshot has no stake)
    if (nextClaims[owner].period == 0) {
      uint16 currentPeriod = _getPeriod(currentCycle, periodLengthInCycles);
      nextClaims[owner] = NextClaim(currentPeriod, uint64(globalHistory.length - 1), 0);
    }

    emit NftsBatchStaked(owner, currentCycle, address(staker.nft), tokenIds, weights);
  }

  /**
   * Unstakes a deposited NFT from the contract and updates the histories accordingly.
   * The NFT's weight will not count for the current cycle.
   * @dev Reverts if the caller is not the original owner of the NFT.
   * @dev While the contract is enabled, reverts if the NFT is still frozen.
   * @dev Reverts if the NFT transfer back to the original owner fails.
   * @dev If ERC1155 safe transfers are supported by the receiver wallet, the whitelisted NFT contract emits an ERC1155 TransferSingle event for the NFT transfer back to the staker.
   * @dev If ERC1155 safe transfers are not supported by the receiver wallet, the whitelisted NFT contract emits an ERC721 Transfer event for the NFT transfer back to the staker.
   * @dev While the contract is enabled, emits a HistoriesUpdated event.
   * @dev Emits a NftUnstaked event.
   * @param tokenId The token identifier, referencing the NFT being unstaked.
   */
  function unstake(address nft, uint256 tokenId) public {
    ContractStaking storage staker = stakingContracts[nft];
    require(staker.enabled, "contract not enabled");

    TokenInfo storage tokenInfo = staker.tokens[tokenId];
    require(tokenInfo.owner == _msgSender(), "not staked for owner");

    uint16 currentCycle = _getCycle(block.timestamp);
    uint128 weight = tokenInfo.weight;

    // ensure that at least an entire cycle has elapsed before unstaking the token to avoid
    // an exploit where a full cycle would be claimable if staking just before the end
    // of a cycle and unstaking right after the start of the new cycle
    require(currentCycle - tokenInfo.depositCycle >= 2, "token still frozen");
    _updateHistories(_msgSender(), -int128(uint128(weight)), currentCycle);

    // clear the token owner to ensure it cannot be unstaked again without being re-staked
    tokenInfo.owner = address(0);

    // set the withdrawal cycle to ensure it cannot be re-staked during the same cycle
    tokenInfo.withdrawCycle = currentCycle;

    staker.nft.safeTransferFrom(address(this), _msgSender(), tokenId, tokenInfo.amount, "");
    emit NftUnstaked(_msgSender(), currentCycle, address(staker.nft), tokenId, weight);
  }

  /**
   * Unstakes a batch of deposited NFTs from the contract.
   * @dev Reverts if `tokenIds` is empty.
   * @dev Reverts if the caller is not the original owner of any of the NFTs.
   * @dev While the contract is enabled, reverts if any NFT is being unstaked before its staking freeze duration has elapsed.
   * @dev While the contract is enabled, creates any missing snapshots, up-to the current cycle.
   * @dev While the contract is enabled, emits the HistoriesUpdated event.
   * @dev Emits the NftsBatchUnstaked event for each NFT unstaked.
   * @param tokenIds The token identifiers, referencing the NFTs being unstaked.
   */
  function batchUnstake(address nft, uint256[] calldata tokenIds) public {
    ContractStaking storage staker = stakingContracts[nft];
    require(staker.enabled, "contract not enabled");

    uint256 numTokens = tokenIds.length;
    require(numTokens != 0, "no tokens");

    uint16 currentCycle = _getCycle(block.timestamp);
    int128 totalUnstakedWeight = 0;
    uint256[] memory values = new uint256[](numTokens);
    uint256[] memory weights = new uint256[](numTokens);

    for (uint256 index = 0; index < numTokens; ++index) {
      uint256 tokenId = tokenIds[index];

      TokenInfo storage tokenInfo = staker.tokens[tokenId];
      require(tokenInfo.owner == _msgSender(), "not staked for owner");

      // ensure that at least an entire cycle has elapsed before
      // unstaking the token to avoid an exploit where a a fukll cycle
      // would be claimable if staking just before the end of a cycle
      // and unstaking right after the start of the new cycle
      require(currentCycle - tokenInfo.depositCycle >= 2, "token still frozen");

      // clear the token owner to ensure it cannot be unstaked again
      // without being re-staked
      tokenInfo.owner = address(0);

      // we can use unsafe math here since the maximum total staked
      // weight that a staker can unstake must fit within uint128
      // (i.e. the staker snapshot stake limit)
      uint128 weight = tokenInfo.weight;
      totalUnstakedWeight += int128(uint128(weight)); // this is safe
      weights[index] = weight;
      values[index] = tokenInfo.amount;
    }

    _updateHistories(_msgSender(), -totalUnstakedWeight, currentCycle);

    staker.nft.safeBatchTransferFrom(address(this), _msgSender(), tokenIds, values, "");
    emit NftsBatchUnstaked(_msgSender(), currentCycle, address(staker.nft), tokenIds, weights);
  }

  /**
   * Estimates the claimable rewards for the specified maximum number of past periods, starting at the next claimable period.
   * Estimations can be done only for periods which have already ended.
   * The maximum number of periods to claim can be calibrated to chunk down claims in several transactions to accomodate gas constraints.
   * @param maxPeriods The maximum number of periods to calculate for.
   * @return startPeriod The first period on which the computation starts.
   * @return periods The number of periods computed for.
   * @return amount The total claimable rewards.
   */
  function estimateRewards(uint16 maxPeriods)
    public
    view
    whenNotPaused
    hasStarted
    returns (
      uint16 startPeriod,
      uint16 periods,
      uint256 amount
    )
  {
    (ComputedClaim memory claim, ) = _computeRewards(_msgSender(), maxPeriods);
    startPeriod = claim.startPeriod;
    periods = claim.periods;
    amount = claim.amount;
  }

  /**
   * Claims the claimable rewards for the specified maximum number of past periods, starting at the next claimable period.
   * Claims can be done only for periods which have already ended.
   * The maximum number of periods to claim can be calibrated to chunk down claims in several transactions to accomodate gas constraints.
   * @dev Reverts if the reward tokens transfer fails.
   * @dev The rewards token contract emits an ERC20 Transfer event for the reward tokens transfer.
   * @dev Emits a RewardsClaimed event.
   * @param maxPeriods The maximum number of periods to claim for.
   */
  function claimRewards(uint16 maxPeriods) external whenNotPaused hasStarted {
    NextClaim memory nextClaim = nextClaims[_msgSender()];

    (ComputedClaim memory claim, NextClaim memory newNextClaim) = _computeRewards(_msgSender(), maxPeriods);

    // free up memory on already processed staker snapshots
    Snapshot[] storage stakerHistory = stakerHistories[_msgSender()];
    while (nextClaim.stakerSnapshotIndex < newNextClaim.stakerSnapshotIndex) {
      delete stakerHistory[nextClaim.stakerSnapshotIndex++];
    }

    if (claim.periods == 0) {
      return;
    }

    if (nextClaims[_msgSender()].period == 0) {
      return;
    }

    Snapshot memory lastStakerSnapshot = stakerHistory[stakerHistory.length - 1];

    uint256 lastClaimedCycle = (claim.startPeriod + claim.periods - 1) * periodLengthInCycles;
    if (
      lastClaimedCycle >= lastStakerSnapshot.startCycle && // the claim reached the last staker snapshot
      lastStakerSnapshot.stake == 0 // and nothing is staked in the last staker snapshot
    ) {
      // re-init the next claim
      delete nextClaims[_msgSender()];
    } else {
      nextClaims[_msgSender()] = newNextClaim;
    }

    if (claim.amount != 0) {
      coin.distribute(_msgSender(), claim.amount);
    }

    emit RewardsClaimed(_msgSender(), _getCycle(block.timestamp), claim.startPeriod, claim.periods, claim.amount);
  }

  /**
   * @return the token info for given token and contract.
   */
  function getTokenInfo(address nft, uint256 id) public view returns (TokenInfo memory) {
    return stakingContracts[nft].tokens[id];
  }

  /**
   * Retrieves the current cycle (index-1 based).
   * @return The current cycle (index-1 based).
   */
  function getCurrentCycle() external view returns (uint16) {
    return _getCycle(block.timestamp);
  }

  /**
   * Retrieves the current period (index-1 based).
   * @return The current period (index-1 based).
   */
  function getCurrentPeriod() external view returns (uint16) {
    return _getCurrentPeriod(periodLengthInCycles);
  }

  /**
   * Retrieves the last global snapshot index, if any.
   * @dev Reverts if the global history is empty.
   * @return The last global snapshot index.
   */
  function lastGlobalSnapshotIndex() external view returns (uint256) {
    uint256 length = globalHistory.length;
    require(length != 0, "empty global history");
    return length - 1;
  }

  /**
   * Retrieves the last staker snapshot index, if any.
   * @dev Reverts if the staker history is empty.
   * @return The last staker snapshot index.
   */
  function lastStakerSnapshotIndex(address staker) external view returns (uint256) {
    uint256 length = stakerHistories[staker].length;
    require(length != 0, "empty staker history");
    return length - 1;
  }

  /**
   * Calculates the amount of rewards for a staker over a capped number of periods.
   * @dev Processes until the specified maximum number of periods to claim is reached, or the last computable period is reached, whichever occurs first.
   * @param staker The staker for whom the rewards will be computed.
   * @param maxPeriods Maximum number of periods over which to compute the rewards.
   * @return claim the result of computation
   * @return nextClaim the next claim which can be used to update the staker's state
   */
  function _computeRewards(address staker, uint16 maxPeriods)
    internal
    view
    returns (ComputedClaim memory claim, NextClaim memory nextClaim)
  {
    // computing 0 periods
    if (maxPeriods == 0) {
      return (claim, nextClaim);
    }

    // the history is empty
    if (globalHistory.length == 0) {
      return (claim, nextClaim);
    }

    nextClaim = nextClaims[staker];
    claim.startPeriod = nextClaim.period;

    // nothing has been staked yet
    if (claim.startPeriod == 0) {
      return (claim, nextClaim);
    }

    uint16 periodLengthInCycles_ = periodLengthInCycles; // 2
    uint16 endClaimPeriod = _getCurrentPeriod(periodLengthInCycles_); // 35

    // current period is not claimable
    if (nextClaim.period == endClaimPeriod) {
      return (claim, nextClaim);
    }

    // retrieve the next snapshots if they exist
    Snapshot[] memory stakerHistory = stakerHistories[staker];

    Snapshot memory globalSnapshot = globalHistory[nextClaim.globalSnapshotIndex];

    Snapshot memory stakerSnapshot = stakerHistory[nextClaim.stakerSnapshotIndex];

    Snapshot memory nextGlobalSnapshot;
    Snapshot memory nextStakerSnapshot;

    if (nextClaim.globalSnapshotIndex != globalHistory.length - 1) {
      nextGlobalSnapshot = globalHistory[nextClaim.globalSnapshotIndex + 1];
    }
    if (nextClaim.stakerSnapshotIndex != stakerHistory.length - 1) {
      nextStakerSnapshot = stakerHistory[nextClaim.stakerSnapshotIndex + 1];
    }

    // excludes the current period
    claim.periods = endClaimPeriod - nextClaim.period;

    if (maxPeriods < claim.periods) {
      claim.periods = maxPeriods;
    }

    // re-calibrate the end claim period based on the actual number of
    // periods to claim. nextClaim.period will be updated to this value
    // after exiting the loop
    endClaimPeriod = nextClaim.period + claim.periods;

    // iterate over periods
    while (nextClaim.period != endClaimPeriod) {
      uint16 nextPeriodStartCycle = nextClaim.period * periodLengthInCycles_ + 1; // 21
      uint256 rewardPerCycle = rewardsSchedule[nextClaim.period];
      uint256 startCycle = nextPeriodStartCycle - periodLengthInCycles_; // 19
      uint256 endCycle = 0;

      // iterate over global snapshots
      while (endCycle != nextPeriodStartCycle) {
        // find the range-to-claim starting cycle, where the current
        // global snapshot, the current staker snapshot, and the current
        // period overlap
        if (globalSnapshot.startCycle > startCycle) {
          startCycle = globalSnapshot.startCycle;
        }
        if (stakerSnapshot.startCycle > startCycle) {
          startCycle = stakerSnapshot.startCycle;
        }

        // find the range-to-claim ending cycle, where the current
        // global snapshot, the current staker snapshot, and the current
        // period no longer overlap. The end cycle is exclusive of the
        // range-to-claim and represents the beginning cycle of the next
        // range-to-claim
        endCycle = nextPeriodStartCycle;
        if ((nextGlobalSnapshot.startCycle != 0) && (nextGlobalSnapshot.startCycle < endCycle)) {
          endCycle = nextGlobalSnapshot.startCycle;
        }

        // only calculate and update the claimable rewards if there is
        // something to calculate with
        if ((globalSnapshot.stake != 0) && (stakerSnapshot.stake != 0) && (rewardPerCycle != 0)) {
          uint256 snapshotReward = (endCycle - startCycle).mul(rewardPerCycle).mul(stakerSnapshot.stake);
          snapshotReward /= globalSnapshot.stake;

          claim.amount = claim.amount.add(snapshotReward);
        }

        // advance the current global snapshot to the next (if any)
        // if its cycle range has been fully processed and if the next
        // snapshot starts at most on next period first cycle
        if (nextGlobalSnapshot.startCycle == endCycle) {
          globalSnapshot = nextGlobalSnapshot;
          ++nextClaim.globalSnapshotIndex;

          if (nextClaim.globalSnapshotIndex != globalHistory.length - 1) {
            nextGlobalSnapshot = globalHistory[nextClaim.globalSnapshotIndex + 1];
          } else {
            nextGlobalSnapshot = Snapshot(0, 0);
          }
        }

        // advance the current staker snapshot to the next (if any)
        // if its cycle range has been fully processed and if the next
        // snapshot starts at most on next period first cycle
        if (nextStakerSnapshot.startCycle == endCycle) {
          stakerSnapshot = nextStakerSnapshot;
          ++nextClaim.stakerSnapshotIndex;

          if (nextClaim.stakerSnapshotIndex != stakerHistory.length - 1) {
            nextStakerSnapshot = stakerHistory[nextClaim.stakerSnapshotIndex + 1];
          } else {
            nextStakerSnapshot = Snapshot(0, 0);
          }
        }
      }

      ++nextClaim.period;
    }

    return (claim, nextClaim);
  }

  /**
   * Updates the global and staker histories at the current cycle with a new difference in stake.
   * @dev Emits a HistoriesUpdated event.
   * @param staker The staker who is updating the history.
   * @param stakeDelta The difference to apply to the current stake.
   * @param currentCycle The current cycle.
   */
  function _updateHistories(
    address staker,
    int128 stakeDelta,
    uint16 currentCycle
  ) internal {
    uint256 stakerSnapshotIndex = _updateHistory(stakerHistories[staker], stakeDelta, currentCycle);
    uint256 globalSnapshotIndex = _updateHistory(globalHistory, stakeDelta, currentCycle);

    emit HistoriesUpdated(
      staker,
      currentCycle,
      stakerHistories[staker][stakerSnapshotIndex].stake,
      globalHistory[globalSnapshotIndex].stake
    );
  }

  /**
   * Updates the history at the current cycle with a new difference in stake.
   * @dev It will update the latest snapshot if it starts at the current cycle, otherwise will create a new snapshot with the updated stake.
   * @param history The history to update.
   * @param stakeDelta The difference to apply to the current stake.
   * @param currentCycle The current cycle.
   * @return snapshotIndex Index of the snapshot that was updated or created (i.e. the latest snapshot index).
   */
  function _updateHistory(
    Snapshot[] storage history,
    int128 stakeDelta,
    uint16 currentCycle
  ) internal returns (uint256 snapshotIndex) {
    uint256 historyLength = history.length;
    uint128 snapshotStake;

    if (historyLength != 0) {
      // there is an existing snapshot
      snapshotIndex = historyLength - 1;
      Snapshot storage snapshot2 = history[snapshotIndex];
      snapshotStake = uint256(int256(int128(snapshot2.stake)).add(stakeDelta)).toUint128();

      if (snapshot2.startCycle == currentCycle) {
        // update the snapshot if it starts on the current cycle
        snapshot2.stake = snapshotStake;
        return snapshotIndex;
      }

      // update the snapshot index (as a reflection that a new latest
      // snapshot will be added to the history), if there was already an
      // existing snapshot
      snapshotIndex += 1;
    } else {
      // the snapshot index (as a reflection that a new latest snapshot
      // will be added to the history) should already be initialized
      // correctly to the default value 0

      // the stake delta will not be negative, if we have no history, as
      // that would indicate that we are unstaking without having staked
      // anything first
      snapshotStake = uint128(stakeDelta);
    }

    Snapshot memory snapshot;
    snapshot.stake = snapshotStake;
    snapshot.startCycle = currentCycle;

    // add a new snapshot in the history
    history.push(snapshot);
  }

  /**
   * Retrieves the cycle (index-1 based) at the specified timestamp.
   * @dev Reverts if the specified timestamp is earlier than the beginning of the staking schedule
   * @param timestamp The timestamp for which the cycle is derived from.
   * @return The cycle (index-1 based) at the specified timestamp.
   */
  function _getCycle(uint256 timestamp) internal view returns (uint16) {
    require(timestamp >= startTimestamp, "timestamp preceeds start");
    return (((timestamp - startTimestamp) / uint256(cycleLengthInSeconds)) + 1).toUint16();
  }

  /**
   * Retrieves the period (index-1 based) for the specified cycle and period length.
   * @dev reverts if the specified cycle is zero.
   * @param cycle The cycle within the period to retrieve.
   * @param periodLengthInCycles_ Length of a period, in cycles.
   * @return The period (index-1 based) for the specified cycle and period length.
   */
  function _getPeriod(uint16 cycle, uint16 periodLengthInCycles_) internal pure returns (uint16) {
    require(cycle != 0, "cycle cannot be zero");
    return (cycle - 1) / periodLengthInCycles_ + 1;
  }

  /**
   * Retrieves the current period (index-1 based).
   * @param periodLengthInCycles_ Length of a period, in cycles.
   * @return The current period (index-1 based).
   */
  function _getCurrentPeriod(uint16 periodLengthInCycles_) internal view returns (uint16) {
    return _getPeriod(_getCycle(block.timestamp), periodLengthInCycles_);
  }

  /**
   * @dev See {IERC165-supportsInterface}.
   */
  function supportsInterface(bytes4 interfaceId) public view override(IERC165, ERC165, AccessControl) returns (bool) {
    return
      type(IERC721Receiver).interfaceId == interfaceId ||
      type(IERC1155Receiver).interfaceId == interfaceId ||
      super.supportsInterface(interfaceId);
  }
}

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
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

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
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

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
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/IERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev _Available since v3.1._
 */
interface IERC1155Receiver is IERC165 {
    /**
     * @dev Handles the receipt of a single ERC1155 token type. This function is
     * called at the end of a `safeTransferFrom` after the balance has been updated.
     *
     * NOTE: To accept the transfer, this must return
     * `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
     * (i.e. 0xf23a6e61, or its own function selector).
     *
     * @param operator The address which initiated the transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param id The ID of the token being transferred
     * @param value The amount of tokens being transferred
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
     */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    /**
     * @dev Handles the receipt of a multiple ERC1155 token types. This function
     * is called at the end of a `safeBatchTransferFrom` after the balances have
     * been updated.
     *
     * NOTE: To accept the transfer(s), this must return
     * `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
     * (i.e. 0xbc197c81, or its own function selector).
     *
     * @param operator The address which initiated the batch transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param ids An array containing ids of each token being transferred (order and length must match values array)
     * @param values An array containing amounts of each token being transferred (order and length must match ids array)
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
     */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/math/SafeCast.sol)

pragma solidity ^0.8.0;

/**
 * @dev Wrappers over Solidity's uintXX/intXX casting operators with added overflow
 * checks.
 *
 * Downcasting from uint256/int256 in Solidity does not revert on overflow. This can
 * easily result in undesired exploitation or bugs, since developers usually
 * assume that overflows raise errors. `SafeCast` restores this intuition by
 * reverting the transaction when such an operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 *
 * Can be combined with {SafeMath} and {SignedSafeMath} to extend it to smaller types, by performing
 * all math on `uint256` and `int256` and then downcasting.
 */
library SafeCast {
    /**
     * @dev Returns the downcasted uint224 from uint256, reverting on
     * overflow (when the input is greater than largest uint224).
     *
     * Counterpart to Solidity's `uint224` operator.
     *
     * Requirements:
     *
     * - input must fit into 224 bits
     */
    function toUint224(uint256 value) internal pure returns (uint224) {
        require(value <= type(uint224).max, "SafeCast: value doesn't fit in 224 bits");
        return uint224(value);
    }

    /**
     * @dev Returns the downcasted uint128 from uint256, reverting on
     * overflow (when the input is greater than largest uint128).
     *
     * Counterpart to Solidity's `uint128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     */
    function toUint128(uint256 value) internal pure returns (uint128) {
        require(value <= type(uint128).max, "SafeCast: value doesn't fit in 128 bits");
        return uint128(value);
    }

    /**
     * @dev Returns the downcasted uint96 from uint256, reverting on
     * overflow (when the input is greater than largest uint96).
     *
     * Counterpart to Solidity's `uint96` operator.
     *
     * Requirements:
     *
     * - input must fit into 96 bits
     */
    function toUint96(uint256 value) internal pure returns (uint96) {
        require(value <= type(uint96).max, "SafeCast: value doesn't fit in 96 bits");
        return uint96(value);
    }

    /**
     * @dev Returns the downcasted uint64 from uint256, reverting on
     * overflow (when the input is greater than largest uint64).
     *
     * Counterpart to Solidity's `uint64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     */
    function toUint64(uint256 value) internal pure returns (uint64) {
        require(value <= type(uint64).max, "SafeCast: value doesn't fit in 64 bits");
        return uint64(value);
    }

    /**
     * @dev Returns the downcasted uint32 from uint256, reverting on
     * overflow (when the input is greater than largest uint32).
     *
     * Counterpart to Solidity's `uint32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     */
    function toUint32(uint256 value) internal pure returns (uint32) {
        require(value <= type(uint32).max, "SafeCast: value doesn't fit in 32 bits");
        return uint32(value);
    }

    /**
     * @dev Returns the downcasted uint16 from uint256, reverting on
     * overflow (when the input is greater than largest uint16).
     *
     * Counterpart to Solidity's `uint16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     */
    function toUint16(uint256 value) internal pure returns (uint16) {
        require(value <= type(uint16).max, "SafeCast: value doesn't fit in 16 bits");
        return uint16(value);
    }

    /**
     * @dev Returns the downcasted uint8 from uint256, reverting on
     * overflow (when the input is greater than largest uint8).
     *
     * Counterpart to Solidity's `uint8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits.
     */
    function toUint8(uint256 value) internal pure returns (uint8) {
        require(value <= type(uint8).max, "SafeCast: value doesn't fit in 8 bits");
        return uint8(value);
    }

    /**
     * @dev Converts a signed int256 into an unsigned uint256.
     *
     * Requirements:
     *
     * - input must be greater than or equal to 0.
     */
    function toUint256(int256 value) internal pure returns (uint256) {
        require(value >= 0, "SafeCast: value must be positive");
        return uint256(value);
    }

    /**
     * @dev Returns the downcasted int128 from int256, reverting on
     * overflow (when the input is less than smallest int128 or
     * greater than largest int128).
     *
     * Counterpart to Solidity's `int128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     *
     * _Available since v3.1._
     */
    function toInt128(int256 value) internal pure returns (int128) {
        require(value >= type(int128).min && value <= type(int128).max, "SafeCast: value doesn't fit in 128 bits");
        return int128(value);
    }

    /**
     * @dev Returns the downcasted int64 from int256, reverting on
     * overflow (when the input is less than smallest int64 or
     * greater than largest int64).
     *
     * Counterpart to Solidity's `int64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     *
     * _Available since v3.1._
     */
    function toInt64(int256 value) internal pure returns (int64) {
        require(value >= type(int64).min && value <= type(int64).max, "SafeCast: value doesn't fit in 64 bits");
        return int64(value);
    }

    /**
     * @dev Returns the downcasted int32 from int256, reverting on
     * overflow (when the input is less than smallest int32 or
     * greater than largest int32).
     *
     * Counterpart to Solidity's `int32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     *
     * _Available since v3.1._
     */
    function toInt32(int256 value) internal pure returns (int32) {
        require(value >= type(int32).min && value <= type(int32).max, "SafeCast: value doesn't fit in 32 bits");
        return int32(value);
    }

    /**
     * @dev Returns the downcasted int16 from int256, reverting on
     * overflow (when the input is less than smallest int16 or
     * greater than largest int16).
     *
     * Counterpart to Solidity's `int16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     *
     * _Available since v3.1._
     */
    function toInt16(int256 value) internal pure returns (int16) {
        require(value >= type(int16).min && value <= type(int16).max, "SafeCast: value doesn't fit in 16 bits");
        return int16(value);
    }

    /**
     * @dev Returns the downcasted int8 from int256, reverting on
     * overflow (when the input is less than smallest int8 or
     * greater than largest int8).
     *
     * Counterpart to Solidity's `int8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits.
     *
     * _Available since v3.1._
     */
    function toInt8(int256 value) internal pure returns (int8) {
        require(value >= type(int8).min && value <= type(int8).max, "SafeCast: value doesn't fit in 8 bits");
        return int8(value);
    }

    /**
     * @dev Converts an unsigned uint256 into a signed int256.
     *
     * Requirements:
     *
     * - input must be less than or equal to maxInt256.
     */
    function toInt256(uint256 value) internal pure returns (int256) {
        // Note: Unsafe cast below is okay because `type(int256).max` is guaranteed to be positive
        require(value <= uint256(type(int256).max), "SafeCast: value doesn't fit in an int256");
        return int256(value);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/math/SignedSafeMath.sol)

pragma solidity ^0.8.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SignedSafeMath` is no longer needed starting with Solidity 0.8. The compiler
 * now has built in overflow checking.
 */
library SignedSafeMath {
    /**
     * @dev Returns the multiplication of two signed integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(int256 a, int256 b) internal pure returns (int256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two signed integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(int256 a, int256 b) internal pure returns (int256) {
        return a / b;
    }

    /**
     * @dev Returns the subtraction of two signed integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(int256 a, int256 b) internal pure returns (int256) {
        return a - b;
    }

    /**
     * @dev Returns the addition of two signed integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(int256 a, int256 b) internal pure returns (int256) {
        return a + b;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (access/AccessControl.sol)

pragma solidity ^0.8.0;

import "./IAccessControl.sol";
import "../utils/Context.sol";
import "../utils/Strings.sol";
import "../utils/introspection/ERC165.sol";

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControl is Context, IAccessControl, ERC165 {
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role, _msgSender());
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControl).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view virtual override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view virtual {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        Strings.toHexString(uint160(account), 20),
                        " is missing role ",
                        Strings.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view virtual override returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been revoked `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     *
     * NOTE: This function is deprecated in favor of {_grantRole}.
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * Internal function without access restriction.
     */
    function _grantRole(bytes32 role, address account) internal virtual {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * Internal function without access restriction.
     */
    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

/**
 * Stakable provides method to get weight for staking IERC 1155/721.
 */
interface IStakable {
  /**
   * ERC1155: Transfers `value` amount of an `id` from  `from` to `to` (with safety call).
   * @dev Caller must be approved to manage the tokens being transferred out of the `from` account (see "Approval" section of the standard).
   * @dev MUST revert if `to` is the zero address.
   * @dev MUST revert if balance of holder for token `id` is lower than the `value` sent.
   * @dev MUST revert on any other error.
   * @dev MUST emit the `TransferSingle` event to reflect the balance change (see "Safe Transfer Rules" section of the standard).
   * @dev After the above conditions are met, this function MUST check if `to` is a smart contract (e.g. code size > 0). If so, it MUST call `onERC1155Received` on `to` and act appropriately (see "Safe Transfer Rules" section of the standard).
   * @param from Source address
   * @param to Target address
   * @param id ID of the token type
   * @param value Transfer amount
   * @param data Additional data with no specified format, MUST be sent unaltered in call to `onERC1155Received` on `to`
   */
  function safeTransferFrom(
    address from,
    address to,
    uint256 id,
    uint256 value,
    bytes calldata data
  ) external;

  /**
   * @notice Transfers `values` amount(s) of `ids` from the `from` address to the `to` address specified (with safety call).
   * @dev Caller must be approved to manage the tokens being transferred out of the `from` account (see "Approval" section of the standard).
   * MUST revert if `to` is the zero address.
   * MUST revert if length of `ids` is not the same as length of `values`.
   * MUST revert if any of the balance(s) of the holder(s) for token(s) in `ids` is lower than the respective amount(s) in `values` sent to the recipient.
   * MUST revert on any other error.
   * MUST emit `TransferSingle` or `TransferBatch` event(s) such that all the balance changes are reflected (see "Safe Transfer Rules" section of the standard).
   * Balance changes and events MUST follow the ordering of the arrays (_ids[0]/_values[0] before _ids[1]/_values[1], etc).
   * After the above conditions for the transfer(s) in the batch are met, this function MUST check if `to` is a smart contract (e.g. code size > 0). If so, it MUST call the relevant `ERC1155TokenReceiver` hook(s) on `to` and act appropriately (see "Safe Transfer Rules" section of the standard).
   * @param from Source address
   * @param to Target address
   * @param ids IDs of each token type (order and length must match _values array)
   * @param values Transfer amounts per token type (order and length must match _ids array)
   * @param data Additional data with no specified format, MUST be sent unaltered in call to the `ERC1155TokenReceiver` hook(s) on `to`
   */
  function safeBatchTransferFrom(
    address from,
    address to,
    uint256[] calldata ids,
    uint256[] calldata values,
    bytes calldata data
  ) external;

  /**
   * @dev returns staking weight for given NFT.
   * This affects amount of reward for staking.
   */
  function getStakingWeight(uint256 tokenId) external view returns (uint128);
}

// SPDX-License-Identifier: MIT
/* solhint-disable no-empty-blocks */

pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/governance/utils/IVotes.sol";

import "./IDistributor.sol";

interface ICoin is IVotes, IERC20, IDistributor {}

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
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (governance/utils/IVotes.sol)
pragma solidity ^0.8.0;

/**
 * @dev Common interface for {ERC20Votes}, {ERC721Votes}, and other {Votes}-enabled contracts.
 *
 * _Available since v4.5._
 */
interface IVotes {
    /**
     * @dev Emitted when an account changes their delegate.
     */
    event DelegateChanged(address indexed delegator, address indexed fromDelegate, address indexed toDelegate);

    /**
     * @dev Emitted when a token transfer or delegate change results in changes to a delegate's number of votes.
     */
    event DelegateVotesChanged(address indexed delegate, uint256 previousBalance, uint256 newBalance);

    /**
     * @dev Returns the current amount of votes that `account` has.
     */
    function getVotes(address account) external view returns (uint256);

    /**
     * @dev Returns the amount of votes that `account` had at the end of a past block (`blockNumber`).
     */
    function getPastVotes(address account, uint256 blockNumber) external view returns (uint256);

    /**
     * @dev Returns the total supply of votes available at the end of a past block (`blockNumber`).
     *
     * NOTE: This value is the sum of all available votes, which is not necessarily the sum of all delegated votes.
     * Votes that have not been delegated are still part of total supply, even though they would not participate in a
     * vote.
     */
    function getPastTotalSupply(uint256 blockNumber) external view returns (uint256);

    /**
     * @dev Returns the delegate that `account` has chosen.
     */
    function delegates(address account) external view returns (address);

    /**
     * @dev Delegates votes from the sender to `delegatee`.
     */
    function delegate(address delegatee) external;

    /**
     * @dev Delegates votes from signer to `delegatee`.
     */
    function delegateBySig(
        address delegatee,
        uint256 nonce,
        uint256 expiry,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

/**
 * Interface used for distributing rewards.
 */
interface IDistributor {
  /**
   * @dev This will distribute BHC to the specified address.
   * @param recipient of BHC token.
   * @param amount of BHC.
   */
  function distribute(address recipient, uint256 amount) external;

  /**
   * @dev will take owner tokens and put them back to the contract.
   * @param owner of BHC token.
   * @param amount of BHC.
   */
  function take(address owner, uint256 amount) external;
}