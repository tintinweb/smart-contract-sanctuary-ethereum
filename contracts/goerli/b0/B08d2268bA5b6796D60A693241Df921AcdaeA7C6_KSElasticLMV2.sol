//SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import {IERC20} from '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import {IERC721} from '@openzeppelin/contracts/token/ERC721/IERC721.sol';
import {ReentrancyGuard} from '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import {EnumerableSet} from '@openzeppelin/contracts/utils/structs/EnumerableSet.sol';

import {LMMath} from 'contracts/libraries/LMMath.sol';
import {KSAdmin} from 'contracts/base/KSAdmin.sol';

import {IKSElasticLMV2} from 'contracts/interfaces/IKSElasticLMV2.sol';
import {IBasePositionManager} from 'contracts/interfaces/IBasePositionManager.sol';
import {IPoolStorage} from 'contracts/interfaces/IPoolStorage.sol';
import {IKSElasticLMHelper} from 'contracts/interfaces/IKSElasticLMHelper.sol';
import {IKyberSwapFarmingToken} from 'contracts/interfaces/periphery/IKyberSwapFarmingToken.sol';

contract KSElasticLMV2 is IKSElasticLMV2, KSAdmin, ReentrancyGuard {
  using EnumerableSet for EnumerableSet.UintSet;

  address private constant ETH_ADDRESS = address(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE);

  IERC721 private immutable nft;
  IKSElasticLMHelper private helper;
  address public immutable weth;

  bytes private farmingTokenCreationCode;
  mapping(uint256 => FarmInfo) private farms; // fId => FarmInfo
  mapping(uint256 => StakeInfo) private stakes; // sId => stakeInfo
  mapping(address => EnumerableSet.UintSet) private depositNFTs;

  uint256 public farmCount;
  bool public emergencyEnabled;

  constructor(IERC721 _nft, IKSElasticLMHelper _helper) {
    nft = _nft;
    helper = _helper;
    weth = IBasePositionManager(address(_nft)).WETH();
  }

  receive() external payable {}

  // ======== admin ============

  //enable emergency mode
  function updateEmergency(bool enableOrDisable) external isAdmin {
    emergencyEnabled = enableOrDisable;

    emit UpdateEmergency(enableOrDisable);
  }

  //update farming token creationCode, use to deploy when add farm
  function updateTokenCode(bytes memory _farmingTokenCreationCode) external isAdmin {
    farmingTokenCreationCode = _farmingTokenCreationCode;

    emit UpdateTokenCode(_farmingTokenCreationCode);
  }

  //update helper contract, use to gather information from elastic
  function updateHelper(IKSElasticLMHelper _helper) external isAdmin {
    helper = _helper;

    emit UpdateHelper(_helper);
  }

  //withdraw leftover rewards from contract
  function withdrawUnusedRewards(
    address[] calldata tokens,
    uint256[] calldata amounts
  ) external isAdmin {
    uint256 rewardTokenLength = tokens.length;
    for (uint256 i; i < rewardTokenLength; ) {
      _safeTransfer(tokens[i], msg.sender, amounts[i]);
      emit WithdrawUnusedRewards(tokens[i], amounts[i], msg.sender);

      unchecked {
        ++i;
      }
    }
  }

  //add a new farm
  function addFarm(
    address poolAddress,
    RangeInput[] calldata ranges,
    PhaseInput calldata phase,
    bool isUsingToken
  ) external isOperator returns (uint256 fId) {
    //new farm id would be current farmCount
    fId = farmCount;
    FarmInfo storage farm = farms[fId];

    //validate phase input
    _isPhaseValid(phase);

    for (uint256 i; i < ranges.length; ) {
      //validate range input
      _isRangeValid(ranges[i]);

      //push range into farm ranges array
      farm.ranges.push(
        IKSElasticLMV2.RangeInfo({
          tickLower: ranges[i].tickLower,
          tickUpper: ranges[i].tickUpper,
          weight: ranges[i].weight,
          isRemoved: false
        })
      );

      unchecked {
        ++i;
      }
    }

    //update farm data
    farm.poolAddress = poolAddress;
    farm.phase.startTime = phase.startTime;
    farm.phase.endTime = phase.endTime;

    for (uint256 i; i < phase.rewards.length; ) {
      //push rewards info to farm phase rewards array
      farm.phase.rewards.push(phase.rewards[i]);

      //sumReward of newly created farm would be, this sumReward is total reward per liquidity until now
      farm.sumRewardPerLiquidity.push(0);

      unchecked {
        ++i;
      }
    }

    //deploy farmingToken if needed
    address destination;
    if (isUsingToken) {
      bytes memory creationCode = abi.encodePacked(
        farmingTokenCreationCode,
        abi.encode(msg.sender)
      );
      bytes32 salt = keccak256(abi.encode(msg.sender, fId));
      assembly {
        destination := create2(0, add(creationCode, 32), mload(creationCode), salt)
        if iszero(extcodesize(destination)) {
          revert(0, 0)
        }
      }
      farm.farmingToken = destination;
    }

    //last touched time would be startTime
    farm.lastTouchedTime = phase.startTime;

    //increase farmCount
    unchecked {
      ++farmCount;
    }

    emit AddFarm(fId, poolAddress, ranges, phase, destination);
  }

  function addPhase(uint256 fId, PhaseInput calldata phaseInput) external isOperator {
    if (fId >= farmCount) revert InvalidFarm();

    //validate phase input
    _isPhaseValid(phaseInput);

    PhaseInfo storage phase = farms[fId].phase;

    uint256 length = phase.rewards.length;
    if (phaseInput.rewards.length != length) revert InvalidInput();

    //if phase not settled, update sumReward.
    //if phase already settled then it's not needed since sumReward would be unchanged
    if (!phase.isSettled) _updateFarmSumRewardPerLiquidity(fId);

    //override phase data with new data
    phase.startTime = phaseInput.startTime;
    phase.endTime = phaseInput.endTime;

    for (uint256 i; i < length; ) {
      //new phase rewards must be the same as old phase
      if (phase.rewards[i].rewardToken != phaseInput.rewards[i].rewardToken)
        revert InvalidReward();

      //update reward amounts
      phase.rewards[i].rewardAmount = phaseInput.rewards[i].rewardAmount;

      unchecked {
        ++i;
      }
    }

    //newly add phase must is not settled
    if (phase.isSettled) phase.isSettled = false;

    //set farm lastTouchedTime to startTime
    farms[fId].lastTouchedTime = phaseInput.startTime;

    emit AddPhase(fId, phaseInput);
  }

  function forceClosePhase(uint256 fId) external isOperator {
    if (fId >= farmCount) revert InvalidFarm();

    if (farms[fId].phase.isSettled) revert PhaseSettled();

    //update sumReward
    _updateFarmSumRewardPerLiquidity(fId);

    //close phase so settled must be true
    if (!farms[fId].phase.isSettled) farms[fId].phase.isSettled = true;

    emit ForceClosePhase(fId);
  }

  function addRange(uint256 fId, RangeInput calldata range) external isOperator {
    if (fId >= farmCount) revert InvalidFarm();
    _isRangeValid(range);

    //add a new range into farm ranges array
    farms[fId].ranges.push(
      IKSElasticLMV2.RangeInfo({
        tickLower: range.tickLower,
        tickUpper: range.tickUpper,
        weight: range.weight,
        isRemoved: false
      })
    );

    emit AddRange(fId, range);
  }

  function removeRange(uint256 fId, uint256 rangeId) external isOperator {
    if (fId >= farmCount) revert InvalidFarm();
    if (rangeId >= farms[fId].ranges.length || farms[fId].ranges[rangeId].isRemoved)
      revert RangeNotFound();

    //remove a range aka set isRemoved to false, it's still be in ranges array but cannot deposit to this range anymore
    farms[fId].ranges[rangeId].isRemoved = true;

    emit RemoveRange(fId, rangeId);
  }

  // ======== user ============
  /// @inheritdoc IKSElasticLMV2
  function deposit(
    uint256 fId,
    uint256 rangeId,
    uint256[] calldata nftIds,
    address receiver
  ) external override nonReentrant {
    _isAddLiquidityValid(fId, rangeId);

    //check positions meet farm requirements
    (bool isInvalid, uint128[] memory nftLiquidities) = _checkPosition(
      farms[fId].poolAddress,
      farms[fId].ranges[rangeId].tickLower,
      farms[fId].ranges[rangeId].tickUpper,
      nftIds
    );

    if (isInvalid) revert PositionNotEligible();

    //calculate lastest farm sumReward
    uint256[] memory curSumRewardPerLiquidity = _updateFarmSumRewardPerLiquidity(fId);
    uint32 weight = farms[fId].ranges[rangeId].weight;
    uint256 rewardLength = farms[fId].phase.rewards.length;
    uint256 totalLiquidity;

    //loop through list nftLength
    for (uint256 i; i < nftIds.length; ) {
      uint256 liquidityWithWeight = nftLiquidities[i];
      liquidityWithWeight = liquidityWithWeight * weight;

      //transfer nft to farm, add to list deposited nfts
      nft.transferFrom(msg.sender, address(this), nftIds[i]);
      if (!depositNFTs[receiver].add(nftIds[i])) revert FailToAdd();

      //create stake info
      StakeInfo storage stake = stakes[nftIds[i]];
      stake.owner = receiver;
      stake.fId = fId;
      stake.rangeId = rangeId;
      stake.liquidity = liquidityWithWeight;

      for (uint256 j; j < rewardLength; ) {
        stakes[nftIds[i]].lastSumRewardPerLiquidity.push(curSumRewardPerLiquidity[j]);
        stakes[nftIds[i]].rewardUnclaimed.push(0);

        unchecked {
          ++j;
        }
      }

      totalLiquidity += liquidityWithWeight;

      unchecked {
        ++i;
      }
    }

    //update farm total liquidity
    farms[fId].liquidity += totalLiquidity;

    //mint farmingToken equals to stake liquidity
    address farmingToken = farms[fId].farmingToken;
    if (farmingToken != address(0)) _mintFarmingToken(farmingToken, receiver, totalLiquidity);

    emit Deposit(fId, rangeId, nftIds, msg.sender, receiver);
  }

  /// @inheritdoc IKSElasticLMV2
  function claimReward(uint256 fId, uint256[] calldata nftIds) external override nonReentrant {
    _claimReward(fId, nftIds, msg.sender);
  }

  /// @inheritdoc IKSElasticLMV2
  function withdraw(uint256 fId, uint256[] calldata nftIds) external override nonReentrant {
    _claimReward(fId, nftIds, msg.sender);

    uint256 length = nftIds.length;
    uint256 totalLiq;

    //loop through list nfts
    for (uint256 i; i < length; ) {
      totalLiq += stakes[nftIds[i]].liquidity;

      //remove stake
      delete stakes[nftIds[i]];
      if (!depositNFTs[msg.sender].remove(nftIds[i])) revert FailToRemove();

      //transfer back nft to user
      nft.transferFrom(address(this), msg.sender, nftIds[i]);

      unchecked {
        ++i;
      }
    }

    //update farm total liquidity
    farms[fId].liquidity -= totalLiq;

    //burn an a mount of farmingToken from msg.sender
    if (farms[fId].farmingToken != address(0))
      _burnFarmingToken(farms[fId].farmingToken, msg.sender, totalLiq);

    emit Withdraw(nftIds, msg.sender);
  }

  /// @inheritdoc IKSElasticLMV2
  function addLiquidity(
    uint256 fId,
    uint256 rangeId,
    uint256[] memory nftIds
  ) external override nonReentrant {
    _isAddLiquidityValid(fId, rangeId);

    uint256 length = nftIds.length;
    uint32 weight = farms[fId].ranges[rangeId].weight;

    for (uint256 i; i < length; ) {
      _isStakeValidForAddLiquidity(fId, rangeId, nftIds[i]);

      //get liq from elastic
      uint256 posLiq = _getLiquidity(nftIds[i]);
      uint256 curLiq = stakes[nftIds[i]].liquidity;
      uint256 newLiq = posLiq * weight;

      //only update stake liquidity if newLiq > curLiq, ignore if liquidity is the same
      if (newLiq > curLiq) _updateLiquidity(fId, nftIds[i], newLiq, msg.sender);

      unchecked {
        ++i;
      }
    }
  }

  /// @inheritdoc IKSElasticLMV2
  function removeLiquidity(
    uint256 nftId,
    uint128 liquidity,
    uint256 amount0Min,
    uint256 amount1Min,
    uint256 deadline,
    bool isClaimFee,
    bool isReceiveNative
  ) external override nonReentrant {
    if (block.timestamp > deadline) revert Expired();
    if (stakes[nftId].owner != msg.sender) revert NotOwner();

    //get liq from elastic
    uint256 posLiq = _getLiquidity(nftId);
    if (liquidity == 0 || liquidity > posLiq) revert InvalidInput();

    //call to posManager to remove liquidity for position, also claim lp fee if needed
    _removeLiquidity(nftId, liquidity, deadline);
    if (isClaimFee) _claimFee(nftId, deadline, false);

    //calculate new liquidity after remove
    posLiq = posLiq - liquidity;

    uint256 fId = stakes[nftId].fId;
    uint256 curLiq = stakes[nftId].liquidity;
    uint256 newLiq = posLiq * farms[fId].ranges[stakes[nftId].rangeId].weight;

    //update liquidity if new liquidity < cur liquidity, ignore case where new liquidity >= cur liquidity
    if (newLiq < curLiq) _updateLiquidity(fId, nftId, newLiq, msg.sender);

    //transfer tokens from posManager to user
    _transferTokens(farms[fId].poolAddress, amount0Min, amount1Min, msg.sender, isReceiveNative);
  }

  /// @inheritdoc IKSElasticLMV2
  function claimFee(
    uint256 fId,
    uint256[] calldata nftIds,
    uint256 amount0Min,
    uint256 amount1Min,
    uint256 deadline,
    bool isReceiveNative
  ) external override nonReentrant {
    if (block.timestamp > deadline) revert Expired();

    uint256 length = nftIds.length;
    for (uint256 i; i < length; ) {
      _isStakeValid(fId, nftIds[i]);

      //call to posManager to claim fee
      _claimFee(nftIds[i], deadline, true);

      unchecked {
        ++i;
      }
    }

    //transfer tokens from posManager to user
    _transferTokens(farms[fId].poolAddress, amount0Min, amount1Min, msg.sender, isReceiveNative);
  }

  /// @inheritdoc IKSElasticLMV2
  function withdrawEmergency(uint256[] calldata nftIds) external override {
    uint256 length = nftIds.length;
    for (uint256 i; i < length; ) {
      uint256 nftId = nftIds[i];
      StakeInfo memory stake = stakes[nftId];

      if (stake.owner != msg.sender) revert NotOwner();

      //if emerency mode is not enable
      if (!emergencyEnabled) {
        address farmingToken = farms[stake.fId].farmingToken;
        uint256 liquidity = stake.liquidity;

        //burn farmingToken from msg.sender if stake liquidity greater than 0
        if (farmingToken != address(0) && liquidity != 0)
          _burnFarmingToken(farmingToken, stake.owner, liquidity);

        //remove nft from deposited nft list
        if (!depositNFTs[stake.owner].remove(nftId)) revert FailToRemove();

        //update farm total liquidity
        farms[stake.fId].liquidity -= liquidity;
      }

      //remove stake and transfer back nft to user, always do this even emergency enable or disable
      delete stakes[nftId];
      nft.transferFrom(address(this), stake.owner, nftId);

      emit WithdrawEmergency(nftId, stake.owner);

      unchecked {
        ++i;
      }
    }
  }

  // ======== getter ============
  function getAdmin() external view override returns (address) {
    return admin;
  }

  function getNft() external view override returns (IERC721) {
    return nft;
  }

  function getFarm(
    uint256 fId
  )
    external
    view
    override
    returns (
      address poolAddress,
      RangeInfo[] memory ranges,
      PhaseInfo memory phase,
      uint256 liquidity,
      address farmingToken,
      uint256[] memory sumRewardPerLiquidity,
      uint32 lastTouchedTime
    )
  {
    return (
      farms[fId].poolAddress,
      farms[fId].ranges,
      farms[fId].phase,
      farms[fId].liquidity,
      farms[fId].farmingToken,
      farms[fId].sumRewardPerLiquidity,
      farms[fId].lastTouchedTime
    );
  }

  function getDepositedNFTs(address user) external view returns (uint256[] memory listNFTs) {
    listNFTs = depositNFTs[user].values();
  }

  function getStake(
    uint256 nftId
  )
    external
    view
    override
    returns (
      address owner,
      uint256 fId,
      uint256 rangeId,
      uint256 liquidity,
      uint256[] memory lastSumRewardPerLiquidity,
      uint256[] memory rewardUnclaimed
    )
  {
    return (
      stakes[nftId].owner,
      stakes[nftId].fId,
      stakes[nftId].rangeId,
      stakes[nftId].liquidity,
      stakes[nftId].lastSumRewardPerLiquidity,
      stakes[nftId].rewardUnclaimed
    );
  }

  // ======== internal ============
  /// @dev claim reward for nfts
  /// @param fId farm's id
  /// @param nftIds nfts for claim reward
  /// @param receiver reward receiver also msgSender
  function _claimReward(uint256 fId, uint256[] memory nftIds, address receiver) internal {
    uint256 nftLength = nftIds.length;

    //validate list of nft valid or not
    for (uint256 i; i < nftLength; ) {
      _isStakeValid(fId, nftIds[i]);
      unchecked {
        ++i;
      }
    }

    //update rewards for all nfts
    _updateRewardInfos(fId, nftIds);

    //accumulate rewards from stakes and transfer at once
    uint256 rewardLength = farms[fId].phase.rewards.length;
    uint256[] memory rewardAmounts = new uint256[](rewardLength);
    for (uint256 i; i < nftLength; ) {
      for (uint256 j; j < rewardLength; ) {
        rewardAmounts[j] += stakes[nftIds[i]].rewardUnclaimed[j];
        stakes[nftIds[i]].rewardUnclaimed[j] = 0;

        unchecked {
          ++j;
        }
      }

      unchecked {
        ++i;
      }
    }

    //transfer rewards
    for (uint256 i; i < rewardLength; ) {
      address token = farms[fId].phase.rewards[i].rewardToken;

      if (rewardAmounts[i] != 0) {
        _safeTransfer(token, receiver, rewardAmounts[i]);
      }

      emit ClaimReward(fId, nftIds, token, rewardAmounts[i], receiver);

      unchecked {
        ++i;
      }
    }
  }

  function _updateLiquidity(
    uint256 fId,
    uint256 nftId,
    uint256 newLiq,
    address receiver
  ) internal {
    //update farm sumReward
    uint256[] memory curSumRewardPerLiquidities = _updateFarmSumRewardPerLiquidity(fId);
    uint256 curLiq = stakes[nftId].liquidity;

    //update stake rewards base on lastest sumReward
    _updateRewardInfo(nftId, curLiq, curSumRewardPerLiquidities);

    address farmingToken = farms[fId].farmingToken;

    //mint/burn farmingToken base on the difference between newLiq/curLiq. there is no case that newLiq == curLiq
    if (newLiq > curLiq) {
      _mintFarmingToken(farmingToken, receiver, newLiq - curLiq);
    } else {
      _burnFarmingToken(farmingToken, receiver, curLiq - newLiq);
    }

    //update stake liquidity, farm total liquidity
    stakes[nftId].liquidity = newLiq;
    farms[fId].liquidity = farms[fId].liquidity + newLiq - curLiq;

    emit UpdateLiquidity(fId, nftId, newLiq);
  }

  /// @dev update rewardInfo for multiple stakes
  /// @param nftIds nfts to update
  function _updateRewardInfos(uint256 fId, uint256[] memory nftIds) internal {
    uint256[] memory curSumRewardPerLiquidities = _updateFarmSumRewardPerLiquidity(fId);
    uint256 length = nftIds.length;
    for (uint256 i; i < length; ) {
      _updateRewardInfo(nftIds[i], stakes[nftIds[i]].liquidity, curSumRewardPerLiquidities);

      unchecked {
        ++i;
      }
    }
  }

  /// @dev calculate and update rewardUnclaimed, lastSumRewardPerLiquidity for a single position
  /// @dev rewardAmount = (sumRewardPerLiq - lastSumRewardPerLiq) * stake.liquidiy
  /// @dev if transferRewardUnclaimed =  true then transfer all rewardUnclaimed, update rewardUnclaimed = 0
  /// @dev if transferRewardUnclaimed =  false then update rewardUnclaimed = rewardUnclaimed + rewardAmount
  /// @dev update lastSumRewardPerLiquidity
  /// @param nftId nft's id to update
  /// @param liquidity current staked liquidity
  /// @param curSumRewardPerLiquidities current sumRewardPerLiquidities of farm, indexing by reward
  function _updateRewardInfo(
    uint256 nftId,
    uint256 liquidity,
    uint256[] memory curSumRewardPerLiquidities
  ) internal {
    uint256 length = curSumRewardPerLiquidities.length;
    for (uint256 i; i < length; ) {
      if (liquidity != 0) {
        //calculate rewardAmount by formula rewardAmount = (sumRewardPerLiq - lastSumRewardPerLiq) * stake.liquidiy
        uint256 rewardAmount = LMMath.calcRewardAmount(
          curSumRewardPerLiquidities[i],
          stakes[nftId].lastSumRewardPerLiquidity[i],
          liquidity
        );

        //accumulate reward into stake rewards
        if (rewardAmount != 0) {
          stakes[nftId].rewardUnclaimed[i] += rewardAmount;
        }
      }

      //store new sumReward into stake
      stakes[nftId].lastSumRewardPerLiquidity[i] = curSumRewardPerLiquidities[i];

      unchecked {
        ++i;
      }
    }
  }

  /// @dev if block.timestamp > lastTouchedTime, update sumRewardPerLiquidity. Otherwise just return it
  /// @dev if block.timestamp > farm's endTime then update phase to settled
  /// @param fId farm's id
  /// @return curSumRewardPerLiquidity array of sumRewardPerLiquidity until now
  function _updateFarmSumRewardPerLiquidity(
    uint256 fId
  ) internal returns (uint256[] memory curSumRewardPerLiquidity) {
    uint256 length = farms[fId].phase.rewards.length;
    curSumRewardPerLiquidity = new uint256[](length);

    uint32 lastTouchedTime = farms[fId].lastTouchedTime;
    uint32 endTime = farms[fId].phase.endTime;
    bool isSettled = farms[fId].phase.isSettled;
    uint256 liquidity = farms[fId].liquidity;

    if (block.timestamp > lastTouchedTime) {
      for (uint256 i; i < length; ) {
        curSumRewardPerLiquidity[i] = farms[fId].sumRewardPerLiquidity[i];
        uint256 deltaSumRewardPerLiquidity;

        //calculate deltaSumReward incase there is any liquidity in farm and farm is not settled yet
        if (liquidity > 0 && !isSettled) {
          deltaSumRewardPerLiquidity = _calcDeltaSumRewardPerLiquidity(
            farms[fId].phase.rewards[i].rewardAmount,
            farms[fId].phase.startTime,
            endTime,
            lastTouchedTime,
            liquidity
          );
        }

        if (deltaSumRewardPerLiquidity != 0) {
          farms[fId].sumRewardPerLiquidity[i] =
            curSumRewardPerLiquidity[i] +
            deltaSumRewardPerLiquidity;

          curSumRewardPerLiquidity[i] += deltaSumRewardPerLiquidity;
        }

        unchecked {
          ++i;
        }
      }

      farms[fId].lastTouchedTime = uint32(block.timestamp);
    } else {
      for (uint256 i; i < length; ) {
        curSumRewardPerLiquidity[i] = farms[fId].sumRewardPerLiquidity[i];

        unchecked {
          ++i;
        }
      }
    }

    //if passed endTime, update phase to settled
    if (block.timestamp > endTime && !isSettled) farms[fId].phase.isSettled = true;
  }

  /// @dev get liquidity of nft from helper
  /// @param nftId nft's id
  /// @return liquidity current liquidity of nft
  function _getLiquidity(uint256 nftId) internal view returns (uint128 liquidity) {
    (, , , liquidity) = helper.getPositionInfo(address(nft), nftId);
  }

  /// @dev check multiple nfts it's valid
  /// @param poolAddress pool's address
  /// @param tickLower farm's tickLower
  /// @param tickUpper farm's tickUpper
  /// @param nftIds nfts to check
  function _checkPosition(
    address poolAddress,
    int24 tickLower,
    int24 tickUpper,
    uint256[] calldata nftIds
  ) internal view returns (bool isInvalid, uint128[] memory nftLiquidities) {
    (isInvalid, nftLiquidities) = helper.checkPosition(
      poolAddress,
      address(nft),
      tickLower,
      tickUpper,
      nftIds
    );
  }

  /// @dev remove liquidiy of nft from posManager
  /// @param nftId nft's id
  /// @param liquidity liquidity amount to remove
  /// @param deadline removeLiquidity deadline
  function _removeLiquidity(uint256 nftId, uint128 liquidity, uint256 deadline) internal {
    IBasePositionManager.RemoveLiquidityParams memory removeLiq = IBasePositionManager
      .RemoveLiquidityParams({
        tokenId: nftId,
        liquidity: liquidity,
        amount0Min: 0,
        amount1Min: 0,
        deadline: deadline
      });

    IBasePositionManager(address(nft)).removeLiquidity(removeLiq);
  }

  /// @dev claim fee of nft from posManager
  /// @param nftId nft's id
  /// @param deadline claimFee deadline
  /// @param syncFee is need to sync new fee or not
  function _claimFee(uint256 nftId, uint256 deadline, bool syncFee) internal {
    if (syncFee) {
      IBasePositionManager(address(nft)).syncFeeGrowth(nftId);
    }

    IBasePositionManager.BurnRTokenParams memory burnRToken = IBasePositionManager
      .BurnRTokenParams({tokenId: nftId, amount0Min: 0, amount1Min: 0, deadline: deadline});

    IBasePositionManager(address(nft)).burnRTokens(burnRToken);
  }

  /// @dev transfer tokens from removeLiquidity (and burnRToken if any) to receiver, also unwrap if needed
  /// @param poolAddress address of Elastic Pool
  /// @param amount0Min minimum amount of token0 should receive
  /// @param amount1Min minimum amount of token1 should receive
  /// @param receiver receiver of tokens
  function _transferTokens(
    address poolAddress,
    uint256 amount0Min,
    uint256 amount1Min,
    address receiver,
    bool isReceiveNative
  ) internal {
    address token0 = address(IPoolStorage(poolAddress).token0());
    address token1 = address(IPoolStorage(poolAddress).token1());
    IBasePositionManager posManager = IBasePositionManager(address(nft));

    if (isReceiveNative) {
      // expect to receive in native token
      if (weth == token0) {
        // receive in native for token0
        posManager.unwrapWeth(amount0Min, receiver);
        posManager.transferAllTokens(token1, amount1Min, receiver);
        return;
      }
      if (weth == token1) {
        // receive in native for token1
        posManager.transferAllTokens(token0, amount0Min, receiver);
        posManager.unwrapWeth(amount1Min, receiver);
        return;
      }
    }

    posManager.transferAllTokens(token0, amount0Min, receiver);
    posManager.transferAllTokens(token1, amount1Min, receiver);
  }

  function _safeTransfer(address token, address to, uint256 amount) internal {
    (bool success, ) = token == ETH_ADDRESS
      ? payable(to).call{value: amount}('')
      : token.call(abi.encodeWithSignature('transfer(address,uint256)', to, amount));

    require(success);
  }

  function _mintFarmingToken(address token, address to, uint256 amount) internal {
    IKyberSwapFarmingToken(token).mint(to, amount);
  }

  function _burnFarmingToken(address token, address from, uint256 amount) internal {
    IKyberSwapFarmingToken(token).burn(from, amount);
  }

  /// @dev calculate sumRewardPerLiquidity for each reward token
  /// @dev if block.timestamp > lastTouched means sumRewardPerLiquidity had increase
  /// @dev if not then just return it
  /// @param rewardAmount rewardAmount to calculate
  /// @param startTime farm's startTime
  /// @param endTime farm's endTime
  /// @param lastTouchedTime farm's lastTouchedTime
  /// @param totalLiquidity farm's total liquidity
  /// @return deltaSumRewardPerLiquidity from lastTouchedTime till now
  function _calcDeltaSumRewardPerLiquidity(
    uint256 rewardAmount,
    uint32 startTime,
    uint32 endTime,
    uint32 lastTouchedTime,
    uint256 totalLiquidity
  ) internal view returns (uint256 deltaSumRewardPerLiquidity) {
    deltaSumRewardPerLiquidity = LMMath.calcSumRewardPerLiquidity(
      rewardAmount,
      startTime,
      endTime,
      uint32(block.timestamp),
      lastTouchedTime,
      totalLiquidity
    );
  }

  /// @dev check if range is valid to be add to farm, revert on fail
  /// @param range range to check
  function _isRangeValid(RangeInput memory range) internal pure {
    if (range.tickLower > range.tickUpper || range.weight == 0) revert InvalidRange();
  }

  /// @dev check if phase is valid to be add to farm, revert on fail
  function _isPhaseValid(PhaseInput memory phase) internal view {
    if (phase.startTime < block.timestamp || phase.endTime <= phase.startTime)
      revert InvalidTime();

    if (phase.rewards.length == 0) revert InvalidReward();
  }

  /// @dev check if add liquidity conditions are meet or not, revert on fail
  /// @param fId farm's id
  function _isAddLiquidityValid(uint256 fId, uint256 rangeId) internal view {
    if (fId >= farmCount) revert FarmNotFound();
    if (rangeId >= farms[fId].ranges.length || farms[fId].ranges[rangeId].isRemoved)
      revert RangeNotFound();
    if (farms[fId].phase.endTime < block.timestamp || farms[fId].phase.isSettled)
      revert PhaseSettled();
    if (emergencyEnabled) revert EmergencyEnabled();
  }

  /// @dev check if stake update conditions are meet or not, revert on fail
  ///   check if the caller is the owner of the NFT and the stake data is valid
  /// @param fId farm's id
  /// @param nftId the NFT's id
  function _isStakeValid(uint256 fId, uint256 nftId) internal view {
    if (stakes[nftId].owner != msg.sender) revert NotOwner();
    if (stakes[nftId].fId != fId) revert StakeNotFound();
  }

  /// @dev check if stake add liquidity conditions are meet or not, revert on fail
  /// @param fId farm's id
  /// @param rangeId range's id
  /// @param nftId NFT's id
  function _isStakeValidForAddLiquidity(
    uint256 fId,
    uint256 rangeId,
    uint256 nftId
  ) internal view {
    _isStakeValid(fId, nftId);
    if (stakes[nftId].rangeId != rangeId) revert RangeNotMatch();
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

abstract contract KSAdmin {
  address public admin;
  mapping(address => bool) public operators; // address => bool

  event TransferAdmin(address indexed admin);
  event UpdateOperator(address indexed user, bool grantOrRevoke);

  modifier isAdmin() {
    require(msg.sender == admin, 'forbidden');
    _;
  }

  modifier isOperator() {
    require(operators[msg.sender], 'forbidden');
    _;
  }

  constructor() {
    admin = msg.sender;
    operators[msg.sender] = true;
  }

  function transferAdmin(address _admin) external virtual isAdmin {
    require(_admin != address(0), 'forbidden');

    admin = _admin;

    emit TransferAdmin(_admin);
  }

  function updateOperator(address user, bool grantOrRevoke) external isAdmin {
    operators[user] = grantOrRevoke;

    emit UpdateOperator(user, grantOrRevoke);
  }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.8.0;

interface IBasePositionManager {
  struct Position {
    // the nonce for permits
    uint96 nonce;
    // the address that is approved for spending this token
    address operator;
    // the ID of the pool with which this token is connected
    uint80 poolId;
    // the tick range of the position
    int24 tickLower;
    int24 tickUpper;
    // the liquidity of the position
    uint128 liquidity;
    // the current rToken that the position owed
    uint256 rTokenOwed;
    // fee growth per unit of liquidity as of the last update to liquidity
    uint256 feeGrowthInsideLast;
  }

  struct PoolInfo {
    address token0;
    uint16 fee;
    address token1;
  }

  struct MintParams {
    address token0;
    address token1;
    uint24 fee;
    int24 tickLower;
    int24 tickUpper;
    int24[2] ticksPrevious;
    uint256 amount0Desired;
    uint256 amount1Desired;
    uint256 amount0Min;
    uint256 amount1Min;
    address recipient;
    uint256 deadline;
  }

  struct IncreaseLiquidityParams {
    uint256 tokenId;
    uint256 amount0Desired;
    uint256 amount1Desired;
    uint256 amount0Min;
    uint256 amount1Min;
    uint256 deadline;
  }

  struct RemoveLiquidityParams {
    uint256 tokenId;
    uint128 liquidity;
    uint256 amount0Min;
    uint256 amount1Min;
    uint256 deadline;
  }

  struct BurnRTokenParams {
    uint256 tokenId;
    uint256 amount0Min;
    uint256 amount1Min;
    uint256 deadline;
  }

  function positions(
    uint256 tokenId
  ) external view returns (Position memory pos, PoolInfo memory info);

  function addressToPoolId(address pool) external view returns (uint80);

  function WETH() external view returns (address);

  function mint(
    MintParams calldata params
  )
    external
    payable
    returns (uint256 tokenId, uint128 liquidity, uint256 amount0, uint256 amount1);

  function addLiquidity(
    IncreaseLiquidityParams calldata params
  )
    external
    payable
    returns (uint128 liquidity, uint256 amount0, uint256 amount1, uint256 additionalRTokenOwed);

  function removeLiquidity(
    RemoveLiquidityParams calldata params
  ) external returns (uint256 amount0, uint256 amount1, uint256 additionalRTokenOwed);

  function syncFeeGrowth(uint256 tokenId) external returns (uint256 additionalRTokenOwed);

  function burnRTokens(
    BurnRTokenParams calldata params
  ) external returns (uint256 rTokenQty, uint256 amount0, uint256 amount1);

  function transferAllTokens(address token, uint256 minAmount, address recipient) external payable;

  function unwrapWeth(uint256 minAmount, address recipient) external payable;
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity >=0.8.0;

/// @title KyberSwap v2 factory
/// @notice Deploys KyberSwap v2 pools and manages control over government fees
interface IFactory {
  /// @notice Emitted when a pool is created
  /// @param token0 First pool token by address sort order
  /// @param token1 Second pool token by address sort order
  /// @param swapFeeBps Fee to be collected upon every swap in the pool, in basis points
  /// @param tickDistance Minimum number of ticks between initialized ticks
  /// @param pool The address of the created pool
  event PoolCreated(
    address indexed token0,
    address indexed token1,
    uint16 indexed swapFeeBps,
    int24 tickDistance,
    address pool
  );

  /// @notice Emitted when a new fee is enabled for pool creation via the factory
  /// @param swapFeeBps Fee to be collected upon every swap in the pool, in basis points
  /// @param tickDistance Minimum number of ticks between initialized ticks for pools created with the given fee
  event SwapFeeEnabled(uint16 indexed swapFeeBps, int24 indexed tickDistance);

  /// @notice Emitted when vesting period changes
  /// @param vestingPeriod The maximum time duration for which LP fees
  /// are proportionally burnt upon LP removals
  event VestingPeriodUpdated(uint32 vestingPeriod);

  /// @notice Emitted when configMaster changes
  /// @param oldConfigMaster configMaster before the update
  /// @param newConfigMaster configMaster after the update
  event ConfigMasterUpdated(address oldConfigMaster, address newConfigMaster);

  /// @notice Emitted when fee configuration changes
  /// @param feeTo Recipient of government fees
  /// @param governmentFeeBps Fee amount, in basis points,
  /// to be collected out of the fee charged for a pool swap
  event FeeConfigurationUpdated(address feeTo, uint16 governmentFeeBps);

  /// @notice Emitted when whitelist feature is enabled
  event WhitelistEnabled();

  /// @notice Emitted when whitelist feature is disabled
  event WhitelistDisabled();

  /// @notice Returns the maximum time duration for which LP fees
  /// are proportionally burnt upon LP removals
  function vestingPeriod() external view returns (uint32);

  /// @notice Returns the tick distance for a specified fee.
  /// @dev Once added, cannot be updated or removed.
  /// @param swapFeeBps Swap fee, in basis points.
  /// @return The tick distance. Returns 0 if fee has not been added.
  function feeAmountTickDistance(uint16 swapFeeBps) external view returns (int24);

  /// @notice Returns the address which can update the fee configuration
  function configMaster() external view returns (address);

  /// @notice Returns the keccak256 hash of the Pool creation code
  /// This is used for pre-computation of pool addresses
  function poolInitHash() external view returns (bytes32);

  /// @notice Fetches the recipient of government fees
  /// and current government fee charged in basis points
  function feeConfiguration() external view returns (address _feeTo, uint16 _governmentFeeBps);

  /// @notice Returns the status of whitelisting feature of NFT managers
  /// If true, anyone can mint liquidity tokens
  /// Otherwise, only whitelisted NFT manager(s) are allowed to mint liquidity tokens
  function whitelistDisabled() external view returns (bool);

  //// @notice Returns all whitelisted NFT managers
  /// If the whitelisting feature is turned on,
  /// only whitelisted NFT manager(s) are allowed to mint liquidity tokens
  function getWhitelistedNFTManagers() external view returns (address[] memory);

  /// @notice Checks if sender is a whitelisted NFT manager
  /// If the whitelisting feature is turned on,
  /// only whitelisted NFT manager(s) are allowed to mint liquidity tokens
  /// @param sender address to be checked
  /// @return true if sender is a whistelisted NFT manager, false otherwise
  function isWhitelistedNFTManager(address sender) external view returns (bool);

  /// @notice Returns the pool address for a given pair of tokens and a swap fee
  /// @dev Token order does not matter
  /// @param tokenA Contract address of either token0 or token1
  /// @param tokenB Contract address of the other token
  /// @param swapFeeBps Fee to be collected upon every swap in the pool, in basis points
  /// @return pool The pool address. Returns null address if it does not exist
  function getPool(
    address tokenA,
    address tokenB,
    uint16 swapFeeBps
  ) external view returns (address pool);

  /// @notice Fetch parameters to be used for pool creation
  /// @dev Called by the pool constructor to fetch the parameters of the pool
  /// @return factory The factory address
  /// @return token0 First pool token by address sort order
  /// @return token1 Second pool token by address sort order
  /// @return swapFeeBps Fee to be collected upon every swap in the pool, in basis points
  /// @return tickDistance Minimum number of ticks between initialized ticks
  function parameters()
    external
    view
    returns (
      address factory,
      address token0,
      address token1,
      uint16 swapFeeBps,
      int24 tickDistance
    );

  /// @notice Creates a pool for the given two tokens and fee
  /// @param tokenA One of the two tokens in the desired pool
  /// @param tokenB The other of the two tokens in the desired pool
  /// @param swapFeeBps Desired swap fee for the pool, in basis points
  /// @dev Token order does not matter. tickDistance is determined from the fee.
  /// Call will revert under any of these conditions:
  ///     1) pool already exists
  ///     2) invalid swap fee
  ///     3) invalid token arguments
  /// @return pool The address of the newly created pool
  function createPool(
    address tokenA,
    address tokenB,
    uint16 swapFeeBps
  ) external returns (address pool);

  /// @notice Enables a fee amount with the given tickDistance
  /// @dev Fee amounts may never be removed once enabled
  /// @param swapFeeBps The fee amount to enable, in basis points
  /// @param tickDistance The distance between ticks to be enforced for all pools created with the given fee amount
  function enableSwapFee(uint16 swapFeeBps, int24 tickDistance) external;

  /// @notice Updates the address which can update the fee configuration
  /// @dev Must be called by the current configMaster
  function updateConfigMaster(address) external;

  /// @notice Updates the vesting period
  /// @dev Must be called by the current configMaster
  function updateVestingPeriod(uint32) external;

  /// @notice Updates the address receiving government fees and fee quantity
  /// @dev Only configMaster is able to perform the update
  /// @param feeTo Address to receive government fees collected from pools
  /// @param governmentFeeBps Fee amount, in basis points,
  /// to be collected out of the fee charged for a pool swap
  function updateFeeConfiguration(address feeTo, uint16 governmentFeeBps) external;

  /// @notice Enables the whitelisting feature
  /// @dev Only configMaster is able to perform the update
  function enableWhitelist() external;

  /// @notice Disables the whitelisting feature
  /// @dev Only configMaster is able to perform the update
  function disableWhitelist() external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IBasePositionManager} from './IBasePositionManager.sol';
import {IKSElasticLMV2 as IELMV2} from './IKSElasticLMV2.sol';
import {IKyberSwapFarmingToken} from './periphery/IKyberSwapFarmingToken.sol';

interface IKSElasticLMHelper {
  struct UserInfo {
    uint256 nftId;
    uint256 fId;
    uint256 rangeId;
    uint256 liquidity;
    uint256[] currentUnclaimedRewards;
  }

  //use by both LMv1 and LMv2
  function checkPool(
    address pAddress,
    address nftContract,
    uint256 nftId
  ) external view returns (bool);

  function getLiq(address nftContract, uint256 nftId) external view returns (uint128);

  function getPair(address nftContract, uint256 nftId) external view returns (address, address);

  //use by LMv1
  function getActiveTime(
    address pAddr,
    address nftContract,
    uint256 nftId
  ) external view returns (uint128);

  function getSignedFee(address nftContract, uint256 nftId) external view returns (int256);

  function getSignedFeePool(
    address poolAddress,
    address nftContract,
    uint256 nftId
  ) external view returns (int256);

  //use by LMv2
  function getCurrentUnclaimedReward(
    IELMV2 farm,
    uint256 nftId
  ) external view returns (uint256[] memory currentUnclaimedRewards);

  function getUserInfo(IELMV2 farm, address user) external view returns (UserInfo[] memory);

  function getEligibleRanges(
    IELMV2 farm,
    uint256 fId,
    uint256 nftId
  ) external view returns (uint256[] memory indexesValid);

  function checkPosition(
    address pAddress,
    address nftContract,
    int24 tickLower,
    int24 tickUpper,
    uint256[] memory nftIds
  ) external view returns (bool isInvalid, uint128[] memory liquidities);

  function getPositionInfo(
    address nftContract,
    uint256 nftId
  ) external view returns (uint256, int24, int24, uint128);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import {IERC20} from '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import {IERC721} from '@openzeppelin/contracts/token/ERC721/IERC721.sol';
import {IKyberSwapFarmingToken} from './periphery/IKyberSwapFarmingToken.sol';
import {IKSElasticLMHelper} from './IKSElasticLMHelper.sol';

interface IKSElasticLMV2 {
  error Forbidden();
  error EmergencyEnabled();

  error InvalidRange();
  error InvalidTime();
  error InvalidReward();

  error PositionNotEligible();
  error FarmNotFound();
  error InvalidFarm();
  error NotOwner();
  error StakeNotFound();
  error RangeNotMatch();
  error RangeNotFound();
  error PhaseSettled();
  error InvalidInput();
  error LiquidityNotMatch();
  error FailToAdd();
  error FailToRemove();
  error Expired();

  event UpdateEmergency(bool enableOrDisable);
  event UpdateTokenCode(bytes farmingTokenCode);
  event UpdateHelper(IKSElasticLMHelper helper);
  event WithdrawUnusedRewards(address token, uint256 amount, address receiver);

  event AddFarm(
    uint256 indexed fId,
    address poolAddress,
    RangeInput[] ranges,
    PhaseInput phase,
    address farmingToken
  );
  event AddPhase(uint256 indexed fId, PhaseInput phase);
  event ForceClosePhase(uint256 indexed fId);
  event AddRange(uint256 indexed fId, RangeInput range);
  event RemoveRange(uint256 indexed fId, uint256 rangeId);
  event ExpandEndTimeAndRewards(uint256 indexed fId, uint256 duration, uint256[] rewardAmounts);

  event Deposit(
    uint256 indexed fId,
    uint256 rangeId,
    uint256[] nftIds,
    address indexed depositer,
    address receiver
  );
  event UpdateLiquidity(uint256 indexed fId, uint256 nftId, uint256 liquidity);
  event Withdraw(uint256[] nftIds, address receiver);
  event WithdrawEmergency(uint256 nftId, address receiver);
  event ClaimReward(
    uint256 fId,
    uint256[] nftIds,
    address token,
    uint256 amount,
    address receiver
  );

  struct RangeInput {
    int24 tickLower;
    int24 tickUpper;
    uint32 weight;
  }

  struct RewardInput {
    address rewardToken;
    uint256 rewardAmount;
  }

  struct PhaseInput {
    uint32 startTime;
    uint32 endTime;
    RewardInput[] rewards;
  }

  struct RemoveLiquidityInput {
    uint256 nftId;
    uint128 liquidity;
  }

  struct RangeInfo {
    int24 tickLower;
    int24 tickUpper;
    uint32 weight;
    bool isRemoved;
  }

  struct PhaseInfo {
    uint32 startTime;
    uint32 endTime;
    bool isSettled;
    RewardInput[] rewards;
  }

  struct FarmInfo {
    address poolAddress;
    RangeInfo[] ranges;
    PhaseInfo phase;
    uint256 liquidity;
    address farmingToken;
    uint256[] sumRewardPerLiquidity;
    uint32 lastTouchedTime;
  }

  struct StakeInfo {
    address owner;
    uint256 fId;
    uint256 rangeId;
    uint256 liquidity;
    uint256[] lastSumRewardPerLiquidity;
    uint256[] rewardUnclaimed;
  }

  // ======== user ============
  /// @dev deposit nfts to farm
  /// @dev store curRewardPerLiq now to stake info, mint an amount of farmingToken (if needed) to msg.sender
  /// @param fId farm's id
  /// @param rangeId rangeId to add, should use quoter to get best APR rangeId
  /// @param nftIds nfts to deposit
  function deposit(
    uint256 fId,
    uint256 rangeId,
    uint256[] memory nftIds,
    address receiver
  ) external;

  /// @dev claim reward earned for nfts
  /// @param fId farm's id
  /// @param nftIds nfts to claim
  function claimReward(uint256 fId, uint256[] memory nftIds) external;

  /// @dev withdraw nfts from farm
  /// @dev only can call by nfts's owner, also claim reward earned
  /// @dev burn an amount of farmingToken (if needed) from msg.sender
  /// @param fId farm's id
  /// @param nftIds nfts to withdraw
  function withdraw(uint256 fId, uint256[] memory nftIds) external;

  /// @dev add liquidity of nfts when liquidity already added on Elastic Pool
  /// @dev only can call by nfts's owner
  /// @dev calculate reward earned, update stakeInfo, mint an amount of farmingToken to msg.sender
  /// @param fId farm's id
  /// @param rangeId rangeId of deposited nfts
  /// @param nftIds nfts to add liquidity
  function addLiquidity(uint256 fId, uint256 rangeId, uint256[] calldata nftIds) external;

  /// @dev remove liquidity of nfts from Elastic Pool
  /// @dev only can call by nfts's owner
  /// @dev calculate reward earned, update stakeInfo, mint/burn an amount of farmingToken
  /// @param nftId id of nft to remove liquidity
  /// @param liquidity amount to remove from nft
  /// @param amount0Min min amount of token0 should receive
  /// @param amount1Min min amount of token1 should receive
  /// @param deadline deadline of remove liquidity tx
  /// @param isClaimFee is also burnRTokens or not
  function removeLiquidity(
    uint256 nftId,
    uint128 liquidity,
    uint256 amount0Min,
    uint256 amount1Min,
    uint256 deadline,
    bool isClaimFee,
    bool isReceiveNative
  ) external;

  /// @dev claim fee from Elastic Pool
  /// @dev only can call by nfts's owner
  /// @param fId farm's id
  /// @param nftIds nfts to claim
  /// @param amount0Min min amount of token0 should receive
  /// @param amount1Min min amount of token1 should receive
  /// @param deadline deadline of remove liquidity tx
  function claimFee(
    uint256 fId,
    uint256[] calldata nftIds,
    uint256 amount0Min,
    uint256 amount1Min,
    uint256 deadline,
    bool isReceiveNative
  ) external;

  /// @dev withdraw nfts in case emergency
  /// @dev only can call by nfts's owner
  /// @dev in normal case, abandon all rewards, must return farmingToken
  /// @dev incase emergencyEnabled, bypass all calculation
  /// @param nftIds nfts to withdraw
  function withdrawEmergency(uint256[] calldata nftIds) external;

  // ======== view ============

  function getAdmin() external view returns (address);

  function getNft() external view returns (IERC721);

  function getFarm(
    uint256 fId
  )
    external
    view
    returns (
      address poolAddress,
      RangeInfo[] memory ranges,
      PhaseInfo memory phase,
      uint256 liquidity,
      address farmingToken,
      uint256[] memory sumRewardPerLiquidity,
      uint32 lastTouchedTime
    );

  function getDepositedNFTs(address user) external view returns (uint256[] memory listNFTs);

  function getStake(
    uint256 nftId
  )
    external
    view
    returns (
      address owner,
      uint256 fId,
      uint256 rangeId,
      uint256 liquidity,
      uint256[] memory lastSumRewardPerLiquidity,
      uint256[] memory rewardUnclaimeds
    );
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity >=0.8.0;

import {IERC20} from '@openzeppelin/contracts/token/ERC20/IERC20.sol';

import {IFactory} from './IFactory.sol';

interface IPoolStorage {
  struct PoolData {
    uint160 sqrtP;
    int24 nearestCurrentTick;
    int24 currentTick;
    bool locked;
    uint128 baseL;
    uint128 reinvestL;
    uint128 reinvestLLast;
    uint256 feeGrowthGlobal;
    uint128 secondsPerLiquidityGlobal;
    uint32 secondsPerLiquidityUpdateTime;
  }

  // data stored for each initialized individual tick
  struct TickData {
    // gross liquidity of all positions in tick
    uint128 liquidityGross;
    // liquidity quantity to be added | removed when tick is crossed up | down
    int128 liquidityNet;
    // fee growth per unit of liquidity on the other side of this tick (relative to current tick)
    // only has relative meaning, not absolute — the value depends on when the tick is initialized
    uint256 feeGrowthOutside;
    // seconds spent on the other side of this tick (relative to current tick)
    // only has relative meaning, not absolute — the value depends on when the tick is initialized
    uint128 secondsPerLiquidityOutside;
  }

  /// @notice The contract that deployed the pool, which must adhere to the IFactory interface
  /// @return The contract address
  function factory() external view returns (IFactory);

  /// @notice The first of the two tokens of the pool, sorted by address
  /// @return The token contract address
  function token0() external view returns (IERC20);

  /// @notice The second of the two tokens of the pool, sorted by address
  /// @return The token contract address
  function token1() external view returns (IERC20);

  /// @notice The fee to be charged for a swap in basis points
  /// @return The swap fee in basis points
  function swapFeeBps() external view returns (uint16);

  /// @notice The pool tick distance
  /// @dev Ticks can only be initialized and used at multiples of this value
  /// It remains an int24 to avoid casting even though it is >= 1.
  /// e.g: a tickDistance of 5 means ticks can be initialized every 5th tick, i.e., ..., -10, -5, 0, 5, 10, ...
  /// @return The tick distance
  function tickDistance() external view returns (int24);

  /// @notice Maximum gross liquidity that an initialized tick can have
  /// @dev This is to prevent overflow the pool's active base liquidity (uint128)
  /// also prevents out-of-range liquidity from being used to prevent adding in-range liquidity to a pool
  /// @return The max amount of liquidity per tick
  function maxTickLiquidity() external view returns (uint128);

  /// @notice Look up information about a specific tick in the pool
  /// @param tick The tick to look up
  /// @return liquidityGross total liquidity amount from positions that uses this tick as a lower or upper tick
  /// liquidityNet how much liquidity changes when the pool tick crosses above the tick
  /// feeGrowthOutside the fee growth on the other side of the tick relative to the current tick
  /// secondsPerLiquidityOutside the seconds spent on the other side of the tick relative to the current tick
  function ticks(
    int24 tick
  )
    external
    view
    returns (
      uint128 liquidityGross,
      int128 liquidityNet,
      uint256 feeGrowthOutside,
      uint128 secondsPerLiquidityOutside
    );

  /// @notice Returns the previous and next initialized ticks of a specific tick
  /// @dev If specified tick is uninitialized, the returned values are zero.
  /// @param tick The tick to look up
  function initializedTicks(int24 tick) external view returns (int24 previous, int24 next);

  /// @notice Returns the information about a position by the position's key
  /// @return liquidity the liquidity quantity of the position
  /// @return feeGrowthInsideLast fee growth inside the tick range as of the last mint / burn action performed
  function getPositions(
    address owner,
    int24 tickLower,
    int24 tickUpper
  ) external view returns (uint128 liquidity, uint256 feeGrowthInsideLast);

  /// @notice Fetches the pool's prices, ticks and lock status
  /// @return sqrtP sqrt of current price: sqrt(token1/token0)
  /// @return currentTick pool's current tick
  /// @return nearestCurrentTick pool's nearest initialized tick that is <= currentTick
  /// @return locked true if pool is locked, false otherwise
  function getPoolState()
    external
    view
    returns (uint160 sqrtP, int24 currentTick, int24 nearestCurrentTick, bool locked);

  /// @notice Fetches the pool's liquidity values
  /// @return baseL pool's base liquidity without reinvest liqudity
  /// @return reinvestL the liquidity is reinvested into the pool
  /// @return reinvestLLast last cached value of reinvestL, used for calculating reinvestment token qty
  function getLiquidityState()
    external
    view
    returns (uint128 baseL, uint128 reinvestL, uint128 reinvestLLast);

  /// @return feeGrowthGlobal All-time fee growth per unit of liquidity of the pool
  function getFeeGrowthGlobal() external view returns (uint256);

  /// @return secondsPerLiquidityGlobal All-time seconds per unit of liquidity of the pool
  /// @return lastUpdateTime The timestamp in which secondsPerLiquidityGlobal was last updated
  function getSecondsPerLiquidityData()
    external
    view
    returns (uint128 secondsPerLiquidityGlobal, uint32 lastUpdateTime);

  /// @notice Calculates and returns the active time per unit of liquidity until current block.timestamp
  /// @param tickLower The lower tick (of a position)
  /// @param tickUpper The upper tick (of a position)
  /// @return secondsPerLiquidityInside active time (multiplied by 2^96)
  /// between the 2 ticks, per unit of liquidity.
  function getSecondsPerLiquidityInside(
    int24 tickLower,
    int24 tickUpper
  ) external view returns (uint128 secondsPerLiquidityInside);
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity >=0.8.0;

import '@openzeppelin/contracts/access/IAccessControl.sol';

interface IKyberSwapFarmingToken is IAccessControl {
  /**
   * @dev Returns the amount of tokens in existence.
   */
  function totalSupply() external view returns (uint256);

  /**
   * @dev Returns the amount of tokens owned by `account`.
   */
  function balanceOf(address account) external view returns (uint256);

  /**
   * @dev Moves `amount` tokens from the caller's account to `recipient`.
   *
   * Returns a boolean value indicating whether the operation succeeded.
   *
   * Emits a {Transfer} event.
   */
  function transfer(address recipient, uint256 amount) external returns (bool);

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
   * @dev Moves `amount` tokens from `sender` to `recipient` using the
   * allowance mechanism. `amount` is then deducted from the caller's
   * allowance.
   *
   * Returns a boolean value indicating whether the operation succeeded.
   *
   * Emits a {Transfer} event.
   */
  function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

  /** @dev Creates `amount` tokens and assigns them to `account`, increasing
   * the total supply.
   *
   * Emits a {Transfer} event with `from` set to the zero address.
   *
   * Requirements:
   *
   * - `account` cannot be the zero address.
   */
  function mint(address account, uint256 amount) external;

  /**
   * @dev Destroys `amount` tokens from the caller.
   *
   * See {ERC20-_burn}.
   */

  function burn(address account, uint256 amount) external;

  function addWhitelist(address account) external;

  function removeWhitelist(address account) external;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import {MathConstants as C} from './MathConstants.sol';

library LMMath {
  function calcSumRewardPerLiquidity(
    uint256 rewardAmount,
    uint32 startTime,
    uint32 endTime,
    uint32 curTime,
    uint32 lastTouchedTime,
    uint256 totalLiquidity
  ) internal pure returns (uint256 deltaSumRewardPerLiquidity) {
    uint256 joinedDuration;
    uint256 duration;

    unchecked {
      joinedDuration = (curTime < endTime ? curTime : endTime) - lastTouchedTime;
      duration = endTime - startTime;
      deltaSumRewardPerLiquidity =
        (rewardAmount * joinedDuration * C.TWO_POW_96) /
        (duration * totalLiquidity);
    }
  }

  function calcRewardAmount(
    uint256 curSumRewardPerLiquidity,
    uint256 lastSumRewardPerLiquidity,
    uint256 liquidity
  ) internal pure returns (uint256 rewardAmount) {
    uint256 deltaSumRewardPerLiquidity;

    unchecked {
      deltaSumRewardPerLiquidity = curSumRewardPerLiquidity - lastSumRewardPerLiquidity;
      rewardAmount = (deltaSumRewardPerLiquidity * liquidity) / C.TWO_POW_96;
    }
  }

  function calcRewardUntilNow(
    uint256 rewardAmount,
    uint32 startTime,
    uint32 endTime,
    uint32 curTime
  ) internal pure returns (uint256 rewardAmountNow) {
    uint256 joinedDuration;
    uint256 duration;

    unchecked {
      joinedDuration = curTime - startTime;
      duration = endTime - startTime;
      rewardAmountNow = (rewardAmount * joinedDuration) / duration;
    }
  }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity >=0.8.0;

/// @title Contains constants needed for math libraries
library MathConstants {
  uint256 internal constant TWO_POW_48 = 2 ** 48;
  uint256 internal constant TWO_POW_96 = 2 ** 96;
  uint128 internal constant MIN_LIQUIDITY = 100_000;
  uint24 internal constant FEE_UNITS = 100_000;
  uint8 internal constant RES_96 = 96;
}

// SPDX-License-Identifier: MIT

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
     * by making the `nonReentrant` function external, and make it call a
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
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
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

pragma solidity ^0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;
        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping(bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastvalue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastvalue;
                // Update the index for the moved value
                set._indexes[lastvalue] = valueIndex; // Replace lastvalue's index to valueIndex
            }

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        return set._values[index];
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(Bytes32Set storage set) internal view returns (bytes32[] memory) {
        return _values(set._inner);
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(AddressSet storage set) internal view returns (address[] memory) {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

        assembly {
            result := store
        }

        return result;
    }

    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(UintSet storage set) internal view returns (uint256[] memory) {
        bytes32[] memory store = _values(set._inner);
        uint256[] memory result;

        assembly {
            result := store
        }

        return result;
    }
}