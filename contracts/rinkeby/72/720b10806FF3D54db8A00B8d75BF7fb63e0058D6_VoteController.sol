//SPDX-License-Identifier: MIT
pragma solidity =0.8.4;

import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "./interfaces/IVotingEscrow.sol";
import "./interfaces/IBoostManager.sol";

import "../interfaces/IComptroller.sol";


/**
 * @title Vote Controller
 * @author 0VIX Protocol (inspired by Curve Finance)
 * @notice Controls voting for supported markets and the issuance of additinal rewards to Comptroller
 */
contract VoteController {
    // TODO sort declarations - unsorted because of using a proxy

    using EnumerableSet for EnumerableSet.AddressSet;

    // sets for updating users' boosters on the looping epochs basis
    // e.g a user voting during the 1st epoch affects markets' weight for the 2nd epoch,
    //     making it not possible for any party/off-chain trigger to update boosters of this user before the 3rd epoch,
    //     if no more voting is performed by this user after the 1st epoch or postponing an update even further otherwise
    EnumerableSet.AddressSet private firstEpochUpdates;
    EnumerableSet.AddressSet private secondEpochUpdates;
    EnumerableSet.AddressSet private thirdEpochUpdates;

    // set of the votable markets - this contract does **not** manage other non-votable 0vix markets
    EnumerableSet.AddressSet private markets;

    bool internal initialized = true; // true, because of using a proxy
    IComptroller public comp;
    IBoostManager public boostManager;

    // 7 * 86400 seconds - all future times are rounded by week
    uint256 public constant PERIOD = 7 * 86400;

    // Cannot change weight votes more often than once in 10 days
    uint256 public constant WEIGHT_VOTE_DELAY = 10 * 86400;

    uint256 public constant MULTIPLIER = 10**18;

    // everywhere in the contract percentages should have hundredths precision
    uint256 public constant HUNDRED_PERCENT = 10000;

    // emissions for the votable markets
    uint256 public totalEmissions = 0; // in wei

    uint256 public votablePercentage; // in %, hundredths precision

    // last scheduled time
    uint256 public timeTotal;
    uint256 public nextTimeRewardsUpdated;

    struct Point {
        uint256 bias;
        uint256 slope;
    }

    struct VotedSlope {
        uint256 slope;
        uint256 power;
        uint256 end;
    }

    // struct for args format when setting the fixed weights
    struct Market {
        address market;
        uint256 weight;
    }

    // to keep track of regular epoch changes and users' boooster update lists corresponding to it
    enum Epoch {
        TO_BE_SET,
        FIRST,
        SECOND,
        THIRD
    }
    Epoch public shiftingEpoch = Epoch.TO_BE_SET;

    // Can and will be a smart contract
    address public admin;
    // Can and will be a smart contract
    address public futureAdmin;
    // Voting escrow
    address public votingEscrow;

    // track the votable 0vix markets
    mapping(address => bool) private isVotable;

    // user -> marketAddr -> VotedSlope
    mapping(address => mapping(address => VotedSlope)) public voteUserSlopes;
    // Total vote power used by user
    mapping(address => uint256) public voteUserPower;
    // Last user vote's timestamp for each market address
    mapping(address => mapping(address => uint256)) public lastUserVote;

    // marketAddr -> time -> Point
    mapping(address => mapping(uint256 => Point)) public pointsWeight;
    // marketAddr -> time -> slope
    mapping(address => mapping(uint256 => uint256)) private changesWeight;
    // marketAddr -> last scheduled time (next period)
    mapping(address => uint256) public timeWeight;

    // time -> Point
    mapping(uint256 => Point) public pointsTotal;
    // time -> slope
    mapping(uint256 => uint256) private changesSum;

    // weights of markets decided by the protocol (non-votable part of totalEmissions)
    mapping(address => uint256) public fixedRewardWeights;

    mapping(uint256 => EnumerableSet.AddressSet) private userAcitivties;

    event CommitOwnership(address admin);

    event ApplyOwnership(address admin);

    event NewMarketWeight(
        address marketAddress,
        uint256 weight,
        uint256 totalWeight
    );

    event VoteForMarket(
        address user,
        address marketAddr,
        uint256 weight
    );

    event NewMarket(address addr);
    event MarketRemoved(address addr);

    event VotablePercentageChanged(
        uint256 oldPercentage,
        uint256 newPercentage
    );
    event TotalEmissionsChanged(uint256 oldAmount, uint256 newAmount);

    /// @param market market address
    /// @param oldWeight normalized to 10^4
    /// @param newWeight normalized to 10^4
    event FixedWeightChanged(
        address market,
        uint256 oldWeight,
        uint256 newWeight
    );

    /// @notice this event logs reward speed set to Comptroller and _relative_ fixed & community weights for the market
    /// @param market market address
    /// @param supplyReward comptroller supply rewards speed
    /// @param borrowReward comptroller supply rewards speed
    /// @param fixedWeight normalized to 10^4
    /// @param communityWeight normalized to 10^18
    event RewardsUpdated(
        address market,
        uint256 supplyReward,
        uint256 borrowReward,
        uint256 fixedWeight,
        uint256 communityWeight
    );

    /// @notice this event logs the amount of users whose boosters were updated due to their inactivity
    event BoostersUpdated(
        uint256 usersUpdated
    );

    modifier onlyAdmin() {
        require(msg.sender == admin, "admin only");
        _;
    }

    constructor() {}

    function initialize(
        address _votingEscrow,
        IComptroller _comptroller,
        IBoostManager _boostManager,
        uint256 _totalEmissions
    ) external {
        require(!initialized, "contract already initialized");
        require(_votingEscrow != address(0));
        require(address(_comptroller) != address(0));
        require(address(_boostManager) != address(0));

        initialized = true;
        comp = _comptroller;
        boostManager = _boostManager;
        totalEmissions = _totalEmissions;

        admin = msg.sender;
        votingEscrow = _votingEscrow;
        timeTotal = (block.timestamp / PERIOD) * PERIOD;
        votablePercentage = 3000;
    }

    /**
     * @notice Transfer ownership of VoteController to `addr`
     * @param addr Address to have ownership transferred to
     * @dev admin only
     */
    function commitTransferOwnership(address addr) external onlyAdmin {
        futureAdmin = addr;
        emit CommitOwnership(addr);
    }

    /**
     * @notice Apply pending ownership transfer
     * @dev admin only
     */
    function applyTransferOwnership() external onlyAdmin {
        address _admin = futureAdmin;
        require(_admin != address(0), "admin not set");
        admin = _admin;
        emit ApplyOwnership(_admin);
    }

    /**
     * @notice Fill historic total weights period-over-period for missed checkins
     * and return the total for the future period
     * @return Total weight
     */
    function _getTotal() internal returns (uint256) {
        uint256 t = timeTotal;

        if (t == 0) return 0;

        Point memory pt = pointsTotal[t];

        for (uint256 i = 0; i < 500; i++) {
            if (t > block.timestamp) break;

            t += PERIOD;
            uint256 biasDelta = pt.slope * PERIOD;
            if (pt.bias > biasDelta) {
                pt.bias -= biasDelta;
                uint256 slopeDelta = changesSum[t];
                pt.slope -= slopeDelta;
            } else {
                pt.bias = 0;
                pt.slope = 0;
            }

            pointsTotal[t] = pt;
            if (t > block.timestamp) {
                timeTotal = t;
            }
        }

        return pt.bias;
    }

    /**
     * @notice Fill historic market weights period-over-period for missed checkins
     * and return the total for the future period
     * @param marketAddr Address of the market
     * @return Market weight
     */
    function _getWeight(address marketAddr) internal returns (uint256) {
        uint256 t = timeWeight[marketAddr];
        if (t == 0) return 0;

        Point memory pt = pointsWeight[marketAddr][t];
        for (uint256 i = 0; i < 500; i++) {
            if (t > block.timestamp) break;

            t += PERIOD;
            uint256 biasDelta = pt.slope * PERIOD;
            if (pt.bias > biasDelta) {
                pt.bias -= biasDelta;
                uint256 slopeDelta = changesWeight[marketAddr][t];
                pt.slope -= slopeDelta;
            } else {
                pt.bias = 0;
                pt.slope = 0;
            }

            pointsWeight[marketAddr][t] = pt;
            if (t > block.timestamp) timeWeight[marketAddr] = t;
        }

        return pt.bias;
    }

    /**
     * @notice Add market `addr` essentially making it votable; manual fixedWeights assignment needed
     * @dev admin only
     * @param addr Market address
     */
    function addMarket(address addr) external onlyAdmin {
        require(!isVotable[addr], "Cannot add the same market twice");
        require(comp.isMarket(addr), "address is not an 0vix market");
        isVotable[addr] = true;

        markets.add(addr);

        uint256 nextTime = ((block.timestamp + PERIOD) / PERIOD) * PERIOD;

        if (timeTotal == 0) timeTotal = nextTime;

        timeWeight[addr] = nextTime;

        emit NewMarket(addr);
    }

    /**
     * @notice Remove market `addr` essentially making it non-votable; manual fixedWeights recalibration needed
     * @dev admin only
     * @param addr Market address
     */
    function removeMarket(address addr) external onlyAdmin {
        require(isVotable[addr], "Market doesn't exist");
        isVotable[addr] = false;

        markets.remove(addr);

        // todo test what happens with market's lists (e.g. timeWeight[addr]) when re-adding

        emit MarketRemoved(addr);
    }

    /**
     * @notice Sets percentage of the emmission community can vote upon
     * @param _market Market's address
     * @param _weight Market's fixed weight with hundredth precision
     */
    function setSingleFixedRewardWeight(address _market, uint256 _weight)
        external
        onlyAdmin
    {
        Market[] memory market = new Market[](1);
        market[0] = Market(_market, _weight);
        setFixedRewardWeights(market);
    }

    /**
     * @notice Sets percentage of the emmission community can vote upon
     * @param _markets The struct containing market's address and its fixed weight with hundredth precision
     */
    function setFixedRewardWeights(Market[] memory _markets) public onlyAdmin {
        uint256 sumWeights = 0;

        for (uint256 i = 0; i < markets.length(); i++) {
            sumWeights += fixedRewardWeights[markets.at(i)];
        }

        for (uint256 i = 0; i < _markets.length; i++) {
            require(
                markets.contains(_markets[i].market),
                "Market is not in the list"
            );

            uint256 oldWeight = fixedRewardWeights[_markets[i].market];
            fixedRewardWeights[_markets[i].market] = _markets[i].weight;
            sumWeights = sumWeights - oldWeight + _markets[i].weight;

            emit FixedWeightChanged(
                _markets[i].market,
                oldWeight,
                _markets[i].weight
            );
        }

        require(sumWeights <= HUNDRED_PERCENT, "New weight(s) too high");
    }

    /**
     * @notice Checkpoint to fill data common for all markets
     */
    function checkpoint() external {
        _getTotal();
    }

    /**
     * @notice Checkpoint to fill data for both a specific market and common for all markets
     * @param addr Market address
     */
    function checkpointMarket(address addr) external {
        _getWeight(addr);
        _getTotal();
    }

    /**
     * @notice Get market relative weight (not more than 1.0) normalized to 1e18
     * (e.g. 1.0 == 1e18). Inflation which will be received by it is
     * inflation_rate * relative_weight / 1e18
     * @param addr Market address
     * @param time Relative weight at the specified timestamp in the past or present
     * @return Value of relative weight normalized to 1e18
     */
    function _marketRelativeWeight(address addr, uint256 time)
        internal
        view
        returns (uint256)
    {
        uint256 t = (time / PERIOD) * PERIOD;
        uint256 _totalWeight = pointsTotal[t].bias;

        if (_totalWeight == 0) return 0;

        uint256 _marketWeight = pointsWeight[addr][t].bias;

        return (MULTIPLIER * _marketWeight) / _totalWeight;
    }

    /**
     * @notice Get market relative weight (not more than 1.0) normalized to 1e18
     * (e.g. 1.0 == 1e18). Inflation which will be received by it is
     * inflation_rate * relative_weight / 1e18
     * @param addr Market address
     * @param time Relative weight at the specified timestamp in the past or present
     * @return Value of relative weight normalized to 1e18
     */
    function marketRelativeWeight(address addr, uint256 time)
        external
        view
        returns (uint256)
    {
        return _marketRelativeWeight(addr, time > 0 ? time : block.timestamp);
    }

    /**
     * @notice Get market weight normalized to 1e18 and also fill all the unfilled
     * values and market records
     * @dev Any address can call, however nothing is recorded if the values are filled already
     * @param addr Market address
     * @param time Relative weight at the specified timestamp in the past or present
     * @return Value of relative weight normalized to 1e18
     */
    function marketRelativeWeightWrite(address addr, uint256 time)
        external
        returns (uint256)
    {
        _getWeight(addr);
        _getTotal();

        return _marketRelativeWeight(addr, time > 0 ? time : block.timestamp);
    }

    // Change market weight
    // Only needed when testing in reality
    function _changeMarketWeight(address addr, uint256 weight) internal {
        uint256 oldMarketWeight = _getWeight(addr);
        uint256 _totalWeight = _getTotal();
        uint256 nextTime = ((block.timestamp + PERIOD) / PERIOD) * PERIOD;

        pointsWeight[addr][nextTime].bias = weight;
        timeWeight[addr] = nextTime;

        _totalWeight = _totalWeight + weight - oldMarketWeight;
        pointsTotal[nextTime].bias = _totalWeight;
        timeTotal = nextTime;

        emit NewMarketWeight(addr, weight, _totalWeight);
    }

    /**
     * @notice Change weight of market `addr` to `weight`
     * @param addr Market's address
     * @param weight New market weight
     */
    function changeMarketWeight(address addr, uint256 weight)
        external
        onlyAdmin
    {
        _changeMarketWeight(addr, weight);
    }

    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a : b;
    }

    /**
     * @notice Allocate voting power for changing market weights
     * @param _marketAddr Market which `msg.sender` votes for
     * @param _userWeight Weight for a market in bps (units of 0.01%). Minimal is 0.01%. Ignored if 0
     */
    function voteForMarketWeights(address _marketAddr, uint256 _userWeight)
        external
    {
        require(
            shiftingEpoch != Epoch.TO_BE_SET,
            "updateRewards() was never called"
        );

        uint256 slope;
        uint256 lockEnd;
        {
            address escrow = votingEscrow;
            slope = uint256(
                int256(IVotingEscrow(escrow).get_last_user_slope(msg.sender))
            );
            lockEnd = IVotingEscrow(escrow).locked__end(msg.sender);
        }
        uint256 nextTime = ((block.timestamp + PERIOD) / PERIOD) * PERIOD;

        require(lockEnd > nextTime, "Your token lock expires too soon");
        require(
            _userWeight <= HUNDRED_PERCENT,
            "Voted with more than 100%"
        );

        require(
            block.timestamp >=
                (lastUserVote[msg.sender][_marketAddr] + WEIGHT_VOTE_DELAY),
            "Cannot vote so often"
        );

        require(isVotable[_marketAddr], "Market is not votable");
        // Prepare slopes and biases in memory
        VotedSlope memory oldSlope = voteUserSlopes[msg.sender][_marketAddr];
        uint256 oldBias;
        {
            uint256 oldDt;
            if (oldSlope.end > nextTime) oldDt = oldSlope.end - nextTime;

            oldBias = oldSlope.slope * oldDt;
        }
        VotedSlope memory newSlope = VotedSlope({
            slope: (slope * _userWeight) / HUNDRED_PERCENT,
            end: lockEnd,
            power: _userWeight
        });

        uint256 newDt = lockEnd - nextTime; // dev: raises when expired
        uint256 newBias = newSlope.slope * newDt;

        // Check and update powers (weights) used
        {
            uint256 powerUsed = voteUserPower[msg.sender];
            powerUsed = powerUsed + newSlope.power - oldSlope.power;
            voteUserPower[msg.sender] = powerUsed;
            require(powerUsed <= HUNDRED_PERCENT, "Used too much power");
        }

        // Remove old and schedule new slope changes
        // Remove slope changes for old slopes
        // Schedule recording of initial slope for nextTime
        {
            uint256 oldWeightBias = _getWeight(_marketAddr);
            uint256 oldSumBias = _getTotal();

            pointsWeight[_marketAddr][nextTime].bias =
                max(oldWeightBias + newBias, oldBias) -
                oldBias;
            pointsTotal[nextTime].bias =
                max(oldSumBias + newBias, oldBias) -
                oldBias;
        }

        uint256 oldWeightSlope = pointsWeight[_marketAddr][nextTime].slope;
        uint256 oldSumSlope = pointsTotal[nextTime].slope;

        if (oldSlope.end > nextTime) {
            pointsWeight[_marketAddr][nextTime].slope =
                max(oldWeightSlope + newSlope.slope, oldSlope.slope) -
                oldSlope.slope;
            pointsTotal[nextTime].slope =
                max(oldSumSlope + newSlope.slope, oldSlope.slope) -
                oldSlope.slope;
        } else {
            pointsWeight[_marketAddr][nextTime].slope += newSlope.slope;
            pointsTotal[nextTime].slope += newSlope.slope;
        }

        // Cancel old slope changes if they still didn't happen
        if (oldSlope.end > block.timestamp) {
            changesWeight[_marketAddr][oldSlope.end] -= oldSlope.slope;
            changesSum[oldSlope.end] -= oldSlope.slope;
        }

        // Add slope changes for new slopes
        changesWeight[_marketAddr][newSlope.end] += newSlope.slope;
        changesSum[newSlope.end] += newSlope.slope;

        _getTotal();

        voteUserSlopes[msg.sender][_marketAddr] = newSlope;

        //Record last action time
        lastUserVote[msg.sender][_marketAddr] = block.timestamp;

        // update the booster of the user
        boostManager.updateBoostBasis(
            msg.sender
        );

        // the user has voted for the next epoch, essentially updating their booster
        // so the protocol is not able to decrease it by updating during the next 2 epochs
        if (shiftingEpoch == Epoch.FIRST) {
            firstEpochUpdates.remove(msg.sender);
            secondEpochUpdates.remove(msg.sender);
            thirdEpochUpdates.add(msg.sender);
        } else if (shiftingEpoch == Epoch.SECOND) {
            firstEpochUpdates.add(msg.sender);
            secondEpochUpdates.remove(msg.sender);
            thirdEpochUpdates.remove(msg.sender);
        } else {
            firstEpochUpdates.remove(msg.sender);
            secondEpochUpdates.add(msg.sender);
            thirdEpochUpdates.remove(msg.sender);
        }

        emit VoteForMarket(
            msg.sender,
            _marketAddr,
            _userWeight
        );
    }

    /**
     * @notice Get current market weight
     * @param addr Market address
     * @return Market weight
     */
    function getMarketWeight(address addr) public view returns (uint256) {
        return pointsWeight[addr][timeWeight[addr]].bias;
    }

    /**
     * @notice Get current total weight
     * @return Total weight
     */
    function getTotalWeight() public view returns (uint256) {
        return pointsTotal[timeTotal].bias;
    }

    /**
     * @notice Sets percentage of the emmission community can vote upon
     * @param _percentage The percentage amount with hundredth precision
     */
    function setVotablePercentage(uint256 _percentage) external onlyAdmin {
        require(_percentage <= HUNDRED_PERCENT, "Maximum percentage exceeded");
        uint256 oldVotablePercentage = votablePercentage;
        votablePercentage = _percentage;
        emit VotablePercentageChanged(oldVotablePercentage, votablePercentage);
    }

    function setTotalEmissions(uint256 _totalEmissions) external onlyAdmin {
        uint256 oldEmissions = totalEmissions;
        totalEmissions = _totalEmissions;

        emit TotalEmissionsChanged(oldEmissions, totalEmissions);
    }

    function checkpointAll() internal {
        for (uint256 i = 0; i < markets.length(); i++) {
            _getWeight(markets.at(i));
        }
        _getTotal();
    }

    function updateRewards() public {
        require(
            block.timestamp >= nextTimeRewardsUpdated,
            "rewards already updated"
        );
        checkpointAll();
        nextTimeRewardsUpdated = ((block.timestamp + PERIOD) / PERIOD) * PERIOD;
        uint256 votableAmount = (totalEmissions * votablePercentage) /
            HUNDRED_PERCENT;
        uint256 fixedAmount = totalEmissions - votableAmount;

        for (uint256 i = 0; i < markets.length(); i++) {
            // todo: check if all markets have (fixed-)weights
            address addr = markets.at(i);
            uint256 relWeight = _marketRelativeWeight(addr, block.timestamp);
            uint256 reward = ((fixedAmount *
                fixedRewardWeights[markets.at(i)]) / HUNDRED_PERCENT) +
                ((votableAmount * relWeight) / 1e18);

            address[] memory addrs = new address[](1);
            addrs[0] = addr;

            uint256[] memory rewards = new uint256[](1);
            rewards[0] = reward/2;

            // current implementation doesn't differentiate supply and borrow reward speeds
            comp._setRewardSpeeds(addrs, rewards, rewards);
            emit RewardsUpdated(addr, reward, reward, fixedRewardWeights[markets.at(i)], relWeight);
        }

        // shift the epoch so the booster of the needed users can be decreased
        shiftingEpoch = shiftingEpoch == Epoch.THIRD
            ? Epoch.FIRST
            : Epoch(uint256(shiftingEpoch) + 1);
    }

    // update boosters for not active users
    function updateBoosters(uint256 userAmount) external {
        // in case an epoch should have been shifted already
        if (block.timestamp >= nextTimeRewardsUpdated) {
            updateRewards();
        }

        EnumerableSet.AddressSet storage toUpdate;
        EnumerableSet.AddressSet storage scheduledUpdate;

        if (shiftingEpoch == Epoch.FIRST) {
            toUpdate = firstEpochUpdates;
            scheduledUpdate = secondEpochUpdates;
        } else if (shiftingEpoch == Epoch.SECOND) {
            toUpdate = secondEpochUpdates;
            scheduledUpdate = thirdEpochUpdates;
        } else {
            toUpdate = thirdEpochUpdates;
            scheduledUpdate = firstEpochUpdates;
        }

        if (userAmount == 0 || userAmount > toUpdate.length())
            userAmount = toUpdate.length();
        for (uint256 i = 0; i < userAmount; i++) {
            address account = toUpdate.at(toUpdate.length() - 1);

            // update the booster of the user
            bool boostApplies = boostManager.updateBoostBasis(
                account
            );

            // check if we need to update the booster in the next epoch's check
            if (boostApplies) {
                toUpdate.remove(account);
                scheduledUpdate.add(account);
            } else {
                toUpdate.remove(account);
            }
        }

        emit BoostersUpdated(userAmount);
    }

    // returns the number of users which boosters could be updated this epoch
    // can be used by any party/off-chain trigger to check if updateBoosters() function should be called
    function numOfBoostersToUpdate() external view returns (uint256) {
        EnumerableSet.AddressSet storage toUpdate;
        if (shiftingEpoch == Epoch.FIRST) {
            toUpdate = firstEpochUpdates;
        } else if (shiftingEpoch == Epoch.SECOND) {
            toUpdate = secondEpochUpdates;
        } else {
            toUpdate = thirdEpochUpdates;
        }

        return toUpdate.length();
    }

    // to satisfy the test cases
    function marketAt(uint256 index) external view returns (address) {
        return markets.at(index);
    }

    function numMarkets() external view returns (uint256) {
        return markets.length();
    }

    function isMarketListed(address _market) external view returns(bool) {
        return markets.contains(_market);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/structs/EnumerableSet.sol)

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

