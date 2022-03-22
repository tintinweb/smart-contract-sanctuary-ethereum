// SPDX-License-Identifier: MIT
pragma solidity =0.8.13;

import "./FreeswapPool.sol"; 

contract FreeswapFactory {
    address[] private tokens;
    mapping(address => address) public tokenToPool;
    mapping(address => address) public poolToToken;

    event PoolLaunched(address token, address pool);

    function launchPool(address _token) external {
        require(_token != address(0), "Zero address provided");

        FreeswapPool _newPool = new FreeswapPool(_token);
        tokens.push(_token);
        tokenToPool[_token] = address(_newPool);
        poolToToken[address(_newPool)] = _token;

        emit PoolLaunched(_token, address(_newPool));
    }

    function getTokens() external view returns (address[] memory) {
        return tokens;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.13;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol"; 
import "./IFreeswapFactory.sol";

contract FreeswapPool {
    using SafeMath for uint256;

    IFreeswapFactory private factory;
    IERC20 private token;

    mapping(address => uint256) public shares;
    uint256 public totalShares = 0;

    event PoolInitialized(address pool, address token, uint256 weiAmount, uint256 tokenAmount);
    event EthToTokenSwitched(address user, address token, uint256 weiIn, uint256 tokenOut);
    event TokenToEthSwitched(address user, address token, uint256 tokenIn, uint256 weiOut);
    event TokenToTokenSwitchedPoolA(
        address user,
        address token1,
        address token2,
        uint256 tokenIn,
        uint256 weiOut
    );
    event TokenToTokenSwitchedPoolB(address user, address token2, uint256 weiIn, uint256 tokenOut);
    event LiquidityInvested(address user, address token, uint256 weiAmount, uint256 tokenAmount);
    event LiquidityDivested(address user, address token, uint256 weiAmount, uint256 tokenAmount);

    constructor(address _tokenAddr) {
        require(_tokenAddr != address(0), "Zero address provided");

        factory = IFreeswapFactory(msg.sender);
        token = IERC20(_tokenAddr);
    }

    function initializePool(uint256 _tokenAmount) external payable {
        require(msg.value >= 100000 && _tokenAmount >= 100000, "Not enough liquidity provided");

        shares[msg.sender] = 1000;
        totalShares = 1000;

        emit PoolInitialized(address(this), address(token), msg.value, _tokenAmount);

        token.transferFrom(msg.sender, address(this), _tokenAmount);
    }

    function investLiquidity(uint256 _minShare) external payable {
        uint256 tokenBalance = token.balanceOf(address(this));
        require(address(this).balance > 0 && tokenBalance > 0);

        uint256 _shareAmount = msg.value.mul(totalShares).div(address(this).balance); // computes the rate of share per wei inside the pool, and multiply it by the amount of wei invested
        require(_shareAmount >= _minShare, "Not enough liquidity provided");

        uint256 _tokenPerShare = token.balanceOf(address(this)).div(totalShares);
        uint256 _tokenAmount = _tokenPerShare.mul(_shareAmount);

        shares[msg.sender] = shares[msg.sender].add(_shareAmount);
        totalShares = totalShares.add(_shareAmount);

        emit LiquidityInvested(msg.sender, address(token), msg.value, _tokenAmount);

        token.transferFrom(msg.sender, address(this), _tokenAmount);
    }

    function divestLiquidity(uint256 _weiAmount, uint256 _minToken) external {
        uint256 _withdrewShareAmount = _weiAmount.mul(totalShares).div(address(this).balance); // computes the rate of share per wei inside the pool, and multiply it by the amount of wei divested
        uint256 _tokenPerShare = token.balanceOf(address(this)).div(totalShares);
        uint256 _tokenOut = _withdrewShareAmount.mul(_tokenPerShare);
        require(_tokenOut >= _minToken, "Not enough token in return");

        shares[msg.sender] = shares[msg.sender].sub(_withdrewShareAmount);
        totalShares = totalShares.sub(_withdrewShareAmount);

        emit LiquidityDivested(msg.sender, address(token), _weiAmount, _tokenOut);

        token.transfer(msg.sender, _tokenOut);
        payable(msg.sender).transfer(_weiAmount); 
    }

    function ethToTokenSwitch(uint256 _minTokenOut) external payable {
        uint256 _tokenOut = ethInHandler(msg.sender, _minTokenOut, false);

        emit EthToTokenSwitched(msg.sender, address(token), msg.value, _tokenOut);
    }

    function tokenToEthSwitch(uint256 _tokenAmount, uint256 _minWeiOut) external {
        uint256 _weiOut = tokenInHandler(msg.sender, _tokenAmount, _minWeiOut);

        emit TokenToEthSwitched(msg.sender, address(token), _tokenAmount, _weiOut);

        payable(msg.sender).transfer(_weiOut);
    }

    function tokenToTokenSwitch(
        uint256 _token1Amount,
        uint256 _minToken2Amount,
        address _token2Addr
    ) external {
        uint256 _weiOut = tokenInHandler(msg.sender, _token1Amount, 0);

        address _poolToken2Addr = factory.tokenToPool(_token2Addr);
        FreeswapPool _poolToken2 = FreeswapPool(_poolToken2Addr);

        _poolToken2.tokenToTokenIn{value: _weiOut}(msg.sender, _minToken2Amount);

        emit TokenToTokenSwitchedPoolA(
            msg.sender,
            address(token),
            _token2Addr,
            _token1Amount,
            _weiOut
        );
    }

    function tokenToTokenIn(address _to, uint256 _minTokenOut) external payable {
        address tokenAssociated = factory.poolToToken(msg.sender);
        require(tokenAssociated != address(0), "Sender is not a pool");

        uint256 _tokenOut = ethInHandler(_to, _minTokenOut, true);

        emit TokenToTokenSwitchedPoolB(_to, address(token), msg.value, _tokenOut);
    }

    function ethInHandler(
        address _to,
        uint256 _minTokenOut,
        bool _tokenToToken
    ) private returns (uint256) {
        uint256 _tokenBalance = token.balanceOf(address(this));
        // computes the rate of token per wei inside the pool, and multiply it by the amount of wei to switch
        uint256 _tokenOut = msg.value.mul(_tokenBalance).div(address(this).balance);

        require(
            _tokenOut >= _minTokenOut,
            _tokenToToken ? "Not enough token provided" : "Not enough wei provided"
        );

        token.transfer(_to, _tokenOut);

        return _tokenOut;
    }

    function tokenInHandler(
        address _to,
        uint256 _tokenAmount,
        uint256 _minWeiOut
    ) private returns (uint256) {
        uint256 _tokenBalance = token.balanceOf(address(this)).add(_tokenAmount);
        // computes the rate of wei per token inside the pool, and multiply it by the amount of token to switch
        uint256 _weiOut = _tokenAmount.mul(address(this).balance).div(_tokenBalance);

        require(_weiOut >= _minWeiOut, "Not enough token provided");
        token.transferFrom(_to, address(this), _tokenAmount);

        return _weiOut;
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
pragma solidity =0.8.13;

interface IFreeswapFactory {
    function poolsAmount() external view returns (uint256);

    function tokens(uint256 i) external view returns (address);

    function tokenToPool(address _addr) external view returns (address);

    function poolToToken(address _addr) external view returns (address);

    event PoolLaunched(address token, address pool);

    function launchPool(address _token) external;

    function getTokens() external view returns (address[] memory);
}