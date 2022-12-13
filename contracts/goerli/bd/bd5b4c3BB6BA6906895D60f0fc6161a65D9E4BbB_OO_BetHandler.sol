// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (security/ReentrancyGuard.sol)

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
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
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

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.0;

/**
 * @title Provides addresses of the live contracts implementing certain interfaces.
 * @dev Examples are the Oracle or Store interfaces.
 */
interface FinderInterface {
    /**
     * @notice Updates the address of the contract that implements `interfaceName`.
     * @param interfaceName bytes32 encoding of the interface name that is either changed or registered.
     * @param implementationAddress address of the deployed contract that implements the interface.
     */
    function changeImplementationAddress(bytes32 interfaceName, address implementationAddress) external;

    /**
     * @notice Gets the address of the contract that implements the given `interfaceName`.
     * @param interfaceName queried interface.
     * @return implementationAddress address of the deployed contract that implements the interface.
     */
    function getImplementationAddress(bytes32 interfaceName) external view returns (address);
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./FinderInterface.sol";

/**
 * @title Financial contract facing Oracle interface.
 * @dev Interface used by financial contracts to interact with the Oracle. Voters will use a different interface.
 */
abstract contract OptimisticOracleV2Interface {
    event RequestPrice(
        address indexed requester,
        bytes32 identifier,
        uint256 timestamp,
        bytes ancillaryData,
        address currency,
        uint256 reward,
        uint256 finalFee
    );
    event ProposePrice(
        address indexed requester,
        address indexed proposer,
        bytes32 identifier,
        uint256 timestamp,
        bytes ancillaryData,
        int256 proposedPrice,
        uint256 expirationTimestamp,
        address currency
    );
    event DisputePrice(
        address indexed requester,
        address indexed proposer,
        address indexed disputer,
        bytes32 identifier,
        uint256 timestamp,
        bytes ancillaryData,
        int256 proposedPrice
    );
    event Settle(
        address indexed requester,
        address indexed proposer,
        address indexed disputer,
        bytes32 identifier,
        uint256 timestamp,
        bytes ancillaryData,
        int256 price,
        uint256 payout
    );
    // Struct representing the state of a price request.
    enum State {
        Invalid, // Never requested.
        Requested, // Requested, no other actions taken.
        Proposed, // Proposed, but not expired or disputed yet.
        Expired, // Proposed, not disputed, past liveness.
        Disputed, // Disputed, but no DVM price returned yet.
        Resolved, // Disputed and DVM price is available.
        Settled // Final price has been set in the contract (can get here from Expired or Resolved).
    }

    struct RequestSettings {
        bool eventBased; // True if the request is set to be event-based.
        bool refundOnDispute; // True if the requester should be refunded their reward on dispute.
        bool callbackOnPriceProposed; // True if callbackOnPriceProposed callback is required.
        bool callbackOnPriceDisputed; // True if callbackOnPriceDisputed callback is required.
        bool callbackOnPriceSettled; // True if callbackOnPriceSettled callback is required.
        uint256 bond; // Bond that the proposer and disputer must pay on top of the final fee.
        uint256 customLiveness; // Custom liveness value set by the requester.
    }

    // Struct representing a price request.
    struct Request {
        address proposer; // Address of the proposer.
        address disputer; // Address of the disputer.
        IERC20 currency; // ERC20 token used to pay rewards and fees.
        bool settled; // True if the request is settled.
        RequestSettings requestSettings; // Custom settings associated with a request.
        int256 proposedPrice; // Price that the proposer submitted.
        int256 resolvedPrice; // Price resolved once the request is settled.
        uint256 expirationTime; // Time at which the request auto-settles without a dispute.
        uint256 reward; // Amount of the currency to pay to the proposer on settlement.
        uint256 finalFee; // Final fee to pay to the Store upon request to the DVM.
    }

    // This value must be <= the Voting contract's `ancillaryBytesLimit` value otherwise it is possible
    // that a price can be requested to this contract successfully, but cannot be disputed because the DVM refuses
    // to accept a price request made with ancillary data length over a certain size.
    uint256 public constant ancillaryBytesLimit = 8192;

    function defaultLiveness() external view virtual returns (uint256);

    function finder() external view virtual returns (FinderInterface);

    function getCurrentTime() external view virtual returns (uint256);

    // Note: this is required so that typechain generates a return value with named fields.
    mapping(bytes32 => Request) public requests;

    /**
     * @notice Requests a new price.
     * @param identifier price identifier being requested.
     * @param timestamp timestamp of the price being requested.
     * @param ancillaryData ancillary data representing additional args being passed with the price request.
     * @param currency ERC20 token used for payment of rewards and fees. Must be approved for use with the DVM.
     * @param reward reward offered to a successful proposer. Will be pulled from the caller. Note: this can be 0,
     *               which could make sense if the contract requests and proposes the value in the same call or
     *               provides its own reward system.
     * @return totalBond default bond (final fee) + final fee that the proposer and disputer will be required to pay.
     * This can be changed with a subsequent call to setBond().
     */
    function requestPrice(
        bytes32 identifier,
        uint256 timestamp,
        bytes memory ancillaryData,
        IERC20 currency,
        uint256 reward
    ) external virtual returns (uint256 totalBond);

    /**
     * @notice Set the proposal bond associated with a price request.
     * @param identifier price identifier to identify the existing request.
     * @param timestamp timestamp to identify the existing request.
     * @param ancillaryData ancillary data of the price being requested.
     * @param bond custom bond amount to set.
     * @return totalBond new bond + final fee that the proposer and disputer will be required to pay. This can be
     * changed again with a subsequent call to setBond().
     */
    function setBond(
        bytes32 identifier,
        uint256 timestamp,
        bytes memory ancillaryData,
        uint256 bond
    ) external virtual returns (uint256 totalBond);

    /**
     * @notice Sets the request to refund the reward if the proposal is disputed. This can help to "hedge" the caller
     * in the event of a dispute-caused delay. Note: in the event of a dispute, the winner still receives the other's
     * bond, so there is still profit to be made even if the reward is refunded.
     * @param identifier price identifier to identify the existing request.
     * @param timestamp timestamp to identify the existing request.
     * @param ancillaryData ancillary data of the price being requested.
     */
    function setRefundOnDispute(
        bytes32 identifier,
        uint256 timestamp,
        bytes memory ancillaryData
    ) external virtual;

    /**
     * @notice Sets a custom liveness value for the request. Liveness is the amount of time a proposal must wait before
     * being auto-resolved.
     * @param identifier price identifier to identify the existing request.
     * @param timestamp timestamp to identify the existing request.
     * @param ancillaryData ancillary data of the price being requested.
     * @param customLiveness new custom liveness.
     */
    function setCustomLiveness(
        bytes32 identifier,
        uint256 timestamp,
        bytes memory ancillaryData,
        uint256 customLiveness
    ) external virtual;

    /**
     * @notice Sets the request to be an "event-based" request.
     * @dev Calling this method has a few impacts on the request:
     *
     * 1. The timestamp at which the request is evaluated is the time of the proposal, not the timestamp associated
     *    with the request.
     *
     * 2. The proposer cannot propose the "too early" value (TOO_EARLY_RESPONSE). This is to ensure that a proposer who
     *    prematurely proposes a response loses their bond.
     *
     * 3. RefundoOnDispute is automatically set, meaning disputes trigger the reward to be automatically refunded to
     *    the requesting contract.
     *
     * @param identifier price identifier to identify the existing request.
     * @param timestamp timestamp to identify the existing request.
     * @param ancillaryData ancillary data of the price being requested.
     */
    function setEventBased(
        bytes32 identifier,
        uint256 timestamp,
        bytes memory ancillaryData
    ) external virtual;

    /**
     * @notice Sets which callbacks should be enabled for the request.
     * @param identifier price identifier to identify the existing request.
     * @param timestamp timestamp to identify the existing request.
     * @param ancillaryData ancillary data of the price being requested.
     * @param callbackOnPriceProposed whether to enable the callback onPriceProposed.
     * @param callbackOnPriceDisputed whether to enable the callback onPriceDisputed.
     * @param callbackOnPriceSettled whether to enable the callback onPriceSettled.
     */
    function setCallbacks(
        bytes32 identifier,
        uint256 timestamp,
        bytes memory ancillaryData,
        bool callbackOnPriceProposed,
        bool callbackOnPriceDisputed,
        bool callbackOnPriceSettled
    ) external virtual;

    /**
     * @notice Proposes a price value on another address' behalf. Note: this address will receive any rewards that come
     * from this proposal. However, any bonds are pulled from the caller.
     * @param proposer address to set as the proposer.
     * @param requester sender of the initial price request.
     * @param identifier price identifier to identify the existing request.
     * @param timestamp timestamp to identify the existing request.
     * @param ancillaryData ancillary data of the price being requested.
     * @param proposedPrice price being proposed.
     * @return totalBond the amount that's pulled from the caller's wallet as a bond. The bond will be returned to
     * the proposer once settled if the proposal is correct.
     */
    function proposePriceFor(
        address proposer,
        address requester,
        bytes32 identifier,
        uint256 timestamp,
        bytes memory ancillaryData,
        int256 proposedPrice
    ) public virtual returns (uint256 totalBond);

    /**
     * @notice Proposes a price value for an existing price request.
     * @param requester sender of the initial price request.
     * @param identifier price identifier to identify the existing request.
     * @param timestamp timestamp to identify the existing request.
     * @param ancillaryData ancillary data of the price being requested.
     * @param proposedPrice price being proposed.
     * @return totalBond the amount that's pulled from the proposer's wallet as a bond. The bond will be returned to
     * the proposer once settled if the proposal is correct.
     */
    function proposePrice(
        address requester,
        bytes32 identifier,
        uint256 timestamp,
        bytes memory ancillaryData,
        int256 proposedPrice
    ) external virtual returns (uint256 totalBond);

    /**
     * @notice Disputes a price request with an active proposal on another address' behalf. Note: this address will
     * receive any rewards that come from this dispute. However, any bonds are pulled from the caller.
     * @param disputer address to set as the disputer.
     * @param requester sender of the initial price request.
     * @param identifier price identifier to identify the existing request.
     * @param timestamp timestamp to identify the existing request.
     * @param ancillaryData ancillary data of the price being requested.
     * @return totalBond the amount that's pulled from the caller's wallet as a bond. The bond will be returned to
     * the disputer once settled if the dispute was value (the proposal was incorrect).
     */
    function disputePriceFor(
        address disputer,
        address requester,
        bytes32 identifier,
        uint256 timestamp,
        bytes memory ancillaryData
    ) public virtual returns (uint256 totalBond);

    /**
     * @notice Disputes a price value for an existing price request with an active proposal.
     * @param requester sender of the initial price request.
     * @param identifier price identifier to identify the existing request.
     * @param timestamp timestamp to identify the existing request.
     * @param ancillaryData ancillary data of the price being requested.
     * @return totalBond the amount that's pulled from the disputer's wallet as a bond. The bond will be returned to
     * the disputer once settled if the dispute was valid (the proposal was incorrect).
     */
    function disputePrice(
        address requester,
        bytes32 identifier,
        uint256 timestamp,
        bytes memory ancillaryData
    ) external virtual returns (uint256 totalBond);

    /**
     * @notice Retrieves a price that was previously requested by a caller. Reverts if the request is not settled
     * or settleable. Note: this method is not view so that this call may actually settle the price request if it
     * hasn't been settled.
     * @param identifier price identifier to identify the existing request.
     * @param timestamp timestamp to identify the existing request.
     * @param ancillaryData ancillary data of the price being requested.
     * @return resolved price.
     */
    function settleAndGetPrice(
        bytes32 identifier,
        uint256 timestamp,
        bytes memory ancillaryData
    ) external virtual returns (int256);

    /**
     * @notice Attempts to settle an outstanding price request. Will revert if it isn't settleable.
     * @param requester sender of the initial price request.
     * @param identifier price identifier to identify the existing request.
     * @param timestamp timestamp to identify the existing request.
     * @param ancillaryData ancillary data of the price being requested.
     * @return payout the amount that the "winner" (proposer or disputer) receives on settlement. This amount includes
     * the returned bonds as well as additional rewards.
     */
    function settle(
        address requester,
        bytes32 identifier,
        uint256 timestamp,
        bytes memory ancillaryData
    ) external virtual returns (uint256 payout);

    /**
     * @notice Gets the current data structure containing all information about a price request.
     * @param requester sender of the initial price request.
     * @param identifier price identifier to identify the existing request.
     * @param timestamp timestamp to identify the existing request.
     * @param ancillaryData ancillary data of the price being requested.
     * @return the Request data structure.
     */
    function getRequest(
        address requester,
        bytes32 identifier,
        uint256 timestamp,
        bytes memory ancillaryData
    ) public view virtual returns (Request memory);

    /**
     * @notice Returns the state of a price request.
     * @param requester sender of the initial price request.
     * @param identifier price identifier to identify the existing request.
     * @param timestamp timestamp to identify the existing request.
     * @param ancillaryData ancillary data of the price being requested.
     * @return the State enum value.
     */
    function getState(
        address requester,
        bytes32 identifier,
        uint256 timestamp,
        bytes memory ancillaryData
    ) public view virtual returns (State);

    /**
     * @notice Checks if a given request has resolved or been settled (i.e the optimistic oracle has a price).
     * @param requester sender of the initial price request.
     * @param identifier price identifier to identify the existing request.
     * @param timestamp timestamp to identify the existing request.
     * @param ancillaryData ancillary data of the price being requested.
     * @return true if price has resolved or settled, false otherwise.
     */
    function hasPrice(
        address requester,
        bytes32 identifier,
        uint256 timestamp,
        bytes memory ancillaryData
    ) public view virtual returns (bool);

    function stampAncillaryData(bytes memory ancillaryData, address requester)
        public
        view
        virtual
        returns (bytes memory);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;

import "@uma/core/contracts/oracle/interfaces/OptimisticOracleV2Interface.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract OO_BetHandler is ReentrancyGuard {
    // Create an Optimistic oracle instance at the deployed address on Görli.
    OptimisticOracleV2Interface oo =
        OptimisticOracleV2Interface(0xA5B9d8a0B0Fa04Ba71BDD68069661ED5C0848884);

    uint256 requestTime = 0; // Store the request time so we can re-use it later.
    bytes32 constant IDENTIFIER = bytes32("YES_OR_NO_QUERY"); // Use the yes no idetifier to ask arbitary questions, such as the weather on a particular day.
    address constant ZERO_ADDRESS = address(0);
    // 0x0000000000000000000000000000000000000000

    struct Bet {
        uint256 betId;
        bytes question;
        uint256 expiry;
        IERC20 bondCurrency;
        address creator;
        bool privateBet;
        uint256 liveness;
        uint256 reward;
        bytes imgUrl;
        BetStatus betStatus;
    }

    struct BetAmount {
        uint256 betId;
        address affirmation; // Address of the side of the bet that affirms the question.
        IERC20 affirmationToken;
        uint256 affirmationAmount; // Amount deposited into the bet by the affrimation.
        address negation; // Address of the side of the bet that negates the question.
        IERC20 negationToken;
        uint256 negationAmount; // Amount deposited into the bet by the negation.
    }

    enum BetStatus {
        LOADING,
        OPEN,
        ACTIVE,
        SETTLING,
        SETTLED,
        CLAIMED,
        DEAD
    }

    // ******** EVENTS ************

    event BetSet(
        address indexed creator,
        IERC20 indexed bondCurrency,
        bytes indexed ancillaryData,
        uint256 betId
    );

    event BetTaken(address indexed taker, uint256 indexed betId);

    event DataRequested(
        address indexed affirmation,
        address indexed negation,
        uint256 indexed betId
    );

    event BetSettled(
        address indexed affirmation,
        address indexed negation,
        uint256 indexed betId
    );

    event WinningsClaimed(
        uint256 indexed betId,
        uint256 indexed totalWinnings,
        int256 indexed winner
    );

    event BetCanceled(
        uint256 indexed betId,
        address indexed bondCurrency,
        uint256 indexed refundAmount
    );

    event BetKilled(
        uint256 indexed betId,
        uint256 indexed affirmationRefund,
        uint256 indexed negationRefund
    );

    uint256 public betId = 0; // latest global betId for all managed bets.
    mapping(uint256 => Bet) public bets; // All bets mapped by their betId
    mapping(bytes => uint256) public hashIds; // A hash of bet question, msg.sender, and timestamp to betId
    mapping(uint256 => BetAmount) public betAmounts; // All bet amounts mapped by their betId.
    mapping(address => uint256[]) public userBets; // All bets the user is and has participated in.

    // ********* MUTATIVE FUNCTIONS *************

    function setBet(
        bytes calldata _question,
        uint256 _expiry,
        IERC20 _bondCurrency,
        uint256 _liveness,
        uint256 _reward,
        bool _privateBet,
        bytes calldata _imgUrl
    ) public nonReentrant {
        Bet memory bet = Bet(
            betId,
            _question,
            _expiry,
            _bondCurrency,
            msg.sender,
            _privateBet,
            _liveness,
            _reward,
            _imgUrl,
            BetStatus.LOADING
        );

        bytes memory hashId = abi.encode(
            _question,
            msg.sender,
            block.timestamp
        );

        emit BetSet(msg.sender, _bondCurrency, _question, betId);

        bets[betId] = bet;
        hashIds[hashId] = betId;
        userBets[msg.sender].push(betId);
        betId += 1;
    }

    function loadBet(
        uint256 _betId,
        address _affirmation,
        IERC20 _affirmationToken,
        uint256 _affirmationAmount,
        address _negation,
        IERC20 _negationToken,
        uint256 _negationAmount
    ) public nonReentrant {
        Bet storage bet = bets[_betId];
        require(msg.sender == bet.creator, "not creator");
        require(
            bet.creator == _affirmation || bet.creator == _negation,
            "must be participant"
        );
        require(_affirmation != _negation, "must have 2 parties");
        require(bet.betStatus == BetStatus.LOADING, "not loading");

        BetAmount memory betAmount = BetAmount(
            _betId,
            _affirmation,
            _affirmationToken,
            _affirmationAmount,
            _negation,
            _negationToken,
            _negationAmount
        );

        // Make sure to approve this contract to spend your ERC20 externally first
        if (msg.sender == _affirmation) {
            _affirmationToken.transferFrom(
                msg.sender,
                address(this),
                _affirmationAmount
            );
        } else if (msg.sender == _negation) {
            _negationToken.transferFrom(
                msg.sender,
                address(this),
                _negationAmount
            );
        }

        betAmounts[_betId] = betAmount;
        bet.betStatus = BetStatus.OPEN;
    }

    function takeBet(uint256 _betId) public nonReentrant {
        Bet storage bet = bets[_betId];
        BetAmount storage betAmount = betAmounts[_betId];
        require(msg.sender != bet.creator, "Can't take your own bet");
        if (bet.privateBet == false) {
            require(
                betAmount.affirmation == ZERO_ADDRESS ||
                    betAmount.negation == ZERO_ADDRESS,
                "Bet already taken"
            );
        } else {
            require(
                msg.sender == betAmount.affirmation ||
                    msg.sender == betAmount.negation,
                "Not bet recipient"
            );
        }
        require(bet.betStatus == BetStatus.OPEN, "not Open");

        if (betAmount.affirmation == ZERO_ADDRESS) {
            // Make sure to approve this contract to spend your ERC20 externally first
            bet.bondCurrency.transferFrom(
                msg.sender,
                address(this),
                betAmount.affirmationAmount
            );
            betAmount.affirmation = msg.sender;
        } else {
            // Make sure to approve this contract to spend your ERC20 externally first
            bet.bondCurrency.transferFrom(
                msg.sender,
                address(this),
                betAmount.negationAmount
            );
            betAmount.negation = msg.sender;
        }

        userBets[msg.sender].push(_betId);
        bet.betStatus = BetStatus.ACTIVE;

        emit BetTaken(msg.sender, _betId);
    }

    function requestData(uint256 _betId) public {
        Bet storage bet = bets[_betId];
        BetAmount storage betAmount = betAmounts[_betId];
        require(
            bet.betStatus == BetStatus.ACTIVE,
            "Bet not ready to be settled"
        );
        require(
            betAmount.affirmation == msg.sender ||
                betAmount.negation == msg.sender
        );

        bytes memory ancillaryData = bet.question; // Question to ask the UMA Oracle.

        requestTime = block.timestamp; // Set the request time to the current block time.
        IERC20 bondCurrency = IERC20(bet.bondCurrency); // Use preferred token as the bond currency.
        uint256 reward = bet.reward; // Set the reward amount for UMA Oracle.

        // Set liveness for request disputes measured in seconds. Recommended time is at least 7200 (2 hours).
        // Users should increase liveness time depending on various factors such as amount of funds being handled
        // and risk of malicious acts.
        uint256 liveness = bet.liveness;

        // Now, make the price request to the Optimistic oracle with preferred inputs.
        oo.requestPrice(
            IDENTIFIER,
            requestTime,
            ancillaryData,
            bondCurrency,
            reward
        );
        oo.setCustomLiveness(IDENTIFIER, requestTime, ancillaryData, liveness);

        bet.betStatus = BetStatus.SETTLING;
        emit DataRequested(
            betAmount.affirmation,
            betAmount.negation,
            betAmount.betId
        );
    }

    // Settle the request once it's gone through the liveness period of 30 seconds. This acts the finalize the voted on price.
    // In a real world use of the Optimistic Oracle this should be longer to give time to disputers to catch bat price proposals.
    function settleRequest(uint256 _betId) public {
        Bet storage bet = bets[_betId];
        BetAmount storage betAmount = betAmounts[_betId];
        require(bet.betStatus == BetStatus.SETTLING, "Bet not settling");
        require(
            betAmount.affirmation == msg.sender ||
                betAmount.negation == msg.sender
        );

        bytes memory ancillaryData = bet.question;

        oo.settle(address(this), IDENTIFIER, requestTime, ancillaryData);
        bet.betStatus = BetStatus.SETTLED;

        emit BetSettled(
            betAmount.affirmation,
            betAmount.negation,
            betAmount.betId
        );
    }

    function claimWinnings(uint256 _betId) public nonReentrant {
        Bet storage bet = bets[_betId];
        BetAmount storage betAmount = betAmounts[_betId];
        uint256 totalWinnings = betAmount.affirmationAmount +
            betAmount.negationAmount;
        int256 settlementData = getSettledData(_betId);
        require(bet.betStatus == BetStatus.SETTLED, "Bet not yet settled");
        require(
            msg.sender == betAmount.affirmation ||
                msg.sender == betAmount.negation,
            "This is not your bet"
        );
        require(
            settlementData == 1e18 || settlementData == 0,
            "Invalid settlement"
        );
        if (settlementData == 1e18) {
            require(
                msg.sender == betAmount.affirmation,
                "Negation did not win bet"
            );
            bet.bondCurrency.transfer(betAmount.affirmation, totalWinnings);
        } else {
            require(
                msg.sender == betAmount.negation,
                "Affirmation did not win bet"
            );
            bet.bondCurrency.transfer(betAmount.negation, totalWinnings);
        }

        bet.betStatus = BetStatus.CLAIMED;

        emit WinningsClaimed(bet.betId, totalWinnings, settlementData);
    }

    function cancelBet(uint256 _betId) public nonReentrant {
        Bet storage bet = bets[_betId];
        BetAmount storage betAmount = betAmounts[_betId];
        uint256 refundAmount;
        require(
            bet.betStatus == BetStatus.LOADING ||
                bet.betStatus == BetStatus.OPEN,
            "Bet already active"
        );
        require(msg.sender == bet.creator, "Not bet creator");

        if (bet.creator == betAmount.affirmation) {
            refundAmount = betAmount.affirmationAmount;
        } else {
            refundAmount = betAmount.negationAmount;
        }

        bet.bondCurrency.transfer(bet.creator, refundAmount);

        emit BetCanceled(bet.betId, address(bet.bondCurrency), refundAmount);
    }

    function killBet(uint256 _betId) public nonReentrant {
        Bet storage bet = bets[_betId];
        BetAmount storage betAmount = betAmounts[_betId];
        int256 settlementData = getSettledData(_betId);
        require(bet.betStatus == BetStatus.SETTLED, "Bet not yet settled");
        require(
            msg.sender == betAmount.affirmation ||
                msg.sender == betAmount.negation,
            "This is not your bet"
        );
        require(settlementData == 2 * 1e18, "Bet is settleable");
        bet.bondCurrency.transfer(
            betAmount.affirmation,
            betAmount.affirmationAmount
        );
        bet.bondCurrency.transfer(betAmount.negation, betAmount.negationAmount);

        bet.betStatus = BetStatus.DEAD;

        emit BetKilled(
            betAmount.betId,
            betAmount.affirmationAmount,
            betAmount.negationAmount
        );
    }

    //******* VIEW FUNCTIONS ***********
    function createQuestion(string memory _question)
        public
        pure
        returns (bytes memory)
    {
        bytes memory question = bytes(
            string.concat(
                "Q: ",
                _question,
                "? --- A:1 for yes. 0 for no. 2 for ambiguous/unknowable"
            )
        );
        return question;
    }

    // Fetch the resolved price from the Optimistic Oracle that was settled.
    function getSettledData(uint256 _betId) public view returns (int256) {
        Bet storage bet = bets[_betId];
        BetAmount storage betAmount = betAmounts[_betId];
        require(
            betAmount.affirmation == msg.sender ||
                betAmount.negation == msg.sender
        );

        return
            oo
                .getRequest(
                    address(this),
                    IDENTIFIER,
                    requestTime,
                    bet.question
                )
                .resolvedPrice;
    }

    function getHashId(bytes calldata _question, uint256 timestamp)
        public
        view
        returns (bytes memory)
    {
        return abi.encode(_question, msg.sender, timestamp);
    }

    function stringEncode(string calldata _string)
        public
        pure
        returns (bytes memory)
    {
        return bytes(_string);
    }

    function stringDecode(bytes calldata _bytes)
        public
        pure
        returns (string memory)
    {
        return string(_bytes);
    }
}