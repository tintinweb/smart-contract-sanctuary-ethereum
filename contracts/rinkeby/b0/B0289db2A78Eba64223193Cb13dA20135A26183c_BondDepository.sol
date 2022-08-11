// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import "./NoteKeeper.sol";

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "./IBondDepository.sol";

/// @title Olympus Bond Depository V2
/// @author Zeus, Indigo
/// Review by: JeffX

contract BondDepository is IBondDepository, NoteKeeper {
    /* ======== DEPENDENCIES ======== */

    using SafeERC20 for IERC20;

    /* ======== EVENTS ======== */

    /* ======== STATE VARIABLES ======== */

    // Storage
    Market[] public markets; // persistent market data
    Terms[] public terms; // deposit construction data
    Metadata[] public metadata; // extraneous market data
    mapping(uint256 => Adjustment) public adjustments; // control variable changes
    address public treasury;

    // Queries
    mapping(address => uint256[]) public marketsForQuote; // market IDs for quote token

    /* ======== CONSTRUCTOR ======== */

    constructor(
        NEND _nend,
        address insurance,
        address _treasury
    ) NoteKeeper(_nend, insurance) {
        treasury = _treasury;
    }

    /* ======== DEPOSIT ======== */

    /**
     * @notice             deposit quote tokens in exchange for a bond from a specified market
     * @param _id          the ID of the market
     * @param _amount      the amount of quote token to spend
     * @param _maxPrice    the maxeimum price at which to buy
     * @return payout_     the amount of gOHM due
     * @return index_      the user index of the Note (usd to redeem or query information)
     */
    function deposit(
        uint256 _id,
        uint256 _amount,
        uint256 _maxPrice
    ) external override returns (uint256 payout_, uint256 index_) {
        Market storage market = markets[_id];
        Terms memory term = terms[_id];
        uint48 currentTime = uint48(block.timestamp);

        // Markets end at a defined timestamp
        // |-------------------------------------| t
        require(currentTime < term.conclusion, "Depository: market concluded");

        // Debt and the control variable decay over time
        _decay(_id, currentTime);

        // Users input a maximum price, which protects them from price changes after
        // entering the mempool. max price is a slippage mitigation measure
        uint256 price = _marketPrice(_id);
        require(price <= _maxPrice, "Depository: more than max price");

        /**
         * payout for the deposit = amount / price
         *
         * where
         * payout = OHM out
         * amount = quote tokens in
         * price = quote tokens : ohm (i.e. 42069 DAI : OHM)
         *
         * 1e18 = NEND decimals (18) + price decimals (9)
         */
        payout_ =
            ((_amount * 1e27) / price) /
            (10**metadata[_id].quoteDecimals);

        // markets have a max payout amount, capping size because deposits
        // do not experience slippage. max payout is recalculated upon tuning
        require(payout_ <= market.maxPayout, "Depository: max size exceeded");

        /*
         * each market is initialized with a capacity
         *
         * this is either the number of OHM that the market can sell
         * (if capacity in quote is false),
         *
         * or the number of quote tokens that the market can buy
         * (if capacity in quote is true)
         */
        market.capacity -= market.capacityInQuote ? _amount : payout_;

        /**
         * bonds mature with a cliff at a set timestamp
         * prior to the expiry timestamp, no payout tokens are accessible to the user
         * after the expiry timestamp, the entire payout can be redeemed
         *
         * there are two types of bonds: fixed-term and fixed-expiration
         *
         * fixed-term bonds mature in a set amount of time from deposit
         * i.e. term = 1 week. when alice deposits on day 1, her bond
         * expires on day 8. when bob deposits on day 2, his bond expires day 9.
         *
         * fixed-expiration bonds mature at a set timestamp
         * i.e. expiration = day 10. when alice deposits on day 1, her term
         * is 9 days. when bob deposits on day 2, his term is 8 days.
         */

        // markets keep track of how many quote tokens have been
        // purchased, and how much OHM has been sold
        market.purchased += _amount;
        market.sold += uint64(payout_);

        // incrementing total debt raises the price of the next bond
        market.totalDebt += uint64(payout_);

        /**
         * user data is stored as Notes. these are isolated array entries
         * storing the amount due, the time created, the time when payout
         * is redeemable, the time when payout was redeemed, and the ID
         * of the market deposited into
         */
        index_ = addNote(uint48(_id), _amount, price, msg.sender, payout_);

        // transfer payment to treasury
        market.quoteToken.safeTransferFrom(msg.sender, treasury, _amount);

        // if max debt is breached, the market is closed
        // this a circuit breaker
        if (term.maxDebt < market.totalDebt) {
            market.capacity = 0;
            emit CloseMarket(_id);
        } else {
            // if market will continue, the control variable is tuned to hit targets on time
            _tune(_id, currentTime);
        }
    }

    /**
     * @notice             decay debt, and adjust control variable if there is an active change
     * @param _id          ID of market
     * @param _time        uint48 timestamp (saves gas when passed in)
     */
    function _decay(uint256 _id, uint48 _time) internal {
        // Debt decay

        /*
         * Debt is a time-decayed sum of tokens spent in a market
         * Debt is added when deposits occur and removed over time
         * |
         * |    debt falls with
         * |   / \  inactivity       / \
         * | /     \              /\/    \
         * |         \           /         \
         * |           \      /\/            \
         * |             \  /  and rises       \
         * |                with deposits
         * |
         * |------------------------------------| t
         */
        markets[_id].totalDebt -= _debtDecay(_id);
        metadata[_id].lastDecay = _time;

        // Control variable decay

        // The bond control variable is continually tuned. When it is lowered (which
        // lowers the market price), the change is carried out smoothly over time.
        if (adjustments[_id].active) {
            Adjustment storage adjustment = adjustments[_id];

            (
                uint256 adjustBy,
                uint48 secondsSince,
                bool stillActive
            ) = _controlDecay(_id);
            terms[_id].controlVariable -= adjustBy;

            if (stillActive) {
                adjustment.change -= adjustBy;
                adjustment.timeToAdjusted -= secondsSince;
                adjustment.lastAdjustment = _time;
            } else {
                adjustment.active = false;
            }
        }
    }

    /**
     * @notice             auto-adjust control variable to hit capacity/spend target
     * @param _id          ID of market
     * @param _time        uint48 timestamp (saves gas when passed in)
     */
    function _tune(uint256 _id, uint48 _time) internal {
        Metadata memory meta = metadata[_id];

        if (_time >= meta.lastTune + meta.tuneInterval) {
            Market memory market = markets[_id];

            // compute seconds remaining until market will conclude
            uint256 timeRemaining = terms[_id].conclusion - _time;
            uint256 price = _marketPrice(_id);

            // standardize capacity into an base token amount
            // NEND decimals (9) + price decimals (9)
            uint256 capacity = market.capacityInQuote
                ? ((market.capacity * 1e27) / price) / (10**meta.quoteDecimals)
                : market.capacity;

            /**
             * calculate the correct payout to complete on time assuming each bond
             * will be max size in the desired deposit interval for the remaining time
             *
             * i.e. market has 10 days remaining. deposit interval is 1 day. capacity
             * is 10,000 OHM. max payout would be 1,000 OHM (10,000 * 1 / 10).
             */
            markets[_id].maxPayout = uint64(
                (capacity * meta.depositInterval) / timeRemaining
            );

            // calculate the ideal total debt to satisfy capacity in the remaining time
            uint256 targetDebt = (capacity * meta.length) / timeRemaining;

            // derive a new control variable from the target debt and current supply
            uint64 newControlVariable = uint64(
                (price * nend.currentSupply()) / targetDebt
            );

            if (newControlVariable >= terms[_id].controlVariable) {
                terms[_id].controlVariable = newControlVariable;
            } else {
                // if decrease, control variable change will be carried out over the tune interval
                // this is because price will be lowered
                uint256 change = terms[_id].controlVariable - newControlVariable;
                adjustments[_id] = Adjustment(
                    change,
                    _time,
                    meta.tuneInterval,
                    true
                );
            }
            metadata[_id].lastTune = _time;
        }
    }

    /* ======== CREATE ======== */

    function create(
        IERC20 _quoteToken,
        uint256 _capacity,
        bool _capacityInQuote,
        uint256 _initialPrice,
        uint48 _conclusion,
        uint32 _depositInterval,
        uint32 _tuneInterval
    ) external override returns (uint256 id_) {
        uint256 secondsToConclusion = _conclusion - block.timestamp;

        // the decimal count of the quote token
        uint256 decimals = ERC20(address(_quoteToken)).decimals();

        /*
         * initial target debt is equal to capacity (this is the amount of debt
         * that will decay over in the length of the program if price remains the same).
         * it is converted into base token terms if passed in in quote token terms.
         *
         * 1e27 = NEND decimals (18) + initial price decimals (9)
         */
        uint256 targetDebt = _capacityInQuote
                ? ((_capacity * 1e27) / _initialPrice) / 10**decimals
                : _capacity;

        /*
         * max payout is the amount of capacity that should be utilized in a deposit
         * interval. for example, if capacity is 1,000 OHM, there are 10 days to conclusion,
         * and the preferred deposit interval is 1 day, max payout would be 100 OHM.
         */
        uint256 maxPayout = (targetDebt * _depositInterval) / secondsToConclusion;

        /*
         * the control variable is set so that initial price equals the desired
         * initial price. the control variable is the ultimate determinant of price,
         * so we compute this last.
         *
         * price = control variable * debt ratio
         * debt ratio = total debt / supply
         * therefore, control variable = price / debt ratio
         */
        uint256 controlVariable = (_initialPrice * nend.currentSupply()) /
            targetDebt;

        // depositing into, or getting info for, the created market uses this ID
        id_ = markets.length;

        markets.push(
            Market({
                quoteToken: _quoteToken,
                capacityInQuote: _capacityInQuote,
                capacity: _capacity,
                totalDebt: targetDebt,
                maxPayout: maxPayout,
                purchased: 0,
                sold: 0
            })
        );

        terms.push(
            Terms({
                controlVariable: uint64(controlVariable),
                conclusion: uint48(_conclusion),
                maxDebt: targetDebt + ((targetDebt * 1000000) / 1e5)
            })
        );

        metadata.push(
            Metadata({
                lastTune: uint48(block.timestamp),
                lastDecay: uint48(block.timestamp),
                length: uint48(secondsToConclusion),
                depositInterval: _depositInterval,
                tuneInterval: _tuneInterval,
                quoteDecimals: uint8(decimals)
            })
        );

        marketsForQuote[address(_quoteToken)].push(id_);

        emit CreateMarket(
            id_,
            address(_quoteToken),
            uint48(_conclusion),
            _capacityInQuote
        );
    }

    /**
     * @notice             disable existing market
     * @param _id          ID of market to close
     */
    function close(uint256 _id) external override {
        terms[_id].conclusion = uint48(block.timestamp);
        markets[_id].capacity = 0;
        emit CloseMarket(_id);
    }

    /* ======== EXTERNAL VIEW ======== */

    function getMarketData(uint256 _id)
        external
        view
        override
        returns (uint256, uint256)
    {
        return (_marketPrice(_id), markets[_id].capacity);
    }

    /* ======== INTERNAL VIEW ======== */

    function _debtDecay(uint256 _id) internal view returns (uint64) {
        Metadata memory meta = metadata[_id];

        uint256 secondsSince = block.timestamp - meta.lastDecay;

        return uint64((markets[_id].totalDebt * secondsSince) / meta.length);
    }

    /**
     * @notice                  calculate current market price of quote token in base token
     * @dev                     see marketPrice() for explanation of price computation
     * @dev                     uses info from storage because data has been updated before call (vs marketPrice())
     * @param _id               market ID
     * @return                  price for market in NEND decimals
     */
    function _marketPrice(uint256 _id) internal view returns (uint256) {
        return
            (terms[_id].controlVariable * _debtRatio(_id)) /
            (10**metadata[_id].quoteDecimals);
    }

    /**
     * @notice                  calculate debt factoring in decay
     * @dev                     uses info from storage because data has been updated before call (vs debtRatio())
     * @param _id               market ID
     * @return                  current debt for market in quote decimals
     */
    function _debtRatio(uint256 _id) internal view returns (uint256) {
        return
            (markets[_id].totalDebt * (10**metadata[_id].quoteDecimals)) /
            nend.currentSupply();
    }

    /**
     * @notice                  amount to decay control variable by
     * @param _id               ID of market
     * @return decay_           change in control variable
     * @return secondsSince_    seconds since last change in control variable
     * @return active_          whether or not change remains active
     */
    function _controlDecay(uint256 _id)
        internal
        view
        returns (
            uint256 decay_,
            uint48 secondsSince_,
            bool active_
        )
    {
        Adjustment memory info = adjustments[_id];
        if (!info.active) return (0, 0, false);

        secondsSince_ = uint48(block.timestamp) - info.lastAdjustment;

        active_ = secondsSince_ < info.timeToAdjusted;
        decay_ = active_
            ? (info.change * secondsSince_) / info.timeToAdjusted
            : info.change;
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.0;

import "./INoteKeeper.sol";
import "../token/ERC20/NEND.sol";

abstract contract NoteKeeper is INoteKeeper {
    mapping(address => Note[]) public notes; // user deposit data
    address public insurance;
    NEND public nend;
    uint8 public immutable totalVestingCount = 5; // 5 times in 5 days

    constructor(NEND _nend, address _insurance) {
        insurance = _insurance;
        nend = _nend;
    }

    // if treasury address changes on authority, update it
    function updateNend(NEND _nend) external {
        nend = _nend;
    }

    function updateInsurance(address _insurance) external {
        insurance = _insurance;
    }

    /* ========== ADD ========== */

    /**
     * @notice             adds a new Note for a user, stores the front end & DAO rewards, and mints & stakes payout & rewards
     * @param _marketId    id of the market that created the note
     * @param _amount      amount of quote token bonded
     * @param _price       the bond price
     * @param _user        the user that owns the Note
     * @param _payout      the amount of OHM due to the user
     * @return index_      the index of the Note in the user's array
     */
    function addNote(
        uint48 _marketId,
        uint256 _amount,
        uint256 _price,
        address _user,
        uint256 _payout
    ) internal returns (uint256 index_) {
        uint256 insuranceFund = (_payout * 30) / 10000;
        uint256 userPayout = _payout - insuranceFund;

        index_ = notes[_user].length;

        // the new note is pushed to the user's array
        notes[_user].push(
            Note({
                payout: userPayout,
                payoutPerVesting: userPayout / 5,
                created: uint48(block.timestamp),
                marketID: _marketId,
                vestingCount: 0
            })
        );

        nend.mint(insurance, insuranceFund);

        emit NoteCreated(
            msg.sender,
            _marketId,
            index_,
            _amount,
            _price,
            _payout,
            userPayout / 5,
            uint48(block.timestamp)
        );
    }

    /* ========== REDEEM ========== */

    /**
     * @notice             redeem notes for user
     * @param _indexes     the note indexes to redeem
     * @return payout_     sum of payout sent, in gOHM
     */
    function redeem(uint256[] memory _indexes)
        public
        override
        returns (uint256 payout_)
    {
        require(_indexes.length > 0, "Nothing to redeem");

        uint8[] memory vestingCount = new uint8[](_indexes.length);
        uint256[] memory totalVested = new uint256[](_indexes.length);

        for (uint256 i = 0; i < _indexes.length; i++) {
            Note storage note = notes[msg.sender][_indexes[i]];
            uint8 pendingVestingCount = getPendingVestingCount(
                msg.sender,
                _indexes[i]
            );

            require(pendingVestingCount > 0, "No pending vesting");

            note.vestingCount += pendingVestingCount;
            payout_ += note.payoutPerVesting * pendingVestingCount;

            vestingCount[i] = note.vestingCount;
            totalVested[i] = note.vestingCount * note.payoutPerVesting;
        }

        nend.mint(msg.sender, payout_);
        emit NotesRedeemed(msg.sender, _indexes, vestingCount, totalVested);
    }

    /**
     * @notice             redeem all redeemable markets for user
     * @dev                if possible, query indexesFor() off-chain and input in redeem() to save gas
     * @return             sum of payout sent, in gOHM
     */
    function redeemAll() external override returns (uint256) {
        return redeem(indexesFor(msg.sender));
    }

    /* ========== VIEW ========== */

    // Note info

    /**
     * @notice             all pending notes for user
     * @param _user        the user to query notes for
     * @return             the pending notes for the user
     */
    function indexesFor(address _user)
        internal
        view
        returns (uint256[] memory)
    {
        Note[] memory info = notes[_user];

        uint256 length;
        for (uint256 i = 0; i < info.length; i++) {
            if (getPendingVestingCount(_user, i) > 0) length++;
        }

        uint256[] memory indexes = new uint256[](length);
        uint256 position;

        for (uint256 i = 0; i < info.length; i++) {
            if (getPendingVestingCount(_user, i) > 0) {
                indexes[position] = i;
                position++;
            }
        }

        return indexes;
    }

    function getPendingVestingCount(address _owner, uint256 _noteId)
        internal
        view
        returns (uint8)
    {
        Note memory note = notes[_owner][_noteId];

        // Max vesting
        if (note.vestingCount == totalVestingCount) {
            return 0;
        }

        uint256 secondsElapsed = block.timestamp - note.created;
        uint256 daysElapsed = secondsElapsed / 1 days;

        return
            uint8(
                daysElapsed > totalVestingCount
                    ? totalVestingCount
                    : daysElapsed
            ) - note.vestingCount;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/utils/SafeERC20.sol)

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
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IBondDepository {
    event CreateMarket(
        uint256 indexed id,
        address indexed quoteToken,
        uint48 conclusion,
        bool capacityInQuote
    );
    event CloseMarket(uint256 indexed id);

    // Info about each type of market
    struct Market {
        uint256 capacity; // capacity remaining
        IERC20 quoteToken; // token to accept as payment
        bool capacityInQuote; // capacity limit is in payment token (true) or in OHM (false, default)
        uint256 totalDebt; // total debt from market
        uint256 maxPayout; // max tokens in/out (determined by capacityInQuote false/true, respectively)
        uint256 sold; // base tokens out
        uint256 purchased; // quote tokens in
    }

    // Info for creating new markets
    struct Terms {
        uint256 controlVariable; // scaling variable for price
        uint48 conclusion; // timestamp when market no longer offered (doubles as time when market matures if fixed-expiry)
        uint256 maxDebt; // 9 decimal debt maximum in OHM
    }

    // Additional info about market.
    struct Metadata {
        uint48 lastTune; // last timestamp when control variable was tuned
        uint48 lastDecay; // last timestamp when market was created and debt was decayed
        uint48 length; // time from creation to conclusion. used as speed to decay debt.
        uint48 depositInterval; // target frequency of deposits
        uint48 tuneInterval; // frequency of tuning
        uint8 quoteDecimals; // decimals of quote token
    }

    // Control variable adjustment data
    struct Adjustment {
        uint256 change;
        uint48 lastAdjustment;
        uint48 timeToAdjusted;
        bool active;
    }

    /**
     * @notice deposit market
     * @param _bid uint256
     * @param _amount uint256
     * @param _maxPrice uint256
     * @return payout_ uint256
     * @return index_ uint256
     */
    function deposit(
        uint256 _bid,
        uint256 _amount,
        uint256 _maxPrice
    ) external returns (uint256 payout_, uint256 index_);

    function create(
        IERC20 _quoteToken,
        uint256 _capacity,
        bool _capacityInQuote,
        uint256 _initialPrice,
        uint48 _conclusion,
        uint32 _depositInterval,
        uint32 _tuneInterval
    ) external returns (uint256 id_);

    function close(uint256 _id) external;

    function getMarketData(uint256 _id) external returns (uint256, uint256);
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.0;

interface INoteKeeper {
    // Info for market note
    struct Note {
        uint256 payout; // Total NEND to be paid
        uint256 payoutPerVesting; // Amount claimable every vesting
        uint48 created; // time note was created
        uint48 marketID; // market ID of deposit. uint48 to avoid adding a slot.
        uint8 vestingCount; // Number of times vested
    }

    event NoteCreated(
        address ownerAddress,
        uint48 marketId,
        uint256 noteId,
        uint256 amount,
        uint256 price,
        uint256 payout,
        uint256 payoutPerVesting,
        uint48 created
    );

    event NotesRedeemed(
        address ownerAddress,
        uint256[] indexes,
        uint8[] vestingCount,
        uint256[] totalVested
    );

    function redeem(uint256[] memory _indexes)
        external
        returns (uint256);

    function redeemAll() external returns (uint256);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "../../bridge/NENDBridge.sol";
import "./NENDAirdrop.sol";
import "./NENDCrowdSale.sol";
import "./NENDCrossChainSupply.sol";
import "../../inflation/Inflation.sol";

contract NEND is NENDAirdrop, NENDCrowdSale, NENDBridge, NENDCrossChainSupply {
    uint256 public ecosystemFund;
    uint256 public liquidity;
    uint256 public marketing;
    uint256 public team;
    uint256 public advisor;
    bool public isMintChain;
    mapping(address => bool) authorizedMinters;

    function authorizeMinter(address _minter, bool _authorized)
        external
        onlyOwner
    {
        authorizedMinters[_minter] = _authorized;
    }

    function mint(address _receiver, uint256 _amount) external {
        require(authorizedMinters[msg.sender], "Not authorized");
        _mint(_receiver, _amount);
    }

    constructor(
        bool _isMainChain,
        uint256[] memory _chains,
        uint256 _inflationAmount
    ) ERC20("NEND", "N") NENDBridge(_chains) Inflation(_inflationAmount) {
        authorizedMinters[msg.sender] = true;
        isMintChain = _isMainChain;
        if (isMintChain) {
            ecosystemFund = 25000000 ether;
            liquidity = 10000000 ether;
            airdrop = 5000000 ether;
            marketing = 5000000 ether;
            team = 10000000 ether;
            advisor = 5000000 ether;
            sale = 10000000 ether;
            _mint(
                address(this),
                ecosystemFund +
                    liquidity +
                    airdrop +
                    marketing +
                    team +
                    advisor +
                    sale
            );
        }
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

abstract contract NENDBridge is ERC20, Ownable {
    event EnterBridge(
        uint48 enteredAt,
        uint256 targetChainId,
        address sender,
        address receiver,
        uint256 amount,
        uint256 nonce
    );

    modifier validDestinationChain(uint256 chainId) {
        require(
            _isChainSupported(chainId) && block.chainid != chainId,
            "Invalid destination chain"
        );
        _;
    }

    mapping(uint256 => mapping(uint256 => bool))
        private chainNonceToExecutedMapping;
    uint256 private nonce;

    uint256[] public supportedChainIds;

    constructor(uint256[] memory _supportedChainIds) {
        require(
            _supportedChainIds.length > 1,
            "Must have at least two destination chains"
        );
        supportedChainIds = _supportedChainIds;
        require(
            _isChainSupported(block.chainid),
            "The hosted chain must be one of the supported chains"
        );
    }

    function enterBridge(
        uint256 _targetChainId,
        address _receiver,
        uint256 _amount
    ) external validDestinationChain(_targetChainId) {
        require(_amount > 0, "Invalid amount");
        require(balanceOf(msg.sender) > _amount, "Insufficient balance");

        _burn(msg.sender, _amount);

        emit EnterBridge(
            uint48(block.timestamp),
            _targetChainId,
            msg.sender,
            _receiver,
            _amount,
            nonce++
        );
    }

    function leaveBridge(
        uint256 _sourceChainId,
        address _receiver,
        uint256 _amount,
        uint256 _nonce
    ) external onlyOwner {
        // Duplicate request, already left bridge
        if (chainNonceToExecutedMapping[_sourceChainId][_nonce]) {
            return;
        }
        chainNonceToExecutedMapping[_sourceChainId][_nonce] = true;

        _mint(_receiver, _amount);
    }

    function _isChainSupported(uint256 chainId) internal view returns (bool) {
        for (uint256 i = 0; i < supportedChainIds.length; i++) {
            if (supportedChainIds[i] == chainId) {
                return true;
            }
        }

        return false;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

abstract contract NENDAirdrop is ERC20 {

    uint airdrop;

    event AirdropCreated(address indexed addresses, uint256 amount);

    function createAirdrop(
        address _receiver,
        uint256 _amount // onlyOwner
    ) external {
        require(airdrop >= _amount, "Not enough airdrop funds");

        airdrop -= _amount;

        _transfer(address(this), _receiver, _amount);
        emit AirdropCreated(_receiver, _amount);
    }

    function createAirdropBatch(address[] memory _receivers, uint256 _amount)
        external
    // onlyOwner
    {
        require(
            airdrop > _receivers.length * _amount,
            "Not enough airdrop funds"
        );

        airdrop -= _receivers.length * _amount;

        for (uint256 i = 0; i < _receivers.length; i++) {
            _transfer(address(this), _receivers[i], _amount);
            emit AirdropCreated(_receivers[i], _amount);
        }
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

abstract contract NENDCrowdSale is ERC20 {

    event SaleCreated(address indexed buyer, uint256 amount);

    uint256 public constant tokenExchangeRate = 5000; // 5000 NEND tokens per 1 ETH
    uint256 public sale;
    bool public onSale;

    function startSale() external // onlyOwner
    {
        require(!onSale, "Already on sale");
        require(sale > 0, "Not enough sale funds");
        onSale = true;
    }

    function endSale() external // onlyOwner
    {
        require(onSale, "Sale not started");
        onSale = false;
    }

    function buyNEND() external payable {
        require(onSale, "Not on sale");

        uint256 nendsBought = msg.value * tokenExchangeRate;

        require(sale >= nendsBought, "Not enough sale funds");

        sale -= nendsBought;

        _transfer(address(this), msg.sender, nendsBought);

        emit SaleCreated(msg.sender, nendsBought);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "../../inflation/Inflation.sol";

abstract contract NENDCrossChainSupply is Inflation {
    uint256 public crossChainSupply;
    uint256 public crossChainInflationAmount;

    function update(
        uint256 _crossChainSupply,
        uint256 _crossChainInflationAmount
    ) external onlyOwner {
        crossChainSupply = _crossChainSupply;
        crossChainInflationAmount = _crossChainInflationAmount;
    }

    function currentSupply() external view returns (uint256) {
        if (lastInflation == 0) {
            return crossChainSupply;
        }

        uint256 timeElapsed = block.timestamp - lastInflation;
        uint256 elapsedPct = (timeElapsed * 10000) / 1 weeks;
        if (elapsedPct > 10000) {
            elapsedPct = 10000;
        }

        return
            crossChainSupply + (crossChainInflationAmount * elapsedPct) / 10000;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "../staking/IStaking.sol";
import "../vault/Vault.sol";

abstract contract Inflation is ERC20, Ownable {
    IStaking public staking;

    // The number of inflations carried out
    uint256 public inflationCount;

    // The time of last inflation
    uint48 public lastInflation;

    // The inflation amount
    uint256 public inflationAmount;

    // Decay rate * 10000
    uint256 public immutable inflationDecay = 125; // 1.25%

    constructor(uint256 _inflationAmount) {
        inflationAmount = _inflationAmount;
    }

    function setStaking(address _staking) external onlyOwner {
        staking = IStaking(_staking);
    }

    function startEpoch() external onlyOwner {
        require(address(staking) != address(0), "Staking not set");
        require(inflationCount < 208, "Maximum epoch");
        require(
            block.timestamp >= lastInflation + 1 weeks,
            "Last epoch not ended"
        );

        inflationCount++;
        lastInflation = uint48(block.timestamp);

        if (inflationCount > 52) {
            inflationAmount -= (inflationAmount * inflationDecay) / 10000;
        }

        _mint(address(staking), inflationAmount);

        staking.distributeRewards();
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/ERC20.sol)

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
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
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
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
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
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
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
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `from` to `to`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     */
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
        }
        _balances[to] += amount;

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
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
     * @dev Updates `owner` s allowance for `spender` based on spent `amount`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
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

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

interface IStaking {
    event Staked(
        uint256 id,
        address indexed staker,
        address indexed stakeToken,
        uint48 start,
        uint48 end,
        uint256 amountStaked,
        uint256 rewardAllocation,
        bool eabBound
    );
    event RewardsClaimed(
        uint256[] stakeIds,
        uint256[] claimedStakeToken,
        uint256[] claimedNend
    );
    event Unstaked(uint256 id);
    event EABIssued(uint256 escrowId);
    event Escrowed(
        uint256 parentStakeId,
        uint256 childStakeId,
        uint256 escrowId,
        uint256 amount,
        uint48 claimAfter,
        address owner
    );
    event EABExchanged(uint256 escrowId);
    event EscrowOwnerChanged(
        uint256 escrowId,
        address previousOwner,
        address newOnwer,
        uint256 newChildStakeId
    );
    event EscrowCanceled(uint escrowId);

    struct Stake {
        // Staker address
        address staker;
        // Stake token address
        address stakeToken;
        // The time of deposit
        uint48 start;
        // The time of withdrawal
        uint48 end;
        // The staked amount
        uint256 amountStaked;
        // The claimed amount in stake token
        uint256 claimedStakeToken;
        // The claimed amount in Nend
        uint256 claimedNend;
        // The portion of rewards allocated to this stake
        uint256 rewardAllocation;
        // Stake is bound to eab, can not be withdrawn
        bool eabBound;
        // Stake was withdrawn
        bool unstaked;
    }

    struct Escrow {
        // Stake id that created this eab
        uint256 parentStakeId;
        // Stake id that was created by this eab
        uint256 childStakeId;
        // The amount of NEND to be claimed
        uint256 amount;
        // The time after which the escrow can be exchanged for NEND
        uint48 claimAfter;
        // Owner of escrow
        address owner;
        // EAB nft issued
        bool eabIssued;
        // Reward claimed
        bool claimed;
        // Unstaked early, escrow canceled
        bool canceled;
    }

    function deposit(
        address _stakeToken,
        uint256 _amount,
        uint8 _durationId
    ) external payable;

    function distributeRewards() external;

    function exchangeEAB(uint256 _escrowId) external;

    function unstake(uint256 _stakeId) external;

    function getStakeTokens()
        external
        view
        returns (address[] memory _stakeTokens);

    function autoUnstake() external;

    function addStakeToken(address _stakeToken) external;

    function removeStakeToken(address _stakeToken) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

contract Vault is Ownable {
    bytes4 private ERC1155_INTERFACE_ID = 0xd9b67a26;
    string public name;

    mapping(address => bool) public authorizedOperators;
    mapping(address => bool) public authorizedSpenders;
    // Balance name => token => amount
    mapping(string => mapping(address => uint256)) public namedBalances;

    constructor(string memory _name) {
        name = _name;
    }

    function authorizeOperator(address operator, bool authorized)
        external
        onlyOperator
    {
        authorizedOperators[operator] = authorized;
    }

    modifier onlyOperator() {
        require(
            msg.sender == owner() || authorizedOperators[msg.sender],
            "Not authorized"
        );
        _;
    }

    function authorizeSpender(address spender, bool authorized)
        external
        onlyOperator
    {
        authorizedSpenders[spender] = authorized;
    }

    modifier onlySpender() {
        require(
            msg.sender == owner() || authorizedSpenders[msg.sender],
            "Not authorized"
        );
        _;
    }

    modifier onlyOperatorOrSpender() {
        require(
            msg.sender == owner() ||
                authorizedOperators[msg.sender] ||
                authorizedSpenders[msg.sender],
            "Not authorized"
        );
        _;
    }

    function approveERC20Transfer(
        address _tokenAddress,
        address _spender,
        uint256 _amount
    ) external onlySpender returns (bool) {
        IERC20 erc20 = IERC20(_tokenAddress);
        return erc20.approve(_spender, _amount);
    }

    function transferERC20(
        address _tokenAddress,
        address _to,
        uint256 _amount
    ) external onlySpender returns (bool) {
        IERC20 erc20 = IERC20(_tokenAddress);
        return erc20.transfer(_to, _amount);
    }

    function setERC721ApprovalForAll(
        address _tokenAddress,
        address _operator,
        bool _approved
    ) external onlySpender {
        IERC721 erc721 = IERC721(_tokenAddress);
        erc721.setApprovalForAll(_operator, _approved);
    }

    function transferERC721(
        address _tokenAddress,
        address _to,
        uint256 _tokenId
    ) external onlySpender {
        IERC721 erc721 = IERC721(_tokenAddress);
        erc721.transferFrom(address(this), _to, _tokenId);
    }

    function transferERC1155(
        address _tokenAddress,
        address _to,
        uint256 _id,
        uint256 _value,
        bytes calldata _data
    ) external onlySpender {
        IERC1155 erc1155 = IERC1155(_tokenAddress);
        require(
            erc1155.supportsInterface(ERC1155_INTERFACE_ID),
            "given token address doesn't support ERC1155"
        );
        erc1155.safeTransferFrom(address(this), _to, _id, _value, _data);
    }

    function transferERC1155Batch(
        address _tokenAddress,
        address _to,
        uint256[] calldata _ids,
        uint256[] calldata _values,
        bytes calldata _data
    ) external onlySpender {
        IERC1155 erc1155 = IERC1155(_tokenAddress);
        require(
            erc1155.supportsInterface(ERC1155_INTERFACE_ID),
            "given token address doesn't support ERC1155"
        );
        erc1155.safeBatchTransferFrom(address(this), _to, _ids, _values, _data);
    }

    function setERC1155ApprovalForAll(
        address _tokenAddress,
        address _operator,
        bool _approved
    ) external onlySpender {
        IERC1155 erc1155 = IERC1155(_tokenAddress);
        require(
            erc1155.supportsInterface(ERC1155_INTERFACE_ID),
            "given token address doesn't support ERC1155"
        );
        erc1155.setApprovalForAll(_operator, _approved);
    }

    function getNativeBalance() external view returns (uint256) {
        return address(this).balance;
    }

    function transferNative(address payable _to, uint256 _amount)
        public
        payable
        onlySpender
    {
        (bool sent, ) = _to.call{ value: _amount }("");
        require(sent, "Failed to send Ether");
    }

    function namedBalanceReceive(
        string memory _name,
        address _token,
        uint256 _amount
    ) external onlySpender {
        namedBalances[_name][_token] += _amount;
    }

    function namedBalanceSpend(
        string memory _name,
        address _token,
        uint256 _amount
    ) external onlySpender {
        require(
            namedBalances[_name][_token] >= _amount,
            "Insufficient balance"
        );
        namedBalances[_name][_token] -= _amount;
    }

    function getNamedBalance(string memory _name, address _token)
        external
        view
        returns (uint256)
    {
        return namedBalances[_name][_token];
    }

    receive() external payable {}

    fallback() external payable {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/ERC721.sol)

pragma solidity ^0.8.0;

import "./IERC721.sol";
import "./IERC721Receiver.sol";
import "./extensions/IERC721Metadata.sol";
import "../../utils/Address.sol";
import "../../utils/Context.sol";
import "../../utils/Strings.sol";
import "../../utils/introspection/ERC165.sol";

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract ERC721 is Context, ERC165, IERC721, IERC721Metadata {
    using Address for address;
    using Strings for uint256;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to owner address
    mapping(uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping(address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: address zero is not a valid owner");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: invalid token ID");
        return owner;
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        _requireMinted(tokenId);

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overridden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not token owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        _requireMinted(tokenId);

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner nor approved");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner nor approved");
        _safeTransfer(from, to, tokenId, data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner || isApprovedForAll(owner, spender) || getApproved(tokenId) == spender);
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);

        _afterTokenTransfer(address(0), to, tokenId);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        _balances[owner] -= 1;
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);

        _afterTokenTransfer(owner, address(0), tokenId);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer from incorrect owner");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);

        _afterTokenTransfer(from, to, tokenId);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits an {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits an {ApprovalForAll} event.
     */
    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, "ERC721: approve to caller");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Reverts if the `tokenId` has not been minted yet.
     */
    function _requireMinted(uint256 tokenId) internal view virtual {
        require(_exists(tokenId), "ERC721: invalid token ID");
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    /// @solidity memory-safe-assembly
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/extensions/ERC721URIStorage.sol)

pragma solidity ^0.8.0;

import "../ERC721.sol";

/**
 * @dev ERC721 token with storage based token URI management.
 */
abstract contract ERC721URIStorage is ERC721 {
    using Strings for uint256;

    // Optional mapping for token URIs
    mapping(uint256 => string) private _tokenURIs;

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        _requireMinted(tokenId);

        string memory _tokenURI = _tokenURIs[tokenId];
        string memory base = _baseURI();

        // If there is no base URI, return the token URI.
        if (bytes(base).length == 0) {
            return _tokenURI;
        }
        // If both are set, concatenate the baseURI and tokenURI (via abi.encodePacked).
        if (bytes(_tokenURI).length > 0) {
            return string(abi.encodePacked(base, _tokenURI));
        }

        return super.tokenURI(tokenId);
    }

    /**
     * @dev Sets `_tokenURI` as the tokenURI of `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _setTokenURI(uint256 tokenId, string memory _tokenURI) internal virtual {
        require(_exists(tokenId), "ERC721URIStorage: URI set of nonexistent token");
        _tokenURIs[tokenId] = _tokenURI;
    }

    /**
     * @dev See {ERC721-_burn}. This override additionally checks to see if a
     * token-specific URI was set for the token, and if so, it deletes the token URI from
     * the storage mapping.
     */
    function _burn(uint256 tokenId) internal virtual override {
        super._burn(tokenId);

        if (bytes(_tokenURIs[tokenId]).length != 0) {
            delete _tokenURIs[tokenId];
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

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
abstract contract ReentrancyGuard {
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

    constructor() {
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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {
    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

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
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165 {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
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