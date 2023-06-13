// SPDX-Licence-Identifier: MIT
pragma solidity 0.8.19;

import {IBetEngine} from "./interfaces/IBetEngine.sol";
import {OracleLib} from "./libs/OracleLib.sol";
import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";

/*
* @title BetEngine
* @author Shahzad Mughal (Haltoshi)
*
* The BetEngine is a contract that allows users to create bets, join bets,
* and settle bets.
* The BetEngine uses Chainlink Oracles to check the price of BTC/USD.
* The BetEngine uses USDC as the deposit token.
* One single betting asset (BTC) is used for all bets.
* 1:1 bets are supported. (Long/Short)
*
* @notice This contract is used to create and manage bets.
*/
contract BetEngine is IBetEngine, ReentrancyGuard {
    ///////////////////
    // Errors
    ///////////////////
    error BetEngine__AddressZero();
    error BetEngine__NeedsMoreThanZero();
    error BetEngine__BetNotActive();
    error BetEngine__BetNotClosed();
    error BetEngine__BetNotPending();
    error BetEngine__BetExpired();
    error BetEngine__BetDoesNotExist();
    error BetEngine__CannotJoinSamePosition();
    error BetEngine__CannotJoinOwnBet();
    error BetEngine__CannotJoinBetTwice();
    error BetEngine__BetAmountsMustBeEqual();
    error BetEngine__OnlyWinnerCanWithdraw();
    error BetEngine__OnlyCreatorCanCancel();
    error BetEngine__UserHasNoBet();
    error BetEngine__BetNotSettled();

    ///////////////////
    // Types
    ///////////////////
    using OracleLib for AggregatorV3Interface;

    /////////////////////////////////////////
    // Contants/Immutables & State Variables
    /////////////////////////////////////////
    uint256 private constant PRECISION = 1e18;
    address public immutable usdcDepositToken;
    AggregatorV3Interface public immutable btcusdpriceFeed;

    uint256 private betId;

    /// @dev Mapping of betId to Bet struct
    mapping(uint256 betId => Bet bet) public bets;

    /// @dev Mapping of user to betId to amount
    mapping(address user => mapping(uint256 betId => uint256 amount)) public userBets;

    ///////////////////
    // Modifiers
    ///////////////////
    modifier moreThanZero(uint256 amount) {
        if (amount == 0) {
            revert BetEngine__NeedsMoreThanZero();
        }
        _;
    }

    ///////////////////
    // Functions
    ///////////////////
    constructor(address usdcDepositTokenAddress, address btcusdPriceFeedAddress) {
        if (usdcDepositTokenAddress == address(0)) {
            revert BetEngine__AddressZero();
        }
        if (btcusdPriceFeedAddress == address(0)) {
            revert BetEngine__AddressZero();
        }
        usdcDepositToken = usdcDepositTokenAddress;
        btcusdpriceFeed = AggregatorV3Interface(btcusdPriceFeedAddress);
    }

    /// @inheritdoc IBetEngine
    function openBet(uint256 _amount, Position _position, Expiration _expiration, ClosingTime _closingTime)
        external
        override
        moreThanZero(_amount)
        returns (uint256)
    {
        uint256 _betId = betId++;
        Bet memory bet = Bet(
            _betId,
            _amount,
            block.timestamp,
            0,
            _position,
            _expiration,
            _closingTime,
            Status.PENDING,
            msg.sender,
            address(0),
            address(0)
        );
        bets[_betId] = bet;
        userBets[msg.sender][_betId] = _amount;
        bool success = IERC20(usdcDepositToken).transferFrom(msg.sender, address(this), _amount);
        require(success, "BetEngine: failed to transfer USDC");
        emit BetPending(_betId);
        return _betId;
    }

    /// @inheritdoc IBetEngine
    function joinBet(uint256 _betId, uint256 _amount, Position _position) external override moreThanZero(_amount) {
        Bet storage bet = bets[_betId];

        if (bets[_betId].creator == address(0)) revert BetEngine__BetDoesNotExist();
        if (betExpired(_betId)) revert BetEngine__BetExpired();
        if (bet.creatorPosition == _position) {
            revert BetEngine__CannotJoinSamePosition();
        }
        if (bet.status != Status.PENDING) revert BetEngine__BetNotPending();
        if (bet.creator == msg.sender) revert BetEngine__CannotJoinOwnBet();
        if (userBets[msg.sender][_betId] != 0) {
            revert BetEngine__CannotJoinBetTwice();
        }
        if (bet.amount != _amount) revert BetEngine__BetAmountsMustBeEqual();

        userBets[msg.sender][_betId] = _amount;
        //bet.amount += _amount;
        bet.status = Status.ACTIVE;
        bet.joiner = msg.sender;
        bet.openingPrice = getBtcUsdPrice();
        bool success = IERC20(usdcDepositToken).transferFrom(msg.sender, address(this), _amount);
        require(success, "BetEngine: failed to transfer USDC");
        emit BetActive(_betId);
    }

    /// @inheritdoc IBetEngine
    function settleBet(uint256 _betId) external override {
        if (!betClosed(_betId)) revert BetEngine__BetNotClosed();
        Bet storage bet = bets[_betId];
        if (bet.status != Status.ACTIVE) revert BetEngine__BetNotActive();

        uint256 closingPrice = getBtcUsdPrice();
        address winner;

        if (
            (bet.creatorPosition == Position.LONG && closingPrice >= bet.openingPrice)
                || (bet.creatorPosition != Position.LONG && closingPrice <= bet.openingPrice)
        ) {
            // creator wins
            winner = bet.creator;
        } else {
            // joiner wins
            winner = bet.joiner;
        }

        uint256 winningAmount = bet.amount + userBets[bet.joiner][_betId];
        userBets[bet.creator][_betId] = 0;
        userBets[bet.joiner][_betId] = 0;
        userBets[winner][_betId] = winningAmount;

        bet.winner = winner;
        bet.status = Status.CLOSED;
        emit BetSettled(_betId, winner);
    }

    /// @inheritdoc IBetEngine
    function withdraw(uint256 _betId) external override nonReentrant {
        Bet storage bet = bets[_betId];

        if (bet.creator == address(0)) revert BetEngine__BetDoesNotExist();
        if (bet.winner == address(0)) revert BetEngine__BetNotSettled();
        if (bet.winner != msg.sender) revert BetEngine__OnlyWinnerCanWithdraw();
        if (bet.status != Status.CLOSED) revert BetEngine__BetNotClosed();
        if (userBets[msg.sender][_betId] == 0) revert BetEngine__UserHasNoBet();

        uint256 amount = userBets[msg.sender][_betId];
        userBets[msg.sender][_betId] = 0;
        bool success = IERC20(usdcDepositToken).transfer(msg.sender, amount);
        require(success, "BetEngine: failed to transfer USDC");
    }

    /// @inheritdoc IBetEngine
    function cancelBeforeActive(uint256 _betId) external override nonReentrant {
        Bet storage bet = bets[_betId];

        if (bet.creator == address(0)) revert BetEngine__BetDoesNotExist();
        if (bet.status != Status.PENDING) revert BetEngine__BetNotPending();
        if (bet.creator != msg.sender) revert BetEngine__OnlyCreatorCanCancel();
        if (userBets[msg.sender][_betId] == 0) revert BetEngine__UserHasNoBet();

        uint256 amount = userBets[msg.sender][_betId];
        userBets[msg.sender][_betId] = 0;
        delete bets[_betId];
        bool success = IERC20(usdcDepositToken).transfer(msg.sender, amount);
        require(success, "BetEngine: failed to transfer USDC");
    }

    function betExpired(uint256 _betId) public view returns (bool) {
        return block.timestamp >= _getBetExpirationTime(_betId);
    }

    function betClosed(uint256 _betId) public view returns (bool) {
        return block.timestamp >= _getBetClosingTime(_betId);
    }

    ///////////////////////////////
    // Private & Internal Functions
    ///////////////////////////////

    function _getBetExpirationTime(uint256 _betId) internal view returns (uint256) {
        Bet storage bet = bets[_betId];
        if (bet.expiration == Expiration.ONE_DAY) {
            return bet.creationTime + 1 days;
        } else if (bet.expiration == Expiration.ONE_WEEK) {
            return bet.creationTime + 1 weeks;
        } else if (bet.expiration == Expiration.TWO_WEEKS) {
            return bet.creationTime + 2 weeks;
        }
    }

    function _getBetClosingTime(uint256 _betId) internal view returns (uint256) {
        Bet storage bet = bets[_betId];
        if (bet.closingTime == ClosingTime.THIRTY_DAYS) {
            return bet.creationTime + 30 days;
        } else if (bet.closingTime == ClosingTime.SIXTY_DAYS) {
            return bet.creationTime + 60 days;
        } else if (bet.closingTime == ClosingTime.NINETY_DAYS) {
            return bet.creationTime + 90 days;
        }
    }

    ////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////
    // External & Public View & Pure Functions
    ////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////

    /// @inheritdoc IBetEngine
    function getBet(uint256 _betId) external view override returns (Bet memory) {
        if (bets[_betId].creator == address(0)) revert BetEngine__BetDoesNotExist();
        return bets[_betId];
    }

    /// @dev Returns the price of BTC in USD with 18 decimals
    function getBtcUsdPrice() public view returns (uint256) {
        (, int256 price,,,) = btcusdpriceFeed.staleCheckLatestRoundData();
        return uint256(price) * PRECISION / 10 ** btcusdpriceFeed.decimals();
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

interface IBetEngine {
    event BetActive(uint256 indexed betId);
    event BetPending(uint256 indexed betId);
    event BetSettled(uint256 indexed betId, address indexed winner);

    enum Position {
        LONG,
        SHORT
    }

    enum Status {
        PENDING,
        ACTIVE,
        CLOSED
    }

    enum Expiration {
        ONE_DAY,
        ONE_WEEK,
        TWO_WEEKS
    }

    enum ClosingTime {
        THIRTY_DAYS,
        SIXTY_DAYS,
        NINETY_DAYS
    }

    struct Bet {
        uint256 betId;
        uint256 amount;
        uint256 creationTime;
        uint256 openingPrice;
        Position creatorPosition;
        Expiration expiration;
        ClosingTime closingTime;
        Status status;
        address creator;
        address joiner;
        address winner;
    }

    /**
     * @notice Opens a new bet
     * @param _amount Amount of USDC to bet
     * @param _position Position of the bet
     * @param _expiration Expiration of the bet
     * @param _closingTime Closing time of the bet
     * @return betId of the new bet
     */
    function openBet(uint256 _amount, Position _position, Expiration _expiration, ClosingTime _closingTime)
        external
        returns (uint256 betId);

    /**
     * @notice Joins an existing bet
     * @param _betId Id of the bet to join
     * @param _amount Amount of USDC to bet
     * @param _position Position of the bet
     */
    function joinBet(uint256 _betId, uint256 _amount, Position _position) external;

    /**
     * @notice Settles an existing bet
     * @param _betId Id of the bet to settle
     */
    function settleBet(uint256 _betId) external;

    /**
     * @notice Withdraws winnings from a settled bet
     * @param _betId Id of the bet to withdraw from
     */
    function withdraw(uint256 _betId) external;

    /**
     * @notice Cancels a bet before it is joined
     * @param _betId Id of the bet to cancel
     */
    function cancelBeforeActive(uint256 _betId) external;

    /**
     * @notice Retrieves a bet by id
     * @param _betId Id of the bet
     */
    function getBet(uint256 _betId) external view returns (Bet memory);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

/*
 * @title OracleLib
 * @author Shahzad Mughal
 * @notice This library is used to check the Chainlink Oracle for stale data.
 * If a price is stale, functions will revert, and render the BetEngine unusable - this is by design.
 */
library OracleLib {
    error OracleLib__StalePrice();

    uint256 private constant TIMEOUT = 2 hours; // 2 * 60 * 60 = 7200 seconds

    function staleCheckLatestRoundData(AggregatorV3Interface chainlinkFeed)
        public
        view
        returns (uint80, int256, uint256, uint256, uint80)
    {
        (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound) =
            chainlinkFeed.latestRoundData();

        if (updatedAt == 0 || answeredInRound < roundId) {
            revert OracleLib__StalePrice();
        }
        uint256 secondsSince = block.timestamp - updatedAt;
        if (secondsSince > TIMEOUT) revert OracleLib__StalePrice();

        return (roundId, answer, startedAt, updatedAt, answeredInRound);
    }

    // TODO: fetch timout from chainlink feed
    function getTimeout(AggregatorV3Interface /* chainlinkFeed */ ) public pure returns (uint256) {
        return TIMEOUT;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorV3Interface {

  function decimals()
    external
    view
    returns (
      uint8
    );

  function description()
    external
    view
    returns (
      string memory
    );

  function version()
    external
    view
    returns (
      uint256
    );

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(
    uint80 _roundId
  )
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/IERC20.sol)

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
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (security/ReentrancyGuard.sol)

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

    /**
     * @dev Returns true if the reentrancy guard is currently set to "entered", which indicates there is a
     * `nonReentrant` function in the call stack.
     */
    function _reentrancyGuardEntered() internal view returns (bool) {
        return _status == _ENTERED;
    }
}