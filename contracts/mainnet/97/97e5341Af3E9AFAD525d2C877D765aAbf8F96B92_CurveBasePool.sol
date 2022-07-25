// SPDX-License-Identifier: MIT

/* 

  _                          _   _____   _                       
 | |       ___   _ __     __| | |  ___| | |   __ _   _ __    ___ 
 | |      / _ \ | '_ \   / _` | | |_    | |  / _` | | '__|  / _ \
 | |___  |  __/ | | | | | (_| | |  _|   | | | (_| | | |    |  __/
 |_____|  \___| |_| |_|  \__,_| |_|     |_|  \__,_| |_|     \___|
                                                                 
LendFlare.finance
*/

pragma solidity ^0.8.0;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeMath } from "@openzeppelin/contracts/utils/math/SafeMath.sol";
import { ICurvePool } from "./ICurvePool.sol";

interface IBasePool is ICurvePool {
    function calc_withdraw_one_coin(uint256 _token_amount, int128 i) external view returns (uint256);

    function get_dy(
        int128 i,
        int128 j,
        uint256 dx
    ) external view returns (uint256);
}

interface IZap {
    function calc_withdraw_one_coin(uint256 _token_amount, int128 i) external view returns (uint256);
}

interface IConfig {
    function getConfig(string memory _key) external view returns (uint256);
}

contract CurveBasePool {
    using SafeMath for uint256;

    address private constant ZERO_ADDRESS = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    uint256 private constant PRECISION = 10**18;
    uint256[] private PRECISION_INDENT;

    bool private initialized;

    IConfig public config;
    IERC20[] public tokens;

    IBasePool public curve;
    IZap public zap;

    struct CorrspondedCoin {
        bool isExist;
        uint256 value;
    }

    mapping(uint256 => CorrspondedCoin) public corrspondedCoins;

    constructor() {
        initialized = true;
    }

    function initialize(
        address _config,
        uint256[] calldata _precisionIndent,
        address[] calldata _tokens,
        address _curveSwap,
        address _zap,
        // like 3pool, [[dai,usdc],[usdc,usdt],[dai,usdt]]
        uint256[][] calldata _corrspondedCoins
    ) public {
        require(!initialized, "CurveBasePool: !initialized");
        require(_config != address(0), "CurveBasePool: !_config");
        require(_curveSwap != address(0), "CurveBasePool: !_curveSwap");
        require(_precisionIndent.length == _tokens.length, "CurveBasePool: length mismatch");

        for (uint256 i = 0; i < _tokens.length; i++) {
            tokens.push(IERC20(_tokens[i]));
        }

        config = IConfig(_config);
        curve = IBasePool(_curveSwap);
        zap = IZap(_zap);

        PRECISION_INDENT = _precisionIndent;

        for (uint256 i = 0; i < _corrspondedCoins.length; i++) {
            corrspondedCoins[_corrspondedCoins[i][0]] = CorrspondedCoin({ isExist: true, value: _corrspondedCoins[i][1] });
        }

        initialized = true;
    }

    function _checkUnderlyingTokenBalance(
        uint256 _calcTokens,
        uint256 _index,
        uint256 _minOut
    ) internal view returns (bool) {
        uint256 bal;

        if (address(tokens[_index]) == ZERO_ADDRESS) {
            bal = address(this).balance;
        } else {
            bal = tokens[_index].balanceOf(address(curve));
        }

        uint256 curveBal;

        try curve.balances(_index) returns (uint256 _bal) {
            curveBal = bal.sub(bal.sub(_bal));
        } catch {
            curveBal = bal.sub(bal.sub(curve.balances(int128(uint128(_index)))));
        }

        uint256 withdrawed;

        if (address(zap) != address(curve)) {
            withdrawed = zap.calc_withdraw_one_coin(_calcTokens, int128(uint128(_index)));
        } else {
            withdrawed = curve.calc_withdraw_one_coin(_calcTokens, int128(uint128(_index)));
        }

        if (_minOut == 0) {
            if (curveBal < withdrawed) return true;
            if (curveBal < (withdrawed.mul(config.getConfig("MAX_OVERFLOW_BALANCE")) / 100)) return true;
        } else {
            if (withdrawed < _minOut) return true;
        }

        return false;
    }

    function _checkExchangeRatio(uint256 _index) internal view returns (bool) {
        uint256 dx = 1e18 / PRECISION_INDENT[_index];

        CorrspondedCoin storage corrspondedCoin = corrspondedCoins[_index];

        require(_index != corrspondedCoin.value, "CurveBasePool: !value");

        uint256 price = curve.get_dy(int128(uint128(_index)), int128(uint128(corrspondedCoin.value)), dx);

        price = price.mul(PRECISION_INDENT[corrspondedCoin.value]);
        dx = dx.mul(PRECISION_INDENT[_index]);

        uint256 averageRatio = price.mul(PRECISION).mul(100).div(dx).div(PRECISION);

        if (averageRatio < config.getConfig("MAX_OVERFLOW_RATIO")) return true;

        return false;
    }

    function _checkVirtualPrice() external view returns (bool) {
        uint256 lastVirtualPrice = 0;

        try curve.get_virtual_price() returns (uint256 _virtualPrice) {
            bool isTriggered = _virtualPrice < ((lastVirtualPrice * 500) / 1000);

            if (isTriggered) return true;

            lastVirtualPrice = _virtualPrice;
        } catch {
            return true;
        }

        // It has not occured
        return false;
    }

    function getCondition(bytes calldata _args) external view returns (uint256) {
        uint256[] memory args = abi.decode(_args, (uint256[]));

        uint256 calcTokens = args[0];
        uint256 index = args[1];
        uint256 minOut = args[2];
        // uint256 result = args[3];

        if (_checkUnderlyingTokenBalance(calcTokens, index, minOut)) return 1;
        if (_checkExchangeRatio(index)) return 1;

        return 0;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/math/SafeMath.sol)

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
library SafeMath {
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
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
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
}

// SPDX-License-Identifier: MIT

/* 

  _                          _   _____   _                       
 | |       ___   _ __     __| | |  ___| | |   __ _   _ __    ___ 
 | |      / _ \ | '_ \   / _` | | |_    | |  / _` | | '__|  / _ \
 | |___  |  __/ | | | | | (_| | |  _|   | | | (_| | | |    |  __/
 |_____|  \___| |_| |_|  \__,_| |_|     |_|  \__,_| |_|     \___|
                                                                 
LendFlare.finance
*/

pragma solidity ^0.8.0;

interface ICurvePool {
    function get_virtual_price() external view returns (uint256);

    function admin_fee() external view returns (uint256);

    function balances(uint256 index) external view returns (uint256);

    function balances(int128 index) external view returns (uint256);

    function coins(uint256 index) external view returns (address);

    // ren and sbtc pool
    function coins(int128 index) external view returns (address);
}