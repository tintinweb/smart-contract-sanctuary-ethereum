/**
 *Submitted for verification at Etherscan.io on 2023-01-27
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

contract FlashLoanArbitrage {
    /*
        This contract is very simplistic and for demonstration purposes only. Here, we always sell on the SushiSwap
        pool and buy back on the Uniswap pool (ie. we assume the Uniswap pool is always the one trading cheaper). In a
        real contract, some things you might want to do include not hard coding the tokens or pools, dynamically
        finding the optimal arbitrage path and amounts, and checking to ensure the arbitrage is profitable, just a few
        examples.
    */
    uint256 constant MAX_UINT = 2**256 - 1;

    // Address of the wBTC token contract
    address constant WBTC_TOKEN = 0x45AC379F019E48ca5dAC02E54F406F99F5088099;

    // Address of the LUSD token contract
    address constant LUSD_TOKEN = 0x4966Bb6Cd9f3e042331b0798525b7970eFB0D94A;

    // Addresses of the SushiSwap and Uniswap V2 routers we will be interacting with to perform the swaps
    address constant SUSHISWAP_ROUTER = 0x1b02dA8Cb0d097eB8D57A175b88c7D8b47997506;
    address constant UNISWAP_ROUTER = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;

    // Address of the Aave pool we will be flash loaning from
    address constant AAVE_POOL = 0x7b5C526B7F8dfdff278b4a3e045083FBA4028790;

    constructor() {
        // Approve the SushiSwap router for all our wBTC
        IERC20(WBTC_TOKEN).approve(SUSHISWAP_ROUTER, MAX_UINT);

        // Approve the Uniswap V2 router for all our LUSD
        IERC20(LUSD_TOKEN).approve(UNISWAP_ROUTER, MAX_UINT);

        // Approve the Aave pool for all our wBTC (needed to return the flash loan)
        IERC20(WBTC_TOKEN).approve(AAVE_POOL, MAX_UINT);
    }

    /**
     * @dev The entry point to this contract to perform the arbitrage. In this simplistic example,
            we flash loan a constant amount of wBTC from the Aave pool and always perform swap it
            for LUSD using the SushiSwap pool, and then swap the LUSD back to wBTC using the
            Uniswap pool.
     */
    function arbitrage() external returns (uint256) {
        // Record the starting balance of wBTC so we can calculate our profit
        // NOTE: We don't need any wBTC to do the arbitrage; that's the point of the flash loan!
        uint256 startingBalance = IERC20(WBTC_TOKEN).balanceOf(address(this));

        // Call the flash loan function in the Aave pool contract
        // See Aave docs for more information:
        // https://docs.aave.com/developers/core-contracts/pool#flashloansimple
        IPool(AAVE_POOL).flashLoanSimple(
            address(this), // receiverAddress: this contract
            WBTC_TOKEN, // asset: wBTC
            1000000, // amount: 0.01 wBTC
            "", // params: not relevant here
            0 // referralCode: not relevant here
        );

        // Any code below will only execute if the flash loan was successful
        uint256 endingBalance = IERC20(WBTC_TOKEN).balanceOf(address(this));

        // This is our profit in wBTC
        return endingBalance - startingBalance;
    }

    /**
     * @dev The callback function that will be invoked by the Aave contract.
     * @param asset The address of the flash-borrowed asset
     * @param amount The amount of the flash-borrowed asset
     * @param premium The fee of the flash-borrowed asset
     * @param initiator The address of the flashloan initiator
     * @param params The byte-encoded params passed when initiating the flashloan
     * @return True if the execution of the operation succeeds, false otherwise
     */
    function executeOperation(
        address asset,
        uint256 amount,
        uint256 premium,
        address initiator,
        bytes calldata params
    ) external returns (bool) {
        // We interact with the routers to perform the swap, rather than the actual pool contracts directly
        IUniswapV2Router02 sushiswapRouter = IUniswapV2Router02(SUSHISWAP_ROUTER);
        IUniswapV2Router02 uniswapRouter = IUniswapV2Router02(UNISWAP_ROUTER);


        /***** Swap all our wBTC for LUSD using the SushiSwap pool *****/

        // Construct swap path
        address[] memory path = new address[](2);
        path[0] = WBTC_TOKEN;
        path[1] = LUSD_TOKEN;

        // Swap the 0.01 wBTC we flash loaned into LUSD
        sushiswapRouter.swapExactTokensForTokens(
            amount, // amountIn: amount of wBTC
            0, // amountOutMin: minimum acceptable LUSD received
            path, // path: swap path
            address(this), // to: this contract
            block.timestamp // deadline: latest acceptable time to complete the swap by
        );


        /***** Swap all our LUSD for wBTC using the Uniswap pool *****/

        // Construct swap path
        path[0] = LUSD_TOKEN;
        path[1] = WBTC_TOKEN;

        // Swap all the LUSD we received from the previous swap back into wBTC
        uniswapRouter.swapExactTokensForTokens(
            IERC20(LUSD_TOKEN).balanceOf(address(this)), // amountIn: amount of LUSD
            0, // amountOutMin: minimum acceptable wBTC received
            path, // path: swap path
            address(this), // to: this contract
            block.timestamp // deadline: latest acceptable time to complete the swap by
        );

        return true;
    }
}

/**
 * @dev Partial interface for a Uniswap V2 router contract (SushiSwap pools use the same interface).
 */
interface IUniswapV2Router02 {
    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);
}

/**
 * @dev Partial interface for an Aave V3 pool contract.
 */
interface IPool {
    function flashLoanSimple(
        address receiverAddress,
        address asset,
        uint256 amount,
        bytes calldata params,
        uint16 referralCode
    ) external;
}

/**
 * @dev Partial interface for an ERC-20 token.
 */
interface IERC20 {
    function approve(address spender, uint256 amount) external returns (bool);

    function balanceOf(address account) external view returns (uint256);
}