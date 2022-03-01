// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "./Ownable.sol";

/**
 * @notice
 * A stake struct is used to represent the way we store stakes,
 * A Stake will contain the users address, the duration (0 for imediate withdrawal or 1 / 2 / 3 years), the amount staked and a timestamp,
 * Since which is when the stake was made
 * _stakeCheckPointIndex: The index in the checkpoints array of the current stake
 */
struct Stake {
    uint256 _amount;
    uint256 _since;
    IERC20 _stakingToken;
    uint256 _stakaAmount;
    uint256 _estimatedReward;
    APY _estimatedAPY;
    uint256 _rewardStartDate; //This date will change as the amount staked increases
    bool _exists;
}

/***@notice Struct to store Staking Contract Parameters */
struct StakingContractParameters {
    uint256 _minimumStake;
    uint256 _maxSupply;
    uint256 _totalReward;
    IERC20 _stakingToken;
    uint256 _stakingDuration;
    uint256 _maximumStake;
    //staking starting parameters
    uint256 _minimumNumberStakeHoldersBeforeStart;
    uint256 _minimumTotalStakeBeforeStart;
    uint256 _startDate;
    uint256 _endDate;
    //vesting parameters
    Percentage _immediateRewardPercentage;
    uint256 _cliffDuration;
    Percentage _cliffRewardPercentage;
    uint256 _linearDuration;
}

struct Percentage {
    uint256 _percentage;
    uint256 _percentageBase;
}

struct StakingContractParametersUpdate {
    uint256 _minimumStake;
    uint256 _maxSupply;
    uint256 _totalReward;
    IERC20 _stakingToken;
    uint256 _stakingDuration;
    uint256 _maximumStake;
    uint256 _minimumNumberStakeHoldersBeforeStart;
    uint256 _minimumTotalStakeBeforeStart;
    Percentage _immediateRewardPercentage;
    uint256 _cliffDuration;
    Percentage _cliffRewardPercentage;
    uint256 _linearDuration;
}

struct APY {
    uint256 _apy;
    uint256 _base;
}

/**
 * @dev Implementation of the {IERC20} interface.
 *
 */
