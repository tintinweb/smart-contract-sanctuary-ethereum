// SPDX-License-Identifier: AGPL-3.0
pragma solidity >=0.7.5;

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity >=0.7.5;

import "./IERC20.sol";

interface IERC20Metadata is IERC20 {
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity >=0.7.5;

interface IOlympusAuthority {
    /* ========== EVENTS ========== */

    event GovernorPushed(address indexed from, address indexed to, bool _effectiveImmediately);
    event GuardianPushed(address indexed from, address indexed to, bool _effectiveImmediately);
    event PolicyPushed(address indexed from, address indexed to, bool _effectiveImmediately);
    event VaultPushed(address indexed from, address indexed to, bool _effectiveImmediately);

    event GovernorPulled(address indexed from, address indexed to);
    event GuardianPulled(address indexed from, address indexed to);
    event PolicyPulled(address indexed from, address indexed to);
    event VaultPulled(address indexed from, address indexed to);

    /* ========== VIEW ========== */

    function governor() external view returns (address);

    function guardian() external view returns (address);

    function policy() external view returns (address);

    function vault() external view returns (address);
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.7.5;

import {IERC20} from "../interfaces/IERC20.sol";

/// @notice Safe IERC20 and ETH transfer library that safely handles missing return values.
/// @author Modified from Uniswap (https://github.com/Uniswap/uniswap-v3-periphery/blob/main/contracts/libraries/TransferHelper.sol)
/// Taken from Solmate
library SafeERC20 {
    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 amount
    ) internal {
        (bool success, bytes memory data) = address(token).call(
            abi.encodeWithSelector(IERC20.transferFrom.selector, from, to, amount)
        );

        require(success && (data.length == 0 || abi.decode(data, (bool))), "TRANSFER_FROM_FAILED");
    }

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 amount
    ) internal {
        (bool success, bytes memory data) = address(token).call(
            abi.encodeWithSelector(IERC20.transfer.selector, to, amount)
        );

        require(success && (data.length == 0 || abi.decode(data, (bool))), "TRANSFER_FAILED");
    }

    function safeApprove(
        IERC20 token,
        address to,
        uint256 amount
    ) internal {
        (bool success, bytes memory data) = address(token).call(
            abi.encodeWithSelector(IERC20.approve.selector, to, amount)
        );

        require(success && (data.length == 0 || abi.decode(data, (bool))), "APPROVE_FAILED");
    }