//SPDX-License-Identifier: Unlicense

pragma solidity =0.8.4;
interface IVotingEscrow {
    function get_last_user_slope(address addr) external view returns(int128);

    function locked__end(address addr) external view returns(uint256);
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IBoostManager {
    function updateBoostBasis(address user)
        external
        returns (bool);

    function updateBoostSupplyBalances(
        address market,
        address user,
        uint256 oldBalance,
        uint256 newBalance
    ) external;

    function updateBoostBorrowBalances(
        address market,
        address user,
        uint256 oldBalance,
        uint256 newBalance
    ) external;

    function boostedSupplyBalanceOf(address market, address user)
        external
        view
        returns (uint256);

    function boostedBorrowBalanceOf(address market, address user)
        external
        view
        returns (uint256);

    function boostedTotalSupply(address market) external view returns (uint256);

    function boostedTotalBorrows(address market)
        external
        view
        returns (uint256);

    function setAuthorized(address addr, bool flag) external;

    function setVeOVIX(IERC20 ve) external;

    function isAuthorized(address addr) external view returns (bool);
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "../otokens/interfaces/IOToken.sol";
import "../PriceOracle.sol";

interface IComptroller {
    /// @notice Indicator that this is a Comptroller contract (for inspection)
    function isComptroller() external view returns(bool);

    /*** Assets You Are In ***/

    function enterMarkets(address[] calldata oTokens) external returns (uint[] memory);
    function exitMarket(address oToken) external returns (uint);

    /*** Policy Hooks ***/

    function mintAllowed(address oToken, address minter, uint mintAmount) external returns (uint);
    function mintVerify(address oToken, address minter, uint mintAmount, uint mintTokens) external;

    function redeemAllowed(address oToken, address redeemer, uint redeemTokens) external returns (uint);
    function redeemVerify(address oToken, address redeemer, uint redeemAmount, uint redeemTokens) external;

    function borrowAllowed(address oToken, address borrower, uint borrowAmount) external returns (uint);
    function borrowVerify(address oToken, address borrower, uint borrowAmount) external;

    function repayBorrowAllowed(
        address oToken,
        address payer,
        address borrower,
        uint repayAmount) external returns (uint);

    function liquidateBorrowAllowed(
        address oTokenBorrowed,
        address oTokenCollateral,
        address liquidator,
        address borrower,
        uint repayAmount) external returns (uint);

    function seizeAllowed(
        address oTokenCollateral,
        address oTokenBorrowed,
        address liquidator,
        address borrower,
        uint seizeTokens) external returns (uint);
        
    function seizeVerify(
        address oTokenCollateral,
        address oTokenBorrowed,
        address liquidator,
        address borrower,
        uint seizeTokens) external;

    function transferAllowed(address oToken, address src, address dst, uint transferTokens) external returns (uint);
    function transferVerify(address oToken, address src, address dst, uint transferTokens) external;

    /*** Liquidity/Liquidation Calculations ***/

    function liquidateCalculateSeizeTokens(
        address oTokenBorrowed,
        address oTokenCollateral,
        uint repayAmount) external view returns (uint, uint);



    function isMarket(address market) external view returns(bool);
    function getBoostManager() external view returns(address);
    function getAllMarkets() external view returns(IOToken[] memory);
    function oracle() external view returns(PriceOracle);

    function updateAndDistributeSupplierRewardsForToken(
        address oToken,
        address account
    ) external;

    function updateAndDistributeBorrowerRewardsForToken(
        address oToken,
        address borrower
    ) external;

    function _setRewardSpeeds(
        address[] memory oTokens,
        uint256[] memory supplySpeeds,
        uint256[] memory borrowSpeeds
    ) external;
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

//SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "../../interfaces/IComptroller.sol";
import "../../interest-rate-models/interfaces/IInterestRateModel.sol";
import "./IEIP20NonStandard.sol";
import "./IEIP20.sol";

interface IOToken is IEIP20{
    /**
     * @notice Indicator that this is a OToken contract (for inspection)
     */
    function isOToken() external view returns(bool);


    /*** Market Events ***/

    /**
     * @notice Event emitted when interest is accrued
     */
    event AccrueInterest(uint cashPrior, uint interestAccumulated, uint borrowIndex, uint totalBorrows);

    /**
     * @notice Event emitted when tokens are minted
     */
    event Mint(address minter, uint mintAmount, uint mintTokens);

    /**
     * @notice Event emitted when tokens are redeemed
     */
    event Redeem(address redeemer, uint redeemAmount, uint redeemTokens);

    /**
     * @notice Event emitted when underlying is borrowed
     */
    event Borrow(address borrower, uint borrowAmount, uint accountBorrows, uint totalBorrows);

    /**
     * @notice Event emitted when a borrow is repaid
     */
    event RepayBorrow(address payer, address borrower, uint repayAmount, uint accountBorrows, uint totalBorrows);

    /**
     * @notice Event emitted when a borrow is liquidated
     */
    event LiquidateBorrow(address liquidator, address borrower, uint repayAmount, address oTokenCollateral, uint seizeTokens);


    /*** Admin Events ***/

    /**
     * @notice Event emitted when pendingAdmin is changed
     */
    event NewPendingAdmin(address oldPendingAdmin, address newPendingAdmin);

    /**
     * @notice Event emitted when pendingAdmin is accepted, which means admin is updated
     */
    event NewAdmin(address oldAdmin, address newAdmin);

    /**
     * @notice Event emitted when comptroller is changed
     */
    event NewComptroller(IComptroller oldComptroller, IComptroller newComptroller);

    /**
     * @notice Event emitted when interestRateModel is changed
     */
    event NewMarketInterestRateModel(IInterestRateModel oldInterestRateModel, IInterestRateModel newInterestRateModel);

    /**
     * @notice Event emitted when the reserve factor is changed
     */
    event NewReserveFactor(uint oldReserveFactorMantissa, uint newReserveFactorMantissa);

    /**
     * @notice Event emitted when the protocol seize share is changed
     */
    event NewProtocolSeizeShare(uint oldProtocolSeizeShareMantissa, uint newProtocolSeizeShareMantissa);

    /**
     * @notice Event emitted when the reserves are added
     */
    event ReservesAdded(address benefactor, uint addAmount, uint newTotalReserves);

    /**
     * @notice Event emitted when the reserves are reduced
     */
    event ReservesReduced(address admin, uint reduceAmount, uint newTotalReserves);

    function accrualBlockTimestamp() external returns(uint256);

    /*** User Interface ***/
    function balanceOfUnderlying(address owner) external returns (uint);
    function getAccountSnapshot(address account) external view returns (uint, uint, uint, uint);
    function borrowRatePerTimestamp() external view returns (uint);
    function supplyRatePerTimestamp() external view returns (uint);
    function totalBorrowsCurrent() external returns (uint);
    function borrowBalanceCurrent(address account) external returns (uint);
    function borrowBalanceStored(address account) external view returns (uint);
    function exchangeRateCurrent() external returns (uint);
    function exchangeRateStored() external view returns (uint);
    function getCash() external view returns (uint);
    function accrueInterest() external returns (uint);
    function seize(address liquidator, address borrower, uint seizeTokens) external returns (uint);

    function totalBorrows() external view returns(uint);
    function comptroller() external view returns(IComptroller);
    function borrowIndex() external view returns(uint);
    function reserveFactorMantissa() external view returns(uint);


    /*** Admin Functions ***/

    function _setPendingAdmin(address payable newPendingAdmin) external returns (uint);
    function _acceptAdmin() external returns (uint);
    function _setComptroller(IComptroller newComptroller) external returns (uint);
    function _setReserveFactor(uint newReserveFactorMantissa) external returns (uint);
    function _reduceReserves(uint reduceAmount) external returns (uint);
    function _setInterestRateModel(IInterestRateModel newInterestRateModel) external returns (uint);
    function _setProtocolSeizeShare(uint newProtocolSeizeShareMantissa) external returns (uint);
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "./otokens/interfaces/IOToken.sol";

abstract contract PriceOracle {
    /// @notice Indicator that this is a PriceOracle contract (for inspection)
    bool public constant isPriceOracle = true;

    /**
      * @notice Get the underlying price of a oToken asset
      * @param oToken The oToken to get the underlying price of
      * @return The underlying asset price mantissa (scaled by 1e18).
      *  Zero means the price is unavailable.
      */
    function getUnderlyingPrice(IOToken oToken) external virtual view returns (uint);
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

/**
  * @title 0VIX's IInterestRateModel Interface
  * @author 0VIX
  */
interface IInterestRateModel {
    /// @notice Indicator that this is an InterestRateModel contract (for inspection)
    function isInterestRateModel() external view returns(bool);

    /**
      * @notice Calculates the current borrow interest rate per timestmp
      * @param cash The total amount of cash the market has
      * @param borrows The total amount of borrows the market has outstanding
      * @param reserves The total amount of reserves the market has
      * @return The borrow rate per timestmp (as a percentage, and scaled by 1e18)
      */
    function getBorrowRate(uint cash, uint borrows, uint reserves) external view returns (uint);

    /**
      * @notice Calculates the current supply interest rate per timestmp
      * @param cash The total amount of cash the market has
      * @param borrows The total amount of borrows the market has outstanding
      * @param reserves The total amount of reserves the market has
      * @param reserveFactorMantissa The current reserve factor the market has
      * @return The supply rate per timestmp (as a percentage, and scaled by 1e18)
      */
    function getSupplyRate(uint cash, uint borrows, uint reserves, uint reserveFactorMantissa) external view returns (uint);

}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

/**
 * @title IEIP20NonStandard
 * @dev Version of ERC20 with no return values for `transfer` and `transferFrom`
 *  See https://medium.com/coinmonks/missing-return-value-bug-at-least-130-tokens-affected-d67bf08521ca
 */
interface IEIP20NonStandard {

    /**
     * @notice Get the total number of tokens in circulation
     * @return The supply of tokens
     */
    function totalSupply() external view returns (uint256);

    /**
     * @notice Gets the balance of the specified address
     * @param owner The address from which the balance will be retrieved
     * @return balance The balance
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    ///
    /// !!!!!!!!!!!!!!
    /// !!! NOTICE !!! `transfer` does not return a value, in violation of the ERC-20 specification
    /// !!!!!!!!!!!!!!
    ///

    /**
      * @notice Transfer `amount` tokens from `msg.sender` to `dst`
      * @param dst The address of the destination account
      * @param amount The number of tokens to transfer
      */
    function transfer(address dst, uint256 amount) external;

    ///
    /// !!!!!!!!!!!!!!
    /// !!! NOTICE !!! `transferFrom` does not return a value, in violation of the ERC-20 specification
    /// !!!!!!!!!!!!!!
    ///

    /**
      * @notice Transfer `amount` tokens from `src` to `dst`
      * @param src The address of the source account
      * @param dst The address of the destination account
      * @param amount The number of tokens to transfer
      */
    function transferFrom(address src, address dst, uint256 amount) external;

    /**
      * @notice Approve `spender` to transfer up to `amount` from `src`
      * @dev This will overwrite the approval amount for `spender`
      *  and is subject to issues noted [here](https://eips.ethereum.org/EIPS/eip-20#approve)
      * @param spender The address of the account which may transfer tokens
      * @param amount The number of tokens that are approved
      * @return success Whether or not the approval succeeded
      */
    function approve(address spender, uint256 amount) external returns (bool success);

    /**
      * @notice Get the current allowance from `owner` for `spender`
      * @param owner The address of the account which owns the tokens to be spent
      * @param spender The address of the account which may transfer tokens
      * @return remaining The number of tokens allowed to be spent
      */
    function allowance(address owner, address spender) external view returns (uint256 remaining);

    event Transfer(address indexed from, address indexed to, uint256 amount);
    event Approval(address indexed owner, address indexed spender, uint256 amount);
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

/**
 * @title ERC 20 Token Standard Interface
 *  https://eips.ethereum.org/EIPS/eip-20
 */
interface IEIP20 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);

    /**
      * @notice Get the total number of tokens in circulation
      * @return The supply of tokens
      */
    function totalSupply() external view returns (uint256);

    /**
     * @notice Gets the balance of the specified address
     * @param owner The address from which the balance will be retrieved
     * @return balance The balance
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
      * @notice Transfer `amount` tokens from `msg.sender` to `dst`
      * @param dst The address of the destination account
      * @param amount The number of tokens to transfer
      * @return success Whether or not the transfer succeeded
      */
    function transfer(address dst, uint256 amount) external returns (bool success);

    /**
      * @notice Transfer `amount` tokens from `src` to `dst`
      * @param src The address of the source account
      * @param dst The address of the destination account
      * @param amount The number of tokens to transfer
      * @return success Whether or not the transfer succeeded
      */
    function transferFrom(address src, address dst, uint256 amount) external returns (bool success);

    /**
      * @notice Approve `spender` to transfer up to `amount` from `src`
      * @dev This will overwrite the approval amount for `spender`
      *  and is subject to issues noted [here](https://eips.ethereum.org/EIPS/eip-20#approve)
      * @param spender The address of the account which may transfer tokens
      * @param amount The number of tokens that are approved (-1 means infinite)
      * @return success Whether or not the approval succeeded
      */
    function approve(address spender, uint256 amount) external returns (bool success);

    /**
      * @notice Get the current allowance from `owner` for `spender`
      * @param owner The address of the account which owns the tokens to be spent
      * @param spender The address of the account which may transfer tokens
      * @return remaining The number of tokens allowed to be spent (-1 means infinite)
      */
    function allowance(address owner, address spender) external view returns (uint256 remaining);

    event Transfer(address indexed from, address indexed to, uint256 amount);
    event Approval(address indexed owner, address indexed spender, uint256 amount);
}