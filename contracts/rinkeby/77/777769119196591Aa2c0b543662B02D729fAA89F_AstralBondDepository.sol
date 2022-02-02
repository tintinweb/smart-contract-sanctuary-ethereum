// SPDX-License-Identifier: AGPL-3.0

pragma solidity ^0.7.5;
pragma abicoder v2;

import "./libraries/SafeMath.sol";
import "./libraries/SafeMath64.sol";
import "./libraries/SafeMath48.sol";
import "./libraries/FixedPoint.sol";
import "./libraries/SafeERC20.sol";

import "./types/AstralAccessControlled.sol";

import "./types/NoteKeeper.sol";
import "./interfaces/IBondDepository.sol";

import "./interfaces/ITreasury.sol";
import "./interfaces/IERC20Metadata.sol";

contract AstralBondDepository is IBondDepository, NoteKeeper {
	
	using FixedPoint for *;
	using SafeERC20  for IERC20;
	using SafeMath   for uint256;
	using SafeMath64 for uint64;
	using SafeMath48 for uint48;

	Market[] public markets;    // persistent market data
	Terms[] public terms;       // deposit construction data
	Metadata[] public metadata; // extraneous market data

	mapping(uint256 => Adjustment) public adjustments;    // control variable changes
	mapping(address => uint256[]) public marketsForQuote; // market IDs for quote tokens

	constructor(
		IAstralAuthority _authority,
		IERC20 _strl,
		IgSTRL _gstrl,
		IStaking _staking,
		ITreasury _treasury
	) NoteKeeper (_authority, _strl, _gstrl, _staking, _treasury) {
		// save gas for users by bulk approving stake() transactions
		_strl.approve(address(_staking), 1e45);
	}

	// deposit quote tokens in exchange for a bond from a specified market
	function deposit(
		uint256 _id,        // the ID of the market
		uint256 _amount,    // the amount of quote token to spend
		uint256 _maxPrice,  // the maximum price at which to buy
		address _user,      // the recipient of the payout
		address _referral   // the front-end operator address
	) external override returns (uint256 payout_, uint256 expiry_, uint256 index_) {
		Market storage market = markets[_id];
		Terms memory term = terms[_id];
		uint48 currentTime = uint48(block.timestamp);

		// Markets end at a defined timestamp
		require(currentTime < term.conclusion, "Depository: market concluded");

		// Debt and the control variable decay over time
		_decay(_id, currentTime);

		// Users input a maximum price, which protects them from price changes after
		// entering the mempool. max price is a slippage mitigation measure
		uint256 price = _marketPrice(_id);
		require(price <= _maxPrice, "Depository: more than max price");

		// payout for the deposit = amount / price
		//
		// where 
		// payout = STRL out
		// amount = quote tokens in
		// price  = quote tokens : STRL (i.e. 123 DAI : STRL)
		// 1e18 = STRL decimals (9) + price decimals (9)
		payout_ = _amount.mul(uint256(1e18)).div(price);
		payout_ = payout_.div(10 ** metadata[_id].quoteDecimals);

		// markets have a max payout amount, capping size because deposits
		// do not experience slippage. max payout is recalculated upon tuning
		require(payout_ <= market.maxPayout, "Depository: max size exceeded");

		// each market is initialized with a capacity
		//
		// this is either the number of STRL that the market can sell
		// (if capacity in quote is false),
		//
		// or the number of quote tokens that the market can buy
		// (if capacity in quote is true)
		market.capacity = market.capacity.sub(
			market.capacityInQuote
				? _amount
				: payout_
		);

		// bonds mature with a cliff at a set timestamp 
		// prior to the expiry timestamp, no payout tokens are accessible to the user
		// after the expiry timestamp, the entire payout can be redeemed
		//
		// there are two types of bonds: fixed-term and fixed-expiration
		//
		// fixed-term bonds mature in a set amount of the time from deposit
		// i.e. term = 1 week. when alice deposits, on day 1, her bond 
		// expires on day 8. when bob deposits on day 2, hit bond expires day 9.
		//
		// fixed-expiration bonds mature at a set timestamp
		// i.e. expiration = 10 day. when alice deposits on day 1, her term 
		// is 9 days. when bob deposits on day 2, his term is 8 days.
		expiry_ = term.fixedTerm
			? term.vesting.add(currentTime)
			: term.vesting;

		// markets keep track of how many quote tokens have been
		// purchased, and how much STRL has been sold
		market.purchased = market.purchased.add(_amount);
		market.sold = market.sold.add(uint64(payout_));

		// incrementing total debt raises the price of next bond
		market.totalDebt = market.totalDebt.add(uint64(payout_));

		emit Bond(_id, _amount, price);

		// the user data is stored as Notes. these are isolated array entries 
		// storing the amount due, the time created, the time when payout
		// is redeemable, the time when payout was redeemed, and the ID
		// of the market deposited into
		index_ = addNote(
			_user,
			payout_,
			uint48(expiry_),
			uint48(_id),
			_referral
		);

		// transfer payment to treasury
		market.quoteToken.safeTransferFrom(msg.sender, address(treasury), _amount);

		// if max debt is breached, the market is closed
		// this a circuit breaker
		if (term.maxDebt < market.totalDebt) {
			market.capacity = 0;
			terms[_id].conclusion = currentTime;
			emit CloseMarket(_id);
		} else {
			// if market will continue, the control variable is tuned to hit targets on time
			_tune(_id, currentTime);
		}
	}

	// decay debt and adjust control variable if there is an active change
	function _decay(uint256 _id, uint48 _time) internal {
		// Debt is a time-decayed sum of tokens spent in a market
		// Debt is added when deposits occur and removed over time
		markets[_id].totalDebt = markets[_id].totalDebt.sub(debtDecay(_id));
		metadata[_id].lastDecay = _time;

		// The bond control variable is continually tuned. when it is lowered (which 
		// lowers the market price), the change is carried out smoothly over time.
		if (adjustments[_id].active) {
			Adjustment storage adjustment = adjustments[_id];

			(uint64 adjustBy, uint48 secondsSince, bool stillActive) = _controlDecay(_id);
			terms[_id].controlVariable = terms[_id].controlVariable.sub(adjustBy);

			if (stillActive) {
				adjustment.change = adjustment.change.sub(adjustBy);
				adjustment.timeToAdjusted = adjustment.timeToAdjusted.sub(secondsSince);
				adjustment.lastAdjustment = _time;
			} else {
				adjustment.active = false;
			}
		}
	}

	// auto-adjust control variable to hit capacity/spend target
	function _tune(uint256 _id, uint48 _time) internal {
		Metadata memory meta = metadata[_id];

		if (_time >= meta.lastTune.add(meta.tuneInterval)) {
			Market memory market = markets[_id];

			// compute seconds remaining until market will conclude
			uint256 timeRemaining = terms[_id].conclusion.sub(_time);
			uint256 price = _marketPrice(_id);

			// standardize capacity into an base token amount
			// strl decimals (9) + price decimals (9)
			uint256 capacity = market.capacityInQuote
				? market.capacity.mul(uint256(1e18)).div(price).div(10 ** meta.quoteDecimals)
				: market.capacity;

			// calculate the correct payout to complete on time assuming each bond
			// will be max size in the desired deposit interval for the remaining time
			//
			// i.e. market has 10 days remaining. deposit interval is 1 day. capacity
			// is 10,000 STRL. max payout would be 1,000 STRL (10,000 * 1 / 10).
			markets[_id].maxPayout = uint64(capacity.mul(meta.depositInterval).div(timeRemaining));

			// calculate the ideal total debt to satisfy capacity in the remaining time
			uint256 targetDebt = capacity.mul(meta.length).div(timeRemaining);

			// derive a new control variable from the target debt and current supply
			uint64 newControlVariable = uint64(price.mul(treasury.baseSupply()).div(targetDebt));

			emit Tuned(_id, terms[_id].controlVariable, newControlVariable);

			if (newControlVariable >= terms[_id].controlVariable) {
				terms[_id].controlVariable = newControlVariable;
			} else {
				// if decreases, control variable change will be carried out over the tune interval
				// this is because price will be lowered
				uint64 change = terms[_id].controlVariable.sub(newControlVariable);
				adjustments[_id] = Adjustment(change, _time, meta.tuneInterval, true);
			}
			metadata[_id].lastTune = _time;
		}
	}

	// creates a new market type
	function create(
		IERC20 _quoteToken,         // token used to deposit
		uint256[3] memory _market,  // [capacity (in STRL or quote), initial price (9 decimals), debt buffer (3 decimals)]
		bool[2] memory _booleans,   // [capacity in quote, fixed term]
		uint256[2] memory _terms,   // [vesting length / vested timestamp, conclusion timestamp]
		uint32[2] memory _intervals // [deposit interval (seconds), tune interval (seconds)]
	) external override onlyPolicy returns (uint256 id_) {
		// the length of the program, in seconds
		uint256 secondsToConclusion = _terms[1].sub(block.timestamp);

		// the decimals count of the quote token
		uint256 decimals = IERC20Metadata(address(_quoteToken)).decimals();

		// initial target debt is equal to capacity (this is the amount of debt
		// that will decay over in the length of the program if price remains the same).
		// it is converted into base token terms if passed in quote token terms.
		//
		// 1e18 = strl decimals (9) + initial price decimals (9)
		uint64 targetDebt = uint64(_booleans[0]
			? _market[0].mul(1e18).div(_market[1]).div(10 ** decimals)
			: _market[0]
		);

		// max payout is the amount of capacity that should be utilized in a deposit 
		// interval. for example, if capacity is 1,000 STRL, there are 10 days to conclusion,
		// and the preferred deposit interval is 1 day, max payout would be 100 OHM.
		uint64 maxPayout = uint64(
			uint256(targetDebt).mul(uint256(_intervals[0])).div(secondsToConclusion)
		);

		// max debt serves as a circuit breaker for the market. let's say the quote
		// token is a stablecoin, and that stablecoin depegs. without max debt, the 
		// market would continue to buy until it runs out of capacity. this is 
		// configurable with a 3 decimals buffer (1000 = 1% above initial price).
		// note that it's likely advisable to keep this buffer wide.
		// note that the buffer is above 100%. i.e. 10% buffer = initial debt * 1.1
		// 1e5 = 100,000. 10,000 / 100,000 = 10%.
		uint256 maxDebt = uint256(targetDebt)
			.add(uint256(targetDebt)
			.mul(_market[2])
			.div(uint256(1e5)));

		// the control variable is set so that initial price equals the desired
		// initial price. the control variable is the ultimate determinant of price,
		// so we compute this last
		//
		// price = control variable * debt ratio
		// debt ratio = total debt / supply 
		// therefore, control varible = price / debt ratio
		uint256 controlVariable = _market[1].mul(treasury.baseSupply()).div(targetDebt);

		// depositing into, or getting info for, the created market uses this ID
		id_ = markets.length;

		markets.push(Market({
			quoteToken: _quoteToken,
			capacityInQuote: _booleans[0],
			capacity: _market[0],
			totalDebt: targetDebt,
			maxPayout: maxPayout,
			purchased: 0,
			sold: 0
		}));

		terms.push(Terms({
			fixedTerm: _booleans[1],
			controlVariable: uint64(controlVariable),
			vesting: uint48(_terms[0]),
			conclusion: uint48(_terms[1]),
			maxDebt: uint64(maxDebt)
		}));
		
		metadata.push(Metadata({
			lastTune: uint48(block.timestamp),
			lastDecay: uint48(block.timestamp),
			length: uint48(secondsToConclusion),
			depositInterval: _intervals[0],
			tuneInterval: _intervals[1],
			quoteDecimals: uint8(decimals)
		}));
		
		marketsForQuote[address(_quoteToken)].push(id_);
		
		emit CreateMarket(id_, address(strl), address(_quoteToken), _market[1]);
	}

	// disable existing market
	function close(uint256 _id) external override onlyPolicy {
		terms[_id].conclusion = uint48(block.timestamp);
		markets[_id].capacity = 0;
		emit CloseMarket(_id);
	}

	// calculate current market price of quote token in base token
	// price is derived from the equation
	//
	// p = cv * dr
	//
	// where
	// p = price
	// cv = control variable
	// dr = debt ratio
	//
	// dr = d / s
	//
	// where
	// d = debt
	// s = supply of token at market creation
	//
	// d -= ( d * (dt / l) )
	//
	// where
	// dt = change in time
	// l = length of program
	function marketPrice(uint256 _id) public view override returns (uint256) {
		return currentControlVariable(_id)
			.mul(debtRatio(_id))
			.div(10 ** metadata[_id].quoteDecimals);
	}

	// payout due for amount of quote tokens
	function payoutFor(uint256 _amount, uint256 _id) external view override returns (uint256) {
		Metadata memory meta = metadata[_id];
		return _amount
			.mul(1e18)
			.div(marketPrice(_id))
			.div(10 ** meta.quoteDecimals);
	}

	// calculate current ratio of debt to supply
	function debtRatio(uint256 _id) public view override returns (uint256) {
		return currentDebt(_id)
			.mul(10 ** metadata[_id].quoteDecimals)
			.div(treasury.baseSupply());
	}

	// calculate debt factoring in decay
	function currentDebt(uint256 _id) public view override returns (uint256) {
		return uint256(markets[_id].totalDebt).sub(debtDecay(_id));
	}

	// amount of debt to decay from total debt for market ID
	function debtDecay(uint256 _id) public view override returns (uint64) {
		Metadata memory meta = metadata[_id];
		uint256 secondsSince = block.timestamp.sub(meta.lastDecay);
		return uint64(uint256(markets[_id].totalDebt).mul(secondsSince).div(uint256(meta.length)));
	}

	// up to date control variable
	function currentControlVariable(uint256 _id) public view returns (uint256) {
		(uint64 decay,,) = _controlDecay(_id);
		return uint256(terms[_id].controlVariable.sub(decay));
	}

	// is a given market accepting deposits
	function isLive(uint256 _id) public view override returns (bool) {
		return (markets[_id].capacity != 0 && terms[_id].conclusion > block.timestamp);
	}

	// returns an array of all active market IDs
	function liveMarkets() external view override returns (uint256[] memory) {
		uint256 num;
		
		for (uint256 i = 0; i < markets.length; i++) {
			if (isLive(i)) num++;
		}

		uint256[] memory ids = new uint256[](num);
		uint256 nonce;

		for (uint256 i = 0; i < markets.length; i++) {
			if (isLive(i)) {
				ids[nonce] = i;
				nonce++;
			}
		}

		return ids;
	}

	// returns an array of all active market IDs for a given quote token
	function liveMarketsFor(address _token) external view override returns (uint256[] memory) {
		uint256[] memory mkts = marketsForQuote[_token];
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

	// calculate current market price of quote token in base token
	function _marketPrice(uint256 _id) internal view returns (uint256) {
		return uint256(terms[_id].controlVariable)
			.mul(_debtRatio(_id))
			.div(uint256(10 ** metadata[_id].quoteDecimals));
	}

	// calculate debt factoring in decay
	function _debtRatio(uint256 _id) internal view returns (uint256) {
		return uint256(markets[_id].totalDebt)
			.mul(uint256(10 ** metadata[_id].quoteDecimals))
			.div(treasury.baseSupply());
	}

	// amount to decay control variable by
	function _controlDecay(uint256 _id) internal view returns (
		uint64 decay_, 
		uint48 secondsSince_, 
		bool active_
	) {
		Adjustment memory info = adjustments[_id];
		if (!info.active) return (0, 0, false);

		secondsSince_ = uint48(block.timestamp).sub(info.lastAdjustment);

		active_ = secondsSince_ < info.timeToAdjusted;
		decay_ = active_
			? info.change.mul(uint64(secondsSince_)).div(uint64(info.timeToAdjusted))
			: info.change;
	}
}

// SPDX-License-Identifier: AGPL-3.0
  
pragma solidity ^0.7.5;

import "../types/FrontEndRewarder.sol";

import "../libraries/SafeMath.sol";

import "../interfaces/IgSTRL.sol";
import "../interfaces/IStaking.sol";
import "../interfaces/ITreasury.sol";
import "../interfaces/INoteKeeper.sol";

abstract contract NoteKeeper is INoteKeeper, FrontEndRewarder {
	
	using SafeMath   for uint256;

	mapping(address => Note[]) public notes; // user deposit data
	mapping(address => mapping(uint256 => address)) private noteTransfers; // change note ownership

	IgSTRL internal immutable gSTRL;
	IStaking internal immutable staking;
	ITreasury internal treasury;

	constructor (
		IAstralAuthority _authority,
		IERC20 _strl,
		IgSTRL _gstrl,
		IStaking _staking,
		ITreasury _treasury
	) FrontEndRewarder(_authority, _strl) {
		gSTRL = _gstrl;
		staking = _staking;
		treasury = _treasury;
	}

	// if treasury address changes on authority, update it
	function updateTreasury() external {
		require(
			msg.sender == authority.governor() ||
			msg.sender == authority.guardian() ||
			msg.sender == authority.policy(),
			"Only authorized"
		);
		treasury = ITreasury(authority.vault());
	}

	// adds a new Note for a user,
	// and mints & stakes payout & rewards
	function addNote(
		address _user,
		uint256 _payout,
		uint48 _expiry,
		uint48 _marketID,
		address _referral
	) internal returns (uint256 index_) {
		// index of the note is the next in the user's array
		index_ = notes[_user].length;

		// the new note is pushed to the user's array
		notes[_user].push(
			Note({
				payout: gSTRL.balanceTo(_payout),
				created: uint48(block.timestamp),
				matured: _expiry,
				redeemed: 0,
				marketID: _marketID
			})
		);

		uint256 rewards = _giveRewards(_payout, _referral);

		// mint and stake payout
		treasury.mint(address(this), _payout.add(rewards));

		// note that only the payout gets staked
		staking.stake(address(this), _payout, false, true);
	}

	// redeem notes for user
	function redeem(
		address _user, 
		uint256[] memory _indexes, 
		bool _sendgSTRL
	) public override returns (uint256 payout_) {
		uint48 time = uint48(block.timestamp);
		payout_ = 0;

		for (uint256 i = 0; i < _indexes.length; i++) {
			(uint256 pay, bool matured) = pendingFor(_user, _indexes[i]);

			if (matured) {
				notes[_user][_indexes[i]].redeemed = time; // mark as redeemed
				payout_ = payout_.add(pay);
			}
		}

		if (_sendgSTRL) {
			gSTRL.transfer(_user, payout_); // send payout as gSTRL
		} else {
			staking.unwrap(_user, payout_); // unwrap and send payout as sSTRL
		}
	}

	// redeem all redeemable markets for user
	function redeemAll(address _user, bool _sendgSTRL) external override returns (uint256) {
		return redeem(_user, indexesFor(_user), _sendgSTRL);
	}

	// approve an address to transfer a note
	function pushNote(address _to, uint256 _index) external override {
		require(notes[msg.sender][_index].created != 0, "Depository: note not found");
		noteTransfers[msg.sender][_index] = _to;
	}

	// transfer a note that has been approved by an address
	function pullNote(address _from, uint256 _index) external override returns (uint256 newIndex_) {
		require(noteTransfers[_from][_index] == msg.sender, "Depository: transfer not found");
		require(notes[_from][_index].redeemed == 0, "Depository: note redeemed");

		newIndex_ = notes[msg.sender].length;
		notes[msg.sender].push(notes[_from][_index]);

		delete notes[_from][_index];
	}

	// all pending notes for user
	function indexesFor(address _user) public view override returns (uint256[] memory) {
		Note[] memory info = notes[_user];

		uint256 length;
		for (uint256 i = 0; i < info.length; i++) {
			if (info[i].redeemed == 0 && info[i].payout != 0) length++;
		}

		uint256[] memory indexes = new uint256[](length);
		uint256 position;

		for (uint256 i = 0; i < info.length; i++) {
			if (info[i].redeemed == 0 && info[i].payout != 0) {
				indexes[position] = i;
				position++;
			}
		}

		return indexes;
	}

	// calculate amount availiable for claim for a single note
	function pendingFor(
		address _user, 
		uint256 _index
	) public view override returns (uint256 payout_, bool matured_) {
		Note memory note = notes[_user][_index];

		payout_ = note.payout;
		matured_ = note.redeemed == 0 && note.matured <= block.timestamp && note.payout != 0;
	}
}

// SPDX-License-Identifier: AGPL-3.0-only

pragma solidity ^0.7.5;

import "../libraries/SafeMath.sol";
import "../types/AstralAccessControlled.sol";
import "../interfaces/IERC20.sol";

abstract contract FrontEndRewarder is AstralAccessControlled {

	using SafeMath for uint256;

	uint256 public daoReward; // % reward for dao (3 decimals: 100 = 1%)
	uint256 public refReward; // % reward for referrer (3 decimals: 100 = 1%)
	
	mapping(address => uint256) public rewards;
	mapping(address => bool) public whitelisted; // whitelisted status for operators

	IERC20 internal immutable strl; // reward token

	constructor(
		IAstralAuthority _authority,
		IERC20 _strl
	) AstralAccessControlled(_authority) {
		strl = _strl;
	}

	function getReward() external {
		uint256 reward = rewards[msg.sender];

		rewards[msg.sender] = 0;
		strl.transfer(msg.sender, reward);
	}

	// add new market payout to user data
	function _giveRewards(
		uint256 _payout,
		address _referral
	) internal returns (uint256) {
		uint256 toDAO = _payout.mul(daoReward).div(1e4);
		uint256 toRef = _payout.mul(refReward).div(1e4);

		if (whitelisted[_referral]) {
			rewards[_referral] = rewards[_referral].add(toDAO);
			rewards[authority.guardian()] = rewards[authority.guardian()].add(toDAO);
		} else {
			rewards[authority.guardian()] = rewards[authority.guardian()].add(toDAO).add(toRef);
		}
		return toDAO.add(toRef);
	}

	function setRewards(uint256 _toFrontEnd, uint256 _toDAO) external onlyGovernor {
		refReward = _toFrontEnd;
		daoReward = _toDAO;
	}

	function whitelist(address _operator) external onlyGovernor {
		whitelisted[_operator] = !whitelisted[_operator];
	}
}

// SPDX-License-Identifier: AGPL-3.0-only

pragma solidity ^0.7.5;

import "../interfaces/IAstralAuthority.sol";

abstract contract AstralAccessControlled {

    event AuthorityUpdated(IAstralAuthority indexed authority);

    string UNAUTHORIZED = "UNAUTHORIZED"; // save gas

    IAstralAuthority public authority;

    constructor(IAstralAuthority _authority) {
        authority = _authority;
        emit AuthorityUpdated(_authority);
    }

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

    function setAuthority(IAstralAuthority _newAuthority) external onlyGovernor {
        authority = _newAuthority;
        emit AuthorityUpdated(_newAuthority);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.5;

/**
 * @title SafeMath64
 * @dev Math operations for uint64 with overflow safety checks.
 */
library SafeMath64 {
    int256 private constant MIN_UINT64 = type(uint64).max;
    int256 private constant MAX_UINT64 = type(uint64).min;

    /**
     * @dev Multiplies two uint64 variables and fails on overflow.
     */
    function mul(uint64 a, uint64 b) internal pure returns (uint64) {
		if (a == 0) {
			return uint64(0);
		}

        uint64 c = a * b;
        require(c / a == b, "SafeMath64: multiplication overflow");
        
		return c;
    }

    /**
     * @dev Division of two uint64 variables and fails on overflow.
     */
    function div(uint64 a, uint64 b) internal pure returns (uint64) {
		require(b > 0, "SafeMath64: division by zero");
        uint64 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Subtracts two uint64 variables and fails on overflow.
     */
    function sub(uint64 a, uint64 b) internal pure returns (uint64) {
		require(b <= a, "SafeMath64: substraction overflow");
        uint64 c = a - b;

        return c;
    }

    /**
     * @dev Adds two uint64 variables and fails on overflow.
     */
    function add(uint64 a, uint64 b) internal pure returns (uint64) {
		uint64 c = a + b;
        require(c >= a, "SafeMath64: addition overflow");

        return c;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.5;

/**
 * @title SafeMath48
 * @dev Math operations for uint48 with overflow safety checks.
 */
library SafeMath48 {
    int256 private constant MIN_UINT48 = type(uint48).max;
    int256 private constant MAX_UINT48 = type(uint48).min;

    /**
     * @dev Multiplies two uint48 variables and fails on overflow.
     */
    function mul(uint48 a, uint48 b) internal pure returns (uint48) {
		if (a == 0) {
			return uint48(0);
		}

        uint48 c = a * b;
        require(c / a == b, "SafeMath48: multiplication overflow");
        
		return c;
    }

    /**
     * @dev Division of two uint48 variables and fails on overflow.
     */
    function div(uint48 a, uint48 b) internal pure returns (uint48) {
		require(b > 0, "SafeMath48: division by zero");
        uint48 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Subtracts two uint48 variables and fails on overflow.
     */
    function sub(uint48 a, uint48 b) internal pure returns (uint48) {
		require(b <= a, "SafeMath48: substraction overflow");
        uint48 c = a - b;

        return c;
    }

    /**
     * @dev Adds two uint48 variables and fails on overflow.
     */
    function add(uint48 a, uint48 b) internal pure returns (uint48) {
		uint48 c = a + b;
        require(c >= a, "SafeMath48: addition overflow");

        return c;
    }
}

// SPDX-License-Identifier: AGPL-3.0

pragma solidity ^0.7.5;

library SafeMath {

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
		// Gas optimization: this is cheaper than requiring 'a' not being zero, but the
		// benefit is lost if 'b' is also tested.
		// See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

	function average(uint256 a, uint256 b) internal pure returns (uint256) {
		return div(add((a & b), (a ^ b)), 2);
	}

    // Only used in the  BondingCalculator.sol
    function sqrrt(uint256 a) internal pure returns (uint c) {
        if (a > 3) {
            c = a;
            uint b = add( div( a, 2), 1 );
            while (b < c) {
                c = b;
                b = div( add( div( a, b ), b), 2 );
            }
        } else if (a != 0) {
            c = 1;
        }
    }

	function mod(uint256 a, uint256 b) internal pure returns (uint256) {
		require(b != 0);
		return a % b;
	}
}

// SPDX-License-Identifier: AGPL-3.0-only

pragma solidity ^0.7.5;

import "../interfaces/IERC20.sol";

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

pragma solidity ^0.7.5;

library FullMath {
    function fullMul(uint256 x, uint256 y) private pure returns (uint256 l, uint256 h) {
        uint256 mm = mulmod(x, y, uint256(-1));
        l = x * y;
        h = mm - l;
        if (mm < l) h -= 1;
    }

    function fullDiv(
        uint256 l,
        uint256 h,
        uint256 d
    ) private pure returns (uint256) {
        uint256 pow2 = d & -d;
        d /= pow2;
        l /= pow2;
        l += h * ((-pow2) / pow2 + 1);
        uint256 r = 1;
        r *= 2 - d * r;
        r *= 2 - d * r;
        r *= 2 - d * r;
        r *= 2 - d * r;
        r *= 2 - d * r;
        r *= 2 - d * r;
        r *= 2 - d * r;
        r *= 2 - d * r;
        return l * r;
    }

    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 d
    ) internal pure returns (uint256) {
        (uint256 l, uint256 h) = fullMul(x, y);

        uint256 mm = mulmod(x, y, d);
        if (mm > l) h -= 1;
        l -= mm;

        if (h == 0) return l / d;

        require(h < d, 'FullMath: FULLDIV_OVERFLOW');
        return fullDiv(l, h, d);
    }
}

// SPDX-License-Identifier: AGPL-3.0

pragma solidity ^0.7.5;

import "./FullMath.sol";

library Babylonian {

    function sqrt(uint256 x) internal pure returns (uint256) {
        if (x == 0) return 0;

        uint256 xx = x;
        uint256 r = 1;
        if (xx >= 0x100000000000000000000000000000000) {
            xx >>= 128;
            r <<= 64;
        }
        if (xx >= 0x10000000000000000) {
            xx >>= 64;
            r <<= 32;
        }
        if (xx >= 0x100000000) {
            xx >>= 32;
            r <<= 16;
        }
        if (xx >= 0x10000) {
            xx >>= 16;
            r <<= 8;
        }
        if (xx >= 0x100) {
            xx >>= 8;
            r <<= 4;
        }
        if (xx >= 0x10) {
            xx >>= 4;
            r <<= 2;
        }
        if (xx >= 0x8) {
            r <<= 1;
        }
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1; // Seven iterations should be enough
        uint256 r1 = x / r;
        return (r < r1 ? r : r1);
    }
}

library BitMath {

    function mostSignificantBit(uint256 x) internal pure returns (uint8 r) {
        require(x > 0, 'BitMath::mostSignificantBit: zero');

        if (x >= 0x100000000000000000000000000000000) {
            x >>= 128;
            r += 128;
        }
        if (x >= 0x10000000000000000) {
            x >>= 64;
            r += 64;
        }
        if (x >= 0x100000000) {
            x >>= 32;
            r += 32;
        }
        if (x >= 0x10000) {
            x >>= 16;
            r += 16;
        }
        if (x >= 0x100) {
            x >>= 8;
            r += 8;
        }
        if (x >= 0x10) {
            x >>= 4;
            r += 4;
        }
        if (x >= 0x4) {
            x >>= 2;
            r += 2;
        }
        if (x >= 0x2) r += 1;
    }
}


library FixedPoint {

    struct uq112x112 {
        uint224 _x;
    }

    struct uq144x112 {
        uint256 _x;
    }

    uint8 private constant RESOLUTION = 112;
    uint256 private constant Q112 = 0x10000000000000000000000000000;
    uint256 private constant Q224 = 0x100000000000000000000000000000000000000000000000000000000;
    uint256 private constant LOWER_MASK = 0xffffffffffffffffffffffffffff; // decimal of UQ*x112 (lower 112 bits)

    function decode(uq112x112 memory self) internal pure returns (uint112) {
        return uint112(self._x >> RESOLUTION);
    }

    function decode112with18(uq112x112 memory self) internal pure returns (uint) {

        return uint(self._x) / 5192296858534827;
    }

    function fraction(uint256 numerator, uint256 denominator) internal pure returns (uq112x112 memory) {
        require(denominator > 0, 'FixedPoint::fraction: division by zero');
        if (numerator == 0) return FixedPoint.uq112x112(0);

        if (numerator <= uint144(-1)) {
            uint256 result = (numerator << RESOLUTION) / denominator;
            require(result <= uint224(-1), 'FixedPoint::fraction: overflow');
            return uq112x112(uint224(result));
        } else {
            uint256 result = FullMath.mulDiv(numerator, Q112, denominator);
            require(result <= uint224(-1), 'FixedPoint::fraction: overflow');
            return uq112x112(uint224(result));
        }
    }
    
    // square root of a UQ112x112
    // lossy between 0/1 and 40 bits
    function sqrt(uq112x112 memory self) internal pure returns (uq112x112 memory) {
        if (self._x <= uint144(-1)) {
            return uq112x112(uint224(Babylonian.sqrt(uint256(self._x) << 112)));
        }

        uint8 safeShiftBits = 255 - BitMath.mostSignificantBit(self._x);
        safeShiftBits -= safeShiftBits % 2;
        return uq112x112(uint224(Babylonian.sqrt(uint256(self._x) << safeShiftBits) << ((112 - safeShiftBits) / 2)));
    }
}

// SPDX-License-Identifier: AGPL-3.0

pragma solidity ^0.7.5;

import "./IERC20.sol";

interface IgSTRL is IERC20 {
	function mint(address _to, uint256 _amount) external;

    function burn(address _from, uint256 _amount) external;

    function index() external view returns (uint256);

    function balanceFrom(uint256 _amount) external view returns (uint256);

    function balanceTo(uint256 _amount) external view returns (uint256);

    function migrate(address _staking, address _sOHM) external;
}

// SPDX-License-Identifier: AGPL-3.0

pragma solidity ^0.7.5;

interface ITreasury {
	event Deposit(address indexed token, uint256 amount, uint256 value);
    event Withdraw(address indexed token, uint256 amount, uint256 value);
    event CreateDebt(
        address indexed debtor,
        address indexed token,
        uint256 amount,
        uint256 value
    );
    event RepayDebt(
        address indexed debtor,
        address indexed token,
        uint256 amount,
        uint256 value
    );
    event Managed(address indexed token, uint256 amount);
    event ReservesAudited(uint256 indexed totalReserves);
    event Minted(address indexed caller, address indexed recipient, uint256 amount);
    event PermissionQueued(STATUS indexed status, address queued);
    event Permissioned(address addr, STATUS indexed status, bool result);

	enum STATUS {
        RESERVEDEPOSITOR,
        RESERVESPENDER,
        RESERVETOKEN,
        RESERVEMANAGER,
        LIQUIDITYDEPOSITOR,
        LIQUIDITYTOKEN,
        LIQUIDITYMANAGER,
        RESERVEDEBTOR,
        REWARDMANAGER,
        SSTRL,
        STRLDEBTOR
    }

    struct Queue {
        STATUS managing;
        address toPermit;
        address calculator;
        uint256 timelockEnd;
        bool nullify;
        bool executed;
    }

	function deposit(
		uint256 amount_,
		address token_,
		uint256 profit_
	) external returns (uint256);

	function withdraw(uint256 amount_, address token_) external;

	function tokenValue(address token_, uint256 amount_) external view returns (uint256 value_);

	function mint(address recipient, uint256 amount) external;

	function manage(address token_, uint256 amount_) external;

	function incurDebt(uint256 amount_, address token_) external;

	function repayDebtWithReserve(uint256 amount_, address token_) external;

	function excessReserves() external view returns (uint256);

	function baseSupply() external view returns (uint256);
}

// SPDX-License-Identifier: AGPL-3.0

pragma solidity ^0.7.5;

interface IStaking {
    function stake(
        address _to,
        uint256 _amount,
        bool _rebasing,
        bool _claim
    ) external returns (uint256);

    function claim(address _recipient, bool _rebasing) external returns (uint256);

    function forfeit() external returns (uint256);

    function toggleLock() external;

    function unstake(
        address _to,
        uint256 _amount,
        bool _trigger,
        bool _rebasing
    ) external returns (uint256);

    function wrap(address _to, uint256 _amount) external returns (uint256 gBalance_);

    function unwrap(address _to, uint256 _amount) external returns (uint256 sBalance_);

    function rebase() external;

    function index() external view returns (uint256);

    function contractBalance() external view returns (uint256);

    function totalStaked() external view returns (uint256);

    function supplyInWarmup() external view returns (uint256);
}

// SPDX-License-Identifier: AGPL-3.0-only

pragma solidity ^0.7.5;

interface INoteKeeper {
	// Info for market note
	struct Note {
		uint256 payout;  // gSTRL remaining to be paid
		uint48 created;  // time market was created
		uint48 matured;  // timestamp when market is matured
		uint48 redeemed; // time market was redeemed
		uint48 marketID; // market ID of deposit. uint48 to avoid adding a slot.
	}
	
	function redeem(
		address _user, 
		uint256[] memory _indexes, 
		bool _sendgSTRL
	) external returns (uint256);
	
	function redeemAll(address _user, bool _sendgSTRL) external returns (uint256);
	function pushNote(address to, uint256 index) external;
	function pullNote(address from, uint256 index) external returns (uint256 newIndex_);
	
	function indexesFor(address _user) external view returns (uint256[] memory);
	function pendingFor(
		address _user, 
		uint256 _index
	) external view returns (uint256 payout_, bool matured_);
}

// SPDX-License-Identifier: AGPL-3.0

pragma solidity ^0.7.5;

import "./IERC20.sol";

interface IERC20Metadata is IERC20 {

	function name() external view returns (string memory);

	function symbol() external view returns (string memory);

	function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.7.5;

interface IERC20 {
	/**
	 * @dev Returns the amount of tokens in existance.
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
	 * condition is to first reduce the spender's allowanceto 0 and set the 
	 * desired value afterwards:
	 * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
	 *
	 * Emits an {Approval} event.
	 */
	function approve(address spender, uint256 amount) external returns (bool);

	/**
	 * @dev Moves `amount` tokens from `spender` to `recipient` using the 
	 * allowance mechanism. `amount` is then deducated from the caller's 
	 * allowance.
	 *
	 * Returns a boolean value indicating whether the operation succeeded.
	 *
	 * Emits a {Transfer} event.
	 */
	function transferFrom(address spender, address recipient, uint256 amount) external returns (bool);

	/**
	 * @dev Emitted when `value` tokens are moved from one account (`from`) to
	 * another (`to`).
	 *
	 * Note that `value` may be zero.
	 */
	event Transfer(address indexed, address indexed to, uint256 value);

	/**
	 * @dev Emitted when the allowance of `spender` for an `owner` is set by
	 * a call to {approve}. `value` is the allowance.
	 */
	event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: AGPL-3.0

pragma solidity ^0.7.5;

import "./IERC20.sol";

interface IBondDepository {
	event CreateMarket(
        uint256 indexed id,
        address indexed baseToken,
        address indexed quoteToken,
        uint256 initialPrice
    );

    event CloseMarket(uint256 indexed id);

    event Bond(
        uint256 indexed id,
        uint256 amount,
        uint256 price
    );

    event Tuned(
        uint256 indexed id,
        uint64 oldControlVariable,
        uint64 newControlVariable
    );
	
	// Info about each type of market
	struct Market {
		uint256 capacity;           // capacity remaining
		IERC20 quoteToken;          // token to accept as payment
		bool capacityInQuote;       // capacity limit is in payment token (true) or in STRL (false, default)
		uint64 totalDebt;           // total debt from market
		uint64 maxPayout;           // max tokens in/out (determined by capacityInQuote false/true)
		uint64 sold;                // base tokens out
		uint256 purchased;          // quote tokens in
	}
	
	// Info for creating new markets
	struct Terms {
		bool fixedTerm;             // fixed term or fixed expiration
		uint64 controlVariable;     // scaling variable for price
		uint48 vesting;             // length of time from deposit to maturity if fixed-term
		uint48 conclusion;          // timestamp when market no longer offered (doubles as time when market matures if fixed-expiry)
		uint64 maxDebt;             // 9 decimal debt maximum in STRL
	}
	
	// Additional info about market.
	struct Metadata {
		uint48 lastTune;            // last timestamp when control variable was tuned
		uint48 lastDecay;           // last timestamp when market was created and debt was decayed
		uint48 length;              // time from creation to conclusion. used as speed to decay debt.
		uint48 depositInterval;     // target frequency of deposits
		uint48 tuneInterval;        // frequency of tuning
		uint8 quoteDecimals;        // decimals of quote token
	}
	
	// Control variable adjustment data
	struct Adjustment {
		uint64 change;              // adjustment for price scaling variable 
		uint48 lastAdjustment;      // time of last adjustment
		uint48 timeToAdjusted;      // time after which adjustment should happen
		bool active;                // if adjustment is available
	}
	
	function deposit(
		uint256 _bid,               // the ID of the market
		uint256 _amount,            // the amount of quote token to spend
		uint256 _maxPrice,          // the maximum price at which to buy
		address _user,              // the recipient of the payout
		address _referral           // the operator address
	) external returns (uint256 payout_, uint256 expiry_, uint256 index_);
	
	function create (
		IERC20 _quoteToken,         // token used to deposit
		uint256[3] memory _market,  // [capacity, initial price]
		bool[2] memory _booleans,   // [capacity in quote, fixed term]
		uint256[2] memory _terms,   // [vesting, conclusion]
		uint32[2] memory _intervals // [deposit interval, tune interval]
	) external returns (uint256 id_);
	
	function close(uint256 _id) external;
	function isLive(uint256 _bid) external view returns (bool);
	function liveMarkets() external view returns (uint256[] memory);
	function liveMarketsFor(address _quoteToken) external view returns (uint256[] memory);
	function payoutFor(uint256 _amount, uint256 _bid) external view returns (uint256);
	function marketPrice(uint256 _bid) external view returns (uint256);
	function currentDebt(uint256 _bid) external view returns (uint256);
	function debtRatio(uint256 _bid) external view returns (uint256);
	function debtDecay(uint256 _bid) external view returns (uint64);
}

// SPDX-License-Identifier: AGPL-3.0

pragma solidity ^0.7.5;

interface IAstralAuthority {
    
	event GovernorPushed(
		address indexed from, 
		address indexed to, 
		bool _effectiveImmediately
	);
    
	event GuardianPushed(
		address indexed from, 
		address indexed to, 
		bool _effectiveImmediately
	);
    
	event PolicyPushed(
		address indexed from, 
		address indexed to, 
		bool _effectiveImmediately
	);
    
	event VaultPushed(
		address indexed from, 
		address indexed to, 
		bool _effectiveImmediately
	);

    event GovernorPulled(address indexed from, address indexed to);
    event GuardianPulled(address indexed from, address indexed to);
    event PolicyPulled(address indexed from, address indexed to);
    event VaultPulled(address indexed from, address indexed to);

    function governor() external view returns (address);
    function guardian() external view returns (address);
    function policy() external view returns (address);
    function vault() external view returns (address);
}