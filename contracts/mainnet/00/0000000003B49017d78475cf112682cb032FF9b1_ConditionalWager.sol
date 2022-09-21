//SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "./BartrrBase.sol";

error Uninitialized();
error WagerAlreadyClosed();
error WagerAlreadyFilled();
error UserAlreadyRefunded();
error WagerNotFilled();
error InvalidValue();
error InvalidDuration();
error InvalidPrices();
error UnauthorizedSender();
error WagerIncomplete();
error WagerExpired();
error TokenNotApproved();
error TransferFailed();
error SelfWager();
error RestrictedP2P();

/// @title Bartrr Conditional Wager Contract
/// @notice This contract is used to manage conditional wagers for the Bartrr protocol.
contract ConditionalWager is BartrrBase {
    using SafeERC20 for IERC20;
    struct Wager {
        bool isFilled; // true if wager is filled
        bool isClosed; // true if the wager has been closed (redeemed or cancelled)
        address userA; // address of userA
        address userB; // address of userB (0x0 if p2m)
        address wagerToken; // token to be used for wager
        address paymentToken; // payment token is the token that is used to pay the wager
        int256 wagerPriceA; // UserA bet price
        int256 wagerPriceB; // UserB bet price
        uint256 amountUserA; // amount userA wagered
        uint256 amountUserB; // amount userB wagered
        uint256 duration; // duration of the wager
    }

    /// Array of wagers
    Wager[] public wagers;

    /// @notice Emitted when a wager is created
    /// @param wagerId The wager id
    /// @param userA The user who created the wager
    /// @param userB The user who will fill the wager (zero address if the wager is open for anyone to fill)
    /// @param wagerPriceA The wagered price of wagerToken by userA
    /// @param wagerPriceB The wagered price of wagerToken by userB
    event WagerCreated(
        uint256 indexed wagerId,
        address indexed userA,
        address userB,
        address wagerToken,
        int256 wagerPriceA,
        int256 wagerPriceB
    );

    /// @notice Emitted when a wager is filled by the second party
    /// @param wagerId The wager id
    /// @param userA The user who created the wager
    /// @param userB The user who filled the wager
    /// @param wagerToken The token whose price was wagered
    /// @param wagerPriceA The wagered price of wagerToken by userA
    /// @param wagerPriceB The wagered price of wagerToken by userB
    event WagerFilled(
        uint256 indexed wagerId,
        address indexed userA,
        address indexed userB,
        address wagerToken,
        int256 wagerPriceA,
        int256 wagerPriceB
    );

    constructor() {
        _transferOwnership(tx.origin);
    }

    /// @notice Creates a new wager
    /// @param _userB address of userB (0x0 if p2m)
    /// @param _wagerToken address of token to be wagered on
    /// @param _paymentToken address of token to be paid with
    /// @param _wagerPriceA UserA bet price -- USD price + 8 decimals
    /// @param _wagerPriceB UserB bet price -- USD price + 8 decimals
    /// @param _amountUserA amount userA wagered
    /// @param _amountUserB amount userB wagered
    /// @param _duration duration of the wager
    function createWager(
        address _userB,
        address _wagerToken,
        address _paymentToken, // Zero address if ETH
        int256 _wagerPriceA,
        int256 _wagerPriceB,
        uint256 _amountUserA,
        uint256 _amountUserB,
        uint256 _duration
    ) external payable nonReentrant {
        if (!isInitialized) revert Uninitialized();
        if (
            !wagerTokens[_wagerToken] ||
            refundableTimestamp[_wagerToken].nonrefundable <
            refundableTimestamp[_wagerToken].refundable
        ) {
            revert TokenNotApproved();
        }
        if (!paymentTokens[_paymentToken]) revert TokenNotApproved();
        if (_duration < MIN_WAGER_DURATION) revert InvalidDuration();
        if (_userB == msg.sender) revert SelfWager();
        if (_wagerPriceA == _wagerPriceB) revert InvalidPrices();

        uint256 feeUserA = _calculateFee(_amountUserA, _paymentToken);

        if (
            _paymentToken == address(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)
        ) {
            // ETH
            if (msg.value != _amountUserA) revert InvalidValue();
            if (_userB == address(0)) {
                // p2m
                _amountUserA = _amountUserA - feeUserA;
                _transfer(payable(feeAddress), feeUserA);
            }
        } else {
            // Tokens
            uint256 balanceBefore = IERC20(_paymentToken).balanceOf(
                address(this)
            );

            IERC20(_paymentToken).safeTransferFrom(
                msg.sender,
                address(this),
                _amountUserA
            );

            if (_userB == address(0)) {
                // p2m - userA fees paid immediately
                IERC20(_paymentToken).safeTransfer(feeAddress, feeUserA);
            }
            uint256 balanceAfter = IERC20(_paymentToken).balanceOf(
                address(this)
            );

            _amountUserA = balanceAfter - balanceBefore;
        }

        _createWager(
            msg.sender,
            _userB,
            _wagerToken,
            _paymentToken,
            _wagerPriceA,
            _wagerPriceB,
            _amountUserA,
            _amountUserB,
            _duration
        );
    }

    /// @notice Fills a wager and starts the wager countdown
    /// @param _wagerId id of the wager
    function fillWager(uint256 _wagerId) external payable nonReentrant {
        Wager memory wager = wagers[_wagerId];

        if (wager.isFilled) revert WagerAlreadyFilled();
        if (wager.isClosed) revert WagerAlreadyClosed();
        if (
            refundableTimestamp[wager.wagerToken].nonrefundable <
            refundableTimestamp[wager.wagerToken].refundable
        ) {
            revert TokenNotApproved();
        }
        if (msg.sender == wager.userA) revert SelfWager();

        uint256 feeUserB = _calculateFee(wager.amountUserB, wager.paymentToken);

        if (wager.userB != address(0)) {
            // p2p
            if (msg.sender != wager.userB) revert RestrictedP2P();

            // UserA fees have not been paid yet
            uint256 feeUserA = _calculateFee(
                wager.amountUserA,
                wager.paymentToken
            );

            if (
                wager.paymentToken ==
                address(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)
            ) {
                // ETH
                if (msg.value != wager.amountUserB) revert InvalidValue();

                wager.amountUserA -= feeUserA;
                wager.amountUserB -= feeUserB;

                _transfer(payable(feeAddress), feeUserA + feeUserB);
            } else {
                uint256 balanceBefore = IERC20(wager.paymentToken).balanceOf(
                    address(this)
                );
                IERC20(wager.paymentToken).safeTransferFrom(
                    msg.sender,
                    address(this),
                    wager.amountUserB
                );
                uint256 balanceAfter = IERC20(wager.paymentToken).balanceOf(
                    address(this)
                );

                wager.amountUserB = balanceAfter - balanceBefore;

                wager.amountUserA -= feeUserA;
                wager.amountUserB -= feeUserB;

                IERC20(wager.paymentToken).safeTransfer(
                    feeAddress,
                    feeUserA + feeUserB
                );
            }
        } else {
            // p2m
            if (createdTimes[_wagerId] + 30 days <= block.timestamp) {
                revert WagerExpired();
            }
            wager.userB = msg.sender;
            if (
                wager.paymentToken ==
                address(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)
            ) {
                if (msg.value != wager.amountUserB) revert InvalidValue();
                wager.amountUserB -= feeUserB;
                _transfer(payable(feeAddress), feeUserB);
            } else {
                uint256 balanceBefore = IERC20(wager.paymentToken).balanceOf(
                    address(this)
                );
                IERC20(wager.paymentToken).safeTransferFrom(
                    msg.sender,
                    address(this),
                    wager.amountUserB
                );
                IERC20(wager.paymentToken).safeTransfer(feeAddress, feeUserB);
                uint256 balanceAfter = IERC20(wager.paymentToken).balanceOf(
                    address(this)
                );

                wager.amountUserB = balanceAfter - balanceBefore;
            }
        }

        endTimes[_wagerId] = wager.duration + block.timestamp;
        wager.isFilled = true;

        wagers[_wagerId] = wager; // update wager to storage

        emit WagerFilled(
            _wagerId,
            wager.userA,
            wager.userB,
            wager.wagerToken,
            wager.wagerPriceA,
            wager.wagerPriceB
        );
    }

    /// @notice Cancels a wager that has not been filled
    /// @dev Fee is not refunded if wager was created as p2m
    /// @param _wagerId id of the wager
    function cancelWager(uint256 _wagerId) external nonReentrant {
        Wager memory wager = wagers[_wagerId];
        if (wager.isClosed) revert WagerAlreadyClosed();
        if (msg.sender != wager.userA && msg.sender != wager.userB)
            revert UnauthorizedSender();
        if (wager.isFilled) revert WagerAlreadyFilled();

        wagers[_wagerId].isClosed = true;

        if (
            wager.paymentToken ==
            address(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)
        ) {
            _transfer(payable(wager.userA), wager.amountUserA);
        } else {
            IERC20(wager.paymentToken).safeTransfer(
                wager.userA,
                wager.amountUserA
            );
        }
        emit WagerCancelled(_wagerId, msg.sender);
    }

    /// @notice Redeems a wager
    /// @param _wagerId id of the wager
    function redeem(uint256 _wagerId) external nonReentrant {
        Wager memory wager = wagers[_wagerId];
        if (!wager.isFilled) revert WagerNotFilled();
        if (wager.isClosed) revert WagerAlreadyClosed();
        uint256 refundable = refundableTimestamp[wager.wagerToken].refundable;
        uint256 nonrefundable = refundableTimestamp[wager.wagerToken]
            .nonrefundable;
        if (
            (refundable > 0 &&
                endTimes[_wagerId] > refundable &&
                (refundable > nonrefundable ||
                    nonrefundable > createdTimes[_wagerId])) || // token has been marked refundable at least once // wager wasn't complete when marked refundable // wager was created before token was marked nonrefundable
            refundUserA[_wagerId] ||
            refundUserB[_wagerId]
        ) {
            _refundWager(_wagerId);
        } else {
            _redeemWager(_wagerId);
        }
    }

    /// @notice Returns the winner of the wager once it is completed
    /// @param _wagerId id of the wager
    /// @return winner The winner of the wager (or the zero address if it is a draw)
    function checkWinner(uint256 _wagerId) public view returns (address) {
        Wager memory wager = wagers[_wagerId];
        if (!wager.isFilled) revert WagerNotFilled();
        uint256 endTime = endTimes[_wagerId];
        if (block.timestamp < endTime) revert WagerIncomplete();

        AggregatorV2V3Interface feed = AggregatorV2V3Interface(
            oracles[wager.wagerToken]
        );

        uint80 roundId = roundIdFetcher.getRoundId(feed, endTime);

        if (roundId == 0) {
            return address(0);
        }

        (int256 price, , ) = _getHistoricalPrice(roundId, wager.wagerToken);

        if (wager.wagerPriceA > wager.wagerPriceB) {
            // User A bets above
            if (price >= wager.wagerPriceA) {
                return wager.userA; // User A wins
            } else if (price <= wager.wagerPriceB) {
                return wager.userB; // User B wins
            }
        } else if (wager.wagerPriceA < wager.wagerPriceB) {
            // User A bets below
            if (price <= wager.wagerPriceA) {
                return wager.userA; // User A wins
            } else if (price >= wager.wagerPriceB) {
                return wager.userB; // User B wins
            }
        }
        return address(0); // Draw
    }

    /// @notice Get all wagers
    /// @return All created wagers
    function getAllWagers() public view returns (Wager[] memory) {
        return wagers;
    }

    function _createWager(
        address _userA,
        address _userB,
        address _wagerToken,
        address _paymentToken,
        int256 _wagerPriceA,
        int256 _wagerPriceB,
        uint256 _amountUserA,
        uint256 _amountUserB,
        uint256 _duration
    ) internal {
        Wager memory wager = Wager(
            false,
            false,
            _userA,
            _userB,
            _wagerToken,
            _paymentToken,
            _wagerPriceA,
            _wagerPriceB,
            _amountUserA,
            _amountUserB,
            _duration
        );
        wagers.push(wager);
        createdTimes[idCounter] = block.timestamp;
        emit WagerCreated(
            idCounter,
            _userA,
            _userB,
            _wagerToken,
            _wagerPriceA,
            _wagerPriceB
        );
        idCounter++;
    }

    function _refundWager(uint256 _wagerId) internal {
        Wager memory wager = wagers[_wagerId];
        if (msg.sender == wager.userA) {
            if (refundUserA[_wagerId]) revert UserAlreadyRefunded();
            refundUserA[_wagerId] = true;
            if (
                wager.paymentToken ==
                address(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)
            ) {
                _transfer(payable(wager.userA), wager.amountUserA);
            } else {
                IERC20(wager.paymentToken).safeTransfer(
                    wager.userA,
                    wager.amountUserA
                );
            }
            emit WagerRefunded(
                _wagerId,
                msg.sender,
                wager.paymentToken,
                wager.amountUserA
            );
        } else if (msg.sender == wager.userB) {
            if (refundUserB[_wagerId]) revert UserAlreadyRefunded();
            refundUserB[_wagerId] = true;
            if (
                wager.paymentToken ==
                address(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)
            ) {
                _transfer(payable(wager.userB), wager.amountUserB);
            } else {
                IERC20(wager.paymentToken).safeTransfer(
                    wager.userB,
                    wager.amountUserB
                );
            }
            emit WagerRefunded(
                _wagerId,
                msg.sender,
                wager.paymentToken,
                wager.amountUserB
            );
        }
    }

    function _redeemWager(uint256 _wagerId) internal {
        Wager memory wager = wagers[_wagerId];
        if (block.timestamp < endTimes[_wagerId]) revert WagerIncomplete();
        uint256 winningSum = wager.amountUserA + wager.amountUserB;
        address winner = checkWinner(_wagerId);

        wagers[_wagerId].isClosed = true;

        if (winner == address(0)) {
            // draw
            if (
                wager.paymentToken ==
                address(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)
            ) {
                _transfer(payable(wager.userA), wager.amountUserA);
                _transfer(payable(wager.userB), wager.amountUserB);
            } else {
                IERC20(wager.paymentToken).safeTransfer(
                    wager.userA,
                    wager.amountUserA
                );
                IERC20(wager.paymentToken).safeTransfer(
                    wager.userB,
                    wager.amountUserB
                );
            }
        } else {
            if (
                wager.paymentToken ==
                address(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)
            ) {
                _transfer(payable(winner), winningSum);
            } else {
                IERC20(wager.paymentToken).safeTransfer(winner, winningSum);
            }
        }
        emit WagerRedeemed(_wagerId, winner, wager.paymentToken, winningSum);
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV2V3Interface.sol";

import "./interfaces/IRoundIdFetcher.sol";

error AlreadyInitialized();
error InvalidAddress();
error EthTransferFailed();
error InsufficientAmount();
error NegativeTokenPrice();
error RoundIncomplete();

/// @title BartrrBase
/// @dev Contains the shared code between ConditionalWager.sol and FixedWager.sol
contract BartrrBase is Ownable, ReentrancyGuard {
    struct RefundableTimestamp {
        uint256 refundable;
        uint256 nonrefundable;
    }

    address public feeAddress;
    IRoundIdFetcher public roundIdFetcher;
    uint256 public constant MIN_WAGER_DURATION = 1 days;
    uint32 public constant MIN_WAGER_AMOUNT = 995_000; // $9.95
    uint32 public constant MIN_WAGER_AMOUNT_FACTOR = 100_000;
    uint32 public constant MIN_FEE_AMOUNT = 250_000_000; // $2.50 (8 decimals)
    uint256 public idCounter; // Counter for the wager id
    bool public isInitialized;

    mapping(uint256 => uint256) public createdTimes; // mapping of contract creation times
    mapping(uint256 => uint256) public endTimes; // mapping of end times
    mapping(address => RefundableTimestamp) public refundableTimestamp; // mapping of timestamps for refundable token switch
    mapping(uint256 => bool) public refundUserA; // Marked true when userA calls refundWager()
    mapping(uint256 => bool) public refundUserB; // Marked true when userB calls refundWager()

    mapping(address => bool) public wagerTokens; // Tokens to be wagered on
    mapping(address => bool) public paymentTokens; // Tokens to be paid with

    mapping(address => address) public oracles; // Store the chainlink oracle for the token

    /// @notice Emitted when a wager is cancelled
    /// @param wagerId The wager id
    /// @param user The user who cancelled the wager
    event WagerCancelled(uint256 indexed wagerId, address indexed user);

    /// @notice Emitted when a wager is redeemed
    /// @param wagerId The wager id
    /// @param winner The winner of the wager
    /// @param paymentToken The token used to pay for the wager
    /// @param winningSum The amount of paymentTokens won
    event WagerRedeemed(
        uint256 indexed wagerId,
        address indexed winner,
        address paymentToken,
        uint256 winningSum
    );

    /// @notice Emitted when a wager is refunded
    /// @param wagerId The wager id
    /// @param user The user refunding the wager
    /// @param paymentToken The token being refunded
    /// @param amount The amount of paymentToken being refunded
    event WagerRefunded(
        uint256 indexed wagerId,
        address indexed user,
        address paymentToken,
        uint256 amount
    );

    /// @notice Emitted when an array of wager tokens is updated
    /// @param tokens Array of wager tokens
    /// @param oracles Array of oracles for the wager tokens
    /// @param update Whether the wager token is added (true) or removed (false)
    event WagerTokensUpdated(
        address[] indexed tokens,
        address[] indexed oracles,
        bool update
    );

    /// @notice Emitted when an array of payment tokens is updated
    /// @param tokens Array of payment tokens
    /// @param oracles Array of oracles
    /// @param update Whether the array of payment tokens is added (true) or removed (false)
    event PaymentTokensUpdated(
        address[] indexed tokens,
        address[] indexed oracles,
        bool update
    );

    /// @notice Called if an error is detected in the chainlink oracle
    /// @param _token address of the token whose wagers need to be refunded
    function oracleMalfunction(address _token) external onlyOwner {
        refundableTimestamp[_token].refundable = block.timestamp;
    }

    /// @notice Called when there is working update for the chainlink oracle
    /// @param _token address of the token whose wagers need to be refunded
    function oracleRecovery(address _token) external onlyOwner {
        refundableTimestamp[_token].nonrefundable = block.timestamp;
    }

    /// @param _feeAddress address of the fee recipient
    function init(
        address _feeAddress,
        address _owner,
        address _roundIdFetcher
    ) external onlyOwner {
        if (isInitialized) revert AlreadyInitialized();
        if (_feeAddress == address(0)) revert InvalidAddress();
        feeAddress = _feeAddress;
        roundIdFetcher = IRoundIdFetcher(_roundIdFetcher);
        _transferOwnership(_owner);
        isInitialized = true;
    }

    /// @param _wagerTokens array of wager token addresses
    /// @param _oracles array of oracles for the wager tokens
    /// @param _update true if the tokens are being added, false if they are being removed
    function updateWagerTokens(
        address[] memory _wagerTokens,
        address[] memory _oracles,
        bool _update
    ) external onlyOwner {
        for (uint256 i = 0; i < _wagerTokens.length; i++) {
            wagerTokens[_wagerTokens[i]] = _update;
            oracles[_wagerTokens[i]] = _oracles[i];
        }
        emit WagerTokensUpdated(_wagerTokens, _oracles, _update);
    }

    /// @param _paymentTokens array of payment token addresses
    /// @param _oracles array of oracles for the payment tokens
    /// @param _update true if the tokens are being added, false if they are being removed
    function updatePaymentTokens(
        address[] memory _paymentTokens,
        address[] memory _oracles,
        bool _update
    ) external onlyOwner {
        for (uint256 i = 0; i < _paymentTokens.length; i++) {
            paymentTokens[_paymentTokens[i]] = _update;
            oracles[_paymentTokens[i]] = _oracles[i];
        }
        emit PaymentTokensUpdated(_paymentTokens, _oracles, _update);
    }

    /// @notice Function to transfer Ether from this contract to address from input
    /// @param _to address of transfer recipient
    /// @param _amount amount of ether to be transferred
    function _transfer(address payable _to, uint256 _amount) internal {
        (bool success, ) = _to.call{value: _amount}("");
        if (!success) {
            revert EthTransferFailed();
        }
    }

    /// @param _roundId Chainlink roundId corresponding to the wager deadline
    /// @param _token address of the token whose price is being queried
    function _getHistoricalPrice(uint80 _roundId, address _token)
        internal
        view
        returns (
            int256,
            uint256,
            uint256
        )
    {
        (
            ,
            int256 price,
            uint256 startedAt,
            uint256 timeStamp,

        ) = AggregatorV2V3Interface(oracles[_token]).getRoundData(_roundId);
        if (timeStamp <= 0) revert RoundIncomplete();
        return (price, startedAt, timeStamp);
    }

    /// @param _token address of the token whose price is being queried
    function _getLatestPrice(address _token)
        internal
        view
        returns (int256, uint8)
    {
        address aggregator = oracles[_token];
        (, int256 answer, , uint256 updatedAt, ) = AggregatorV2V3Interface(
            aggregator
        ).latestRoundData();
        if (updatedAt <= 0) revert RoundIncomplete();
        uint8 decimals = AggregatorV2V3Interface(aggregator).decimals();
        return (answer, decimals);
    }

    /// @param _amount amount of the wager
    /// @param _paymentToken address of the payment token
    function _calculateFee(uint256 _amount, address _paymentToken)
        internal
        view
        returns (uint256 fee)
    {
        (int256 tokenPrice, uint8 oracleDecimals) = _getLatestPrice(
            _paymentToken
        );

        // Protection against negative prices
        if (tokenPrice <= 0) {
            revert NegativeTokenPrice();
        } else {
            uint256 usdPrice = uint256(tokenPrice);
            uint8 decimals;
            if (
                _paymentToken ==
                address(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)
            ) {
                decimals = 18;
            } else {
                decimals = IERC20Metadata(_paymentToken).decimals();
            }

            uint256 dollarAmount = (((_amount * usdPrice) *
                MIN_WAGER_AMOUNT_FACTOR) / (10**decimals)) /
                (10**oracleDecimals);

            if (dollarAmount < MIN_WAGER_AMOUNT) revert InsufficientAmount();
            fee = (_amount * 5) / 1000; // .5% fee
            if (((fee * usdPrice) / (10**decimals)) < MIN_FEE_AMOUNT) {
                fee = (MIN_FEE_AMOUNT * (10**decimals)) / usdPrice; // $5 fee
            }
        }
        return fee;
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV2V3Interface.sol";

interface IRoundIdFetcher {
    function getPhaseForTimestamp(address _feed, uint256 _targetTime)
        external
        view
        returns (
            uint80,
            uint256,
            uint80
        );

    function getRoundId(AggregatorV2V3Interface _feed, uint256 _timeStamp)
        external
        view
        returns (uint80 roundId);
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
pragma solidity ^0.8.0;

import "./AggregatorInterface.sol";
import "./AggregatorV3Interface.sol";

interface AggregatorV2V3Interface is AggregatorInterface, AggregatorV3Interface {}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorInterface {
  function latestAnswer() external view returns (int256);

  function latestTimestamp() external view returns (uint256);

  function latestRound() external view returns (uint256);

  function getAnswer(uint256 roundId) external view returns (int256);

  function getTimestamp(uint256 roundId) external view returns (uint256);

  event AnswerUpdated(int256 indexed current, uint256 indexed roundId, uint256 updatedAt);

  event NewRound(uint256 indexed roundId, address indexed startedBy, uint256 startedAt);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(uint80 _roundId)
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