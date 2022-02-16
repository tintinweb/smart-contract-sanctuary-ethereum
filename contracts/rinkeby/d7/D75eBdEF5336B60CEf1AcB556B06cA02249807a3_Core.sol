// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.3;

//import "hardhat/console.sol";

import "./helpers/AzuroErrors.sol";
import "./Math.sol";
import "./interface/ILP.sol";
import "./interface/ICore.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

/// @title This contract register bets and create conditions
contract Core is OwnableUpgradeable, ICore, Math {
    enum conditionState {
        CREATED,
        RESOLVED,
        CANCELED
    }

    struct Bet {
        uint256 conditionID;
        uint128 amount;
        uint64 outcome;
        uint64 createdAt;
        address affiliate; // 160 bit
        uint64 odds;
        bool payed;
    }

    struct Condition {
        uint128[2] fundBank;
        uint128[2] payouts;
        uint128[2] totalNetBets;
        uint128 reinforcement;
        uint64[2] outcomes; // unique outcomes for the condition
        bytes32 ipfsHash;
        uint128 margin;
        uint64 outcomeWin;
        uint64 timestamp; // after this time user cant put bet on condition
        conditionState state;
    }

    uint128 public decimals;
    mapping(address => bool) public oracles;
    uint128 public conditionsReinforcementFix; // should be 20k
    mapping(address => bool) public maintainers;
    uint128 public conditionsMargin;

    address public lpAddress;

    mapping(uint256 => Condition) public conditions;
    mapping(uint256 => Bet) public bets; // tokenID -> BET

    // total payout's locked value - sum of maximum payouts of all execution Condition.
    // on each Condition at betting calculate sum of maximum payouts and put it here
    // after Condition finished on each user payout decrease its value
    uint128 public totalLockedPayout;

    uint256 public lastConditionId;

    // oracle-oracleCondId-conditionId
    mapping(address => mapping(uint256 => uint256)) public oracleConditionIDs;

    modifier onlyOracle() {
        _require(oracles[msg.sender], Errors.ONLY_ORACLE);
        _;
    }
    modifier onlyMaintainer() {
        _require(maintainers[msg.sender], Errors.ONLY_MAINTAINER);
        _;
    }

    modifier OnlyLP() {
        _require(msg.sender == lpAddress, Errors.ONLY_LP);
        _;
    }

    /**
     * init
     */
    function initialize(
        uint128 reinforcement_,
        address oracle_,
        uint128 margin_
    ) public virtual initializer {
        __Ownable_init();
        oracles[oracle_] = true;
        conditionsMargin = margin_; // in decimals ^9
        conditionsReinforcementFix = reinforcement_; // in token decimals
        decimals = 10**9;
    }

    function getLockedPayout() external view override returns (uint256) {
        return totalLockedPayout;
    }

    /**
     * @dev create condition from oracle
     * @param oracleCondID the current match or game id, (it is oracle's game number, internal conditionId is hash(oracleConditionIDs, oracle wallet))
     * @param odds start odds array[2] for [team 1, team 2]
     * @param outcomes unique outcome for the condition [outcome 1, outcome 2]
     * @param timestamp time when match starts and bets stopped accepts
     * @param ipfsHash detailed info about math stored in IPFS
     */
    function createCondition(
        uint256 oracleCondID,
        uint64[2] memory odds,
        uint64[2] memory outcomes,
        uint64 timestamp,
        bytes32 ipfsHash
    ) external override onlyOracle {
        // condition must be ended before next phase end date
        _require(timestamp < ILP(lpAddress).phase2end(), Errors.DISTANT_FUTURE);
        _require(timestamp > 0, Errors.TIMESTAMP_CAN_NOT_BE_ZERO);
        _require(
            odds[0] > 0 && odds[1] > 0 && outcomes[0] != outcomes[1],
            Errors.CONDITION_PARAMS_INCORRECT
        );
        _require(
            oracleConditionIDs[msg.sender][oracleCondID] == 0,
            Errors.CONDITION_ALREADY_CREATED
        );
        _require(
            ILP(lpAddress).getPossibilityOfReinforcement(
                conditionsReinforcementFix
            ),
            Errors.NOT_ENOUGH_LIQUIDITY
        );

        lastConditionId++;
        oracleConditionIDs[msg.sender][oracleCondID] = lastConditionId;

        Condition storage newCondition = conditions[lastConditionId];

        newCondition.fundBank[0] =
            (conditionsReinforcementFix * odds[1]) /
            (odds[0] + odds[1]);
        newCondition.fundBank[1] =
            (conditionsReinforcementFix * odds[0]) /
            (odds[0] + odds[1]);

        newCondition.outcomes = outcomes;
        newCondition.reinforcement = conditionsReinforcementFix;
        newCondition.timestamp = timestamp;
        newCondition.ipfsHash = ipfsHash;
        ILP(lpAddress).lockReserve(conditionsReinforcementFix);

        // save new condition link
        newCondition.margin = conditionsMargin; //not used yet
        newCondition.state = conditionState.CREATED;

        emit ConditionCreated(lastConditionId, timestamp);
    }

    /**
     * @dev register the bet in the core
     * @param conditionID the current match or game
     * @param tokenId bet id of the stake (registered on nft AzuroBet)
     * @param amount bet amount in tokens
     * @param outcomeWin bet outcome
     * @param minOdds odds slippage
     * @return odds
     * @return fund1 after bet
     * @return fund2 after bet
     */
    function putBet(
        uint256 conditionID,
        uint256 tokenId,
        uint128 amount,
        uint64 outcomeWin,
        uint64 minOdds,
        address affiliate
    )
        external
        override
        OnlyLP
        returns (
            uint64,
            uint128,
            uint128
        )
    {
        Condition storage condition = conditions[conditionID];
        _require(
            (condition.fundBank[1] + amount) / condition.fundBank[0] < 10000 &&
                (condition.fundBank[0] + amount) / condition.fundBank[1] <
                10000,
            Errors.BIG_DIFFERENCE
        );
        _require(
            block.timestamp < condition.timestamp,
            Errors.BETS_TIME_EXCEEDED
        );

        _require(
            isOutComeCorrect(conditionID, outcomeWin),
            Errors.WRONG_OUTCOME
        );

        uint8 outcomeIndex = (
            outcomeWin == conditions[conditionID].outcomes[0] ? 0 : 1
        );

        uint64 odds = calculateOdds(conditionID, amount, outcomeWin);

        _require(odds >= minOdds, Errors.ODDS_TOO_SMALL);
        _require(amount > decimals, Errors.SMALL_BET);

        condition.totalNetBets[outcomeIndex] += amount;

        bets[tokenId] = Bet({
            conditionID: conditionID,
            amount: amount,
            outcome: outcomeWin,
            affiliate: affiliate,
            createdAt: uint64(block.timestamp),
            odds: odds,
            payed: false
        });

        condition.fundBank[outcomeIndex] += amount;

        // calc previous maximum payout's value
        uint128 previousMaxPayout = (
            condition.payouts[0] > condition.payouts[1]
                ? condition.payouts[0]
                : condition.payouts[1]
        );

        // calc new payout for the outcome
        condition.payouts[outcomeIndex] += (odds * amount) / decimals;
        // calc maximum payout's value
        uint128 maxPayout = (
            condition.payouts[0] > condition.payouts[1]
                ? condition.payouts[0]
                : condition.payouts[1]
        );
        if (maxPayout > previousMaxPayout) {
            // if new maxPayout greater than previouse add greater delta to global totalLockedPayout
            totalLockedPayout += (maxPayout - previousMaxPayout);
        }

        _require(
            maxPayout <= condition.fundBank[0] + condition.fundBank[1],
            Errors.CANT_ACCEPT_THE_BET
        );

        return (odds, condition.fundBank[0], condition.fundBank[1]);
    }

    /**
     * @dev resolve the payout
     * @param tokenID it is betID
     * @return success
     * @return amount of better win
     */
    function resolvePayout(uint256 tokenID)
        external
        override
        OnlyLP
        returns (bool success, uint128 amount)
    {
        Bet storage currentBet = bets[tokenID];

        Condition storage condition = conditions[currentBet.conditionID];

        _require(
            condition.state == conditionState.RESOLVED ||
                condition.state == conditionState.CANCELED,
            Errors.EVENT_NOT_HAPPENED_YET
        );

        (success, amount) = _viewPayout(tokenID);

        if (success && amount > 0) {
            currentBet.payed = true;
        }

        return (success, amount);
    }

    /**
     * @dev resolve condition from oracle
     * @param oracleCondID - id of the game, (it is oracle's game number, internal conditionId is hash(conditionId, oracle wallet))
     * @param outcomeWin - team win outcome
     */
    function resolveCondition(uint256 oracleCondID, uint64 outcomeWin)
        external
        override
        onlyOracle
    {
        uint256 conditionID = oracleConditionIDs[msg.sender][oracleCondID];

        Condition storage condition = conditions[conditionID];
        _require(condition.timestamp > 0, Errors.CONDITION_NOT_EXISTS);
        _require(
            block.timestamp >= condition.timestamp,
            Errors.CONDITION_CANT_BE_RESOLVE_BEFORE_TIMELIMIT
        );
        _require(
            condition.state == conditionState.CREATED,
            Errors.CONDITION_ALREADY_SET
        );

        _require(
            isOutComeCorrect(conditionID, outcomeWin),
            Errors.WRONG_OUTCOME
        );

        condition.outcomeWin = outcomeWin;
        condition.state = conditionState.RESOLVED;

        uint8 outcomeIndex = (outcomeWin == condition.outcomes[0] ? 0 : 1);
        uint128 bettersPayout = condition.payouts[outcomeIndex];

        uint128 profitReserve = (condition.fundBank[0] +
            condition.fundBank[1]) - bettersPayout;

        reduceTotalLockedPayout(condition);

        ILP(lpAddress).addReserve(condition.reinforcement, profitReserve);

        // send oracle profit if it is
        if (profitReserve >= condition.reinforcement) {
            ILP(lpAddress).sendOracleReward(
                msg.sender,
                ((profitReserve - condition.reinforcement) *
                    ILP(lpAddress).getOracleFee()) /
                    ILP(lpAddress).getFeeDecimals()
            );
        }

        emit ConditionResolved(
            conditionID,
            outcomeWin,
            uint8(conditionState.RESOLVED),
            profitReserve
        );
    }

    function setLP(address lpAddress_) external override onlyOwner {
        lpAddress = lpAddress_;
    }

    // for test MVP
    function setOracle(address oracle_) external onlyOwner {
        oracles[oracle_] = true;
    }

    function renounceOracle(address oracle_) external onlyOwner {
        oracles[oracle_] = false;
    }

    function addMaintainer(address maintainer, bool active) external onlyOwner {
        maintainers[maintainer] = active;
    }

    // set conditionState.CANCELED for cancelled conditions
    function cancel(uint256 conditionID) external onlyMaintainer {
        Condition storage condition = conditions[conditionID];
        _require(condition.timestamp > 0, Errors.CONDITION_NOT_EXISTS);
        _require(
            block.timestamp >= condition.timestamp,
            Errors.CONDITION_CANT_BE_RESOLVE_BEFORE_TIMELIMIT
        );
        _require(
            condition.state == conditionState.CREATED,
            Errors.CONDITION_ALREADY_SET
        );

        condition.state = conditionState.CANCELED;

        reduceTotalLockedPayout(condition);

        ILP(lpAddress).addReserve(condition.reinforcement, 0);
        emit ConditionResolved(
            conditionID,
            0,
            uint8(conditionState.CANCELED),
            0
        );
    }

    function reduceTotalLockedPayout(Condition storage condition) internal {
        // if exists amount of locked payout -> release locked payout from global state
        uint128 maxPayout = (
            condition.payouts[0] > condition.payouts[1]
                ? condition.payouts[0]
                : condition.payouts[1]
        );
        if (maxPayout != 0) {
            // decrease global totalLockedPayout on payout paid value
            totalLockedPayout -= maxPayout;
        }
    }

    function shift(uint256 conditionID, uint64 newTimestamp)
        external
        onlyMaintainer
    {
        _require(
            conditions[conditionID].timestamp > 0,
            Errors.CONDITION_NOT_EXISTS
        );
        conditions[conditionID].timestamp = newTimestamp;
        emit ConditionShifted(conditionID, newTimestamp);
    }

    function viewPayout(uint256 tokenID_)
        external
        view
        override
        returns (bool success, uint256 amount)
    {
        return (_viewPayout(tokenID_));
    }

    function getCondition(uint256 conditionID)
        external
        view
        returns (Condition memory)
    {
        return (conditions[conditionID]);
    }

    /**
     * @dev get fundBanks from condition record by conditionID
     */
    function getConditionFunds(uint256 conditionID)
        external
        view
        returns (uint128[2] memory fundBank)
    {
        return (conditions[conditionID].fundBank);
    }

    /**
     * internal view, used resolve payout and external views
     * @param tokenID - NFT token id
     */

    function _viewPayout(uint256 tokenID)
        internal
        view
        returns (bool success, uint128 amount)
    {
        Bet storage currentBet = bets[tokenID];
        Condition storage condition = conditions[currentBet.conditionID];

        if (
            !currentBet.payed &&
            (condition.outcomeWin == condition.outcomes[0]) &&
            (currentBet.outcome == condition.outcomes[0])
        ) {
            uint128 winAmount = (currentBet.odds * currentBet.amount) /
                decimals;
            return (true, winAmount);
        }

        if (
            !currentBet.payed &&
            (condition.outcomeWin == condition.outcomes[1]) &&
            (currentBet.outcome == condition.outcomes[1])
        ) {
            uint128 winAmount = (currentBet.odds * currentBet.amount) /
                decimals;
            return (true, winAmount);
        }

        if (!currentBet.payed && (condition.state == conditionState.CANCELED)) {
            return (true, currentBet.amount);
        }
        return (false, 0);
    }

    /**
     * @dev resolve condition from oracle
     * @param conditionID - id of the game
     * @param amount - tokens to bet
     * @param outcomeWin - team win outcome
     * @return odds for this bet
     */
    function calculateOdds(
        uint256 conditionID,
        uint128 amount,
        uint64 outcomeWin
    ) public view returns (uint64 odds) {
        if (isOutComeCorrect(conditionID, outcomeWin)) {
            Condition storage condition = conditions[conditionID];
            uint8 outcomeIndex = (outcomeWin == condition.outcomes[0] ? 0 : 1);
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
                    decimals
                )
            );
        }
    }

    function getCurrentReinforcement()
        external
        view
        override
        returns (uint256)
    {
        return conditionsReinforcementFix;
    }

    /**
     * @dev check outcome correctness
     * @param conditionID - condition id
     * @param outcomeWin - outcome to be tested
     */
    function isOutComeCorrect(uint256 conditionID, uint256 outcomeWin)
        public
        view
        returns (bool correct)
    {
        correct = (outcomeWin == conditions[conditionID].outcomes[0] ||
            outcomeWin == conditions[conditionID].outcomes[1]);
    }

    function getBetInfo(uint256 betId)
        external
        view
        override
        returns (
            uint128 amount,
            uint64 odds,
            uint64 createdAt,
            address affiliate
        )
    {
        return (
            bets[betId].amount,
            bets[betId].odds,
            bets[betId].createdAt,
            bets[betId].affiliate
        );
    }

    function isOraclce(address oracleWallet)
        external
        view
        override
        returns (bool)
    {
        return oracles[oracleWallet];
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity 0.8.3;

// solhint-disable

/**
 * @dev Reverts if `condition` is false, with a revert reason containing `errorCode`. Only codes up to 999 are
 * supported.
 */
function _require(bool condition, uint256 errorCode) pure {
    if (!condition) _revert(errorCode);
}

/**
 * @dev Reverts with a revert reason containing `errorCode`. Only codes up to 999 are supported.
 */
function _revert(uint256 errorCode) pure {
    // We're going to dynamically create a revert string based on the error code, with the following format:
    // 'AZU#{errorCode}'
    // where the code is left-padded with zeroes to three digits (so they range from 000 to 999).
    //
    // We don't have revert strings embedded in the contract to save bytecode size: it takes much less space to store a
    // number (8 to 16 bits) than the individual string characters.
    //
    // The dynamic string creation algorithm that follows could be implemented in Solidity, but assembly allows for a
    // much denser implementation, again saving bytecode size. Given this function unconditionally reverts, this is a
    // safe place to rely on it without worrying about how its usage might affect e.g. memory contents.
    assembly {
        // First, we need to compute the ASCII representation of the error code. We assume that it is in the 0-999
        // range, so we only need to convert three digits. To convert the digits to ASCII, we add 0x30, the value for
        // the '0' character.

        let units := add(mod(errorCode, 10), 0x30)

        errorCode := div(errorCode, 10)
        let tenths := add(mod(errorCode, 10), 0x30)

        errorCode := div(errorCode, 10)
        let hundreds := add(mod(errorCode, 10), 0x30)

        // With the individual characters, we can now construct the full string. The "AZU#" part is a known constant
        // (0x415a5523): we simply shift this by 24 (to provide space for the 3 bytes of the error code), and add the
        // characters to it, each shifted by a multiple of 8.
        // The revert reason is then shifted left by 200 bits (256 minus the length of the string, 7 characters * 8 bits
        // per character = 56) to locate it in the most significant part of the 256 slot (the beginning of a byte
        // array).

        let revertReason := shl(
            200,
            add(
                0x415a5523000000,
                add(add(units, shl(8, tenths)), shl(16, hundreds))
            )
        )

        // We can now encode the reason in memory, which can be safely overwritten as we're about to revert. The encoded
        // message will have the following layout:
        // [ revert reason identifier ] [ string location offset ] [ string length ] [ string contents ]

        // The Solidity revert reason identifier is 0x08c739a0, the function selector of the Error(string) function. We
        // also write zeroes to the next 28 bytes of memory, but those are about to be overwritten.
        mstore(
            0x0,
            0x08c379a000000000000000000000000000000000000000000000000000000000
        )
        // Next is the offset to the location of the string, which will be placed immediately after (20 bytes away).
        mstore(
            0x04,
            0x0000000000000000000000000000000000000000000000000000000000000020
        )
        // The string length is fixed: 7 characters.
        mstore(0x24, 7)
        // Finally, the string itself is stored.
        mstore(0x44, revertReason)

        // Even if the string is only 7 bytes long, we need to return a full 32 byte slot containing it. The length of
        // the encoded message is therefore 4 + 32 + 32 + 32 = 100.
        revert(0, 100)
    }
}

library Errors {
    // LP
    uint256 internal constant EXPIRED_ERROR = 30;
    uint256 internal constant ONLY_BET_OWNER = 31;
    uint256 internal constant ONLY_CORE = 32;
    uint256 internal constant AMOUNT_MUST_BE_NON_ZERO = 33;
    uint256 internal constant LIQUIDITY_REQUEST_EXCEEDED_BALANCE = 34;
    uint256 internal constant LIQUIDITY_REQUEST_EXCEEDED = 35;
    uint256 internal constant NOT_ENOUGH_RESERVE = 36;
    uint256 internal constant PERIOD_NOT_PASSED = 37;
    uint256 internal constant NO_WIN_NO_PRIZE = 38;
    uint256 internal constant INCORRECT_OUTCOME = 41;
    uint256 internal constant TIMELIMIT = 42;
    uint256 internal constant ALREADY_SET = 43;
    uint256 internal constant RESOLVE_NOT_STARTED = 44;
    uint256 internal constant RESOLVE_COMPLETED = 45;
    uint256 internal constant MUST_NOT_HAVE_ACTIVE_DISPUTES = 46;
    uint256 internal constant TIME_TO_RESOLVE_NOT_PASSED = 47;
    uint256 internal constant DISTANT_FUTURE = 48;
    uint256 internal constant LP_INIT = 49;
    uint256 internal constant NO_LOCKED_PAYMENT = 491;

    // Core
    uint256 internal constant ONLY_ORACLE = 50;
    uint256 internal constant ONLY_MAINTAINER = 51;
    uint256 internal constant ONLY_LP = 52;
    uint256 internal constant TIMESTAMP_CAN_NOT_BE_ZERO = 53;
    uint256 internal constant CONDITION_ALREADY_SET = 54;
    uint256 internal constant BIG_DIFFERENCE = 55;
    uint256 internal constant BETS_TIME_EXCEEDED = 56;
    uint256 internal constant WRONG_OUTCOME = 57;
    uint256 internal constant ODDS_TOO_SMALL = 58;
    uint256 internal constant SMALL_BET = 59;
    uint256 internal constant CANT_ACCEPT_THE_BET = 60;
    uint256 internal constant EVENT_NOT_HAPPENED_YET = 61;
    uint256 internal constant CONDITION_NOT_EXISTS = 62;
    uint256 internal constant CONDITION_CANT_BE_RESOLVE_BEFORE_TIMELIMIT = 63;
    uint256 internal constant NOT_ENOUGH_LIQUIDITY = 64;
    uint256 internal constant CONDITION_ALREADY_CREATED = 65;
    uint256 internal constant CONDITION_PARAMS_INCORRECT = 66;
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.3;

//import "hardhat/console.sol";

contract Math {
    function getOddsFromBanks(
        uint256 fund1Bank_,
        uint256 fund2Bank_,
        uint256 amount_,
        uint256 outcomeIndex_,
        uint256 marginality_,
        uint256 decimals_
    ) public pure returns (uint256) {
        if (outcomeIndex_ == 0) {
            uint256 pe1 = ((fund1Bank_ + amount_) * decimals_) /
                (fund1Bank_ + fund2Bank_ + amount_);
            uint256 ps1 = (fund1Bank_ * decimals_) / (fund1Bank_ + fund2Bank_);
            uint256 cAmount = ceil(
                ((amount_ * decimals_) / (fund1Bank_ / 100)),
                decimals_,
                decimals_
            ) / decimals_; // step
            if (cAmount == 1) {
                return addMargin((decimals_**2) / ps1, marginality_, decimals_);
            }
            uint256 odds = (decimals_**3) /
                (((pe1 * cAmount + ps1 * 2 - pe1 * 2) * decimals_) / cAmount);
            return addMargin(odds, marginality_, decimals_);
        }

        if (outcomeIndex_ == 1) {
            uint256 pe2 = ((fund2Bank_ + amount_) * decimals_) /
                (fund1Bank_ + fund2Bank_ + amount_);
            uint256 ps2 = (fund2Bank_ * decimals_) / (fund1Bank_ + fund2Bank_);
            uint256 cAmount = ceil(
                ((amount_ * decimals_) / (fund2Bank_ / 100)),
                decimals_,
                decimals_
            ) / decimals_;
            if (cAmount == 1) {
                return addMargin((decimals_**2) / ps2, marginality_, decimals_);
            }
            uint256 odds = (decimals_**3) /
                (((pe2 * cAmount + ps2 * 2 - pe2 * 2) * decimals_) / cAmount);
            return addMargin(odds, marginality_, decimals_);
        }
        return 0;
    }

    function ceil(
        uint256 a,
        uint256 m,
        uint256 decimals
    ) public pure returns (uint256) {
        if (a < decimals) return decimals;
        return ((a + m - 1) / m) * m;
    }

    function sqrt(uint256 x) public pure returns (uint256 y) {
        uint256 z = (x + 1) / 2;
        y = x;
        while (z < y) {
            y = z;
            z = (x / z + z) / 2;
        }
    }

    function addMargin(
        uint256 odds,
        uint256 marginality,
        uint256 decimals
    ) public pure returns (uint256 newOdds) {
        uint256 revertOdds = decimals**2 / (decimals - decimals**2 / odds);
        uint256 marginEUR = decimals + marginality; // decimals
        uint256 a = (marginEUR * (revertOdds - decimals)) / (odds - decimals);
        uint256 b = ((((revertOdds - decimals) * decimals) /
            (odds - decimals)) *
            marginality +
            decimals *
            marginality) / decimals;
        uint256 c = (2 * decimals - marginEUR);
        newOdds =
            ((sqrt(b**2 + 4 * a * c) - b) * decimals) /
            (2 * a) +
            decimals;
        return newOdds;
    }
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.3;

interface ILP {
    function changeCore(address addr_) external;

    function addLiquidity(uint256 _amount) external;

    function withdrawLiquidity(uint256 _amount) external;

    function viewPayout(uint256 tokenId) external view returns (bool, uint256);

    function bet(
        uint256 conditionID,
        uint128 amount,
        uint64 outcomeID,
        uint64 deadline,
        uint64 minOdds,
        address affiliate_
    ) external returns (uint256);

    function getReserve() external view returns (uint256);

    function lockReserve(uint128 amount) external;

    function addReserve(uint128 initReserve, uint128 profitReserve) external;

    function withdrawPayout(uint256 tokenId) external;

    function sendOracleReward(address _oracle, uint256 _amount) external;

    function claimDAOReward() external;

    function getPossibilityOfReinforcement(uint256 reinforcementAmount)
        external
        view
        returns (bool);

    function getLiquidityRequests(address wallet)
        external
        view
        returns (
            uint256[3] memory beginDates,
            uint256[3] memory personal,
            uint256[3] memory total
        );

    function phase2end() external view returns (uint256);

    function getOracleFee() external view returns (uint256 fee);

    function getFeeDecimals() external view returns (uint256 feeDecimals);
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.3;

interface ICore {
    event ConditionCreated(uint256 conditionID, uint64 timestamp);
    event ConditionResolved(
        uint256 conditionID,
        uint64 outcomeWin,
        uint8 state,
        uint256 amountForLP
    );
    event ConditionShifted(uint256 conditionID, uint64 newTimestamp);

    function getLockedPayout() external view returns (uint256);

    function createCondition(
        uint256 oracleConditionID,
        uint64[2] memory odds,
        uint64[2] memory outcomes,
        uint64 timestamp,
        bytes32 ipfsHash
    ) external;

    function resolveCondition(uint256 conditionID_, uint64 outcomeWin_)
        external;

    function viewPayout(uint256 tokenID) external view returns (bool, uint256);

    function resolvePayout(uint256 tokenID) external returns (bool, uint128);

    function setLP(address lpAddress_) external;

    function getCurrentReinforcement() external view returns (uint256);

    function putBet(
        uint256 conditionID,
        uint256 tokenId,
        uint128 amount,
        uint64 outcomeWin,
        uint64 minOdds,
        address affiliate
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
            uint64 createdAt,
            address affiliate
        );

    function isOraclce(address oracleWallet) external view returns (bool);
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