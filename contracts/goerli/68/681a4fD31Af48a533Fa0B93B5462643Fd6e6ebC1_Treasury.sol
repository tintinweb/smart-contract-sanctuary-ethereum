// SPDX-License-Identifier: GNU GPLv3

pragma solidity 0.8.17;

import "./Ownable.sol";
import "./SafeMathUpgradeable.sol";
import "./SafeERC20.sol";

contract Treasury is Ownable {
    using SafeMathUpgradeable for uint256;

    uint256 private immutable MAX_INT = 2 ** 256 - 1;

    uint8 private constant BUY_POOL = 0;
    uint8 private constant BOND_POOL = 1;
    uint8 private constant STAKE_POOL = 2;
    uint8 private constant LEND_POOL = 3;
    uint8 private constant BORROW_POOL = 4;
    uint8 private constant EXCHANGE_POOL = 5;

    uint8 private constant STAKE_REWARD_DISTRIBUTED = 6;
    uint8 private constant LEND_REWARD_DISTRIBUTED = 7;

    uint8 private constant COLLATERAL_STABL3_POOL = 8;

    address public ROI;
    address public HQ;

    IERC20 public stabl3;
    uint256 public initialTreasurySupply;

    RateInfo public rateInfo;

    uint256 private unlocked = 1;

    // structs

    struct RateInfo {
        uint256 compoundPercentage;
        uint256 rate;
        uint256 tokenWindow;
        uint256 stabl3Window;
        uint256 tokenWindowConsumed;
    }

    // mappings

    // contracts with permission to access treasury funds
    mapping (address => bool) public permitted;

    // reserved tokens to buy STABL3
    mapping (IERC20 => bool) public isReservedToken;

    // array for reserved tokens
    IERC20[] public allReservedTokens;

    // record for funds pooled
    mapping (uint8 => mapping(IERC20 => uint256)) public getTreasuryPool;
    mapping (uint8 => mapping(IERC20 => uint256)) public getROIPool;
    mapping (uint8 => mapping(IERC20 => uint256)) public getHQPool;

    // events

    event UpdatedROI(address newROI, address oldROI);

    event UpdatedHQ(address newHQ, address oldHQ);

    event UpdatedPermission(address contractAddress, bool state);

    event UpdatedReservedToken(IERC20 token, bool state);

    event Rate(uint256 rate, uint256 reserves, uint256 blockTimestampLast);

    // constructor

    constructor() {
        HQ = 0x294d0487fdf7acecf342ae70AFc5549A6E90f3e0;

        stabl3 = IERC20(0xDf9c4990a8973b6cC069738592F27Ea54b27D569);

        rateInfo = RateInfo(1 * (10 ** 15), 0.0007 * (10 ** 18), 10000 * (10 ** 18), 0, 0);
        rateInfo.stabl3Window = (rateInfo.tokenWindow * (10 ** 6)) / rateInfo.rate;

        IERC20 USDC = IERC20(0x1092d50E8E14479bB769b687427B72BeE70c9534);
        IERC20 DAI = IERC20(0x59f78fB97FB36adbaDCbB43Fa9031797faAad54A);

        updateReservedToken(USDC, true);
        updateReservedToken(DAI, true);
    }

    function updateROI(address _ROI) external onlyOwner {
        require(ROI != _ROI, "Treasury: ROI is already this address");
        emit UpdatedROI(_ROI, ROI);
        ROI = _ROI;
    }

    function updateHQ(address _HQ) external onlyOwner {
        require(HQ != _HQ, "Treasury: HQ is already this address");
        emit UpdatedHQ(_HQ, HQ);
        HQ = _HQ;
    }

    function updatePermission(address _contractAddress, bool _state) external onlyOwner {
        require(permitted[_contractAddress] != _state, "Treasury: Contract is already of the value 'state'");
        permitted[_contractAddress] = _state;

        if (_state) {
            delegateApprove(stabl3, _contractAddress, true);

            for (uint256 i = 0 ; i < allReservedTokens.length ; i++) {
                delegateApprove(allReservedTokens[i], _contractAddress, true);
            }
        }
        else {
            delegateApprove(stabl3, _contractAddress, false);

            for (uint256 i = 0 ; i < allReservedTokens.length ; i++) {
                delegateApprove(allReservedTokens[i], _contractAddress, false);
            }
        }

        emit UpdatedPermission(_contractAddress, _state);
    }

    function updateReservedToken(IERC20 _token, bool _state) public onlyOwner {
        require(isReservedToken[_token] != _state, "Treasury: Reserved token is already of the value 'state'");
        isReservedToken[_token] = _state;
        allReservedTokens.push(_token);
        emit UpdatedReservedToken(_token, _state);
    }

    function allReservedTokensLength() external view returns (uint256) {
        return allReservedTokens.length;
    }

    function allPools(uint8 _type, IERC20 _token) external view returns (uint256, uint256, uint256) {
        return (
            getTreasuryPool[_type][_token],
            getROIPool[_type][_token],
            getHQPool[_type][_token]
        );
    }

    function sumOfAllPools(uint8 _type, IERC20 _token) external view returns (uint256) {
        return getTreasuryPool[_type][_token] + getROIPool[_type][_token] + getHQPool[_type][_token];
    }

    function circulatingSupply() external view returns (uint256) {
        return initialTreasurySupply - stabl3.balanceOf(address(this));
    }

    function provideInitialTreasurySupply(uint256 _amountStabl3) external onlyOwner {
        require(stabl3.balanceOf(address(this)) == 0, "Treasury: Supply already provided");

        initialTreasurySupply = _amountStabl3;

        stabl3.transferFrom(owner(), address(this), _amountStabl3);
    }

    function getReserves() public view returns (uint256) {
        uint256 totalReserves;

        for (uint256 i = 0 ; i < allReservedTokens.length ; i++) {
            if (isReservedToken[allReservedTokens[i]]) {
                uint256 amount = allReservedTokens[i].balanceOf(address(this));

                amount += allReservedTokens[i].balanceOf(ROI);
                amount += allReservedTokens[i].balanceOf(HQ);

                uint256 decimals = allReservedTokens[i].decimals();

                if (decimals < 18) {
                    amount *= 10 ** (18 - decimals);
                }

                totalReserves += amount;
            }
        }

        return totalReserves;
    }

    // rate is in 18 decimals
    function getRate() public view returns (uint256) {
        if (initialTreasurySupply == 0) {
            return 0;
        }

        return rateInfo.rate;
    }

    function getRateImpact(IERC20 _token, uint256 _amountToken) public view reserved(_token) returns (uint256) {
        if (initialTreasurySupply == 0) {
            return 0;
        }

        uint256 amountTokenConverted = _amountToken;
        if (_token.decimals() < 18) {
            amountTokenConverted *= 10 ** (18 - _token.decimals());
        }

        uint256 amountTokenToConsider = amountTokenConverted + rateInfo.tokenWindowConsumed;
        if (amountTokenToConsider <= rateInfo.tokenWindow) {
            return rateInfo.rate;
        }
        else {
            uint256 tokenWindowToConsider = rateInfo.tokenWindow;

            uint256 stabl3WindowToConsider = rateInfo.stabl3Window;

            amountTokenToConsider = amountTokenToConsider.safeSub(tokenWindowToConsider);

            while (amountTokenToConsider > 0) {
                tokenWindowToConsider += _compoundSingle(tokenWindowToConsider, rateInfo.compoundPercentage);

                stabl3WindowToConsider -= _compoundSingle(stabl3WindowToConsider, rateInfo.compoundPercentage);

                amountTokenToConsider = amountTokenToConsider.safeSub(tokenWindowToConsider);
            }

            uint256 rate = (tokenWindowToConsider * (10 ** 6)) / stabl3WindowToConsider;

            return rate;
        }
    }

    function getRateImpact(uint256 _amountStabl3, IERC20 _token) public view reserved(_token) returns (uint256) {
        require(_amountStabl3 > 0, "Treasury: Insufficient input amount");
        if (initialTreasurySupply == 0) {
            return 0;
        }

        uint256 amountStabl3ToConsider = _amountStabl3 + ((rateInfo.tokenWindowConsumed * (10 ** 6)) / rateInfo.rate);
        if (amountStabl3ToConsider <= rateInfo.stabl3Window) {
            return rateInfo.rate;
        }
        else {
            uint256 tokenWindowToConsider = rateInfo.tokenWindow;

            uint256 stabl3WindowToConsider = rateInfo.stabl3Window;

            amountStabl3ToConsider = amountStabl3ToConsider.safeSub(stabl3WindowToConsider);

            while (amountStabl3ToConsider > 0) {
                tokenWindowToConsider += _compoundSingle(tokenWindowToConsider, rateInfo.compoundPercentage);

                stabl3WindowToConsider -= _compoundSingle(stabl3WindowToConsider, rateInfo.compoundPercentage);

                amountStabl3ToConsider = amountStabl3ToConsider.safeSub(stabl3WindowToConsider);
            }

            uint256 rate = (tokenWindowToConsider * (10 ** 6)) / stabl3WindowToConsider;

            return rate;
        }
    }

    // TODO FE -> call get rate for price in landing page call get rate impact for price in exchange
    function getAmountOut(IERC20 _token, uint256 _amountToken) external view reserved(_token) returns (uint256) {
        require(_amountToken > 0, "Treasury: Insufficient input amount");
        if (initialTreasurySupply == 0) {
            return 0;
        }

        uint256 rate = getRateImpact(_token, _amountToken);

        uint256 amountTokenConverted = _amountToken;
        if (_token.decimals() < 18) {
            amountTokenConverted *= (10 ** (18 - _token.decimals()));
        }

        uint256 amountStabl3 = (amountTokenConverted  * (10 ** 6)) / rate;

        return amountStabl3;
    }

    function getAmountIn(uint256 _amountStabl3, IERC20 _token) external view reserved(_token) returns (uint256) {
        require(_amountStabl3 > 0, "Treasury: Insufficient input amount");
        if (initialTreasurySupply == 0) {
            return 0;
        }

        uint256 rate = getRateImpact(_amountStabl3, _token);

        uint256 amountToken = (_amountStabl3 * rate) / 10 ** 6;

        if (_token.decimals() < 18) {
            amountToken /= 10 ** (18 - _token.decimals());
        }

        return amountToken;
    }

    function updatePool(
        uint8 _type,
        IERC20 _token,
        uint256 _amountTokenTreasury,
        uint256 _amountTokenROI,
        uint256 _amountTokenHQ,
        bool _isIncrease
    ) external lock permission {
        if (_isIncrease) {
            getTreasuryPool[_type][_token] += _amountTokenTreasury;
            getROIPool[_type][_token] += _amountTokenROI;
            getHQPool[_type][_token] += _amountTokenHQ;
        }
        else {
            getTreasuryPool[_type][_token].safeSub(_amountTokenTreasury);
            getROIPool[_type][_token].safeSub(_amountTokenROI);
            getHQPool[_type][_token].safeSub(_amountTokenHQ);
        }
    }

    function updateRate(IERC20 _token, uint256 _amountToken) public lock permission reserved(_token) {
        uint256 amountTokenConverted = _amountToken;
        if (_token.decimals() < 18) {
            amountTokenConverted *= 10 ** (18 - _token.decimals());
        }

        uint256 amountTokenToConsider = amountTokenConverted + rateInfo.tokenWindowConsumed;
        if (amountTokenToConsider > rateInfo.tokenWindow) {
            uint256 tokenWindowToConsider = rateInfo.tokenWindow;

            uint256 stabl3WindowToConsider = rateInfo.stabl3Window;

            uint256 tokenWindowConsumedToConsider = rateInfo.tokenWindowConsumed;

            amountTokenToConsider = amountTokenToConsider.safeSub(tokenWindowToConsider);

            while (amountTokenToConsider > 0) {
                tokenWindowToConsider += _compoundSingle(tokenWindowToConsider, rateInfo.compoundPercentage);

                stabl3WindowToConsider -= _compoundSingle(stabl3WindowToConsider, rateInfo.compoundPercentage);

                tokenWindowConsumedToConsider = amountTokenToConsider;

                amountTokenToConsider = amountTokenToConsider.safeSub(tokenWindowToConsider);
            }

            rateInfo.rate = (tokenWindowToConsider * (10 ** 6)) / stabl3WindowToConsider;

            rateInfo.tokenWindow = tokenWindowToConsider;

            rateInfo.stabl3Window = stabl3WindowToConsider;

            rateInfo.tokenWindowConsumed = tokenWindowConsumedToConsider;
        }
        else {
            rateInfo.tokenWindowConsumed += amountTokenConverted;
        }

        uint256 reserves = getReserves();

        emit Rate(rateInfo.rate, reserves, block.timestamp);
    }

    function delegateApprove(IERC20 _token, address _spender, bool _isApprove) public onlyOwner {
        if (_isApprove) {
            SafeERC20.safeApprove(_token, _spender, MAX_INT);
        }
        else {
            SafeERC20.safeApprove(_token, _spender, 0);
        }
    }

    function withdrawFunds(IERC20 _token, uint256 _amountToken) external onlyOwner {
        require(!isReservedToken[_token], "Treasury: Funds Locked");
        SafeERC20.safeTransfer(_token, owner(), _amountToken);
    }

    function withdrawAllFunds(IERC20 _token) external onlyOwner {
        require(!isReservedToken[_token], "Treasury: Funds Locked");
        SafeERC20.safeTransfer(_token, owner(), _token.balanceOf(address(this)));
    }

    function _compoundSingle(uint256 _principal, uint256 _ratio) internal pure returns (uint256) {
        uint256 accruedAmount = _principal.mul(_ratio).div(10 ** 18);

        return accruedAmount;
    }

    // TODO remove
    // Testing only
    function testWithdrawAllFunds(IERC20 _token) external onlyOwner {
        SafeERC20.safeTransfer(_token, owner(), _token.balanceOf(address(this)));
    }

    // modifiers

    modifier lock() {
        require(unlocked == 1, "Treasury: Locked");
        unlocked = 0;
        _;
        unlocked = 1;
    }

    modifier permission() {
        require(permitted[msg.sender] || msg.sender == owner(), "Treasury: Not permitted");
        _;
    }

    modifier reserved(IERC20 _token) {
        require(isReservedToken[_token], "Treasury: Not a reserved token");
        _;
    }
}

