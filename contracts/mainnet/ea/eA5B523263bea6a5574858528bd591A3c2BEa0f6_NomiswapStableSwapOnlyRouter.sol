// SPDX-License-Identifier: MIT
pragma solidity =0.8.15;

import '@nominex/stable-swap/contracts/interfaces/INomiswapFactory.sol';
import '@nominex/stable-swap/contracts/interfaces/INomiswapStablePair.sol';

contract NomiswapStableSwapOnlyRouter {

    address public immutable stableSwapFactory;

    constructor(address _stableSwapFactory) {
        stableSwapFactory = _stableSwapFactory;
    }
    
    modifier ensure(uint deadline) {
        require(deadline >= block.timestamp, 'NomiswapRouter: EXPIRED');
        _;
    }

    receive() external payable {
        require(msg.sender == 0x0000000000000000000000000000000000000000, 'NomiswapRouter: no payments'); // accept no ETH via fallback
    }

    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external ensure(deadline) returns (uint[] memory) {
        (address[] memory pairs, uint[] memory amounts) = getAmountsOut(amountIn, path, to);
        require(amounts[amounts.length - 1] >= amountOutMin, 'NomiswapRouter: INSUFFICIENT_OUTPUT_AMOUNT');
        safeTransferFrom(path[0], msg.sender, pairs[0], amountIn);
        _swap(pairs, amounts, path[0] < path[1]);
        return amounts;
    }

    // requires the initial amount to have already been sent to the first pair
    function _swap(address[] memory pairs, uint[] memory amounts, bool swapToken0) private {
        bytes memory data = new bytes(0);
        for (uint i; i < pairs.length - 1; i++) {
            INomiswapPair(pairs[i]).swap(swapToken0 ? 0 : amounts[i + 1], swapToken0 ? amounts[i + 1] : 0, pairs[i + 1], data);
        }
    }

    function getAmountsOut(uint amountIn, address[] memory path, address to) private view returns (address[] memory pairs, uint[] memory amounts) {
        require(path.length >= 2, 'NomiswapLibrary: INVALID_PATH');
        pairs = new address[](path.length);
        amounts = new uint[](path.length);
        amounts[0] = amountIn;
        for (uint i; i < path.length - 1; i++) {
            pairs[i] = INomiswapFactory(stableSwapFactory).getPair(path[i], path[i + 1]);
            amounts[i + 1] = INomiswapStablePair(pairs[i]).getAmountOut(path[i], amounts[i]);
        }
        pairs[path.length - 1] = to;
    }

    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) private {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            'TransferHelper::transferFrom: transferFrom failed'
        );
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

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

import "./INomiswapPair.sol";
pragma experimental ABIEncoderV2;

interface INomiswapStablePair is INomiswapPair {

    event RampA(uint256 oldA, uint256 newA, uint256 initialTime, uint256 futureTime);
    event StopRampA(uint256 A, uint256 t);

    function devFee() external view returns (uint128);

//    function burnSingle(address tokenOut, address recipient) external returns (uint256 amountOut);

    function getA() external view returns (uint256);

    function setSwapFee(uint32) external;
    function setDevFee(uint128) external;

    function rampA(uint32 _futureA, uint40 _futureTime) external;
    function stopRampA() external;

    function getAmountIn(address tokenIn, uint256 amountOut) external view returns (uint256);
    function getAmountOut(address tokenIn, uint256 amountIn) external view returns (uint256);

}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

import "./INomiswapERC20.sol";

interface INomiswapPair is INomiswapERC20 {

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);

    function swapFee() external view returns (uint32);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.5.0;

interface INomiswapFactory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);
    function INIT_CODE_HASH() external view returns (bytes32);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
    function setSwapFee(address pair, uint32 swapFee) external;
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

interface INomiswapERC20 is IERC20Metadata {
    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;
}