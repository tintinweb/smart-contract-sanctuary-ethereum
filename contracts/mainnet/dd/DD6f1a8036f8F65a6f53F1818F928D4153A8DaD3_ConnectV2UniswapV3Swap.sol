//SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;
pragma abicoder v2;

/**
 * @title Uniswap v3 swap.
 * @dev Decentralized Exchange.
 */

import { TokenInterface } from "../../../common/interfaces.sol";
import { Helpers } from "./helpers.sol";
import { Events } from "./events.sol";
import "./interface.sol";

abstract contract UniswapResolver is Helpers, Events {
	/**
	 * @dev Buy Function
	 * @notice Swap token(sellAddr) with token(buyAddr), buy token with minimum sell token
	 * @param _buyAddr token to be bought
	 * @param _sellAddr token to be sold
	 * @param _fee pool fees for buyAddr-sellAddr token pair
	 * @param _unitAmt The unit amount of sellAmt/buyAmt with slippage
	 * @param _buyAmt amount of token to be bought
	 * @param _getId Id to get buyAmt
	 * @param _setId Id to store sellAmt
	 */
	function buy(
		address _buyAddr,
		address _sellAddr,
		uint24 _fee,
		uint256 _unitAmt,
		uint256 _buyAmt,
		uint256 _getId,
		uint256 _setId
	)
		external
		payable
		returns (string memory _eventName, bytes memory _eventParam)
	{
		return
			_buy(
				BuyInfo({
					buyAddr: _buyAddr,
					sellAddr: _sellAddr,
					fee: _fee,
					unitAmt: _unitAmt,
					buyAmt: _buyAmt
				}),
				_getId,
				_setId
			);
	}

	/**
	 * @dev Sell Function
	 * @notice Swap token(sellAddr) with token(buyAddr), buy token with minimum sell token
	 * @param _buyAddr token to be bought
	 * @param _sellAddr token to be sold
	 * @param _fee pool fees for buyAddr-sellAddr token pair
	 * @param _unitAmt The unit amount of buyAmt/sellAmt with slippage
	 * @param _sellAmt amount of token to be sold
	 * @param _getId Id to get sellAmt
	 * @param _setId Id to store buyAmt
	 */
	function sell(
		address _buyAddr,
		address _sellAddr,
		uint24 _fee,
		uint256 _unitAmt,
		uint256 _sellAmt,
		uint256 _getId,
		uint256 _setId
	)
		external
		payable
		returns (string memory _eventName, bytes memory _eventParam)
	{
		return
			_sell(
				SellInfo({
					buyAddr: _buyAddr,
					sellAddr: _sellAddr,
					fee: _fee,
					unitAmt: _unitAmt,
					sellAmt: _sellAmt
				}),
				_getId,
				_setId
			);
	}
}

