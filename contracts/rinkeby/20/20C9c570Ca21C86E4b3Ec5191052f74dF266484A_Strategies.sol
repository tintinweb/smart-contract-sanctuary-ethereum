/**
 *Submitted for verification at Etherscan.io on 2022-01-31
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.11;

// We create the interfaces to the contracts we will be calling
interface ISbUSD {
    function approve(
        address spender, 
        uint256 amount
        ) external returns (bool);
}

interface IStableSwapSbUSD {
    function get_dy_underlying(
        int128 i, 
        int128 j, 
        uint256 dx
        ) external view returns(uint256); 
    
    function exchange_underlying(
        int128 i, 
        int128 j, 
        uint256 dx, 
        uint256 min_dy
        ) external returns(uint256);
}

interface IUniswapV2Router {
    function swapExactTokensForTokens(
        uint256 amountIn, 
        uint256 amountOutMin, 
        address[] memory path, 
        address to,
        uint256 deadline
        ) external returns(uint[] memory amounts);
}


contract Strategies{
    /**
     * @dev this contract performs an exchange sbUSD/USDC following one of two available strategies
     * stableSwapAddress: address of the Stable Swap Metapool
     * strategyAddress: address of the Strategy Swap pool
     * uniRouterAddress: address to UniswapV2 Router contract
     * strategy: True to use the Strategy, False to use UniswapV2
     */
    address owner;
    address sbUSDAddress;
    address usdcAddress;
    address stableSwapAddress;
    address uniRouterAddress;
    bool strategy;

    event highSlippage(string failure);

    constructor() {
        owner = msg.sender;
        sbUSDAddress = 0xf9F73c4a9c45EA93d49F5f0A7447716699ffAC9b;
        usdcAddress = 0x1D54C9F7ce7eb6Ef50eAeA43Ea644b7BB786B106;
        stableSwapAddress = 0x4989E2a01280A5FE125AC9b7FfC6d1cD8030c2F5;
        uniRouterAddress = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
        strategy = false;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function setStrategy(bool _strategy) external onlyOwner{
        strategy = _strategy;
    }

    function _swapStrategy(uint256 _dx, uint256 _min_dy) internal returns(uint256) {
        uint256 dy1 = IStableSwapSbUSD(stableSwapAddress).
                        exchange_underlying(0, 2, _dx/2, _min_dy/4); //to make it work
        uint256 dy2 = _uniswap(_dx - _dx/2, _min_dy/2);
        return dy1+dy2;
    }

    function _uniswap(uint256 _dx, uint256 _min_dy) internal returns(uint256) {
        uint256 deadline = block.timestamp + 60;
        address[] memory path = new address[](2);
        path[0] = sbUSDAddress;
        path[1] = usdcAddress;
        uint256 dy = IUniswapV2Router(uniRouterAddress).
                        swapExactTokensForTokens(_dx, _min_dy, path, msg.sender, deadline)[0];
        return dy;
    }

    function exchange(uint256 _dx, uint256 _max_slippage) external returns(uint256 dy) {
        /**
         * @dev it performs an exchange of sbUSD for USDC using the predefined strategy
         * @param _dx amount of sbUSD to exchange
         * @param _max_slippage maximal slippage allowed in units/100000 (0.5% <--> 500)
         * @return dy the amount of USDC obtained
         */
         
        //assert (_max_slippage < 100000);

        // estimate the dy to obtain in the swap and setting the minimal amount after slippage
        uint256 dy_estimated = IStableSwapSbUSD(stableSwapAddress).get_dy_underlying(0, 2, _dx);
        uint256 min_dy = dy_estimated * (100000-_max_slippage) / 100000; // amount will be rounded

        // approve the sbUSD amount to swap before transfering it to the swap
        ISbUSD(sbUSDAddress).approve(stableSwapAddress, _dx);

        // @dev Make a big transaction now in order to generate big slippage.
        
        // try to swap with the determined amount
        try IStableSwapSbUSD(stableSwapAddress).exchange_underlying(0, 2, _dx, min_dy) returns (uint256) {
            return dy;
        } 
        catch Error(string memory _err) {
            emit highSlippage(_err);
            ISbUSD(sbUSDAddress).approve(stableSwapAddress, 0); // Avoid double ERC20 approve attack
            if (strategy) {
                // Reroute to my strategy 
                ISbUSD(sbUSDAddress).approve(stableSwapAddress, _dx/2);
                ISbUSD(sbUSDAddress).approve(stableSwapAddress, _dx - _dx/2);
                
                dy = _swapStrategy(_dx, min_dy);
                return dy;
            }
            else {
                // Reroute to UniswapV2
                ISbUSD(sbUSDAddress).approve(uniRouterAddress, _dx);

                dy = _uniswap(_dx, min_dy);
                return dy;
            }
        } 
    }
    
}