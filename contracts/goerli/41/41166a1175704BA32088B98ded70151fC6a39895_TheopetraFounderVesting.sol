// SPDX-License-Identifier: MIT

pragma solidity ^0.7.5;

import "../Types/TheopetraAccessControlled.sol";

import "../Libraries/SafeMath.sol";
import "../Libraries/SafeERC20.sol";
import "../Libraries/SignedSafeMath.sol";

import "../Interfaces/IFounderVesting.sol";
import "../Interfaces/ITHEO.sol";
import "../Interfaces/ITreasury.sol";

/**
 * @title TheopetraFounderVesting
 * @dev This contract allows to split THEO payments among a group of accounts. The sender does not need to be aware
 * that the THEO will be split in this way, since it is handled transparently by the contract.
 *
 * The split can be in equal parts or in any other arbitrary proportion. The way this is specified is by assigning each
 * account to a number of shares. Of all the THEO that this contract receives, each account will then be able to claim
 * an amount proportional to the percentage of total shares they were assigned.
 *
 * `TheopetraFounderVesting` follows a _pull payment_ model. This means that payments are not automatically forwarded to the
 * accounts but kept in this contract, and the actual transfer is triggered as a separate step by calling the {release}
 * function.
 */
contract TheopetraFounderVesting is IFounderVesting, TheopetraAccessControlled {
    /* ========== DEPENDENCIES ========== */

    using SafeMath for uint256;
    using SignedSafeMath for int256;
    using SafeERC20 for IERC20;

    /* ========== STATE VARIABLES ========== */
    ITreasury private treasury;
    ITHEO private THEO;

    uint256 private fdvTarget;

    uint256 private totalShares;

    mapping(address => uint256) private shares;
    address[] private payees;

    mapping(IERC20 => uint256) private erc20TotalReleased;
    mapping(IERC20 => mapping(address => uint256)) private erc20Released;

    uint256 private immutable deployTime = block.timestamp;
    uint256[] private unlockTimes;
    uint256[] private unlockAmounts;

    bool private founderRebalanceLocked = false;
    bool private initialized = false;

    /**
     * @notice return the decimals in the percentage values and
     * thus the number of shares per percentage point (1% = 10_000_000 shares)
     */
    function decimals() public pure returns (uint8) {
        return 9;
    }

    /**
     * @dev Creates an instance of `TheopetraFounderVesting` where each account in `payees` is assigned the number of shares at
     * the matching position in the `shares` array.
     *
     * All addresses in `payees` must be non-zero. Both arrays must have the same non-zero length, and there must be no
     * duplicates in `payees`.
     */
    constructor(
        ITheopetraAuthority _authority,
        address _treasury,
        address _theo,
        uint256 _fdvTarget,
        address[] memory _payees,
        uint256[] memory _shares,
        uint256[] memory _unlockTimes,
        uint256[] memory _unlockAmounts
    ) TheopetraAccessControlled(_authority) {
        require(_payees.length == _shares.length, "TheopetraFounderVesting: payees and shares length mismatch");
        require(_payees.length > 0, "TheopetraFounderVesting: no payees");
        require(
            _unlockTimes.length == _unlockAmounts.length,
            "TheopetraFounderVesting: unlock times and amounts length mismatch"
        );
        require(_unlockTimes.length > 0, "TheopetraFounderVesting: no unlock schedule");

        fdvTarget = _fdvTarget;
        THEO = ITHEO(_theo);
        treasury = ITreasury(_treasury);
        unlockTimes = _unlockTimes;
        unlockAmounts = _unlockAmounts;

        for (uint256 i = 0; i < _payees.length; i++) {
            _addPayee(_payees[i], _shares[i]);
        }
    }

    function initialMint() public onlyGovernor {
        require(!initialized, "TheopetraFounderVesting: initialMint can only be run once");
        initialized = true;

        // mint tokens for the initial shares
        uint256 tokensToMint = totalShares.mul(THEO.totalSupply()).div(10**decimals() - totalShares);
        treasury.mint(address(this), tokensToMint);
        emit InitialMint(tokensToMint);
    }

    /**
     * @dev Getter for the total shares held by payees.
     */
    function getTotalShares() public view override returns (uint256) {
        return totalShares;
    }

    /**
     * @dev Getter for the total amount of `token` already released. `token` should be the address of an IERC20
     * contract.
     */
    function getTotalReleased(IERC20 token) public view override returns (uint256) {
        return erc20TotalReleased[token];
    }

    /**
     * @dev Getter for the amount of shares held by an account.
     */
    function getShares(address account) external view override returns (uint256) {
        return shares[account];
    }

    /**
     * @dev Getter for the amount of `token` tokens already released to a payee. `token` should be the address of an
     * IERC20 contract.
     */
    function getReleased(IERC20 token, address account) public view override returns (uint256) {
        return erc20Released[token][account];
    }

    /**
     * @dev Getter for unlocked multiplier for time-locked funds. This is the percent currently unlocked as a decimal ratio of 1.
     */
    function getUnlockedMultiplier() public view returns (uint256) {
        uint256 timeSinceDeploy = block.timestamp - deployTime;
        for (uint256 i = unlockTimes.length; i > 0; i--) {
            if (timeSinceDeploy >= unlockTimes[i - 1]) {
                return unlockAmounts[i - 1];
            }
        }
        return 0;
    }

    /**
     * @notice Scale the founder amount with respect to the FDV target value
     * @dev calculated as currentFDV / FDVtarget (using 9 decimals)
     * @return uint256 proportion of FDV target, 9 decimals
     */
    function getFdvFactor() public view returns (uint256) {
        IBondCalculator theoBondingCalculator = treasury.getTheoBondingCalculator();
        if (address(theoBondingCalculator) == address(0)) {
            revert("TheopetraFounderVesting: No bonding calculator");
        }

        // expects valuation to be come back as fixed point with 9 decimals
        uint256 currentPrice = IBondCalculator(theoBondingCalculator).valuation(address(THEO), 1_000_000_000);
        uint256 calculatedFdv = currentPrice.mul(THEO.totalSupply());

        if (calculatedFdv >= fdvTarget.mul(10**decimals())) {
            return 10**decimals();
        }

        return calculatedFdv.div(fdvTarget);
    }

    /**
     * @dev Mints or burns tokens for this contract to balance shares to their appropriate percentage
     */
    function rebalance() public {
        require(shares[msg.sender] > 0, "TheopetraFounderVesting: account has no shares");

        uint256 totalSupply = THEO.totalSupply();
        uint256 contractBalance = THEO.balanceOf(address(this));
        uint256 totalReleased = erc20TotalReleased[THEO];

        // Checks if rebalance has been locked
        if (founderRebalanceLocked) return;

        uint256 founderAmount = totalShares
            .mul(totalSupply - (contractBalance + totalReleased))
            .mul(getFdvFactor())
            .div(10**decimals())
            .div(10**decimals() - totalShares);

        if (founderAmount > (contractBalance + totalReleased)) {
            treasury.mint(address(this), founderAmount - (contractBalance + totalReleased));
        } else if (founderAmount < (contractBalance + totalReleased)) {
            THEO.burn(contractBalance + totalReleased - founderAmount);
        }

        // locks the rebalance to not occur again after it is called once after unlock schedule
        uint256 timeSinceDeploy = block.timestamp - deployTime;
        if (timeSinceDeploy > unlockTimes[unlockTimes.length - 1]) {
            founderRebalanceLocked = true;
        }
    }

    /**
     * @dev Triggers a transfer to `account` of the amount of `token` tokens they are owed, according to their
     * percentage of the total shares and their previous withdrawals. `token` must be the address of an IERC20
     * contract.
     */
    function release(IERC20 token) external override {
        address account = msg.sender;
        require(shares[account] > 0, "TheopetraFounderVesting: account has no shares");

        rebalance();

        uint256 totalReceived = token.balanceOf(address(this)) + getTotalReleased(token);
        uint256 payment = _pendingPayment(account, totalReceived, getReleased(token, account));

        require(payment != 0, "TheopetraFounderVesting: account is not due payment");

        erc20Released[token][account] += payment;
        erc20TotalReleased[token] += payment;

        SafeERC20.safeTransfer(token, account, payment);
        emit ERC20PaymentReleased(token, account, payment);
    }

    /**
     * @dev Triggers a transfer to `account` of the amount of `token` tokens specified, according to their
     * percentage of the total shares and their previous withdrawals. `token` must be the address of an IERC20
     * contract.
     */
    function releaseAmount(IERC20 token, uint256 amount) external override {
        address account = msg.sender;
        require(shares[account] > 0, "TheopetraFounderVesting: account has no shares");
        require(amount > 0, "TheopetraFounderVesting: amount cannot be 0");

        rebalance();

        uint256 totalReceived = token.balanceOf(address(this)) + getTotalReleased(token);
        uint256 payment = _pendingPayment(account, totalReceived, getReleased(token, account));

        require(payment != 0, "TheopetraFounderVesting: account is not due payment");
        require(amount <= payment, "TheopetraFounderVesting: requested amount is more than due payment for account");

        erc20Released[token][account] += amount;
        erc20TotalReleased[token] += amount;

        SafeERC20.safeTransfer(token, account, amount);
        emit ERC20PaymentReleased(token, account, amount);
    }

    /**
     * @dev Returns the amount of tokens that could be paid to `account` at the current time.
     */
    function getReleasable(IERC20 token, address account) external view override returns (uint256) {
        require(shares[account] > 0, "TheopetraFounderVesting: account has no shares");

        uint256 totalReceived = token.balanceOf(address(this)) + getTotalReleased(token);
        uint256 payment = _pendingPayment(account, totalReceived, getReleased(token, account));

        return payment;
    }

    /**
     * @dev internal logic for computing the pending payment of an `account` given the token historical balances and
     * already released amounts.
     */
    function _pendingPayment(
        address account,
        uint256 totalReceived,
        uint256 alreadyReleased
    ) private view returns (uint256) {
        return
            (totalReceived * shares[account] * getUnlockedMultiplier()) /
            (totalShares * 10**decimals()) -
            alreadyReleased;
    }

    /**
     * @dev Add a new payee to the contract.
     * @param account The address of the payee to add.
     * @param shares_ The number of shares owned by the payee.
     */
    function _addPayee(address account, uint256 shares_) private {
        require(account != address(0), "TheopetraFounderVesting: account is the zero address");
        require(shares_ > 0, "TheopetraFounderVesting: shares are 0");
        require(shares[account] == 0, "TheopetraFounderVesting: account already has shares");

        payees.push(account);
        shares[account] = shares_;
        totalShares = totalShares + shares_;
        emit PayeeAdded(account, shares_);
    }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity >=0.7.5;

import "./IBondCalculator.sol";

interface ITreasury {
    function deposit(
        uint256 _amount,
        address _token,
        uint256 _profit
    ) external returns (uint256);

    function withdraw(uint256 _amount, address _token) external;

    function tokenValue(address _token, uint256 _amount) external view returns (uint256 value_);

    function mint(address _recipient, uint256 _amount) external;

    function manage(address _token, uint256 _amount) external;

    function incurDebt(uint256 amount_, address token_) external;

    function repayDebtWithReserve(uint256 amount_, address token_) external;

    function tokenPerformanceUpdate() external;

    function baseSupply() external view returns (uint256);

    function deltaTokenPrice() external view returns (int256);

    function deltaTreasuryYield() external view returns (int256);

    function getTheoBondingCalculator() external view returns (IBondCalculator);

    function setTheoBondingCalculator(address _theoBondingCalculator) external;
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity >=0.7.5;

import "./IERC20.sol";

interface ITHEO is IERC20 {
    function mint(address account_, uint256 amount_) external;

    function burn(uint256 amount) external;

    function burnFrom(address account_, uint256 amount_) external;
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity >=0.7.5;

import "./IERC20.sol";

interface IFounderVesting {
    event PayeeAdded(address account, uint256 shares);
    event ERC20PaymentReleased(IERC20 indexed token, address to, uint256 amount);
    event PaymentReceived(address from, uint256 amount);
    event InitialMint(uint256 amount);

    function getTotalShares() external view returns (uint256);

    function getTotalReleased(IERC20 token) external view returns (uint256);

    function getShares(address account) external view returns (uint256);

    function getReleased(IERC20 token, address account) external view returns (uint256);

    function release(IERC20 token) external;

    function releaseAmount(IERC20 token, uint256 amount) external;

    function getReleasable(IERC20 token, address account) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

/**
 * @title SignedSafeMath
 * @dev Signed math operations with safety checks that revert on error.
 */
library SignedSafeMath {
    int256 private constant _INT256_MIN = -2**255;

    /**
     * @dev Returns the multiplication of two signed integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(int256 a, int256 b) internal pure returns (int256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        require(!(a == -1 && b == _INT256_MIN), "SignedSafeMath: multiplication overflow");

        int256 c = a * b;
        require(c / a == b, "SignedSafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two signed integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(int256 a, int256 b) internal pure returns (int256) {
        require(b != 0, "SignedSafeMath: division by zero");
        require(!(b == -1 && a == _INT256_MIN), "SignedSafeMath: division overflow");

        int256 c = a / b;

        return c;
    }

    /**
     * @dev Returns the subtraction of two signed integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a - b;
        require((b >= 0 && c <= a) || (b < 0 && c > a), "SignedSafeMath: subtraction overflow");

        return c;
    }

    /**
     * @dev Returns the addition of two signed integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a + b;
        require((b >= 0 && c >= a) || (b < 0 && c < a), "SignedSafeMath: addition overflow");

        return c;
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.7.5;

import { IERC20 } from "../Interfaces/IERC20.sol";

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
        (bool success, ) = to.call{ value: amount }(new bytes(0));

        require(success, "ETH_TRANSFER_FAILED");
    }
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.7.5;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }

    // babylonian method (https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method)
    function sqrrt(uint256 a) internal pure returns (uint256 c) {
        if (a > 3) {
            c = a;
            uint256 b = add(div(a, 2), 1);
            while (b < c) {
                c = b;
                b = div(add(div(a, b), b), 2);
            }
        } else if (a != 0) {
            c = 1;
        }
    }

    /*
     * Expects percentage to be trailed by 00,
     */
    function percentageAmount(uint256 total_, uint8 percentage_) internal pure returns (uint256 percentAmount_) {
        return div(mul(total_, percentage_), 1000);
    }

    /*
     * Expects percentage to be trailed by 00,
     */
    function substractPercentage(uint256 total_, uint8 percentageToSub_) internal pure returns (uint256 result_) {
        return sub(total_, div(mul(total_, percentageToSub_), 1000));
    }

    function percentageOfTotal(uint256 part_, uint256 total_) internal pure returns (uint256 percent_) {
        return div(mul(part_, 100), total_);
    }

    /**
     * Taken from Hypersonic https://github.com/M2629/HyperSonic/blob/main/Math.sol
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow, so we distribute
        return (a / 2) + (b / 2) + (((a % 2) + (b % 2)) / 2);
    }

    function quadraticPricing(uint256 payment_, uint256 multiplier_) internal pure returns (uint256) {
        return sqrrt(mul(multiplier_, payment_));
    }

    function bondingCurve(uint256 supply_, uint256 multiplier_) internal pure returns (uint256) {
        return mul(multiplier_, supply_);
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.7.5;

import "../Interfaces/ITheopetraAuthority.sol";

abstract contract TheopetraAccessControlled {
    /* ========== EVENTS ========== */

    event AuthorityUpdated(ITheopetraAuthority indexed authority);

    string constant UNAUTHORIZED = "UNAUTHORIZED"; // save gas

    /* ========== STATE VARIABLES ========== */

    ITheopetraAuthority public authority;

    /* ========== Constructor ========== */

    constructor(ITheopetraAuthority _authority) {
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

    modifier onlyManager() {
        require(msg.sender == authority.manager(), UNAUTHORIZED);
        _;
    }

    modifier onlyVault() {
        require(msg.sender == authority.vault(), UNAUTHORIZED);
        _;
    }

    /* ========== GOV ONLY ========== */

    function setAuthority(ITheopetraAuthority _newAuthority) external onlyGovernor {
        authority = _newAuthority;
        emit AuthorityUpdated(_newAuthority);
    }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity >=0.7.5;

interface ITheopetraAuthority {
    /* ========== EVENTS ========== */

    event GovernorPushed(address indexed from, address indexed to, bool _effectiveImmediately);
    event GuardianPushed(address indexed from, address indexed to, bool _effectiveImmediately);
    event PolicyPushed(address indexed from, address indexed to, bool _effectiveImmediately);
    event ManagerPushed(address indexed from, address indexed to, bool _effectiveImmediately);
    event VaultPushed(address indexed from, address indexed to, bool _effectiveImmediately);
    event SignerPushed(address indexed from, address indexed to, bool _effectiveImmediately);

    event GovernorPulled(address indexed from, address indexed to);
    event GuardianPulled(address indexed from, address indexed to);
    event PolicyPulled(address indexed from, address indexed to);
    event ManagerPulled(address indexed from, address indexed to);
    event VaultPulled(address indexed from, address indexed to);
    event SignerPulled(address indexed from, address indexed to);

    /* ========== VIEW ========== */

    function governor() external view returns (address);

    function guardian() external view returns (address);

    function policy() external view returns (address);

    function manager() external view returns (address);

    function vault() external view returns (address);

    function whitelistSigner() external view returns (address);
}

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

// SPDX-License-Identifier: AGPL-1.0

pragma solidity >=0.7.5 <=0.8.10;

interface IBondCalculator {
    function valuation(address tokenIn, uint256 amount_) external view returns (uint256 amountOut);
}