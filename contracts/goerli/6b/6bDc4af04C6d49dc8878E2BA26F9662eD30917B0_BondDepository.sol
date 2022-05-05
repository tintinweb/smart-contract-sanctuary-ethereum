// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "./type/NoteKeeper.sol";
import "./interface/IBondDepository.sol";

contract BondDepository is IBondDepository, NoteKeeper {
    /* ========== DEPENDENCIES ========== */

    using SafeERC20 for IERC20;
    
    /* ========== EVENTS ========== */

    event CreateMarket(uint256 indexed id, address indexed baseToken, address indexed quoteToken, uint256 initialPrice);
    event CloseMarket(uint256 indexed id);
    event Bond(uint256 indexed id, uint256 amount, uint256 price);
    event Tuned(uint256 indexed id, uint64 oldControlVariable, uint64 newControlVariable);

    /* ========== STATE VARIABLES ========== */

    Market[] public markets;
    Terms[] public terms;
    Metadata[] public metadata;
    mapping(uint256 => Adjustment) public adjustments;
    mapping(address => uint256[]) public marketsForQuote;

    /* ========== CONSTRUCTOR ========== */

    constructor(
        IAuthority _authority, 
        IERC20 _mainToken, 
        IGovernanceToken _governanceToken, 
        IStaking _staking, 
        ITreasury _treasury
    ) NoteKeeper(
        _authority, 
        _mainToken, 
        _governanceToken, 
        _staking, 
        _treasury) {
        _mainToken.approve(address(_staking),1e45);
    }

    /* ========== MUTATIVE FUNCTIONS ========== */

    function deposit(
        uint256 _id,
        uint256 _amount,
        uint256 _maxPrice,
        address _user,
        address _referral
    )   external override returns (
            uint256 payout_,
            uint256 expiry_,
            uint256 index_
        )
    {
        Market storage market = markets[_id];
        Terms memory term = terms[_id];
        uint48 currentTime = uint48(block.timestamp);
        require(currentTime < term.conclusion, "Depository: market concluded");

        _decay(_id, currentTime);

        uint256 price = _marketPrice(_id);
        require(price <= _maxPrice, "Depository: more than max price");

        payout_ = ((_amount * 1e18) / price) / (10**metadata[_id].quoteDecimals);
        require(payout_ <= market.maxPayout, "Depository: max size exceeded");
        
        market.capacity -= market.capacityInQuote ? _amount : payout_;
        expiry_ = term.fixedTerm ? term.vesting + currentTime : term.vesting;
        market.purchased += _amount;
        market.sold += uint64(payout_);
        market.totalDebt += uint64(payout_);

        emit Bond(_id, _amount, price);

        index_ = addNote(_user, payout_, uint48(expiry_), uint48(_id), _referral);
        market.quoteToken.safeTransferFrom(msg.sender, address(treasury), _amount);

        if (term.maxDebt < market.totalDebt) {
            market.capacity = 0;
            emit CloseMarket(_id);
        } else {
            _tune(_id, currentTime);
        }
    }
    

    function _decay(uint256 _id, uint48 _time) internal {
        markets[_id].totalDebt -= debtDecay(_id);
        metadata[_id].lastDecay = _time;

        if (adjustments[_id].active) {
            Adjustment storage adjustment = adjustments[_id];

            (uint64 adjustBy, uint48 secondsSince, bool stillActive) = _controlDecay(_id);
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

    function _tune(uint256 _id, uint48 _time) internal {
        Metadata memory meta = metadata[_id];
        if (_time >= meta.lastTune + meta.tuneInterval) {
            Market memory market = markets[_id];
            uint256 timeRemaining = terms[_id].conclusion - _time;
            uint256 price = _marketPrice(_id);

            uint256 capacity = market.capacityInQuote
                ? ((market.capacity * 1e18) / price) / (10**meta.quoteDecimals)
                : market.capacity;

            markets[_id].maxPayout = uint64((capacity * meta.depositInterval) / timeRemaining);
            uint256 targetDebt = (capacity * meta.length) / timeRemaining;
            uint64 newControlVariable = uint64((price * treasury.baseSupply()) / targetDebt);

            emit Tuned(_id, terms[_id].controlVariable, newControlVariable);

            if (newControlVariable >= terms[_id].controlVariable) {
                terms[_id].controlVariable = newControlVariable;
            } else {
                uint64 change = terms[_id].controlVariable - newControlVariable;
                adjustments[_id] = Adjustment(change, _time, meta.tuneInterval, true);
            }
            metadata[_id].lastTune = _time;
        }
    }

    function create(
        IERC20 _quoteToken,
        uint256[3] memory _market,
        bool[2] memory _booleans,
        uint256[2] memory _terms,
        uint32[2] memory _intervals
    ) external override onlyPolicy returns (uint256 id_) {
        uint256 secondsToConclusion = _terms[1] - block.timestamp;
        uint256 decimals = IERC20Metadata(address(_quoteToken)).decimals();
        uint64 targetDebt = uint64(_booleans[0] ? ((_market[0] * 1e18 / _market[1]) / _market[1]) : _market[0]);
        uint64 maxPayout = uint64((targetDebt * _intervals[0]) / secondsToConclusion);
        uint256 maxDebt = targetDebt + ((targetDebt * _market[2]) / 1e5);
        uint256 controlVariable = (_market[1] * treasury.baseSupply()) / targetDebt;
        
        id_ = markets.length;
        markets.push(
                Market({
                    quoteToken: _quoteToken,
                    capacityInQuote: _booleans[0],
                    capacity: _market[0],
                    totalDebt: targetDebt,
                    maxPayout: maxPayout,
                    purchased: 0,
                    sold: 0
                })
            );

        terms.push(
            Terms({
                fixedTerm: _booleans[1],
                controlVariable: uint64(controlVariable),
                vesting: uint48(_terms[0]),
                conclusion: uint48(_terms[1]),
                maxDebt: uint64(maxDebt)
            })
        );

        metadata.push(
            Metadata({
                lastTune: uint48(block.timestamp),
                lastDecay: uint48(block.timestamp),
                length: uint48(secondsToConclusion),
                depositInterval: _intervals[0],
                tuneInterval: _intervals[1],
                quoteDecimals: uint8(decimals)
            })
        );

        marketsForQuote[address(_quoteToken)].push(id_);

        emit CreateMarket(id_, address(mainToken), address(_quoteToken), _market[1]);
    }

    function close(uint256 _id) external override onlyPolicy {
        terms[_id].conclusion = uint48(block.timestamp);
        markets[_id].capacity = 0;
        emit CloseMarket(_id);
    }
    
    /* ========== VIEW FUNCTIONS ========== */

    function marketPrice(uint256 _id) public view override returns (uint256) {
        return (currentControlVariable(_id) * debtRatio(_id)) / (10**metadata[_id].quoteDecimals);
    }

    function payoutFor(uint256 _amount, uint256 _id) external view override returns (uint256) {
        Metadata memory meta = metadata[_id];
        return (_amount * 1e18) / marketPrice(_id) / 10**meta.quoteDecimals;
    }

    function debtRatio(uint256 _id) public view override returns (uint256) {
        return (currentDebt(_id) * (10**metadata[_id].quoteDecimals)) / treasury.baseSupply();
    }

    function currentDebt(uint256 _id) public view override returns (uint256) {
        return markets[_id].totalDebt - debtDecay(_id);
    }

    function debtDecay(uint256 _id) public view override returns (uint64) {
        Metadata memory meta = metadata[_id];

        uint256 secondsSince = block.timestamp - meta.lastDecay;

        return uint64((markets[_id].totalDebt * secondsSince) / meta.length);
    }

    function currentControlVariable(uint256 _id) public view returns (uint256) {
        (uint64 decay, , ) = _controlDecay(_id);
        return terms[_id].controlVariable - decay;
    }

    function isLive(uint256 _id) public view override returns (bool) {
        return (markets[_id].capacity != 0 && terms[_id].conclusion > block.timestamp);
    }

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

    function _marketPrice(uint256 _id) internal view returns (uint256) {
        return (terms[_id].controlVariable * _debtRatio(_id)) / (10**metadata[_id].quoteDecimals);
    }

    function _debtRatio(uint256 _id) internal view returns (uint256) {
        return (markets[_id].totalDebt * (10**metadata[_id].quoteDecimals)) / treasury.baseSupply();
    }

    function _controlDecay(uint256 _id)
        internal
        view
        returns (
            uint64 decay_,
            uint48 secondsSince_,
            bool active_
        )
    {
        Adjustment memory info = adjustments[_id];
        if (!info.active) return (0, 0, false);

        secondsSince_ = uint48(block.timestamp) - info.lastAdjustment;

        active_ = secondsSince_ < info.timeToAdjusted;
        decay_ = active_ ? (info.change * secondsSince_) / info.timeToAdjusted : info.change;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "./FrontEndRewarder.sol";
import "../interface/IGovernanceToken.sol";
import "../interface/IStaking.sol";
import "../interface/ITreasury.sol";
import "../interface/INoteKeeper.sol";

abstract contract NoteKeeper is INoteKeeper, FrontEndRewarder {

    /* ========== STATE VARIABLES ========== */
    mapping(address => Note[]) public notes; // user deposit data
    mapping(address => mapping(uint256 => address)) private noteTransfers; // change note ownership

    IGovernanceToken internal governanceToken;
    IStaking internal staking;
    ITreasury internal treasury;

    constructor(
        IAuthority _authority,
        IERC20 _mainToken,
        IGovernanceToken _governanceToken,
        IStaking _staking,
        ITreasury _treasury
    ) FrontEndRewarder(_authority, _mainToken) {
        governanceToken = _governanceToken;
        staking = _staking;
        treasury = _treasury;
    }

    function updateTreasury() external onlyAuthority {
       treasury = ITreasury(authority.vault());
    }

    function addNote(
        address _user,
        uint256 _payout,
        uint48 _expiry,
        uint48 _marketID,
        address _referral
    ) internal returns (uint256 index_) {
        index_ = notes[_user].length;
        notes[_user].push(
            Note({
                payout: governanceToken.balanceTo(_payout),
                created: uint48(block.timestamp),
                matured: _expiry,
                redeemed: 0,
                marketID: _marketID
            })
        );

        uint256 rewards = _giveRewards(_payout, _referral);

        treasury.mint(address(this), _payout + rewards);

        staking.stake(address(this), _payout, false, true);
    }


    function redeem(
        address _user,
        uint256[] memory _indexes,
        bool _sendGovernanceToken
    ) public override returns (uint256 payout_) {
        uint48 time = uint48(block.timestamp);

        for (uint256 i = 0; i < _indexes.length; i++) {
            (uint256 pay, bool matured) = pendingFor(_user, _indexes[i]);

            if (matured) {
                notes[_user][_indexes[i]].redeemed = time; // mark as redeemed
                payout_ += pay;
            }
        }

        if (_sendGovernanceToken) {
            governanceToken.transfer(_user, payout_); // send payout as governance token
        } else {
            staking.unwrap(_user, payout_); // unwrap and send payout as staking token
        }
    }

    function redeemAll(address _user, bool _sendGovernanceToken) external override returns (uint256) {
        return redeem(_user, indexesFor(_user), _sendGovernanceToken);
    }

    /* ========== TRANSFER ========== */

    function pushNote(address _to, uint256 _index) external override {
        require(notes[msg.sender][_index].created != 0, "Depository: note not found");
        noteTransfers[msg.sender][_index] = _to;
    }

    function pullNote(address _from, uint256 _index) external override returns (uint256 newIndex_) {
        require(noteTransfers[_from][_index] == msg.sender, "Depository: transfer not found");
        require(notes[_from][_index].redeemed == 0, "Depository: note redeemed");

        newIndex_ = notes[msg.sender].length;
        notes[msg.sender].push(notes[_from][_index]);

        delete notes[_from][_index];
    }

    /* ========== VIEW ========== */

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

    function pendingFor(address _user, uint256 _index) public view override returns (uint256 payout_, bool matured_) {
        Note memory note = notes[_user][_index];
        payout_ = note.payout;
        matured_ = note.redeemed == 0 && note.matured <= block.timestamp && note.payout != 0;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IBondDepository {

    // Info about each type of market
    struct Market {
        uint256 capacity; //capacity remaining
        IERC20 quoteToken; //token to accept as payment
        bool capacityInQuote; //capacity limit is in payment token (true) or in MainToken (false, default)
        uint64 totalDebt; // total debt from market
        uint64 maxPayout; // max tokens in/out (determined by capacityInQuote false/true, respectively)
        uint64 sold; // base token out
        uint256 purchased; // quote token in
    }

    // Info for creating new markets
    struct Terms {
        bool fixedTerm; // fixed term or fixed expiration
        uint64 controlVariable;  // scaling variable for price
        uint48 vesting;  // length of time from deposit to maturity if fixed-term
        uint48 conclusion; // timestamp when market no longer offered
        uint64 maxDebt; // 9 decimal debt maximum in MainToken
    }

    struct Metadata {
        uint48 lastTune; // last timestamp when control variable was tuned
        uint48 lastDecay; // last timestamp when market was created and debt was decayed
        uint48 length; // time from creation to conclusion. used as speed to decay debt
        uint48 depositInterval; // target frequency of deposits
        uint48 tuneInterval; // frequency of tuning
        uint8 quoteDecimals; // target frequency of deposits
    }

    // Control variable adjustment data
    struct Adjustment {
        uint64 change;
        uint48 lastAdjustment;
        uint48 timeToAdjusted;
        bool active;
    }

    function deposit(
        uint256 _bid,
        uint256 _amount,
        uint256 _maxPrice,
        address _user,
        address _referral
    ) external returns (
        uint256 payout_,
        uint256 expiry_,
        uint256 index_
    );

    function create(
        IERC20 _quoteToken, // token used to deposit
        uint256[3] memory _market, // [capacity, initial price]
        bool[2] memory _booleans, // [capacity in quote, fixed term]
        uint256[2] memory _terms, // [vesting, conclusion]
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
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

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
pragma solidity ^0.8.10;

import "./AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

abstract contract FrontEndRewarder is AccessControl {
    /* ========= STATE VARIABLES ========== */

    uint256 public daoReward; // % reward for dao (3 decimals: 100 = 1%)
    uint256 public refReward; // % reward for referer (3 decimals : 100 = 1%)
    mapping(address => uint256) public rewards;
    mapping(address => bool) public whitelisted;

    IERC20 internal mainToken;

    constructor(IAuthority _authority, IERC20 _mainToken) AccessControl(_authority) {
        mainToken = _mainToken;
    }

    /* ========= EXTERNAL FUNCTIONS ========== */

    // Pay reward to front end operator
    function getReward() external {
        uint256 reward = rewards[msg.sender];
        rewards[msg.sender] = 0;
        mainToken.transfer(msg.sender, reward);
    }

    /* ========= INTERNAL ========== */

    function _giveRewards(uint256 _payout, address _referral) internal returns (uint256) {
        uint256 toDAO = (_payout * daoReward) / 1e4;
        uint256 toRef = (_payout * refReward) / 1e4;

        if (whitelisted[_referral]) {
            rewards[_referral] += toRef;
            rewards[authority.guardian()] += toDAO;
        } else {
            rewards[authority.guardian()] += toDAO + toRef;
        }
        return toDAO + toRef;
    }

    function setRewards(uint256 _toFrontEnd, uint256 _toDAO) external onlyGovernor {
        refReward = _toFrontEnd;
        daoReward = _toDAO;
    }

    function whitelist(address _operator) external onlyPolicy {
        whitelisted[_operator] = !whitelisted[_operator];
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IGovernanceToken is IERC20 {
    function mint(address _to, uint256 _amount) external;

    function burn(address _from, uint256 _amount) external;

    function index() external view returns (uint256);

    function balanceFrom(uint256 _amount) external view returns (uint256);

    function balanceTo(uint256 _amount) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IStaking {
    function stake(address _to, uint256 _amount, bool _rebasing, bool _claim) external returns (uint256);

    function claim(address _recipient, bool _rebasing) external returns (uint256);

    function forfeit() external returns (uint256);

    function toggleLock() external;

    function unstake(address _to, uint256 _amount, bool _trigger, bool _rebasing) external returns (uint256);

    function wrap(address _to, uint256 _amount) external returns (uint256 gBalance_);

    function unwrap(address _to, uint256 _amount) external returns (uint256 sBalance_);

    function rebase() external;

    function index() external view returns (uint256);

    function contractBalance() external view returns (uint256);

    function totalStaked() external view returns (uint256);

    function supplyInWarmup() external view returns (uint256);

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface ITreasury {
    function deposit(uint256 _amount, address _token, uint256 _profit) external returns (uint256);

    function withdraw(uint256 _amount, address _token) external;

    function tokenValue(address _token, uint256 _amount) external view returns (uint256 value_);

    function mint(address _recipient, uint256 _amount) external;

    function manage(address _token, uint256 _amount) external;

    function incurDebt(uint256 _amount, address token) external;

    function repayDebtWithReserve(uint256 _amount, address _token) external;

    function excessReserves() external view returns (uint256);

    function baseSupply() external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface INoteKeeper {
    // Info for market note
    struct Note {
        uint256 payout; // GovernanceToken remaining to be paid
        uint48 created; // time market was created
        uint48 matured; // timestamp when market is matured
        uint48 redeemed; // time market was redeemed
        uint48 marketID; // market ID of deposit. uint48 to avoid adding a slot.
    }

    function redeem(
        
        address _user,
        uint256[] memory _indexes,
        bool _sendGovernanceToken
    ) external returns (uint256);

    function redeemAll(address _user, bool _sendGovernanceToken) external returns (uint256);

    function pushNote(address to, uint256 index) external;

    function pullNote(address from, uint256 index) external returns (uint256 newIndex_);

    function indexesFor(address _user) external view returns (uint256[] memory);

    function pendingFor(address _user, uint256 _index) external view returns (uint256 payout_, bool matured_);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/utils/Context.sol";
import "../interface/IAuthority.sol";

abstract contract AccessControl is Context {

    /* ========== EVENTS ========== */

    event AuthorityUpdated(IAuthority _newAuthority);

    string UNAUTHORIZED;
    
    /* ========== STATE VARIABLES ========== */
    
    IAuthority public authority;

    /* ========== CONSTRUCTOR/INITIALIZER ========== */

    constructor (IAuthority _authority)  {
        authority = _authority;
        UNAUTHORIZED = "UNAUTHORIZED";
        emit AuthorityUpdated(authority);
    }

    /* ========== MODIFIERS ========== */

    modifier onlyGovernor() {
        require(msg.sender == authority.governor(), UNAUTHORIZED);
        _;
    }

    modifier onlyNewGovernor() {
        require(msg.sender == authority.newGovernor(), UNAUTHORIZED);
        _;
    }

    modifier onlyVault() {
        require(msg.sender == authority.vault(), UNAUTHORIZED);
        _;
    }

    modifier onlyNewVault() {
        require(msg.sender == authority.newVault(), UNAUTHORIZED);
        _;
    }

    modifier onlyGuardian() {
        require(msg.sender == authority.guardian(), UNAUTHORIZED);
        _;
    }

    modifier onlyNewGuardian() {
        require(msg.sender == authority.newGuardian(), UNAUTHORIZED);
        _;
    }

    modifier onlyPolicy() {
        require(msg.sender == authority.policy(), UNAUTHORIZED);
        _;
    }

    modifier onlyNewPolicy() {
        require(msg.sender == authority.newPolicy(), UNAUTHORIZED);
        _;
    }

    modifier onlyGovernorGuardian() {
        require(msg.sender == authority.newGovernor(), UNAUTHORIZED);
        _;
    }

    modifier onlyAuthority() {
        require(
            msg.sender == authority.governor() ||
            msg.sender == authority.guardian() ||
            msg.sender == authority.policy(), UNAUTHORIZED
        );
        _;
    }

    /* ========== GOV ONLY ========== */

     function setAuthority(IAuthority _newAuthority) external onlyGovernor {
        authority = _newAuthority;
        emit AuthorityUpdated(_newAuthority);
    }
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
pragma solidity ^0.8.4;

interface IAuthority {
    /* ========== EVENTS ========== */

    event GovernorPushed(address indexed _from, address indexed _to, bool _effectiveImmediately);
    
    event VaultPushed(address indexed _from, address indexed _to, bool _effectiveImmediately);

    event GuardianPushed(address indexed _from, address indexed _to, bool _effectiveImmediately);

    event PolicyPushed(address indexed _from, address indexed _to, bool _effectiveImmediately);
    
    event GovernorPulled(address indexed _from, address indexed _to);
      
    event VaultPulled(address indexed _from, address indexed _to);

    event GuardianPulled(address indexed _from, address indexed _to);

    event PolicyPulled(address indexed _from, address indexed _to);

    /* ========== VIEW ========== */

    function governor() external view returns (address);

    function guardian() external view returns (address);

    function vault() external view returns (address);

    function policy() external view returns (address);

    function newGovernor() external view returns (address);

    function newGuardian() external view returns (address);

    function newVault() external view returns (address);

    function newPolicy() external view returns (address);
}