// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;
pragma abicoder v2;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
//import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { UniFactoryV2, UniRouterV2 } from "../interfaces/UniV2.sol";
import { IStargateReceiver, IStargateRouter } from "../interfaces/IStargate.sol";

contract StargateComposed is IStargateReceiver {
    using SafeMath for uint;
    address public stargateRouter;      // an IStargateRouter instance
    address public ammRouter;           // an IUniswapV2Router02 instance

    // special token value that indicates the sgReceive() should swap OUT native asset
    address public OUT_TO_NATIVE = 0x0000000000000000000000000000000000000000;
    event ReceivedOnDestination(address token, uint qty);

    constructor(address _stargateRouter, address _ammRouter) {
        stargateRouter = _stargateRouter;
        ammRouter = _ammRouter;
    }

    //-----------------------------------------------------------------------------------------------------------------------
    // 1. swap native on source chain to native on destination chain (!)
    function swapNativeForNative(
        uint16 dstChainId,                      // Stargate/LayerZero chainId
        address bridgeToken,                    // the address of the native ERC20 to swap() - *must* be the token for the poolId
        uint16 srcPoolId,                       // stargate poolId - *must* be the poolId for the bridgeToken asset
        uint16 dstPoolId,                       // stargate destination poolId
        uint nativeAmountIn,                    // exact amount of native token coming in on source
        address to,                             // the address to send the destination tokens to
        uint amountOutMin,                      // minimum amount of stargatePoolId token to get out of amm router
        uint amountOutMinSg,                    // minimum amount of stargatePoolId token to get out on destination chain
        uint amountOutMinDest,                  // minimum amount of native token to receive on destination
        uint deadline,                          // overall deadline
        address destStargateComposed            // destination contract. it must implement sgReceive()
    ) external payable {

        require(nativeAmountIn > 0, "nativeAmountIn must be greater than 0");
        require(msg.value.sub(nativeAmountIn) > 0, "stargate requires fee to pay crosschain message");

        uint bridgeAmount;
        // using the amm router, swap native into the Stargate pool token, sending the output token to this contract
        {
            // create path[] for amm swap
            address[] memory path = new address[](2);
            path[0] = UniRouterV2(ammRouter).WETH();    // native IN requires that we specify the WETH in path[0]
            path[1] = bridgeToken;                             // the bridge token,

            uint[] memory amounts = UniRouterV2(ammRouter).swapExactETHForTokens{value:nativeAmountIn}(
                amountOutMin,
                path,
                address(this),
                deadline
            );

            bridgeAmount = amounts[1];
            require(bridgeAmount > 0, 'error: ammRouter gave us 0 tokens to swap() with stargate');

            // this contract needs to approve the stargateRouter to spend its path[1] token!
            IERC20(bridgeToken).approve(address(stargateRouter), bridgeAmount);
        }

        // encode payload data to send to destination contract, which it will handle with sgReceive()
        bytes memory data;
        {
            data = abi.encode(OUT_TO_NATIVE, deadline, amountOutMinDest, to);
        }

        // Stargate's Router.swap() function sends the tokens to the destination chain.
        IStargateRouter(stargateRouter).swap{value:msg.value.sub(nativeAmountIn)}(
            dstChainId,                                     // the destination chain id
            srcPoolId,                                      // the source Stargate poolId
            dstPoolId,                                      // the destination Stargate poolId
            payable(msg.sender),                            // refund adddress. if msg.sender pays too much gas, return extra eth
            bridgeAmount,                                   // total tokens to send to destination chain
            amountOutMinSg,                                 // minimum
            IStargateRouter.lzTxObj(500000, 0, "0x"),       // 500,000 for the sgReceive()
            abi.encodePacked(destStargateComposed),         // destination address, the sgReceive() implementer
            data                                            // bytes payload
        );
    }

    //-----------------------------------------------------------------------------------------------------------------------
    // sgReceive() - the destination contract must implement this function to receive the tokens and payload
    function sgReceive(uint16 _chainId, bytes memory _srcAddress, uint _nonce, address _token, uint amountLD, bytes memory payload) override external {
        require(msg.sender == address(stargateRouter), "only stargate router can call sgReceive!");

        (address _tokenOut, uint _deadline, uint _amountOutMin, address _toAddr) = abi.decode(payload, (address, uint, uint, address));

        // so that router can swap our tokens
        IERC20(_token).approve(address(ammRouter), amountLD);

        uint _toBalancePreTransferOut = address(_toAddr).balance;

        if(_tokenOut == address(0x0)){
            // they want to get out native tokens
            address[] memory path = new address[](2);
            path[0] = _token;
            path[1] = UniRouterV2(ammRouter).WETH();

            // use ammRouter to swap incoming bridge token into native tokens
            try UniRouterV2(ammRouter).swapExactTokensForETH(
                amountLD,           // the stable received from stargate at the destination
                _amountOutMin,      // slippage param, min amount native token out
                path,               // path[0]: stabletoken address, path[1]: WETH from sushi router
                _toAddr,            // the address to send the *out* native to
                _deadline           // the unix timestamp deadline
            ) {
                // success, the ammRouter should have sent the eth to them
                emit ReceivedOnDestination(OUT_TO_NATIVE, address(_toAddr).balance.sub(_toBalancePreTransferOut));
            } catch {
                // send transfer _token/amountLD to msg.sender because the swap failed for some reason
                IERC20(_token).transfer(_toAddr, amountLD);
                emit ReceivedOnDestination(_token, amountLD);
            }

        } else { // they want to get out erc20 tokens
            uint _toAddrTokenBalancePre = IERC20(_tokenOut).balanceOf(_toAddr);
            address[] memory path = new address[](2);
            path[0] = _token;
            path[1] = _tokenOut;
            try UniRouterV2(ammRouter).swapExactTokensForTokens(
                amountLD,           // the stable received from stargate at the destination
                _amountOutMin,      // slippage param, min amount native token out
                path,               // path[0]: stabletoken address, path[1]: WETH from sushi router
                _toAddr,            // the address to send the *out* tokens to
                _deadline           // the unix timestamp deadline
            ) {
                // success, the ammRouter should have sent the eth to them
                emit ReceivedOnDestination(_tokenOut, IERC20(_tokenOut).balanceOf(_toAddr).sub(_toAddrTokenBalancePre));
            } catch {
                // transfer _token/amountLD to msg.sender because the swap failed for some reason.
                // this is not the ideal scenario, but the contract needs to deliver them eth or USDC.
                IERC20(_token).transfer(_toAddr, amountLD);
                emit ReceivedOnDestination(_token, amountLD);
            }
        }
    }

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

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

interface UniFactoryV2 {
    //Address for tokenA and address for tokenB return address of pair contract (where one exists).
    //tokenA and tokenB order is interchangeable.
    //Returns 0x0000000000000000000000000000000000000000 as address where no pair exists.
    function getPair(address tokenA, address tokenB) external view returns (address pair);
}

interface UniRouterV2 {
    //Receive as many output tokens as possible for an exact amount of input tokens.
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);

    //Receive as many output tokens as possible for an exact amount of BNB.
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
    external
    returns (uint[] memory amounts);

    //Receive an exact amount of output tokens for as little BNB as possible.
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
    external
    payable
    returns (uint[] memory amounts);

    //Returns the canonical address for Binance: WBNB token
    //(WETH being a vestige from Ethereum network origins).
    function WETH() external pure returns (address);

    //Returns the canonical address for PancakeFactory.
    function factory() external pure returns (address);
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

interface IStargateReceiver {
    function sgReceive(
        uint16 _srcChainId,              // the remote chainId sending the tokens
        bytes memory _srcAddress,        // the remote Bridge address
        uint256 _nonce,
        address _token,                  // the token contract on the local chain
        uint256 amountLD,                // the qty of local _token contract tokens
        bytes memory payload
    ) external;
}

interface IStargateRouter {
    function swap(
        uint16 _dstChainId,
        uint256 _srcPoolId,
        uint256 _dstPoolId,
        address payable _refundAddress,
        uint256 _amountLD,
        uint256 _minAmountLD,
        lzTxObj memory _lzTxParams,
        bytes calldata _to,
        bytes calldata _payload
    ) external payable;

    // Router.sol method to get the value for swap()
    function quoteLayerZeroFee(
        uint16 _dstChainId,
        uint8 _functionType,
        bytes calldata _toAddress,
        bytes calldata _transferAndCallPayload,
        lzTxObj memory _lzTxParams
    ) external view returns (uint256, uint256);

    struct lzTxObj {
        uint256 dstGasForCall;
        uint256 dstNativeAmount;
        bytes dstNativeAddr;
    }
}