// SPDX-License-Identifier: Unlicense

pragma solidity 0.8.17;

import "./Address.sol";
import "./IERC20.sol";
import "./IERC20Permit.sol";

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
// OpenZeppelin Contracts (last updated v4.6.0) (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMathUpgradeable {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

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
        return a + b;
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
        return a - b;
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
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
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
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
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
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
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
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
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
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }

    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a / b + (a % b == 0 ? 0 : 1);
    }

    /**
     * @dev Returns the current rounding of the division of two numbers.
     *
     * This differs from standard division with `/` in that it can round up and
     * down depending on the floating point.
     */
    function roundDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 result = a * 10 / b;
        if (result % 10 >= 5) {
            result = a / b + (a % b == 0 ? 0 : 1);
        }
        else {
            result = a / b;
        }

        return result;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, without an overflow flag
     */
    function safeSub(uint256 a, uint256 b) internal pure returns (uint256) {
        unchecked {
            if (b > a) return 0;
            return a - b;
        }
    }
}

pragma solidity ^0.8.0;
// SPDX-License-Identifier: Unlicense

import "./Context.sol";

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
}

// SPDX-License-Identifier: Unlicense

pragma solidity 0.8.17;

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

pragma solidity ^0.8.0;
// SPDX-License-Identifier: MIT

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
    * @dev Returns the amount of tokens in existence.
    */
    function totalSupply() external view returns (uint256);

    /**
    * @dev Returns the token decimals.
    */
    function decimals() external view returns (uint256);

    /**
    * @dev Returns the token symbol.
    */
    function symbol() external view returns (string memory);

    /**
    * @dev Returns the token name.
    */
    function name() external view returns (string memory);

    /**
    * @dev Returns the bep token owner.
    */
    function getOwner() external view returns (address);

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
    function allowance(address _owner, address spender) external view returns (uint256);

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
    * @dev Moves `amount` tokens from `sender` to `recipient` using the
    * allowance mechanism. `amount` is then deducted from the caller's
    * allowance.
    *
    * Returns a boolean value indicating whether the operation succeeded.
    *
    * Emits a {Transfer} event.
    */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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
}

// SPDX-License-Identifier: Unlicense

pragma solidity 0.8.17;

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
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
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
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
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
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
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
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
     * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
     *
     * _Available since v4.8._
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason or using the provided one.
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
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
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

pragma solidity ^0.8.0;
// SPDX-License-Identifier: MIT

/*
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
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}