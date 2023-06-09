// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

/**
 *
 * ETH CRYPTOCURRENCY DISTRIBUTION PROJECT
 *
 * Web              - https://invest.cryptohoma.com
 * Twitter          - https://twitter.com/cryptohoma
 * Telegram_channel - https://t.me/cryptohoma_channel
 * EN  Telegram_chat: https://t.me/cryptohoma_chateng
 * RU  Telegram_chat: https://t.me/cryptohoma_chat
 * KOR Telegram_chat: https://t.me/cryptohoma_chatkor
 * Email:             mailto:info(at sign)cryptohoma.com
 *
 *  - GAIN PER 24 HOURS:
 *     -- Contract balance < 20 Ether: 3,25 %
 *     -- Contract balance >= 20 Ether: 3.50 %
 *     -- Contract balance >= 40 Ether: 3.75 %
 *     -- Contract balance >= 60 Ether: 4.00 %
 *     -- Contract balance >= 80 Ether: 4.25 %
 *     -- Contract balance >= 100 Ether: 4.50 %
 *  - Life-long payments
 *  - The revolutionary reliability
 *  - Minimal contribution 0.01 eth
 *  - Currency and payment - ETH
 *  - Contribution allocation schemes:
 *    -- 90% payments
 *    -- 10% Marketing + Operating Expenses
 *
 * ---How to use:
 *  1. Send from ETH wallet to the smart contract address
 *     any amount from 0.01 ETH.
 *  2. Verify your transaction in the history of your application or etherscan.io, specifying the address
 *     of your wallet.
 *  3. Claim your profit by sending 0 ether transaction (every day, every week, i don't care unless you're
 *      spending too much on GAS)
 *
 * RECOMMENDED GAS LIMIT: 200000
 * RECOMMENDED GAS PRICE: https://ethgasstation.info/
 * You can check the payments on the etherscan.io site, in the "Internal Txns" tab of your wallet.
 *
 * ---It is not allowed to transfer from exchanges, only from your personal ETH wallet, for which you
 * have private keys.
 *
 * Contracts reviewed and approved by pros!
 *
 */

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract SecretInvest is Ownable, ReentrancyGuard {
    // Constants

    uint256 public FEE_MARKETING_MAIN = 500;
    uint256 public FEE_MARKETING_RESERVE = 500;
    // The marks of the balance on the contract after which the percentage of payments will change
    uint256 public constant MIN_BALANCE_STEP_1 = 0 ether;
    uint256 public constant MIN_BALANCE_STEP_2 = 20 ether;
    uint256 public constant MIN_BALANCE_STEP_3 = 40 ether;
    uint256 public constant MIN_BALANCE_STEP_4 = 60 ether;
    uint256 public constant MIN_BALANCE_STEP_5 = 80 ether;
    uint256 public constant MIN_BALANCE_STEP_6 = 100 ether;
    uint256 public constant PERCENT_STEP_1 = 325;
    uint256 public constant PERCENT_STEP_2 = 350;
    uint256 public constant PERCENT_STEP_3 = 375;
    uint256 public constant PERCENT_STEP_4 = 400;
    uint256 public constant PERCENT_STEP_5 = 425;
    uint256 public constant PERCENT_STEP_6 = 450;
    // The time through which dividends will be paid
    uint256 public constant DIVIDENDS_TIME = 1 days;
    uint256 public constant MIN_INVESTMENT = 0.01 ether;

    // Properties

    // Investors balances
    mapping(address => uint256) public balances;
    // The time of payment
    mapping(address => uint256) public time;
    uint256 public totalValueLocked;
    uint256 public totalDividendsPaid;
    uint256 public totalInvestors;
    uint256 public lastPayment;
    bool public isStarted;
    address public immutable marketingMain;
    address public immutable marketingReserve;

    // Constructor
    constructor(address marketingMain_, address marketingReserve_) {
        marketingMain = marketingMain_;
        marketingReserve = marketingReserve_;
    }

    // Events

    event NewInvestor(address indexed investor, uint256 deposit);
    event PayOffDividends(address indexed investor, uint256 value);
    event NewDeposit(address indexed investor, uint256 value);

    // Modifiers

    /// Checking the positive balance of the beneficiary
    modifier isInvestor() {
        require(balances[msg.sender] > 0, "SecretInvest: Deposit not found");
        _;
    }

    // Checking if contract is started
    modifier started() {
        require(
            isStarted == true,
            "SecretInvest: Contract is not started. Please wait."
        );
        _;
    }

    // Private functions
    function _receivePayment() private isInvestor nonReentrant {
        (uint256 unpaid, uint256 numDaysToPay) = unpaidDividends();
        require(
            numDaysToPay > 0,
            "SecretInvest: Too fast payout request. The time of payment has not yet come"
        );
        time[msg.sender] += numDaysToPay * DIVIDENDS_TIME;
        payable(msg.sender).transfer(unpaid);

        totalDividendsPaid += unpaid;
        lastPayment = block.timestamp;
        emit PayOffDividends(msg.sender, unpaid);
    }

    function _calcFeeMarketingMain(
        uint256 value
    ) private view returns (uint256 fee) {
        fee = (value * FEE_MARKETING_MAIN) / 10000;
    }

    function _calcFeeMarketingReserve(
        uint256 value
    ) private view returns (uint256 fee) {
        fee = (value * FEE_MARKETING_RESERVE) / 10000;
    }

    function _createDeposit() private started {
        if (msg.value > 0) {
            require(
                msg.value >= MIN_INVESTMENT,
                "SecretInvest: msg.value must be >= minInvesment"
            );

            if (balances[msg.sender] == 0) {
                emit NewInvestor(msg.sender, msg.value);
                totalInvestors += 1;
            }

            // Fee
            uint256 mainMarketingFee = _calcFeeMarketingMain(msg.value);
            payable(marketingMain).transfer(mainMarketingFee);
            uint256 reserveMarketingFee = _calcFeeMarketingReserve(msg.value);
            payable(marketingReserve).transfer(reserveMarketingFee);

            // Check if we need to pay any dividend now to this wallet
            (uint256 unpaid, uint256 numDaysToPay) = unpaidDividends();
            if (unpaid > 0 && numDaysToPay > 0) {
                _receivePayment();
            }

            // Save new amount to balance of this wallet
            balances[msg.sender] = balances[msg.sender] + msg.value;
            time[msg.sender] = block.timestamp;

            totalValueLocked += msg.value;
            emit NewDeposit(msg.sender, msg.value);
        } else {
            _receivePayment();
        }
    }

    function _numDaysToPay() private view returns (uint256 numDaysToPay) {
        numDaysToPay = (block.timestamp - time[msg.sender]) / DIVIDENDS_TIME;
    }

    // Public functions
    function claimDividends() public {
        _receivePayment();
    }

    function unpaidDividends()
        public
        view
        returns (uint256 unpaid, uint256 numDaysToPay)
    {
        uint256 dividendPerDay = (balances[msg.sender] * currentPercent()) /
            10000;
        numDaysToPay = _numDaysToPay();
        unpaid = dividendPerDay * numDaysToPay;
    }

    function isAutorizedPayment() public view returns (bool result) {
        result = balances[msg.sender] > 0 && _numDaysToPay() > 0;
    }

    function currentLevel() public view returns (uint256 level) {
        uint256 contractBalance = address(this).balance;
        level = 0;
        if (
            contractBalance >= MIN_BALANCE_STEP_1 &&
            contractBalance < MIN_BALANCE_STEP_2
        ) {
            level = 1;
        } else if (
            contractBalance >= MIN_BALANCE_STEP_2 &&
            contractBalance < MIN_BALANCE_STEP_3
        ) {
            level = 2;
        } else if (
            contractBalance >= MIN_BALANCE_STEP_3 &&
            contractBalance < MIN_BALANCE_STEP_4
        ) {
            level = 3;
        } else if (
            contractBalance >= MIN_BALANCE_STEP_4 &&
            contractBalance < MIN_BALANCE_STEP_5
        ) {
            level = 4;
        } else if (
            contractBalance >= MIN_BALANCE_STEP_5 &&
            contractBalance < MIN_BALANCE_STEP_6
        ) {
            level = 5;
        } else {
            level = 6;
        }
    }

    function currentPercent() public view returns (uint256 percent) {
        uint256 level = currentLevel();
        if (level == 1) {
            percent = PERCENT_STEP_1;
        } else if (level == 2) {
            percent = PERCENT_STEP_2;
        } else if (level == 3) {
            percent = PERCENT_STEP_3;
        } else if (level == 4) {
            percent = PERCENT_STEP_4;
        } else if (level == 5) {
            percent = PERCENT_STEP_5;
        } else {
            percent = PERCENT_STEP_6;
        }
    }

    function start() public onlyOwner {
        isStarted = true;
    }

    /// Function that is launched when transferring money to a contract
    receive() external payable {
        _createDeposit();
    }
}

// Test: 0x4fed9d1ed02D51BF99505F1DED7CbF4c474BaE9b, 0x9F94fF7E6Fd7F7637862D8aCc32101fbf4896130

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