    function safeTransferETH(address to, uint256 amount) internal {
        (bool success, ) = to.call{value: amount}(new bytes(0));

        require(success, "ETH_TRANSFER_FAILED");
    }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.10;

import "./types/MarketCreator.sol";
import "./types/NoteKeeper.sol";
import "./types/Rewarder.sol";
import "./types/Viewer.sol";

import "../libraries/SafeERC20.sol";

import "../interfaces/IERC20Metadata.sol";
import "./interfaces/IOlympusPro.sol";
import "./interfaces/IProCall.sol";

/// @title Olympus Pro Depository V2
/// @author Zeus, Indigo
/// Review by: JeffX

contract TestnetOPBondDepo is ProMarketCreator, ProViewer, ProNoteKeeper, ProRewarder {
    using SafeERC20 for IERC20;

    event Bond(uint256 indexed id, uint256 amount, uint256 price);
    event Tuned(uint256 indexed id, uint256 oldControlVariable, uint256 newControlVariable);

    constructor(address _authority)
        ProMarketCreator()
        ProViewer()
        ProNoteKeeper()
        ProRewarder(IOlympusAuthority(_authority))
    {}

    /* ========== EXTERNAL ========== */

    /**
     * @notice             deposit quote tokens in exchange for a bond in a specified market
     * @param _amounts     [amount in, min amount out]
     * @param _addresses   [recipient, referrer]
     */
    function deposit(
        uint48 _id,
        uint256[2] memory _amounts,
        address[2] memory _addresses
    )
        external
        returns (
            uint256 payout_,
            uint256 expiry_,
            uint256 index_
        )
    {
        Market storage market = markets[_id];
        Terms memory term = terms[_id];
        uint48 currentTime = uint48(block.timestamp);
        address sendTo; // receives base tokens at time of deposit
        uint256 price = _decayAndGetPrice(_id, currentTime); // Debt and the control variable decay over time

        // Markets end at a defined timestamp
        require(currentTime < term.conclusion, "Depository: market concluded");

        /**
         * payout for the deposit = amount / price
         *
         * where
         * payout = base tokens out
         * amount = quote tokens in
         * price = quote tokens : base token (i.e. 200 QUOTE : BASE)
         */
        payout_ = (_amounts[0] * (10**(2 * metadata[_id].baseDecimals))) / price / (10**metadata[_id].quoteDecimals);

        // markets have a max payout amount, capping size because deposits
        // do not experience slippage. max payout is recalculated upon tuning
        require(payout_ <= market.maxPayout, "Depository: max size exceeded");

        // payout must be greater than user inputted minimum
        require(payout_ >= _amounts[1], "Depository: Less than min out");

        // if there is no vesting time, the deposit is treated as an instant swap.
        // in this case, the recipient (_address[0]) receives the payout immediately.
        // otherwise, deposit info is stored and payout is available at a future timestamp.
        if ((term.fixedTerm && term.vesting == 0) || (!term.fixedTerm && term.vesting <= block.timestamp)) {
            // instant swap case
            sendTo = _addresses[0];

            // Note zero expiry denotes an instant swap in return values
            expiry_ = 0;
        } else {
            // vested swap case
            sendTo = address(vestingContract);

            // we have to store info about their deposit

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
            expiry_ = term.fixedTerm ? term.vesting + currentTime : term.vesting;

            // the index of the note is the next in the user's array
            index_ = notes[_addresses[0]].length;

            /**
             * user data is stored as Notes. these are isolated array entries
             * storing the amount due, the time created, the time when payout
             * is redeemable, the time when payout was redeemed, the ID
             * of the market deposited into, and the payout (quote) token.
             */
            notes[_addresses[0]].push(
                Note({
                    payout: payout_,
                    created: uint48(block.timestamp),
                    matured: uint48(expiry_),
                    redeemed: 0,
                    marketID: uint48(_id),
                    token: address(market.baseToken)
                })
            );
        }

        /*
         * capacity is either the number of base tokens that the market can sell
         * (if capacity in quote is false),
         *
         * or the number of quote tokens that the market can buy
         * (if capacity in quote is true)
         */

        // capacity is decreased by the deposited or paid amount
        market.capacity -= market.capacityInQuote ? _amounts[0] : payout_;

        // markets keep track of how many quote tokens have been
        // purchased, and how many base tokens have been sold
        market.purchased += _amounts[0];
        market.sold += payout_;

        // incrementing total debt raises the price of the next bond
        market.totalDebt += payout_;

        emit Bond(_id, _amounts[0], price);

        // if max debt is breached, the market is closed
        // this a circuit breaker
        if (term.maxDebt < market.totalDebt) {
            market.capacity = 0;
            emit CloseMarket(_id);
        } else {
            // if market will continue, the control variable is tuned to hit targets on time
            _tune(_id, currentTime, price); // TODO
        }

        // give fees, and transfer in base tokens from creator
        _getBaseTokens(market.call, _id, _amounts[0], payout_, _addresses[1]);

        // if instant swap, send payout to recipient. otherwise, sent to vesting
        markets[_id].baseToken.safeTransfer(sendTo, payout_);

        // transfer payment to creator
        markets[_id].quoteToken.safeTransferFrom(msg.sender, markets[_id].creator, _amounts[0]);
    }

    /* ========== INTERNAL ========== */

    /**
     * @notice             calculate current market price of base token in quote tokens
     * @dev                see marketPrice() for explanation of price computation
     * @dev                uses info from storage because data has been updated before call (vs marketPrice())
     * @param _id          market ID
     * @return             price for market in base token decimals
     */
    function _marketPrice(uint256 _id) internal view returns (uint256) {
        return (terms[_id].controlVariable * markets[_id].totalDebt) / 10**metadata[_id].baseDecimals;
    }

    /**
     * @notice             decay debt, and adjust control variable if there is an active change
     * @param _id          ID of market
     * @param _time        uint48 timestamp (saves gas when passed in)
     */
    function _decayAndGetPrice(uint256 _id, uint48 _time) internal returns (uint256 marketPrice_) {
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

            (uint256 adjustBy, uint48 secondsSince, bool stillActive) = _controlDecay(_id); // implementation in ProViewer
            terms[_id].controlVariable -= adjustBy;

            if (stillActive) {
                adjustment.change -= uint128(adjustBy);
                adjustment.timeToAdjusted -= secondsSince;
                adjustment.lastAdjustment = _time;
            } else {
                adjustment.active = false;
            }
        }

        // a minimum price is maintained by raising debt back up if price has fallen below.
        marketPrice_ = _marketPrice(_id);
        uint256 minPrice = markets[_id].minPrice;
        if (marketPrice_ < minPrice) {
            markets[_id].totalDebt = (markets[_id].totalDebt * minPrice) / marketPrice_;
            marketPrice_ = minPrice;
        }
    }

