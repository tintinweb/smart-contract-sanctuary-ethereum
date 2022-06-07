// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.4;

import "./Math.sol";
import "./interface/ILP.sol";
import "./interface/ICore.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

/// @title Azuro internal core register bets and create conditions
contract Core is OwnableUpgradeable, ICore, Math {
    uint256 public lastConditionId;

    uint128 public defaultReinforcement;
    uint128 public defaultMargin;

    // total payout's locked value - sum of maximum payouts of all execution Condition.
    // on each Condition at betting calculate sum of maximum payouts and put it here
    // after Condition finished on each user payout decrease its value
    uint128 public totalLockedPayout;
    uint128 public multiplier;

    uint64 public maxBanksRatio;
    bool public allConditionsStopped;

    mapping(uint64 => uint128) reinforcements; // outcomeId -> reinforcement
    mapping(uint64 => uint128) margins; // outcomeId -> margin

    mapping(uint256 => Condition) public conditions;
    mapping(uint256 => Bet) public bets; // tokenId -> bet

    mapping(address => bool) public oracles;
    mapping(address => bool) public maintainers;

    // oracle-oracleCondId-conditionId
    mapping(address => mapping(uint256 => uint256)) public oracleConditionIds;

    ILP public LP;

    // All condition stopped receive bets

    /**
     * @notice Only permits calls by oracles.
     */
    modifier onlyOracle() {
        if (oracles[msg.sender] == false) revert OnlyOracle();
        _;
    }

    /**
     * @notice Only permits calls by maintainers.
     */
    modifier onlyMaintainer() {
        if (maintainers[msg.sender] == false) revert OnlyMaintainer();
        _;
    }

    /**
     * @notice Only permits calls by LP.
     */
    modifier onlyLp() {
        if (msg.sender != address(LP)) revert OnlyLp();
        _;
    }

    function initialize(
        uint128 reinforcement,
        address oracle,
        uint128 margin
    ) external virtual initializer {
        __Ownable_init();
        oracles[oracle] = true;
        defaultReinforcement = reinforcement;
        defaultMargin = margin;
        maxBanksRatio = 10000;
        multiplier = 10**9;
    }

    /**
     * @notice Get total amount of locked payouts.
     */
    function getLockedPayout() external view override returns (uint256) {
        return totalLockedPayout;
    }

    /**
     * @notice Oracle: Register new condition.
     * @param  oracleCondId the match or game ID in oracle's internal system
     * @param  scopeId ID of the competition or event the condition belongs
     * @param  odds start odds for [team 1, team 2]
     * @param  outcomes unique outcomes for the condition [outcome 1, outcome 2]
     * @param  timestamp time when match starts and bets stopped accepts
     * @param  ipfsHash detailed info about match stored in IPFS
     */
    function createCondition(
        uint256 oracleCondId,
        uint128 scopeId,
        uint64[2] memory odds,
        uint64[2] memory outcomes,
        uint64 timestamp,
        bytes32 ipfsHash
    ) external override onlyOracle {
        if (timestamp <= block.timestamp) revert IncorrectTimestamp();
        if (odds[0] == 0 || odds[1] == 0) revert ZeroOdds();
        if (outcomes[0] == outcomes[1]) revert SameOutcomes();
        if (oracleConditionIds[msg.sender][oracleCondId] != 0)
            revert ConditionAlreadyCreated();
        if (!LP.getPossibilityOfReinforcement(getReinforcement(outcomes[0])))
            revert NotEnoughLiquidity();

        lastConditionId++;
        oracleConditionIds[msg.sender][oracleCondId] = lastConditionId;

        Condition storage newCondition = conditions[lastConditionId];
        newCondition.scopeId = scopeId;
        newCondition.reinforcement = getReinforcement(outcomes[0]);

        newCondition.fundBank[0] =
            (newCondition.reinforcement * odds[1]) /
            (odds[0] + odds[1]);
        newCondition.fundBank[1] =
            (newCondition.reinforcement * odds[0]) /
            (odds[0] + odds[1]);

        newCondition.margin = getMargin(outcomes[0]);
        newCondition.outcomes = outcomes;
        newCondition.timestamp = timestamp;
        newCondition.ipfsHash = ipfsHash;
        newCondition.leaf = LP.getLeaf();

        LP.lockReserve(newCondition.reinforcement);

        emit ConditionCreated(oracleCondId, lastConditionId, timestamp);
    }

    /**
     * @notice LP: Register new bet in the core.
     * @param  conditionId the match or game ID
     * @param  tokenId AzuroBet token ID
     * @param  amount amount of tokens to bet
     * @param  outcome ID of predicted outcome
     * @param  minOdds minimum allowed bet odds
     * @return betting odds
     * @return fund bank of condition's outcome 1
     * @return fund bank of condition's outcome 2
     */
    function putBet(
        uint256 conditionId,
        uint256 tokenId,
        uint128 amount,
        uint64 outcome,
        uint64 minOdds
    )
        external
        override
        onlyLp
        returns (
            uint64,
            uint128,
            uint128
        )
    {
        Condition storage condition = conditions[conditionId];
        if (allConditionsStopped || condition.state != ConditionState.CREATED)
            revert BetNotAllowed();
        uint8 outcomeIndex = (
            outcome == conditions[conditionId].outcomes[0] ? 0 : 1
        );
        if (
            (condition.fundBank[outcomeIndex] + amount) /
                condition.fundBank[outcomeIndex == 1 ? 0 : 1] >=
            maxBanksRatio
        ) revert BigDifference();
        if (block.timestamp >= condition.timestamp) revert ConditionStarted();
        if (!isOutComeCorrect(conditionId, outcome)) revert WrongOutcome();

        uint64 odds = calculateOdds(conditionId, amount, outcome);

        if (odds < minOdds) revert SmallOdds();
        if (amount <= multiplier) revert SmallBet();

        Bet storage bet = bets[tokenId];
        bet.conditionId = conditionId;
        bet.amount = amount;
        bet.outcome = outcome;
        bet.createdAt = uint64(block.timestamp);
        bet.odds = odds;

        condition.fundBank[outcomeIndex] += amount;

        // calc previous maximum payout's value
        uint128 previousMaxPayout = (
            condition.payouts[0] > condition.payouts[1]
                ? condition.payouts[0]
                : condition.payouts[1]
        );
        // calc new payout for the outcome
        condition.payouts[outcomeIndex] += (odds * amount) / multiplier;
        // calc maximum payout's value
        uint128 maxPayout = (
            condition.payouts[0] > condition.payouts[1]
                ? condition.payouts[0]
                : condition.payouts[1]
        );

        // update total locked payout's value
        if (maxPayout > previousMaxPayout) {
            uint128 deltaPayout = maxPayout - previousMaxPayout;
            // maximum bet limit check, bet's maximum payout limited by available LP reserve
            if (deltaPayout > (LP.getReserve() - totalLockedPayout))
                revert CantAcceptBet();
            totalLockedPayout += deltaPayout;
        }

        condition.totalNetBets[outcomeIndex] += amount;

        return (odds, condition.fundBank[0], condition.fundBank[1]);
    }

    /**
     * @notice LP: Resolve AzuroBet token `tokenId` payout.
     * @param  tokenId AzuroBet token ID
     * @return success if the payout is successfully resolved
     * @return amount the amount of winnings of the owner of the token
     */
    function resolvePayout(uint256 tokenId)
        external
        override
        onlyLp
        returns (bool success, uint128 amount)
    {
        Bet storage currentBet = bets[tokenId];

        Condition storage condition = conditions[currentBet.conditionId];

        if (
            condition.state != ConditionState.RESOLVED &&
            condition.state != ConditionState.CANCELED
        ) revert ConditionNotStarted();

        (success, amount) = viewPayout(tokenId);

        if (success && amount > 0) {
            currentBet.payed = true;
            // reduce common payouts
            totalLockedPayout -= amount;
        }

        return (success, amount);
    }

    /**
     * @notice Oracle: Indicate outcome `outcomeWin` as happened in oracle's condition `oracleCondId`.
     * @param  oracleCondId the match or game ID in oracle's internal system
     * @param  outcomeWin ID of happened outcome
     */
    function resolveCondition(uint256 oracleCondId, uint64 outcomeWin)
        external
        override
        onlyOracle
    {
        uint256 conditionId = oracleConditionIds[msg.sender][oracleCondId];

        Condition storage condition = conditions[conditionId];
        if (condition.timestamp == 0) revert ConditionNotExists();
        uint64 timeOut = condition.timestamp + 1 minutes;
        if (block.timestamp < timeOut) revert ResolveTooEarly(timeOut);
        if (condition.state != ConditionState.CREATED)
            revert ConditionAlreadyResolved();

        if (!isOutComeCorrect(conditionId, outcomeWin)) revert WrongOutcome();

        condition.outcomeWin = outcomeWin;
        condition.state = ConditionState.RESOLVED;

        uint8 outcomeIndex = (outcomeWin == condition.outcomes[0] ? 0 : 1);
        uint128 bettersPayout = condition.payouts[outcomeIndex];

        // totalLockedPayout: exchange maxPayOut with winnerPayout
        reduceTotalLockedPayout(condition, bettersPayout);

        uint128 profitReserve = (condition.fundBank[0] +
            condition.fundBank[1]) - bettersPayout;

        LP.addReserve(
            condition.reinforcement,
            profitReserve,
            condition.leaf,
            msg.sender
        );

        emit ConditionResolved(
            oracleCondId,
            conditionId,
            outcomeWin,
            uint8(ConditionState.RESOLVED),
            profitReserve
        );
    }

    /**
     * @notice Owner: Set `lp` as LP new address.
     * @param  lp new LP contract address
     */
    function setLp(address lp) external override onlyOwner {
        LP = ILP(lp);
        emit LpChanged(lp);
    }

    /**
     * @notice Owner: Indicate address `oracle` as oracle.
     * @param  oracle new oracle address
     */
    function setOracle(address oracle) external onlyOwner {
        oracles[oracle] = true;
        emit OracleAdded(oracle);
    }

    /**
     * @notice Owner: Do not consider address `oracle` a oracle anymore
     * @param  oracle address of oracle to renounce
     */
    function renounceOracle(address oracle) external onlyOwner {
        oracles[oracle] = false;
        emit OracleRenounced(oracle);
    }

    /**
     * @notice Owner: Indicate if address `maintainer` is active maintainer or not.
     * @param  maintainer maintainer address
     * @param  active if address is currently maintainer or not
     */
    function addMaintainer(address maintainer, bool active) external onlyOwner {
        maintainers[maintainer] = active;
        emit MaintainerUpdated(maintainer, active);
    }

    /**
     * @notice  Oracle: Indicate the condition `oracleConditionId` as canceled.
     * @param   oracleConditionId the current match or game ID in oracle's internal system
     */
    function cancelByOracle(uint256 oracleConditionId) external onlyOracle {
        cancel(
            oracleConditionIds[msg.sender][oracleConditionId],
            oracleConditionId
        );
    }

    /**
     * @notice  Maintainer: Indicate the condition `conditionId` as canceled.
     * @param   conditionId the current match or game ID
     */
    function cancelByMaintainer(uint256 conditionId) external onlyMaintainer {
        cancel(conditionId, 0);
    }

    /**
     * @notice  Indicate the condition `conditionId` with oracle ID `oracleConditionId` as canceled.
     * @dev     Set oracleConditionId to zero if the function is not called by an oracle.
     * @param   conditionId the current match or game ID
     * @param   oracleConditionId the current match or game ID in oracle's internal system
     */
    function cancel(uint256 conditionId, uint256 oracleConditionId) internal {
        Condition storage condition = conditions[conditionId];
        if (condition.timestamp == 0) revert ConditionNotExists();
        if (
            condition.state == ConditionState.RESOLVED ||
            condition.state == ConditionState.CANCELED
        ) revert ConditionAlreadyResolved();

        condition.state = ConditionState.CANCELED;

        reduceTotalLockedPayout(
            condition,
            condition.totalNetBets[0] + condition.totalNetBets[1]
        );

        LP.addReserve(
            condition.reinforcement,
            condition.reinforcement,
            condition.leaf,
            address(0)
        );
        emit ConditionResolved(
            oracleConditionId,
            conditionId,
            0,
            uint8(ConditionState.CANCELED),
            0
        );
    }

    /**
     * @dev    Reduce amount of funds locked by condition by `lockValue`.
     * @param  condition the match or game struct
     * @param  lockValue the value by which reduce the amount of funds locked by condition
     */
    function reduceTotalLockedPayout(
        Condition storage condition,
        uint128 lockValue
    ) internal {
        // if exists amount of locked payout -> release locked payout from global state
        uint128 maxPayout = (
            condition.payouts[0] > condition.payouts[1]
                ? condition.payouts[0]
                : condition.payouts[1]
        );
        if (maxPayout != 0) {
            // exchange maxPayout with lockValue
            totalLockedPayout = totalLockedPayout - maxPayout + lockValue;
        }
    }

    /**
     * @notice Maintainer: Set `newTimestamp` as new condition `conditionId` deadline.
     * @param  conditionId the match or game ID
     * @param  newTimestamp new condition start time
     */
    function shift(uint256 conditionId, uint64 newTimestamp)
        external
        onlyOracle
    {
        if (conditions[conditionId].timestamp == 0) revert ConditionNotExists();
        conditions[conditionId].timestamp = newTimestamp;
        emit ConditionShifted(conditionId, newTimestamp);
    }

    /**
     * @notice Maintainer: Change maximum ratio of condition's outcomes fund banks.
     * @param  newRatio new maximum ratio
     */
    function changeMaxBanksRatio(uint64 newRatio) external onlyMaintainer {
        maxBanksRatio = newRatio;
        emit MaxBanksRatioChanged(newRatio);
    }

    /**
     * @notice Get reinforcement for outcome `outcomeId`.
     * @param  outcomeId outcome ID
     * @return reinforcement for outcome `outcomeId` if defined or default value
     */
    function getReinforcement(uint64 outcomeId) public view returns (uint128) {
        if (reinforcements[outcomeId] != 0) return reinforcements[outcomeId];
        return defaultReinforcement;
    }

    /**
     * @notice Maintainer: Update reinforcement values for outcomes.
     * @param  data new reinforcement values in format:
     *              [outcomeId 1, reinforcement 1, ... 2, ... 2, ...]
     */
    function updateReinforcements(uint128[] memory data)
        external
        onlyMaintainer
    {
        if (data.length % 2 == 1) revert WrongDataFormat();

        for (uint256 i = 0; i < data.length; i += 2) {
            reinforcements[uint64(data[i])] = data[i + 1];
        }
    }

    /**
     * @notice Get margin for outcome `outcomeId`.
     * @param  outcomeId outcome ID
     * @return margin for outcome `outcomeId` if defined or default value
     */
    function getMargin(uint64 outcomeId) public view returns (uint128) {
        if (margins[outcomeId] != 0) return margins[outcomeId];
        return defaultMargin;
    }

    /**
     * @notice Maintainer: Update margin values for outcomes.
     * @param  data new margin values in format:
     *              [outcomeId 1, margin 1, ... 2, ... 2, ...]
     */
    function updateMargins(uint128[] memory data) external onlyMaintainer {
        if (data.length % 2 == 1) revert WrongDataFormat();

        for (uint256 i = 0; i < data.length; i += 2) {
            margins[uint64(data[i])] = data[i + 1];
        }
    }

    /**
     * @notice Maintainer: Indicate the status of total bet lock.
     * @param  flag if stop receiving bets or not
     */
    function stopAllConditions(bool flag) external onlyMaintainer {
        if (allConditionsStopped == flag) revert FlagAlreadySet();
        allConditionsStopped = flag;
        emit AllConditionsStopped(flag);
    }

    /**
     * @notice Maintainer: Indicate the status of condition `conditionId` bet lock.
     * @param  conditionId the match or game ID
     * @param  flag if stop receiving bets for the condition or not
     */
    function stopCondition(uint256 conditionId, bool flag)
        external
        onlyMaintainer
    {
        Condition storage condition = conditions[conditionId];
        // only CREATED state can be stoped
        // only PAUSED state can be restored
        if (
            (condition.state != ConditionState.CREATED && flag) ||
            (condition.state != ConditionState.PAUSED && !flag)
        ) revert CantChangeFlag();

        condition.state = flag ? ConditionState.PAUSED : ConditionState.CREATED;

        emit ConditionStopped(conditionId, flag);
    }

    /**
     * @notice Get AzuroBet token `tokenId` payout.
     * @param  tokenId AzuroBet token ID
     * @return success if the payout is successfully resolved
     * @return amount winnings of the owner of the token
     */
    function viewPayout(uint256 tokenId)
        public
        view
        override
        returns (bool success, uint128 amount)
    {
        Bet storage currentBet = bets[tokenId];
        Condition storage condition = conditions[currentBet.conditionId];

        if (currentBet.payed) return (false, 0);
        if (condition.state == ConditionState.CANCELED)
            return (true, currentBet.amount);
        if (
            condition.state == ConditionState.RESOLVED &&
            condition.outcomeWin == currentBet.outcome
        ) return (true, (currentBet.odds * currentBet.amount) / multiplier);
        return (false, 0);
    }

    /**
     * @notice Get condition by it's ID.
     * @param  conditionId the match or game ID
     * @return the match or game struct
     */
    function getCondition(uint256 conditionId)
        external
        view
        returns (Condition memory)
    {
        return (conditions[conditionId]);
    }

    /**
     * @notice Get condition `conditionId` fund banks.
     * @param  conditionId the match or game ID
     * @return fundBank fund banks of condition
     */
    function getConditionFunds(uint256 conditionId)
        external
        view
        returns (uint128[2] memory fundBank)
    {
        return (conditions[conditionId].fundBank);
    }

    /**
     * @notice Get condition `conditionId` reinforcement.
     * @param  conditionId the match or game ID
     * @return reinforcement condition's reinforcement
     */
    function getConditionReinforcement(uint256 conditionId)
        external
        view
        returns (uint128 reinforcement)
    {
        return (conditions[conditionId].reinforcement);
    }

    /**
     * @notice Calculate the odds of bet with amount `amount` for outcome `outcome` of condition `conditionId`.
     * @param  conditionId the match or game ID
     * @param  amount amount of tokens to bet
     * @param  outcome ID of predicted outcome
     * @return odds betting odds
     */
    function calculateOdds(
        uint256 conditionId,
        uint128 amount,
        uint64 outcome
    ) public view returns (uint64 odds) {
        if (isOutComeCorrect(conditionId, outcome)) {
            Condition storage condition = conditions[conditionId];
            uint8 outcomeIndex = (outcome == condition.outcomes[0] ? 0 : 1);
            odds = uint64(
                Math.getOddsFromBanks(
                    condition.fundBank[0] +
                        condition.totalNetBets[1] -
                        condition.payouts[1],
                    condition.fundBank[1] +
                        condition.totalNetBets[0] -
                        condition.payouts[0],
                    amount,
                    outcomeIndex,
                    condition.margin,
                    multiplier
                )
            );
        }
    }

    /**
     * @notice Check if the condition `conditionId` have outcome `outcome` as possible
     * @param  conditionId the match or game ID
     * @param  outcome outcome ID
     */
    function isOutComeCorrect(uint256 conditionId, uint256 outcome)
        public
        view
        returns (bool correct)
    {
        correct = (outcome == conditions[conditionId].outcomes[0] ||
            outcome == conditions[conditionId].outcomes[1]);
    }

    /**
     * @notice  Get AzuroBet token info.
     * @param   betId AzuroBet token ID
     * @return  amount the bet amount
     * @return  odds betting odds
     * @return  createdAt when the bet was registered
     */
    function getBetInfo(uint256 betId)
        external
        view
        override
        returns (
            uint128 amount,
            uint64 odds,
            uint64 createdAt
        )
    {
        return (bets[betId].amount, bets[betId].odds, bets[betId].createdAt);
    }

    /**
     * @notice Check if the address `oracle` is oracle.
     * @return if the address `oracle` is oracle.
     */
    function isOracle(address oracle) external view override returns (bool) {
        return oracles[oracle];
    }
    function dummy2() public {}
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.4;

/// @title Azuro betting odds calculation logic
contract Math {
    /**
     * @dev    See {_getOddsFromBanks}.
     * @param  outcomeIndex bet related condition's outcome number [0, 1]
     */
    function getOddsFromBanks(
        uint256 fund1Bank,
        uint256 fund2Bank,
        uint256 amount,
        uint256 outcomeIndex,
        uint256 margin,
        uint256 multiplier
    ) public pure returns (uint256) {
        if (outcomeIndex == 0) {
            return
                _getOddsFromBanks(
                    fund1Bank,
                    fund2Bank,
                    amount,
                    margin,
                    multiplier
                );
        }
        if (outcomeIndex == 1) {
            return
                _getOddsFromBanks(
                    fund2Bank,
                    fund1Bank,
                    amount,
                    margin,
                    multiplier
                );
        }
        return 0;
    }

    /**
     * @notice Get betting odds.
     * @param  fund1Bank fund bank of condition's outcome 1
     * @param  fund2Bank fund bank of condition's outcome 2
     * @param  amount amount of tokens to bet
     * @param  margin bookmaker commission
     * @param  multiplier decimal unit representation
     * @return betting odds value
     */
    function _getOddsFromBanks(
        uint256 fund1Bank,
        uint256 fund2Bank,
        uint256 amount,
        uint256 margin,
        uint256 multiplier
    ) internal pure returns (uint256) {
        uint256 pe1 = ((fund1Bank + amount) * multiplier) /
            (fund1Bank + fund2Bank + amount);
        uint256 ps1 = (fund1Bank * multiplier) / (fund1Bank + fund2Bank);
        uint256 cAmount = ceil(
            ((amount * multiplier) / (fund1Bank / 100)),
            multiplier
        ) / multiplier; // step
        if (cAmount == 1) {
            return
                marginAdjustedOdds((multiplier**2) / ps1, margin, multiplier);
        }
        uint256 odds = (multiplier**3) /
            (((pe1 * cAmount + ps1 * 2 - pe1 * 2) * multiplier) / cAmount);
        return marginAdjustedOdds(odds, margin, multiplier);
    }

    /**
     * @notice Get ceil of `x` with decimal unit representation `m`.
     */
    function ceil(uint256 a, uint256 m) public pure returns (uint256) {
        if (a < m) return m;
        return ((a + m - 1) / m) * m;
    }

    /**
     * @notice Get integer square root of `x`.
     */
    function sqrt(uint256 x) public pure returns (uint256 y) {
        uint256 z = (x + 1) / 2;
        y = x;
        while (z < y) {
            y = z;
            z = (x / z + z) / 2;
        }
    }

    /**
     * @notice Get commission adjusted betting odds.
     * @param  odds betting odds
     * @param  marginality bookmaker commission
     * @param  multiplier decimal unit representation
     * @return newOdds commission adjusted betting odds
     */
    function marginAdjustedOdds(
        uint256 odds,
        uint256 marginality,
        uint256 multiplier
    ) public pure returns (uint256 newOdds) {
        uint256 revertOdds = multiplier**2 /
            (multiplier - multiplier**2 / odds);
        uint256 a = ((multiplier + marginality) * (revertOdds - multiplier)) /
            (odds - multiplier);
        uint256 b = ((((revertOdds - multiplier) * multiplier) /
            (odds - multiplier)) *
            marginality +
            multiplier *
            marginality) / multiplier;
        newOdds =
            ((sqrt(b**2 + 4 * a * (multiplier - marginality)) - b) *
                multiplier) /
            (2 * a) +
            multiplier;
        return newOdds;
    }
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.4;

interface ILP {
    event NewBet(
        address indexed owner,
        uint256 indexed betId,
        uint256 indexed conditionId,
        uint64 outcomeId,
        uint128 amount,
        uint256 odds,
        uint128 fund1,
        uint128 fund2
    );

    event BetterWin(address indexed better, uint256 tokenId, uint256 amount);
    event LiquidityAdded(address indexed account, uint256 amount, uint48 leaf);
    event LiquidityRemoved(address indexed account, uint256 amount);
    event LiquidityRequested(
        address indexed requestWallet,
        uint256 requestedValueLp
    );

    event OracleRewardChanged(uint128 newOracleFee);
    event DaoRewardChanged(uint128 newDaoFee);
    event AzuroBetChanged(address newAzuroBet);
    event PeriodChanged(uint64 newPeriod);
    event MinDepoChanged(uint128 newMinDepo);
    event WithdrawTimeoutChanged(uint64 newWithdrawTimeout);
    event ReinforcementAbilityChanged(uint128 newReinforcementAbility);

    error OnlyBetOwner();
    error OnlyCore();

    error AmountMustNotBeZero();
    error AmountNotSufficient();
    error NoDaoReward();
    error NoWinNoPrize();
    error LiquidityNotOwned();
    error LiquidityIsLocked();
    error NoLiquidity();
    error PaymentLocked();
    error WrongToken();
    error ConditionStarted();
    error NotEnoughReserves();
    error WithdrawalTimeout(uint64 waitTime);

    function changeCore(address newCore) external;

    function addLiquidity(uint128 amount) external;

    function addLiquidityNative() external payable;

    function withdrawLiquidity(uint48 depNum, uint40 percent) external;

    function withdrawLiquidityNative(uint48 depNum, uint40 percent) external;

    function viewPayout(uint256 tokenId) external view returns (bool, uint128);

    function bet(
        uint256 conditionId,
        uint128 amount,
        uint64 outcomeId,
        uint64 deadline,
        uint64 minOdds
    ) external returns (uint256);

    function getReserve() external view returns (uint128);

    function lockReserve(uint128 amount) external;

    function addReserve(
        uint128 initReserve,
        uint128 profitReserve,
        uint48 leaf,
        address oracle
    ) external;

    function withdrawPayout(uint256 tokenId) external;

    function withdrawPayoutNative(uint256 tokenId) external;

    function claimDaoReward() external;

    function getPossibilityOfReinforcement(uint128 reinforcementAmount)
        external
        view
        returns (bool);

    function getLeaf() external view returns (uint48 leaf);

    function betNative(
        uint256 conditionId,
        uint64 outcomeId,
        uint64 deadline,
        uint64 minOdds
    ) external payable returns (uint256);
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.4;

interface ICore {
    enum ConditionState {
        CREATED,
        RESOLVED,
        CANCELED,
        PAUSED
    }

    struct Bet {
        uint256 conditionId;
        uint128 amount;
        uint64 outcome;
        uint64 createdAt;
        uint64 odds;
        bool payed;
    }

    struct Condition {
        uint128[2] fundBank;
        uint128[2] payouts;
        uint128[2] totalNetBets;
        uint128 reinforcement;
        uint128 margin;
        bytes32 ipfsHash;
        uint64[2] outcomes; // unique outcomes for the condition
        uint128 scopeId;
        uint64 outcomeWin;
        uint64 timestamp; // after this time user cant put bet on condition
        ConditionState state;
        uint48 leaf;
    }

    event ConditionCreated(
        uint256 indexed oracleConditionId,
        uint256 indexed conditionId,
        uint64 timestamp
    );
    event ConditionResolved(
        uint256 indexed oracleConditionId,
        uint256 indexed conditionId,
        uint64 outcomeWin,
        uint8 state,
        uint256 amountForLp
    );
    event LpChanged(address indexed newLp);
    event MaxBanksRatioChanged(uint64 newRatio);
    event MaintainerUpdated(address indexed maintainer, bool active);
    event OracleAdded(address indexed newOracle);
    event OracleRenounced(address indexed oracle);
    event AllConditionsStopped(bool flag);
    event ConditionStopped(uint256 indexed conditionId, bool flag);
    event ConditionShifted(uint256 conditionId, uint64 newTimestamp);

    error OnlyLp();
    error OnlyMaintainer();
    error OnlyOracle();

    error FlagAlreadySet();
    error CantChangeFlag();
    error IncorrectTimestamp();
    error SameOutcomes();
    error SmallBet();
    error SmallOdds();
    error WrongDataFormat();
    error WrongOutcome();
    error ZeroOdds();

    error ConditionNotExists();
    error ConditionNotStarted();
    error ResolveTooEarly(uint64 waitTime);
    error ConditionStarted();
    error ConditionAlreadyCreated();
    error ConditionAlreadyResolved();
    error BetNotAllowed();

    error BigDifference();
    error CantAcceptBet();
    error NotEnoughLiquidity();

    function getLockedPayout() external view returns (uint256);

    function createCondition(
        uint256 oracleConditionId,
        uint128 scopeId,
        uint64[2] memory odds,
        uint64[2] memory outcomes,
        uint64 timestamp,
        bytes32 ipfsHash
    ) external;

    function resolveCondition(uint256 conditionId, uint64 outcomeWin) external;

    function viewPayout(uint256 tokenId) external view returns (bool, uint128);

    function resolvePayout(uint256 tokenId) external returns (bool, uint128);

    function setLp(address lp) external;

    function putBet(
        uint256 conditionId,
        uint256 tokenId,
        uint128 amount,
        uint64 outcome,
        uint64 minOdds
    )
        external
        returns (
            uint64,
            uint128,
            uint128
        );

    function getBetInfo(uint256 betId)
        external
        view
        returns (
            uint128 amount,
            uint64 odds,
            uint64 createdAt
        );

    function isOracle(address oracle) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (access/Ownable.sol)

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
    function __Ownable_init() internal initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal initializer {
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
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/Context.sol)

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
    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (proxy/utils/Initializable.sol)

pragma solidity ^0.8.0;

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
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
        require(_initializing || !_initialized, "Initializable: contract is already initialized");

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
}