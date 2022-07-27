// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.13;

import "./DcrPool.sol";
import "./interfaces/IWeth.sol";
import "solmate/utils/SafeTransferLib.sol";

contract DcrRouter {
    
    using SafeTransferLib for ERC20;

    bytes32 public constant POOL_INIT_CODE_HASH = keccak256(type(DcrPool).creationCode);
    address public immutable weth;
    address public immutable factory;

    struct SwapPath {
        address token;
        uint96 poolIndex;
    }

    error NotEnoughReceived();

    receive() external payable {}

    constructor(address _weth, address _factory) {
        weth = _weth;
        factory = _factory;
    }

    // External functions:

    function getPool(
        address tokenA,
        address tokenB,
        uint256 index
    ) external view returns (address) {
        return _getPool(tokenA, tokenB, index);
    }

    // Public functions:

    function swapExactInSingle(uint256 amountIn, address tokenIn, address tokenOut, uint256 poolIndex, uint256 amountOutMin, address to) public payable returns (uint256 amountOut) {
        address pool = _getPool(tokenIn, tokenOut, poolIndex);
        ERC20(tokenIn).safeTransferFrom(msg.sender, pool, amountIn);
        amountOut = _singleSwap(pool, tokenIn < tokenOut, amountOutMin, to);
    }

    function swapExactInSingleETH(address tokenOut, uint256 poolIndex, uint256 amountOutMin, address to) public payable returns (uint256 amountOut) {
        uint256 amountIn = msg.value;
        address tokenIn = weth;
        address pool = _getPool(weth, tokenOut, poolIndex);
        _wrapETH(amountIn, pool);
        amountOut = _singleSwap(pool, tokenIn < tokenOut, amountOutMin, to);
    }

    function swapExactInSingleToETH(uint256 amountIn, address tokenIn, uint256 poolIndex, uint256 amountOutMin, address to) public payable returns (uint256 amountOut) {
        address tokenOut = weth;
        address pool = _getPool(tokenIn, tokenOut, poolIndex);
        ERC20(tokenIn).safeTransferFrom(msg.sender, pool, amountIn);
        amountOut = _singleSwap(pool, tokenIn < tokenOut, amountOutMin, address(this));
        _unwrapETH(amountOut, to);
    }

    function swapExactIn(uint256 amountIn, SwapPath[] memory path, uint256 amountOutMin, address to) public payable returns (uint256 amountOut) {
        address tokenIn = path[0].token;
        address tokenOut = path[1].token;
        uint256 poolIndex = path[0].poolIndex;
        address pool = _getPool(tokenIn, tokenOut, poolIndex);
        ERC20(tokenIn).safeTransferFrom(msg.sender, pool, amountIn);
        amountOut = _pathSwap(tokenIn, tokenOut, poolIndex, pool, path, amountOutMin, to);
    }

    function swapExactInETH(SwapPath[] memory path, uint256 amountOutMin, address to) public payable returns (uint256 amountOut) {
        uint256 amountIn = msg.value;
        address tokenIn = weth;
        address tokenOut = path[1].token;
        uint256 poolIndex = path[0].poolIndex;
        address pool = _getPool(tokenIn, tokenOut, poolIndex);
        _wrapETH(amountIn, pool);
        amountOut = _pathSwap(tokenIn, tokenOut, poolIndex, pool, path, amountOutMin, to);
    }

    function swapExactInToETH(uint256 amountIn, SwapPath[] memory path, uint256 amountOutMin, address to) public payable returns (uint256 amountOut) {
        address tokenIn = path[0].token;
        address tokenOut = path[1].token;
        uint256 poolIndex = path[0].poolIndex;
        address pool = _getPool(tokenIn, tokenOut, poolIndex);
        ERC20(tokenIn).safeTransferFrom(msg.sender, pool, amountIn);
        amountOut = _pathSwap(tokenIn, tokenOut, poolIndex, pool, path,  amountOutMin, address(this));
        _unwrapETH(amountOut, to);
    }

    function mint(uint256 amount0, uint256 amount1, DcrPool pool, address recipient, uint256 minimumOut) external returns (uint256 liquidityMinted) {
        ERC20 token0 = pool.token0();
        ERC20 token1 = pool.token1();
        token0.transferFrom(msg.sender, address(pool), amount0);
        token1.transferFrom(msg.sender, address(pool), amount1);
        liquidityMinted = pool.mint(recipient);
        if (liquidityMinted < minimumOut) revert NotEnoughReceived();
    }

    // Internal functions:
 
    // Private functions:

    function _singleSwap(address pool, bool zeroForOne, uint256 amountOutMin, address to) private returns (uint256 amountOut) {
        amountOut = DcrPool(pool).swap(zeroForOne, to);
        if (amountOut < amountOutMin) revert NotEnoughReceived();
    }

    function _pathSwap(address tokenIn, address tokenOut, uint256 poolIndex, address pool, SwapPath[] memory path, uint256 amountOutMin, address to) private returns (uint256 amountOut) {
        amountOut = _swap(tokenIn, tokenOut, poolIndex, pool, path, to);
        if (amountOut < amountOutMin) revert NotEnoughReceived();
    }

    function _swap(
        address tokenIn,
        address tokenOut,
        uint256 poolIndex,
        address pool,
        SwapPath[] memory path,
        address to
    ) private returns (uint256 amountOut) {
        uint256 n = path.length;
        address nextTokenOut;
        address nextPool;
        for (uint256 i = 1; i < n;) {
            if (i < n - 1) {
                nextTokenOut = path[i + 1].token;
                poolIndex = path[i + 1].poolIndex;
                nextPool = _getPool(tokenOut, nextTokenOut, poolIndex);
                amountOut = DcrPool(pool).swap(
                    tokenIn < tokenOut,
                    nextPool
                );
                tokenIn = tokenOut;
                tokenOut = nextTokenOut;
                pool = nextPool;
                unchecked {
                    i = i + 1;
                }
            } else {
                amountOut = DcrPool(pool).swap(tokenIn < tokenOut, to);
                break;
            }
        }
    }

    function _getPool(address tokenA, address tokenB, uint256 index) internal view returns (address) {
        (address token0, address token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        bytes32 pool = keccak256(
            abi.encodePacked(
                hex'ff',
                factory,
                keccak256(abi.encode(token0, token1, index)),
                POOL_INIT_CODE_HASH
            )
        );
        return address(uint160(uint256(pool & bytes32(uint256(type(uint160).max))))); // Clean the dirty bits so SafeTransferFrom works as expected.
    }

    function _wrapETH(uint256 amount, address to) private {
        IWeth(weth).deposit{value: amount}();
        ERC20(weth).transfer(to, amount);
    }

    function _unwrapETH(uint256 amount, address to) private {
        IWeth(weth).withdraw(amount);
        (bool success, ) = to.call{value: amount}("");
        require(success);
    }

}

// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.13;

import "./interfaces/IDcrFactory.sol";
import "./libraries/TickMath.sol";
import "./libraries/Math.sol";
import "./libraries/FullMath.sol";
import "solmate/utils/SafeTransferLib.sol";

// TODO, add swapFee to this struct so we use 1 sload less on swaps.
struct Range {
    int24 lowerTick;
    int24 upperTick;
    int24 lowerTickOld;
    int24 upperTickOld;
    uint32 priceChangeStart;
    uint32 priceChangeEnd;
}

contract DcrPool is ERC20("Dcr Pool", "DCR LP", 18) {
    
    using SafeTransferLib for ERC20;

    uint256 internal constant Q96 = 0x1000000000000000000000000;
    uint256 internal constant MAX_FEE = 10000; // Use swapFee 10 for a 0.1% fee.
    uint256 internal constant MAX_FEE_SQUARED = MAX_FEE ** 2;

    ERC20 public immutable token0;
    ERC20 public immutable token1;
    uint256 public immutable protocolFee; // Taken as a part of swap Fee. Allowed values: from 0 to MAX_FEE.
    address public immutable feeTo;

    uint128 private _reserve0;
    uint128 private _reserve1;
    uint128 private _fee0;
    uint128 private _fee1;
    uint256 public swapFee; // Allowed values: from 0 to MAX_FEE.

    Range public range;

    address public controller;

    event Mint(address indexed owner, uint256 liquidity, uint256 amount0, uint256 amount1);
    event Burn(address indexed owner, uint256 liquidity, uint256 amount0, uint256 amount1);
    event Swap(address indexed sender, address indexed recipient, bool zeroForOne, uint256 amountIn, uint256 amountOut);
    event UpdateReserves(uint256 reserve0, uint256 reserve1);
    event SetController(address indexed newController);
    event SetRange(int24 lowerTick, int24 upperTick, uint32 priceChangeStart, uint32 priceChangeEnd);
    event SetSwapFee(uint256 swapFee);

    error InvalidTokens();
    error InvalidRange();
    error InvalidFee();
    error InvalidTimeRange();
    error OnlyController();
    error ReservesTooLow();

    constructor() {

        (
            address _token0,
            address _token1,
            address _controller,
            address _feeTo,
            uint256 _swapFee,
            uint256 _protocolFee,
            int24 _lowerTick,
            int24 _upperTick
        ) = IDcrFactory(msg.sender).parameters();

        if (_token0 >= _token1) revert InvalidTokens();
        if (_swapFee >= MAX_FEE) revert InvalidFee();
        if (_protocolFee >= MAX_FEE) revert InvalidFee();

        _checkTickValidity(_lowerTick, _upperTick);

        token0 = ERC20(_token0);
        token1 = ERC20(_token1);
        protocolFee = _protocolFee;

        swapFee = _swapFee;
        feeTo = _feeTo;
        controller = _controller;

        range = Range({
            lowerTick: _lowerTick,
            upperTick: _upperTick,
            lowerTickOld: _lowerTick,
            upperTickOld: _upperTick,
            priceChangeStart: uint32(0),
            priceChangeEnd: uint32(block.timestamp)
        });
    }

    // External functions:

    function burn(address to) external returns (uint256 amount0, uint256 amount1) {
        mintFee();
        (uint256 reserve0, uint256 reserve1) = getReserves();
        uint256 liquidity = balanceOf[address(this)];
        amount0 = liquidity * reserve0 / totalSupply;
        amount1 = liquidity * reserve1 / totalSupply;
        _burn(address(this), liquidity);
        _updateReserves(reserve0 - amount0, reserve1 - amount1);
        token0.safeTransfer(to, amount0);
        token1.safeTransfer(to, amount1);
        emit Burn(to, liquidity, amount0, amount1);
    }

    function swap(bool zeroForOne, address to) external returns (uint256 amountOut) {
        (uint256 reserve0, uint256 reserve1) = getReserves();
        (uint256 virtualReserve0, uint256 virtualReserve1) = _getVirtualReserves(reserve0, reserve1);
        uint256 amountIn;
        if (zeroForOne) {
            uint256 fee0 = _fee0;
            uint256 balance0 = token0.balanceOf(address(this));
            amountIn = balance0 - (reserve0 + fee0);
            amountOut = _getAmountOut(amountIn, virtualReserve0, virtualReserve1);
            token1.safeTransfer(to, amountOut);
            fee0 += amountIn * swapFee * protocolFee / MAX_FEE_SQUARED;
            _updateReserves(balance0 - fee0, reserve1 - amountOut);
            _fee0 = uint128(fee0);
        } else {
            uint256 fee1 = _fee1;
            uint256 balance1 = token1.balanceOf(address(this));
            amountIn = balance1 - (reserve1 + fee1);
            amountOut = _getAmountOut(amountIn, virtualReserve1, virtualReserve0);
            token0.safeTransfer(to, amountOut);
            fee1 += amountIn * swapFee * protocolFee / MAX_FEE_SQUARED;
            _updateReserves(reserve0 - amountOut, balance1 - fee1);
            _fee1 = uint128(fee1);
        }
        emit Swap(msg.sender, to, zeroForOne, amountIn, amountOut);
    }

    function sync() external {
        (uint256 balance0, uint256 balance1) = getBalancesWithoutFees();
        _updateReserves(balance0, balance1);
    }

    function setController(address _controller) external {
        if (msg.sender != controller) revert OnlyController();
        controller = _controller;
        emit SetController(_controller);
    }

    function setSwapFee(uint256 _swapFee) external {
        if (msg.sender != controller) revert OnlyController();
        if (_swapFee >= MAX_FEE) revert InvalidFee();
        swapFee = _swapFee;
        emit SetSwapFee(_swapFee);
    }

    function setRange(int24 lowerTick, int24 upperTick, uint32 startTime, uint32 endTime) external {
        if (msg.sender != controller) revert OnlyController();
        _checkTimeValidity(startTime, endTime);
        _checkTickValidity(lowerTick, upperTick);
        (int24 lowerTickOld, int24 upperTickOld) = getRange();
        range = Range({
            lowerTick: lowerTick,
            upperTick: upperTick,
            lowerTickOld: lowerTickOld,
            upperTickOld: upperTickOld,
            priceChangeStart: startTime,
            priceChangeEnd: endTime
        });
        emit SetRange(lowerTick, upperTick, startTime, endTime);
    }

    // Public functions:

    function mint(
        address to
    ) public returns (uint256 liquidityAdded) {
        (uint256 reserve0, uint256 reserve1) = getReserves();
        (uint256 balance0, uint256 balance1) = getBalancesWithoutFees();
        (uint256 amount0, uint256 amount1) = (balance0 - reserve0, balance1 - reserve1);
        (uint256 priceLower, uint256 priceUpper) = getRangePrices();
        {
            (uint256 virtualReserve0, uint256 virtualReserve1) = _getVirtualReserves(reserve0, reserve1, priceLower, priceUpper);
            (uint256 token0Fee, uint256 token1Fee) = _nonOptimalMintFee(amount0, amount1, virtualReserve0, virtualReserve1);
            reserve0 += token0Fee;
            reserve1 += token1Fee;
        }
        if (totalSupply == 0) {
            liquidityAdded = Math.sqrt(amount0 * amount1) - 1000;
            // _fee0 = 1; // Gas savings on first swap.
            // _fee1 = 1;
            _mint(address(0), 1000);
        } else {
            uint256 k = _getLiquidity(priceLower, priceUpper, reserve0, reserve1);
            uint256 newK = _getLiquidity(priceLower, priceUpper, balance0, balance1);
            liquidityAdded = totalSupply * (newK - k) / k;
        }
        _mint(to, liquidityAdded);
        _updateReserves(balance0, balance1);
        emit Mint(to, liquidityAdded, amount0, amount1);
    }

    /// @notice Reserves do not include fees.
    function getReserves() public view returns (uint128 reserve0, uint128 reserve1) {
        reserve0 = _reserve0;
        reserve1 = _reserve1;
    }

    /// @notice Protocol fees. They get minted as LP tokens on each mintFee() call.
    function getFees() public view returns (uint128 fee0, uint128 fee1) {
        fee0 = _fee0;
        fee1 = _fee1;
    }

    /// @notice Track the protocol fees.
    function mintFee() public {
        (uint256 fee0, uint256 fee1) = getFees();
        if (fee0 > 1 && fee1 > 1) {
            _fee0 = 1;
            _fee1 = 1;
            mint(feeTo);
        }
    }

    function getBalancesWithoutFees() public view returns (uint256 balance0, uint256 balance1) {
        (uint256 fees0, uint256 fees1) = getFees();
        balance0 = token0.balanceOf(address(this)) - fees0;
        balance1 = token1.balanceOf(address(this)) - fees1;
    }

    function getRange() public view returns (int24 lowerTick, int24 upperTick) {
        uint32 currentTime = uint32(block.timestamp);
        if (range.priceChangeEnd <= currentTime) {
            lowerTick = range.lowerTick;
            upperTick = range.upperTick;
        } else {
            int32 totalTime = int32(range.priceChangeEnd - range.priceChangeStart);
            int32 passedTime = int32(currentTime > range.priceChangeStart ? (currentTime - range.priceChangeStart) : 0);
            int256 lowerTickChange = int256(range.lowerTick) - range.lowerTickOld; // Use int256 since tick change value can overflow int24.
            int256 upperTickChange = int256(range.upperTick) - range.upperTickOld;
            lowerTick = int24(range.lowerTickOld + lowerTickChange * passedTime / totalTime);
            upperTick = int24(range.upperTickOld + upperTickChange * passedTime / totalTime);
        }
    }

    function getRangePrices() public view returns (uint256 priceLower, uint256 priceUpper) {
        (int24 lowerTick, int24 upperTick) = getRange();
        priceLower = TickMath.getSqrtRatioAtTick(lowerTick);
        priceUpper = TickMath.getSqrtRatioAtTick(upperTick);
    }

    function getLiquidity() public view returns (uint256 liquidity) {
        (uint256 reserve0, uint256 reserve1) = getReserves();
        (uint256 priceLower, uint256 priceUpper) = getRangePrices();
        liquidity = _getLiquidity(priceLower, priceUpper, reserve0, reserve1);
    }

    function getVirtualReserves() public view returns (uint256 vReserve0, uint256 vReserve1) {
        (uint256 reserve0, uint256 reserve1) = getReserves();
        (uint256 priceLower, uint256 priceUpper) = getRangePrices();
        (vReserve0, vReserve1) = _getVirtualReserves(reserve0, reserve1, priceLower, priceUpper);
    }

    function getAmountOut(bool zeroForOne, uint256 amountIn) public view returns (uint256 amountOut) {
        (uint256 reserveOut, uint256 reserveIn) = getVirtualReserves();
        if (zeroForOne) (reserveIn, reserveOut) = (reserveOut, reserveIn);
        amountOut = _getAmountOut(amountIn, reserveIn, reserveOut);
    }

    function getAmountIn(bool zeroForOne, uint256 amountOut) public view returns (uint256 amountIn) {
        (uint256 reserveOut, uint256 reserveIn) = getVirtualReserves();
        if (zeroForOne) (reserveIn, reserveOut) = (reserveOut, reserveIn);
        amountIn = _getAmountIn(amountOut, reserveIn, reserveOut);
    }

    // Internal functions:

    // TODO Turn into pure funtion and pass swap fee as param.
    function _getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) internal view returns (uint256 amountOut) {
        uint256 amountInWithFee = amountIn * (MAX_FEE - swapFee);
        uint256 numerator = amountInWithFee * reserveOut;
        uint256 denominator = reserveIn * MAX_FEE + amountInWithFee;
        amountOut = numerator / denominator;
    }

    function _getAmountIn(
        uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut
    ) internal view returns (uint256 amountIn) {
        uint256 numerator = reserveIn * amountOut * MAX_FEE;
        uint256 denominator = (reserveOut - amountOut) * (MAX_FEE - swapFee);
        amountIn = numerator / denominator + 1;
    }

    function _nonOptimalMintFee(
        uint256 amount0,
        uint256 amount1,
        uint256 virtualReserve0,
        uint256 virtualReserve1
    ) internal view returns (uint256 token0Fee, uint256 token1Fee) {
        if (virtualReserve0 == 0 && virtualReserve1 == 0) return (0, 0);
        if (virtualReserve0 == 0) return (swapFee * amount0 / (2 * MAX_FEE), 0);
        if (virtualReserve1 == 0) return (0, swapFee * amount1 / (2 * MAX_FEE));
        uint256 amount1Optimal = amount0 * virtualReserve1 / virtualReserve0;
        if (amount1Optimal <= amount1) {
            // Virtually swap 50% of the difference between optimal and actual amount - plus the % swapFee.
            // E.g. swap 50.1% of the difference if swapFee is 0.1%.
            uint256 virtualSwapAmount = (amount1 - amount1Optimal) * (swapFee + MAX_FEE) / (2 * MAX_FEE);
            token1Fee = swapFee * virtualSwapAmount / MAX_FEE;
        } else {
            uint256 amount0Optimal = amount1 * virtualReserve0 / virtualReserve1;
            uint256 virtualSwapAmount = (amount0 - amount0Optimal) * (swapFee + MAX_FEE) / (2 * MAX_FEE);
            token0Fee = swapFee * virtualSwapAmount / MAX_FEE;
        }
    }

    function _getVirtualReserves(
        uint256 reserve0,
        uint256 reserve1
    ) internal view returns (
        uint256 vReserve0,
        uint256 vReserve1
    ) {
        (uint256 priceLower, uint256 priceUpper) = getRangePrices();
        (vReserve0, vReserve1) = _getVirtualReserves(reserve0, reserve1, priceLower, priceUpper);
    }

    function _getVirtualReserves(
        uint256 reserve0,
        uint256 reserve1,
        uint256 priceLower,
        uint256 priceUpper
    ) internal pure returns (
        uint256 vReserve0,
        uint256 vReserve1
    ) {
        uint256 liquidity = _getLiquidity(priceLower, priceUpper, reserve0, reserve1);
        vReserve0 = reserve0 + liquidity * Q96 / priceUpper;
        vReserve1 = reserve1 + liquidity * priceLower / Q96;
    }

    /* 
    x is token0 (WETH), y is token1 (DAI). Price is y / x reserves (DAI / WETH).
    Main formula - relation between real reserves, range and liquidity. We want to calcualte liquidity.
    (x + L / √Pb) (y + L√Pa) = L²
    Solve for L.
    L²(√Pb - √Pa) - L(√Pa√Pb·x + y) - √Pb·xy = 0
    Tto help with overflow issues we can divide the equation with √Pb:
    L²(1 - √Pa / √Pb) - L(√Pa·x + y / √Pb) - xy = 0
    (ax²+bx+c=0)
     */
    function _getLiquidity(
        uint256 sqrtPa,
        uint256 sqrtPb,
        uint256 reserve0,
        uint256 reserve1
    ) internal pure returns (uint256 liquidity) {
        uint256 a = Q96 - sqrtPa * Q96 / sqrtPb; // < uint96
        uint256 b = reserve0 * sqrtPa / Q96 + reserve1 * Q96 / sqrtPb; // < uint128
        uint256 c = reserve0 * reserve1; // < uint256
        uint256 sqrtD = Math.sqrt(b * b + FullMath.mulDiv(4 * a, c, Q96)); // 4 * a * c can overflow uint256.
        liquidity = (b + sqrtD) * Q96 / (2 * a);
    }

    function _checkTimeValidity(uint32 startTime, uint32 endTime) internal view {
        if (
            startTime > uint32(block.timestamp) ||
            startTime >= endTime ||
            endTime - startTime > uint32(type(int32).max)
        ) revert InvalidTimeRange();
    }

    function _checkTickValidity(int24 lowerTick, int24 upperTick) internal pure {
        if (
            lowerTick >= upperTick ||
            upperTick > TickMath.MAX_TICK ||
            lowerTick < TickMath.MIN_TICK
        ) revert InvalidRange();
    }

    // Private functions:

    function _updateReserves(uint256 balance0, uint256 balance1) private {
        require(balance0 <= type(uint120).max);
        require(balance1 <= type(uint120).max); // Otherwise liquidity can overflow uint256.
        if (balance0 < 1000 || balance1 < 1000) revert ReservesTooLow(); // Prevent going out of the range to avoid rounding issues.
        _reserve0 = uint128(balance0);
        _reserve1 = uint128(balance1);
        emit UpdateReserves(balance0, balance1);
    }

}

// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.13;

interface IWeth {
    function deposit() external payable;
    function withdraw(uint256 amount) external;
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

import {ERC20} from "../tokens/ERC20.sol";

/// @notice Safe ETH and ERC20 transfer library that gracefully handles missing return values.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/utils/SafeTransferLib.sol)
/// @dev Use with caution! Some functions in this library knowingly create dirty bits at the destination of the free memory pointer.
/// @dev Note that none of the functions in this library check that a token has code at all! That responsibility is delegated to the caller.
library SafeTransferLib {
    /*//////////////////////////////////////////////////////////////
                             ETH OPERATIONS
    //////////////////////////////////////////////////////////////*/

    function safeTransferETH(address to, uint256 amount) internal {
        bool success;

        assembly {
            // Transfer the ETH and store if it succeeded or not.
            success := call(gas(), to, amount, 0, 0, 0, 0)
        }

        require(success, "ETH_TRANSFER_FAILED");
    }

    /*//////////////////////////////////////////////////////////////
                            ERC20 OPERATIONS
    //////////////////////////////////////////////////////////////*/

    function safeTransferFrom(
        ERC20 token,
        address from,
        address to,
        uint256 amount
    ) internal {
        bool success;

        assembly {
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata into memory, beginning with the function selector.
            mstore(freeMemoryPointer, 0x23b872dd00000000000000000000000000000000000000000000000000000000)
            mstore(add(freeMemoryPointer, 4), from) // Append the "from" argument.
            mstore(add(freeMemoryPointer, 36), to) // Append the "to" argument.
            mstore(add(freeMemoryPointer, 68), amount) // Append the "amount" argument.

            success := and(
                // Set success to whether the call reverted, if not we check it either
                // returned exactly 1 (can't just be non-zero data), or had no return data.
                or(and(eq(mload(0), 1), gt(returndatasize(), 31)), iszero(returndatasize())),
                // We use 100 because the length of our calldata totals up like so: 4 + 32 * 3.
                // We use 0 and 32 to copy up to 32 bytes of return data into the scratch space.
                // Counterintuitively, this call must be positioned second to the or() call in the
                // surrounding and() call or else returndatasize() will be zero during the computation.
                call(gas(), token, 0, freeMemoryPointer, 100, 0, 32)
            )
        }

        require(success, "TRANSFER_FROM_FAILED");
    }

    function safeTransfer(
        ERC20 token,
        address to,
        uint256 amount
    ) internal {
        bool success;

        assembly {
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata into memory, beginning with the function selector.
            mstore(freeMemoryPointer, 0xa9059cbb00000000000000000000000000000000000000000000000000000000)
            mstore(add(freeMemoryPointer, 4), to) // Append the "to" argument.
            mstore(add(freeMemoryPointer, 36), amount) // Append the "amount" argument.

            success := and(
                // Set success to whether the call reverted, if not we check it either
                // returned exactly 1 (can't just be non-zero data), or had no return data.
                or(and(eq(mload(0), 1), gt(returndatasize(), 31)), iszero(returndatasize())),
                // We use 68 because the length of our calldata totals up like so: 4 + 32 * 2.
                // We use 0 and 32 to copy up to 32 bytes of return data into the scratch space.
                // Counterintuitively, this call must be positioned second to the or() call in the
                // surrounding and() call or else returndatasize() will be zero during the computation.
                call(gas(), token, 0, freeMemoryPointer, 68, 0, 32)
            )
        }

        require(success, "TRANSFER_FAILED");
    }

    function safeApprove(
        ERC20 token,
        address to,
        uint256 amount
    ) internal {
        bool success;

        assembly {
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata into memory, beginning with the function selector.
            mstore(freeMemoryPointer, 0x095ea7b300000000000000000000000000000000000000000000000000000000)
            mstore(add(freeMemoryPointer, 4), to) // Append the "to" argument.
            mstore(add(freeMemoryPointer, 36), amount) // Append the "amount" argument.

            success := and(
                // Set success to whether the call reverted, if not we check it either
                // returned exactly 1 (can't just be non-zero data), or had no return data.
                or(and(eq(mload(0), 1), gt(returndatasize(), 31)), iszero(returndatasize())),
                // We use 68 because the length of our calldata totals up like so: 4 + 32 * 2.
                // We use 0 and 32 to copy up to 32 bytes of return data into the scratch space.
                // Counterintuitively, this call must be positioned second to the or() call in the
                // surrounding and() call or else returndatasize() will be zero during the computation.
                call(gas(), token, 0, freeMemoryPointer, 68, 0, 32)
            )
        }

        require(success, "APPROVE_FAILED");
    }
}

// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.13;

interface IDcrFactory {
    struct Parameters {
        address token0;
        address token1;
        address controller;
        address feeTo;
        uint256 swapFee;
        uint256 protocolFee;
        int24 priceLower;
        int24 priceUpper;
    }
    function parameters() external view returns (
        address token0,
        address token1,
        address controller,
        address feeTo,
        uint256 swapFee,
        uint256 protocolFee,
        int24 priceLower,
        int24 priceUpper
    );
}

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity >=0.8.13;

/// @notice Math library for computing sqrt price for ticks of size 1.0001, i.e., sqrt(1.0001^tick) as fixed point Q64.96 numbers - supports
/// prices between 2**-128 and 2**128 - 1.
/// @author Adapted from https://github.com/Uniswap/uniswap-v3-core/blob/main/contracts/libraries/TickMath.sol.
library TickMath {
    /// @dev The minimum tick that may be passed to #getSqrtRatioAtTick computed from log base 1.0001 of 2**-128.
    int24 internal constant MIN_TICK = -887272;
    /// @dev The maximum tick that may be passed to #getSqrtRatioAtTick computed from log base 1.0001 of 2**128 - 1.
    int24 internal constant MAX_TICK = -MIN_TICK;
    /// @dev The minimum value that can be returned from #getSqrtRatioAtTick - equivalent to getSqrtRatioAtTick(MIN_TICK).
    uint160 internal constant MIN_SQRT_RATIO = 4295128739;
    /// @dev The maximum value that can be returned from #getSqrtRatioAtTick - equivalent to getSqrtRatioAtTick(MAX_TICK).
    uint160 internal constant MAX_SQRT_RATIO = 1461446703485210103287273052203988822378723970342;

    error TickOutOfBounds();
    error PriceOutOfBounds();

    /// @notice Calculates sqrt(1.0001^tick) * 2^96.
    /// @dev Throws if |tick| > max tick.
    /// @param tick The input tick for the above formula.
    /// @return sqrtPriceX96 Fixed point Q64.96 number representing the sqrt of the ratio of the two assets (token1/token0)
    /// at the given tick.
    function getSqrtRatioAtTick(int24 tick) internal pure returns (uint160 sqrtPriceX96) {
        uint256 absTick = tick < 0 ? uint256(-int256(tick)) : uint256(int256(tick));
        if (absTick > uint256(uint24(MAX_TICK))) revert TickOutOfBounds();
        unchecked {
            uint256 ratio = absTick & 0x1 != 0 ? 0xfffcb933bd6fad37aa2d162d1a594001 : 0x100000000000000000000000000000000;
            if (absTick & 0x2 != 0) ratio = (ratio * 0xfff97272373d413259a46990580e213a) >> 128;
            if (absTick & 0x4 != 0) ratio = (ratio * 0xfff2e50f5f656932ef12357cf3c7fdcc) >> 128;
            if (absTick & 0x8 != 0) ratio = (ratio * 0xffe5caca7e10e4e61c3624eaa0941cd0) >> 128;
            if (absTick & 0x10 != 0) ratio = (ratio * 0xffcb9843d60f6159c9db58835c926644) >> 128;
            if (absTick & 0x20 != 0) ratio = (ratio * 0xff973b41fa98c081472e6896dfb254c0) >> 128;
            if (absTick & 0x40 != 0) ratio = (ratio * 0xff2ea16466c96a3843ec78b326b52861) >> 128;
            if (absTick & 0x80 != 0) ratio = (ratio * 0xfe5dee046a99a2a811c461f1969c3053) >> 128;
            if (absTick & 0x100 != 0) ratio = (ratio * 0xfcbe86c7900a88aedcffc83b479aa3a4) >> 128;
            if (absTick & 0x200 != 0) ratio = (ratio * 0xf987a7253ac413176f2b074cf7815e54) >> 128;
            if (absTick & 0x400 != 0) ratio = (ratio * 0xf3392b0822b70005940c7a398e4b70f3) >> 128;
            if (absTick & 0x800 != 0) ratio = (ratio * 0xe7159475a2c29b7443b29c7fa6e889d9) >> 128;
            if (absTick & 0x1000 != 0) ratio = (ratio * 0xd097f3bdfd2022b8845ad8f792aa5825) >> 128;
            if (absTick & 0x2000 != 0) ratio = (ratio * 0xa9f746462d870fdf8a65dc1f90e061e5) >> 128;
            if (absTick & 0x4000 != 0) ratio = (ratio * 0x70d869a156d2a1b890bb3df62baf32f7) >> 128;
            if (absTick & 0x8000 != 0) ratio = (ratio * 0x31be135f97d08fd981231505542fcfa6) >> 128;
            if (absTick & 0x10000 != 0) ratio = (ratio * 0x9aa508b5b7a84e1c677de54f3e99bc9) >> 128;
            if (absTick & 0x20000 != 0) ratio = (ratio * 0x5d6af8dedb81196699c329225ee604) >> 128;
            if (absTick & 0x40000 != 0) ratio = (ratio * 0x2216e584f5fa1ea926041bedfe98) >> 128;
            if (absTick & 0x80000 != 0) ratio = (ratio * 0x48a170391f7dc42444e8fa2) >> 128;

            if (tick > 0) ratio = type(uint256).max / ratio;
            // This divides by 1<<32 rounding up to go from a Q128.128 to a Q128.96.
            // We then downcast because we know the result always fits within 160 bits due to our tick input constraint.
            // We round up in the division so getTickAtSqrtRatio of the output price is always consistent.
            sqrtPriceX96 = uint160((ratio >> 32) + (ratio % (1 << 32) == 0 ? 0 : 1));
        }
    }

    function validatePrice(uint160 price) internal pure {
        if (price < MIN_SQRT_RATIO || price >= MAX_SQRT_RATIO) revert PriceOutOfBounds();
    }

    /// @notice Calculates the greatest tick value such that getRatioAtTick(tick) <= ratio.
    /// @dev Throws in case sqrtPriceX96 < MIN_SQRT_RATIO, as MIN_SQRT_RATIO is the lowest value getRatioAtTick may
    /// ever return.
    /// @param sqrtPriceX96 The sqrt ratio for which to compute the tick as a Q64.96.
    /// @return tick The greatest tick for which the ratio is less than or equal to the input ratio.
    function getTickAtSqrtRatio(uint160 sqrtPriceX96) internal pure returns (int24 tick) {
        // Second inequality must be < because the price can never reach the price at the max tick.
        if (sqrtPriceX96 < MIN_SQRT_RATIO || sqrtPriceX96 >= MAX_SQRT_RATIO) revert PriceOutOfBounds();
        uint256 ratio = uint256(sqrtPriceX96) << 32;

        uint256 r = ratio;
        uint256 msb;

        assembly {
            let f := shl(7, gt(r, 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF))
            msb := or(msb, f)
            r := shr(f, r)
        }
        assembly {
            let f := shl(6, gt(r, 0xFFFFFFFFFFFFFFFF))
            msb := or(msb, f)
            r := shr(f, r)
        }
        assembly {
            let f := shl(5, gt(r, 0xFFFFFFFF))
            msb := or(msb, f)
            r := shr(f, r)
        }
        assembly {
            let f := shl(4, gt(r, 0xFFFF))
            msb := or(msb, f)
            r := shr(f, r)
        }
        assembly {
            let f := shl(3, gt(r, 0xFF))
            msb := or(msb, f)
            r := shr(f, r)
        }
        assembly {
            let f := shl(2, gt(r, 0xF))
            msb := or(msb, f)
            r := shr(f, r)
        }
        assembly {
            let f := shl(1, gt(r, 0x3))
            msb := or(msb, f)
            r := shr(f, r)
        }
        assembly {
            let f := gt(r, 0x1)
            msb := or(msb, f)
        }
        unchecked {
            if (msb >= 128) r = ratio >> (msb - 127);
            else r = ratio << (127 - msb);

            int256 log_2 = (int256(msb) - 128) << 64;

            assembly {
                r := shr(127, mul(r, r))
                let f := shr(128, r)
                log_2 := or(log_2, shl(63, f))
                r := shr(f, r)
            }
            assembly {
                r := shr(127, mul(r, r))
                let f := shr(128, r)
                log_2 := or(log_2, shl(62, f))
                r := shr(f, r)
            }
            assembly {
                r := shr(127, mul(r, r))
                let f := shr(128, r)
                log_2 := or(log_2, shl(61, f))
                r := shr(f, r)
            }
            assembly {
                r := shr(127, mul(r, r))
                let f := shr(128, r)
                log_2 := or(log_2, shl(60, f))
                r := shr(f, r)
            }
            assembly {
                r := shr(127, mul(r, r))
                let f := shr(128, r)
                log_2 := or(log_2, shl(59, f))
                r := shr(f, r)
            }
            assembly {
                r := shr(127, mul(r, r))
                let f := shr(128, r)
                log_2 := or(log_2, shl(58, f))
                r := shr(f, r)
            }
            assembly {
                r := shr(127, mul(r, r))
                let f := shr(128, r)
                log_2 := or(log_2, shl(57, f))
                r := shr(f, r)
            }
            assembly {
                r := shr(127, mul(r, r))
                let f := shr(128, r)
                log_2 := or(log_2, shl(56, f))
                r := shr(f, r)
            }
            assembly {
                r := shr(127, mul(r, r))
                let f := shr(128, r)
                log_2 := or(log_2, shl(55, f))
                r := shr(f, r)
            }
            assembly {
                r := shr(127, mul(r, r))
                let f := shr(128, r)
                log_2 := or(log_2, shl(54, f))
                r := shr(f, r)
            }
            assembly {
                r := shr(127, mul(r, r))
                let f := shr(128, r)
                log_2 := or(log_2, shl(53, f))
                r := shr(f, r)
            }
            assembly {
                r := shr(127, mul(r, r))
                let f := shr(128, r)
                log_2 := or(log_2, shl(52, f))
                r := shr(f, r)
            }
            assembly {
                r := shr(127, mul(r, r))
                let f := shr(128, r)
                log_2 := or(log_2, shl(51, f))
                r := shr(f, r)
            }
            assembly {
                r := shr(127, mul(r, r))
                let f := shr(128, r)
                log_2 := or(log_2, shl(50, f))
            }

            int256 log_sqrt10001 = log_2 * 255738958999603826347141; // 128.128 number.

            int24 tickLow = int24((log_sqrt10001 - 3402992956809132418596140100660247210) >> 128);
            int24 tickHi = int24((log_sqrt10001 + 291339464771989622907027621153398088495) >> 128);

            tick = tickLow == tickHi ? tickLow : getSqrtRatioAtTick(tickHi) <= sqrtPriceX96 ? tickHi : tickLow;
        }
    }
}

pragma solidity 0.8.13;

library Math {
    // babylonian method (https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method)
    function sqrt(uint y) internal pure returns (uint z) {
        if (y > 3) {
            z = y;
            uint x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

/// @title Contains 512-bit math functions
/// @notice Facilitates multiplication and division that can have overflow of an intermediate value without any loss of precision
/// @dev Handles "phantom overflow" i.e., allows multiplication and division where an intermediate value overflows 256 bits
library FullMath {
    /// @notice Calculates floor(a×b÷denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
    /// @param a The multiplicand
    /// @param b The multiplier
    /// @param denominator The divisor
    /// @return result The 256-bit result
    /// @dev Credit to Remco Bloemen under MIT license https://xn--2-umb.com/21/muldiv
    function mulDiv(
        uint256 a,
        uint256 b,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        unchecked {
            // 512-bit multiply [prod1 prod0] = a * b
            // Compute the product mod 2**256 and mod 2**256 - 1
            // then use the Chinese Remainder Theorem to reconstruct
            // the 512 bit result. The result is stored in two 256
            // variables such that product = prod1 * 2**256 + prod0
            uint256 prod0; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(a, b, not(0))
                prod0 := mul(a, b)
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }

            // Handle non-overflow cases, 256 by 256 division
            if (prod1 == 0) {
                require(denominator > 0);
                assembly {
                    result := div(prod0, denominator)
                }
                return result;
            }

            // Make sure the result is less than 2**256.
            // Also prevents denominator == 0
            require(denominator > prod1);

            ///////////////////////////////////////////////
            // 512 by 256 division.
            ///////////////////////////////////////////////

            // Make division exact by subtracting the remainder from [prod1 prod0]
            // Compute remainder using mulmod
            uint256 remainder;
            assembly {
                remainder := mulmod(a, b, denominator)
            }
            // Subtract 256 bit number from 512 bit number
            assembly {
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
            }

            // Factor powers of two out of denominator
            // Compute largest power of two divisor of denominator.
            // Always >= 1.
            // https://ethereum.stackexchange.com/questions/96642/unary-operator-minus-cannot-be-applied-to-type-uint256
            uint256 twos = (type(uint256).max - denominator + 1) & denominator;

            // Divide denominator by power of two
            assembly {
                denominator := div(denominator, twos)
            }

            // Divide [prod1 prod0] by the factors of two
            assembly {
                prod0 := div(prod0, twos)
            }
            // Shift in bits from prod1 into prod0. For this we need
            // to flip `twos` such that it is 2**256 / twos.
            // If twos is zero, then it becomes one
            assembly {
                twos := add(div(sub(0, twos), twos), 1)
            }
            prod0 |= prod1 * twos;

            // Invert denominator mod 2**256
            // Now that denominator is an odd number, it has an inverse
            // modulo 2**256 such that denominator * inv = 1 mod 2**256.
            // Compute the inverse by starting with a seed that is correct
            // correct for four bits. That is, denominator * inv = 1 mod 2**4
            uint256 inv = (3 * denominator) ^ 2;
            // Now use Newton-Raphson iteration to improve the precision.
            // Thanks to Hensel's lifting lemma, this also works in modular
            // arithmetic, doubling the correct bits in each step.
            inv *= 2 - denominator * inv; // inverse mod 2**8
            inv *= 2 - denominator * inv; // inverse mod 2**16
            inv *= 2 - denominator * inv; // inverse mod 2**32
            inv *= 2 - denominator * inv; // inverse mod 2**64
            inv *= 2 - denominator * inv; // inverse mod 2**128
            inv *= 2 - denominator * inv; // inverse mod 2**256

            // Because the division is now exact we can divide by multiplying
            // with the modular inverse of denominator. This will give us the
            // correct result modulo 2**256. Since the precoditions guarantee
            // that the outcome is less than 2**256, this is the final result.
            // We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inv;
        }
        return result;
    }

    /// @notice Calculates ceil(a×b÷denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
    /// @param a The multiplicand
    /// @param b The multiplier
    /// @param denominator The divisor
    /// @return result The 256-bit result
    function mulDivRoundingUp(
        uint256 a,
        uint256 b,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        result = mulDiv(a, b, denominator);
        if (mulmod(a, b, denominator) > 0) {
            require(result < type(uint256).max);
            result++;
        }
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Modern and gas efficient ERC20 + EIP-2612 implementation.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/tokens/ERC20.sol)
/// @author Modified from Uniswap (https://github.com/Uniswap/uniswap-v2-core/blob/master/contracts/UniswapV2ERC20.sol)
/// @dev Do not manually set balances without updating totalSupply, as the sum of all user balances must not exceed it.
abstract contract ERC20 {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event Transfer(address indexed from, address indexed to, uint256 amount);

    event Approval(address indexed owner, address indexed spender, uint256 amount);

    /*//////////////////////////////////////////////////////////////
                            METADATA STORAGE
    //////////////////////////////////////////////////////////////*/

    string public name;

    string public symbol;

    uint8 public immutable decimals;

    /*//////////////////////////////////////////////////////////////
                              ERC20 STORAGE
    //////////////////////////////////////////////////////////////*/

    uint256 public totalSupply;

    mapping(address => uint256) public balanceOf;

    mapping(address => mapping(address => uint256)) public allowance;

    /*//////////////////////////////////////////////////////////////
                            EIP-2612 STORAGE
    //////////////////////////////////////////////////////////////*/

    uint256 internal immutable INITIAL_CHAIN_ID;

    bytes32 internal immutable INITIAL_DOMAIN_SEPARATOR;

    mapping(address => uint256) public nonces;

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(
        string memory _name,
        string memory _symbol,
        uint8 _decimals
    ) {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;

        INITIAL_CHAIN_ID = block.chainid;
        INITIAL_DOMAIN_SEPARATOR = computeDomainSeparator();
    }

    /*//////////////////////////////////////////////////////////////
                               ERC20 LOGIC
    //////////////////////////////////////////////////////////////*/

    function approve(address spender, uint256 amount) public virtual returns (bool) {
        allowance[msg.sender][spender] = amount;

        emit Approval(msg.sender, spender, amount);

        return true;
    }

    function transfer(address to, uint256 amount) public virtual returns (bool) {
        balanceOf[msg.sender] -= amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(msg.sender, to, amount);

        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual returns (bool) {
        uint256 allowed = allowance[from][msg.sender]; // Saves gas for limited approvals.

        if (allowed != type(uint256).max) allowance[from][msg.sender] = allowed - amount;

        balanceOf[from] -= amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(from, to, amount);

        return true;
    }

    /*//////////////////////////////////////////////////////////////
                             EIP-2612 LOGIC
    //////////////////////////////////////////////////////////////*/

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public virtual {
        require(deadline >= block.timestamp, "PERMIT_DEADLINE_EXPIRED");

        // Unchecked because the only math done is incrementing
        // the owner's nonce which cannot realistically overflow.
        unchecked {
            address recoveredAddress = ecrecover(
                keccak256(
                    abi.encodePacked(
                        "\x19\x01",
                        DOMAIN_SEPARATOR(),
                        keccak256(
                            abi.encode(
                                keccak256(
                                    "Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"
                                ),
                                owner,
                                spender,
                                value,
                                nonces[owner]++,
                                deadline
                            )
                        )
                    )
                ),
                v,
                r,
                s
            );

            require(recoveredAddress != address(0) && recoveredAddress == owner, "INVALID_SIGNER");

            allowance[recoveredAddress][spender] = value;
        }

        emit Approval(owner, spender, value);
    }

    function DOMAIN_SEPARATOR() public view virtual returns (bytes32) {
        return block.chainid == INITIAL_CHAIN_ID ? INITIAL_DOMAIN_SEPARATOR : computeDomainSeparator();
    }

    function computeDomainSeparator() internal view virtual returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                    keccak256(bytes(name)),
                    keccak256("1"),
                    block.chainid,
                    address(this)
                )
            );
    }

    /*//////////////////////////////////////////////////////////////
                        INTERNAL MINT/BURN LOGIC
    //////////////////////////////////////////////////////////////*/

    function _mint(address to, uint256 amount) internal virtual {
        totalSupply += amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(address(0), to, amount);
    }

    function _burn(address from, uint256 amount) internal virtual {
        balanceOf[from] -= amount;

        // Cannot underflow because a user's balance
        // will never be larger than the total supply.
        unchecked {
            totalSupply -= amount;
        }

        emit Transfer(from, address(0), amount);
    }
}