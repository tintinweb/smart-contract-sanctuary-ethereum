pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/// @title   PDT Staking
/// @notice  Contract that allows users to stake PDT
/// @author  JeffX
contract PDTStaking {
    /// ERRORS ///

    /// @notice Error for if epoch is invalid
    error InvalidEpoch();
    /// @notice Error for if user has claimed for epoch
    error EpochClaimed();
    /// @notice Error for if there is nothing to claim
    error NothingToClaim();
    /// @notice Error for if staking more than balance
    error MoreThanBalance();
    /// @notice Error for if unstaking when nothing is staked
    error NothingStaked();
    /// @notice Error for if not owner
    error NotOwner();
    /// @notice Error for if zero address
    error ZeroAddress();

    /// STRUCTS ///

    /// @notice                     Details for epoch
    /// @param totalToDistribute    Total amount of token to distribute for epoch
    /// @param totalClaimed         Total amount of tokens claimed from epoch
    /// @param startTime            Timestamp epoch started
    /// @param endTime              Timestamp epoch ends
    /// @param meanMultiplierAtEnd  Mean multiplier at end of epoch
    /// @param weightAtEnd          Weight of staked tokens at end of epoch
    struct Epoch {
        uint256 totalToDistribute;
        uint256 totalClaimed;
        uint256 startTime;
        uint256 endTime;
        uint256 meanMultiplierAtEnd;
        uint256 weightAtEnd;
    }

    /// @notice                    Stake details for user
    /// @param amountStaked        Amount user has staked
    /// @param adjustedTimeStaked  Adjusted time user staked
    struct Stake {
        uint256 amountStaked;
        uint256 adjustedTimeStaked;
    }

    /// STATE VARIABLES ///

    /// @notice Starting multiplier
    uint256 public constant multiplierStart = 1e18;
    /// @notice Length of epoch
    uint256 public epochLength;

    /// @notice Timestmap contract was deplpoyed
    uint256 public immutable startTime;
    /// @notice Time to double multiplier
    uint256 public immutable timeToDouble;

    /// @notice Adjusted time for contract
    uint256 public adjustedTime;

    /// @notice Total amount of PDT staked
    uint256 public totalStaked;
    /// @notice Amount of unclaimed rewards
    uint256 private unclaimedRewards;

    /// @notice Epoch id
    uint256 public epochId;

    /// @notice Current epoch
    Epoch public currentEpoch;

    /// @notice Address of PDT
    address public immutable pdt;
    /// @notice Address of reward token
    address public immutable rewardToken;
    /// @notice Address of owner
    address public owner;

    /// @notice If user has claimed for certain epoch
    mapping(address => mapping(uint256 => bool)) public userClaimedEpoch;
    /// @notice User's multiplier at end of epoch
    mapping(address => mapping(uint256 => uint256)) public userMultiplierAtEpoch;
    /// @notice User's weight at an epoch
    mapping(address => mapping(uint256 => uint256)) public userWeightAtEpoch;
    /// @notice Epoch user has last claimed
    mapping(address => uint256) public epochLeftOff;
    /// @notice Id to epoch details
    mapping(uint256 => Epoch) public epoch;
    /// @notice Stake details of user
    mapping(address => Stake) public stakeDetails;

    /// CONSTRUCTOR ///

    /// @param _timeToDouble  Time for multiplier to double
    /// @param _epochLength   Length of epoch
    /// @param _pdt           PDT token address
    /// @param _rewardToken   Address of reward token
    /// @param _owner   Address of owner
    constructor(
        uint256 _timeToDouble,
        uint256 _epochLength,
        address _pdt,
        address _rewardToken,
        address _owner
    ) {
        startTime = block.timestamp;
        currentEpoch.endTime = block.timestamp;
        timeToDouble = _timeToDouble;
        epochLength = _epochLength;
        pdt = _pdt;
        rewardToken = _rewardToken;
        owner = _owner;
    }

    /// OWNER FUNCTION ///

    /// @notice              Update epoch length of contract
    /// @param _epochLength  New epoch length
    function updateEpochLength(uint256 _epochLength) external {
        if (msg.sender != owner) revert NotOwner();
        epochLength = _epochLength;
    }

    /// @notice           Changing owner of contract to `newOwner_`
    /// @param _newOwner  Address of who will be the new owner of contract
    function transferOwnership(address _newOwner) external {
        if (msg.sender != owner) revert NotOwner();
        if (_newOwner == address(0)) revert ZeroAddress();
        owner = _newOwner;
    }

    /// PUBLIC FUNCTIONS ///

    /// @notice  Update epoch details if time
    function distribute() public {
        if (block.timestamp >= currentEpoch.endTime) {
            uint256 multiplier_;
            if (totalStaked != 0) multiplier_ = _multiplier(currentEpoch.endTime, adjustedTime);
            epoch[epochId].meanMultiplierAtEnd = multiplier_;
            epoch[epochId].weightAtEnd = multiplier_ * totalStaked;

            ++epochId;
            
            Epoch memory _epoch;
            _epoch.totalToDistribute = IERC20(rewardToken).balanceOf(address(this)) - unclaimedRewards;
            _epoch.startTime = block.timestamp;
            _epoch.endTime = block.timestamp + epochLength;

            currentEpoch = _epoch;
            epoch[epochId] = _epoch;

            unclaimedRewards += _epoch.totalToDistribute;
        }
    }

    /// @notice         Stake PDT
    /// @param _to      Address that will receive credit for stake
    /// @param _amount  Amount of PDT to stake
    function stake(address _to, uint256 _amount) external {
        if (IERC20(pdt).balanceOf(msg.sender) < _amount) revert MoreThanBalance();
        IERC20(pdt).transferFrom(msg.sender, address(this), _amount);

        distribute();
        _setUserMultiplierAtEpoch(_to);
        _adjustMeanMultilpier(true, _amount);

        totalStaked += _amount;

        Stake memory stakeDetail = stakeDetails[_to];

        uint256 previousStakeAmount = stakeDetail.amountStaked;

        if (previousStakeAmount > 0) {
            uint256 previousTimeStaked = stakeDetail.adjustedTimeStaked;
            uint256 timePassed = block.timestamp - previousTimeStaked;
            uint256 percentStakeIncreased = (1e18 * _amount) / (previousStakeAmount + _amount);
            stakeDetail.adjustedTimeStaked = previousTimeStaked + ((percentStakeIncreased * timePassed) / 1e18);
        } else {
            stakeDetail.adjustedTimeStaked = block.timestamp;
        }

        stakeDetail.amountStaked += _amount;

        stakeDetails[_to] = stakeDetail;
    }

    /// @notice     Unstake PDT
    /// @param _to  Address that will receive PDT unstaked
    function unstake(address _to) external {
        Stake memory stakeDetail = stakeDetails[msg.sender];
        uint256 _amountStaked = stakeDetail.amountStaked;

        if (_amountStaked == 0) revert NothingStaked();
        distribute();
        _setUserMultiplierAtEpoch(msg.sender);
        _adjustMeanMultilpier(false, _amountStaked);

        totalStaked -= _amountStaked;

        stakeDetail.amountStaked = 0;
        stakeDetail.adjustedTimeStaked = 0;

        stakeDetails[msg.sender] = stakeDetail;

        IERC20(pdt).transfer(_to, _amountStaked);
    }

    /// @notice           Claims rewards tokens for msg.sender of `_epochIds`
    /// @param _to        Address to send rewards to
    /// @param _epochIds  Array of epoch ids to claim for
    function claim(address _to, uint256[] calldata _epochIds) external {
        _setUserMultiplierAtEpoch(msg.sender);

        uint256 _pendingRewards;

        for (uint256 i; i < _epochIds.length; ++i) {
            if (userClaimedEpoch[msg.sender][_epochIds[i]]) revert EpochClaimed();
            if (epochId <= _epochIds[i]) revert InvalidEpoch();

            userClaimedEpoch[msg.sender][_epochIds[i]] = true;
            Epoch memory _epoch = epoch[_epochIds[i]];
            uint256 _userWeightAtEpoch = userWeightAtEpoch[msg.sender][_epochIds[i]];

            uint256 _epochRewards = (_epoch.totalToDistribute * _userWeightAtEpoch) / weightAtEpoch(_epochIds[i]);
            if (_epoch.totalClaimed + _epochRewards > _epoch.totalToDistribute) {
                _epochRewards = _epoch.totalToDistribute - _epoch.totalClaimed;
            }
            _pendingRewards += _epochRewards;
            _epoch.totalClaimed += _epochRewards;
            epoch[_epochIds[i]] = _epoch;
        }

        unclaimedRewards -= _pendingRewards;
        IERC20(rewardToken).transfer(_to, _pendingRewards);
    }

    /// VIEW FUNCTIONS ///

    /// @notice         Returns multiplier if staked from beginning
    /// @return index_  Multiplier index
    function multiplierIndex() public view returns (uint256 index_) {
        return _multiplier(block.timestamp, startTime);
    }

    /// @notice              Returns contracts mean multiplier
    /// @return multiplier_  Current mean multiplier of contract
    function meanMultiplier() public view returns (uint256 multiplier_) {
        return _multiplier(block.timestamp, adjustedTime);
    }

    /// @notice              Returns `multiplier_' of `_user`
    /// @param _user         Address of who getting `multiplier_` for
    /// @return multiplier_  Current multiplier of `_user`
    function userStakeMultiplier(address _user) public view returns (uint256 multiplier_) {
        Stake memory stakeDetail = stakeDetails[_user];
        if (stakeDetail.amountStaked > 0) return _multiplier(block.timestamp, stakeDetail.adjustedTimeStaked);
    }

    /// @notice              Returns `multiplier_' of `_user` at `_epochId`
    /// @param _user         Address of user getting `multiplier_` of `_epochId`
    /// @param _epochId      Epoch of id to get user for
    /// @return multiplier_  Multiplier of `_user` at `_epochId`
    function userStakeMultiplierAtEpoch(address _user, uint256 _epochId) external view returns (uint256 multiplier_) {
        if (epochId <= _epochId) revert InvalidEpoch();
        uint256 _epochLeftOff = epochLeftOff[_user];
        Stake memory stakeDetail = stakeDetails[_user];

        if (_epochLeftOff > _epochId) multiplier_ = userMultiplierAtEpoch[_user][_epochId];
        else {
            Epoch memory _epoch = epoch[_epochId];
            if (stakeDetail.amountStaked > 0) return _multiplier(_epoch.endTime, stakeDetail.adjustedTimeStaked);
        }
    }

    /// @notice          Returns weight of contract at `_epochId`
    /// @param _epochId  Id of epoch wanting to get weight for
    /// @return weight_  Weight of contract for `_epochId`
    function weightAtEpoch(uint256 _epochId) public view returns (uint256 weight_) {
        if (epochId <= _epochId) revert InvalidEpoch();
        return epoch[_epochId].weightAtEnd;
    }

    /// @notice             Returns amount `_user` has claimable for `_epochId`
    /// @param _user        Address to see `claimable_` for `_epochId`
    /// @param _epochId     Id of epoch wanting to get `claimable_` for
    /// @return claimable_  Amount claimable
    function claimAmountForEpoch(address _user, uint256 _epochId) external view returns (uint256 claimable_) {
        if (epochId <= _epochId) revert InvalidEpoch();
        if (userClaimedEpoch[_user][_epochId]) return 0;

        uint256 _epochLeftOff = epochLeftOff[_user];

        Epoch memory _epoch = epoch[_epochId];

        uint256 _userWeightAtEpoch;

        if (_epochLeftOff < epochId) {
            Stake memory stakeDetail = stakeDetails[_user];

            for (_epochLeftOff; _epochLeftOff < epochId; ++_epochLeftOff) {
                if (stakeDetail.amountStaked > 0) {
                    if (stakeDetail.adjustedTimeStaked > _epoch.endTime) return 0;
                    uint256 _multiplierAtEpoch = _multiplier(_epoch.endTime, stakeDetail.adjustedTimeStaked);
                    _userWeightAtEpoch = _multiplierAtEpoch * stakeDetail.amountStaked;
                }
            }
        } else  {
            _userWeightAtEpoch = userWeightAtEpoch[_user][_epochId];
        }

        claimable_ = (_epoch.totalToDistribute * _userWeightAtEpoch) / weightAtEpoch(_epochId);
    }

    /// INTERNAL VIEW FUNCTION ///

    /// @notice               Returns multiplier using `_timestamp` and `_adjustedTime`
    /// @param _timeStamp     Timestamp to use to calcaulte `multiplier_`
    /// @param _adjustedTime  Adjusted stake time to use to calculate `multiplier_`
    /// @return multiplier_   Multitplier using `_timeStamp` and `adjustedTime`
    function _multiplier(uint256 _timeStamp, uint256 _adjustedTime) internal view returns (uint256 multiplier_) {
        uint256 _adjustedTimePassed = _timeStamp - _adjustedTime;
        multiplier_ = multiplierStart + ((multiplierStart * _adjustedTimePassed) / timeToDouble);
    }

    /// INTERNAL FUNCTIONS ///

    /// @notice         Adjust mean multiplier of the contract
    /// @param _stake   Bool if `_amount` is being staked or withdrawn
    /// @param _amount  Amount of PDT being staked or withdrawn
    function _adjustMeanMultilpier(bool _stake, uint256 _amount) internal {
        if (totalStaked == 0) {
            adjustedTime = block.timestamp;
            return;
        }

        uint256 previousTotalStaked = totalStaked;
        uint256 previousTimeStaked = adjustedTime;

        uint256 timePassed = block.timestamp - previousTimeStaked;

        uint256 percent;

        if (_stake) {
            percent = (1e18 * _amount) / (previousTotalStaked + _amount);
            adjustedTime += (timePassed * percent) / 1e18;
        } else {
            percent = (1e18 * (previousTotalStaked - _amount)) / (previousTotalStaked);
            adjustedTime -= (timePassed * percent) / 1e18;
       }
    }

    /// @notice        Set epochs of `_user` that they left off on
    /// @param _user   Address of user being updated
    function _setUserMultiplierAtEpoch(address _user) internal {
        uint256 _epochLeftOff = epochLeftOff[_user];

        if (_epochLeftOff != epochId) {
            Stake memory stakeDetail = stakeDetails[_user];

            for (_epochLeftOff; _epochLeftOff < epochId; ++_epochLeftOff) {
                Epoch memory _epoch = epoch[_epochLeftOff];
                if (stakeDetail.amountStaked > 0) {
                    uint256 _multiplierAtEpoch = _multiplier(_epoch.endTime, stakeDetail.adjustedTimeStaked);
                    userMultiplierAtEpoch[_user][_epochLeftOff] = _multiplierAtEpoch;
                    userWeightAtEpoch[_user][_epochLeftOff] = _multiplierAtEpoch * stakeDetail.amountStaked;
                }
            }

            epochLeftOff[_user] = epochId;
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