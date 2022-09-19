// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "../tokens/interfaces/IWETH.sol";
import "./interfaces/IFurionSwapV2Router.sol";
import "./interfaces/IFurionSwapFactory.sol";
import "./interfaces/IFurionSwapPair.sol";
import {IERC20Decimals} from "../utils/interfaces/IERC20Decimals.sol";

/*
//===================================//
 ______ _   _______ _____ _____ _   _ 
 |  ___| | | | ___ \_   _|  _  | \ | |
 | |_  | | | | |_/ / | | | | | |  \| |
 |  _| | | | |    /  | | | | | | . ` |
 | |   | |_| | |\ \ _| |_\ \_/ / |\  |
 \_|    \___/\_| \_|\___/ \___/\_| \_/
//===================================//
* /

/**
 * @title  FurionSwapRouter
 * @notice Router for the pool, you can add/remove liquidity or swap A for B.
 *         Swapping fee rate is 3‰, 99% of them is given to LP, and 1% to income maker
 *         Very similar logic with Uniswap V2.
 *
 */

contract FurionSwapV2Router is IFurionSwapV2Router {
    using SafeERC20 for IERC20;
    using SafeERC20 for IFurionSwapPair;

    // ---------------------------------------------------------------------------------------- //
    // ************************************* Variables **************************************** //
    // ---------------------------------------------------------------------------------------- //

    // Some other contracts
    address public immutable override factory;
    address public immutable override WETH;

    // ---------------------------------------------------------------------------------------- //
    // *************************************** Events ***************************************** //
    // ---------------------------------------------------------------------------------------- //

    event LiquidityAdded(
        address indexed pairAddress,
        uint256 amountA,
        uint256 amountB,
        uint256 liquidity
    );

    event LiquidityRemoved(
        address indexed pairAddress,
        uint256 amountA,
        uint256 amountB,
        uint256 liquidity
    );

    // ---------------------------------------------------------------------------------------- //
    // ************************************* Constructor ************************************** //
    // ---------------------------------------------------------------------------------------- //

    constructor(address _factory, address _weth) {
        factory = _factory;
        WETH = _weth;
    }

    // ---------------------------------------------------------------------------------------- //
    // ************************************** Modifiers *************************************** //
    // ---------------------------------------------------------------------------------------- //

    /**
     * @notice Transactions are available only before the deadline
     * @param _deadline Deadline of the pool
     */
    modifier beforeDeadline(uint256 _deadline) {
        if (_deadline > 0) {
            if (msg.sender != IFurionSwapFactory(factory).incomeMaker()) {
                require(block.timestamp < _deadline, "expired transaction");
            }
        }
        _;
    }

    // ---------------------------------------------------------------------------------------- //
    // ************************************ Main Functions ************************************ //
    // ---------------------------------------------------------------------------------------- //

    receive() external payable {
        assert(msg.sender == WETH); // only accept ETH via fallback from the WETH contract
    }

    /**
     * @notice Add liquidity function
     * @param _tokenA Address of tokenA
     * @param _tokenB Address of tokenB
     * @param _amountADesired Amount of tokenA desired
     * @param _amountBDesired Amount of tokenB desired
     * @param _amountAMin Minimum amoutn of tokenA
     * @param _amountBMin Minimum amount of tokenB
     * @param _to Address that receive the lp token, normally the user himself
     * @param _deadline Transaction will revert after this deadline
     * @return amountA Amount of tokenA to be input
     * @return amountB Amount of tokenB to be input
     * @return liquidity LP token to be mint
     */
    function addLiquidity(
        address _tokenA,
        address _tokenB,
        uint256 _amountADesired,
        uint256 _amountBDesired,
        uint256 _amountAMin,
        uint256 _amountBMin,
        address _to,
        uint256 _deadline
    )
        external
        beforeDeadline(_deadline)
        returns (
            uint256 amountA,
            uint256 amountB,
            uint256 liquidity
        )
    {
        (amountA, amountB) = _addLiquidity(
            _tokenA,
            _tokenB,
            _amountADesired,
            _amountBDesired,
            _amountAMin,
            _amountBMin
        );

        address pair = IFurionSwapFactory(factory).getPair(_tokenA, _tokenB);

        _transferFromHelper(_tokenA, msg.sender, pair, amountA);
        _transferFromHelper(_tokenB, msg.sender, pair, amountB);

        liquidity = IFurionSwapPair(pair).mint(_to);

        emit LiquidityAdded(pair, amountA, amountB, liquidity);
    }

    /**
     * @notice Add liquidity for pair where one token is ETH
     * @param _token Address of the other token
     * @param _amountTokenDesired Amount of token desired
     * @param _amountTokenMin Minimum amount of token
     * @param _amountETHMin Minimum amount of ETH
     * @param _to Address that receive the lp token, normally the user himself
     * @param _deadline Transaction will revert after this deadline
     * @return amountToken Amount of token to be input
     * @return amountETH Amount of ETH to be input
     * @return liquidity LP token to be mint
     */
    function addLiquidityETH(
        address _token,
        uint256 _amountTokenDesired,
        uint256 _amountTokenMin,
        uint256 _amountETHMin,
        address _to,
        uint256 _deadline
    )
        external
        payable
        beforeDeadline(_deadline)
        returns (
            uint256 amountToken,
            uint256 amountETH,
            uint256 liquidity
        )
    {
        (amountToken, amountETH) = _addLiquidity(
            _token,
            WETH,
            _amountTokenDesired,
            msg.value,
            _amountTokenMin,
            _amountETHMin
        );

        address pair = IFurionSwapFactory(factory).getPair(_token, WETH);

        _transferFromHelper(_token, msg.sender, pair, amountToken);
        IWETH(WETH).deposit{value: amountETH}();
        assert(IWETH(WETH).transfer(pair, amountETH));

        liquidity = IFurionSwapPair(pair).mint(_to);

        // refund dust eth, if any
        if (msg.value > amountETH)
            _safeTransferETH(msg.sender, msg.value - amountETH);

        emit LiquidityAdded(pair, amountToken, amountETH, liquidity);
    }

    /**
     * @notice Remove liquidity from the pool
     * @param _tokenA Address of token A
     * @param _tokenB Address of token B
     * @param _liquidity The lp token amount to be removed
     * @param _amountAMin Minimum amount of tokenA given out
     * @param _amountBMin Minimum amount of tokenB given out
     * @param _to User address
     * @param _deadline Deadline of this transaction
     * @return amount0 Amount of token0 given out
     * @return amount1 Amount of token1 given out, here amount0 & 1 is ordered
     */
    function removeLiquidity(
        address _tokenA,
        address _tokenB,
        uint256 _liquidity,
        uint256 _amountAMin,
        uint256 _amountBMin,
        address _to,
        uint256 _deadline
    )
        public
        override
        beforeDeadline(_deadline)
        returns (uint256 amount0, uint256 amount1)
    {
        address pair = IFurionSwapFactory(factory).getPair(_tokenA, _tokenB);

        IFurionSwapPair(pair).safeTransferFrom(msg.sender, pair, _liquidity); // send liquidity to pair

        // token0 < token1, corresponding amoount
        (amount0, amount1) = IFurionSwapPair(pair).burn(_to);

        (uint256 amount0Min, uint256 amount1Min) = _tokenA < _tokenB
            ? (_amountAMin, _amountBMin)
            : (_amountBMin, _amountAMin);

        require(amount0 >= amount0Min, "Insufficient amount for token0");
        require(amount1 >= amount1Min, "Insufficient amount for token1");

        emit LiquidityRemoved(pair, amount0, amount1, _liquidity);
    }

    /**
     * @notice Remove liquidity from the pool, one token is ETH
     * @param _token Address of the other token
     * @param _liquidity The lp token amount to be removed
     * @param _amountTokenMin Minimum amount of token given out
     * @param _amountETHMin Minimum amount of ETH given out
     * @param _to User address
     * @param _deadline Deadline of this transaction
     * @return amountToken Amount of token given out
     * @return amountETH Amount of ETH given out
     */
    function removeLiquidityETH(
        address _token,
        uint256 _liquidity,
        uint256 _amountTokenMin,
        uint256 _amountETHMin,
        address _to,
        uint256 _deadline
    )
        external
        beforeDeadline(_deadline)
        returns (uint256 amountToken, uint256 amountETH)
    {
        (amountToken, amountETH) = removeLiquidity(
            _token,
            WETH,
            _liquidity,
            _amountTokenMin,
            _amountETHMin,
            address(this),
            _deadline
        );

        // firstly make tokens inside the contract then transfer out
        _transferHelper(_token, _to, amountToken);

        IWETH(WETH).withdraw(amountETH);
        _safeTransferETH(_to, amountETH);
    }

    /**
     * @notice Swap exact tokens for another token, input is fixed
     * @param _amountIn Amount of input token
     * @param _amountOutMin Minimum amount of token given out
     * @param _path Address collection of trading path
     * @param _to Receiver of the output token, generally user address
     * @param _deadline Deadline of this transaction
     * @return amounts Amount of tokens
     */
    function swapExactTokensForTokens(
        uint256 _amountIn,
        uint256 _amountOutMin,
        address[] calldata _path,
        address _to,
        uint256 _deadline
    )
        public
        override
        beforeDeadline(_deadline)
        returns (uint256[] memory amounts)
    {
        amounts = getAmountsOut(_amountIn, _path);

        require(
            amounts[amounts.length - 1] >= _amountOutMin,
            "FurionSwapV2Router: INSUFFICIENT_OUTPUT_AMOUNT"
        );

        _transferFromHelper(
            _path[0],
            msg.sender,
            IFurionSwapFactory(factory).getPair(_path[0], _path[1]),
            amounts[0]
        );
        _swap(amounts, _path, _to);
    }

    /**
     * @notice Swap token for exact token, output is fixed
     * @param _amountOut Amount of output token
     * @param _amountInMax Maxmium amount of token in
     * @param _path Address collection of trading path
     * @param _to Receiver of the output token, generally user address
     * @param _deadline Deadline of this transaction
     * @return amounts Amount of tokens
     */
    function swapTokensForExactTokens(
        uint256 _amountOut,
        uint256 _amountInMax,
        address[] calldata _path,
        address _to,
        uint256 _deadline
    )
        public
        override
        beforeDeadline(_deadline)
        returns (uint256[] memory amounts)
    {
        amounts = getAmountsIn(_amountOut, _path);

        require(
            amounts[0] <= _amountInMax,
            "FurionSwapV2Router: EXCESSIVE_INPUT_AMOUNT"
        );

        _transferFromHelper(
            _path[0],
            msg.sender,
            IFurionSwapFactory(factory).getPair(_path[0], _path[1]),
            amounts[0]
        );
        _swap(amounts, _path, _to);
    }

    /**
     * @notice Swap exact ETH for another token, input is fixed
     * @param _amountOutMin Minimum amount of output token
     * @param _path Address collection of trading path
     * @param _to Receiver of the output token, generally user address
     * @param _deadline Deadline of this transaction
     * @return amounts Amount of tokens
     */
    function swapExactETHForTokens(
        uint256 _amountOutMin,
        address[] calldata _path,
        address _to,
        uint256 _deadline
    )
        external
        payable
        override
        beforeDeadline(_deadline)
        returns (uint256[] memory amounts)
    {
        require(_path[0] == WETH, "FurionSwapV2Router: INVALID_PATH");
        amounts = getAmountsOut(msg.value, _path);
        require(
            amounts[amounts.length - 1] >= _amountOutMin,
            "FurionSwapV2Router: INSUFFICIENT_OUTPUT_AMOUNT"
        );

        IWETH(WETH).deposit{value: amounts[0]}();
        assert(
            IWETH(WETH).transfer(
                IFurionSwapFactory(factory).getPair(_path[0], _path[1]),
                amounts[0]
            )
        );
        _swap(amounts, _path, _to);
    }

    /**
     * @notice Swap token for exact ETH, output is fixed
     * @param _amountOut Amount of output token
     * @param _amountInMax Maxmium amount of token in
     * @param _path Address collection of trading path
     * @param _to Receiver of the output token, generally user address
     * @param _deadline Deadline of this transaction
     * @return amounts Amount of tokens
     */
    function swapTokensForExactETH(
        uint256 _amountOut,
        uint256 _amountInMax,
        address[] calldata _path,
        address _to,
        uint256 _deadline
    )
        external
        override
        beforeDeadline(_deadline)
        returns (uint256[] memory amounts)
    {
        require(
            _path[_path.length - 1] == WETH,
            "FurionSwapV2Router: INVALID_PATH"
        );
        amounts = getAmountsIn(_amountOut, _path);
        require(
            amounts[0] <= _amountInMax,
            "FurionSwapV2Router: EXCESSIVE_INPUT_AMOUNT"
        );

        _transferFromHelper(
            _path[0],
            msg.sender,
            IFurionSwapFactory(factory).getPair(_path[0], _path[1]),
            amounts[0]
        );
        _swap(amounts, _path, address(this));
        IWETH(WETH).withdraw(amounts[amounts.length - 1]);
        _safeTransferETH(_to, amounts[amounts.length - 1]);
    }

    /**
     * @notice Swap exact tokens for ETH, input is fixed
     * @param _amountIn Amount of input token
     * @param _amountOutMin Minimum amount of output token
     * @param _path Address collection of trading path
     * @param _to Receiver of the output token, generally user address
     * @param _deadline Deadline of this transaction
     * @return amounts Amount of tokens
     */
    function swapExactTokensForETH(
        uint256 _amountIn,
        uint256 _amountOutMin,
        address[] calldata _path,
        address _to,
        uint256 _deadline
    )
        external
        override
        beforeDeadline(_deadline)
        returns (uint256[] memory amounts)
    {
        require(
            _path[_path.length - 1] == WETH,
            "FurionSwapV2Router: INVALID_PATH"
        );
        amounts = getAmountsOut(_amountIn, _path);
        require(
            amounts[amounts.length - 1] >= _amountOutMin,
            "FurionSwapV2Router: INSUFFICIENT_OUTPUT_AMOUNT"
        );

        _transferFromHelper(
            _path[0],
            msg.sender,
            IFurionSwapFactory(factory).getPair(_path[0], _path[1]),
            amounts[0]
        );

        _swap(amounts, _path, address(this));
        IWETH(WETH).withdraw(amounts[amounts.length - 1]);
        _safeTransferETH(_to, amounts[amounts.length - 1]);
    }

    /**
     * @notice Swap token for exact ETH, output is fixed
     * @param _amountOut Amount of output token
     * @param _path Address collection of trading path
     * @param _to Receiver of the output token, generally user address
     * @param _deadline Deadline of this transaction
     * @return amounts Amount of tokens
     */
    function swapETHForExactTokens(
        uint256 _amountOut,
        address[] calldata _path,
        address _to,
        uint256 _deadline
    )
        external
        payable
        override
        beforeDeadline(_deadline)
        returns (uint256[] memory amounts)
    {
        require(_path[0] == WETH, "FurionSwapV2Router: INVALID_PATH");
        amounts = getAmountsIn(_amountOut, _path);
        require(
            amounts[0] <= msg.value,
            "FurionSwapV2Router: EXCESSIVE_INPUT_AMOUNT"
        );

        IWETH(WETH).deposit{value: amounts[0]}();
        assert(
            IWETH(WETH).transfer(
                IFurionSwapFactory(factory).getPair(_path[0], _path[1]),
                amounts[0]
            )
        );
        _swap(amounts, _path, _to);

        // refund dust eth, if any
        if (msg.value > amounts[0])
            _safeTransferETH(msg.sender, msg.value - amounts[0]);
    }

    // ---------------------------------------------------------------------------------------- //
    // *********************************** Helper Functions *********************************** //
    // ---------------------------------------------------------------------------------------- //

    /**
     * @notice Fetch the reserves for a trading pair
     * @dev You need to sort the token order by yourself!
     *      No matter your input order, the return value will always start with lower address
     *      i.e. _tokenA < _tokenB ? (_tokenA, _tokenB) : (_tokenB, _tokenA)
     * @param _tokenA Address of tokenA
     * @param _tokenB Address of tokenB
     * @return reserve0 Reserve of token0,
     * @return reserve1 Reserve of token1
     */
    function getReserves(address _tokenA, address _tokenB)
        public
        view
        returns (uint112 reserve0, uint112 reserve1)
    {
        address pairAddress = IFurionSwapFactory(factory).getPair(
            _tokenA,
            _tokenB
        );

        // (token0 reserve, token1 reserve)
        (reserve0, reserve1) = IFurionSwapPair(pairAddress).getReserves();
    }

    /**
     * @notice Used when swap exact tokens for tokens (in is fixed)
     * @param _amountIn Amount of tokens put in
     * @param _tokenIn Address of the input token
     * @param _tokenOut Address of the output token
     * @return amountOut Amount of token out
     */
    function getAmountOut(
        uint256 _amountIn,
        address _tokenIn,
        address _tokenOut
    ) public view returns (uint256 amountOut) {
        (uint256 reserve0, uint256 reserve1) = getReserves(_tokenIn, _tokenOut);

        // Get the right order
        (uint256 reserveIn, uint256 reserveOut) = _tokenIn < _tokenOut
            ? (reserve0, reserve1)
            : (reserve1, reserve0);

        require(_amountIn > 0, "insufficient input amount");
        require(reserveIn > 0 && reserveOut > 0, "insufficient liquidity");

        // read fee rate from FurionSwapPair
        uint256 feeRate = IFurionSwapPair(
            IFurionSwapFactory(factory).getPair(_tokenIn, _tokenOut)
        ).feeRate();

        uint256 amountInWithFee = _amountIn * (1000 - feeRate);
        uint256 numerator = amountInWithFee * reserveOut;
        uint256 denominator = reserveIn * 1000 + amountInWithFee;

        amountOut = numerator / denominator;
    }

    /**
     * @notice Used when swap tokens for exact tokens (out is fixed)
     * @param _amountOut Amount of tokens given out
     * @param _tokenIn Address of the input token
     * @param _tokenOut Address of the output token
     * @return amountIn Amount of token in
     */
    function getAmountIn(
        uint256 _amountOut,
        address _tokenIn,
        address _tokenOut
    ) public view returns (uint256 amountIn) {
        (uint256 reserve0, uint256 reserve1) = getReserves(_tokenIn, _tokenOut);

        // Get the right order
        (uint256 reserveIn, uint256 reserveOut) = _tokenIn < _tokenOut
            ? (reserve0, reserve1)
            : (reserve1, reserve0);

        require(_amountOut > 0, "insufficient output amount");
        require(reserveIn > 0 && reserveOut > 0, "insufficient liquidity");

        // read fee rate from FurionSwapPair
        uint256 feeRate = IFurionSwapPair(
            IFurionSwapFactory(factory).getPair(_tokenIn, _tokenOut)
        ).feeRate();

        uint256 numerator = reserveIn * (_amountOut) * 1000;
        uint256 denominator = (reserveOut - _amountOut) * (1000 - feeRate);

        amountIn = numerator / denominator + 1;
    }

    /**
     * @notice Used when swap exact tokens for tokens (in is fixed), multiple swap
     * @param _amountIn Amount of tokens put in
     * @param _path Path of trading routes
     * @return amounts Amount of tokens
     */
    function getAmountsOut(uint256 _amountIn, address[] memory _path)
        public
        view
        returns (uint256[] memory amounts)
    {
        require(_path.length >= 2, "FurionSwap: INVALID_PATH");
        amounts = new uint256[](_path.length);
        amounts[0] = _amountIn;
        for (uint256 i; i < _path.length - 1; i++) {
            amounts[i + 1] = getAmountOut(amounts[i], _path[i], _path[i + 1]);
        }
    }

    /**
     * @notice Used when swap exact tokens for tokens (out is fixed), multiple swap
     * @param _amountOut Amount of tokens get out
     * @param _path Path of trading routes
     * @return amounts Amount of tokens
     */
    function getAmountsIn(uint256 _amountOut, address[] memory _path)
        public
        view
        returns (uint256[] memory amounts)
    {
        require(_path.length >= 2, "FurionSwap: INVALID_PATH");
        amounts = new uint256[](_path.length);
        amounts[amounts.length - 1] = _amountOut;

        for (uint256 i = _path.length - 1; i > 0; i--) {
            amounts[i - 1] = getAmountIn(amounts[i], _path[i - 1], _path[i]);
        }
    }

    /**
     * @notice Given some amount of an asset and pair reserves
     *         returns an equivalent amount of the other asset
     * @dev Used when add or remove liquidity
     * @param _amountA Amount of tokenA
     * @param _reserveA Reserve of tokenA
     * @param _reserveB Reserve of tokenB
     * @return amountB Amount of tokenB
     */
    function quote(
        uint256 _amountA,
        uint256 _reserveA,
        uint256 _reserveB
    ) public pure returns (uint256 amountB) {
        require(_amountA > 0, "insufficient amount");
        require(_reserveA > 0 && _reserveB > 0, "insufficient liquidity");

        amountB = (_amountA * _reserveB) / _reserveA;
    }

    // ---------------------------------------------------------------------------------------- //
    // *********************************** Internal Functions ********************************* //
    // ---------------------------------------------------------------------------------------- //

    /**
     * @notice Internal function to finish adding liquidity
     * @param _tokenA Address of tokenA
     * @param _tokenB Address of tokenB
     * @param _amountADesired Amount of tokenA to be added
     * @param _amountBDesired Amount of tokenB to be added
     * @param _amountAMin Minimum amount of tokenA
     * @param _amountBMin Minimum amount of tokenB
     * @return amountA Real amount of tokenA
     * @return amountB Real amount of tokenB
     */
    function _addLiquidity(
        address _tokenA,
        address _tokenB,
        uint256 _amountADesired,
        uint256 _amountBDesired,
        uint256 _amountAMin,
        uint256 _amountBMin
    ) private view returns (uint256 amountA, uint256 amountB) {
        (uint256 reserve0, uint256 reserve1) = getReserves(_tokenA, _tokenB);
        (uint256 reserveA, uint256 reserveB) = _tokenA < _tokenB
            ? (reserve0, reserve1)
            : (reserve1, reserve0);

        if (reserveA == 0 && reserveB == 0) {
            (amountA, amountB) = (_amountADesired, _amountBDesired);
        } else {
            uint256 amountBOptimal = quote(_amountADesired, reserveA, reserveB);
            if (amountBOptimal <= _amountBDesired) {
                require(amountBOptimal >= _amountBMin, "INSUFFICIENT_B_AMOUNT");
                (amountA, amountB) = (_amountADesired, amountBOptimal);
            } else {
                uint256 amountAOptimal = quote(
                    _amountBDesired,
                    reserveB,
                    reserveA
                );
                require(amountAOptimal <= _amountADesired, "UNAVAILABLE");
                require(amountAOptimal >= _amountAMin, "INSUFFICIENT_A_AMOUNT");
                (amountA, amountB) = (amountAOptimal, _amountBDesired);
            }
        }
    }

    /**
     * @notice Finish the erc20 transfer operation
     * @param _token ERC20 token address
     * @param _from Address to give out the token
     * @param _to Pair address to receive the token
     * @param _amount Transfer amount
     */
    function _transferFromHelper(
        address _token,
        address _from,
        address _to,
        uint256 _amount
    ) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        // (bool success, bytes memory data) = _token.call(abi.encodeWithSelector(0x23b872dd, _from, _to, _amount));
        // require(success && (data.length == 0 || abi.decode(data, (bool))), "TransferHelper: TRANSFER_FROM_FAILED");
        IERC20(_token).safeTransferFrom(_from, _to, _amount);
    }

    /**
     * @notice Finish the erc20 transfer operation
     * @param _token ERC20 token address
     * @param _to Address to receive the token
     * @param _amount Transfer amount
     */
    function _transferHelper(
        address _token,
        address _to,
        uint256 _amount
    ) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        // (bool success, bytes memory data) = _token.call(abi.encodeWithSelector(0x23b872dd, _from, _to, _amount));
        // require(success && (data.length == 0 || abi.decode(data, (bool))), "TransferHelper: TRANSFER_FROM_FAILED");
        IERC20(_token).safeTransfer(_to, _amount);
    }

    /**
     * @notice Finish the ETH transfer operation
     * @param _to Address to receive the token
     * @param _amount Transfer amount
     */
    function _safeTransferETH(address _to, uint256 _amount) internal {
        (bool success, ) = _to.call{value: _amount}("");
        require(success, "TransferHelper: ETH_TRANSFER_FAILED");
    }

    /**
     * @notice Finish swap process, requires the initial amount to have already been sent to the first pair
     * @param _amounts Amounts of token out for multiple swap
     * @param _path Address of tokens for multiple swap
     * @param _to Address of the final token receiver
     */
    function _swap(
        uint256[] memory _amounts,
        address[] memory _path,
        address _to
    ) private {
        for (uint256 i; i < _path.length - 1; i++) {
            // get token pair for each seperate swap
            (address input, address output) = (_path[i], _path[i + 1]);
            address token0 = input < output ? input : output;

            // get tokenOutAmount for each swap
            uint256 amountOut = _amounts[i + 1];
            (uint256 amount0Out, uint256 amount1Out) = input == token0
                ? (uint256(0), amountOut)
                : (amountOut, uint256(0));

            address to = i < _path.length - 2
                ? IFurionSwapFactory(factory).getPair(output, _path[i + 2])
                : _to;

            IFurionSwapPair(IFurionSwapFactory(factory).getPair(input, output))
                .swap(amount0Out, amount1Out, to);
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

interface IWETH {
    function deposit() external payable;

    function transfer(address to, uint256 value) external returns (bool);

    function withdraw(uint256) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

interface IFurionSwapV2Router {
    function factory() external view returns (address);

    function WETH() external view returns (address);

    function addLiquidity(
        address _tokenA,
        address _tokenB,
        uint256 _amountADesired,
        uint256 _amountBDesired,
        uint256 _amountAMin,
        uint256 _amountBMin,
        address _to,
        uint256 _deadline
    )
        external
        returns (
            uint256 _amountA,
            uint256 _amountB,
            uint256 _liquidity
        );

    function addLiquidityETH(
        address _token,
        uint256 _amountTokenDesired,
        uint256 _amountTokenMin,
        uint256 _amountETHMin,
        address _to,
        uint256 _deadline
    )
        external
        payable
        returns (
            uint256 _amountToken,
            uint256 _amountETH,
            uint256 _liquidity
        );

    function removeLiquidity(
        address _tokenA,
        address _tokenB,
        uint256 _liquidity,
        uint256 _amountAMin,
        uint256 _amountBMin,
        address _to,
        uint256 _deadline
    ) external returns (uint256 _amountA, uint256 _amountB);

    function removeLiquidityETH(
        address _token,
        uint256 _liquidity,
        uint256 _amountTokenMin,
        uint256 _amountETHMin,
        address _to,
        uint256 _deadline
    ) external returns (uint256 _amountToken, uint256 _amountETH);

    function swapExactTokensForTokens(
        uint256 _amountIn,
        uint256 _amountOutMin,
        address[] calldata _path,
        address _to,
        uint256 _deadline
    ) external returns (uint256[] memory _amounts);

    function swapTokensForExactTokens(
        uint256 _amountOut,
        uint256 _amountInMax,
        address[] calldata _path,
        address _to,
        uint256 _deadline
    ) external returns (uint256[] memory _amounts);

    function swapExactETHForTokens(
        uint256 _amountOutMin,
        address[] calldata _path,
        address _to,
        uint256 _deadline
    ) external payable returns (uint256[] memory _amounts);

    function swapTokensForExactETH(
        uint256 _amountOut,
        uint256 _amountInMax,
        address[] calldata _path,
        address _to,
        uint256 _deadline
    ) external returns (uint256[] memory _amounts);

    function swapExactTokensForETH(
        uint256 _amountIn,
        uint256 _amountOutMin,
        address[] calldata _path,
        address _to,
        uint256 _deadline
    ) external returns (uint256[] memory amounts);

    function swapETHForExactTokens(
        uint256 _amountOut,
        address[] calldata _path,
        address _to,
        uint256 _deadline
    ) external payable returns (uint256[] memory amounts);
}

// SPDX-License-Identifier: MIT

// OpenZeppelin Contracts v4.4.0 (token/ERC20/IERC20.sol)

pragma solidity ^0.8.10;

interface IERC20Decimals {
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

interface IFurionSwapFactory {
    function getPair(address _token0, address _token1)
        external
        view
        returns (address);

    function isFurionPairs(address _token0, address _token1)
        external
        view
        returns (bool);

    function createPair(address _token0, address _token1)
        external
        returns (address _pair);

    function allPairs(uint256) external view returns (address _pair);

    function allPairsLength() external view returns (uint256);

    function incomeMaker() external view returns (address);

    function incomeMakerProportion() external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IFurionSwapPair is IERC20 {
    function initialize(address _token0, address _token1) external;

    function factory() external view returns (address);

    function token0() external view returns (address);

    function token1() external view returns (address);

    function feeRate() external view returns (uint256);

    function deadline() external view returns (uint256);

    function getReserves()
        external
        view
        returns (uint112 _reserve0, uint112 _reserve1);

    function swap(
        uint256,
        uint256,
        address
    ) external;

    function burn(address) external returns (uint256, uint256);

    function mint(address) external returns (uint256);

    function sync() external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../extensions/draft-IERC20Permit.sol";
import "../../../utils/Address.sol";

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

pragma solidity ^0.8.1;

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
        return functionCall(target, data, "Address: low-level call failed");
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
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
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
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
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
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/draft-IERC20Permit.sol)

pragma solidity ^0.8.0;

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