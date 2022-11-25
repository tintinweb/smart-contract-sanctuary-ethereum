// SPDX-License-Identifier: MIT
pragma solidity 0.7.4;
pragma experimental ABIEncoderV2;

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

// SPDX-License-Identifier: MIT
pragma solidity 0.7.4;
pragma experimental ABIEncoderV2;

interface IERC20Simple {
    function decimals() external view virtual returns (uint8);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.7.4;
pragma experimental ABIEncoderV2;

interface IPoolFunctionality {

    struct SwapData {
        uint112     amount_spend;
        uint112     amount_receive;
        address     orionpool_router;
        bool        is_exact_spend;
        bool        supportingFee;
        bool        isInContractTrade;
        bool        isSentETHEnough;
        bool        isFromWallet;
        address     asset_spend;
        address[]   path;
    }

    struct InternalSwapData {
        address user;
        uint256 amountIn;
        uint256 amountOut;
        address asset_spend;
        address[] path;
        bool isExactIn;
        address to;
        address curFactory;
        FactoryType curFactoryType;
        bool supportingFee;
    }

    enum FactoryType {
        UNSUPPORTED,
        UNISWAPLIKE,
        CURVE
    }

    function doSwapThroughOrionPool(
        address user,
        address to,
        IPoolFunctionality.SwapData calldata swapData
    ) external returns (uint amountOut, uint amountIn);

    function getWETH() external view returns (address);

    function addLiquidityFromExchange(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to
    ) external returns (uint amountA, uint amountB, uint liquidity);