    /**
     * @notice             auto-adjust control variable to hit capacity/spend target
     * @param _id          ID of market
     * @param _time        uint48 timestamp (saves gas when passed in)
     */
    function _tune(
        uint256 _id,
        uint48 _time,
        uint256 _price
    ) internal {
        Metadata memory meta = metadata[_id];

        if (_time >= meta.lastTune + meta.tuneInterval) {
            Market memory market = markets[_id];

            // compute seconds remaining until market will conclude
            uint256 timeRemaining = terms[_id].conclusion - _time;

            // standardize capacity into an base token amount
            uint256 capacity = market.capacityInQuote
                ? ((market.capacity * (10**(2 * meta.baseDecimals))) / _price) / (10**meta.quoteDecimals)
                : market.capacity;

            /**
             * calculate the correct payout to complete on time assuming each bond
             * will be max size in the desired deposit interval for the remaining time
             *
             * i.e. market has 10 days remaining. deposit interval is 1 day. capacity
             * is 10,000 TOKEN. max payout would be 1,000 TOKEN (10,000 * 1 / 10).
             */
            markets[_id].maxPayout = (capacity * meta.depositInterval) / timeRemaining;

            // calculate the ideal total debt to satisfy capacity in the remaining time
            uint256 targetDebt = (capacity * meta.length) / timeRemaining;

            // derive a new control variable from the target deb
            uint256 newControlVariable = (_price * (10**meta.baseDecimals)) / targetDebt;

            emit Tuned(_id, terms[_id].controlVariable, newControlVariable);

            if (newControlVariable >= terms[_id].controlVariable) {
                terms[_id].controlVariable = newControlVariable;
            } else {
                // if decrease, control variable change will be carried out over the tune interval
                // this is because price will be lowered
                uint256 change = terms[_id].controlVariable - newControlVariable;
                adjustments[_id] = Adjustment(uint128(change), _time, meta.tuneInterval, true);
            }
            metadata[_id].lastTune = _time;
        }
    }

    function _getBaseTokens(
        bool _call,
        uint48 _id,
        uint256 _amount,
        uint256 _payout,
        address _referrer
    ) internal {
        IERC20 baseToken = markets[_id].baseToken;

        /**
         * front end operators can earn rewards by referring users
         * transfers in reward amount to this contract (must be separate
         * transfer because payout may be sent directly to _address[0])
         */
        uint256 fee = _giveRewards(baseToken, _payout, _referrer);

        /**
         * instead of basic transferFrom, creator can be called. useful if creator
         * i.e. mints the tokens, or wants custom logic blocking transactions.
         * the balance of the correct recipient must be increased by the payout amount.
         * note that call could reenter, so this is done second to last, followed only by paying creator.
         */
        if (_call) {
            uint256 balance = baseToken.balanceOf(address(this));
            IProCall(markets[_id].creator).call(_id, _amount, _payout + fee);
            require(baseToken.balanceOf(address(this)) >= balance + _payout + fee, "Depository: not funded");

            // default is to simply transfer tokens in. make sure creator has approved this address.
        } else baseToken.safeTransferFrom(markets[_id].creator, address(this), _payout + fee);
    }

    /**
     * @notice             amount of debt to decay from total debt for market ID
     * @param _id          ID of market
     * @return             amount of debt to decay
     */
    function _debtDecay(uint256 _id) internal view returns (uint256) {
        Metadata memory meta = metadata[_id];

        uint256 secondsSince = block.timestamp - meta.lastDecay;

        return (markets[_id].totalDebt * secondsSince) / meta.length;
    }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.10;

import "./IProMarketCreator.sol";
import "./IProNoteKeeper.sol";
import "./IProViewer.sol";

interface IOlympusPro is IProMarketCreator, IProNoteKeeper, IProViewer {
    /**
     * @notice deposit quote tokens in exchange for a bond in a specified market
     */
    function deposit(
        uint48 _id,
        uint256[2] memory _amounts,
        address[2] memory _addresses
    )
        external
        returns (
            uint256 payout_,
            uint256 expiry_,
            uint256 index_
        );
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.10;

interface IProCall {
    function call(
        uint256 id,
        uint256 amountIn,
        uint256 amountOut
    ) external;
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.10;

import "../../interfaces/IERC20.sol";

interface IProMarketCreator {
    // Info about each type of market
    struct Market {
        address creator; // market creator. sends base tokens, receives quote tokens
        IERC20 baseToken; // token to pay depositors with
        IERC20 quoteToken; // token to accept as payment
        bool call; // perform custom call for payout
        bool capacityInQuote; // capacity limit is in payment token (true) or in OHM (false, default)
        uint256 capacity; // capacity remaining
        uint256 totalDebt; // total base token debt from market
        uint256 minPrice; // minimum price (debt will stop decaying to maintain this)
        uint256 maxPayout; // max base tokens out in one order
        uint256 sold; // base tokens out
        uint256 purchased; // quote tokens in
    }

