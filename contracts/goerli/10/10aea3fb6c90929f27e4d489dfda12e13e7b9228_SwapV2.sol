// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/math/SafeMathUpgradeable.sol";

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);
}

interface IUniswapV3Factory {
    function getPool(
        address tokenA,
        address tokenB,
        uint24 fee
    ) external view returns (address pool);

    function createPool(
        address tokenA,
        address tokenB,
        uint24 fee
    ) external returns (address pool);
}

interface IUniswapV3SwapCallback {
    function uniswapV3SwapCallback(
        int256 amount0Delta,
        int256 amount1Delta,
        bytes calldata data
    ) external;
}

interface ISwapRouter is IUniswapV3SwapCallback {
    struct ExactInputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
        uint160 sqrtPriceLimitX96;
    }

    function exactInputSingle(ExactInputSingleParams calldata params)
        external
        payable
        returns (uint256 amountOut);

    struct ExactInputParams {
        bytes path;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
    }

    function exactInput(ExactInputParams calldata params)
        external
        payable
        returns (uint256 amountOut);

    struct ExactOutputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountOut;
        uint256 amountInMaximum;
        uint160 sqrtPriceLimitX96;
    }

    function exactOutputSingle(ExactOutputSingleParams calldata params)
        external
        payable
        returns (uint256 amountIn);

    struct ExactOutputParams {
        bytes path;
        address recipient;
        uint256 deadline;
        uint256 amountOut;
        uint256 amountInMaximum;
    }

    function exactOutput(ExactOutputParams calldata params)
        external
        payable
        returns (uint256 amountIn);
}

interface IUniswapV3Router is ISwapRouter {
    function refundETH() external payable;

    function factory() external pure returns (address);

    function WETH9() external pure returns (address);
}

interface IUniswapV2Factory {
    function getPair(address tokenA, address tokenB)
        external
        view
        returns (address pair);

    function allPairs(uint) external view returns (address pair);

    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB)
        external
        returns (address pair);
}

interface IUniswapV2Pair {
    function factory() external view returns (address);

    function token0() external view returns (address);

    function token1() external view returns (address);

    function getReserves()
        external
        view
        returns (
            uint112 reserve0,
            uint112 reserve1,
            uint32 blockTimestampLast
        );
}

interface IUniswapV2Router {
    function getAmountsOut(uint256 amountIn, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable;

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function WETH() external pure returns (address);

    function factory() external pure returns (address);
}

interface IQuoter {
    function quoteExactInput(bytes calldata path, uint256 amountIn)
        external
        returns (uint256 amountOut);

    function quoteExactInputSingle(
        address tokenIn,
        address tokenOut,
        uint24 fee,
        uint256 amountIn,
        uint160 sqrtPriceLimitX96
    ) external returns (uint256 amountOut);

    function quoteExactOutput(bytes calldata path, uint256 amountOut)
        external
        returns (uint256 amountIn);

    function quoteExactOutputSingle(
        address tokenIn,
        address tokenOut,
        uint24 fee,
        uint256 amountOut,
        uint160 sqrtPriceLimitX96
    ) external returns (uint256 amountIn);
}

library UniversalERC20 {
    IERC20 public constant ZERO_ADDRESS =
        IERC20(0x0000000000000000000000000000000000000000);
    IERC20 public constant ETH_ADDRESS =
        IERC20(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE);

    function universalBalanceOf(IERC20 token, address who)
        public
        view
        returns (uint256)
    {
        if (isETH(token)) {
            return who.balance;
        } else {
            return token.balanceOf(who);
        }
    }

    function isETH(IERC20 token) public pure returns (bool) {
        return (address(token) == address(ZERO_ADDRESS) ||
            address(token) == address(ETH_ADDRESS));
    }
}

library TransferHelper {
    function safeApprove(
        address token,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(0x095ea7b3, to, value)
        );
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "TransferHelper::safeApprove: approve failed"
        );
    }

    function safeTransfer(
        address token,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(0xa9059cbb, to, value)
        );
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "TransferHelper::safeTransfer: transfer failed"
        );
    }

    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(0x23b872dd, from, to, value)
        );
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "TransferHelper::transferFrom: transferFrom failed"
        );
    }

    function safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(
            success,
            "TransferHelper::safeTransferETH: ETH transfer failed"
        );
    }
}