contract ConnectV2UniswapV3Swap is UniswapResolver {
	string public constant name = "UniswapV3-Swap-v1";
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;
pragma abicoder v2;

interface TokenInterface {
    function approve(address, uint256) external;
    function transfer(address, uint) external;
    function transferFrom(address, address, uint) external;
    function deposit() external payable;
    function withdraw(uint) external;
    function balanceOf(address) external view returns (uint);
    function decimals() external view returns (uint);
    function totalSupply() external view returns (uint);
}

interface MemoryInterface {
    function getUint(uint id) external returns (uint num);
    function setUint(uint id, uint val) external;
}

interface InstaMapping {
    function cTokenMapping(address) external view returns (address);
    function gemJoinMapping(bytes32) external view returns (address);
}

interface AccountInterface {
    function enable(address) external;
    function disable(address) external;
    function isAuth(address) external view returns (bool);
    function cast(
        string[] calldata _targetNames,
        bytes[] calldata _datas,
        address _origin
    ) external payable returns (bytes32[] memory responses);
}

interface ListInterface {
    function accountID(address) external returns (uint64);
}

interface InstaConnectors {
    function isConnectors(string[] calldata) external returns (bool, address[] memory);
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;
pragma abicoder v2;

import { TokenInterface } from "../../../common/interfaces.sol";
import { DSMath } from "../../../common/math.sol";
import { Basic } from "../../../common/basic.sol";
import "./interface.sol";

abstract contract Helpers is DSMath, Basic {
	/**
	 * @dev uniswap v3 Swap Router
	 */
	ISwapRouter02 constant swapRouter =
		ISwapRouter02(0x68b3465833fb72A70ecDF485E0e4C7bD8665Fc45);

	struct BuyInfo {
		address buyAddr; //token to be bought
		address sellAddr; //token to be sold
		uint24 fee; //pool fees for buyAddr-sellAddr token pair
		uint256 unitAmt; //The unit amount of sellAmt/buyAmt with slippage
		uint256 buyAmt; //amount of token to be bought
	}

	struct SellInfo {
		address buyAddr; //token to be bought
		address sellAddr; //token to be sold
		uint24 fee; //pool fees for buyAddr-sellAddr token pair
		uint256 unitAmt; //The unit amount of buyAmt/sellAmt with slippage.
		uint256 sellAmt; //amount of token to be bought
	}

	/**
	 * @dev Buy Function
	 * @notice Swap token(sellAddr) with token(buyAddr), buy token with minimum sell token
	 * @param buyData Data input for the buy action
	 * @param getId Id to get buyAmt
	 * @param setId Id to store sellAmt
	 */
	function _buy(
		BuyInfo memory buyData,
		uint256 getId,
		uint256 setId
	) internal returns (string memory _eventName, bytes memory _eventParam) {
		uint256 _buyAmt = getUint(getId, buyData.buyAmt);

		(TokenInterface _buyAddr, TokenInterface _sellAddr) = changeEthAddress(
			buyData.buyAddr,
			buyData.sellAddr
		);

		uint256 _slippageAmt = convert18ToDec(
			_sellAddr.decimals(),
			wmul(buyData.unitAmt, convertTo18(_buyAddr.decimals(), _buyAmt))
		);
		bool isEth = address(buyData.sellAddr) == ethAddr;
		convertEthToWeth(isEth, _sellAddr, _slippageAmt);
		approve(_sellAddr, address(swapRouter), _slippageAmt);

		ExactOutputSingleParams memory params = ExactOutputSingleParams({
			tokenIn: address(_sellAddr),
			tokenOut: address(_buyAddr),
			fee: buyData.fee,
			recipient: address(this),
			amountOut: _buyAmt,
			amountInMaximum: _slippageAmt, //require(_sellAmt <= amountInMaximum)
			sqrtPriceLimitX96: 0
		});
		uint256 _sellAmt = swapRouter.exactOutputSingle(params);
		require(_slippageAmt >= _sellAmt, "Too much slippage");

		if (_slippageAmt > _sellAmt) {
			convertEthToWeth(isEth, _sellAddr, _slippageAmt - _sellAmt);
			approve(_sellAddr, address(swapRouter), 0);
		}
		isEth = address(buyData.buyAddr) == ethAddr;
		convertWethToEth(isEth, _buyAddr, _buyAmt);

		setUint(setId, _sellAmt);

		_eventName = "LogBuy(address,address,uint256,uint256,uint256,uint256)";
		_eventParam = abi.encode(
			buyData.buyAddr,
			buyData.sellAddr,
			_buyAmt,
			_sellAmt,
			getId,
			setId
		);
	}

	/**
	 * @dev Sell Function
	 * @notice Swap token(sellAddr) with token(buyAddr), to get max buy tokens
	 * @param sellData Data input for the sell action
	 * @param getId Id to get buyAmt
	 * @param setId Id to store sellAmt
	 */
	function _sell(
		SellInfo memory sellData,
		uint256 getId,
		uint256 setId
	) internal returns (string memory _eventName, bytes memory _eventParam) {
		uint256 _sellAmt = getUint(getId, sellData.sellAmt);
		(TokenInterface _buyAddr, TokenInterface _sellAddr) = changeEthAddress(
			sellData.buyAddr,
			sellData.sellAddr
		);

		if (_sellAmt == uint256(-1)) {
			_sellAmt = sellData.sellAddr == ethAddr
				? address(this).balance
				: _sellAddr.balanceOf(address(this));
		}

		uint256 _slippageAmt = convert18ToDec(
			_buyAddr.decimals(),
			wmul(sellData.unitAmt, convertTo18(_sellAddr.decimals(), _sellAmt))
		);

		bool isEth = address(sellData.sellAddr) == ethAddr;
		convertEthToWeth(isEth, _sellAddr, _sellAmt);
		approve(_sellAddr, address(swapRouter), _sellAmt);
		ExactInputSingleParams memory params = ExactInputSingleParams({
			tokenIn: address(_sellAddr),
			tokenOut: address(_buyAddr),
			fee: sellData.fee,
			recipient: address(this),
			amountIn: _sellAmt,
			amountOutMinimum: _slippageAmt, //require(_buyAmt >= amountOutMinimum)
			sqrtPriceLimitX96: 0
		});
		uint256 _buyAmt = swapRouter.exactInputSingle(params);
		require(_slippageAmt <= _buyAmt, "Too much slippage");

		isEth = address(sellData.buyAddr) == ethAddr;
		convertWethToEth(isEth, _buyAddr, _buyAmt);

		setUint(setId, _buyAmt);

		_eventName = "LogSell(address,address,uint256,uint256,uint256,uint256)";
		_eventParam = abi.encode(
			sellData.buyAddr,
			sellData.sellAddr,
			_buyAmt,
			_sellAmt,
			getId,
			setId
		);
	}
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

contract Events {
	event LogBuy(
		address indexed buyToken,
		address indexed sellToken,
		uint256 buyAmt,
		uint256 sellAmt,
		uint256 getId,
		uint256 setId
	);

	event LogSell(
		address indexed buyToken,
		address indexed sellToken,
		uint256 buyAmt,
		uint256 sellAmt,
		uint256 getId,
		uint256 setId
	);
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;
pragma abicoder v2;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Metadata.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Enumerable.sol";

struct ExactInputSingleParams {
	address tokenIn;
	address tokenOut;
	uint24 fee;
	address recipient;
	uint256 amountIn;
	uint256 amountOutMinimum;
	uint160 sqrtPriceLimitX96;
}

struct ExactInputParams {
	bytes path;
	address recipient;
	uint256 amountIn;
	uint256 amountOutMinimum;
}

struct ExactOutputSingleParams {
	address tokenIn;
	address tokenOut;
	uint24 fee;
	address recipient;
	uint256 amountOut;
	uint256 amountInMaximum;
	uint160 sqrtPriceLimitX96;
}

struct ExactOutputParams {
	bytes path;
	address recipient;
	uint256 amountOut;
	uint256 amountInMaximum;
}

/// @title Callback for IUniswapV3PoolActions#swap
/// @notice Any contract that calls IUniswapV3PoolActions#swap must implement this interface
interface IUniswapV3SwapCallback {
	/// @notice Called to `msg.sender` after executing a swap via IUniswapV3Pool#swap.
	/// @dev In the implementation you must pay the pool tokens owed for the swap.
	/// The caller of this method must be checked to be a UniswapV3Pool deployed by the canonical UniswapV3Factory.
	/// amount0Delta and amount1Delta can both be 0 if no tokens were swapped.
	/// @param amount0Delta The amount of token0 that was sent (negative) or must be received (positive) by the pool by
	/// the end of the swap. If positive, the callback must send that amount of token0 to the pool.
	/// @param amount1Delta The amount of token1 that was sent (negative) or must be received (positive) by the pool by
	/// the end of the swap. If positive, the callback must send that amount of token1 to the pool.
	/// @param data Any data passed through by the caller via the IUniswapV3PoolActions#swap call
	function uniswapV3SwapCallback(
		int256 amount0Delta,
		int256 amount1Delta,
		bytes calldata data
	) external;
}

interface IV3SwapRouter is IUniswapV3SwapCallback {
	/// @notice Swaps `amountIn` of one token for as much as possible of another token
	/// @dev Setting `amountIn` to 0 will cause the contract to look up its own balance,
	/// and swap the entire amount, enabling contracts to send tokens before calling this function.
	/// @param params The parameters necessary for the swap, encoded as `ExactInputSingleParams` in calldata
	/// @return amountOut The amount of the received token
	function exactInputSingle(ExactInputSingleParams calldata params)
		external
		payable
		returns (uint256 amountOut);

	/// @notice Swaps `amountIn` of one token for as much as possible of another along the specified path
	/// @dev Setting `amountIn` to 0 will cause the contract to look up its own balance,
	/// and swap the entire amount, enabling contracts to send tokens before calling this function.
	/// @param params The parameters necessary for the multi-hop swap, encoded as `ExactInputParams` in calldata
	/// @return amountOut The amount of the received token
	function exactInput(ExactInputParams calldata params)
		external
		payable
		returns (uint256 amountOut);

	/// @notice Swaps as little as possible of one token for `amountOut` of another token
	/// that may remain in the router after the swap.
	/// @param params The parameters necessary for the swap, encoded as `ExactOutputSingleParams` in calldata
	/// @return amountIn The amount of the input token
	function exactOutputSingle(ExactOutputSingleParams calldata params)
		external
		payable
		returns (uint256 amountIn);

	/// @notice Swaps as little as possible of one token for `amountOut` of another along the specified path (reversed)
	/// that may remain in the router after the swap.
	/// @param params The parameters necessary for the multi-hop swap, encoded as `ExactOutputParams` in calldata
	/// @return amountIn The amount of the input token
	function exactOutput(ExactOutputParams calldata params)
		external
		payable
		returns (uint256 amountIn);
}

interface IApproveAndCall {}

/// @title Multicall interface
/// @notice Enables calling multiple methods in a single call to the contract
interface IMulticall {

}

/// @title MulticallExtended interface
/// @notice Enables calling multiple methods in a single call to the contract with optional validation
interface IMulticallExtended is IMulticall {

}

/// @title Self Permit
/// @notice Functionality to call permit on any EIP-2612-compliant token for use in the route
interface ISelfPermit {

}

/// @title Router token swapping functionality
/// @notice Functions for swapping tokens via Uniswap V2
interface IV2SwapRouter {

}

interface ISwapRouter02 is
	IV2SwapRouter,
	IV3SwapRouter,
	IApproveAndCall,
	IMulticallExtended,
	ISelfPermit
{}

//SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

import { SafeMath } from "@openzeppelin/contracts/math/SafeMath.sol";

contract DSMath {
  uint constant WAD = 10 ** 18;
  uint constant RAY = 10 ** 27;

  function add(uint x, uint y) internal pure returns (uint z) {
    z = SafeMath.add(x, y);
  }

  function sub(uint x, uint y) internal virtual pure returns (uint z) {
    z = SafeMath.sub(x, y);
  }

  function mul(uint x, uint y) internal pure returns (uint z) {
    z = SafeMath.mul(x, y);
  }

  function div(uint x, uint y) internal pure returns (uint z) {
    z = SafeMath.div(x, y);
  }

  function wmul(uint x, uint y) internal pure returns (uint z) {
    z = SafeMath.add(SafeMath.mul(x, y), WAD / 2) / WAD;
  }

  function wdiv(uint x, uint y) internal pure returns (uint z) {
    z = SafeMath.add(SafeMath.mul(x, WAD), y / 2) / y;
  }

  function rdiv(uint x, uint y) internal pure returns (uint z) {
    z = SafeMath.add(SafeMath.mul(x, RAY), y / 2) / y;
  }

  function rmul(uint x, uint y) internal pure returns (uint z) {
    z = SafeMath.add(SafeMath.mul(x, y), RAY / 2) / RAY;
  }

  function toInt(uint x) internal pure returns (int y) {
    y = int(x);
    require(y >= 0, "int-overflow");
  }

  function toUint(int256 x) internal pure returns (uint256) {
      require(x >= 0, "int-overflow");
      return uint256(x);
  }

  function toRad(uint wad) internal pure returns (uint rad) {
    rad = mul(wad, 10 ** 27);
  }

}

//SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

import { TokenInterface } from "./interfaces.sol";
import { Stores } from "./stores.sol";
import { DSMath } from "./math.sol";

abstract contract Basic is DSMath, Stores {

    function convert18ToDec(uint _dec, uint256 _amt) internal pure returns (uint256 amt) {
        amt = (_amt / 10 ** (18 - _dec));
    }

    function convertTo18(uint _dec, uint256 _amt) internal pure returns (uint256 amt) {
        amt = mul(_amt, 10 ** (18 - _dec));
    }

    function getTokenBal(TokenInterface token) internal view returns(uint _amt) {
        _amt = address(token) == ethAddr ? address(this).balance : token.balanceOf(address(this));
    }

    function getTokensDec(TokenInterface buyAddr, TokenInterface sellAddr) internal view returns(uint buyDec, uint sellDec) {
        buyDec = address(buyAddr) == ethAddr ?  18 : buyAddr.decimals();
        sellDec = address(sellAddr) == ethAddr ?  18 : sellAddr.decimals();
    }

    function encodeEvent(string memory eventName, bytes memory eventParam) internal pure returns (bytes memory) {
        return abi.encode(eventName, eventParam);
    }

    function approve(TokenInterface token, address spender, uint256 amount) internal {
        try token.approve(spender, amount) {

        } catch {
            token.approve(spender, 0);
            token.approve(spender, amount);
        }
    }

    function changeEthAddress(address buy, address sell) internal pure returns(TokenInterface _buy, TokenInterface _sell){
        _buy = buy == ethAddr ? TokenInterface(wethAddr) : TokenInterface(buy);
        _sell = sell == ethAddr ? TokenInterface(wethAddr) : TokenInterface(sell);
    }

    function changeEthAddrToWethAddr(address token) internal pure returns(address tokenAddr){
        tokenAddr = token == ethAddr ? wethAddr : token;
    }

    function convertEthToWeth(bool isEth, TokenInterface token, uint amount) internal {
        if(isEth) token.deposit{value: amount}();
    }

    function convertWethToEth(bool isEth, TokenInterface token, uint amount) internal {
       if(isEth) {
            approve(token, address(token), amount);
            token.withdraw(amount);
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
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
        require(b <= a, "SafeMath: subtraction overflow");
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
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
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
        require(b > 0, "SafeMath: division by zero");
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
        require(b > 0, "SafeMath: modulo by zero");
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
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
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
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

import { MemoryInterface, InstaMapping, ListInterface, InstaConnectors } from "./interfaces.sol";


abstract contract Stores {

  /**
   * @dev Return ethereum address
   */
  address constant internal ethAddr = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

  /**
   * @dev Return Wrapped ETH address
   */
  address constant internal wethAddr = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

  /**
   * @dev Return memory variable address
   */
  MemoryInterface constant internal instaMemory = MemoryInterface(0x8a5419CfC711B2343c17a6ABf4B2bAFaBb06957F);

  /**
   * @dev Return InstaDApp Mapping Addresses
   */
  InstaMapping constant internal instaMapping = InstaMapping(0xe81F70Cc7C0D46e12d70efc60607F16bbD617E88);

  /**
   * @dev Return InstaList Address
   */
  ListInterface internal constant instaList = ListInterface(0x4c8a1BEb8a87765788946D6B19C6C6355194AbEb);

  /**
	 * @dev Return connectors registry address
	 */
	InstaConnectors internal constant instaConnectors = InstaConnectors(0x97b0B3A8bDeFE8cB9563a3c610019Ad10DB8aD11);

  /**
   * @dev Get Uint value from InstaMemory Contract.
   */
  function getUint(uint getId, uint val) internal returns (uint returnVal) {
    returnVal = getId == 0 ? val : instaMemory.getUint(getId);
  }

  /**
  * @dev Set Uint value in InstaMemory Contract.
  */
  function setUint(uint setId, uint val) virtual internal {
    if (setId != 0) instaMemory.setUint(setId, val);
  }

}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

import "../../introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint256 tokenId) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /**
      * @dev Safely transfers `tokenId` token from `from` to `to`.
      *
      * Requirements:
      *
      * - `from` cannot be the zero address.
      * - `to` cannot be the zero address.
      * - `tokenId` token must exist and be owned by `from`.
      * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
      * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
      *
      * Emits a {Transfer} event.
      */
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

import "./IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {

    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

import "./IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Enumerable is IERC721 {

    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}