contract KatanaInuStakingContract is
    ERC20("STAKA Token", "STAKA"),
    Ownable,
    Pausable
{
    using SafeMath for uint256;

    ///////////// Events ///////////////////
    /**
     * @dev Emitted when a user stakes tokens
     */
    event Staked(
        address indexed stakeholder,
        uint256 amountStaked,
        IERC20 stakingToken,
        uint256 xKataAmount
    );

    /**
     * @dev Emitted when a user withdraw stake
     */
    event Withdrawn(
        address indexed stakeholder,
        uint256 amountStaked,
        uint256 amountReceived,
        IERC20 stakingToken
    );

    /**
     * @dev Emitted when a user withdraw stake
     */
    event EmergencyWithdraw(
        address indexed stakeholder,
        uint256 amountSKataBurned,
        uint256 amountReceived
    );

    ///////////////////////////////////////

    ///// Fields //////////
    /*** @notice Stakes by stakeholder address */
    mapping(address => Stake) public _stakeholdersMapping;
    uint256 _currentNumberOfStakeholders;

    /*** @notice Staking contract parameters */
    StakingContractParameters private _stakingParameters;

    /***@notice Total Kata Staked */
    uint256 private _totalKataStaked;

    /***@notice Total Kata rewards claimed */
    uint256 private _totalKataRewardsClaimed;

    bool private _stakingStarted;

    ////////////////////////////////////////

    constructor(address stakingTokenAddress) {
        _stakingParameters._stakingToken = IERC20(stakingTokenAddress);
        _stakingParameters._minimumNumberStakeHoldersBeforeStart = 1;
    }

    /***@notice Update Staking Parameters: _startDate can't be updated, it is automatically set when the first stake is created */
    function updateStakingParameters(
        StakingContractParametersUpdate calldata stakingParameters
    ) external onlyOwner {
        _stakingParameters._minimumStake = stakingParameters._minimumStake;
        _stakingParameters._maxSupply = stakingParameters._maxSupply;
        _stakingParameters._totalReward = stakingParameters._totalReward;
        _stakingParameters._stakingToken = IERC20(
            stakingParameters._stakingToken
        );
        _stakingParameters._stakingDuration = stakingParameters
            ._stakingDuration;
        if (_stakingStarted) {
            _stakingParameters._endDate =
                _stakingParameters._startDate +
                _stakingParameters._stakingDuration;
        }
        if (!_stakingStarted) {
            // No need to update these paraeter if the staking has already started
            _stakingParameters
                ._minimumNumberStakeHoldersBeforeStart = stakingParameters
                ._minimumNumberStakeHoldersBeforeStart;
            _stakingParameters._minimumTotalStakeBeforeStart = stakingParameters
                ._minimumTotalStakeBeforeStart;
            if (
                (_stakingParameters._minimumTotalStakeBeforeStart == 0 ||
                    _totalKataStaked >=
                    _stakingParameters._minimumTotalStakeBeforeStart) &&
                (_stakingParameters._minimumNumberStakeHoldersBeforeStart ==
                    0 ||
                    _currentNumberOfStakeholders >=
                    _stakingParameters._minimumNumberStakeHoldersBeforeStart)
            ) {
                _stakingStarted = true;
                _stakingParameters._startDate = block.timestamp;
                _stakingParameters._endDate =
                    _stakingParameters._startDate +
                    _stakingParameters._stakingDuration;
            }
        }
        _stakingParameters._maximumStake = stakingParameters._maximumStake;

        //Update reward schedule array
        _stakingParameters._immediateRewardPercentage = stakingParameters
            ._immediateRewardPercentage;
        _stakingParameters._cliffDuration = stakingParameters._cliffDuration;
        _stakingParameters._cliffRewardPercentage = stakingParameters
            ._cliffRewardPercentage;
        _stakingParameters._linearDuration = stakingParameters._linearDuration;
    }

    /***@notice Stake Kata coins in exchange for xKata coins to earn a share of the rewards */
    function stake(uint256 amount) external onlyUser whenNotPaused {
        //Check the amount is >= _minimumStake
        require(
            amount >= _stakingParameters._minimumStake,
            "Amount below the minimum stake"
        );
        //Check the amount is <= _maximumStake
        require(
            _stakingParameters._maximumStake == 0 ||
                amount <= _stakingParameters._maximumStake,
            "amount exceeds maximum stake"
        );
        //Check if the new stake will exceed the maximum supply for this pool
        require(
            (_totalKataStaked + amount) <= _stakingParameters._maxSupply,
            "You can not exceeed maximum supply for staking"
        );

        require(
            !_stakingStarted || block.timestamp < _stakingParameters._endDate,
            "The staking period has ended"
        );
        //Check if the totalReward have been already claimed, in theory this should always be true,
        //but added the extra check for additional safety
        require(
            _totalKataRewardsClaimed < _stakingParameters._totalReward,
            "All rewards have been distributed"
        );

        Stake memory newStake = createStake(amount);
        _totalKataStaked += amount;
        if (!_stakeholdersMapping[msg.sender]._exists) {
            _currentNumberOfStakeholders += 1;
        }
        //Check if the staking period did not end
        if (
            !_stakingStarted &&
            (_stakingParameters._minimumTotalStakeBeforeStart == 0 ||
                _totalKataStaked >=
                _stakingParameters._minimumTotalStakeBeforeStart) &&
            (_stakingParameters._minimumNumberStakeHoldersBeforeStart == 0 ||
                _currentNumberOfStakeholders >=
                _stakingParameters._minimumNumberStakeHoldersBeforeStart)
        ) {
            _stakingStarted = true;
            _stakingParameters._startDate = block.timestamp;
            _stakingParameters._endDate =
                _stakingParameters._startDate +
                _stakingParameters._stakingDuration;
        }
        //Transfer amount to contract (this)
        if (
            !_stakingParameters._stakingToken.transferFrom(
                msg.sender,
                address(this),
                amount
            )
        ) {
            revert("couldn 't transfer tokens from sender to contract");
        }

        _mint(msg.sender, newStake._stakaAmount);

        //Update stakeholders

        if (!_stakeholdersMapping[msg.sender]._exists) {
            _stakeholdersMapping[msg.sender] = newStake;
            _stakeholdersMapping[msg.sender]._exists = true;
        } else {
            _stakeholdersMapping[msg.sender]
                ._rewardStartDate = calculateNewRewardStartDate(
                _stakeholdersMapping[msg.sender],
                newStake
            );
            _stakeholdersMapping[msg.sender]._amount += newStake._amount;
            _stakeholdersMapping[msg.sender]._stakaAmount += newStake
                ._stakaAmount;
        }
        //Emit event
        emit Staked(
            msg.sender,
            amount,
            _stakingParameters._stakingToken,
            newStake._stakaAmount
        );
    }

    function calculateNewRewardStartDate(
        Stake memory existingStake,
        Stake memory newStake
    ) private pure returns (uint256) {
        uint256 multiplier = (
            existingStake._rewardStartDate.mul(existingStake._stakaAmount)
        ).add(newStake._rewardStartDate.mul(newStake._stakaAmount));
        uint256 divider = existingStake._stakaAmount.add(newStake._stakaAmount);
        return multiplier.div(divider);
    }

    /*** @notice Withdraw stake and get initial amount staked + share of the reward */
    function withdrawStake(uint256 amount) external onlyUser whenNotPaused {
        require(
            _stakeholdersMapping[msg.sender]._exists,
            "Can not find stake for sender"
        );
        require(
            _stakeholdersMapping[msg.sender]._amount >= amount,
            "Can not withdraw more than actual stake"
        );
        Stake memory stakeToWithdraw = _stakeholdersMapping[msg.sender];
        require(stakeToWithdraw._amount > 0, "Stake alreday withdrawn");
        //Reward proportional to amount withdrawn
        uint256 reward = (
            computeRewardForStake(block.timestamp, stakeToWithdraw, true).mul(
                amount
            )
        ).div(stakeToWithdraw._amount);
        //Check if there is enough reward tokens, this is to avoid paying rewards with other stakeholders stake
        uint256 currentRewardBalance = getRewardBalance();
        require(
            reward <= currentRewardBalance,
            "The contract does not have enough reward tokens"
        );
        uint256 totalAmoutToWithdraw = reward + amount;
        //Calculate nb STAKA to burn:
        uint256 nbStakaToBurn = (stakeToWithdraw._stakaAmount.mul(amount)).div(
            stakeToWithdraw._amount
        );

        _stakeholdersMapping[msg.sender]._amount -= amount;
        _stakeholdersMapping[msg.sender]._stakaAmount -= nbStakaToBurn;

        _totalKataStaked = _totalKataStaked - amount;
        _totalKataRewardsClaimed += reward;
        //Transfer amount to contract (this)
        if (
            !stakeToWithdraw._stakingToken.transfer(
                msg.sender,
                totalAmoutToWithdraw
            )
        ) {
            revert("couldn 't transfer tokens from sender to contract");
        }
        _burn(msg.sender, nbStakaToBurn);
        emit Withdrawn(
            msg.sender,
            stakeToWithdraw._amount,
            totalAmoutToWithdraw,
            stakeToWithdraw._stakingToken
        );
    }

    /***@notice withdraw all stakes of a given user without including rewards */
    function emergencyWithdraw(address stakeHolderAddress) external onlyOwner {
        require(
            _stakeholdersMapping[stakeHolderAddress]._exists,
            "Can not find stake for sender"
        );
        require(
            _stakeholdersMapping[stakeHolderAddress]._amount > 0,
            "Can not any stake for supplied address"
        );

        uint256 totalAmoutTowithdraw;
        uint256 totalSKataToBurn;
        totalAmoutTowithdraw = _stakeholdersMapping[stakeHolderAddress]._amount;
        totalSKataToBurn = _stakeholdersMapping[stakeHolderAddress]
            ._stakaAmount;
        if (
            !_stakeholdersMapping[stakeHolderAddress]._stakingToken.transfer(
                stakeHolderAddress,
                _stakeholdersMapping[stakeHolderAddress]._amount
            )
        ) {
            revert("couldn 't transfer tokens from sender to contract");
        }
        _stakeholdersMapping[stakeHolderAddress]._amount = 0;
        _stakeholdersMapping[stakeHolderAddress]._exists = false;
        _stakeholdersMapping[stakeHolderAddress]._stakaAmount = 0;

        _totalKataStaked = _totalKataStaked - totalAmoutTowithdraw;
        _burn(stakeHolderAddress, totalSKataToBurn);
        emit EmergencyWithdraw(
            stakeHolderAddress,
            totalSKataToBurn,
            totalAmoutTowithdraw
        );
    }

    /***@notice Get an estimate of the reward  */
    function getStakeReward(uint256 targetTime)
        external
        view
        onlyUser
        returns (uint256)
    {
        require(
            _stakeholdersMapping[msg.sender]._exists,
            "Can not find stake for sender"
        );
        Stake memory targetStake = _stakeholdersMapping[msg.sender];
        return computeRewardForStake(targetTime, targetStake, true);
    }

    /***@notice Get an estimate of the reward  */
    function getEstimationOfReward(uint256 targetTime, uint256 amountToStake)
        external
        view
        returns (uint256)
    {
        Stake memory targetStake = createStake(amountToStake);
        return computeRewardForStake(targetTime, targetStake, false);
    }

    function getAPY() external view returns (APY memory) {
        if (
            !_stakingStarted ||
            _stakingParameters._endDate == _stakingParameters._startDate ||
            _totalKataStaked == 0
        ) return APY(0, 1);

        uint256 targetTime = 365 days;
        if (
            _stakingParameters._immediateRewardPercentage._percentage == 0 &&
            _stakingParameters._cliffRewardPercentage._percentage == 0 &&
            _stakingParameters._cliffDuration == 0 &&
            _stakingParameters._linearDuration == 0
        ) {
            uint256 reward = _stakingParameters
                ._totalReward
                .mul(targetTime)
                .div(
                    _stakingParameters._endDate.sub(
                        _stakingParameters._startDate
                    )
                );
            return APY(reward.mul(100000).div(_totalKataStaked), 100000);
        }
        return getAPYWithVesting();
    }

    function getAPYWithVesting() private view returns (APY memory) {
        uint256 targetTime = 365 days;
        Stake memory syntheticStake = Stake(
            _totalKataStaked,
            block.timestamp,
            _stakingParameters._stakingToken,
            totalSupply(),
            0,
            APY(0, 1),
            block.timestamp,
            true
        );
        uint256 reward = computeRewardForStakeWithVesting(
            block.timestamp + targetTime,
            syntheticStake,
            true
        );
        return APY(reward.mul(100000).div(_totalKataStaked), 100000);
    }

    /***@notice Create a new stake by taking into account accrued rewards when estimating the number of xKata tokens in exchange for Kata tokens */
    function createStake(uint256 amount) private view returns (Stake memory) {
        uint256 xKataAmountToMint;
        uint256 currentTimeStanp = block.timestamp;
        if (_totalKataStaked == 0 || totalSupply() == 0) {
            xKataAmountToMint = amount;
        } else {
            //Add multiplication by 1 + time to maturity ratio
            uint256 multiplier = amount
                .mul(
                    _stakingParameters._endDate.sub(
                        _stakingParameters._startDate
                    )
                )
                .div(
                    _stakingParameters._endDate.add(currentTimeStanp).sub(
                        2 * _stakingParameters._startDate
                    )
                );
            xKataAmountToMint = multiplier.mul(totalSupply()).div(
                _totalKataStaked
            );
        }
        return
            Stake(
                amount,
                currentTimeStanp,
                _stakingParameters._stakingToken,
                xKataAmountToMint,
                0,
                APY(0, 1),
                currentTimeStanp,
                true
            );
    }

    /*** Stats functions */

    /***@notice returns the amount of Kata tokens available for rewards */
    function getRewardBalance() public view returns (uint256) {
        uint256 stakingTokenBalance = _stakingParameters
            ._stakingToken
            .balanceOf(address(this));
        uint256 rewardBalance = stakingTokenBalance.sub(_totalKataStaked);
        return rewardBalance;
    }

    /***@notice returns the amount of Kata tokens withdrawn as rewards */
    function getTotalRewardsClaimed() public view returns (uint256) {
        return _totalKataRewardsClaimed;
    }

    function getRequiredRewardAmountForPerdiod(uint256 endPeriod)
        external
        view
        onlyOwner
        returns (uint256)
    {
        return caluclateRequiredRewardAmountForPerdiod(endPeriod);
    }

    function getRequiredRewardAmount() external view returns (uint256) {
        return caluclateRequiredRewardAmountForPerdiod(block.timestamp);
    }

    ///////////////////////////////////////////////////////////////

    function caluclateRequiredRewardAmountForPerdiod(uint256 endPeriod)
        private
        view
        returns (uint256)
    {
        if (
            !_stakingStarted ||
            _stakingParameters._endDate == _stakingParameters._startDate ||
            _totalKataStaked == 0
        ) return 0;
        uint256 requiredReward = _stakingParameters
            ._totalReward
            .mul(endPeriod.sub(_stakingParameters._startDate))
            .div(_stakingParameters._endDate.sub(_stakingParameters._startDate))
            .sub(_totalKataRewardsClaimed);
        return requiredReward;
    }

    /***@notice Calculate the reward for a give stake if withdrawn at 'targetTime' */
    function computeRewardForStake(
        uint256 targetTime,
        Stake memory targetStake,
        bool existingStake
    ) private view returns (uint256) {
        if (
            _stakingParameters._immediateRewardPercentage._percentage == 0 &&
            _stakingParameters._cliffRewardPercentage._percentage == 0 &&
            _stakingParameters._cliffDuration == 0 &&
            _stakingParameters._linearDuration == 0
        ) {
            return
                computeReward(
                    _stakingParameters._totalReward,
                    targetTime,
                    targetStake._stakaAmount,
                    targetStake._rewardStartDate,
                    existingStake
                );
        }
        return
            computeRewardForStakeWithVesting(
                targetTime,
                targetStake,
                existingStake
            );
    }

    function computeRewardForStakeWithVesting(
        uint256 targetTime,
        Stake memory targetStake,
        bool existingStake
    ) private view returns (uint256) {
        uint256 accumulatedReward;
        uint256 currentStartTime = targetStake._rewardStartDate;
        uint256 currentTotalRewardAmount = (
            _stakingParameters._totalReward.mul(
                _stakingParameters._immediateRewardPercentage._percentage
            )
        ).div(_stakingParameters._immediateRewardPercentage._percentageBase);

        if (
            (currentStartTime + _stakingParameters._cliffDuration) >= targetTime
        ) {
            return
                computeReward(
                    currentTotalRewardAmount,
                    targetTime,
                    targetStake._stakaAmount,
                    currentStartTime,
                    existingStake
                );
        }

        accumulatedReward += computeReward(
            currentTotalRewardAmount,
            currentStartTime + _stakingParameters._cliffDuration,
            targetStake._stakaAmount,
            currentStartTime,
            existingStake
        );

        currentStartTime = currentStartTime + _stakingParameters._cliffDuration;
        currentTotalRewardAmount += (
            _stakingParameters._totalReward.mul(
                _stakingParameters._cliffRewardPercentage._percentage
            )
        ).div(_stakingParameters._cliffRewardPercentage._percentageBase);

        if (
            _stakingParameters._linearDuration == 0 ||
            (currentStartTime + _stakingParameters._linearDuration) <=
            targetTime
        ) {
            // 100% percent of the reward vested
            currentTotalRewardAmount = _stakingParameters._totalReward;

            return (
                accumulatedReward.add(
                    computeReward(
                        currentTotalRewardAmount,
                        targetTime,
                        targetStake._stakaAmount,
                        currentStartTime,
                        existingStake
                    )
                )
            );
        }
        // immediate + cliff + linear proportion of the reward
        currentTotalRewardAmount += (
            _stakingParameters._totalReward.sub(currentTotalRewardAmount)
        ).mul(targetTime - currentStartTime).div(
                _stakingParameters._linearDuration
            );
        accumulatedReward += computeReward(
            currentTotalRewardAmount,
            targetTime,
            targetStake._stakaAmount,
            currentStartTime,
            existingStake
        );
        return accumulatedReward;
    }

    /***@notice Calculate the reward for a give stake if withdrawn at 'targetTime' */
    function computeReward(
        uint256 applicableReward,
        uint256 targetTime,
        uint256 stakaAmount,
        uint256 rewardStartDate,
        bool existingStake
    ) private view returns (uint256) {
        uint256 mulltiplier = stakaAmount
            .mul(applicableReward)
            .mul(targetTime.sub(rewardStartDate))
            .div(
                _stakingParameters._endDate.sub(_stakingParameters._startDate)
            );

        uint256 divider = existingStake
            ? totalSupply()
            : totalSupply().add(stakaAmount);
        return mulltiplier.div(divider);
    }

    /**
     * @notice
     * Update Staking Token
     */
    function setStakingToken(address stakingTokenAddress) external onlyOwner {
        _stakingParameters._stakingToken = IERC20(stakingTokenAddress);
    }

    /*** @notice Withdraw reward */
    function withdrawFromReward(uint256 amount) external onlyOwner {
        //Check if there is enough reward tokens, this is to avoid paying rewards with other stakeholders stake
        require(
            amount <= getRewardBalance(),
            "The contract does not have enough reward tokens"
        );
        //Transfer amount to contract (this)
        if (!_stakingParameters._stakingToken.transfer(msg.sender, amount)) {
            revert("couldn 't transfer tokens from sender to contract");
        }
    }

    /**
     * @notice
     * Return the total amount staked
     */
    function getTotalStaked() external view returns (uint256) {
        return _totalKataStaked;
    }

    /**
     * @notice
     * Return the value of the penalty for early exit
     */
    function getContractParameters()
        external
        view
        returns (StakingContractParameters memory)
    {
        return _stakingParameters;
    }

    /**
     * @notice
     * Return stakes for msg.sender
     */
    function getStake() external view returns (Stake memory) {
        Stake memory currentStake = _stakeholdersMapping[msg.sender];
        if (!currentStake._exists) {
            // Return empty stake
            return
                Stake(
                    0,
                    0,
                    _stakingParameters._stakingToken,
                    0,
                    0,
                    APY(0, 1),
                    0,
                    false
                );
        }
        if (_stakingStarted) {
            currentStake._estimatedReward = computeRewardForStake(
                block.timestamp,
                currentStake,
                true
            );
            currentStake._estimatedAPY = APY(
                computeRewardForStake(
                    currentStake._rewardStartDate + 365 days,
                    currentStake,
                    true
                ).mul(100000).div(currentStake._amount),
                100000
            );
        }
        return currentStake;
    }

    function shouldStartContract(
        uint256 newTotalKataStaked,
        uint256 newCurrentNumberOfStakeHolders
    ) private view returns (bool) {
        if (
            _stakingParameters._minimumTotalStakeBeforeStart > 0 &&
            newTotalKataStaked <
            _stakingParameters._minimumTotalStakeBeforeStart
        ) {
            return false;
        }
        if (
            _stakingParameters._minimumNumberStakeHoldersBeforeStart > 0 &&
            newCurrentNumberOfStakeHolders <
            _stakingParameters._minimumNumberStakeHoldersBeforeStart
        ) {
            return false;
        }
        return true;
    }

    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        if (from == address(0))
            //Nothing to do when _mint is called
            return;
        if (to == address(0))
            //Nothing to do when _burn is called
            return;

        Stake memory fromStake = _stakeholdersMapping[from];
        uint256 amountOfKataToTransfer = (
            _stakeholdersMapping[from]._amount.mul(amount)
        ).div(_stakeholdersMapping[from]._stakaAmount);

        fromStake._exists = true;
        fromStake._stakaAmount = amount;
        fromStake._amount = amountOfKataToTransfer;
        if (!_stakeholdersMapping[to]._exists) {
            _stakeholdersMapping[to] = fromStake;
            _stakeholdersMapping[from]._stakaAmount -= amount;
            _stakeholdersMapping[from]._amount -= amountOfKataToTransfer;
        } else {
            _stakeholdersMapping[to]
                ._rewardStartDate = calculateNewRewardStartDate(
                _stakeholdersMapping[to],
                fromStake
            );
            _stakeholdersMapping[to]._stakaAmount += amount;
            _stakeholdersMapping[to]._amount += amountOfKataToTransfer;
            _stakeholdersMapping[from]._stakaAmount -= amount;
            _stakeholdersMapping[from]._amount -= amountOfKataToTransfer;
        }
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    /**
     * onlyUser
     * @dev guard contracts from calling method
     **/
    modifier onlyUser() {
        require(msg.sender == tx.origin);
        _;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title Ownable
 * @dev Ownable has an owner address to simplify "user permissions".
 */
contract Ownable {
  address payable public owner;

  /**
   * Ownable
   * @dev Ownable constructor sets the `owner` of the contract to sender
   */
  constructor() {  owner = payable(msg.sender);  }

  /**
   * ownerOnly
   * @dev Throws an error if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  /**
   * transferOwnership
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address payable newOwner) public onlyOwner {
    require(newOwner != address(0));
    owner = newOwner;
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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);

        _afterTokenTransfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
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