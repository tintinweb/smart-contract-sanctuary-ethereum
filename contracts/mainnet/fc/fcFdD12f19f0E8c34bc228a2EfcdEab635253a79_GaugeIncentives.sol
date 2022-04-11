// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.7;

// ==========================================
// |            ____  _ __       __         |
// |           / __ \(_) /______/ /_        |
// |          / /_/ / / __/ ___/ __ \       |
// |         / ____/ / /_/ /__/ / / /       |
// |        /_/   /_/\__/\___/_/ /_/        |
// |                                        |
// ==========================================
// ================= Pitch ==================
// ==========================================

// Authored by Pitch Research: [email protected]
// Adapted from 0x7893bbb46613d7a4fbcc31dab4c9b823ffee1026

import "./interfaces/IGaugeController.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";

contract GaugeIncentives is OwnableUpgradeable, UUPSUpgradeable {
    // Use SafeERC20 for transfers
    using SafeERC20Upgradeable for IERC20Upgradeable;

    uint constant WEEK = 86400 * 7;
    uint256 public constant DENOMINATOR = 10000; // denominates weights 10000 = 100%

    // Pitch Multisig with fee modeled after Votium.
    address public feeAddress;
    uint256 public platformFee;
    address public gaugeControllerAddress;
    
    // These mappings were made public, while the bribe.crv.finance implementation keeps them private.
    mapping(address => mapping(address => uint)) public currentlyClaimableRewards;
    mapping(address => mapping(address => uint)) public currentlyClaimedRewards;

    mapping(address => mapping(address => uint)) public activePeriod;
    mapping(address => mapping(address => mapping(address => uint))) public last_user_claim;

    // users can delegate their rewards to another address (key = delegator, value = delegate)
    mapping (address => address) public delegation;
    
    // list of addresses who have pushed pending rewards that should be checked on periodic update.
    mapping (address => mapping (address => address[])) public pendingRewardAddresses;
    
    mapping(address => address[]) _rewardsPerGauge;
    mapping(address => address[]) _gaugesPerReward;
    mapping(address => mapping(address => bool)) _rewardsInGauge;

    // Rewards are intrinsically tied to a certain price per vote.
    struct Reward {
        uint amount;
        uint pricePerPercent;
    }

    // pending rewards are indexed with [gauge][token][user]. each user can only have one reward per gauge per token.
    mapping (address => mapping (address => mapping (address => Reward))) public pendingPricedRewards;

    /* ========== INITIALIZER FUNCTION ========== */ 
    function initialize(address _feeAddress, uint256 _platformFee, address _gaugeControllerAddress) public initializer {
       __Context_init_unchained();
       __Ownable_init_unchained();
       feeAddress = _feeAddress;
       platformFee = _platformFee;
       gaugeControllerAddress = _gaugeControllerAddress;
    }
    /* ========== END INITIALIZER FUNCTION ========== */ 

    /* ========== EXTERNAL VIEW FUNCTIONS ========== */
    function rewardsPerGauge(address _gauge) external view returns (address[] memory) {
        return _rewardsPerGauge[_gauge];
    }
    
    function gaugesPerReward(address _reward) external view returns (address[] memory) {
        return _gaugesPerReward[_reward];
    }

    function getPendingRewardAddresses(address _gauge, address _token) external view returns (address[] memory) {
        return pendingRewardAddresses[_gauge][_token];
    }

    function getPendingPricedRewards(address _gauge, address _token, address _user) external view returns (Reward memory) {
        return pendingPricedRewards[_gauge][_token][_user];
    }

    /**
     * @notice Returns a list of pending priced rewards for a given gauge and reward token.
     * @param _gauge The token underlying the supported gauge.
     * @param _token The incentive deposited on this gauge.
     * @return pendingPRs List of pending rewards.
     */
    function viewPendingPricedRewards(address _gauge, address _token) external view returns (Reward[] memory pendingPRs) {
        uint numPendingRewards = pendingRewardAddresses[_gauge][_token].length;

        pendingPRs = new Reward[](numPendingRewards);

        for (uint i = 0; i < numPendingRewards; i++) {
            address pendingRewardAddress = pendingRewardAddresses[_gauge][_token][i];
            pendingPRs[i] = pendingPricedRewards[_gauge][_token][pendingRewardAddress];
        }
    }

    /**
     * @notice Goes through every pending reward on a [gauge][token] pair and calculates the pending rewards.
     * @param _gauge The token underlying the supported gauge.
     * @param _token The incentive deposited on this gauge.
     * @return _amount the updated reward amount
     */
    function calculatePendingRewards(address _gauge, address _token) public view returns (uint _amount) {
        _amount = 0;

        for (uint i = 0; i < pendingRewardAddresses[_gauge][_token].length; i++) {
            address pendingRewardAddress = pendingRewardAddresses[_gauge][_token][i];
            uint _rewardAmount = viewGaugeReturn(_gauge, _token, pendingRewardAddress);
            _amount += _rewardAmount;
        }
    }
    
    /**
     * @notice Provides a user their quoted share of future rewards. If the contract's not synced with the controller, it'll reference the updated period.
     * @param _user Reward owner
     * @param _gauge The gauge being referenced by this function.
     * @param _token The incentive deposited on this gauge.
     * @return _amount The amount currently claimable
     */
    function claimable(address _user, address _gauge, address _token) external view returns (uint _amount) {
        _amount = 0;

        // current gauge period
        uint _currentPeriod = IGaugeController(gaugeControllerAddress).time_total();
        
        // last checkpointed period
        uint _checkpointedPeriod = activePeriod[_gauge][_token];

        // if now is past the active period, users are eligible to claim
        if (_currentPeriod > _checkpointedPeriod) {
            /* 
             * return indiv/total * (future + current)
             * start by collecting total slopes at the end of period
             */
            uint _totalWeight = IGaugeController(gaugeControllerAddress).points_weight(_gauge, _currentPeriod).bias;
            IGaugeController.VotedSlope memory _individualSlope = IGaugeController(gaugeControllerAddress).vote_user_slopes(_user, _gauge);

            /*
             * avoids a divide by zero problem. 
             * curve-style gauge controllers don't allow votes to kick in until 
             * the following period, so we don't need to track that ourselves 
             */
            if (_totalWeight > 0 && _individualSlope.end > 0) {
                uint _individualWeight = (_individualSlope.end - _currentPeriod) * _individualSlope.slope;
                uint _pendingRewardsAmount = calculatePendingRewards(_gauge, _token);

                /*
                 * includes:
                 * rewards available next period
                 * rewards qualified after the next period
                 * removes rewards that have been claimed
                 */
                uint _totalRewards = currentlyClaimableRewards[_gauge][_token] + _pendingRewardsAmount - currentlyClaimedRewards[_gauge][_token];
                _amount = (_totalRewards * _individualWeight) / _totalWeight;
            } 
        } else {
            // make sure we haven't voted or claimed in the past week
            uint _votingWeek = _checkpointedPeriod - WEEK;
            if (last_user_claim[_user][_gauge][_token] < _votingWeek) {
                uint _totalWeight = IGaugeController(gaugeControllerAddress).points_weight(_gauge, _checkpointedPeriod).bias;
                IGaugeController.VotedSlope memory _individualSlope = IGaugeController(gaugeControllerAddress).vote_user_slopes(_user, _gauge);

                if (_totalWeight > 0 && _individualSlope.end > 0) {
                    uint _individualWeight = (_individualSlope.end - _checkpointedPeriod) * _individualSlope.slope;
                    uint _totalRewards = currentlyClaimableRewards[_gauge][_token];
                    _amount = (_totalRewards * _individualWeight) / _totalWeight;
                }  
            }
        }
    }

    /**
     * @notice Checks whether or not the voter earned rewards have exceeded the originally deposited amount
     * @param _gauge The gauge being referenced by this function.
     * @param _token The incentive deposited on this gauge.
     * @param _pendingRewardAddress Address of rewards depositor
     * @return _amount The amount currently claimable
     */
    function earnedAmountExceedsDeposited(address _gauge, address _token, address _pendingRewardAddress) external view returns (bool) {
        Reward memory pr = pendingPricedRewards[_gauge][_token][_pendingRewardAddress];
        uint currentGaugeWeight = IGaugeController(gaugeControllerAddress).gauge_relative_weight(_gauge);
        return _voterEarnedRewards(pr.pricePerPercent, currentGaugeWeight) > pr.amount;
    }
    /* ========== END EXTERNAL VIEW FUNCTIONS ========== */

    /* ========== EXTERNAL FUNCTIONS ========== */
    /**
     * @notice Referenced from Gnosis' DelegateRegistry (https://github.com/gnosis/delegate-registry/blob/main/contracts/DelegateRegistry.sol)
     * @dev Sets a delegate for the msg.sender. Every msg.sender serves as a unique key.
     * @param delegate Address of the delegate
     */
    function setDelegate(address delegate) external {
        require (delegate != msg.sender, "Can't delegate to self");
        require (delegate != address(0), "Can't delegate to 0x0");
        address currentDelegate = delegation[msg.sender];
        require (delegate != currentDelegate, "Already delegated to this address");
        
        // Update delegation mapping
        delegation[msg.sender] = delegate;
        
        if (currentDelegate != address(0)) {
            emit ClearDelegate(msg.sender, currentDelegate);
        }

        emit SetDelegate(msg.sender, delegate);
    }
    
    /**
     * @notice Referenced from Gnosis' DelegateRegistry (https://github.com/gnosis/delegate-registry/blob/main/contracts/DelegateRegistry.sol)
     * @dev Clears a delegate for the msg.sender. Every msg.sender serves as a unique key.
     */
    function clearDelegate() external {
        address currentDelegate = delegation[msg.sender];
        require (currentDelegate != address(0), "No delegate set");
        
        // update delegation mapping
        delegation[msg.sender]= address(0);
        
        emit ClearDelegate(msg.sender, currentDelegate);
    }

    // if msg.sender is not user,
    function claimDelegatedReward(address _delegatingUser, address _delegatedUser, address _gauge, address _token) external returns (uint _amount) {
        require(delegation[_delegatingUser] == _delegatedUser, "Not the delegated address");
        _amount = _claimDelegatedReward(_delegatingUser, _delegatedUser, _gauge, _token);
        emit DelegateClaimed(_delegatingUser, _delegatedUser, _gauge, _token, _amount);
    }
    
    // if msg.sender is not user,
    function claimReward(address _user, address _gauge, address _token) external returns (uint _amount) {
        _amount = _claimReward(_user, _gauge, _token);
        emit Claimed(_user, _gauge, _token, _amount);
    }

    // if msg.sender is not user,
    function claimReward(address _gauge, address _token) external returns (uint _amount) {
        _amount = _claimReward(msg.sender, _gauge, _token);
        emit Claimed(msg.sender, _gauge, _token, _amount);
    }

    /**
     * @notice Deposits a reward on the gauge, which is stored in future claimable rewards. These will only be claimable once the contract has cleared the vote limit (measured 0 --> 10000 in bps percentage)
     * @param _gauge The gauge being updated by this function.
     * @param _token The incentive deposited on this gauge.
     * @param _amount The amount to deposit on this gauge.
     * @param _pricePerPercent The price paid per basis point of a vote.
     * @return The amount claimed.
     */
    function addRewardAmount(address _gauge, address _token, uint _amount, uint _pricePerPercent) external returns (bool) {
        require(!(
            pendingPricedRewards[_gauge][_token][msg.sender].pricePerPercent != 0 && 
            pendingPricedRewards[_gauge][_token][msg.sender].amount != 0
        ), "Pending reward already exists for sender. Please update instead.");
        require(_amount > 0, "Amount must be greater than 0");
        require(_pricePerPercent > 0, "Price per vote must be greater than 0");
        _updatePeriod(_gauge, _token);

        Reward memory newReward = Reward(_amount, _pricePerPercent);

        pendingPricedRewards[_gauge][_token][msg.sender] = newReward;
        pendingRewardAddresses[_gauge][_token].push(msg.sender);

        IERC20Upgradeable(_token).safeTransferFrom(msg.sender, address(this), _amount);

        _add(_gauge, _token);
        return true;
    }

    /**
     * @notice Deposits a reward on the gauge, which is stored in future claimable rewards. These will only be claimable once the contract has cleared the vote limit (measured 0 --> 10000 in bps percentage)
     * @param _gauge The gauge being updated by this function.
     * @param _token The incentive deposited on this gauge.
     * @param _amount The amount to deposit on this gauge.
     * @param _pricePerPercent The price paid per basis point of a vote.
     * @return The amount claimed.
     */
    function updateRewardAmount(address _gauge, address _token, uint _amount, uint _pricePerPercent) external returns (bool) {
        Reward memory r = pendingPricedRewards[_gauge][_token][msg.sender];
        require(r.pricePerPercent != 0 && r.amount != 0, "Pending reward does not exist. Please pich a new reward.");
        require(_amount >= 0, "Amount must be greater than 0");
        require(_pricePerPercent >= r.pricePerPercent, "Price per vote must monotonically increase");
        require(_amount > 0 || _pricePerPercent > r.pricePerPercent, "Either price per vote or amount must increase");

        uint _newAmount = r.amount + _amount;

        Reward memory newReward = Reward(_newAmount, _pricePerPercent);

        pendingPricedRewards[_gauge][_token][msg.sender] = newReward;

        // replaced the amount variable with our incentiveTotal variable
        IERC20Upgradeable(_token).safeTransferFrom(msg.sender, address(this), _amount);

        return true;
    }

    /* ========== END EXTERNAL FUNCTIONS ========== */
    
    /* ========== INTERNAL FUNCTIONS ========== */

    /**
     * @notice Pure function to compute voter earned rewards
     * @param _pricePerPercent Set price per percent of votes
     * @param _gaugeWeight Ending gauge weight
     * @return Amount voters have earned
     */
    function _voterEarnedRewards(uint _pricePerPercent, uint _gaugeWeight) internal pure returns (uint) {
        return (_pricePerPercent * _gaugeWeight) / (1 * (10**16));
    }

    /**
     * @notice Claims a pro-rata share reward of a voting gauge. This can only be done once per period per reward token per gauge, which is enforced at the Gauge Controller level.
     * @param _user The reward claimer
     * @param _gauge The gauge being updated by this function.
     * @param _token The incentive deposited on this gauge.
     * @return _amount Amount claimed.
     */
    function _claimReward(address _user, address _gauge, address _token) internal returns (uint _amount) {
        _amount = 0;
        uint _period = _updatePeriod(_gauge, _token);
        uint _votingWeek = _period - WEEK;

        if (last_user_claim[_user][_gauge][_token] < _votingWeek) {
            uint _totalWeight = IGaugeController(gaugeControllerAddress).points_weight(_gauge, _period).bias; // bookmark the total slopes at the weds of current period
                
            if (_totalWeight > 0) {
                IGaugeController.VotedSlope memory _individualSlope = IGaugeController(gaugeControllerAddress).vote_user_slopes(_user, _gauge);
                uint _timeRemaining = _individualSlope.end - _period;
                uint _individualWeight = _timeRemaining * _individualSlope.slope;

                uint _totalRewards = currentlyClaimableRewards[_gauge][_token];
                _amount = _totalRewards * _individualWeight / _totalWeight;

                if (_amount > 0) {
                    currentlyClaimedRewards[_gauge][_token] += _amount;
                    last_user_claim[_user][_gauge][_token] = block.timestamp;
                    IERC20Upgradeable(_token).safeTransfer(_user, _amount);
                }
            }
        }
    }

    /**
     * @notice Claims a pro-rata share reward of a voting gauge. This can only be 
     * done once per period per reward token per gauge, which is enforced at the 
     * Gauge Controller level. This should be refactored for elegance eventually.
     * @param _delegatingUser The voter who's delegated their rewards.
     * @param _delegatedUser The delegated reward address.
     * @param _gauge The gauge being updated by this function.
     * @param _token The incentive deposited on this gauge.
     * @return _amount Amount claimed.
     */
    function _claimDelegatedReward(address _delegatingUser, address _delegatedUser, address _gauge, address _token) internal returns (uint _amount) {
        _amount = 0;
        uint _period = _updatePeriod(_gauge, _token);
        uint _votingWeek = _period - WEEK;

        if (last_user_claim[_delegatingUser][_gauge][_token] < _votingWeek) {
            // collect total slopes at end of period
            uint _totalWeight = IGaugeController(gaugeControllerAddress).points_weight(_gauge, _period).bias;
                
            if (_totalWeight > 0) {
                IGaugeController.VotedSlope memory _individualSlope = IGaugeController(gaugeControllerAddress).vote_user_slopes(_delegatingUser, _gauge);
                uint _timeRemaining = _individualSlope.end - _period;
                uint _individualWeight = _timeRemaining * _individualSlope.slope;

                uint _totalRewards = currentlyClaimableRewards[_gauge][_token];
                _amount = _totalRewards * _individualWeight / _totalWeight;

                if (_amount > 0) {
                    currentlyClaimedRewards[_gauge][_token] += _amount;
                    // sends the reward to the delegated user.
                    IERC20Upgradeable(_token).safeTransfer(_delegatedUser, _amount);
                }
            }
        }
    }

    /**
     * @notice Synchronizes this contract's period for a given (gauge, reward) pair with the Gauge Controller, checkpointing votes.
     * @param _gauge The token underlying the supported gauge.
     * @param _token The incentive deposited on this gauge.
     * @return _currentPeriod updated period
     */
    function _updatePeriod(address _gauge, address _token) internal returns (uint _currentPeriod) {
        // Period set to previous wednesday @ 5PM pt
        _currentPeriod = IGaugeController(gaugeControllerAddress).time_total();
        // Period needs to be set to next wednesday @ 5PM pt
        uint _checkpointedPeriod = activePeriod[_gauge][_token];

        if (_currentPeriod > _checkpointedPeriod) {
            IGaugeController(gaugeControllerAddress).checkpoint_gauge(_gauge);

            uint newlyQualifiedRewards = _updatePendingRewards(_gauge, _token);

            // add rewards that are newly qualified into this one
            currentlyClaimableRewards[_gauge][_token] += newlyQualifiedRewards;
            // subtract rewards that have already been claimed
            currentlyClaimableRewards[_gauge][_token] -= currentlyClaimedRewards[_gauge][_token];
            // 0 out the current claimed rewards... could be gas optimized because it's setting it to 0
            currentlyClaimedRewards[_gauge][_token] = 0;
            // syncs our storage with external period
            activePeriod[_gauge][_token] = _currentPeriod; 
        }
    }

    /**
     * @notice Goes through every pending reward on a [gauge][token] pair, calculates the amount on each vote incentive.
     * @param _gauge The token underlying the supported gauge.
     * @param _token The incentive deposited on this gauge.
     * @return _amount Updated pending rewards
     */
    function _updatePendingRewards(address _gauge, address _token) internal returns (uint _amount) {
        _amount = 0;
        uint pendingRewardAddressLength = pendingRewardAddresses[_gauge][_token].length;

        for (uint i = 0; i < pendingRewardAddressLength; i++) {
            address _pendingRewardAddress = pendingRewardAddresses[_gauge][_token][i];

            uint _lrAmount = calculatePendingGaugeAmount(_gauge, _token, _pendingRewardAddress);

            _amount += _lrAmount;

            pendingRewardAddresses[_gauge][_token][i] = pendingRewardAddresses[_gauge][_token][pendingRewardAddressLength-1];
            pendingRewardAddresses[_gauge][_token].pop();
            delete pendingPricedRewards[_gauge][_token][_pendingRewardAddress];
        }
    }

    function calculatePendingGaugeAmount(address _gauge, address _token, address _pendingRewardAddress) internal returns (uint _amount) {
        _amount = 0;
        Reward memory pr = pendingPricedRewards[_gauge][_token][_pendingRewardAddress];
        
        uint currentGaugeWeight = IGaugeController(gaugeControllerAddress).gauge_relative_weight(_gauge);
        uint voterEarnedRewards = _voterEarnedRewards(pr.pricePerPercent, currentGaugeWeight);

        IERC20Upgradeable rewardToken = IERC20Upgradeable(_token);

        if (voterEarnedRewards >= pr.amount) {
            // take the fee on the fully converted amount
            uint256 _fee = (pr.amount*platformFee)/DENOMINATOR;
            uint256 _incentiveTotal = pr.amount-_fee;

            _amount += _incentiveTotal;

            // transfer fee to fee address, doesn't take off the top
            rewardToken.safeTransfer(feeAddress, _fee);
        } else {
            uint _amountClaimable = voterEarnedRewards;
            uint256 _fee = (_amountClaimable * platformFee)/DENOMINATOR;

            // take the whole fee with no dilution
            if (pr.amount > (_amountClaimable + _fee)) {
                _amount += _amountClaimable;

                uint256 _amountToReturn = pr.amount - _amountClaimable - _fee;

                // take fee on the amount now claimable
                rewardToken.safeTransfer(feeAddress, _fee);

                // transfer the remainder to the original address
                rewardToken.safeTransfer(_pendingRewardAddress, _amountToReturn);
            } else {
                uint256 _totalFee = (pr.amount * platformFee)/DENOMINATOR;
                
                uint256 remainingReward = pr.amount - _totalFee;

                _amount += remainingReward;
                
                // take fee on the amount now claimable
                rewardToken.safeTransfer(feeAddress, _totalFee);
            }
        }
    }

    function viewGaugeReturn(address _gauge, address _token, address _pendingRewardAddress) internal view returns (uint) {
        Reward memory pr = pendingPricedRewards[_gauge][_token][_pendingRewardAddress];
        
        uint currentGaugeWeight = IGaugeController(gaugeControllerAddress).gauge_relative_weight(_gauge);

        uint expectedAmountOut = _voterEarnedRewards(pr.pricePerPercent, currentGaugeWeight);
        if (expectedAmountOut > pr.amount) {
            return pr.amount;
        } else {
            return expectedAmountOut;
        }
    }

    /**
     * @notice Adds the reward to internal bookkeeping for visibility at the contract level
     * @param _gauge The token underlying the supported gauge.
     * @param _reward The incentive deposited on this gauge.
     */
    function _add(address _gauge, address _reward) internal {
        if (!_rewardsInGauge[_gauge][_reward]) {
            _rewardsPerGauge[_gauge].push(_reward);
            _gaugesPerReward[_reward].push(_gauge);
            _rewardsInGauge[_gauge][_reward] = true;
        }
    }
    /* ========== END INTERNAL FUNCTIONS ========== */

    /* ========== OWNER FUNCTIONS ========== */
    // used to manage upgrading the contract
    function _authorizeUpgrade(address) internal override onlyOwner {}

    function updateGaugeControllerAddress(address _gaugeControllerAddress) public onlyOwner {
      gaugeControllerAddress = _gaugeControllerAddress;
      emit UpdatedGaugeController(_gaugeControllerAddress);
    }

    // update fee address
    function updateFeeAddress(address _feeAddress) public onlyOwner {
      feeAddress = _feeAddress;
    }

    // update fee amount
    function updateFeeAmount(uint256 _feeAmount) public onlyOwner {
      require(_feeAmount < 400, "max fee"); // Max fee 4%
      platformFee = _feeAmount;
      emit UpdatedFee(_feeAmount);
    }
    /* ========== END OWNER FUNCTIONS ========== */

    /* ========== EVENTS ========== */
    event Claimed(address indexed user, address indexed gauge, address indexed token, uint256 amount);
    event DelegateClaimed(address indexed delegatingUser, address indexed delegatedUser, address indexed gauge, address token, uint256 amount);
    event UpdatedFee(uint256 _feeAmount);
    event UpdatedGaugeController(address gaugeController);
    event SetDelegate(address indexed delegator, address indexed delegate);
    event ClearDelegate(address indexed delegator, address indexed delegate);   
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

interface IGaugeController {
    struct VotedSlope {
        uint slope;
        uint power;
        uint end;
    }
    
    struct Point {
        uint bias;
        uint slope;
    }
    
    function vote_user_slopes(address, address) external view returns (VotedSlope memory);
    function gauge_relative_weight(address) external view returns (uint);
    function last_user_vote(address, address) external view returns (uint);
    function points_weight(address, uint256) external view returns (Point memory);
    function checkpoint_gauge(address) external;
    function time_total() external view returns (uint);
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
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/utils/UUPSUpgradeable.sol)

pragma solidity ^0.8.0;

import "../../interfaces/draft-IERC1822Upgradeable.sol";
import "../ERC1967/ERC1967UpgradeUpgradeable.sol";
import "./Initializable.sol";

/**
 * @dev An upgradeability mechanism designed for UUPS proxies. The functions included here can perform an upgrade of an
 * {ERC1967Proxy}, when this contract is set as the implementation behind such a proxy.
 *
 * A security mechanism ensures that an upgrade does not turn off upgradeability accidentally, although this risk is
 * reinstated if the upgrade retains upgradeability but removes the security mechanism, e.g. by replacing
 * `UUPSUpgradeable` with a custom implementation of upgrades.
 *
 * The {_authorizeUpgrade} function must be overridden to include access restriction to the upgrade mechanism.
 *
 * _Available since v4.1._
 */
abstract contract UUPSUpgradeable is Initializable, IERC1822ProxiableUpgradeable, ERC1967UpgradeUpgradeable {
    function __UUPSUpgradeable_init() internal onlyInitializing {
    }

    function __UUPSUpgradeable_init_unchained() internal onlyInitializing {
    }
    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable state-variable-assignment
    address private immutable __self = address(this);

    /**
     * @dev Check that the execution is being performed through a delegatecall call and that the execution context is
     * a proxy contract with an implementation (as defined in ERC1967) pointing to self. This should only be the case
     * for UUPS and transparent proxies that are using the current contract as their implementation. Execution of a
     * function through ERC1167 minimal proxies (clones) would not normally pass this test, but is not guaranteed to
     * fail.
     */
    modifier onlyProxy() {
        require(address(this) != __self, "Function must be called through delegatecall");
        require(_getImplementation() == __self, "Function must be called through active proxy");
        _;
    }

    /**
     * @dev Check that the execution is not being performed through a delegate call. This allows a function to be
     * callable on the implementing contract but not through proxies.
     */
    modifier notDelegated() {
        require(address(this) == __self, "UUPSUpgradeable: must not be called through delegatecall");
        _;
    }

    /**
     * @dev Implementation of the ERC1822 {proxiableUUID} function. This returns the storage slot used by the
     * implementation. It is used to validate that the this implementation remains valid after an upgrade.
     *
     * IMPORTANT: A proxy pointing at a proxiable contract should not be considered proxiable itself, because this risks
     * bricking a proxy that upgrades to it, by delegating to itself until out of gas. Thus it is critical that this
     * function revert if invoked through a proxy. This is guaranteed by the `notDelegated` modifier.
     */
    function proxiableUUID() external view virtual override notDelegated returns (bytes32) {
        return _IMPLEMENTATION_SLOT;
    }

    /**
     * @dev Upgrade the implementation of the proxy to `newImplementation`.
     *
     * Calls {_authorizeUpgrade}.
     *
     * Emits an {Upgraded} event.
     */
    function upgradeTo(address newImplementation) external virtual onlyProxy {
        _authorizeUpgrade(newImplementation);
        _upgradeToAndCallUUPS(newImplementation, new bytes(0), false);
    }

    /**
     * @dev Upgrade the implementation of the proxy to `newImplementation`, and subsequently execute the function call
     * encoded in `data`.
     *
     * Calls {_authorizeUpgrade}.
     *
     * Emits an {Upgraded} event.
     */
    function upgradeToAndCall(address newImplementation, bytes memory data) external payable virtual onlyProxy {
        _authorizeUpgrade(newImplementation);
        _upgradeToAndCallUUPS(newImplementation, data, true);
    }

    /**
     * @dev Function that should revert when `msg.sender` is not authorized to upgrade the contract. Called by
     * {upgradeTo} and {upgradeToAndCall}.
     *
     * Normally, this function will use an xref:access.adoc[access control] modifier such as {Ownable-onlyOwner}.
     *
     * ```solidity
     * function _authorizeUpgrade(address) internal override onlyOwner {}
     * ```
     */
    function _authorizeUpgrade(address newImplementation) internal virtual;

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20Upgradeable.sol";
import "../../../utils/AddressUpgradeable.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20Upgradeable {
    using AddressUpgradeable for address;

    function safeTransfer(
        IERC20Upgradeable token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20Upgradeable token,
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
        IERC20Upgradeable token,
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
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20Upgradeable token,
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

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20Upgradeable token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
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
// OpenZeppelin Contracts (last updated v4.5.0) (interfaces/draft-IERC1822.sol)

pragma solidity ^0.8.0;

/**
 * @dev ERC1822: Universal Upgradeable Proxy Standard (UUPS) documents a method for upgradeability through a simplified
 * proxy whose upgrades are fully controlled by the current implementation.
 */
interface IERC1822ProxiableUpgradeable {
    /**
     * @dev Returns the storage slot that the proxiable contract assumes is being used to store the implementation
     * address.
     *
     * IMPORTANT: A proxy pointing at a proxiable contract should not be considered proxiable itself, because this risks
     * bricking a proxy that upgrades to it, by delegating to itself until out of gas. Thus it is critical that this
     * function revert if invoked through a proxy.
     */
    function proxiableUUID() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/ERC1967/ERC1967Upgrade.sol)

pragma solidity ^0.8.2;

import "../beacon/IBeaconUpgradeable.sol";
import "../../interfaces/draft-IERC1822Upgradeable.sol";
import "../../utils/AddressUpgradeable.sol";
import "../../utils/StorageSlotUpgradeable.sol";
import "../utils/Initializable.sol";

/**
 * @dev This abstract contract provides getters and event emitting update functions for
 * https://eips.ethereum.org/EIPS/eip-1967[EIP1967] slots.
 *
 * _Available since v4.1._
 *
 * @custom:oz-upgrades-unsafe-allow delegatecall
 */
abstract contract ERC1967UpgradeUpgradeable is Initializable {
    function __ERC1967Upgrade_init() internal onlyInitializing {
    }

    function __ERC1967Upgrade_init_unchained() internal onlyInitializing {
    }
    // This is the keccak-256 hash of "eip1967.proxy.rollback" subtracted by 1
    bytes32 private constant _ROLLBACK_SLOT = 0x4910fdfa16fed3260ed0e7147f7cc6da11a60208b5b9406d12a635614ffd9143;

    /**
     * @dev Storage slot with the address of the current implementation.
     * This is the keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    /**
     * @dev Emitted when the implementation is upgraded.
     */
    event Upgraded(address indexed implementation);

    /**
     * @dev Returns the current implementation address.
     */
    function _getImplementation() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_IMPLEMENTATION_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 implementation slot.
     */
    function _setImplementation(address newImplementation) private {
        require(AddressUpgradeable.isContract(newImplementation), "ERC1967: new implementation is not a contract");
        StorageSlotUpgradeable.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
    }

    /**
     * @dev Perform implementation upgrade
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeTo(address newImplementation) internal {
        _setImplementation(newImplementation);
        emit Upgraded(newImplementation);
    }

    /**
     * @dev Perform implementation upgrade with additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCall(
        address newImplementation,
        bytes memory data,
        bool forceCall
    ) internal {
        _upgradeTo(newImplementation);
        if (data.length > 0 || forceCall) {
            _functionDelegateCall(newImplementation, data);
        }
    }

    /**
     * @dev Perform implementation upgrade with security checks for UUPS proxies, and additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCallUUPS(
        address newImplementation,
        bytes memory data,
        bool forceCall
    ) internal {
        // Upgrades from old implementations will perform a rollback test. This test requires the new
        // implementation to upgrade back to the old, non-ERC1822 compliant, implementation. Removing
        // this special case will break upgrade paths from old UUPS implementation to new ones.
        if (StorageSlotUpgradeable.getBooleanSlot(_ROLLBACK_SLOT).value) {
            _setImplementation(newImplementation);
        } else {
            try IERC1822ProxiableUpgradeable(newImplementation).proxiableUUID() returns (bytes32 slot) {
                require(slot == _IMPLEMENTATION_SLOT, "ERC1967Upgrade: unsupported proxiableUUID");
            } catch {
                revert("ERC1967Upgrade: new implementation is not UUPS");
            }
            _upgradeToAndCall(newImplementation, data, forceCall);
        }
    }

    /**
     * @dev Storage slot with the admin of the contract.
     * This is the keccak-256 hash of "eip1967.proxy.admin" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _ADMIN_SLOT = 0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;

    /**
     * @dev Emitted when the admin account has changed.
     */
    event AdminChanged(address previousAdmin, address newAdmin);

    /**
     * @dev Returns the current admin.
     */
    function _getAdmin() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_ADMIN_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 admin slot.
     */
    function _setAdmin(address newAdmin) private {
        require(newAdmin != address(0), "ERC1967: new admin is the zero address");
        StorageSlotUpgradeable.getAddressSlot(_ADMIN_SLOT).value = newAdmin;
    }

    /**
     * @dev Changes the admin of the proxy.
     *
     * Emits an {AdminChanged} event.
     */
    function _changeAdmin(address newAdmin) internal {
        emit AdminChanged(_getAdmin(), newAdmin);
        _setAdmin(newAdmin);
    }

    /**
     * @dev The storage slot of the UpgradeableBeacon contract which defines the implementation for this proxy.
     * This is bytes32(uint256(keccak256('eip1967.proxy.beacon')) - 1)) and is validated in the constructor.
     */
    bytes32 internal constant _BEACON_SLOT = 0xa3f0ad74e5423aebfd80d3ef4346578335a9a72aeaee59ff6cb3582b35133d50;

    /**
     * @dev Emitted when the beacon is upgraded.
     */
    event BeaconUpgraded(address indexed beacon);

    /**
     * @dev Returns the current beacon.
     */
    function _getBeacon() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_BEACON_SLOT).value;
    }

    /**
     * @dev Stores a new beacon in the EIP1967 beacon slot.
     */
    function _setBeacon(address newBeacon) private {
        require(AddressUpgradeable.isContract(newBeacon), "ERC1967: new beacon is not a contract");
        require(
            AddressUpgradeable.isContract(IBeaconUpgradeable(newBeacon).implementation()),
            "ERC1967: beacon implementation is not a contract"
        );
        StorageSlotUpgradeable.getAddressSlot(_BEACON_SLOT).value = newBeacon;
    }

    /**
     * @dev Perform beacon upgrade with additional setup call. Note: This upgrades the address of the beacon, it does
     * not upgrade the implementation contained in the beacon (see {UpgradeableBeacon-_setImplementation} for that).
     *
     * Emits a {BeaconUpgraded} event.
     */
    function _upgradeBeaconToAndCall(
        address newBeacon,
        bytes memory data,
        bool forceCall
    ) internal {
        _setBeacon(newBeacon);
        emit BeaconUpgraded(newBeacon);
        if (data.length > 0 || forceCall) {
            _functionDelegateCall(IBeaconUpgradeable(newBeacon).implementation(), data);
        }
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function _functionDelegateCall(address target, bytes memory data) private returns (bytes memory) {
        require(AddressUpgradeable.isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return AddressUpgradeable.verifyCallResult(success, returndata, "Address: low-level delegate call failed");
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/beacon/IBeacon.sol)

pragma solidity ^0.8.0;

/**
 * @dev This is the interface that {BeaconProxy} expects of its beacon.
 */
interface IBeaconUpgradeable {
    /**
     * @dev Must return an address that can be used as a delegate call target.
     *
     * {BeaconProxy} will check that this address is a contract.
     */
    function implementation() external view returns (address);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/StorageSlot.sol)

pragma solidity ^0.8.0;

/**
 * @dev Library for reading and writing primitive types to specific storage slots.
 *
 * Storage slots are often used to avoid storage conflict when dealing with upgradeable contracts.
 * This library helps with reading and writing to such slots without the need for inline assembly.
 *
 * The functions in this library return Slot structs that contain a `value` member that can be used to read or write.
 *
 * Example usage to set ERC1967 implementation slot:
 * ```
 * contract ERC1967 {
 *     bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
 *
 *     function _getImplementation() internal view returns (address) {
 *         return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
 *     }
 *
 *     function _setImplementation(address newImplementation) internal {
 *         require(Address.isContract(newImplementation), "ERC1967: new implementation is not a contract");
 *         StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
 *     }
 * }
 * ```
 *
 * _Available since v4.1 for `address`, `bool`, `bytes32`, and `uint256`._
 */
library StorageSlotUpgradeable {
    struct AddressSlot {
        address value;
    }

    struct BooleanSlot {
        bool value;
    }

    struct Bytes32Slot {
        bytes32 value;
    }

    struct Uint256Slot {
        uint256 value;
    }

    /**
     * @dev Returns an `AddressSlot` with member `value` located at `slot`.
     */
    function getAddressSlot(bytes32 slot) internal pure returns (AddressSlot storage r) {
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `BooleanSlot` with member `value` located at `slot`.
     */
    function getBooleanSlot(bytes32 slot) internal pure returns (BooleanSlot storage r) {
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Bytes32Slot` with member `value` located at `slot`.
     */
    function getBytes32Slot(bytes32 slot) internal pure returns (Bytes32Slot storage r) {
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Uint256Slot` with member `value` located at `slot`.
     */
    function getUint256Slot(bytes32 slot) internal pure returns (Uint256Slot storage r) {
        assembly {
            r.slot := slot
        }
    }
}