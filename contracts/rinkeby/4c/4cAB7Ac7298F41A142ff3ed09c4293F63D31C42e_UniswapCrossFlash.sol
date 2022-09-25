//SPDX-License-Identifier: Unlicense
pragma solidity >=0.6.6;


// Uniswap interface and library imports
import "UniswapV2Library.sol";
import "SafeERC20.sol";
import "IUniswapV2Router01.sol";
import "IUniswapV2Router02.sol";
import "IUniswapV2Pair.sol";
import "IUniswapV2Factory.sol";
import "IERC20.sol";

contract UniswapCrossFlash {
    using SafeERC20 for IERC20;

    // Factory and Routing Addresses
    address private constant UNISWAP_FACTORY =
        0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f;
    address private constant UNISWAP_ROUTER =
        0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    address private constant SUSHI_FACTORY =
        0xC0AEe478e3658e2610c5F7A4A2E1777cE9e4f2Ac;
    address private constant SUSHI_ROUTER =
        0xd9e1cE17f2641f24aE83637ab66a2cca9C378B9F;

    // Token Addresses
    address private constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address private constant USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address private constant LINK = 0x514910771AF9Ca656af840dff83E8264EcF986CA;

    // Trade Variables
    uint256 private deadline = block.timestamp + 1 days;
    uint256 private constant MAX_INT =
        115792089237316195423570985008687907853269984665640564039457584007913129639935;

    // FUND SMART CONTRACT
    // Provides a function to allow contract to be funded
    function fundFlashSwapContract(
        address _owner,
        address _token,
        uint256 _amount
    ) public {
        IERC20(_token).transferFrom(_owner, address(this), _amount);
    }

    // GET CONTRACT BALANCE
    // Allows public view of balance for contract
    function getBalanceOfToken(address _address) public view returns (uint256) {
        return IERC20(_address).balanceOf(address(this));
    }

    // PLACE A TRADE
    // Executed placing a trade
    function placeTrade(
        address _fromToken,
        address _toToken,
        uint256 _amountIn,
        address factory,
        address router
    ) private returns (uint256) {
        address pair = IUniswapV2Factory(factory).getPair(_fromToken, _toToken);
        require(pair != address(0), "Pool does not exist");

        // Calculate Amount Out
        address[] memory path = new address[](2);
        path[0] = _fromToken;
        path[1] = _toToken;

        uint256 amountRequired = IUniswapV2Router01(router).getAmountsOut(
            _amountIn,
            path
        )[1];

        // console.log("amountRequired", amountRequired);

        // Perform Arbitrage - Swap for another token
        uint256 amountReceived = IUniswapV2Router01(router)
            .swapExactTokensForTokens(
                _amountIn, // amountIn
                amountRequired, // amountOutMin
                path, // path
                address(this), // address to
                deadline // deadline
            )[1];

        // console.log("amountRecieved", amountReceived);

        require(amountReceived > 0, "Aborted Tx: Trade returned zero");

        return amountReceived;
    }

    // CHECK PROFITABILITY
    // Checks whether > output > input
    function checkProfitability(uint256 _input, uint256 _output)
        private
        returns (bool)
    {
        return _output > _input;
    }

    // INITIATE ARBITRAGE
    // Begins receiving loan to engage performing arbitrage trades
    function startArbitrage(address _tokenBorrow, uint256 _amount) external {
        IERC20(WETH).safeApprove(address(UNISWAP_ROUTER), MAX_INT);
        IERC20(USDC).safeApprove(address(UNISWAP_ROUTER), MAX_INT);
        IERC20(LINK).safeApprove(address(UNISWAP_ROUTER), MAX_INT);

        IERC20(WETH).safeApprove(address(SUSHI_ROUTER), MAX_INT);
        IERC20(USDC).safeApprove(address(SUSHI_ROUTER), MAX_INT);
        IERC20(LINK).safeApprove(address(SUSHI_ROUTER), MAX_INT);

        // Get the Factory Pair address for combined tokens
        address pair = IUniswapV2Factory(UNISWAP_FACTORY).getPair(
            _tokenBorrow,
            WETH
        );

        // Return error if combination does not exist
        require(pair != address(0), "Pool does not exist");

        // Figure out which token (0 or 1) has the amount and assign
        address token0 = IUniswapV2Pair(pair).token0();
        address token1 = IUniswapV2Pair(pair).token1();
        uint256 amount0Out = _tokenBorrow == token0 ? _amount : 0;
        uint256 amount1Out = _tokenBorrow == token1 ? _amount : 0;

        // Passing data as bytes so that the 'swap' function knows it is a flashloan
        bytes memory data = abi.encode(_tokenBorrow, _amount, msg.sender);

        // Execute the initial swap to get the loan
        IUniswapV2Pair(pair).swap(amount0Out, amount1Out, address(this), data);
    }

    function uniswapV2Call(
        address _sender,
        uint256 _amount0,
        uint256 _amount1,
        bytes calldata _data
    ) external {
        // Ensure this request came from the contract
        address token0 = IUniswapV2Pair(msg.sender).token0();
        address token1 = IUniswapV2Pair(msg.sender).token1();
        address pair = IUniswapV2Factory(UNISWAP_FACTORY).getPair(
            token0,
            token1
        );
        require(msg.sender == pair, "The sender needs to match the pair");
        require(_sender == address(this), "Sender should match this contract");

        // Decode data for calculating the repayment
        (address tokenBorrow, uint256 amount, address myAddress) = abi.decode(
            _data,
            (address, uint256, address)
        );

        // Calculate the amount to repay at the end
        uint256 fee = ((amount * 3) / 997) + 1;
        uint256 amountToRepay = amount + fee;

        // DO ARBITRAGE

        // Assign loan amount
        uint256 loanAmount = _amount0 > 0 ? _amount0 : _amount1;

        // Trade 1
        uint256 trade1Acquired = placeTrade(
            USDC,
            LINK,
            loanAmount,
            UNISWAP_FACTORY,
            UNISWAP_ROUTER
        );

        // Trade 2
        uint256 trade2Acquired = placeTrade(
            LINK,
            USDC,
            trade1Acquired,
            SUSHI_FACTORY,
            SUSHI_ROUTER
        );

        // Check Profitability
        bool profCheck = checkProfitability(amountToRepay, trade2Acquired);
        require(profCheck, "Arbitrage not profitable");

        // Pay Myself
        IERC20 otherToken = IERC20(USDC);
        otherToken.transfer(myAddress, trade2Acquired - amountToRepay);

        // Pay Loan Back
        IERC20(tokenBorrow).transfer(pair, amountToRepay);
    }
}