// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;
pragma abicoder v2;

import "./INextVersionLock.sol";
import "./LockingBase.sol";
import "./LockingRelock.sol";
import "./LockingVotes.sol";
import "./ILocking.sol";

contract Locking is ILocking, LockingBase, LockingRelock, LockingVotes {
    using SafeMathUpgradeable for uint;
    using LibBrokenLine for LibBrokenLine.BrokenLine;

    function __Locking_init(IERC20Upgradeable _token, uint _startingPointWeek, uint _minCliffPeriod, uint _minSlopePeriod) external initializer {
        __LockingBase_init_unchained(_token, _startingPointWeek, _minCliffPeriod, _minSlopePeriod);
        __Ownable_init_unchained();
        __Context_init_unchained();
    }

    function stop() external onlyOwner notStopped {
        stopped = true;
        emit StopLocking(msg.sender);
    }

    function start() external onlyOwner isStopped {
        stopped = false;
        emit StartLocking(msg.sender);
    }

    function startMigration(address to) external onlyOwner {
        migrateTo = to;
        emit StartMigration(msg.sender, to);
    }

    function lock(address account, address _delegate, uint amount, uint slopePeriod, uint cliff) external notStopped notMigrating override returns (uint) {
        require(amount > 0, "zero amount");
        require(cliff <= MAX_CLIFF_PERIOD, "cliff too big");
        require(slopePeriod <= MAX_SLOPE_PERIOD, "period too big");

        counter++;

        uint time = roundTimestamp(getBlockNumber());
        addLines(account, _delegate, amount, slopePeriod, cliff, time);
        accounts[account].amount = accounts[account].amount.add(amount);

        require(token.transferFrom(msg.sender, address(this), amount), "transfer failed");

        emit LockCreate(counter, account, _delegate, time, amount, slopePeriod, cliff);

        // IVotesUpgradeable events
        emit DelegateChanged(account, address(0), _delegate);
        emit DelegateVotesChanged(_delegate, 0, accounts[_delegate].balance.actualValue(time));
        return counter;
    }

    function withdraw() external {
        uint value = getAvailableForWithdraw(msg.sender);
        if (value > 0) {
            accounts[msg.sender].amount = accounts[msg.sender].amount.sub(value);
            require(token.transfer(msg.sender, value), "transfer failed");
        }
        emit Withdraw(msg.sender, value);
    }

    // Amount available for withdrawal
    function getAvailableForWithdraw(address account) public view returns (uint value) {
        value = accounts[account].amount;
        if (!stopped) {
            uint time = roundTimestamp(getBlockNumber());
            uint bias = accounts[account].locked.actualValue(time);
            value = value.sub(bias);
        }
    }

    //Remaining locked amount
    function locked(address account) external view returns (uint) {
        return accounts[account].amount;
    }

    //For a given Line id, the owner and delegate addresses.
    function getAccountAndDelegate(uint id) external view returns (address _account, address _delegate) {
        _account = locks[id].account;
        _delegate = locks[id].delegate;
    }

    //Getting "current week" of the contract.
    function getWeek() external view returns (uint) {
        return roundTimestamp(getBlockNumber());
    }

    function delegateTo(uint id, address newDelegate) external notStopped notMigrating {
        address account = verifyLockOwner(id);
        address _delegate = locks[id].delegate;
        uint time = roundTimestamp(getBlockNumber());
        accounts[_delegate].balance.update(time);
        (uint bias, uint slope, uint cliff) = accounts[_delegate].balance.remove(id, time);
        LibBrokenLine.Line memory line = LibBrokenLine.Line(time, bias, slope);
        accounts[newDelegate].balance.update(time);
        accounts[newDelegate].balance.add(id, line, cliff);
        locks[id].delegate = newDelegate;
        emit Delegate(id, account, newDelegate, time);

        // IVotesUpgradeable events
        emit DelegateChanged(account, _delegate, newDelegate);
        emit DelegateVotesChanged(_delegate, 0, accounts[_delegate].balance.actualValue(time));
        emit DelegateVotesChanged(newDelegate, 0, accounts[newDelegate].balance.actualValue(time));
    }

    function totalSupply() external view returns (uint) {
        if ((totalSupplyLine.initial.bias == 0) || (stopped)) {
            return 0;
        }
        uint time = roundTimestamp(getBlockNumber());
        return totalSupplyLine.actualValue(time);
    }

    function balanceOf(address account) external view returns (uint) {
        if ((accounts[account].balance.initial.bias == 0) || (stopped)) {
            return 0;
        }
        uint time = roundTimestamp(getBlockNumber());
        return accounts[account].balance.actualValue(time);
    }

    function migrate(uint[] memory id) external {
        if (migrateTo == address(0)) {
            return;
        }
        uint time = roundTimestamp(getBlockNumber());
        INextVersionLock nextVersionLock = INextVersionLock(migrateTo);
        for (uint256 i = 0; i < id.length; ++i) {
            address account = verifyLockOwner(id[i]);
            address _delegate = locks[id[i]].delegate;
            updateLines(account, _delegate, time);
            //save data Line before remove
            LibBrokenLine.LineData memory lineData = accounts[account].locked.initiatedLines[id[i]];
            (uint residue,,) = accounts[account].locked.remove(id[i], time);

            accounts[account].amount = accounts[account].amount.sub(residue);

            accounts[_delegate].balance.remove(id[i], time);
            totalSupplyLine.remove(id[i], time);
            nextVersionLock.initiateData(id[i], lineData, account, _delegate);

            require(token.transfer(migrateTo, residue), "transfer failed");
        }
        emit Migrate(msg.sender, id);
    }

    function name() public view virtual returns (string memory) {
        return "Rarible Vote-Escrow";
    }

    function symbol() public view virtual returns (string memory) {
        return "veRARI";
    }

    function decimals() public view virtual returns (uint8) {
        return 18;
    }

    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

import "@openzeppelin/contracts-upgradeable/math/SignedSafeMathUpgradeable.sol";

library LibIntMapping {
    using SignedSafeMathUpgradeable for int;

    function addToItem(mapping(uint => int) storage map, uint key, int value) internal {
        map[key] = map[key].add(value);
    }

    function subFromItem(mapping(uint => int) storage map, uint key, int value) internal {
        map[key] = map[key].sub(value);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;
pragma abicoder v2;

import "@openzeppelin/contracts-upgradeable/math/SignedSafeMathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/math/SafeMathUpgradeable.sol";
import "./LibIntMapping.sol";

/**
  * Line describes a linear function, how the user's voice decreases from point (start, bias) with speed slope
  * BrokenLine - a curve that describes the curve of the change in the sum of votes of several users
  * This curve starts with a line (Line) and then, at any time, the slope can be changed.
  * All slope changes are stored in slopeChanges. The slope can always be reduced only, it cannot increase,
  * because users can only run out of lockup periods.
  **/

library LibBrokenLine {
    using SignedSafeMathUpgradeable for int;
    using SafeMathUpgradeable for uint;
    using LibIntMapping for mapping(uint => int);

    struct Line {
        uint start;
        uint bias;
        uint slope;
    }

    struct LineData {//all data about line
        Line line;
        uint cliff;
    }

    struct BrokenLine {
        mapping(uint => int) slopeChanges;          //change of slope applies to the next time point
        mapping(uint => int) biasChanges;           //change of bias applies to the next time point
        mapping(uint => LineData) initiatedLines;   //initiated (successfully added) Lines
        Line initial;
    }

    /**
     * @dev Add Line, save data in LineData. Run update BrokenLine, require:
     *      1. slope != 0, slope <= bias
     *      2. line not exists
     **/
    function add(BrokenLine storage brokenLine, uint id, Line memory line, uint cliff) internal {
        require(line.slope != 0, "Slope == 0, unacceptable value for slope");
        require(line.slope <= line.bias, "Slope > bias, unacceptable value for slope");
        require(brokenLine.initiatedLines[id].line.bias == 0, "Line with given id is already exist");
        brokenLine.initiatedLines[id] = LineData(line, cliff);

        update(brokenLine, line.start);
        brokenLine.initial.bias = brokenLine.initial.bias.add(line.bias);
        //save bias for history in line.start minus one
        uint256 lineStartMinusOne = line.start.sub(1);
        brokenLine.biasChanges.addToItem(lineStartMinusOne, safeInt(line.bias));
        //period is time without tail
        uint period = line.bias.div(line.slope);

        if (cliff == 0) {
            //no cliff, need to increase brokenLine.initial.slope write now
            brokenLine.initial.slope = brokenLine.initial.slope.add(line.slope);
            //no cliff, save slope in history in time minus one
            brokenLine.slopeChanges.addToItem(lineStartMinusOne, safeInt(line.slope));
        } else {
            //cliffEnd finish in lineStart minus one plus cliff
            uint cliffEnd = lineStartMinusOne.add(cliff);
            //save slope in history in cliffEnd 
            brokenLine.slopeChanges.addToItem(cliffEnd, safeInt(line.slope));
            period = period.add(cliff);
        }

        int mod = safeInt(line.bias.mod(line.slope));
        uint256 endPeriod = line.start.add(period);
        uint256 endPeriodMinus1 = endPeriod.sub(1);
        brokenLine.slopeChanges.subFromItem(endPeriodMinus1, safeInt(line.slope).sub(mod));
        brokenLine.slopeChanges.subFromItem(endPeriod, mod);
    }

    /**
     * @dev Remove Line from BrokenLine, return bias, slope, cliff. Run update BrokenLine.
     **/
    function remove(BrokenLine storage brokenLine, uint id, uint toTime) internal returns (uint bias, uint slope, uint cliff) {
        LineData memory lineData = brokenLine.initiatedLines[id];
        require(lineData.line.bias != 0, "Removing Line, which not exists");
        Line memory line = lineData.line;

        update(brokenLine, toTime);
        //check time Line is over
        bias = line.bias;
        slope = line.slope;
        cliff = 0;
        //for information: bias.div(slope) - this`s period while slope works
        uint finishTime = line.start.add(bias.div(slope)).add(lineData.cliff);
        if (toTime > finishTime) {
            bias = 0;
            slope = 0;
            return (bias, slope, cliff);
        }
        uint finishTimeMinusOne = finishTime.sub(1);
        uint toTimeMinusOne = toTime.sub(1);
        int mod = safeInt(bias.mod(slope));
        uint cliffEnd = line.start.add(lineData.cliff).sub(1);
        if (toTime <= cliffEnd) {//cliff works
            cliff = cliffEnd.sub(toTime).add(1);
            //in cliff finish time compensate change slope by oldLine.slope
            brokenLine.slopeChanges.subFromItem(cliffEnd, safeInt(slope));
            //in new Line finish point use oldLine.slope
            brokenLine.slopeChanges.addToItem(finishTimeMinusOne, safeInt(slope).sub(mod));
        } else if (toTime <= finishTimeMinusOne) {//slope works
            //now compensate change slope by oldLine.slope
            brokenLine.initial.slope = brokenLine.initial.slope.sub(slope);
            //in new Line finish point use oldLine.slope
            brokenLine.slopeChanges.addToItem(finishTimeMinusOne, safeInt(slope).sub(mod));
            bias = finishTime.sub(toTime).mul(slope).add(uint(mod));
            //save slope for history
            brokenLine.slopeChanges.subFromItem(toTimeMinusOne, safeInt(slope));
        } else {//tail works
            //now compensate change slope by tail
            brokenLine.initial.slope = brokenLine.initial.slope.sub(uint(mod));
            bias = uint(mod);
            slope = bias;
            //save slope for history
            brokenLine.slopeChanges.subFromItem(toTimeMinusOne, safeInt(slope));
        }
        brokenLine.slopeChanges.addToItem(finishTime, mod);
        brokenLine.initial.bias = brokenLine.initial.bias.sub(bias);
        brokenLine.initiatedLines[id].line.bias = 0;
        //save bias for history
        brokenLine.biasChanges.subFromItem(toTimeMinusOne, safeInt(bias));
    }

    /**
     * @dev Update initial Line by parameter toTime. Calculate and set all changes
     **/
    function update(BrokenLine storage brokenLine, uint toTime) internal {
        uint time = brokenLine.initial.start;
        if (time == toTime) {
            return;
        }
        uint slope = brokenLine.initial.slope;
        uint bias = brokenLine.initial.bias;
        if (bias != 0) {
            require(toTime > time, "can't update BrokenLine for past time");
            while (time < toTime) {
                bias = bias.sub(slope);

                int newSlope = safeInt(slope).add(brokenLine.slopeChanges[time]);
                require(newSlope >= 0, "slope < 0, something wrong with slope");
                slope = uint(newSlope);

                time = time.add(1);
            }
        }
        brokenLine.initial.start = toTime;
        brokenLine.initial.bias = bias;
        brokenLine.initial.slope = slope;
    }

    function actualValue(BrokenLine storage brokenLine, uint toTime) internal view returns (uint) {
        uint fromTime = brokenLine.initial.start;
        uint bias = brokenLine.initial.bias;
        if (fromTime == toTime) {
            return (bias);
        }

        if (toTime > fromTime) {
            return actualValueForward(brokenLine, fromTime, toTime, bias);
        }
        require(toTime > 0, "unexpected past time");
        return actualValueBack(brokenLine, fromTime, toTime, bias);
    }

    function actualValueForward(BrokenLine storage brokenLine, uint fromTime, uint toTime, uint bias) internal view returns (uint) {
        if ((bias == 0)){
            return (bias);
        }
        uint slope = brokenLine.initial.slope;
        uint time = fromTime;

        while (time < toTime) {
            bias = bias.sub(slope);

            int newSlope = safeInt(slope).add(brokenLine.slopeChanges[time]);
            require(newSlope >= 0, "slope < 0, something wrong with slope");
            slope = uint(newSlope);

            time = time.add(1);
        }
        return bias;
    }

    function actualValueBack(BrokenLine storage brokenLine, uint fromTime, uint toTime, uint bias) internal view returns (uint) {
        uint slope = brokenLine.initial.slope;
        uint time = fromTime;

        while (time > toTime) {
            time = time.sub(1);

            int newBias = safeInt(bias).sub(brokenLine.biasChanges[time]);
            require(newBias >= 0, "bias < 0, something wrong with bias");
            bias = uint(newBias);

            int newSlope = safeInt(slope).sub(brokenLine.slopeChanges[time]);
            require(newSlope >= 0, "slope < 0, something wrong with slope");
            slope = uint(newSlope);

            bias = bias.add(slope);
        }
        return bias;
    }

    function safeInt(uint value) pure internal returns (int result) {
        require(value < 2**255, "int cast error");
        result = int(value);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;
pragma abicoder v2;

import "./LockingBase.sol";

contract LockingVotes is LockingBase {
    using LibBrokenLine for LibBrokenLine.BrokenLine;

    /**
     * @dev Returns the current amount of votes that `account` has.
     */
    function getVotes(address account) external override view returns (uint256) {
        uint currentWeek = roundTimestamp(getBlockNumber());
        return accounts[account].balance.actualValue(currentWeek - 1);
    }

    /**
     * @dev Returns the amount of votes that `account` had
     * at the end of the last period
     */
    function getPastVotes(address account, uint256 blockNumber) external override view returns (uint256) {
        uint currentWeek = roundTimestamp(blockNumber);
        require(blockNumber < getBlockNumber() && currentWeek > 0, "block not yet mined");

        return accounts[account].balance.actualValue(currentWeek - 1);
    }

    /**
     * @dev Returns the total supply of votes available 
     * at the end of the last period
     */
    function getPastTotalSupply(uint256 blockNumber) external override view returns (uint256) {
        uint currentWeek = roundTimestamp(blockNumber);
        require(blockNumber < getBlockNumber() && currentWeek > 0, "block not yet mined");

        return totalSupplyLine.actualValue(currentWeek - 1);
    }

    /**
     * @dev Returns the delegate that `account` has chosen.
     */
    function delegates(address account) external override view returns (address) {
        revert("not implemented");
    }

    /**
     * @dev Delegates votes from the sender to `delegatee`.
     */
    function delegate(address delegatee) external override {
        revert("not implemented");
    }

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
    ) external override {
        revert("not implemented");
    }

    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;
pragma abicoder v2;

import "./LockingBase.sol";

abstract contract LockingRelock is LockingBase {
    using SafeMathUpgradeable for uint;
    using LibBrokenLine for LibBrokenLine.BrokenLine;

    function relock(uint id, address newDelegate, uint newAmount, uint newSlopePeriod, uint newCliff) external notStopped notMigrating returns (uint) {
        address account = verifyLockOwner(id);
        uint time = roundTimestamp(getBlockNumber());
        verification(account, id, newAmount, newSlopePeriod, newCliff, time);

        address _delegate = locks[id].delegate;
        accounts[account].locked.update(time);

        rebalance(id, account, accounts[account].locked.initial.bias, removeLines(id, account, _delegate, time), newAmount);

        counter++;

        addLines(account, newDelegate, newAmount, newSlopePeriod, newCliff, time);
        emit Relock(id, account, newDelegate, counter, time, newAmount, newSlopePeriod, newCliff);

        // IVotesUpgradeable events
        emit DelegateChanged(account, _delegate, newDelegate);
        emit DelegateVotesChanged(_delegate, 0, accounts[_delegate].balance.actualValue(time));
        emit DelegateVotesChanged(newDelegate, 0, accounts[newDelegate].balance.actualValue(time));

        return counter;
    }

    /**
     * @dev Verification parameters:
     *      1. amount > 0, slope > 0
     *      2. cliff period and slope period less or equal two years
     *      3. newFinishTime more or equal oldFinishTime
     */
    function verification(address account, uint id, uint newAmount, uint newSlopePeriod, uint newCliff, uint toTime) internal view {
        require(newAmount > 0, "zero amount");
        require(newCliff <= MAX_CLIFF_PERIOD, "cliff too big");
        require(newSlopePeriod <= MAX_SLOPE_PERIOD, "slope period too big");
        require(newSlopePeriod > 0, "slope period equal 0");

        //check Line with new parameters don`t finish earlier than old Line
        uint newEnd = toTime.add(newCliff).add(newSlopePeriod);
        LibBrokenLine.LineData memory lineData = accounts[account].locked.initiatedLines[id];
        LibBrokenLine.Line memory line = lineData.line;
        uint oldSlopePeriod = divUp(line.bias, line.slope);
        uint oldEnd = line.start.add(lineData.cliff).add(oldSlopePeriod);
        require(oldEnd <= newEnd, "new line period lock too short");

        //check Line with new parameters don`t cut corner old Line
        uint oldCliffEnd = line.start.add(lineData.cliff);
        uint newCliffEnd = toTime.add(newCliff);
        if (oldCliffEnd > newCliffEnd) {
            uint balance = oldCliffEnd.sub(newCliffEnd);
            uint newSlope = divUp(newAmount, newSlopePeriod);
            uint newBias = newAmount.sub(balance.mul(newSlope));
            require(newBias >= line.bias, "detect cut deposit corner");
        }
    }

    function removeLines(uint id, address account, address delegate, uint toTime) internal returns (uint residue) {
        updateLines(account, delegate, toTime);
        accounts[delegate].balance.remove(id, toTime);
        totalSupplyLine.remove(id, toTime);
        (residue,,) = accounts[account].locked.remove(id, toTime);
    }

    function rebalance(uint id, address account, uint bias, uint residue, uint newAmount) internal {
        require(residue <= newAmount, "Impossible to relock: less amount, then now is");
        uint addAmount = newAmount.sub(residue);
        uint amount = accounts[account].amount;
        uint balance = amount.sub(bias);
        if (addAmount > balance) {
            //need more, than balance, so need transfer tokens to this
            uint transferAmount = addAmount.sub(balance);
            accounts[account].amount = accounts[account].amount.add(transferAmount);
            require(token.transferFrom(locks[id].account, address(this), transferAmount), "transfer failed");
        }
    }

    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;
pragma abicoder v2;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

import "./libs/LibBrokenLine.sol";

import "./IVotesUpgradeable.sol";

abstract contract LockingBase is OwnableUpgradeable, IVotesUpgradeable {

    using SafeMathUpgradeable for uint;
    using LibBrokenLine for LibBrokenLine.BrokenLine;

    uint256 constant public WEEK = 50400; //blocks one week = 50400, day = 7200, goerli = 50
    
    uint256 constant MAX_CLIFF_PERIOD = 103;
    uint256 constant MAX_SLOPE_PERIOD = 104;

    uint256 constant ST_FORMULA_DIVIDER =  1 * (10 ** 8);           //stFormula divider          100000000
    uint256 constant ST_FORMULA_CONST_MULTIPLIER = 2 * (10 ** 7);   //stFormula const multiplier  20000000
    uint256 constant ST_FORMULA_CLIFF_MULTIPLIER = 8 * (10 ** 7);   //stFormula cliff multiplier  80000000
    uint256 constant ST_FORMULA_SLOPE_MULTIPLIER = 4 * (10 ** 7);   //stFormula slope multiplier  40000000

    /**
     * @dev ERC20 token to lock
     */
    IERC20Upgradeable public token;
    /**
     * @dev counter for Lock identifiers
     */
    uint public counter;

    /**
     * @dev true if contract entered stopped state
     */
    bool public stopped;

    /**
     * @dev address to migrate Locks to (zero if not in migration state)
     */
    address public migrateTo;

    /**
     * @dev minimal cliff period in weeks, minCliffPeriod < MAX_CLIFF_PERIOD
     */

    uint public minCliffPeriod;

    /**
     * @dev minimal slope period in weeks, minSlopePeriod < MAX_SLOPE_PERIOD
     */
    uint public minSlopePeriod;

    /**
     * @dev locking epoch start in weeks
     */
    uint public startingPointWeek;

    /**
     * @dev represents one user Lock
     */
    struct Lock {
        address account;
        address delegate;
    }

    /**
     * @dev describes state of accounts's balance.
     *      balance - broken line describes lock
     *      locked - broken line describes how many tokens are locked
     *      amount - total currently locked tokens (including tokens which can be withdrawed)
     */
    struct Account {
        LibBrokenLine.BrokenLine balance;
        LibBrokenLine.BrokenLine locked;
        uint amount;
    }

    mapping(address => Account) accounts;
    mapping(uint => Lock) locks;
    LibBrokenLine.BrokenLine public totalSupplyLine;

    /**
     * @dev Emitted when create Lock with parameters (account, delegate, amount, slopePeriod, cliff)
     */
    event LockCreate(uint indexed id, address indexed account, address indexed delegate, uint time, uint amount, uint slopePeriod, uint cliff);
    /**
     * @dev Emitted when change Lock parameters (newDelegate, newAmount, newSlopePeriod, newCliff) for Lock with given id
     */
    event Relock(uint indexed id, address indexed account, address indexed delegate, uint counter, uint time, uint amount, uint slopePeriod, uint cliff);
    /**
     * @dev Emitted when to set newDelegate address for Lock with given id
     */
    event Delegate(uint indexed id, address indexed account, address indexed delegate, uint time);
    /**
     * @dev Emitted when withdraw amount of Rari, account - msg.sender, amount - amount Rari
     */
    event Withdraw(address indexed account, uint amount);
    /**
     * @dev Emitted when migrate Locks with given id, account - msg.sender
     */
    event Migrate(address indexed account, uint[] id);
    /**
     * @dev Stop run contract functions, accept withdraw, account - msg.sender
     */
    event StopLocking(address indexed account);
    /**
     * @dev Start run contract functions, accept withdraw, account - msg.sender
     */
    event StartLocking(address indexed account);
    /**
     * @dev StartMigration initiate migration to another contract, account - msg.sender, to - address delegate to
     */
    event StartMigration(address indexed account, address indexed to);
    /**
     * @dev set newMinCliffPeriod
     */
    event SetMinCliffPeriod(uint indexed newMinCliffPeriod);
    /**
     * @dev set newMinSlopePeriod
     */
    event SetMinSlopePeriod(uint indexed newMinSlopePeriod);
    /**
     * @dev set startingPointWeek
     */
    event SetStartingPointWeek(uint indexed newStartingPointWeek);

    function __LockingBase_init_unchained(IERC20Upgradeable _token, uint _startingPointWeek, uint _minCliffPeriod, uint _minSlopePeriod) internal initializer {
        token = _token;
        startingPointWeek = _startingPointWeek;

        //setting min cliff and slope
        require(_minCliffPeriod <= MAX_CLIFF_PERIOD, "cliff too big");
        require(_minSlopePeriod <= MAX_SLOPE_PERIOD, "period too big");
        minCliffPeriod = _minCliffPeriod;
        minSlopePeriod = _minSlopePeriod;
    }

    function addLines(address account, address _delegate, uint amount, uint slopePeriod, uint cliff, uint time) internal {
        require(slopePeriod <= amount, "Wrong value slopePeriod");
        updateLines(account, _delegate, time);
        (uint stAmount, uint stSlope) = getLock(amount, slopePeriod, cliff);
        LibBrokenLine.Line memory line = LibBrokenLine.Line(time, stAmount, stSlope);
        totalSupplyLine.add(counter, line, cliff);
        accounts[_delegate].balance.add(counter, line, cliff);
        uint slope = divUp(amount, slopePeriod);
        line = LibBrokenLine.Line(time, amount, slope);
        accounts[account].locked.add(counter, line, cliff);
        locks[counter].account = account;
        locks[counter].delegate = _delegate;
    }

    function updateLines(address account, address _delegate, uint time) internal {
        totalSupplyLine.update(time);
        accounts[_delegate].balance.update(time);
        accounts[account].locked.update(time);
    }

    /**
     * Сalculate and return (newAmount, newSlope), using formula:
     * locking = (tokens * (
     *      ST_FORMULA_CONST_MULTIPLIER
     *      + ST_FORMULA_CLIFF_MULTIPLIER * (cliffPeriod - minCliffPeriod))/(MAX_CLIFF_PERIOD - minCliffPeriod)
     *      + ST_FORMULA_SLOPE_MULTIPLIER * (slopePeriod - minSlopePeriod))/(MAX_SLOPE_PERIOD - minSlopePeriod)
     *      )) / ST_FORMULA_DIVIDER
     **/
    function getLock(uint amount, uint slopePeriod, uint cliff) public view returns (uint lockAmount, uint lockSlope) {
        require(cliff >= minCliffPeriod, "cliff period < minimal lock period");
        require(slopePeriod >= minSlopePeriod, "slope period < minimal lock period");

        uint cliffSide = (cliff - minCliffPeriod).mul(ST_FORMULA_CLIFF_MULTIPLIER).div(MAX_CLIFF_PERIOD - minCliffPeriod);
        uint slopeSide = (slopePeriod - minSlopePeriod).mul(ST_FORMULA_SLOPE_MULTIPLIER).div(MAX_SLOPE_PERIOD - minSlopePeriod);
        uint multiplier = cliffSide.add(slopeSide).add(ST_FORMULA_CONST_MULTIPLIER);

        lockAmount = amount.mul(multiplier).div(ST_FORMULA_DIVIDER);
        lockSlope = divUp(lockAmount, slopePeriod);
    }

    function divUp(uint a, uint b) internal pure returns (uint) {
        return ((a.sub(1)).div(b)).add(1);
    }
    
    function roundTimestamp(uint ts) view public returns (uint) {
        if (ts < getEpochShift()) {
            return 0;
        }
        uint shifted = ts.sub(getEpochShift());
        return shifted.div(WEEK).sub(startingPointWeek);
    }

    /**
    * @notice method returns the amount of blocks to shift locking epoch to.
    * By the time of development, the default weekly-epoch calculated by main-net block number
    * would start at about 11-35 UTC on Tuesday
    * we move it to 00-00 UTC Thursday by adding 10800 blocks (approx)
    */
    function getEpochShift() internal view virtual returns (uint) {
        return 10800;
    }

    function verifyLockOwner(uint id) internal view returns (address account) {
        account = locks[id].account;
        require(account == msg.sender, "caller not a lock owner");
    }

    function getBlockNumber() internal virtual view returns (uint) {
        return block.number;
    }

    function setStartingPointWeek(uint newStartingPointWeek) public notStopped notMigrating onlyOwner {
        require(newStartingPointWeek < roundTimestamp(getBlockNumber()) , "wrong newStartingPointWeek");
        startingPointWeek = newStartingPointWeek;

        emit SetStartingPointWeek(newStartingPointWeek);
    } 

    function setMinCliffPeriod(uint newMinCliffPeriod) external  notStopped notMigrating onlyOwner {
        require(newMinCliffPeriod < MAX_CLIFF_PERIOD, "new cliff period > 2 years");
        minCliffPeriod = newMinCliffPeriod;

        emit SetMinCliffPeriod(newMinCliffPeriod);
    }

    function setMinSlopePeriod(uint newMinSlopePeriod) external  notStopped notMigrating onlyOwner {
        require(newMinSlopePeriod < MAX_SLOPE_PERIOD, "new slope period > 2 years");
        minSlopePeriod = newMinSlopePeriod;

        emit SetMinSlopePeriod(newMinSlopePeriod);
    }

    /**
     * @dev Throws if stopped
     */
    modifier notStopped() {
        require(!stopped, "stopped");
        _;
    }

    /**
     * @dev Throws if not stopped
     */
    modifier isStopped() {
        require(stopped, "not stopped");
        _;
    }

    modifier notMigrating() {
        require(migrateTo == address(0), "migrating");
        _;
    }

    function updateAccountLines(address account, uint time) public notStopped notMigrating onlyOwner {
        accounts[account].balance.update(time);
        accounts[account].locked.update(time);
    }

    function updateTotalSupplyLine(uint time) public notStopped notMigrating onlyOwner {
        totalSupplyLine.update(time);
    }

    function updateAccountLinesBlockNumber(address account, uint256 blockNumber) external notStopped notMigrating onlyOwner {
        uint256 time = roundTimestamp(blockNumber);
        updateAccountLines(account, time);
    }
    
    function updateTotalSupplyLineBlockNumber(uint256 blockNumber) external notStopped notMigrating onlyOwner {
        uint256 time = roundTimestamp(blockNumber);
        updateTotalSupplyLine(time);
    }

    //add minCliffPeriod, decrease __gap
    //add minSlopePeriod, decrease __gap
    uint256[48] private __gap;

}

// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;

/**
 * @dev Common interface for {ERC20Votes}, {ERC721Votes}, and other {Votes}-enabled contracts.
 *
 * _Available since v4.5._
 */
interface IVotesUpgradeable {
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

pragma solidity 0.7.6;
pragma abicoder v2;

import "./libs/LibBrokenLine.sol";

interface INextVersionLock {
    function initiateData(uint idLock, LibBrokenLine.LineData memory lineData, address locker, address delegate) external;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.9 <0.8.0;
pragma abicoder v2;

interface ILocking {
    function lock(
        address account,
        address delegate,
        uint amount,
        uint slope,
        uint cliff
    ) external returns (uint);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;
import "../proxy/Initializable.sol";

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {
    }
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

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
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
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

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
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
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
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
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
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
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
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

pragma solidity >=0.6.0 <0.8.0;

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

// solhint-disable-next-line compiler-version
pragma solidity >=0.4.24 <0.8.0;

import "../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {UpgradeableProxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
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
        require(_initializing || _isConstructor() || !_initialized, "Initializable: contract is already initialized");

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

    /// @dev Returns true if and only if the function is running in the constructor
    function _isConstructor() private view returns (bool) {
        return !AddressUpgradeable.isContract(address(this));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @title SignedSafeMath
 * @dev Signed math operations with safety checks that revert on error.
 */
library SignedSafeMathUpgradeable {
    int256 constant private _INT256_MIN = -2**255;

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
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        require(!(a == -1 && b == _INT256_MIN), "SignedSafeMath: multiplication overflow");

        int256 c = a * b;
        require(c / a == b, "SignedSafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two signed integers. Reverts on
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
    function div(int256 a, int256 b) internal pure returns (int256) {
        require(b != 0, "SignedSafeMath: division by zero");
        require(!(b == -1 && a == _INT256_MIN), "SignedSafeMath: division overflow");

        int256 c = a / b;

        return c;
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
        int256 c = a - b;
        require((b >= 0 && c <= a) || (b < 0 && c > a), "SignedSafeMath: subtraction overflow");

        return c;
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
        int256 c = a + b;
        require((b >= 0 && c >= a) || (b < 0 && c < a), "SignedSafeMath: addition overflow");

        return c;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMathUpgradeable {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
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
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
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
        require(b <= a, "SafeMath: subtraction overflow");
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
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
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
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
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
        require(b > 0, "SafeMath: modulo by zero");
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
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
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
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/Initializable.sol";
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
    function __Ownable_init() internal initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal initializer {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
    uint256[49] private __gap;
}