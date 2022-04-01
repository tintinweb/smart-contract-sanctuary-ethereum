// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.6;

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

// Original idea and credit: 
// Curve Finance's Incentive System 
// bribe.crv.finance
// https://etherscan.io/address/0x7893bbb46613d7a4fbcc31dab4c9b823ffee1026

// Primary Author(s)
// Charlie Pyle: https://github.com/charliepyle

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

// Base Interface used to interact with a curve-style gauge system, an example of which can be found here: https://etherscan.io/address/0x3669C421b77340B2979d1A00a792CC2ee0FcE737
interface GaugeController {
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

interface erc20 { 
    function transfer(address recipient, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}

contract GaugeIncentives is OwnableUpgradeable, UUPSUpgradeable {
    uint constant WEEK = 86400 * 7;
    uint256 public constant DENOMINATOR = 10000; // denominates weights 10000 = 100%
    
    // Allows rewards that aren't claimable until the votes pass a certain threshold. Are redeemable at any point.
    struct LimitReward {
        uint amount;
        uint threshold; // scaled between 0 and 10000 in BPs
    }

    // Pitch Multisig with fee modeled after Votium.
    address public feeAddress;
    uint256 public platformFee;
    address public gaugeControllerAddress;
    
    // These mappings were made public, while the bribe.crv.finance implementation keeps them private.
    mapping(address => mapping(address => uint)) public currentlyClaimableRewards;
    mapping(address => mapping(address => uint)) public currentlyClaimedRewards;
    mapping(address => mapping(address => uint)) public futureClaimableRewards;
    mapping(address => mapping(address => uint)) public activePeriod;
    mapping(address => mapping(address => mapping(address => uint))) public last_user_claim;

    // users can delegate their rewards to another address (key = delegator, value = delegate)
    mapping (address => address) public delegation;

    // pending rewards are indexed with [gauge][token][user]. each user can only have one limit reward per gauge per token.
    mapping (address => mapping (address => mapping (address => LimitReward))) public pendingRewards;
    
    // list of addresses who have pushed pending rewards that should be checked on periodic update.
    mapping (address => mapping (address => address[])) public pendingRewardAddresses;
    
    mapping(address => address[]) _rewardsPerGauge;
    mapping(address => address[]) _gaugesPerReward;
    mapping(address => mapping(address => bool)) _rewardsInGauge;

    

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

    /**
     * @notice Returns a list of pending limit orders for a given gauge and reward token.
     * @param _gauge The token underlying the supported gauge.
     * @param _rewardToken The incentive deposited on this gauge.
     * @return pendingLRs List of pending limit rewards.
     */
    function pendingLimitRewards(address _gauge, address _rewardToken) external view returns (LimitReward[] memory pendingLRs) {
        uint numPendingLimitRewards = pendingRewardAddresses[_gauge][_rewardToken].length;

        LimitReward[] memory _pendingLRs = new LimitReward[](numPendingLimitRewards);

        for (uint i = 0; i < numPendingLimitRewards; i++) {
            address pendingRewardAddress = pendingRewardAddresses[_gauge][_rewardToken][i];
            _pendingLRs[i] = pendingRewards[_gauge][_rewardToken][pendingRewardAddress];
        }

        return _pendingLRs;
    }

    /**
     * @notice Goes through every pending reward on a [gauge][token] pair and calculates the pending rewards.
     * @param _gauge The token underlying the supported gauge.
     * @param _rewardToken The incentive deposited on this gauge.
     * @return amount the updated 
     */
    function calculatePendingRewards(address _gauge, address _rewardToken) public view returns (uint amount) {
        uint _amount = 0;

        for (uint i = 0; i < pendingRewardAddresses[_gauge][_rewardToken].length; i++) {
            address pendingRewardAddress = pendingRewardAddresses[_gauge][_rewardToken][i];
            LimitReward memory lr = pendingRewards[_gauge][_rewardToken][pendingRewardAddress];

            uint currentGaugeWeight = GaugeController(gaugeControllerAddress).gauge_relative_weight(_gauge);

            // only include amounts for fulfilled orders (threshold is scaled up 10**14 to work with gauge_relative_weight)
            if (currentGaugeWeight >= (lr.threshold * 10**14)) {
                _amount += lr.amount;
            }

        }
        return _amount;
    }
    
    /**
     * @notice Provides a user their quoted share of future rewards. If the contract's not synced with the controller, it'll reference the updated period.
     * @param _user Reward owner
     * @param _gauge The gauge being referenced by this function.
     * @param _rewardToken The incentive deposited on this gauge.
     * @return _amount The amount currently claimable
     */
    function claimable(address _user, address _gauge, address _rewardToken) external view returns (uint) {
        uint _amount = 0;
        uint _currentPeriod = GaugeController(gaugeControllerAddress).time_total(); // get the current gauge period
        
        uint _checkpointedPeriod = activePeriod[_gauge][_rewardToken]; // reference our current bookmarked period

        // if now is past the active period, they're definitely eligible to claim, so we return indiv/total * (future + current)
        if (_currentPeriod > _checkpointedPeriod) {
            
            uint _totalWeight = GaugeController(gaugeControllerAddress).points_weight(_gauge, _currentPeriod).bias; // bookmark the total slopes at the weds of current period
            GaugeController.VotedSlope memory _individualSlope = GaugeController(gaugeControllerAddress).vote_user_slopes(_user, _gauge);

            // avoids a divide by zero problem. curve-style gauge controllers don't allow votes to kick in until the following period, so we don't need to track that ourselves
            if (_totalWeight > 0 && _individualSlope.end > 0) {
                uint _individualWeight = (_individualSlope.end - _currentPeriod) * _individualSlope.slope;

                uint _pendingRewardsAmount = calculatePendingRewards(_gauge, _rewardToken);

                // includes rewards that will certainly be available next period, rewards that will since be qualified after the next period, and removes rewards that have since been claimed.
                uint _totalRewards = currentlyClaimableRewards[_gauge][_rewardToken] + _pendingRewardsAmount + futureClaimableRewards[_gauge][_rewardToken] - currentlyClaimedRewards[_gauge][_rewardToken];
                _amount = _totalRewards * _individualWeight / _totalWeight;
            }   
        }
        else {
            // otherwise, we need to make sure they haven't claimed in the past week and that they haven't voted in the past week
            uint _votingWeek = _checkpointedPeriod - WEEK;
            if (last_user_claim[_user][_gauge][_rewardToken] < _votingWeek) {
                uint _totalWeight = GaugeController(gaugeControllerAddress).points_weight(_gauge, _checkpointedPeriod).bias; // bookmark the total slopes at the weds of current period
                GaugeController.VotedSlope memory _individualSlope = GaugeController(gaugeControllerAddress).vote_user_slopes(_user, _gauge);
                if (_totalWeight > 0 && _individualSlope.end > 0) {
                    
                    uint _individualWeight = (_individualSlope.end - _checkpointedPeriod) * _individualSlope.slope;
                    uint _totalRewards = currentlyClaimableRewards[_gauge][_rewardToken];
                    _amount = _totalRewards * _individualWeight / _totalWeight;
                }  
            }
        }
        
        return _amount;
        
    }

    /* ========== END EXTERNAL VIEW FUNCTIONS ========== */

    /* ========== EXTERNAL FUNCTIONS ========== */

    /**
     * @notice Referenced from Gnosis' DelegateRegistry, found here: https://github.com/gnosis/delegate-registry/blob/main/contracts/DelegateRegistry.sol
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
     * @notice Referenced from Gnosis' DelegateRegistry, found here: https://github.com/gnosis/delegate-registry/blob/main/contracts/DelegateRegistry.sol
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
    function claimDelegatedReward(address _delegatingUser, address _delegatedUser, address _gauge, address _rewardToken) external returns (uint) {
        require(delegation[_delegatingUser] == _delegatedUser, "Not the delegated address");
        uint _amount = _claimDelegatedReward(_delegatingUser, _delegatedUser, _gauge, _rewardToken);
        emit DelegateClaimed(_delegatingUser, _delegatedUser, _gauge, _rewardToken, _amount);
        return _amount;
    }
    
    // if msg.sender is not user,
    function claimReward(address _user, address _gauge, address _rewardToken) external returns (uint) {
        uint _amount = _claimReward(_user, _gauge, _rewardToken);
        emit Claimed(_user, _gauge, _rewardToken, _amount);
        return _amount;
    }

    // if msg.sender is not user,
    function claimReward(address _gauge, address _rewardToken) external returns (uint) {
        uint _amount = _claimReward(msg.sender, _gauge, _rewardToken);
        emit Claimed(msg.sender, _gauge, _rewardToken, _amount);
        return _amount;
    }

    /**
     * @notice Deposits a reward on the gauge, which is stored in future claimable rewards. These will be claimable once the contract updates to the next period.
     * @param _gauge The gauge being updated by this function.
     * @param _rewardToken The incentive deposited on this gauge.
     * @param _amount The amount to deposit on this gauge.
     * @return The amount claimed.
     */
    function addRewardAmount(address _gauge, address _rewardToken, uint _amount) external returns (bool) {
        _updatePeriod(_gauge, _rewardToken);
        
        // The below was added to the bribe.crv.finance implementation to handle fee distribution
        uint256 _fee = _amount*platformFee/DENOMINATOR;
        uint256 _incentiveTotal = _amount-_fee;
        _safeTransferFrom(_rewardToken, msg.sender, feeAddress, _fee);
        
        // replaced the amount variable with our incentiveTotal variable
        _safeTransferFrom(_rewardToken, msg.sender, address(this), _incentiveTotal);

        futureClaimableRewards[_gauge][_rewardToken] += _incentiveTotal;

        _add(_gauge, _rewardToken);
        return true;
    }

    /**
     * @notice Deposits a reward on the gauge, which is stored in future claimable rewards. These will only be claimable once the contract has cleared the vote limit (measured 0 --> 10000 in bps percentage)
     * @param _gauge The gauge being updated by this function.
     * @param _rewardToken The incentive deposited on this gauge.
     * @param _amount The amount to deposit on this gauge.
     * @param _threshold The amount to deposit on this gauge.
     * @return The amount claimed.
     */
    function addLimitRewardAmount(address _gauge, address _rewardToken, uint _amount, uint _threshold) external returns (bool) {
        require(!(pendingRewards[_gauge][_rewardToken][msg.sender].threshold != 0 && pendingRewards[_gauge][_rewardToken][msg.sender].amount != 0), "Pending reward already exists for sender. Please update instead.");
        require(_amount > 0, "Amount must be greater than 0");
        require(_threshold > 0 && _threshold <= 10000, "Threshold must be greater than 0 and less than 10000");
        _updatePeriod(_gauge, _rewardToken);
        
        // The below was added to the bribe.crv.finance implementation to handle fee distribution
        uint256 _fee = _amount*platformFee/DENOMINATOR;
        uint256 _incentiveTotal = _amount-_fee;
        _safeTransferFrom(_rewardToken, msg.sender, feeAddress, _fee);
        
        // replaced the amount variable with our incentiveTotal variable
        _safeTransferFrom(_rewardToken, msg.sender, address(this), _incentiveTotal);

        LimitReward memory newLimit = LimitReward(_incentiveTotal, _threshold);

        pendingRewards[_gauge][_rewardToken][msg.sender] = newLimit;
        pendingRewardAddresses[_gauge][_rewardToken].push(msg.sender);

        _add(_gauge, _rewardToken);
        return true;
    }

    /**
     * @notice Updates a limit reward that's been deposited on behalf of msg.sender. This can be done to modify the threshold, increase the amount, or withdraw the limit reward altogether.
     * @param _gauge The gauge being updated by this function.
     * @param _rewardToken The incentive deposited on this gauge.
     * @param _amount The new amount that the user would like.
     * @param _threshold The amount to deposit on this gauge.
     * @return The amount claimed.
     */
    function updateLimitRewardAmount(address _gauge, address _rewardToken, uint _amount, uint _threshold) external returns (bool) {
        LimitReward memory lr = pendingRewards[_gauge][_rewardToken][msg.sender];
        require(lr.threshold != 0 && lr.amount != 0, "Pending reward does not exist for msg.sender");
        require(_threshold > 0 && _threshold <= 10000, "Threshold must be greater than 0 and less than 10000");
        require(_threshold <= lr.threshold, "Cannot increase threshold");
        require(_amount >= (lr.amount * 5 / 4), "Must increase amount by 25% on limit order modifications");
        
        // fulfilled limit orders cannot be modified
        uint currentGaugeWeight = GaugeController(gaugeControllerAddress).gauge_relative_weight(_gauge);
        require((lr.threshold * (10 ** 14)) > currentGaugeWeight, "Already crossed threshold - not modifiable");

        // calculate the delta to subtract fee
        uint _delta = _amount - lr.amount;
        uint256 _fee = _delta*platformFee/DENOMINATOR;
        uint256 _deltaMinusFees = _delta-_fee;

        uint _newTotal = _deltaMinusFees + lr.amount;

        // sends the new fee to address
        _safeTransferFrom(_rewardToken, msg.sender, feeAddress, _fee);
        
        // transfers the delta here
        _safeTransferFrom(_rewardToken, msg.sender, address(this), _deltaMinusFees);

        LimitReward memory newLimit = LimitReward(_newTotal, _threshold);

        pendingRewards[_gauge][_rewardToken][msg.sender] = newLimit;

        return true;
    }

    /* ========== END EXTERNAL FUNCTIONS ========== */
    
    /* ========== INTERNAL FUNCTIONS ========== */
    
    /**
     * @notice Claims a pro-rata share reward of a voting gauge. This can only be done once per period per reward token per gauge, which is enforced at the Gauge Controller level.
     * @param _user The reward claimer
     * @param _gauge The gauge being updated by this function.
     * @param _rewardToken The incentive deposited on this gauge.
     * @return The amount claimed.
     */
    function _claimReward(address _user, address _gauge, address _rewardToken) internal returns (uint) {
        uint _period = _updatePeriod(_gauge, _rewardToken);
        uint _amount = 0;
        uint _votingWeek = _period - WEEK;

        if (last_user_claim[_user][_gauge][_rewardToken] < _votingWeek) {
            uint _totalWeight = GaugeController(gaugeControllerAddress).points_weight(_gauge, _period).bias; // bookmark the total slopes at the weds of current period
                
            if (_totalWeight > 0) {
                GaugeController.VotedSlope memory _individualSlope = GaugeController(gaugeControllerAddress).vote_user_slopes(_user, _gauge);
                uint _timeRemaining = _individualSlope.end - _period;
                uint _individualWeight = _timeRemaining * _individualSlope.slope;

                uint _totalRewards = currentlyClaimableRewards[_gauge][_rewardToken];
                _amount = _totalRewards * _individualWeight / _totalWeight;

                if (_amount > 0) {
                    currentlyClaimedRewards[_gauge][_rewardToken] += _amount;
                    last_user_claim[_user][_gauge][_rewardToken] = block.timestamp;
                    _safeTransfer(_rewardToken, _user, _amount);
                }
            }
        }

        return _amount;
    }

    /**
     * @notice Claims a pro-rata share reward of a voting gauge. This can only be done once per period per reward token per gauge, which is enforced at the Gauge Controller level. This should be refactored for elegance eventually.
     * @param _delegatingUser The voter who's delegated their rewards.
     * @param _delegatedUser The delegated reward address.
     * @param _gauge The gauge being updated by this function.
     * @param _rewardToken The incentive deposited on this gauge.
     * @return The amount claimed.
     */
    function _claimDelegatedReward(address _delegatingUser, address _delegatedUser, address _gauge, address _rewardToken) internal returns (uint) {
        uint _period = _updatePeriod(_gauge, _rewardToken);
        uint _amount = 0;
        uint _votingWeek = _period - WEEK;

        if (last_user_claim[_delegatingUser][_gauge][_rewardToken] < _votingWeek) {
            uint _totalWeight = GaugeController(gaugeControllerAddress).points_weight(_gauge, _period).bias; // bookmark the total slopes at the weds of current period
                
            if (_totalWeight > 0) {
                GaugeController.VotedSlope memory _individualSlope = GaugeController(gaugeControllerAddress).vote_user_slopes(_delegatingUser, _gauge);
                uint _timeRemaining = _individualSlope.end - _period;
                uint _individualWeight = _timeRemaining * _individualSlope.slope;

                uint _totalRewards = currentlyClaimableRewards[_gauge][_rewardToken];
                _amount = _totalRewards * _individualWeight / _totalWeight;

                if (_amount > 0) {
                    currentlyClaimedRewards[_gauge][_rewardToken] += _amount;
                    // sends the reward to the delegated user.
                    _safeTransfer(_rewardToken, _delegatedUser, _amount);
                }
            }
        }

        return _amount;
    }

    /**
     * @notice Synchronizes this contract's period for a given (gauge, reward) pair with the Gauge Controller, checkpointing votes.
     * @param _gauge The token underlying the supported gauge.
     * @param _rewardToken The incentive deposited on this gauge.
     * @return The updated period
     */
    function _updatePeriod(address _gauge, address _rewardToken) internal returns (uint) {

        uint _currentPeriod = GaugeController(gaugeControllerAddress).time_total(); // period set to the previous weds at 5pm 
        uint _checkpointedPeriod = activePeriod[_gauge][_rewardToken]; // period needs to be hardcoded to next weds @ 5pm
        if (_currentPeriod > _checkpointedPeriod) {
            
            GaugeController(gaugeControllerAddress).checkpoint_gauge(_gauge);

            uint newlyQualifiedRewards = _updatePendingRewards(_gauge, _rewardToken);

            currentlyClaimableRewards[_gauge][_rewardToken] += futureClaimableRewards[_gauge][_rewardToken]; // add rewards that were signaled for next period into this one
            currentlyClaimableRewards[_gauge][_rewardToken] += newlyQualifiedRewards; // add rewards that are newly qualified into this one
            currentlyClaimableRewards[_gauge][_rewardToken] -= currentlyClaimedRewards[_gauge][_rewardToken]; // subtract rewards that have already been claimed
            currentlyClaimedRewards[_gauge][_rewardToken] = 0; // 0 out the current claimed rewards... could be gas optimized because it's setting it to 0
            futureClaimableRewards[_gauge][_rewardToken] = 0; // 0 out the future as well - could be gas optimized optimized.

            activePeriod[_gauge][_rewardToken] = _currentPeriod; // syncs our storage with external period
        }
        return _currentPeriod;
    }

    /**
     * @notice Goes through every pending reward on a [gauge][token] pair, and if the gauge has passed the threshold, it removes it from the list and frees its amount.
     * @param _gauge The token underlying the supported gauge.
     * @param _rewardToken The incentive deposited on this gauge.
     * @return The updated period
     */
    function _updatePendingRewards(address _gauge, address _rewardToken) internal returns (uint) {
        uint _amount = 0;
        uint pendingRewardAddressLength = pendingRewardAddresses[_gauge][_rewardToken].length;
        for (uint i = 0; i < pendingRewardAddressLength; i++) {
            address pendingRewardAddress = pendingRewardAddresses[_gauge][_rewardToken][i];
            LimitReward memory lr = pendingRewards[_gauge][_rewardToken][pendingRewardAddress];

            uint currentGaugeWeight = GaugeController(gaugeControllerAddress).gauge_relative_weight(_gauge);

            // scaled the bps by 10**14
            if (currentGaugeWeight > (lr.threshold * (10 ** 14))) {
                _amount += lr.amount;
                
                // shifts final element to the current element and pops off last element for length preservation
                pendingRewardAddresses[_gauge][_rewardToken][i] = pendingRewardAddresses[_gauge][_rewardToken][pendingRewardAddressLength-1];
                pendingRewardAddresses[_gauge][_rewardToken].pop();
                delete pendingRewards[_gauge][_rewardToken][pendingRewardAddress];
            }
        }
        return _amount;
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
    
    function _safeTransfer(
        address token,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) =
            token.call(abi.encodeWithSelector(erc20.transfer.selector, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))));
    }
    
    function _safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) =
            token.call(abi.encodeWithSelector(erc20.transferFrom.selector, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))));
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