// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./abstract/AbstractLiquidityMiningStaking.sol";

contract LiquidityMiningStakingETH is AbstractLiquidityMiningStaking {
    function __LiquidityMiningStakingETH_init() external initializer {
        __LiquidityMiningStaking_init();
    }

    function setDependencies(IContractsRegistry _contractsRegistry)
        external
        override
        onlyInjectorOrZero
    {
        deinToken = IERC20(_contractsRegistry.getDEINContract());
        deinStaking = IDEINStaking(_contractsRegistry.getDEINStakingContract());
        stakingToken = IERC20(_contractsRegistry.getAMMDEINToETHPairContract());
        rewardPool = _contractsRegistry.getRewardPoolContract();
        compoundPool = ICompoundPool(_contractsRegistry.getCompoundPoolContract());
        ammRouter = IUniswapV2Router02(_contractsRegistry.getAMMRouterContract());
        stblDecimals = IERC20Metadata(_contractsRegistry.getUSDTContract()).decimals();
        priceFeed = IPriceFeed(_contractsRegistry.getPriceFeedContract());
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "../interfaces/imports/IUniswapV2Router02.sol";
import "../interfaces/imports/IUniswapV2Pair.sol";

import "../interfaces/IDEINStaking.sol";
import "../interfaces/ILiquidityMiningStaking.sol";
import "../interfaces/tokens/erc20permit-upgradeable/IERC20PermitUpgradeable.sol";

import "../libraries/DecimalsConverter.sol";

import "./AbstractStaking.sol";

abstract contract AbstractLiquidityMiningStaking is AbstractStaking, ILiquidityMiningStaking {
    using EnumerableSet for EnumerableSet.UintSet;
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    IERC20 public stakingToken;
    IDEINStaking public deinStaking;
    IUniswapV2Router02 public ammRouter;

    uint256 public stblDecimals;

    function __LiquidityMiningStaking_init() internal onlyInitializing {
        __Staking_init();
    }

    function stakeWithPermit(
        uint256 _amount,
        uint256 _lock,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) external override nonReentrant {
        require(_amount > 0, "LMS: Amount should be greater than 0");
        IERC20PermitUpgradeable(address(stakingToken)).permit(
            _msgSender(),
            address(this),
            _amount,
            MAX_INT,
            _v,
            _r,
            _s
        );

        stakingToken.safeTransferFrom(_msgSender(), address(this), _amount);
        _stake(_msgSender(), _amount, _lock);
    }

    function stake(uint256 _amount, uint256 _lock) external override nonReentrant {
        require(_amount > 0, "LMS: Amount should be greater than 0");

        stakingToken.safeTransferFrom(_msgSender(), address(this), _amount);
        _stake(_msgSender(), _amount, _lock);
    }

    //@dve provide ETH/DEIN liquidity to Uniswap V2 pool
    // sender must approve the contract to spend his DEIN
    ///@param _amountTokenDesired uint256 the amount of DEIN at the ideal ratio according to the price
    ///@param _amountETHDesired uint256 the amount of ETH add as a liquidity
    ///@param _amountTokenMin uint256 the minimum amount of DEIN that user will pay , 1% tolerance level
    ///@param _amountETHMin uint256 the minimum amount of ETH that user will pay , 1% tolerance level
    ///@param _lock uint256 the locking period of staked amount
    function provideLiquidity(
        uint256 _amountTokenDesired,
        uint256 _amountETHDesired,
        uint256 _amountTokenMin,
        uint256 _amountETHMin,
        uint256 _lock
    ) external payable override nonReentrant {
        require(
            _amountETHMin > 0 &&
                _amountETHMin <= _amountETHDesired &&
                msg.value == _amountETHDesired,
            "LMS: Invalid ETH amount"
        );
        require(
            _amountTokenMin > 0 && _amountTokenMin <= _amountTokenDesired,
            "LMS: Invalid DEIN amount"
        );
        // transfer dein to the contract
        deinToken.safeTransferFrom(_msgSender(), address(this), _amountTokenDesired);
        // approve AMM router
        deinToken.safeApprove(address(ammRouter), 0);
        deinToken.safeApprove(address(ammRouter), _amountTokenDesired);

        (uint256 amountToken, uint256 amountETH, uint256 liquidityAmount) =
            ammRouter.addLiquidityETH{value: msg.value}(
                address(deinToken),
                _amountTokenDesired,
                _amountTokenMin,
                _amountETHMin,
                address(this),
                type(uint256).max
            );
        // refund user of unprovided token
        if (_amountTokenDesired > amountToken) {
            deinToken.safeTransfer(_msgSender(), _amountTokenDesired.uncheckedSub(amountToken));
        }
        // refund user of unprovided ETH
        if (_amountETHDesired > amountETH) {
            (bool success, ) =
                _msgSender().call{value: _amountETHDesired.uncheckedSub(amountETH)}(new bytes(0));
            require(success, "LMS: ETH transfer failed");
        }

        emit ProvidedLiquidity(_msgSender(), amountToken, amountETH, liquidityAmount);
        // stake for the user
        _stake(_msgSender(), liquidityAmount, _lock);
    }

    function withdraw(uint256 _stakingIndex)
        external
        override
        nonReentrant
        updateReward(_stakingIndex)
    {
        require(ownerOf(_stakingIndex) == _msgSender(), "LMS: Not a staking owner");

        require(canWithdraw(_stakingIndex), "LMS: Withdrawal is not ready");

        uint256 _stakedAmount = stakers[_stakingIndex].staked;

        require(
            compoundPool.canWithdraw(_getAmountbyLiquidation(_stakedAmount), true),
            "LMS: Not allowed"
        );

        uint256 _amount = _withdraw(_stakingIndex, _stakedAmount);
        uint256 reward = _getReward(_stakingIndex);

        // remove staking info
        stakerStaking[_msgSender()].remove(_stakingIndex);
        delete stakers[_stakingIndex];

        //claim reward
        if (reward > 0) {
            _claimReward(reward);
        }

        stakingToken.safeTransfer(_msgSender(), _amount);

        emit Withdrawn(_msgSender(), _stakingIndex, _amount, reward);
    }

    function claimReward(uint256[] memory _tokenIds) external override nonReentrant {
        uint256 reward = _calculateReward(_tokenIds);

        if (reward > 0) {
            _claimReward(reward);
        }
    }

    function _claimReward(uint256 _reward) internal {
        deinToken.safeTransfer(_msgSender(), _reward);
    }

    /// @dev if _stakingPosition new , the _stakingPositionInput should be locking period
    /// otherwise should be tokenId of native staking
    function restakeReward(
        uint256[] memory _tokenIds,
        uint256 _stakingPositionInput,
        StakingPosition _stakingPosition
    ) external override nonReentrant {
        uint256 reward = _calculateReward(_tokenIds);

        if (reward > 0) {
            // stake dein in dein native staking for the user
            deinToken.safeTransfer(address(deinStaking), reward);

            deinStaking.stakeFor(
                _msgSender(),
                reward,
                _stakingPositionInput,
                _stakingPosition,
                false
            );
        }
    }

    ///@dev accessed by compound pool
    function liquidate(
        uint256 _liquidationAmount,
        uint256 _amountTokenMin,
        uint256 _amountETHMin,
        address _receiver
    ) external override onlyCompoundPool {
        if (_liquidationAmount <= totalPool && _amountTokenMin > 0 && _amountETHMin > 0) {
            liquidationAmount = liquidationAmount.add(_liquidationAmount);

            // approve AMM router
            stakingToken.safeApprove(address(ammRouter), 0);
            stakingToken.safeApprove(address(ammRouter), _liquidationAmount);

            (uint256 amountToken, uint256 amountETH) =
                ammRouter.removeLiquidityETH(
                    address(deinToken),
                    _liquidationAmount,
                    _amountTokenMin,
                    _amountETHMin,
                    _receiver,
                    type(uint256).max
                );

            emit Liquidated(_liquidationAmount, amountToken, amountETH, _receiver);
        }
    }

    function _stake(
        address _user,
        uint256 _amount,
        uint256 _lock
    ) internal updateReward(stakingIndex) checkLockingPeriod(_lock, false) {
        totalPool = totalPool.add(_amount);

        uint256 multiplier = stakedMultipliers[_lock];

        totalPoolWithPower = totalPoolWithPower.add(_amount.mul(multiplier));
        stakers[stakingIndex].staker = _user;
        stakers[stakingIndex].staked = _amount;
        stakers[stakingIndex].startTime = block.timestamp;
        stakers[stakingIndex].lockingPeriod = _lock;

        stakerStaking[_user].add(stakingIndex);

        emit Staked(_user, stakingIndex, _amount, _lock);

        stakingIndex = stakingIndex.tryAdd(1);
    }

    /// @notice returns APY% with 10**5 precision
    /// Max (General) APY
    function getAPY() external view override returns (uint256) {
        // multiply by Multiplier=5
        uint256 _initialStaked = INITIAL_STAKED_AMOUNT_LP.mul(5);

        uint256 _totalPoolWithPower = totalPoolWithPower;

        if (_totalPoolWithPower == 0) {
            _totalPoolWithPower = _initialStaked;
        }

        uint256 _reward =
            rewardPerBlock.mul(BLOCKS_PER_YEAR).mul(_initialStaked).uncheckedDiv(
                _totalPoolWithPower
            );

        return
            DecimalsConverter
                .convertTo18(priceFeed.howManyUSDTsInDEIN(_reward), stblDecimals)
                .mul(10**7)
                .tryDiv(
                compoundPool.getDEINLPTokenPrice().mul(INITIAL_STAKED_AMOUNT_LP).uncheckedDiv(
                    DECIMALS18
                )
            );
    }

    /// @notice returns APY% with 10**5 precision
    /// position APY
    function getPositionAPY(uint256 _stakingIndex) external view override returns (uint256) {
        uint256 _staked = stakers[_stakingIndex].staked;
        uint256 _multiplier = getStakerMultiplier(_stakingIndex);

        uint256 _reward =
            rewardPerBlock.mul(BLOCKS_PER_YEAR).mul(_staked.mul(_multiplier)).tryDiv(
                totalPoolWithPower
            );

        return
            DecimalsConverter
                .convertTo18(priceFeed.howManyUSDTsInDEIN(_reward), stblDecimals)
                .mul(10**7)
                .tryDiv(compoundPool.getDEINLPTokenPrice().mul(_staked).uncheckedDiv(DECIMALS18));
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

import "../interfaces/IContractsRegistry.sol";
import "../interfaces/IStaking.sol";
import "../interfaces/ICompoundPool.sol";
import "../interfaces/helpers/IPriceFeed.sol";
import "../libraries/SafeMath.sol";

import "./AbstractDependant.sol";

import "../Globals.sol";

abstract contract AbstractStaking is
    IStaking,
    OwnableUpgradeable,
    ReentrancyGuardUpgradeable,
    AbstractDependant
{
    using EnumerableSet for EnumerableSet.UintSet;
    using SafeMath for uint256;
    using Math for uint256;
    using SafeERC20 for IERC20;

    uint256 public constant Locking24Month = 24;

    uint256[] public override lockingPeriods; // in months
    bool internal isDeinStaking;

    IERC20 public deinToken;
    ICompoundPool public compoundPool;
    IPriceFeed public priceFeed;

    address public rewardPool;

    uint256 public override rewardPerBlock;
    uint256 public firstBlockWithReward;
    uint256 public lastBlockWithReward;
    uint256 public lastUpdateBlock;
    uint256 public rewardPerTokenStored;
    uint256 public rewardTokensLocked;

    uint256 public totalPool; // use for liquidation
    uint256 public override totalPoolWithPower; // use for rewards
    uint256 public liquidationAmount; // use for liquidation

    uint256 internal stakingIndex; // next stake index for lp staking / next nft mint id for dein staking

    mapping(uint256 => uint256) public stakedMultipliers; // stake duration (months) => multiplier , for staker
    mapping(uint256 => StakingInfo) public stakers; // staking index or nft id => staking info

    mapping(address => EnumerableSet.UintSet) internal stakerStaking; // staker -> staking index or nft id

    modifier updateReward(uint256 _stakingIndex) {
        _updateReward(_stakingIndex);
        _;
    }

    modifier onlyRewardPool() {
        require(_msgSender() == rewardPool, "Staking : Not allowed");
        _;
    }

    modifier onlyCompoundPool() {
        require(_msgSender() == address(compoundPool), "Staking: Not allowed");
        _;
    }

    modifier checkLockingPeriod(uint256 _lock, bool _isVesting) {
        if (_isVesting) {
            require(
                _lock == lockingPeriods[3] || _lock == lockingPeriods[4],
                "Staking: invalid locking period for vesting"
            );
        } else
            require(
                _lock == lockingPeriods[0] ||
                    _lock == lockingPeriods[1] ||
                    _lock == lockingPeriods[2] ||
                    _lock == lockingPeriods[3] ||
                    _lock == lockingPeriods[4],
                "Staking: invalid locking period"
            );
        _;
    }

    function __Staking_init() internal onlyInitializing {
        __Ownable_init();

        lockingPeriods = [1, 6, 12, 24, 36];
        stakingIndex = 1;
        _setStakedMultiplier();
    }

    function _setStakedMultiplier() internal {
        stakedMultipliers[1] = 1;
        stakedMultipliers[6] = 2;
        stakedMultipliers[12] = 3;
        stakedMultipliers[24] = 4;
        stakedMultipliers[36] = 5;
    }

    function _withdraw(uint256 _stakingIndex, uint256 _amount)
        internal
        returns (uint256 stakedByLiquidiation)
    {
        stakedByLiquidiation = _amount;

        if (liquidationAmount > 0) {
            stakedByLiquidiation = _getAmountbyLiquidation(_amount);

            liquidationAmount = liquidationAmount.sub(_amount.sub(stakedByLiquidiation));
        }

        totalPool = totalPool.sub(_amount);

        if (stakingHasBenefits(_stakingIndex))
            totalPoolWithPower = totalPoolWithPower.sub(
                _amount.mul(getStakerMultiplier(_stakingIndex))
            );
    }

    function _calculateReward(uint256[] memory _stakingIndexes) internal returns (uint256 reward) {
        for (uint256 i = 0; i < _stakingIndexes.length; i = uncheckedInc(i)) {
            uint256 _stakingIndex = _stakingIndexes[i];
            require(ownerOf(_stakingIndex) == _msgSender(), "Staking: Not a staking owner");

            _updateReward(_stakingIndex);

            uint256 _reward = _getReward(_stakingIndex);
            reward = reward.add(_reward);
        }
    }

    function _getReward(uint256 _stakingIndex) internal returns (uint256 _reward) {
        _reward = stakers[_stakingIndex].rewards;

        if (_reward > 0) {
            stakers[_stakingIndex].rewards = 0;
            rewardTokensLocked = rewardTokensLocked.sub(_reward);
            emit RewardPaid(stakers[_stakingIndex].staker, _stakingIndex, _reward);
        }
    }

    function whenCanWithdraw(uint256 _stakingIndex) external view returns (uint256) {
        uint256 _endTime =
            stakers[_stakingIndex].startTime.tryAdd(
                stakers[_stakingIndex].lockingPeriod.tryMul(PERIOD_DURATION)
            );

        return _endTime >= block.timestamp ? _endTime : 0;
    }

    function canWithdraw(uint256 _stakingIndex) public view override returns (bool) {
        uint256 _endTime =
            stakers[_stakingIndex].startTime.tryAdd(
                stakers[_stakingIndex].lockingPeriod.tryMul(PERIOD_DURATION)
            );

        return _endTime < block.timestamp;
    }

    // staked amount stored
    function getFullStakedAmount(uint256 _stakingIndex) public view override returns (uint256) {
        return stakers[_stakingIndex].staked;
    }

    // staked amount stored
    function getFullStakedAmounts(uint256[] calldata _stakingIndexes)
        external
        view
        override
        returns (uint256 totalStaked)
    {
        for (uint256 i = 0; i < _stakingIndexes.length; i = uncheckedInc(i)) {
            uint256 _stakingIndex = _stakingIndexes[i];
            totalStaked = totalStaked.add(getFullStakedAmount(_stakingIndex));
        }
    }

    function getTotalStakedAmountByStaker(address _user)
        external
        view
        override
        returns (uint256 totalStaked, uint256 totalStakedByLiquidation)
    {
        for (uint256 i = 0; i < stakerStaking[_user].length(); i = uncheckedInc(i)) {
            uint256 _stakingIndex = stakerStaking[_user].at(i);
            uint256 _staked = stakers[_stakingIndex].staked;
            totalStaked = totalStaked.add(_staked);
            totalStakedByLiquidation = totalStakedByLiquidation.add(
                _getAmountbyLiquidation(_staked)
            );
        }
    }

    ///@dev return the amount affected by liquidation
    function _getAmountbyLiquidation(uint256 _amount) internal view returns (uint256) {
        uint256 userLiquidationAmount = liquidationAmount.mul(_amount).tryDiv(totalPool);

        return _amount.sub(userLiquidationAmount);
    }

    ///@dev get pool liquidity in tokens
    function getPoolLiquidity() external view override returns (uint256) {
        return totalPool.trySub(liquidationAmount);
    }

    function getStakerMultiplier(uint256 _stakingIndex) public view override returns (uint256) {
        return stakedMultipliers[stakers[_stakingIndex].lockingPeriod];
    }

    function getStakerLockingDuration(uint256 _stakingIndex)
        public
        view
        override
        returns (uint256)
    {
        return stakers[_stakingIndex].lockingPeriod;
    }

    ///@dev durations should passed in days * PRECISION
    function setRewards(uint256 _amount, uint256 _durations)
        external
        override
        onlyRewardPool
        updateReward(0)
    {
        uint256 _unlockedTokens = _getFutureRewardTokens();

        uint256 _blocksAmount = _durations.mul(BLOCKS_PER_DAY).div(PRECISION);

        rewardPerBlock = _amount.add(_unlockedTokens).uncheckedDiv(_blocksAmount);
        firstBlockWithReward = block.number;
        lastBlockWithReward = block.number.tryAdd(_blocksAmount).uncheckedSub(1);

        uint256 _lockedTokens = _getFutureRewardTokens();
        rewardTokensLocked = rewardTokensLocked.sub(_unlockedTokens).add(_lockedTokens);

        uint256 _totalStakedAmount;
        if (isDeinStaking) {
            _totalStakedAmount = totalPool.sub(liquidationAmount);
        }
        require(
            rewardTokensLocked <= deinToken.balanceOf(address(this)).sub(_totalStakedAmount),
            "Staking: Not enough tokens for the rewards"
        );

        emit RewardsSet(rewardPerBlock, firstBlockWithReward, lastBlockWithReward);
    }

    function recoverNonLockedRewardTokens() external onlyOwner {
        uint256 _totalStakedAmount;
        if (isDeinStaking) {
            _totalStakedAmount = totalPool.sub(liquidationAmount);
        }
        uint256 nonLockedTokens =
            deinToken.balanceOf(address(this)).sub(rewardTokensLocked).sub(_totalStakedAmount);

        if (nonLockedTokens > 0) {
            deinToken.safeTransfer(owner(), nonLockedTokens);

            emit RewardTokensRecovered(nonLockedTokens);
        }
    }

    function blocksWithRewardsPassed() public view returns (uint256) {
        uint256 from = Math.max(lastUpdateBlock, firstBlockWithReward);
        uint256 to = Math.min(block.number, lastBlockWithReward);

        return to.trySub(from);
    }

    function rewardPerToken() public view returns (uint256) {
        uint256 totalPoolStaked = totalPoolWithPower;

        if (totalPoolStaked == 0) {
            return rewardPerTokenStored;
        }

        uint256 accumulatedReward =
            blocksWithRewardsPassed().mul(rewardPerBlock).mul(DECIMALS18).uncheckedDiv(
                totalPoolStaked
            );

        return rewardPerTokenStored.add(accumulatedReward);
    }

    function earned(uint256 _stakingIndex) public view override returns (uint256) {
        if (!stakingHasBenefits(_stakingIndex)) return 0;

        StakingInfo memory info = stakers[_stakingIndex];

        uint256 rewardsDifference = rewardPerToken().sub(info.rewardPerTokenPaid);

        uint256 newlyAccumulated =
            info
                .staked
                .mul(getStakerMultiplier(_stakingIndex))
                .mul(rewardsDifference)
                .uncheckedDiv(DECIMALS18);

        return info.rewards.add(newlyAccumulated);
    }

    function _updateReward(uint256 _stakingIndex) internal {
        uint256 currentRewardPerToken = rewardPerToken();

        rewardPerTokenStored = currentRewardPerToken;
        lastUpdateBlock = block.number;

        if (_stakingIndex != 0 && stakingHasBenefits(_stakingIndex)) {
            stakers[_stakingIndex].rewards = earned(_stakingIndex);
            stakers[_stakingIndex].rewardPerTokenPaid = currentRewardPerToken;
        }
    }

    /// @notice vesting user of 24 lock will not get benefits (voting mulipliter , policy discount)
    function stakingHasBenefits(uint256 _stakingIndex) public view override returns (bool) {
        return
            !(stakers[_stakingIndex].isVesting &&
                stakers[_stakingIndex].lockingPeriod == Locking24Month);
    }

    function _getFutureRewardTokens() internal view returns (uint256) {
        uint256 blocksLeft = _calculateBlocksLeft(firstBlockWithReward, lastBlockWithReward);

        return blocksLeft.mul(rewardPerBlock);
    }

    function _calculateBlocksLeft(uint256 _from, uint256 _to) internal view returns (uint256) {
        if (block.number >= _to) return 0;

        if (block.number < _from) return _to.sub(_from).tryAdd(1);

        return _to.uncheckedSub(block.number);
    }

    /// @notice returns number of staks/NFT on user's account
    function balanceOf(address user) public view override returns (uint256) {
        return stakerStaking[user].length();
    }

    function ownerOf(uint256 _stakingIndex) public view override returns (address) {
        return stakers[_stakingIndex].staker;
    }

    function tokenOfOwnerByIndex(address user, uint256 index)
        public
        view
        override
        returns (uint256)
    {
        return stakerStaking[user].at(index);
    }

    /// @dev use with balanceOf()
    function getStakingInfoByStaker(
        address staker,
        uint256 offset,
        uint256 limit
    ) external view override returns (PublicStakingInfo[] memory _stakingInfo) {
        uint256 to = (offset.tryAdd(limit)).min(stakerStaking[staker].length()).max(offset);
        _stakingInfo = new PublicStakingInfo[](to.uncheckedSub(offset));

        for (uint256 i = offset; i < to; i = uncheckedInc(i)) {
            uint256 _stakingIndex = stakerStaking[staker].at(i);
            _stakingInfo[i.uncheckedSub(offset)] = getStakingInfoByIndex(_stakingIndex);
        }
    }

    /// @notice Returns a StakingInfo for a given staking/nft index
    function getStakingInfoByIndex(uint256 _stakingIndex)
        public
        view
        override
        returns (PublicStakingInfo memory)
    {
        StakingInfo memory info = stakers[_stakingIndex];
        return
            PublicStakingInfo(
                _stakingIndex,
                info.staked,
                _getAmountbyLiquidation(info.staked),
                info.startTime,
                info.startTime.tryAdd(info.lockingPeriod.tryMul(PERIOD_DURATION)),
                info.lockingPeriod,
                getStakerMultiplier(_stakingIndex),
                earned(_stakingIndex),
                info.isVesting
            );
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "./IStaking.sol";

interface IDEINStaking {
    event StakedNFTMinted(uint256 nftMintId, address indexed recipient);
    event StakedNFTBurned(uint256 tokenId, address indexed recipient);
    event CLAIMED(uint256 claimedDEIN, uint256 tokenId, address indexed recipient);
    event VoterPenaltyApplied(uint256 penaltyAmount, uint256 tokenId);

    struct VestingInfo {
        uint256 locked;
        uint256 claimed;
    }

    function stakeFor(
        address _user,
        uint256 _amountDEIN,
        uint256 _stakingPositionInput,
        IStaking.StakingPosition _stakingPosition,
        bool _isVesting
    ) external;

    function claim(uint256 _tokenId, uint256 _amount) external;

    function applyVoterPenalty(
        uint256[] calldata _tokenIds,
        uint256[] calldata _penaltyAmounts,
        address user
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

interface ILiquidityMiningStaking {
    event ProvidedLiquidity(
        address indexed user,
        uint256 amountToken,
        uint256 amountETH,
        uint256 liquidityAmount
    );

    function provideLiquidity(
        uint256 _amountTokenDesired,
        uint256 _amountETHDesired,
        uint256 _amountTokenMin,
        uint256 _amountETHMin,
        uint256 _lock
    ) external payable;

    function getAPY() external view returns (uint256);

    function getPositionAPY(uint256 _tokenId) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

interface IUniswapV2Router02 {
    function getAmountsOut(uint256 amountIn, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);

    function addLiquidityETH(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    )
        external
        payable
        returns (
            uint256 amountToken,
            uint256 amountETH,
            uint256 liquidity
        );

    function removeLiquidityETH(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountToken, uint256 amountETH);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "../libraries/SafeMath.sol";

/// @notice the intention of this library is to be able to easily convert
///     one amount of tokens with N decimal places
///     to another amount with M decimal places
library DecimalsConverter {
    using SafeMath for uint256;

    function convert(
        uint256 amount,
        uint256 baseDecimals,
        uint256 destinationDecimals
    ) internal pure returns (uint256) {
        if (baseDecimals > destinationDecimals) {
            amount = amount.uncheckedDiv(10**(baseDecimals.uncheckedSub(destinationDecimals)));
        } else if (baseDecimals < destinationDecimals) {
            amount = amount.mul(10**(destinationDecimals.uncheckedSub(baseDecimals)));
        }

        return amount;
    }

    function convertTo18(uint256 amount, uint256 baseDecimals) internal pure returns (uint256) {
        if (baseDecimals == 18) return amount;
        return convert(amount, baseDecimals, 18);
    }

    function convertFrom18(uint256 amount, uint256 destinationDecimals)
        internal
        pure
        returns (uint256)
    {
        if (destinationDecimals == 18) return amount;
        return convert(amount, 18, destinationDecimals);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

interface IUniswapV2Pair {
    function token0() external view returns (address);

    function token1() external view returns (address);

    function totalSupply() external view returns (uint256);

    function getReserves()
        external
        view
        returns (
            uint112 reserve0,
            uint112 reserve1,
            uint32 blockTimestampLast
        );
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

/**
 * COPIED FROM https://github.com/OpenZeppelin/openzeppelin-contracts-upgradeable/tree/release-v4.5/contracts/drafts
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20PermitUpgradeable {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

uint256 constant SECONDS_IN_THE_YEAR = 365 * 24 * 60 * 60; // 365 days * 24 hours * 60 minutes * 60 seconds
uint256 constant SECONDS_IN_THE_MONTH = 30 * 24 * 60 * 60; // 30 days * 24 hours * 60 minutes * 60 seconds
uint256 constant DAYS_IN_THE_YEAR = 365;
uint256 constant MAX_INT = type(uint256).max;

uint256 constant DECIMALS18 = 10**18;

uint256 constant INITIAL_STAKED_AMOUNT = 100 * DECIMALS18;
uint256 constant INITIAL_STAKED_AMOUNT_LP = 1 * DECIMALS18;

uint256 constant PRECISION = 10**25;
uint256 constant PERCENTAGE_100 = 100 * PRECISION;

uint256 constant BLOCKS_PER_DAY = 7200;
uint256 constant BLOCKS_PER_YEAR = BLOCKS_PER_DAY * 365;

uint256 constant BLOCKS_PER_DAY_BSC = 28800;
uint256 constant BLOCKS_PER_DAY_POLYGON = 43200;

uint256 constant APY_TOKENS = DECIMALS18;

uint256 constant ACTIVE_REWARD_PERCENTAGE = 80 * PRECISION;
uint256 constant CLOSED_REWARD_PERCENTAGE = 1 * PRECISION;

uint256 constant DEFAULT_REBALANCING_THRESHOLD = 10**23;

uint256 constant EPOCH_DAYS_AMOUNT = 7;

// ClaimVoting ClaimingRegistry
uint256 constant APPROVAL_PERCENTAGE = 66 * PRECISION;
uint256 constant PENALTY_THRESHOLD = 11 * PRECISION;
uint256 constant QUORUM = 10 * PRECISION;
uint256 constant CALCULATION_REWARD_PER_DAY = PRECISION;
uint256 constant PERCENTAGE_50 = 50 * PRECISION;
uint256 constant PENALTY_PERCENTAGE = 10 * PRECISION;
uint256 constant UNEXPOSED_PERCENTAGE = 1 * PRECISION;

// PolicyBook
uint256 constant MINUMUM_COVERAGE = 100 * DECIMALS18; // 100 STBL
uint256 constant ANNUAL_COVERAGE_TOKENS = MINUMUM_COVERAGE * 10; // 1000 STBL

uint256 constant PREMIUM_DISTRIBUTION_EPOCH = 1 days;
uint256 constant MAX_PREMIUM_DISTRIBUTION_EPOCHS = 90;
// policy
uint256 constant EPOCH_DURATION = 1 weeks;
uint256 constant MAXIMUM_EPOCHS = SECONDS_IN_THE_YEAR / EPOCH_DURATION;
uint256 constant MAXIMUM_EPOCHS_FOR_COMPOUND_LIQUIDITY = 5; //5 epoch
uint256 constant VIRTUAL_EPOCHS = 1;
// demand
uint256 constant DEMAND_EPOCH_DURATION = 1 days;
uint256 constant DEMAND_MAXIMUM_EPOCHS = SECONDS_IN_THE_YEAR / DEMAND_EPOCH_DURATION;
uint256 constant MINIMUM_EPOCHS = SECONDS_IN_THE_MONTH / DEMAND_EPOCH_DURATION;

uint256 constant PERIOD_DURATION = 30 days;

enum Networks {ETH, BSC, POL}

/// @dev unchecked increment
function uncheckedInc(uint256 i) pure returns (uint256) {
    unchecked {return i + 1;}
}

/// @dev unchecked decrement
function uncheckedDec(uint256 i) pure returns (uint256) {
    unchecked {return i - 1;}
}

function getBlocksPerDay(Networks _currentNetwork) pure returns (uint256 _blockPerDays) {
    if (_currentNetwork == Networks.ETH) {
        _blockPerDays = BLOCKS_PER_DAY;
    } else if (_currentNetwork == Networks.BSC) {
        _blockPerDays = BLOCKS_PER_DAY_BSC;
    } else if (_currentNetwork == Networks.POL) {
        _blockPerDays = BLOCKS_PER_DAY_POLYGON;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "../Globals.sol";

interface IContractsRegistry {
    function currentNetwork() external view returns (Networks);

    function getAMMRouterContract() external view returns (address);

    function getAMMDEINToETHPairContract() external view returns (address);

    function getPriceFeedContract() external view returns (address);

    function getWETHContract() external view returns (address);

    function getUSDTContract() external view returns (address);

    function getBMIContract() external view returns (address);

    function getDEINContract() external view returns (address);

    function getPolicyBookRegistryContract() external view returns (address);

    function getPolicyBookFabricContract() external view returns (address);

    function getBMICoverStakingContract() external view returns (address);

    function getBMICoverStakingViewContract() external view returns (address);

    function getBMITreasury() external view returns (address);

    function getDEINTreasuryContract() external view returns (address);

    function getRewardsGeneratorContract() external view returns (address);

    function getLiquidityBridgeContract() external view returns (address);

    function getClaimingRegistryContract() external view returns (address);

    function getPolicyRegistryContract() external view returns (address);

    function getLiquidityRegistryContract() external view returns (address);

    function getClaimVotingContract() external view returns (address);

    function getRewardPoolContract() external view returns (address);

    function getCompoundPoolContract() external view returns (address);

    function getLeveragePortfolioViewContract() external view returns (address);

    function getCapitalPoolContract() external view returns (address);

    function getPolicyBookAdminContract() external view returns (address);

    function getPolicyQuoteContract() external view returns (address);

    function getBMIStakingContract() external view returns (address);

    function getDEINStakingContract() external view returns (address);

    function getDEINStakingViewContract() external view returns (address);

    function getDEINNFTStakingContract() external view returns (address);

    function getSTKBMIContract() external view returns (address);

    function getStkBMIStakingContract() external view returns (address);

    function getLiquidityMiningStakingETHContract() external view returns (address);

    function getLiquidityMiningStakingUSDTContract() external view returns (address);

    function getReputationSystemContract() external view returns (address);

    function getDefiProtocol1Contract() external view returns (address);

    function getAaveLendPoolAddressProvdierContract() external view returns (address);

    function getAaveATokenContract() external view returns (address);

    function getDefiProtocol2Contract() external view returns (address);

    function getCompoundCTokenContract() external view returns (address);

    function getCompoundComptrollerContract() external view returns (address);

    function getDefiProtocol3Contract() external view returns (address);

    function getYearnVaultContract() external view returns (address);

    function getYieldGeneratorContract() external view returns (address);

    function getShieldMiningContract() external view returns (address);

    function getDemandBookContract() external view returns (address);

    function getDemandBookLiquidityContract() external view returns (address);

    function getSwapEventContract() external view returns (address);

    function getVestingContract() external view returns (address);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

interface IStaking {
    event RewardsSet(
        uint256 rewardPerBlock,
        uint256 firstBlockWithReward,
        uint256 lastBlockWithReward
    );
    event RewardTokensRecovered(uint256 amount);

    event Staked(address indexed user, uint256 stakingIndex, uint256 amount, uint256 lock);
    event Withdrawn(
        address indexed user,
        uint256 stakingIndex,
        uint256 amountByLiquidation,
        uint256 reward
    );

    event Liquidated(
        uint256 liquidationAmount,
        uint256 amountToken,
        uint256 amountETH,
        address indexed receiver
    );
    event RewardPaid(address indexed user, uint256 stakingIndex, uint256 reward);
    event AddedToStake(address indexed user, uint256 stakingIndex, uint256 amount);

    struct StakingInfo {
        address staker;
        uint256 staked;
        uint256 startTime;
        uint256 lockingPeriod;
        uint256 rewards;
        uint256 rewardPerTokenPaid;
        bool isVesting;
    }

    struct PublicStakingInfo {
        uint256 stakingId;
        uint256 staked;
        uint256 stakedByLiquidation;
        uint256 startTime;
        uint256 endTime;
        uint256 lockingPeriod;
        uint256 stakingMultiplier;
        uint256 rewards;
        bool isVesting;
    }

    enum StakingPosition {NEW, CURRENT}

    function rewardPerBlock() external view returns (uint256);

    function totalPoolWithPower() external view returns (uint256);

    function lockingPeriods(uint256 index) external view returns (uint256);

    function stakeWithPermit(
        uint256 _amount,
        uint256 _lock,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) external;

    function stake(uint256 _amount, uint256 _lock) external;

    function withdraw(uint256 _stakingIndex) external;

    function claimReward(uint256[] memory _tokenIds) external;

    function restakeReward(
        uint256[] memory _tokenIds,
        uint256 _stakingPositionInput,
        StakingPosition _stakingPosition
    ) external;

    function liquidate(
        uint256 _liquidationAmount,
        uint256 _amountTokenMin,
        uint256 _amountETHMin,
        address _receiver
    ) external;

    function getPoolLiquidity() external view returns (uint256);

    function setRewards(uint256 _amount, uint256 _durations) external;

    function getFullStakedAmount(uint256 _stakingIndex) external view returns (uint256);

    // staked amount stored
    function getFullStakedAmounts(uint256[] calldata _stakingIndexes)
        external
        view
        returns (uint256 totalStaked);

    function canWithdraw(uint256 _stakingIndex) external view returns (bool);

    function balanceOf(address user) external view returns (uint256);

    function ownerOf(uint256 _stakingIndex) external view returns (address);

    function tokenOfOwnerByIndex(address user, uint256 index) external view returns (uint256);

    function getStakingInfoByStaker(
        address staker,
        uint256 offset,
        uint256 limit
    ) external view returns (PublicStakingInfo[] memory _stakingInfo);

    function getTotalStakedAmountByStaker(address _user)
        external
        view
        returns (uint256 totalStaked, uint256 totalStakedByLiquidation);

    function getStakingInfoByIndex(uint256 _stakingIndex)
        external
        view
        returns (PublicStakingInfo memory);

    function stakingHasBenefits(uint256 _stakingIndex) external view returns (bool);

    function getStakerMultiplier(uint256 _stakingIndex) external view returns (uint256);

    function getStakerLockingDuration(uint256 _stakingIndex) external view returns (uint256);

    function earned(uint256 _nftId) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/math/SafeMath.sol)

pragma solidity ^0.8.7;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * COPIED FROM https://github.com/OpenZeppelin/openzeppelin-contracts/blob/release-v4.5/contracts/utils/math/SafeMath.sol
 * customize try functions to return one value which is uint256 instead of return tupple
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
    function tryAdd(uint256 a, uint256 b) internal pure returns (uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return 0;
            return c;
        }
    }

    function uncheckedAdd(uint256 a, uint256 b) internal pure returns (uint256) {
        unchecked {return a + b;}
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (uint256) {
        unchecked {
            if (b > a) return 0;
            return a - b;
        }
    }

    function uncheckedSub(uint256 a, uint256 b) internal pure returns (uint256) {
        unchecked {return a - b;}
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return 0;
            uint256 c = a * b;
            if (c / a != b) return 0;
            return c;
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        unchecked {
            if (b == 0) return 0;
            return a / b;
        }
    }

    function uncheckedDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        unchecked {return a / b;}
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (uint256) {
        unchecked {
            if (b == 0) return 0;
            return a % b;
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
pragma solidity ^0.8.7;

interface ICompoundPool {
    function getCompoundLiquidity() external view returns (uint256);

    function poolsUsage(address _policyBook) external view returns (uint256);

    function getCompoundLiquidityForPool(address _policyBookAddress)
        external
        view
        returns (uint256);

    function deployLiquidity(address _policyBook, uint256 _amount) external;

    function undeployLiquidity(address _policyBook, uint256 _amount) external;

    function canWithdraw(uint256 _withdrawAmount, bool isLPToken) external view returns (bool);

    function getDEINLPTokenPrice() external view returns (uint256);

    function liquidate(
        address _policyBook,
        address claimer,
        uint256 liquidationAmount
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "../interfaces/IContractsRegistry.sol";

abstract contract AbstractDependant {
    /// @dev keccak256(AbstractDependant.setInjector(address)) - 1
    bytes32 private constant _INJECTOR_SLOT =
        0xd6b8f2e074594ceb05d47c27386969754b6ad0c15e5eb8f691399cd0be980e76;

    modifier onlyInjectorOrZero() {
        address _injector = injector();

        require(_injector == address(0) || _injector == msg.sender, "Dependant: Not an injector");
        _;
    }

    function setInjector(address _injector) external onlyInjectorOrZero {
        bytes32 slot = _INJECTOR_SLOT;

        assembly {
            sstore(slot, _injector)
        }
    }

    /// @dev has to apply onlyInjectorOrZero() modifier
    function setDependencies(IContractsRegistry) external virtual;

    function injector() public view returns (address _injector) {
        bytes32 slot = _INJECTOR_SLOT;

        assembly {
            _injector := sload(slot)
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

interface IPriceFeed {
    enum Token {DEIN, ETH}

    function howManyDEINsInUSDT(uint256 usdtAmount) external view returns (uint256);

    function howManyUSDTsInDEIN(uint256 deinAmount) external view returns (uint256);

    function howManyETHsInUSDT(uint256 usdtAmount) external view returns (uint256);

    function howManyUSDTsInETH(uint256 ethAmount) external view returns (uint256);

    function updateTokensPrice() external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ReentrancyGuardUpgradeable is Initializable {
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

    function __ReentrancyGuard_init() internal onlyInitializing {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal onlyInitializing {
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

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
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal onlyInitializing {
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal onlyInitializing {
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    enum Rounding {
        Down, // Toward negative infinity
        Up, // Toward infinity
        Zero // Toward zero
    }

    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a == 0 ? 0 : (a - 1) / b + 1;
    }

    /**
     * @notice Calculates floor(x * y / denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
     * @dev Original credit to Remco Bloemen under MIT license (https://xn--2-umb.com/21/muldiv)
     * with further edits by Uniswap Labs also under MIT license.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        unchecked {
            // 512-bit multiply [prod1 prod0] = x * y. Compute the product mod 2^256 and mod 2^256 - 1, then use
            // use the Chinese Remainder Theorem to reconstruct the 512 bit result. The result is stored in two 256
            // variables such that product = prod1 * 2^256 + prod0.
            uint256 prod0; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(x, y, not(0))
                prod0 := mul(x, y)
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }

            // Handle non-overflow cases, 256 by 256 division.
            if (prod1 == 0) {
                return prod0 / denominator;
            }

            // Make sure the result is less than 2^256. Also prevents denominator == 0.
            require(denominator > prod1);

            ///////////////////////////////////////////////
            // 512 by 256 division.
            ///////////////////////////////////////////////

            // Make division exact by subtracting the remainder from [prod1 prod0].
            uint256 remainder;
            assembly {
                // Compute remainder using mulmod.
                remainder := mulmod(x, y, denominator)

                // Subtract 256 bit number from 512 bit number.
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
            }

            // Factor powers of two out of denominator and compute largest power of two divisor of denominator. Always >= 1.
            // See https://cs.stackexchange.com/q/138556/92363.

            // Does not overflow because the denominator cannot be zero at this stage in the function.
            uint256 twos = denominator & (~denominator + 1);
            assembly {
                // Divide denominator by twos.
                denominator := div(denominator, twos)

                // Divide [prod1 prod0] by twos.
                prod0 := div(prod0, twos)

                // Flip twos such that it is 2^256 / twos. If twos is zero, then it becomes one.
                twos := add(div(sub(0, twos), twos), 1)
            }

            // Shift in bits from prod1 into prod0.
            prod0 |= prod1 * twos;

            // Invert denominator mod 2^256. Now that denominator is an odd number, it has an inverse modulo 2^256 such
            // that denominator * inv = 1 mod 2^256. Compute the inverse by starting with a seed that is correct for
            // four bits. That is, denominator * inv = 1 mod 2^4.
            uint256 inverse = (3 * denominator) ^ 2;

            // Use the Newton-Raphson iteration to improve the precision. Thanks to Hensel's lifting lemma, this also works
            // in modular arithmetic, doubling the correct bits in each step.
            inverse *= 2 - denominator * inverse; // inverse mod 2^8
            inverse *= 2 - denominator * inverse; // inverse mod 2^16
            inverse *= 2 - denominator * inverse; // inverse mod 2^32
            inverse *= 2 - denominator * inverse; // inverse mod 2^64
            inverse *= 2 - denominator * inverse; // inverse mod 2^128
            inverse *= 2 - denominator * inverse; // inverse mod 2^256

            // Because the division is now exact we can divide by multiplying with the modular inverse of denominator.
            // This will give us the correct result modulo 2^256. Since the preconditions guarantee that the outcome is
            // less than 2^256, this is the final result. We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inverse;
            return result;
        }
    }

    /**
     * @notice Calculates x * y / denominator with full precision, following the selected rounding direction.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator,
        Rounding rounding
    ) internal pure returns (uint256) {
        uint256 result = mulDiv(x, y, denominator);
        if (rounding == Rounding.Up && mulmod(x, y, denominator) > 0) {
            result += 1;
        }
        return result;
    }

    /**
     * @dev Returns the square root of a number. If the number is not a perfect square, the value is rounded down.
     *
     * Inspired by Henry S. Warren, Jr.'s "Hacker's Delight" (Chapter 11).
     */
    function sqrt(uint256 a) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        // For our first guess, we get the biggest power of 2 which is smaller than the square root of the target.
        //
        // We know that the "msb" (most significant bit) of our target number `a` is a power of 2 such that we have
        // `msb(a) <= a < 2*msb(a)`. This value can be written `msb(a)=2**k` with `k=log2(a)`.
        //
        // This can be rewritten `2**log2(a) <= a < 2**(log2(a) + 1)`
        // → `sqrt(2**k) <= sqrt(a) < sqrt(2**(k+1))`
        // → `2**(k/2) <= sqrt(a) < 2**((k+1)/2) <= 2**(k/2 + 1)`
        //
        // Consequently, `2**(log2(a) / 2)` is a good first approximation of `sqrt(a)` with at least 1 correct bit.
        uint256 result = 1 << (log2(a) >> 1);

        // At this point `result` is an estimation with one bit of precision. We know the true value is a uint128,
        // since it is the square root of a uint256. Newton's method converges quadratically (precision doubles at
        // every iteration). We thus need at most 7 iteration to turn our partial result with one bit of precision
        // into the expected uint128 result.
        unchecked {
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            return min(result, a / result);
        }
    }

    /**
     * @notice Calculates sqrt(a), following the selected rounding direction.
     */
    function sqrt(uint256 a, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = sqrt(a);
            return result + (rounding == Rounding.Up && result * result < a ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 2, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 128;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 64;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 32;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 16;
            }
            if (value >> 8 > 0) {
                value >>= 8;
                result += 8;
            }
            if (value >> 4 > 0) {
                value >>= 4;
                result += 4;
            }
            if (value >> 2 > 0) {
                value >>= 2;
                result += 2;
            }
            if (value >> 1 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 2, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log2(value);
            return result + (rounding == Rounding.Up && 1 << result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 10, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >= 10**64) {
                value /= 10**64;
                result += 64;
            }
            if (value >= 10**32) {
                value /= 10**32;
                result += 32;
            }
            if (value >= 10**16) {
                value /= 10**16;
                result += 16;
            }
            if (value >= 10**8) {
                value /= 10**8;
                result += 8;
            }
            if (value >= 10**4) {
                value /= 10**4;
                result += 4;
            }
            if (value >= 10**2) {
                value /= 10**2;
                result += 2;
            }
            if (value >= 10**1) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log10(value);
            return result + (rounding == Rounding.Up && 10**result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 256, rounded down, of a positive value.
     * Returns 0 if given 0.
     *
     * Adding one to the result gives the number of pairs of hex symbols needed to represent `value` as a hex string.
     */
    function log256(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 16;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 8;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 4;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 2;
            }
            if (value >> 8 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log256(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log256(value);
            return result + (rounding == Rounding.Up && 1 << (result * 8) < value ? 1 : 0);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/structs/EnumerableSet.sol)
// This file was procedurally generated from scripts/generate/templates/EnumerableSet.js.

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
 *
 * [WARNING]
 * ====
 * Trying to delete such a structure from storage will likely result in data corruption, rendering the structure
 * unusable.
 * See https://github.com/ethereum/solidity/pull/11843[ethereum/solidity#11843] for more info.
 *
 * In order to clean an EnumerableSet, you can either remove all elements one by one or create a fresh instance using an
 * array of EnumerableSet.
 * ====
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
                bytes32 lastValue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastValue;
                // Update the index for the moved value
                set._indexes[lastValue] = valueIndex; // Replace lastValue's index to valueIndex
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
        bytes32[] memory store = _values(set._inner);
        bytes32[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
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

        /// @solidity memory-safe-assembly
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
     * @dev Returns the number of values in the set. O(1).
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

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../extensions/draft-IERC20Permit.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    function safePermit(
        IERC20Permit token,
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        uint256 nonceBefore = token.nonces(owner);
        token.permit(owner, spender, value, deadline, v, r, s);
        uint256 nonceAfter = token.nonces(owner);
        require(nonceAfter == nonceBefore + 1, "SafeERC20: permit did not succeed");
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address-functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.0;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To initialize the implementation contract, you can either invoke the
 * initializer manually, or you can include a constructor to automatically mark it as initialized when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() initializer {}
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, because in other contexts the
        // contract may have been reentered.
        require(_initializing ? _isConstructor() : !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} modifier, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    function _isConstructor() private view returns (bool) {
        return !AddressUpgradeable.isContract(address(this));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal onlyInitializing {
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
     * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
     *
     * _Available since v4.8._
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason or using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
        // Look for revert reason and bubble it up if present
        if (returndata.length > 0) {
            // The easiest way to bubble the revert reason is using memory via assembly
            /// @solidity memory-safe-assembly
            assembly {
                let returndata_size := mload(returndata)
                revert(add(32, returndata), returndata_size)
            }
        } else {
            revert(errorMessage);
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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/draft-IERC20Permit.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20Permit {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}