    // Info for creating new markets
    struct Terms {
        uint256 controlVariable; // scaling variable for price
        uint256 maxDebt; // max base token debt accrued
        bool fixedTerm; // fixed term or fixed expiration
        uint48 vesting; // length of time from deposit to maturity if fixed-term
        uint48 conclusion; // timestamp when market no longer offered (doubles as time when market matures if fixed-expiry)
    }

    // Additional info about market.
    struct Metadata {
        uint48 lastTune; // last timestamp when control variable was tuned
        uint48 lastDecay; // last timestamp when market was created and debt was decayed
        uint48 length; // time from creation to conclusion. used as speed to decay debt.
        uint48 depositInterval; // target frequency of deposits
        uint48 tuneInterval; // frequency of tuning
        uint8 baseDecimals; // decimals of base token
        uint8 quoteDecimals; // decimals of quote token
    }

    // Control variable adjustment data
    struct Adjustment {
        uint128 change;
        uint48 lastAdjustment;
        uint48 timeToAdjusted;
        bool active;
    }

    function create(
        IERC20[2] memory _tokens, // [base token, quote token]
        uint256[4] memory _market, // [capacity, initial price, minimum price, debt buffer]
        bool[2] memory _booleans, // [capacity in quote, fixed term]
        uint256[2] memory _terms, // [vesting, conclusion]
        uint32[2] memory _intervals // [deposit interval, tune interval]
    ) external returns (uint256 id_);

    function close(uint256 _id) external;
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.10;

import "../../interfaces/IERC20.sol";

interface IProNoteKeeper {
    // Info for market note
    struct Note {
        uint256 payout; // gOHM remaining to be paid
        uint48 created; // time market was created
        uint48 matured; // timestamp when market is matured
        uint48 redeemed; // time market was redeemed
        uint48 marketID; // market ID of deposit. uint48 to avoid adding a slot.
        address token; // token to be paid.
    }

    function redeem(address _user, uint256[] memory _indexes) external;

    function redeemAll(address _user) external;

    function pushNote(address to, uint256 index) external;

    function pullNote(address from, uint256 index) external returns (uint256 newIndex_);

    function indexesFor(address _user) external view returns (uint256[] memory);

    function pendingFor(address _user, uint256 _index) external view returns (uint256 payout_, bool matured_);
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.10;

interface IProViewer {
    function isLive(uint256 _bid) external view returns (bool);

    function liveMarkets() external view returns (uint256[] memory);

    function liveMarketsFor(
        bool _creator,
        bool _base,
        address _address
    ) external view returns (uint256[] memory);

    function payoutFor(uint256 _amount, uint256 _bid) external view returns (uint256);

    function marketPrice(uint256 _bid) external view returns (uint256);