contract SwapV2 is Initializable, OwnableUpgradeable {
    using SafeMathUpgradeable for uint256;
    using UniversalERC20 for IERC20;

    IUniswapV2Router public sushiswapRouter;
    IUniswapV2Router public uniswapV2Router;
    IUniswapV3Router public uniswapV3Router;

    IQuoter public uniswapV3Quoter;

    uint24 public poolFee;

    // token addresses for route creation
    address[] public tokens;

    uint256 public reserveCheckMultiplier;

    constructor() public {}

    function initialize(
        address _sushiswapRouter,
        address _uniswapV2Router,
        address _uniswapV3Router,
        address _uniswapV3Quoter,
        address[] memory _tokens
    ) initializer public {
        __Ownable_init();
        sushiswapRouter = IUniswapV2Router(_sushiswapRouter);
        uniswapV2Router = IUniswapV2Router(_uniswapV2Router);
        uniswapV3Router = IUniswapV3Router(_uniswapV3Router);
        uniswapV3Quoter = IQuoter(_uniswapV3Quoter);
        tokens = _tokens;
        poolFee = 3000;
        reserveCheckMultiplier = 2000;
    }

    /**
     * @dev calculate rate from all three exchanges with auto routing 
     * and perform swapping from best exchange which having sufficient liquidity.
     */
    function swapFromBestExchange(
        address tokenIn,
        address tokenOut,
        uint256 amountIn,
        uint256 amountOutMinimum
    ) public payable returns (uint256) {
        require(amountIn > 0, "Swap: Amount too small to swap");

        (
            uint256 amountOut,
            address[] memory path,
            address router
        ) = getBestExchangeRate(tokenIn, tokenOut, amountIn);

        require(
            amountOut >= amountOutMinimum,
            "Swap: Insufficient output amount"
        );

        uint256 balanceBefore = IERC20(tokenOut).universalBalanceOf(msg.sender);

        if (router == address(uniswapV3Router)) {
            swapV3(uniswapV3Router, tokenIn, path, amountIn, amountOutMinimum);
        } else {
            swapV2(IUniswapV2Router(router), tokenIn, tokenOut, path, amountIn, amountOutMinimum);
        }

        uint256 balanceAfter = IERC20(tokenOut).universalBalanceOf(msg.sender);

        return balanceAfter.sub(balanceBefore);
    }

    /**
     * @dev returns best rate from all three exchanges with auto routing
     */
    function getBestExchangeRate(
        address tokenIn,
        address tokenOut,
        uint256 amountIn
    )
        public
        returns (
            uint256 amountOut,
            address[] memory path,
            address router
        )
    {
        (uint256 ssAmountOut, address[] memory ssPath) = getV2Rate(
            sushiswapRouter,
            tokenIn,
            tokenOut,
            amountIn
        );

        (uint256 usV2AmountOut, address[] memory usV2Path) = getV2Rate(
            uniswapV2Router,
            tokenIn,
            tokenOut,
            amountIn
        );

        (uint256 usV3AmountOut, address[] memory usV3Path) = getV3Rate(
            uniswapV3Router,
            tokenIn,
            tokenOut,
            amountIn
        );

        if (usV3AmountOut >= usV2AmountOut && usV3AmountOut >= ssAmountOut) {
            return (usV3AmountOut, usV3Path, address(uniswapV3Router));
        }

        if (usV2AmountOut >= usV3AmountOut && usV2AmountOut >= ssAmountOut) {
            return (usV2AmountOut, usV2Path, address(uniswapV2Router));
        }

        if (ssAmountOut >= usV3AmountOut && ssAmountOut >= usV2AmountOut) {
            return (ssAmountOut, ssPath, address(sushiswapRouter));
        }
    }

    /**
     * @dev Swap tokenIn with tokenOut with given specific V2 router also performs
     * auto routing if pair not exists
     */
    function swapV2(
        IUniswapV2Router router,
        address tokenIn,
        address tokenOut,
        uint256 amountIn,
        uint256 amountOutMinimum
    ) internal {
        require(amountIn > 0, "Swap: Amount too small to swap");

        (uint256 amountOut, address[] memory path) = getV2Rate(
            sushiswapRouter,
            tokenIn,
            tokenOut,
            amountIn
        );

        require(path.length >= 2, "Swap: Route not found");
        require(
            amountOut >= amountOutMinimum,
            "Swap: Insufficient output amount"
        );

        swapV2(router, tokenIn, tokenOut, path, amountIn, amountOutMinimum);
    }

    /**
     * @dev Swap tokens from given path and V2 router
     */
    function swapV2(
        IUniswapV2Router router,
        address tokenIn,
        address tokenOut,
        address[] memory path,
        uint256 amountIn,
        uint256 amountOutMinimum
    ) internal {
        transferFromAndApprove(tokenIn, address(router), amountIn);

        if (IERC20(tokenIn).isETH()) {
            require(msg.value >= amountIn, "Swap: Insufficient ETH provided");
            router.swapExactETHForTokensSupportingFeeOnTransferTokens{
                value: msg.value
            }(amountOutMinimum, path, msg.sender, block.timestamp);
        } else if (IERC20(tokenOut).isETH()) {
            router.swapExactTokensForETHSupportingFeeOnTransferTokens(
                amountIn,
                amountOutMinimum,
                path,
                msg.sender,
                block.timestamp
            );
        } else {
            router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
                amountIn,
                amountOutMinimum,
                path,
                msg.sender,
                block.timestamp
            );
        }
    }

    /**
     * @dev Swap tokenIn with tokenOut with given V3 router also performs
     * auto routing if pair not exists
     */
    function swapV3(
        IUniswapV3Router router,
        address tokenIn,
        address tokenOut,
        uint256 amountIn,
        uint256 amountOutMinimum
    ) internal {
        require(amountIn > 0, "Swap: Amount too small to swap");

        (uint256 amountOut, address[] memory path) = getV3Rate(
            router,
            tokenIn,
            tokenOut,
            amountIn
        );

        require(path.length >= 2, "Swap: Route not found");
        require(
            amountOut >= amountOutMinimum,
            "Swap: Insufficient output amount"
        );
    }

    /**
     * @dev Swap tokens from given path and V3 router
     */
    function swapV3(
        IUniswapV3Router router,
        address tokenIn,
        address[] memory path,
        uint256 amountIn,
        uint256 amountOutMinimum
    ) internal {
        transferFromAndApprove(tokenIn, address(router), amountIn);

        ISwapRouter.ExactInputParams memory exactInputParams = ISwapRouter
            .ExactInputParams(
                convertToBytesPath(path),
                msg.sender,
                block.timestamp + 15,
                amountIn,
                amountOutMinimum
            );

        if (IERC20(tokenIn).isETH()) {
            require(msg.value >= amountIn, "Swap: Insufficient ETH provided");
            router.exactInput{value: msg.value}(exactInputParams);
            router.refundETH();

            // refund leftover ETH to user
            (bool success, ) = msg.sender.call{value: address(this).balance}(
                ""
            );
            require(success, "refund failed");
        } else {
            router.exactInput(exactInputParams);
        }
    }

    function getV2Rate(
        IUniswapV2Router router,
        address tokenIn,
        address tokenOut,
        uint256 amountIn
    ) internal view returns (uint256 amountOut, address[] memory path) {
        path = getV2Path(router, tokenIn, tokenOut, amountIn);

        if (path.length < 2) return (0, path);

        uint256[] memory amountsOut = router.getAmountsOut(amountIn, path);

        amountOut = amountsOut[path.length - 1];
    }

    function getV3Rate(
        IUniswapV3Router router,
        address tokenIn,
        address tokenOut,
        uint256 amountIn
    ) internal returns (uint256 amountOut, address[] memory path) {
        path = getV3Path(router, tokenIn, tokenOut, amountIn);

        if (path.length < 2) return (0, path);

        amountOut = uniswapV3Quoter.quoteExactInput(
            convertToBytesPath(path),
            amountIn
        );
    }
 
    function getV2Path(
        IUniswapV2Router router,
        address tokenIn,
        address tokenOut,
        uint256 amountIn
    ) private view returns (address[] memory) {
        tokenIn = IERC20(tokenIn).isETH() ? router.WETH() : tokenIn;
        tokenOut = IERC20(tokenOut).isETH() ? router.WETH() : tokenOut;

        address[] memory defaultPath = new address[](2);
        defaultPath[0] = tokenIn;
        defaultPath[1] = tokenOut;

        if (
            pairExists(router, tokenIn, tokenOut) &&
            haveLiquidity(router, tokenIn, tokenOut, amountIn)
        ) return defaultPath;

        return computeV2Path(router, tokenIn, tokenOut);
    }

    function getV3Path(
        IUniswapV3Router router,
        address tokenIn,
        address tokenOut,
        uint256 amountIn
    ) private view returns (address[] memory) {
        tokenIn = IERC20(tokenIn).isETH() ? router.WETH9() : tokenIn;
        tokenOut = IERC20(tokenOut).isETH() ? router.WETH9() : tokenOut;

        address[] memory defaultPath = new address[](2);
        defaultPath[0] = tokenIn;
        defaultPath[1] = tokenOut;

        if (
            pairExists(router, tokenIn, tokenOut) &&
            haveLiquidity(router, tokenIn, tokenOut, amountIn)
        ) return defaultPath;

        return computeV3Path(router, tokenIn, tokenOut);
    }

    function computeV2Path(
        IUniswapV2Router router,
        address tokenIn,
        address tokenOut
    ) private view returns (address[] memory) {
        address[] memory _tokens = new address[](tokens.length);
        for (uint256 i = 0; i < tokens.length; i++) {
            if (IERC20(tokens[i]).isETH()) _tokens[i] = router.WETH();
        }

        for (uint i = 0; i < _tokens.length; i++) {
            if (
                pairExists(router, tokenIn, _tokens[i]) &&
                pairExists(router, _tokens[i], tokenOut)
            ) {
                address[] memory path = new address[](3);
                path[0] = tokenIn;
                path[1] = _tokens[i];
                path[2] = tokenOut;
                return path;
            }
        }

        return new address[](0);
    }

    function computeV3Path(
        IUniswapV3Router router,
        address tokenIn,
        address tokenOut
    ) private view returns (address[] memory) {
        address[] memory _tokens = new address[](tokens.length);
        for (uint256 i = 0; i < tokens.length; i++) {
            if (IERC20(tokens[i]).isETH()) _tokens[i] = router.WETH9();
        }

        for (uint i = 0; i < _tokens.length; i++) {
            if (
                pairExists(router, tokenIn, _tokens[i]) &&
                pairExists(router, _tokens[i], tokenOut)
            ) {
                address[] memory path = new address[](3);
                path[0] = tokenIn;
                path[1] = _tokens[i];
                path[2] = tokenOut;
                return path;
            }
        }

        return new address[](0);
    }

    function transferFromAndApprove(
        address token,
        address router,
        uint256 amount
    ) private {
        TransferHelper.safeTransferFrom(
            token,
            msg.sender,
            address(this),
            amount
        );

        TransferHelper.safeApprove(token, router, amount);
    }

    function convertToBytesPath(address[] memory path)
        private
        view
        returns (bytes memory bytesPath)
    {
        uint256 i;
        for (i = 0; i < path.length - 1; i++) {
            bytesPath = abi.encodePacked(bytesPath, path[i], poolFee);
        }
        bytesPath = abi.encodePacked(bytesPath, path[i]);
    }

    function pairExists(
        IUniswapV2Router router,
        address tokenA,
        address tokenB
    ) private view returns (bool) {
        IUniswapV2Factory factory = IUniswapV2Factory(router.factory());
        return factory.getPair(tokenA, tokenB) != address(0);
    }

    function pairExists(
        IUniswapV3Router router,
        address tokenA,
        address tokenB
    ) private view returns (bool) {
        IUniswapV3Factory factory = IUniswapV3Factory(router.factory());
        return factory.getPool(tokenA, tokenB, poolFee) != address(0);
    }

    /**
     * @dev checks liquidity available on V2 router to swap tokenA with tokenB
     * on basis of reserveCheckMuliplier.
     * @return true if liquidity available otherwise false
     */
    function haveLiquidity(
        IUniswapV2Router router,
        address tokenA,
        address tokenB,
        uint256 amountIn
    ) private view returns (bool) {
        address pairAddress = IUniswapV2Factory(router.factory()).getPair(
            tokenA,
            tokenB
        );
        IUniswapV2Pair pair = IUniswapV2Pair(pairAddress);
        (uint112 reserve0, uint112 reserve1, ) = pair.getReserves();

        if (pair.token0() != tokenA) {
            uint112 temp = reserve0;
            reserve0 = reserve1;
            reserve1 = temp;
        }

        return reserve0 > reserveCheckMultiplier.mul(amountIn).div(1000);
    }

    /**
     * @dev checks liquidity available on V3 router to swap tokenA with tokenB
     * on basis of reserveCheckMuliplier.
     * @return true if liquidity available otherwise false
     */
    function haveLiquidity(
        IUniswapV3Router router,
        address tokenA,
        address tokenB,
        uint256 amountIn
    ) private view returns (bool) {
        address pairAddress = IUniswapV3Factory(router.factory()).getPool(
            tokenA,
            tokenB,
            poolFee
        );
        uint256 reserve0 = IERC20(tokenA).balanceOf(pairAddress);
        return reserve0 > reserveCheckMultiplier.mul(amountIn).div(1000);
    }

    function updateReserveCheckMultiplier(uint256 _reserveCheckMultiplier)
        public
        onlyOwner
    {
        require(
            reserveCheckMultiplier != _reserveCheckMultiplier,
            "Swap: Same state"
        );
        reserveCheckMultiplier = _reserveCheckMultiplier;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/Initializable.sol";
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
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal initializer {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

// solhint-disable-next-line compiler-version
pragma solidity >=0.4.24 <0.8.0;

import "../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {UpgradeableProxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 */
abstract contract Initializable {

    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || _isConstructor() || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }

    /// @dev Returns true if and only if the function is running in the constructor
    function _isConstructor() private view returns (bool) {
        return !AddressUpgradeable.isContract(address(this));
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
library SafeMathUpgradeable {
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

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;
import "../proxy/Initializable.sol";

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {
    }
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
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
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
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

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
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
      return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
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
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
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
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}