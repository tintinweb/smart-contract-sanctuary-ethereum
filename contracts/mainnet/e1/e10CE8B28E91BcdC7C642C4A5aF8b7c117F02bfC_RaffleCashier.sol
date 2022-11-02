// SPDX-License-Identifier: MIT
pragma solidity >=0.8;

import "./RaffleManager.sol";
import "./RaffleOperator.sol";

interface IPair {
    function token0() external view returns (address);

    function token1() external view returns (address);

    function balanceOf(address owner) external view returns (uint256);

    function approve(address spender, uint256 value) external returns (bool);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function getReserves()
        external
        view
        returns (
            uint112 reserve0,
            uint112 reserve1,
            uint32 blockTimestampLast
        );
}

interface IRouter {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

    function swapTokensForExactTokens(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function addLiquidity(
        address tokenA,
        address tokenB,
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

    function swapETHForExactTokens(
        uint256 amountOut,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function addLiquidityETH(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    )
        external
        payable
        returns (
            uint256 amountToken,
            uint256 amountETH,
            uint256 liquidity
        );

    function removeLiquidityETH(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountToken, uint256 amountETH);
}

interface IFactory {
    function getPair(address tokenA, address tokenB)
        external
        view
        returns (address pair);

    function createPair(address tokenA, address tokenB)
        external
        returns (address pair);
}

interface AggregatorV3Interface {
    function decimals() external view returns (uint8);

    function description() external view returns (string memory);

    function version() external view returns (uint256);

    function getRoundData(uint80 _roundId)
        external
        view
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        );

    function latestRoundData()
        external
        view
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        );
}

contract RaffleCashier is Owned {
    IRouter public router;
    address public immutable WETH;
    address public immutable FMON;
    address public treasuryAddress;
    AggregatorV3Interface internal priceFeed;

    RaffleManager raffleManagerInstance;

    error Unauthorized();

    constructor(
        address _routerAddress,
        address _WETH,
        address _FMON
    ) {
        IRouter _router = IRouter(_routerAddress);
        router = _router;
        WETH = _WETH;
        FMON = _FMON;
        raffleManagerInstance = RaffleManager(msg.sender);
        priceFeed = AggregatorV3Interface(
            0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419
        );
    }

    function getCurrentPriceOfTokenByETHInUSDC(address _tokenA, address _USDC)
        public
        view
        returns (uint256 _currentPriceOfTokenWithoutDecimalsInUSD)
    {
        // tokenA always the token which we want to know the price
        address _pair = IFactory(router.factory()).getPair(_tokenA, WETH);
        uint256 decimalsUSDC = IERC20(_USDC).decimals();
        uint256 decimalsToken0 = IERC20(IPair(_pair).token0()).decimals();
        uint256 decimalsToken1 = IERC20(IPair(_pair).token1()).decimals();
        (uint256 reserve0, uint256 reserve1, ) = IPair(_pair).getReserves();

        uint256 currentToken0PriceWithoutDecimals = (1 *
            10**decimalsToken0 *
            reserve1) / reserve0; // --> For 1 FMON is this ETH
        uint256 currentToken1PriceWithoutDecimals = (1 *
            10**decimalsToken1 *
            reserve0) / reserve1; // --> For 1 ETH is this FMON

        uint256 currentETHPrice = uint256(getETHLatestPrice());
        uint8 ETHPriceDecimals = getETHPriceDecimals();
        uint256 currentPriceETHInUSD = currentETHPrice / 10**ETHPriceDecimals;
        uint256 currentPriceETHInUSDWithoutDecimals = 1 *
            10**decimalsUSDC *
            currentPriceETHInUSD;

        // If token0 is ETH, token1 is FMON
        if (_tokenA == IPair(_pair).token0()) {
            _currentPriceOfTokenWithoutDecimalsInUSD =
                ((1 * 10**decimalsToken0) *
                    currentPriceETHInUSDWithoutDecimals) /
                currentToken1PriceWithoutDecimals;
        } else if (_tokenA == IPair(_pair).token1()) {
            _currentPriceOfTokenWithoutDecimalsInUSD =
                ((1 * 10**decimalsToken1) *
                    currentPriceETHInUSDWithoutDecimals) /
                currentToken0PriceWithoutDecimals;
        }
    }

    function addUSDCLiquidity(
        address _USDC,
        address _liquidityProvider,
        uint256 _liquidityToAdd
    ) external onlyOwner returns (bool _success) {
        TransferHelper.safeTransferFrom(
            _USDC,
            _liquidityProvider,
            address(this),
            _liquidityToAdd
        );
        return true;
    }

    function removeUSDCLiquidity(
        address _USDC,
        uint256 _liquidityToRemove,
        address _liquidityReceiver
    ) external onlyOwner returns (bool _removeLiquiditySuccess) {
        TransferHelper.safeTransfer(
            _USDC,
            _liquidityReceiver,
            _liquidityToRemove
        );
        return true;
    }

    function changeRouterToMakeSwap(address _newRouterAddress)
        external
        onlyOwner
        returns (bool _success)
    {
        IRouter _router = IRouter(_newRouterAddress);
        router = _router;
        return true;
    }

    function transferAmountToBuyTickets(
        address _USDC,
        address _ticketsBuyer,
        address _raffleOperator,
        uint256 _amountToBuyTickets
    ) external returns (bool _transferSuccess) {
        if (msg.sender != _raffleOperator) revert Unauthorized();

        TransferHelper.safeTransferFrom(
            _USDC,
            _ticketsBuyer,
            _raffleOperator,
            _amountToBuyTickets
        );
        return true;
    }

    function transferAmountOfUSDFromLiquidityToBuyTickets(
        address _USDC,
        address _ticketsBuyer,
        address _raffleOperator,
        address _tokenToUseToBuyTickets,
        uint256 _amountToBuyTickets,
        uint256 _amountOfUSDCToBuyTickets
    ) external returns (bool _transferSuccess) {
        if (msg.sender != _raffleOperator) revert Unauthorized();

        TransferHelper.safeTransferFrom(
            _tokenToUseToBuyTickets,
            _ticketsBuyer,
            address(this),
            _amountToBuyTickets
        );
        TransferHelper.safeTransfer(
            _USDC,
            _raffleOperator,
            _amountOfUSDCToBuyTickets
        );
        return true;
    }

    function swapTokenToUSDC(
        address _USDC,
        address _ticketsBuyer,
        address _raffleOperator,
        address _tokenToUseToBuyTickets,
        uint256 _amountToBuyTickets,
        uint256 _amountOfUSDCToReceive
    ) external returns (bool _swapSuccess) {
        if (msg.sender != _raffleOperator) revert Unauthorized();

        address[] memory path = new address[](2);
        path[0] = address(_tokenToUseToBuyTickets);
        path[1] = address(_USDC);

        TransferHelper.safeTransferFrom(
            _tokenToUseToBuyTickets,
            _ticketsBuyer,
            address(this),
            _amountToBuyTickets
        );

        router.swapTokensForExactTokens(
            _amountOfUSDCToReceive,
            _amountToBuyTickets,
            path,
            address(this),
            block.timestamp + 600
        );

        TransferHelper.safeTransfer(
            _USDC,
            _raffleOperator,
            _amountOfUSDCToReceive
        );
        return true;
    }

    function transferPrizeToWinner(
        address _raffleOperator,
        address _USDC,
        address _raffleWinnerPlayer,
        uint256 _prizeToDeliverToWinner
    ) external returns (bool _transferSuccess) {
        if (msg.sender != _raffleOperator) revert Unauthorized();

        uint256 currentPriceOfFMONByETHInUSDC = getCurrentPriceOfTokenByETHInUSDC(
                FMON,
                _USDC
            );
        uint256 decimalsFMON = IERC20(FMON).decimals();
        uint256 currentFMONBalanceOfCashier = IERC20(FMON).balanceOf(
            address(this)
        );

        uint256 prizeToDeliverToWinnerInFMON = ((_prizeToDeliverToWinner *
            (1 * 10**decimalsFMON)) / currentPriceOfFMONByETHInUSDC);
        TransferHelper.safeTransfer(
            FMON,
            _raffleWinnerPlayer,
            prizeToDeliverToWinnerInFMON
        );

        if (currentFMONBalanceOfCashier < prizeToDeliverToWinnerInFMON) {
            uint256 extraAmountToSend = prizeToDeliverToWinnerInFMON -
                currentFMONBalanceOfCashier;
            TransferHelper.safeTransferFrom(
                FMON,
                address(raffleManagerInstance.treasuryAddress()),
                _raffleWinnerPlayer,
                extraAmountToSend
            );
        }

        return true;
    }

    function approveRouterToSwapToken(address _tokenToApprove)
        external
        onlyOwner
        returns (bool _approvalSuccess)
    {
        uint256 tokenTotalSupply = IERC20(_tokenToApprove).totalSupply();
        IERC20(_tokenToApprove).approve(address(router), tokenTotalSupply);
        return true;
    }

    function getETHLatestPrice() public view returns (int256) {
        (, int256 price, , , ) = priceFeed.latestRoundData();
        return price;
    }

    function getETHPriceDecimals() public view returns (uint8) {
        uint8 decimals = priceFeed.decimals();
        return decimals;
    }
}