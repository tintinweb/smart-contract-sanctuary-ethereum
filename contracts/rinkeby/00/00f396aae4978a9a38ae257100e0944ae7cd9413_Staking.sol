/**
 *Submitted for verification at Etherscan.io on 2022-06-07
*/

// File @openzeppelin/contracts/token/ERC20/[email protected]

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


// File contracts/Deploy.sol

pragma solidity ^0.8.7;

/// @title   PDT Staking
/// @notice  Contract that allows users to stake PDT
contract Staking {
    /// ERRORS ///

    /// @notice Error for if epoch is invalid
    error InvalidEpoch();
    /// @notice Error for if user has claimed for epoch
    error EpochClaimed();
    /// @notice Error for if there is nothing to claim
    error NothingToClaim();

    /// STATE VARIABLES ///

    /// @notice Starting multiplier
    uint256 public constant multiplierStart = 1e18;
    /// @notice Length of epoch
    uint256 public immutable epochLength;

    /// @notice Timestmap contract was deplpoyed
    uint256 public immutable startTime;
    /// @notice Time to double multiplier
    uint256 public immutable timeToDouble;

    /// @notice Adjusted time for contract
    uint256 private adjustedTime;

    /// @notice Total amount of PDT staked
    uint256 public totalStaked;
    /// @notice Last interaction with contract
    uint256 private timeSinceLastInteraction;
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

    /// @notice If user has claimed for certain epoch
    mapping(address => mapping(uint256 => bool)) userClaimedEpoch;
    /// @notice User's multiplier at end of epoch
    mapping(address => mapping(uint256 => uint256)) userMultiplierAtEpoch;
    /// @notice User's weight at an epoch
    mapping(address => mapping(uint256 => uint256)) userWeightAtEpoch;
    /// @notice Epoch user has last claimed
    mapping(address => uint256) epochLeftOff;
    /// @notice Id to epoch details
    mapping(uint256 => Epoch) public epoch;
    /// @notice Stake details of user
    mapping(address => Stake) public stakeDetails;

    /// STRUCTS ///

    /// @notice                     Details for epoch
    /// @param totalToDistirbute    Total amount of token to distirbute for epoch
    /// @param totalClaimed         Total amount of tokens claimed from epoch
    /// @param startTime            Timestamp epoch started
    /// @param endTime              Timestamp epoch ends
    /// @param meanMultiplierAtEnd  Mean multiplier at end of epoch
    /// @param weightAtEnd          Weight of staked tokens at end of epoch
    struct Epoch {
        uint256 totalToDistirbute;
        uint256 totalClaimed;
        uint256 startTime;
        uint256 endTime;
        uint256 meanMultiplierAtEnd;
        uint256 weightAtEnd;
    }

    /// @notice                    Stake details for user
    /// @param amountStaked        Amount user has staked
    /// @param adjustedTimeStaked  Adjusted time user staked
    /// @param lastInteraction     Timestamp last interacted
    struct Stake {
        uint256 amountStaked;
        uint256 adjustedTimeStaked;
        uint256 lastInteraction;
    }

    /// CONSTRUCTOR ///

    /// @param _timeToDouble  Time for multiplier to double
    /// @param _epochLength   Length of epoch
    /// @param _pdt           PDT token address
    /// @param _rewardToken   Address of reward token
    constructor(
        uint256 _timeToDouble,
        uint256 _epochLength,
        address _pdt,
        address _rewardToken
    ) {
        startTime = block.timestamp;
        timeToDouble = _timeToDouble;
        epochLength = _epochLength;
        pdt = _pdt;
        rewardToken = _rewardToken;
    }

    /// PUBLIC FUNCTIONS ///

    /// @notice  Update epoch details if time
    function distirbute() external {
        if (block.timestamp >= currentEpoch.endTime) {
            epoch[epochId].meanMultiplierAtEnd = meanMultiplier();
            epoch[epochId].weightAtEnd = meanMultiplier() * totalStaked;

            ++epochId;
            Epoch memory _epoch = epoch[epochId];
            _epoch.totalToDistirbute = IERC20(rewardToken).balanceOf(address(this)) - unclaimedRewards;
            _epoch.totalClaimed = 0;
            _epoch.startTime = block.timestamp;
            _epoch.endTime = block.timestamp + epochLength;

            currentEpoch = _epoch;
            epoch[epochId] = _epoch;

            unclaimedRewards += _epoch.totalToDistirbute;
        }
    }

    /// @notice         Stake PDT
    /// @param _to      Address that will recieve credit for stake
    /// @param _amount  Amount of PDT to stake
    function stake(address _to, uint256 _amount) external {
        _setUserMultiplierAtEpoch(msg.sender);
        IERC20(pdt).transferFrom(msg.sender, address(this), _amount);

        _adjustMeanMultilpier(true, _amount);

        totalStaked += _amount;

        Stake memory stakeDetail = stakeDetails[_to];

        uint256 previousStakeAmount = stakeDetail.amountStaked;
        uint256 previousTimeStaked = stakeDetail.adjustedTimeStaked;

        uint256 percentStakeIncreased = (1e18 * _amount) / previousStakeAmount;

        stakeDetail.amountStaked += _amount;
        stakeDetail.adjustedTimeStaked = previousTimeStaked + ((percentStakeIncreased * previousTimeStaked) / 1e18);
        stakeDetail.lastInteraction = block.timestamp;

        stakeDetails[_to] = stakeDetail;
    }

    /// @notice         Unstake PDT
    /// @param _to      Address that will recieve PDT unstaked
    /// @param _amount  Amount of PDT to unstake
    function unstake(address _to, uint256 _amount) external {
        _setUserMultiplierAtEpoch(msg.sender);
        _adjustMeanMultilpier(false, _amount);

        totalStaked -= _amount;

        Stake memory stakeDetail = stakeDetails[msg.sender];

        uint256 previousStakeAmount = stakeDetail.amountStaked;
        uint256 previousTimeStaked = stakeDetail.adjustedTimeStaked;

        uint256 percentStakeDecreased = (1e18 * _amount) / previousStakeAmount;

        stakeDetail.amountStaked -= _amount;
        stakeDetail.adjustedTimeStaked = previousTimeStaked - ((percentStakeDecreased * previousTimeStaked) / 1e18);
        stakeDetail.lastInteraction = block.timestamp;

        IERC20(pdt).transfer(_to, _amount);
        stakeDetails[msg.sender] = stakeDetail;
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
            uint256 _epochRewards = (_epoch.totalToDistirbute * _userWeightAtEpoch) / weightAtEpoch(_epochIds[i]);
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
    function multipierIndex() public view returns (uint256 index_) {
        uint256 _timePassed = block.timestamp - startTime;
        index_ = multiplierStart + ((multiplierStart * _timePassed) / timeToDouble);
    }

    /// @notice              Returns contracts mean multiplier
    /// @return multiplier_  Current mean multiplier of contract
    function meanMultiplier() public view returns (uint256 multiplier_) {
        uint256 _timePassed = block.timestamp - timeSinceLastInteraction;
        uint256 _adjustedTime = adjustedTime + _timePassed;
        multiplier_ = multiplierStart + ((multiplierStart * _adjustedTime) / timeToDouble);
    }

    /// @notice              Returns `multiplier_' of `_user`
    /// @param _user         Address of who getting `multiplier_` for
    /// @return multiplier_  Current multiplier of `_user`
    function userStakeMultiplier(address _user) public view returns (uint256 multiplier_) {
        Stake memory stakeDetail = stakeDetails[_user];
        uint256 _timeSinceLastInteraction = block.timestamp - stakeDetail.lastInteraction;
        uint256 _adjustedTime = stakeDetail.adjustedTimeStaked + _timeSinceLastInteraction;

        multiplier_ = multiplierStart + ((multiplierStart * _adjustedTime) / timeToDouble);
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
            uint256 _interactionSinceEpochEnd = _epoch.endTime - stakeDetail.lastInteraction;
            uint256 _adjustedTime = stakeDetail.adjustedTimeStaked + _interactionSinceEpochEnd;
            multiplier_ = multiplierStart + ((multiplierStart * _adjustedTime) / timeToDouble);
        }
    }

    /// @notice          Returns weight of contract at `_epochId`
    /// @param _epochId  Id of epoch wanting to get weight for
    /// @return uint256  Weight of contract for `_epochId`
    function weightAtEpoch(uint256 _epochId) public view returns (uint256) {
        if (epochId <= _epochId) revert InvalidEpoch();
        return epoch[_epochId].weightAtEnd;
    }

    /// INTERNAL FUNCTIONS ///

    /// @notice         Adjust mean multiplier of the contract
    /// @param _stake   Bool if `_amount` is being staked or withdrawn
    /// @param _amount  Amount of PDT being staked or withdrawn
    function _adjustMeanMultilpier(bool _stake, uint256 _amount) internal {
        uint256 previousTotalStaked = totalStaked;
        uint256 previousTimeStaked = adjustedTime;

        uint256 percent = (1e18 * _amount) / previousTotalStaked;

        if (_stake) {
            adjustedTime = previousTimeStaked + ((percent * previousTimeStaked) / 1e18);
        } else {
            adjustedTime = previousTimeStaked - ((percent * previousTimeStaked) / 1e18);
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
                uint256 _interactionSinceEpochEnd = _epoch.endTime - stakeDetail.lastInteraction;
                uint256 _adjustedTime = stakeDetail.adjustedTimeStaked + _interactionSinceEpochEnd;
                uint256 _multiplier = multiplierStart + ((multiplierStart * _adjustedTime) / timeToDouble);
                userMultiplierAtEpoch[_user][_epochLeftOff] = _multiplier;
                userWeightAtEpoch[_user][_epochLeftOff] = _multiplier * stakeDetail.amountStaked;
            }

            epochLeftOff[_user] = epochId;
        }
    }
}