    function currentDebt(uint256 _bid) external view returns (uint256);
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.10;

import "../../interfaces/IERC20Metadata.sol";
import "../interfaces/IProMarketCreator.sol";

abstract contract ProMarketCreator is IProMarketCreator {

/* ========== EVENTS ========== */

  event CreateMarket(uint256 indexed id, address baseToken, address quoteToken, uint256 initialPrice, uint256 conclusion);
  event CloseMarket(uint256 indexed id);

/* ========== STATE VARIABLES ========== */

  // Markets
  Market[] public markets; // persistent market data
  Terms[] public terms; // deposit construction data
  Metadata[] public metadata; // extraneous market data
  mapping(uint256 => Adjustment) public adjustments; // control variable changes

  // Queries
  mapping(address => uint256[]) public marketsForBase; // market IDs for base token
  mapping(address => uint256[]) public marketsForQuote; // market IDs for quote token
  mapping(address => uint256[]) public marketsForCreator; // market IDs for market creator

/* ========== CREATE ========== */

  /**
   * @notice             creates a new market type
   * @dev                current price should be in base token decimals.
   * @param _tokens      [base token for payout, quote token used to deposit]
   * @param _market      [capacity (in base or quote), initial price / base, minimum price, debt buffer (3 decimals)]
   * @param _booleans    [capacity in quote, fixed term, call]
   * @param _terms       [vesting length (if fixed term) or vested timestamp, conclusion timestamp]
   * @param _intervals   [deposit interval (seconds), tune interval (seconds)]
   * @return id_         ID of new bond market
   */
  function create(
    IERC20[2] memory _tokens,
    uint256[4] memory _market,
    bool[2] memory _booleans,
    uint256[2] memory _terms,
    uint32[2] memory _intervals
  ) external override returns (uint256 id_) {
    require(_market[1] >= _market[2], "Creator: min price must be > initial");

    // depositing into, or getting info for, the created market uses this ID
    id_ = markets.length;

    marketsForBase[address(_tokens[0])].push(id_);
    marketsForQuote[address(_tokens[1])].push(id_);
    marketsForCreator[msg.sender].push(id_);

    emit CreateMarket(id_, address(_tokens[0]), address(_tokens[1]), _market[1], _terms[1]);

    // the length of the program, in seconds
    uint256 secondsToConclusion = _terms[1] - block.timestamp;

    // the decimal count of the base and quote token
    uint256 baseDecimals = IERC20Metadata(address(_tokens[0])).decimals();
    uint256 quoteDecimals = IERC20Metadata(address(_tokens[1])).decimals();

    metadata.push(Metadata({
      lastTune: uint48(block.timestamp),
      lastDecay: uint48(block.timestamp),
      length: uint48(secondsToConclusion),
      depositInterval: _intervals[0],
      tuneInterval: _intervals[1],
      baseDecimals: uint8(baseDecimals),
      quoteDecimals: uint8(quoteDecimals)
    }));

    /* 
     * initial target debt is equal to capacity (this is the amount of debt
     * that will decay over in the length of the program if price remains the same).
     * it is converted into base token terms if passed in in quote token terms.
     */
    uint256 targetDebt = _booleans[0]
      ? (_market[0] * (10 ** (2 * baseDecimals)) / _market[1]) / 10 ** quoteDecimals
      : _market[0];

    /*
     * max payout is the amount of capacity that should be utilized in a deposit
     * interval. for example, if capacity is 1,000 TOKEN, there are 10 days to conclusion, 
     * and the preferred deposit interval is 1 day, max payout would be 100 TOKEN.
     */
    uint256 maxPayout = targetDebt * _intervals[0] / secondsToConclusion;

    markets.push(Market({
      creator: msg.sender,
      baseToken: _tokens[0],
      quoteToken: _tokens[1],
      call: false,
      capacityInQuote: _booleans[0],
      capacity: _market[0],
      totalDebt: targetDebt, 
      minPrice: _market[2],
      maxPayout: maxPayout,
      purchased: 0,
      sold: 0
    }));

    /*
     * max debt serves as a circuit breaker for the market. let's say the quote
     * token is a stablecoin, and that stablecoin depegs. without max debt, the
     * market would continue to buy until it runs out of capacity. this is
     * configurable with a 3 decimal buffer (1000 = 1% above initial price).
     * note that its likely advisable to keep this buffer wide.
     * note that the buffer is above 100%. i.e. 10% buffer = initial debt * 1.1
     */
    uint256 maxDebt = targetDebt + (targetDebt * _market[3] / 1e5); // 1e5 = 100,000. 10,000 / 100,000 = 10%.

    /*
     * the control variable is set so that initial price equals the desired
     * initial price. the control variable is the ultimate determinant of price,
     * so we compute this last.
     *
     * price = control variable * debt ratio
     * debt ratio = total debt / supply
     * therefore, control variable = price / debt ratio
     */
    uint256 controlVariable = _market[1] * (10 ** baseDecimals) / targetDebt;

    terms.push(Terms({
      fixedTerm: _booleans[1], 
      controlVariable: controlVariable,
      vesting: uint48(_terms[0]), 
      conclusion: uint48(_terms[1]), 
      maxDebt: maxDebt
    }));
  }

/* ========== CLOSE ========== */

  /**
   * @notice             disable existing market
   * @notice             must be creator
   * @param _id          ID of market to close
   */
  function close(uint256 _id) external override {
    require(msg.sender == markets[_id].creator, "Only creator");
    terms[_id].conclusion = uint48(block.timestamp);
    markets[_id].capacity = 0;
    emit CloseMarket(_id);
  }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.10;

import "../interfaces/IProNoteKeeper.sol";

contract ProVesting {
    address internal immutable depository;
    
    constructor() {
      depository = msg.sender;
    }

    function transfer(address token, address to, uint256 amount) external {
        require(msg.sender == depository, "Vesting: Only depository");
        IERC20(token).transfer(to, amount);
    }
}

interface IVesting {
  function transfer(address token, address to, uint256 amount) external;
}

abstract contract ProNoteKeeper is IProNoteKeeper {

  mapping(address => Note[]) public notes; // user deposit data
  mapping(address => mapping(uint256 => address)) private noteTransfers; // change note ownership

  IVesting public immutable vestingContract;

  constructor () {
    vestingContract = IVesting(address(new ProVesting()));
  }

/* ========== REDEEM ========== */

  /**
   * @notice             redeem notes for user
   * @param _user        the user to redeem for
   * @param _indexes     the note indexes to redeem
   */
  function redeem(address _user, uint256[] memory _indexes) public override {
    uint48 time = uint48(block.timestamp);

    for (uint256 i = 0; i < _indexes.length; i++) {
      Note storage note = notes[_user][_indexes[i]];

      bool matured = note.redeemed == 0 && note.matured <= block.timestamp && note.payout != 0;

      if (matured) {
        note.redeemed = time; // mark as redeemed
        vestingContract.transfer(note.token, _user, note.payout);
      }
    }
  }

  /**
   * @notice             redeem all redeemable markets for user
   * @dev                if possible, query indexesFor() off-chain and input in redeem() to save gas
   * @param _user        user to redeem all notes for
   */ 
  function redeemAll(address _user) external override {
    return redeem(_user, indexesFor(_user));
  }

/* ========== TRANSFER ========== */

  /**
   * @notice             approve an address to transfer a note
   * @param _to          address to approve note transfer for
   * @param _index       index of note to approve transfer for
   */ 
  function pushNote(address _to, uint256 _index) external override {
    require(notes[msg.sender][_index].created != 0, "Depository: note not found");
    noteTransfers[msg.sender][_index] = _to;
  }

  /**
   * @notice             transfer a note that has been approved by an address
   * @param _from        the address that approved the note transfer
   * @param _index       the index of the note to transfer (in the sender's array)
   */ 
  function pullNote(address _from, uint256 _index) external override returns (uint256 newIndex_) {
    require(noteTransfers[_from][_index] == msg.sender, "Depository: transfer not found");
    require(notes[_from][_index].redeemed == 0, "Depository: note redeemed");

    newIndex_ = notes[msg.sender].length;
    notes[msg.sender].push(notes[_from][_index]);

    delete notes[_from][_index];
  }

/* ========== VIEW ========== */

  // Note info

  /**
   * @notice             all pending notes for user
   * @param _user        the user to query notes for
   * @return indexes_    the pending notes for the user
   */
  function indexesFor(address _user) public view override returns (uint256[] memory indexes_) {
    Note[] memory info = notes[_user];

    uint256 length;
    for (uint256 i = 0; i < info.length; i++) {
      if (info[i].redeemed == 0 && info[i].payout != 0) length++;
    }

    indexes_ = new uint256[](length);
    uint256 position;

    for (uint256 i = 0; i < info.length; i++) {
      if (info[i].redeemed == 0 && info[i].payout != 0) {
        indexes_[position] = i;
        position++;
      }
    }
  }

  /**
   * @notice             calculate amount available for claim for a single note
   * @param _user        the user that the note belongs to
   * @param _index       the index of the note in the user's array
   * @return payout_     the payout due
   * @return matured_    if the payout can be redeemed
   */
  function pendingFor(address _user, uint256 _index) public view override returns (uint256 payout_, bool matured_) {
    Note memory note = notes[_user][_index];

    payout_ = note.payout;
    matured_ = note.redeemed == 0 && note.matured <= block.timestamp && note.payout != 0;
  }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.10;

import "../../types/OlympusAccessControlled.sol";

import "../../interfaces/IERC20.sol";

abstract contract ProRewarder is OlympusAccessControlled {

/* ========== STATE VARIABLES ========== */

  uint256 public daoReward; // % reward for dao (3 decimals: 100 = 1%)
  uint256 public refReward; // % reward for referrer (3 decimals: 100 = 1%)

  mapping(address => mapping(IERC20 => uint256)) public rewards; // front end operator rewards
  mapping(address => bool) public whitelisted; // whitelisted status for operators

  constructor(IOlympusAuthority _authority) OlympusAccessControlled(_authority) {}

/* ========== EXTERNAL FUNCTIONS ========== */

  // pay reward to front end operator
  function getReward(IERC20[] memory tokens) external {
    for (uint256 i; i < tokens.length; i++) {
      uint256 reward = rewards[msg.sender][tokens[i]];

      rewards[msg.sender][tokens[i]] = 0;
      tokens[i].transfer(msg.sender, reward);
    }
  }

/* ========== INTERNAL ========== */

  /** 
   * @notice add new market payout to user data
   */
  function _giveRewards(
    IERC20 _token,
    uint256 _payout,
    address _referral
  ) internal returns (uint256) {
    // first we calculate rewards paid to the DAO and to the front end operator (referrer)
    uint256 toDAO = _payout * daoReward / 1e4;
    uint256 toRef = _payout * refReward / 1e4;

    // and store them in our rewards mapping
    if (whitelisted[_referral]) {
      rewards[_referral][_token] += toRef;
      rewards[authority.guardian()][_token] += toDAO;
    } else { // the DAO receives both rewards if referrer is not whitelisted
      rewards[authority.guardian()][_token] += toDAO + toRef;
    }
    return toDAO + toRef;
  }

/* ========== OWNABLE ========== */ 

  /**
   * @notice turn on rewards for front end operators and DAO
   */
  function enableRewards() external onlyGovernor {
    refReward = 3;
    daoReward = 30;
  }

  /**
   * @notice turn off rewards for front end operators and DAO
   */
  function disableRewards(bool _dao) external onlyGovernor {
    if (_dao) {
      daoReward = 0;
    } else {
      refReward = 0;
    }
  }

  /**
   * @notice add or remove addresses from the front end reward whitelist
   */
  function whitelist(address _operator) external onlyPolicy {
    whitelisted[_operator] = !whitelisted[_operator];
  }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.10;

import "./MarketCreator.sol";
import "../interfaces/IProViewer.sol";

abstract contract ProViewer is IProViewer, ProMarketCreator {

    constructor() ProMarketCreator() {}

/* ========== EXTERNAL VIEW ========== */

  /**
   * @notice             calculate current market price of base token in quote tokens
   * @dev                accounts for debt and control variable decay since last deposit (vs _marketPrice())
   * @param _id          ID of market
   * @return             price for market in base token decimals
   *
   * price is derived from the equation
   *
   * p = c * d
   *
   * where
   * p = price
   * c = control variable
   * d = debt
   *
   * d -= ( d * (dt / l) )
   * 
   * where
   * dt = change in time
   * l = length of program
   *
   * if price is below minimum price, minimum price is returned
   * this is enforced on deposits by manipulating total debt (see _decay())
   */
  function marketPrice(uint256 _id) public view override returns (uint256) {
    uint256 price = 
      currentControlVariable(_id)
      * currentDebt(_id)
      / (10 ** metadata[_id].baseDecimals);
    return 
      (price > markets[_id].minPrice) 
      ? price 
      : markets[_id].minPrice;
  }

  /**
   * @notice             payout due for amount of quote tokens
   * @dev                accounts for debt and control variable decay so it is up to date
   * @param _amount      amount of quote tokens to spend
   * @param _id          ID of market
   * @return             amount of base tokens to be paid
   */
  function payoutFor(uint256 _amount, uint256 _id) public view override returns (uint256) {
    Metadata memory meta = metadata[_id];
    return 
      _amount
      * 10 ** (2 * meta.baseDecimals)
      / marketPrice(_id)
      / 10 ** meta.quoteDecimals;
  }

  /**
   * @notice             calculate debt factoring in decay
   * @dev                accounts for debt decay since last deposit
   * @param _id          ID of market
   * @return             current debt for market in base token decimals
   */
  function currentDebt(uint256 _id) public view override returns (uint256) {
    uint256 decay = markets[_id].totalDebt 
      * (block.timestamp - metadata[_id].lastDecay) 
      / metadata[_id].length;
    return markets[_id].totalDebt - decay;
  }

  /**
   * @notice             up to date control variable
   * @dev                accounts for control variable adjustment
   * @param _id          ID of market
   * @return             control variable for market in base token decimals
   */
  function currentControlVariable(uint256 _id) public view returns (uint256) {
    (uint256 decay,,) = _controlDecay(_id);
    return terms[_id].controlVariable - decay;
  }

  /**
   * @notice             returns maximum quote token in for market
   */
  function maxIn(uint256 _id) public view returns (uint256) {
    Metadata memory meta = metadata[_id];
    return
      markets[_id].maxPayout
      * 10 ** meta.quoteDecimals
      * marketPrice(_id)
      / 2 * (10 ** meta.baseDecimals);
  }

  /**
   * @notice             does market send payout immediately
   * @param _id          market ID to search for
   */
  function instantSwap(uint256 _id) public view returns (bool) {
    Terms memory term = terms[_id];
    return (term.fixedTerm && term.vesting == 0) || (!term.fixedTerm && term.vesting <= block.timestamp);
  }

  /**
   * @notice             is a given market accepting deposits
   * @param _id          ID of market
   */
  function isLive(uint256 _id) public view override returns (bool) {
    return (markets[_id].capacity != 0 && terms[_id].conclusion > block.timestamp);
  }

  /**
   * @notice             returns an array of all active market IDs
   */
  function liveMarkets() external view override returns (uint256[] memory) {
    return liveMarketsBetween(0, markets.length);
  }

  /**
   * @notice             returns array of active market IDs within a range
   * @notice             should be used if length exceeds max to query entire array
   */
  function liveMarketsBetween(uint256 firstIndex, uint256 lastIndex) public view returns (uint256[] memory) {
    uint256 num;
    for (uint256 i = firstIndex; i < lastIndex; i++) {
      if (isLive(i)) num++;
    }

    uint256[] memory ids = new uint256[](num);
    uint256 nonce;
    for (uint256 i = firstIndex; i < lastIndex; i++) {
      if (isLive(i)) {
        ids[nonce] = i;
        nonce++;
      }
    }
    return ids;
  }

  /**
   * @notice             returns an array of all active market IDs for a given quote token
   * @param _creator     is query for markets by creator, or for markets by token
   * @param _base        if query is for markets by token, search by base or quote token
   * @param _address     address of creator or token to query by
   */
  function liveMarketsFor(bool _creator, bool _base, address _address) public view override returns (uint256[] memory) {
    uint256[] memory mkts;
    
    if (_creator) {
      mkts = marketsForCreator[_address];
    } else {
      mkts = _base 
      ? marketsForBase[_address]
      : marketsForQuote[_address];
    }

    uint256 num;

    for (uint256 i = 0; i < mkts.length; i++) {
      if (isLive(mkts[i])) num++;
    }

    uint256[] memory ids = new uint256[](num);
    uint256 nonce;

    for (uint256 i = 0; i < mkts.length; i++) {
      if (isLive(mkts[i])) {
        ids[nonce] = mkts[i];
        nonce++;
      }
    }
    return ids;
  }


  function marketsFor(address tokenIn, address tokenOut) public view returns (uint256[] memory) {
    uint256[] memory forBase = liveMarketsFor(false, true, tokenOut);
    uint256[] memory ids;
    uint256 nonce;
    for(uint256 i; i < forBase.length; i++) {
      if (address(markets[forBase[i]].quoteToken) == tokenIn) {
        ids[nonce] = forBase[i];
      }
    }
    return ids;
  }

  function findMarketFor(
    address tokenIn, 
    address tokenOut, 
    uint256 amountIn, 
    uint256 minAmountOut, 
    uint256 maxExpiry
  ) external view returns (uint256 id) {
    uint256[] memory ids = marketsFor(tokenIn, tokenOut);
    uint256[] memory payouts;
    uint256 n;
    for(uint256 i; i < ids.length; i++) {
      Terms memory term = terms[ids[i]];

      uint256 expiry = term.fixedTerm ? block.timestamp + term.vesting : term.vesting;
      require(expiry <= maxExpiry, "Bad expiry");

      if (minAmountOut > markets[ids[i]].maxPayout) {
        payouts[n] = payoutFor(amountIn, ids[i]);
      } else {
        payouts[n] = 0;
      }
      n++;
    }
    uint256 highestOut;
    for (uint256 i; i < payouts.length; i++) {
      if (payouts[i] > highestOut) {
        highestOut = payouts[i];
        id = ids[i];
      }
    }
  }

/* ========== INTERNAL VIEW ========== */

  /**
   * @notice                  amount to decay control variable by
   * @param _id               ID of market
   * @return decay_           change in control variable
   * @return secondsSince_    seconds since last change in control variable
   * @return active_          whether or not change remains active
   */ 
  function _controlDecay(uint256 _id) internal view returns (uint256 decay_, uint48 secondsSince_, bool active_) {
    Adjustment memory info = adjustments[_id];
    if (!info.active) return (0, 0, false);

    secondsSince_ = uint48(block.timestamp) - info.lastAdjustment;

    active_ = secondsSince_ < info.timeToAdjusted;
    decay_ = active_ 
      ? info.change * secondsSince_ / info.timeToAdjusted
      : info.change;
  }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.7.5;

import "../interfaces/IOlympusAuthority.sol";

abstract contract OlympusAccessControlled {
    /* ========== EVENTS ========== */

    event AuthorityUpdated(IOlympusAuthority indexed authority);

    string UNAUTHORIZED = "UNAUTHORIZED"; // save gas

    /* ========== STATE VARIABLES ========== */

    IOlympusAuthority public authority;

    /* ========== Constructor ========== */

    constructor(IOlympusAuthority _authority) {
        authority = _authority;
        emit AuthorityUpdated(_authority);
    }

    /* ========== MODIFIERS ========== */

    modifier onlyGovernor() {
        require(msg.sender == authority.governor(), UNAUTHORIZED);
        _;
    }

    modifier onlyGuardian() {
        require(msg.sender == authority.guardian(), UNAUTHORIZED);
        _;
    }

    modifier onlyPolicy() {
        require(msg.sender == authority.policy(), UNAUTHORIZED);
        _;
    }

    modifier onlyVault() {
        require(msg.sender == authority.vault(), UNAUTHORIZED);
        _;
    }

    /* ========== GOV ONLY ========== */

    function setAuthority(IOlympusAuthority _newAuthority) external onlyGovernor {
        authority = _newAuthority;
        emit AuthorityUpdated(_newAuthority);
    }
}