// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "./interfaces/IRouter.sol";
import "./interfaces/IWETH.sol";
import "./libraries/DEXLibrary.sol";

import "./../core/interfaces/IERC20Pair.sol";
import "./../core/interfaces/IPoolFactory.sol";

contract Router is IRouter {
    address public immutable override factory;

    address public immutable override WNative;

    constructor(address _factory, address _WNative) {
        factory = _factory;
        WNative = _WNative;
    }

    modifier ensure(uint256 deadline) {
        require(deadline >= block.timestamp, "Router: EXPIRED");
        _;
    }

    receive() external payable {
        assert(msg.sender == WNative);
        // only accept Native via fallback from the WNative contract
    }

    // SWAP

    function _swap(
        uint256[] memory amounts,
        address[] memory path,
        uint32[] calldata feePath,
        address _to
    ) internal virtual {
        for (uint256 i; i < path.length - 1; i++) {
            (address input, address output) = (path[i], path[i + 1]);
            (address token0,) = DEXLibrary.sortTokens(input, output);
            uint256 amountOut = amounts[i + 1];
            (uint256 amount0Out, uint256 amount1Out) = input == token0
            ? (uint256(0), amountOut)
            : (amountOut, uint256(0));
            address to = i < path.length - 2
            ? DEXLibrary.pairFor(factory, output, path[i + 2], feePath[i])
            : _to;
            IERC20Pair(DEXLibrary.pairFor(factory, input, output, feePath[i]))
            .swap(amount0Out, amount1Out, to, new bytes(0));
        }
    }

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        uint32[] calldata feePath,
        address to,
        uint256 deadline
    )
    external
    virtual
    override
    ensure(deadline)
    returns (uint256[] memory amounts)
    {
        amounts = DEXLibrary.getAmountsOut(factory, amountIn, path, feePath);
        require(
            amounts[amounts.length - 1] >= amountOutMin,
            "Router: INSUFFICIENT_OUTPUT_AMOUNT"
        );
        safeTransferFrom(
            path[0],
            msg.sender,
            DEXLibrary.pairFor(factory, path[0], path[1], feePath[0]),
            amounts[0]
        );
        _swap(amounts, path, feePath, to);
    }

    function swapTokensForExactTokens(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        uint32[] calldata feePath,
        address to,
        uint256 deadline
    )
    external
    virtual
    override
    ensure(deadline)
    returns (uint256[] memory amounts)
    {
        amounts = DEXLibrary.getAmountsIn(factory, amountOut, path, feePath);
        require(amounts[0] <= amountInMax, "Router: EXCESSIVE_INPUT_AMOUNT");
        safeTransferFrom(
            path[0],
            msg.sender,
            DEXLibrary.pairFor(factory, path[0], path[1], feePath[0]),
            amounts[0]
        );
        _swap(amounts, path, feePath, to);
    }

    function swapExactNativeForTokens(
        uint256 amountOutMin,
        address[] calldata path,
        uint32[] calldata feePath,
        address to,
        uint256 deadline
    )
    external
    payable
    virtual
    override
    ensure(deadline)
    returns (uint256[] memory amounts)
    {
        require(path[0] == WNative, "Router: INVALID_PATH");
        amounts = DEXLibrary.getAmountsOut(factory, msg.value, path, feePath);
        require(
            amounts[amounts.length - 1] >= amountOutMin,
            "Router: INSUFFICIENT_OUTPUT_AMOUNT"
        );
        IWETH(WNative).deposit{value : amounts[0]}();
        assert(
            IWETH(WNative).transfer(
                DEXLibrary.pairFor(factory, path[0], path[1], feePath[0]),
                amounts[0]
            )
        );
        _swap(amounts, path, feePath, to);
    }

    function swapTokensForExactNative(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        uint32[] calldata feePath,
        address to,
        uint256 deadline
    )
    external
    virtual
    override
    ensure(deadline)
    returns (uint256[] memory amounts)
    {
        require(path[path.length - 1] == WNative, "Router: INVALID_PATH");
        amounts = DEXLibrary.getAmountsIn(factory, amountOut, path, feePath);
        require(amounts[0] <= amountInMax, "Router: EXCESSIVE_INPUT_AMOUNT");
        safeTransferFrom(
            path[0],
            msg.sender,
            DEXLibrary.pairFor(factory, path[0], path[1], feePath[0]),
            amounts[0]
        );
        _swap(amounts, path, feePath, address(this));
        IWETH(WNative).withdraw(amounts[amounts.length - 1]);
        safeTransferNative(to, amounts[amounts.length - 1]);
    }

    // **** ADD LIQUIDITY ****
    function _addLiquidity(
        address tokenA,
        address tokenB,
        uint32 fee,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin
    ) internal virtual returns (uint256 amountA, uint256 amountB) {
        // create the pair if it doesn't exist yet
        if (IPoolFactory(factory).getPair(tokenA, tokenB, fee) == address(0)) {
            IPoolFactory(factory).createPair(tokenA, tokenB, fee);
        }
        (uint256 reserveA, uint256 reserveB) = DEXLibrary.getReserves(
            factory,
            tokenA,
            tokenB,
            fee
        );
        if (reserveA == 0 && reserveB == 0) {
            (amountA, amountB) = (amountADesired, amountBDesired);
        } else {
            uint256 amountBOptimal = this.quote(
                amountADesired,
                reserveA,
                reserveB
            );
            if (amountBOptimal <= amountBDesired) {
                require(
                    amountBOptimal >= amountBMin,
                    "Router: INSUFFICIENT B AMOUNT"
                );
                (amountA, amountB) = (amountADesired, amountBOptimal);
            } else {
                uint256 amountAOptimal = this.quote(
                    amountBDesired,
                    reserveB,
                    reserveA
                );
                assert(amountAOptimal <= amountADesired);
                require(
                    amountAOptimal >= amountAMin,
                    "Router: INSUFFICIENT A AMOUNT"
                );
                (amountA, amountB) = (amountAOptimal, amountBDesired);
            }
        }
    }

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint32 fee,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    )
    external
    virtual
    override
    ensure(deadline)
    returns (
        uint256 amountA,
        uint256 amountB,
        uint256 liquidity
    )
    {
        (amountA, amountB) = _addLiquidity(
            tokenA,
            tokenB,
            fee,
            amountADesired,
            amountBDesired,
            amountAMin,
            amountBMin
        );
        {
            address _tokenA = tokenA;
            address _tokenB = tokenB;
            uint32 _fee = fee;
            address pair = DEXLibrary.pairFor(factory, _tokenA, _tokenB, _fee);
            safeTransferFrom(_tokenA, msg.sender, pair, amountA);
            safeTransferFrom(_tokenB, msg.sender, pair, amountB);
            liquidity = IERC20Pair(pair).mint(to);
        }
    }

    function addLiquidityNative(
        address token,
        uint32 fee,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountNativeMin,
        address to,
        uint256 deadline
    )
    external
    payable
    virtual
    override
    ensure(deadline)
    returns (
        uint256 amountToken,
        uint256 amountNative,
        uint256 liquidity
    )
    {
        (amountToken, amountNative) = _addLiquidity(
            token,
            WNative,
            fee,
            amountTokenDesired,
            msg.value,
            amountTokenMin,
            amountNativeMin
        );
        address pair = DEXLibrary.pairFor(factory, token, WNative, fee);
        safeTransferFrom(token, msg.sender, pair, amountToken);
        IWETH(WNative).deposit{value : amountNative}();
        assert(IWETH(WNative).transfer(pair, amountNative));
        liquidity = IERC20Pair(pair).mint(to);
        // refund dust Native, if any
        if (msg.value > amountNative)
            safeTransferNative(msg.sender, msg.value - amountNative);
    }

    // **** REMOVE LIQUIDITY ****
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint32 fee,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    )
    public
    virtual
    override
    ensure(deadline)
    returns (uint256 amountA, uint256 amountB)
    {
        address pair = DEXLibrary.pairFor(factory, tokenA, tokenB, fee);
        IERC20Pair(pair).transferFrom(msg.sender, pair, liquidity);
        // send liquidity to pair
        (uint256 amount0, uint256 amount1) = IERC20Pair(pair).burn(to);
        (address token0,) = DEXLibrary.sortTokens(tokenA, tokenB);
        (amountA, amountB) = tokenA == token0
        ? (amount0, amount1)
        : (amount1, amount0);
        require(amountA >= amountAMin, "Router: INSUFFICIENT_A_AMOUNT");
        require(amountB >= amountBMin, "Router: INSUFFICIENT_B_AMOUNT");
    }

    function removeLiquidityNative(
        address token,
        uint32 fee,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountNativeMin,
        address to,
        uint256 deadline
    )
    public
    virtual
    override
    ensure(deadline)
    returns (uint256 amountToken, uint256 amountNative)
    {
        (amountToken, amountNative) = removeLiquidity(
            token,
            WNative,
            fee,
            liquidity,
            amountTokenMin,
            amountNativeMin,
            address(this),
            deadline
        );
        safeTransfer(token, to, amountToken);
        IWETH(WNative).withdraw(amountNative);
        safeTransferNative(to, amountNative);
    }

    // **** LIBRARY FUNCTIONS ****
    function quote(
        uint256 amountA,
        uint256 reserveA,
        uint256 reserveB
    ) external pure virtual override returns (uint256 amountB) {
        return DEXLibrary.quote(amountA, reserveA, reserveB);
    }

    function quoteByTokens(
        uint256 amountA,
        address tokenA,
        address tokenB,
        uint32 fee
    ) external view virtual override returns (uint256 amountB) {
        amountB = 0;
        address poolAddress = IPoolFactory(factory).getPair(
            tokenA,
            tokenB,
            fee
        );
        if (poolAddress != address(0)) {
            (uint256 reserveA, uint256 reserveB) = DEXLibrary.getReserves(
                factory,
                tokenA,
                tokenB,
                fee
            );
            amountB = DEXLibrary.quote(amountA, reserveA, reserveB);
        }
    }

    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut,
        uint32 fee
    ) external pure virtual override returns (uint256 amountOut) {
        return DEXLibrary.getAmountOut(amountIn, reserveIn, reserveOut, fee);
    }

    function getAmountIn(
        uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut,
        uint32 fee
    ) external pure virtual override returns (uint256 amountIn) {
        return DEXLibrary.getAmountIn(amountOut, reserveIn, reserveOut, fee);
    }

    function getAmountsOut(
        uint256 amountIn,
        address[] memory path,
        uint32[] calldata feePath
    ) external view virtual override returns (uint256[] memory amounts) {
        require(path.length >= 2, "INVALID_PATH");
        for (uint256 i; i < path.length - 1; i++) {
            address poolAddress = IPoolFactory(factory).getPair(
                path[i],
                path[i + 1],
                feePath[i]
            );
            if (poolAddress == address(0)) {
                amounts = new uint256[](2);
                amounts[0] = 0;
                amounts[1] = 0;
                return amounts;
            }
        }
        return DEXLibrary.getAmountsOut(factory, amountIn, path, feePath);
    }

    function getAmountsIn(
        uint256 amountOut,
        address[] memory path,
        uint32[] calldata feePath
    ) external view virtual override returns (uint256[] memory amounts) {
        require(path.length >= 2, "INVALID_PATH");
        for (uint256 i; i < path.length - 1; i++) {
            address poolAddress = IPoolFactory(factory).getPair(
                path[i],
                path[i + 1],
                feePath[i]
            );
            if (poolAddress == address(0)) {
                amounts = new uint256[](2);
                amounts[0] = 0;
                amounts[1] = 0;
                return amounts;
            }
        }
        return DEXLibrary.getAmountsIn(factory, amountOut, path, feePath);
    }

    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(0x23b872dd, from, to, value)
        );
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "Router::transferFrom: transferFrom failed"
        );
    }

    function safeTransfer(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(0xa9059cbb, to, value)
        );
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "Router::safeTransfer: transfer failed"
        );
    }

    function safeTransferNative(address to, uint256 value) internal {
        (bool success,) = to.call{value : value}(new bytes(0));
        require(success, "Router::safeTransferNative: Native transfer failed");
    }

    function pairAddress(
        address tokenA,
        address tokenB,
        uint32 poolFee
    ) external view returns (address) {
        return IPoolFactory(factory).getPair(tokenA, tokenB, poolFee);
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
pragma solidity ^0.8.0;

interface IRouter {
    function factory() external view returns (address);

    function WNative() external view returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint32 fee,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    )
    external
    returns (
        uint256 amountA,
        uint256 amountB,
        uint256 liquidity
    );

    function addLiquidityNative(
        address token,
        uint32 fee,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountNativeMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountNative, uint liquidity);

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint32 fee,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityNative(
        address token,
        uint32 fee,
        uint liquidity,
        uint amountTokenMin,
        uint amountNativeMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountNative);

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        uint32[] calldata feePath,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapTokensForExactTokens(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        uint32[] calldata feePath,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactNativeForTokens(uint amountOutMin, address[] calldata path, uint32[] calldata feePath, address to, uint deadline)
    external
    payable
    returns (uint[] memory amounts);

    function swapTokensForExactNative(uint amountOut, uint amountInMax, address[] calldata path, uint32[] calldata feePath, address to, uint deadline)
    external
    returns (uint[] memory amounts);

    function quote(
        uint256 amountA,
        uint256 reserveA,
        uint256 reserveB
    ) external pure returns (uint256 amountB);

    function quoteByTokens(
        uint256 amountA,
        address tokenA,
        address tokenB,
        uint32 fee
    ) external view returns (uint256 amountB);

    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut,
        uint32 fee
    ) external pure returns (uint256 amountOut);

    function getAmountIn(
        uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut,
        uint32 fee
    ) external pure returns (uint256 amountIn);

    function getAmountsOut(uint256 amountIn, address[] memory path, uint32[] calldata feePath)
    external
    view
    returns (uint256[] memory amounts);

    function getAmountsIn(uint256 amountOut, address[] memory path, uint32[] calldata feePath)
    external
    view
    returns (uint256[] memory amounts);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IWETH {
    function deposit() external payable;

    function transfer(address to, uint256 value) external returns (bool);

    function withdraw(uint256) external;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "./../../core/interfaces/IERC20Pair.sol";
import "./../../core/library/SafeMath.sol";

//import "./../../core/ERC20Pair.sol";

library DEXLibrary {
    using SafeMath for uint256;

    // returns sorted token addresses, used to handle return values from pairs sorted in this order
    function sortTokens(address tokenA, address tokenB)
        internal
        pure
        returns (address token0, address token1)
    {
        require(tokenA != tokenB, "DEXLibrary: IDENTICAL_ADDRESSES");
        (token0, token1) = tokenA < tokenB
            ? (tokenA, tokenB)
            : (tokenB, tokenA);
        require(token0 != address(0), "DEXLibrary: ZERO_ADDRESS");
    }

    /* function hashCode() public pure returns (bytes32){
         bytes memory bytecode = type(ERC20Pair).creationCode;
         return keccak256(abi.encodePacked(bytecode));
     }*/
    // calculates the CREATE2 address for a pair without making any external calls
    function pairFor(
        address factory,
        address tokenA,
        address tokenB,
        uint32 poolFee
    ) public pure returns (address pair) {
        (address token0, address token1) = sortTokens(tokenA, tokenB);
        pair = address(
            uint160(
                uint256(
                    keccak256(
                        abi.encodePacked(
                            hex"ff",
                            factory,
                            keccak256(
                                abi.encodePacked(token0, token1, poolFee)
                            ),
                            hex"4865ea389995915db67b44b39fd00c73c081158e770991b408389498fb8dc480"
                        )
                    )
                )
            )
        );
    }

    // fetches and sorts the reserves for a pair
    function getReserves(
        address factory,
        address tokenA,
        address tokenB,
        uint32 poolFee
    ) internal view returns (uint256 reserveA, uint256 reserveB) {
        (address token0, ) = sortTokens(tokenA, tokenB);
        (uint256 reserve0, uint256 reserve1, ) = IERC20Pair(
            pairFor(factory, tokenA, tokenB, poolFee)
        ).getReserves();
        (reserveA, reserveB) = tokenA == token0
            ? (reserve0, reserve1)
            : (reserve1, reserve0);
    }

    // given some amount of an asset and pair reserves, returns an equivalent amount of the other asset
    function quote(
        uint256 amountA,
        uint256 reserveA,
        uint256 reserveB
    ) internal pure returns (uint256 amountB) {
        require(amountA > 0, "DEXLibrary: INSUFFICIENT_AMOUNT");
        require(
            reserveA > 0 && reserveB > 0,
            "DEXLibrary: INSUFFICIENT_LIQUIDITY"
        );
        amountB = amountA.mul(reserveB) / reserveA;
    }

    // given an input amount of an asset and pair reserves, returns the maximum output amount of the other asset
    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut,
        uint32 fee
    ) internal pure returns (uint256 amountOut) {
        require(amountIn > 0, "DEXLibrary: INSUFFICIENT_INPUT_AMOUNT");
        require(
            reserveIn > 0 && reserveOut > 0,
            "DEXLibrary: INSUFFICIENT_LIQUIDITY"
        );
        uint256 amountInWithFee = amountIn.mul(10**5 - fee);
        uint256 numerator = amountInWithFee.mul(reserveOut);
        uint256 denominator = reserveIn.mul(10**5).add(amountInWithFee);
        amountOut = numerator / denominator;
    }

    // given an output amount of an asset and pair reserves, returns a required input amount of the other asset
    function getAmountIn(
        uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut,
        uint32 fee
    ) internal pure returns (uint256 amountIn) {
        require(amountOut > 0, "DEXLibrary: INSUFFICIENT_OUTPUT_AMOUNT");
        require(
            reserveIn > 0 && reserveOut > 0,
            "DEXLibrary: INSUFFICIENT_LIQUIDITY"
        );
        uint256 numerator = reserveIn.mul(amountOut).mul(10**5);
        uint256 denominator = reserveOut.sub(amountOut).mul(10**5 - fee);
        amountIn = (numerator / denominator).add(1);
    }

    // performs chained getAmountOut calculations on any number of pairs
    function getAmountsOut(
        address factory,
        uint256 amountIn,
        address[] memory path,
        uint32[] calldata feePath
    ) internal view returns (uint256[] memory amounts) {
        require(path.length >= 2, "DEXLibrary: INVALID_PATH");
        amounts = new uint256[](path.length);
        amounts[0] = amountIn;
        for (uint256 i; i < path.length - 1; i++) {
            (uint256 reserveIn, uint256 reserveOut) = getReserves(
                factory,
                path[i],
                path[i + 1],
                feePath[i]
            );
            amounts[i + 1] = getAmountOut(
                amounts[i],
                reserveIn,
                reserveOut,
                feePath[i]
            );
        }
    }

    // performs chained getAmountIn calculations on any number of pairs
    function getAmountsIn(
        address factory,
        uint256 amountOut,
        address[] memory path,
        uint32[] calldata feePath
    ) external view returns (uint256[] memory amounts) {
        require(path.length >= 2, "DEXLibrary: INVALID_PATH");
        amounts = new uint256[](path.length);
        amounts[amounts.length - 1] = amountOut;
        for (uint256 i = path.length - 1; i > 0; i--) {
            (uint256 reserveIn, uint256 reserveOut) = getReserves(
                factory,
                path[i - 1],
                path[i],
                feePath[i - 1]
            );
            amounts[i - 1] = getAmountIn(
                amounts[i],
                reserveIn,
                reserveOut,
                feePath[i - 1]
            );
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IERC20PairToken.sol";

interface IERC20Pair is IERC20PairToken {
    function swap(
        uint256 amountOfAsset1,
        uint256 amountOfAsset2,
        address to,
        bytes calldata data
    ) external;

    function getReserves()
        external
        view
        returns (
            uint112 _reserve0,
            uint112 _reserve1,
            uint32 _blockTimestampLast
        );

    function mint(address to) external returns (uint256 liquidity);

    function burn(address to)
        external
        returns (uint256 amount1, uint256 amount2);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IPoolFactory {
    event PairCreated(
        address indexed token0,
        address indexed token1,
        address pair,
        uint32 feeNumerator
    );

    function feeTo() external view returns (address);

    function feeToSetter() external view returns (address);

    function owner() external view returns (address);

    function ownerSetter() external view returns (address);

    function getPair(
        address tokenA,
        address tokenB,
        uint32 fee
    ) external view returns (address pair);

    function allPairs(uint256) external view returns (address pair);

    function allPairsLength() external view returns (uint256);

    function createPair(
        address tokenA,
        address tokenB,
        uint32 feeNumerator
    ) external returns (address pair);

    function setFeeTo(address) external;

    function setFeeToSetter(address) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library SafeMath {
    function add(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x + y) >= x, "ds-math-add-overflow");
    }

    function sub(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x - y) <= x, "ds-math-sub-underflow");
    }

    function mul(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require(y == 0 || (z = x * y) / y == x, "ds-math-mul-overflow");
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC20PairToken {
    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);
}