    function isFactory(address a) external view returns (bool);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.7.4;
pragma experimental ABIEncoderV2;

interface IPoolSwapCallback {
    function safeAutoTransferFrom(address token, address from, address to, uint value) external;
}

// SPDX-License-Identifier: GNU
pragma solidity 0.7.4;
pragma experimental ABIEncoderV2;

interface IWETH {
    function deposit() external payable;
    function transfer(address to, uint value) external returns (bool);
    function withdraw(uint) external;
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.7.4;
pragma experimental ABIEncoderV2;

import '../interfaces/IERC20Simple.sol';
import '../utils/fromOZ/SafeMath.sol';

library LibUnitConverter {

    using SafeMath for uint;

    /**
        @notice convert asset amount from8 decimals (10^8) to its base unit
     */
    function decimalToBaseUnit(address assetAddress, uint amount) internal view returns(uint112 baseValue){
        uint256 result;

        if(assetAddress == address(0)){
            result =  amount.mul(1 ether).div(10**8); // 18 decimals
        } else {
            uint decimals = IERC20Simple(assetAddress).decimals();

            result = amount.mul(10**decimals).div(10**8);
        }

        require(result < uint256(type(int112).max), "E3U");
        baseValue = uint112(result);
    }

    /**
        @notice convert asset amount from its base unit to 8 decimals (10^8)
     */
    function baseUnitToDecimal(address assetAddress, uint amount) internal view returns(uint112 decimalValue){
        uint256 result;

        if(assetAddress == address(0)){
            result = amount.mul(10**8).div(1 ether);
        } else {
            uint decimals = IERC20Simple(assetAddress).decimals();

            result = amount.mul(10**8).div(10**decimals);
        }
        require(result < uint256(type(int112).max), "E3U");
        decimalValue = uint112(result);
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.7.4;
pragma experimental ABIEncoderV2;

import "../interfaces/IERC20.sol";
import "../utils/fromOZ/SafeMath.sol";
import "../utils/fromOZ/SafeERC20.sol";
import "../utils/fromOZ/Ownable.sol";

import "../interfaces/IPoolFunctionality.sol";
import "../interfaces/IPoolSwapCallback.sol";
import "./SafeTransferHelper.sol";
import "../utils/orionpool/OrionMultiPoolLibrary.sol";
import "../utils/orionpool/periphery/interfaces/ICurvePool.sol";
import "./LibUnitConverter.sol";

contract PoolFunctionality is Ownable, IPoolFunctionality {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    address public immutable factory;
    address public immutable WETH;

    address[] public factories;

    mapping(address => FactoryType) public supportedFactories;

    event OrionPoolSwap(
        address sender,
        address st,
        address rt,
        uint256 st_r,
        uint256 st_a,
        uint256 rt_r,
        uint256 rt_a,
        address f
    );

    constructor(address _factory, FactoryType _type, address _WETH) {
        factory = _factory;
        WETH = _WETH;
        factories = [_factory];
        supportedFactories[_factory] = _type;
    }

    receive() external payable {
        assert(msg.sender == WETH); // only accept ETH via fallback from the WETH contract
    }

    function getWETH() external view override returns (address) {
        return WETH;
    }

    function getFactoriesLength() public view returns (uint256) {
        return factories.length;
    }

    function updateFactories(
        address[] calldata _factories,
        FactoryType[] calldata _types
    ) public onlyOwner {
        require(_factories.length > 0, "PoolFunctionality: FL");
        for (uint256 i = 0; i < factories.length; ++i) {
            supportedFactories[factories[i]] = FactoryType.UNSUPPORTED;
        }

        factories = _factories;

        for (uint256 i = 0; i < factories.length; i++) {
            supportedFactories[factories[i]] = _types[i];
        }
    }

    function isFactory(address a) external view override returns (bool) {
        return supportedFactories[a] != FactoryType.UNSUPPORTED;
    }

    function doSwapThroughOrionPool(
        address user,
        address to,
        IPoolFunctionality.SwapData calldata swapData
    ) external override returns (uint256 amountOut, uint256 amountIn) {
        bool withFactory = swapData.path.length > 2 &&
            (supportedFactories[swapData.path[0]] != FactoryType.UNSUPPORTED);
        address curFactory = withFactory ? swapData.path[0] : factory;
        address[] memory new_path;

        uint256 tokenIndex = withFactory ? 1 : 0;
        new_path = new address[](swapData.path.length - tokenIndex);

        for ((uint256 i, uint256 j) = (tokenIndex, 0); i < swapData.path.length; (++i, ++j)) {
            new_path[j] = swapData.path[i] == address(0) ? WETH : swapData.path[i];
        }

        (uint256 amount_spend_base_units, uint256 amount_receive_base_units) = (
            LibUnitConverter.decimalToBaseUnit(
                swapData.path[tokenIndex],
                swapData.amount_spend
            ),
            LibUnitConverter.decimalToBaseUnit(
                swapData.path[swapData.path.length - 1],
                swapData.amount_receive
            )
        );
        {
        (uint256 userAmountIn, uint256 userAmountOut) = _doSwapTokens(InternalSwapData(
            user,
            amount_spend_base_units,
            amount_receive_base_units,
            withFactory ? swapData.path[1] : swapData.path[0],
            new_path,
            swapData.is_exact_spend,
            to,
            curFactory,
            supportedFactories[curFactory],
            swapData.supportingFee
        ));

        //  Anyway user gave amounts[0] and received amounts[len-1]
        amountOut = LibUnitConverter.baseUnitToDecimal(
            swapData.path[tokenIndex],
            userAmountIn
        );
        amountIn = LibUnitConverter.baseUnitToDecimal(
            swapData.path[swapData.path.length - 1],
            userAmountOut
        );
        }
    }

    function convertFromWETH(address a) internal view returns (address) {
        return a == WETH ? address(0) : a;
    }

    function pairFor(
        address curFactory,
        address tokenA,
        address tokenB
    ) public view returns (address pair) {
        return OrionMultiPoolLibrary.pairFor(curFactory, tokenA, tokenB);
    }

    function _doSwapTokens(InternalSwapData memory swapData) internal returns (uint256 amountIn, uint256 amountOut) {
        bool isLastWETH = swapData.path[swapData.path.length - 1] == WETH;
        address toAuto = isLastWETH || swapData.curFactoryType == FactoryType.CURVE ? address(this) : swapData.to;
        uint256[] memory amounts;
        if (!swapData.supportingFee) {
            if (swapData.isExactIn) {
                amounts = OrionMultiPoolLibrary.getAmountsOut(
                    swapData.curFactory,
                    swapData.curFactoryType,
                    swapData.amountIn,
                    swapData.path
                );
                require(amounts[amounts.length - 1] >= swapData.amountOut, "PoolFunctionality: IOA");
            } else {
                amounts = OrionMultiPoolLibrary.getAmountsIn(
                    swapData.curFactory,
                    swapData.curFactoryType,
                    swapData.amountOut,
                    swapData.path
                );
                require(amounts[0] <= swapData.amountIn, "PoolFunctionality: EIA");
            }
        } else {
            amounts = new uint256[](1);
            amounts[0] = swapData.amountIn;
        }
        amountIn = amounts[0];

        {
            uint256 curBalance;
            address initialTransferSource = swapData.curFactoryType == FactoryType.CURVE ? address(this)
                : OrionMultiPoolLibrary.pairFor(swapData.curFactory, swapData.path[0], swapData.path[1]);

            if (swapData.supportingFee) curBalance = IERC20(swapData.path[0]).balanceOf(initialTransferSource);

            IPoolSwapCallback(msg.sender).safeAutoTransferFrom(
                swapData.asset_spend,
                swapData.user,
                initialTransferSource,
                amountIn
            );
            if (swapData.supportingFee) amounts[0] = IERC20(swapData.path[0]).balanceOf(initialTransferSource) - curBalance;
        }

        {
            uint256 curBalance = IERC20(swapData.path[swapData.path.length - 1]).balanceOf(toAuto);
            if (swapData.curFactoryType == FactoryType.CURVE) {
                _swapCurve(swapData.curFactory, amounts, swapData.path, swapData.supportingFee);
            } else if (swapData.curFactoryType == FactoryType.UNISWAPLIKE) {
                _swap(swapData.curFactory, amounts, swapData.path, toAuto, swapData.supportingFee);
            }
            amountOut = IERC20(swapData.path[swapData.path.length - 1]).balanceOf(toAuto) - curBalance;
        }

        require(
            swapData.amountIn == 0 || swapData.amountOut == 0 ||
            amountIn * 1e18 / swapData.amountIn <= amountOut * 1e18 / swapData.amountOut,
            "PoolFunctionality: OOS"
        );

        if (isLastWETH) {
            SafeTransferHelper.safeAutoTransferTo(
                WETH,
                address(0),
                swapData.to,
                amountOut
            );
        } else if (swapData.curFactoryType == FactoryType.CURVE) {
            IERC20(swapData.path[swapData.path.length - 1]).safeTransfer(swapData.to, amountOut);
        }

        emit OrionPoolSwap(
            tx.origin,
            convertFromWETH(swapData.path[0]),
            convertFromWETH(swapData.path[swapData.path.length - 1]),
            swapData.amountIn,
            amountIn,
            swapData.amountOut,
            amountOut,
            swapData.curFactory
        );
    }

    function _swap(
        address curFactory,
        uint256[] memory amounts,
        address[] memory path,
        address _to,
        bool supportingFee
    ) internal {
        for (uint256 i; i < path.length - 1; ++i) {
            (address input, address output) = (path[i], path[i + 1]);
            IOrionPoolV2Pair pair = IOrionPoolV2Pair(OrionMultiPoolLibrary.pairFor(curFactory, input, output));
            (address token0, ) = OrionMultiPoolLibrary.sortTokens(input, output);
            uint256 amountOut;

            if (supportingFee) {
                (uint reserve0, uint reserve1,) = pair.getReserves();
                (uint reserveInput, uint reserveOutput) = input == token0 ? (reserve0, reserve1) : (reserve1, reserve0);
                uint256 amountIn = IERC20(input).balanceOf(address(pair)).sub(reserveInput);
                amountOut = OrionMultiPoolLibrary.getAmountOutUv2(amountIn, reserveInput, reserveOutput);
            } else {
                amountOut = amounts[i + 1];
            }

            (uint256 amount0Out, uint256 amount1Out) = input == token0 ? (uint256(0), amountOut) : (amountOut, uint256(0));
            address to = i < path.length - 2 ? OrionMultiPoolLibrary.pairFor(curFactory, output, path[i + 2]) : _to;

            pair.swap(amount0Out, amount1Out, to, new bytes(0));
        }
    }

    function _swapCurve(
        address curFactory,
        uint256[] memory amounts,
        address[] memory path,
        bool supportingFee
    ) internal {
        for (uint256 i; i < path.length - 1; ++i) {
            (address input, address output) = (path[i], path[i + 1]);
            address pool = OrionMultiPoolLibrary.pairForCurve(curFactory, input, output);
            (int128 inputInd, int128 outputInd,) = ICurveRegistry(curFactory).get_coin_indices(pool, input, output);

            uint256 curBalance;
            uint amountsIndex = supportingFee ? 0 : i;
            if (supportingFee) curBalance = IERC20(path[i + 1]).balanceOf(address(this));
            
            if (IERC20(input).allowance(address(this), pool) < amounts[amountsIndex]) {
                IERC20(input).safeIncreaseAllowance(pool, type(uint256).max);
            }
            ICurvePool(pool).exchange(inputInd, outputInd, amounts[amountsIndex], 0);
            
            if (supportingFee) amounts[0] = IERC20(path[i + 1]).balanceOf(address(this)) - curBalance;
        }
    }

    function addLiquidityFromExchange(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to
    )
        external
        override
        returns (
            uint256 amountA,
            uint256 amountB,
            uint256 liquidity
        )
    {
        amountADesired = LibUnitConverter.decimalToBaseUnit(
            tokenA,
            amountADesired
        );
        amountBDesired = LibUnitConverter.decimalToBaseUnit(
            tokenB,
            amountBDesired
        );
        amountAMin = LibUnitConverter.decimalToBaseUnit(tokenA, amountAMin);
        amountBMin = LibUnitConverter.decimalToBaseUnit(tokenB, amountBMin);

        address tokenAOrWETH = tokenA;
        if (tokenAOrWETH == address(0)) {
            tokenAOrWETH = WETH;
        }

        (amountA, amountB) = _addLiquidity(
            tokenAOrWETH,
            tokenB,
            amountADesired,
            amountBDesired,
            amountAMin,
            amountBMin
        );

        address pair = IOrionPoolV2Factory(factory).getPair(
            tokenAOrWETH,
            tokenB
        );
        IPoolSwapCallback(msg.sender).safeAutoTransferFrom(
            tokenA,
            msg.sender,
            pair,
            amountA
        );
        IPoolSwapCallback(msg.sender).safeAutoTransferFrom(
            tokenB,
            msg.sender,
            pair,
            amountB
        );

        liquidity = IOrionPoolV2Pair(pair).mint(to);

        amountA = LibUnitConverter.baseUnitToDecimal(tokenA, amountA);
        amountB = LibUnitConverter.baseUnitToDecimal(tokenB, amountB);
    }

    function _addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin
    ) internal returns (uint256 amountA, uint256 amountB) {
        // create the pair if it doesn't exist yet
        if (
            IOrionPoolV2Factory(factory).getPair(tokenA, tokenB) == address(0)
        ) {
            IOrionPoolV2Factory(factory).createPair(tokenA, tokenB);
        }
        (uint256 reserveA, uint256 reserveB) = OrionMultiPoolLibrary.getReserves(
            factory,
            tokenA,
            tokenB
        );
        if (reserveA == 0 && reserveB == 0) {
            (amountA, amountB) = (amountADesired, amountBDesired);
        } else {
            uint256 amountBOptimal = OrionMultiPoolLibrary.quoteUv2(
                amountADesired,
                reserveA,
                reserveB
            );
            if (amountBOptimal <= amountBDesired) {
                require(
                    amountBOptimal >= amountBMin,
                    "PoolFunctionality: INSUFFICIENT_B_AMOUNT"
                );
                (amountA, amountB) = (amountADesired, amountBOptimal);
            } else {
                uint256 amountAOptimal = OrionMultiPoolLibrary.quoteUv2(
                    amountBDesired,
                    reserveB,
                    reserveA
                );
                assert(amountAOptimal <= amountADesired);
                require(
                    amountAOptimal >= amountAMin,
                    "PoolFunctionality: INSUFFICIENT_A_AMOUNT"
                );
                (amountA, amountB) = (amountAOptimal, amountBDesired);
            }
        }
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.7.4;
pragma experimental ABIEncoderV2;

import "../interfaces/IWETH.sol";
import "../utils/fromOZ/SafeERC20.sol";
import "../interfaces/IERC20.sol";
import "../utils/fromOZ/Address.sol";

library SafeTransferHelper {

    function safeAutoTransferFrom(address weth, address token, address from, address to, uint value) internal {
        if (token == address(0)) {
            require(from == address(this), "TransferFrom: this");
            IWETH(weth).deposit{value: value}();
            assert(IWETH(weth).transfer(to, value));
        } else {
            if (from == address(this)) {
                SafeERC20.safeTransfer(IERC20(token), to, value);
            } else {
                SafeERC20.safeTransferFrom(IERC20(token), from, to, value);
            }
        }
    }

    function safeAutoTransferTo(address weth, address token, address to, uint value) internal {
        if (address(this) != to) {
            if (token == address(0)) {
                IWETH(weth).withdraw(value);
                Address.sendValue(payable(to), value);
            } else {
                SafeERC20.safeTransfer(IERC20(token), to, value);
            }
        }
    }

    function safeTransferTokenOrETH(address token, address to, uint value) internal {
        if (address(this) != to) {
            if (token == address(0)) {
                Address.sendValue(payable(to), value);
            } else {
                SafeERC20.safeTransfer(IERC20(token), to, value);
            }
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.4;
pragma experimental ABIEncoderV2;

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
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
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

// SPDX-License-Identifier: MIT
pragma solidity 0.7.4;
pragma experimental ABIEncoderV2;

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
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.4;
pragma experimental ABIEncoderV2;

import "./Context.sol";
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
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
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
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.4;
pragma experimental ABIEncoderV2;

import "../../interfaces/IERC20.sol";
import "./SafeMath.sol";
import "./Address.sol";

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
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
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
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.4;
pragma experimental ABIEncoderV2;

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

// SPDX-License-Identifier: MIT
pragma solidity 0.7.4;
pragma experimental ABIEncoderV2;

interface IOrionPoolV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.4;
pragma experimental ABIEncoderV2;

interface IOrionPoolV2Pair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

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
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.7.4;
pragma experimental ABIEncoderV2;

import './core/interfaces/IOrionPoolV2Pair.sol';
import './core/interfaces/IOrionPoolV2Factory.sol';
import "./periphery/interfaces/ICurveRegistry.sol";
import "./periphery/interfaces/ICurvePool.sol";
import "../../interfaces/IPoolFunctionality.sol";
import "../../interfaces/IERC20Simple.sol";

import "../fromOZ/SafeMath.sol";

library OrionMultiPoolLibrary {
    using SafeMath for uint;

    // returns sorted token addresses, used to handle return values from pairs sorted in this order
    function sortTokens(address tokenA, address tokenB) internal pure returns (address token0, address token1) {
        require(tokenA != tokenB, 'OMPL: IDENTICAL_ADDRESSES');
        (token0, token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0), 'OMPL: ZERO_ADDRESS');
    }

    // calculates the CREATE2 address for a pair without making any external calls
    function pairFor(address factory, address tokenA, address tokenB) internal view returns (address pair) {
        pair = IOrionPoolV2Factory(factory).getPair(tokenA, tokenB);
    }

    function pairForCurve(address factory, address tokenA, address tokenB) internal view returns (address pool) {
        pool = ICurveRegistry(factory).find_pool_for_coins(tokenA, tokenB, 0);
    }

    // fetches and sorts the reserves for a pair
    function getReserves(address factory, address tokenA, address tokenB) internal view returns (uint reserveA, uint reserveB) {
        (address token0,) = sortTokens(tokenA, tokenB);
        (uint reserve0, uint reserve1,) = IOrionPoolV2Pair(pairFor(factory, tokenA, tokenB)).getReserves();
        (reserveA, reserveB) = tokenA == token0 ? (reserve0, reserve1) : (reserve1, reserve0);
    }

    function get_D(uint256[] memory xp, uint256 amp) internal pure returns(uint256) {
        uint N_COINS = xp.length;
        uint256 S = 0;
        for(uint i; i < N_COINS; ++i)
            S += xp[i];
        if(S == 0)
            return 0;

        uint256 Dprev = 0;
        uint256 D = S;
        uint256 Ann = amp * N_COINS;
        for(uint _i; _i < 255; ++_i) {
            uint256 D_P = D;
            for(uint j; j < N_COINS; ++j) {
                D_P = D_P * D / (xp[j] * N_COINS);  // If division by 0, this will be borked: only withdrawal will work. And that is good
            }
            Dprev = D;
            D = (Ann * S + D_P * N_COINS) * D / ((Ann - 1) * D + (N_COINS + 1) * D_P);
            // Equality with the precision of 1
            if (D > Dprev) {
                if (D - Dprev <= 1)
                    break;
            } else  {
                if (Dprev - D <= 1)
                    break;
            }
        }
        return D;
    }

    function get_y(int128 i, int128 j, uint256 x, uint256[] memory xp_, uint256 amp) pure internal returns(uint256)
    {
        // x in the input is converted to the same price/precision
        uint N_COINS = xp_.length;
        require(i != j, "same coin");
        require(j >= 0, "j below zero");
        require(uint128(j) < N_COINS, "j above N_COINS");

        require(i >= 0, "i below zero");
        require(uint128(i) < N_COINS, "i above N_COINS");

        uint256 D = get_D(xp_, amp);
        uint256 c = D;
        uint256 S_ = 0;
        uint256 Ann = amp * N_COINS;

        uint256 _x = 0;
        for(uint _i; _i < N_COINS; ++_i) {
            if(_i == uint128(i))
                _x = x;
            else if(_i != uint128(j))
                _x = xp_[_i];
            else
                continue;
            S_ += _x;
            c = c * D / (_x * N_COINS);
        }
        c = c * D / (Ann * N_COINS);
        uint256 b = S_ + D / Ann;  // - D
        uint256 y_prev = 0;
        uint256 y = D;
        for(uint _i; _i < 255; ++_i) {
            y_prev = y;
            y = (y*y + c) / (2 * y + b - D);
            // Equality with the precision of 1
            if(y > y_prev) {
                if (y - y_prev <= 1)
                    break;
            } else {
                if(y_prev - y <= 1)
                    break;
            }
        }
        return y;
    }

    function get_xp(address factory, address pool) internal view returns(uint256[] memory xp) {
        xp = new uint256[](MAX_COINS);

        address[MAX_COINS] memory coins = ICurveRegistry(factory).get_coins(pool);
        uint256[MAX_COINS] memory balances = ICurveRegistry(factory).get_balances(pool);

        uint i = 0;
        for (; i < balances.length; ++i) {
            if (balances[i] == 0)
                break;
            xp[i] = baseUnitToCurveDecimal(coins[i], balances[i]);
        }
        assembly { mstore(xp, sub(mload(xp), sub(MAX_COINS, i))) } // remove trail zeros from array
    }

    function getAmountOutCurve(address factory, address from, address to, uint256 amount) view internal returns(uint256) {
        address pool = pairForCurve(factory, from, to);
        (int128 i, int128 j,) = ICurveRegistry(factory).get_coin_indices(pool, from, to);
        uint256[] memory xp = get_xp(factory, pool);

        uint256 y;
        {
            uint256 A = ICurveRegistry(factory).get_A(pool);
            uint256 x = xp[uint(i)] + baseUnitToCurveDecimal(from, amount);
            y = get_y(i, j, x, xp, A);
        }

        (uint256 fee,) = ICurveRegistry(factory).get_fees(pool);
        uint256 dy = xp[uint(j)] - y - 1;
        uint256 dy_fee = dy * fee / FEE_DENOMINATOR;
        dy = curveDecimalToBaseUnit(to, dy - dy_fee);

        return dy;
    }

    function getAmountInCurve(address factory, address from, address to, uint256 amount) view internal returns(uint256) {
        address pool = pairForCurve(factory, from, to);
        (int128 i, int128 j,) = ICurveRegistry(factory).get_coin_indices(pool, from, to);
        uint256[] memory xp = get_xp(factory, pool);

        uint256 x;
        {
            (uint256 fee,) = ICurveRegistry(factory).get_fees(pool);
            uint256 A = ICurveRegistry(factory).get_A(pool);
            uint256 y = xp[uint256(j)] - baseUnitToCurveDecimal(to, (amount + 1)) * FEE_DENOMINATOR / (FEE_DENOMINATOR - fee);
            x = get_y(j, i, y, xp, A);
        }

        uint256 dx = curveDecimalToBaseUnit(from, x - xp[uint256(i)]);
        return dx;
    }

    function getAmountOutUniversal(
        address factory,
        IPoolFunctionality.FactoryType factoryType,
        address from,
        address to,
        uint256 amountIn
    ) view internal returns(uint256 amountOut) {
        if (factoryType == IPoolFunctionality.FactoryType.UNISWAPLIKE) {
            (uint reserveIn, uint reserveOut) = getReserves(factory, from, to);
            amountOut = getAmountOutUv2(amountIn, reserveIn, reserveOut);
        } else if (factoryType == IPoolFunctionality.FactoryType.CURVE) {
            amountOut = getAmountOutCurve(factory, from, to, amountIn);
        } else if (factoryType == IPoolFunctionality.FactoryType.UNSUPPORTED) {
            revert("OMPL: FACTORY_UNSUPPORTED");
        }
    }

    function getAmountInUniversal(
        address factory,
        IPoolFunctionality.FactoryType factoryType,
        address from,
        address to,
        uint256 amountOut
    ) view internal returns(uint256 amountIn) {
        if (factoryType == IPoolFunctionality.FactoryType.UNISWAPLIKE) {
            (uint reserveIn, uint reserveOut) = getReserves(factory, from, to);
            amountIn = getAmountInUv2(amountOut, reserveIn, reserveOut);
        } else if (factoryType == IPoolFunctionality.FactoryType.CURVE) {
            amountIn = getAmountInCurve(factory, from, to, amountOut);
        } else if (factoryType == IPoolFunctionality.FactoryType.UNSUPPORTED) {
            revert("OMPL: FACTORY_UNSUPPORTED");
        }
    }

    // performs chained getAmountOut calculations on any number of pairs
    function getAmountsOut(
        address factory,
        IPoolFunctionality.FactoryType factoryType,
        uint amountIn,
        address[] memory path
    ) internal view returns (uint[] memory amounts) {
        require(path.length >= 2, 'OMPL: INVALID_PATH');
        amounts = new uint[](path.length);
        amounts[0] = amountIn;

        for (uint i = 1; i < path.length; ++i) {
            amounts[i] = getAmountOutUniversal(factory, factoryType, path[i - 1], path[i], amounts[i - 1]);
        }
    }

    // performs chained getAmountIn calculations on any number of pairs
    function getAmountsIn(
        address factory,
        IPoolFunctionality.FactoryType factoryType,
        uint amountOut,
        address[] memory path
    ) internal view returns (uint[] memory amounts) {
        require(path.length >= 2, 'OMPL: INVALID_PATH');
        amounts = new uint[](path.length);
        amounts[amounts.length - 1] = amountOut;
        for (uint i = path.length - 1; i > 0; --i) {
            amounts[i - 1] = getAmountInUniversal(factory, factoryType, path[i - 1], path[i], amounts[i]);
        }
    }

    /**
        @notice convert asset amount from decimals (10^18) to its base unit
    */
    function curveDecimalToBaseUnit(address assetAddress, uint amount) internal view returns(uint256 baseValue){
        uint256 result;

        if(assetAddress == address(0)){
            result = amount; // 18 decimals
        } else {
            uint decimals = IERC20Simple(assetAddress).decimals();

            result = amount.mul(10**decimals).div(10**18);
        }

        baseValue = result;
    }

    /**
        @notice convert asset amount from its base unit to 18 decimals (10^18)
    */
    function baseUnitToCurveDecimal(address assetAddress, uint amount) internal view returns(uint256 decimalValue){
        uint256 result;

        if(assetAddress == address(0)){
            result = amount;
        } else {
            uint decimals = IERC20Simple(assetAddress).decimals();

            result = amount.mul(10**18).div(10**decimals);
        }
        decimalValue = result;
    }

    // given an input amount of an asset and pair reserves, returns the maximum output amount of the other asset
    function getAmountOutUv2(uint amountIn, uint reserveIn, uint reserveOut) internal pure returns (uint amountOut) {
        require(amountIn > 0, 'OMPL: INSUFFICIENT_INPUT_AMOUNT');
        require(reserveIn > 0 && reserveOut > 0, 'OMPL: INSUFFICIENT_LIQUIDITY');
        uint amountInWithFee = amountIn.mul(997);
        uint numerator = amountInWithFee.mul(reserveOut);
        uint denominator = reserveIn.mul(1000).add(amountInWithFee);
        amountOut = numerator / denominator;
    }

    // given an output amount of an asset and pair reserves, returns a required input amount of the other asset
    function getAmountInUv2(uint amountOut, uint reserveIn, uint reserveOut) internal pure returns (uint amountIn) {
        require(amountOut > 0, 'OMPL: INSUFFICIENT_OUTPUT_AMOUNT');
        require(reserveIn > 0 && reserveOut > 0, 'OMPL: INSUFFICIENT_LIQUIDITY');
        uint numerator = reserveIn.mul(amountOut).mul(1000);
        uint denominator = reserveOut.sub(amountOut).mul(997);
        amountIn = (numerator / denominator).add(1);
    }

    // given some amount of an asset and pair reserves, returns an equivalent amount of the other asset
    function quoteUv2(uint amountA, uint reserveA, uint reserveB) internal pure returns (uint amountB) {
        require(amountA > 0, 'OMPL: INSUFFICIENT_AMOUNT');
        require(reserveA > 0 && reserveB > 0, 'OMPL: INSUFFICIENT_LIQUIDITY');
        amountB = amountA.mul(reserveB) / reserveA;
    }

}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.4;
pragma experimental ABIEncoderV2;

interface ICurvePool {
    function exchange(int128 i, int128 j, uint256 dx, uint256 min_dy) external;
    function get_dy(int128 i, int128 j, uint256 dx) external view returns(uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.4;
pragma experimental ABIEncoderV2;

uint256 constant FEE_DENOMINATOR = 10**10;
uint256 constant PRECISION = 10**18;
uint256 constant MAX_COINS = 8;

interface ICurveRegistry {
    function find_pool_for_coins(address _from, address _to, uint256 i) view external returns(address);
    function get_coin_indices(address _pool, address _from, address _to) view external returns(int128, int128, bool);
    function get_balances(address _pool) view external returns (uint256[MAX_COINS] memory);
    function get_rates(address _pool) view external returns (uint256[MAX_COINS] memory);
    function get_A(address _pool) view external returns (uint256);
    function get_fees(address _pool) view external returns (uint256, uint256);
    function get_coins(address _pool) view external returns (address[MAX_COINS] memory);
}