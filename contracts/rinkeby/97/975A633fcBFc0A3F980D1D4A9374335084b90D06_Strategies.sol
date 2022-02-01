/**
 *Submitted for verification at Etherscan.io on 2022-02-01
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.11;

// We create the interfaces to the contracts we will be calling
interface IStableCoin {
    function approve(
        address spender, 
        uint256 amount
        ) external returns (bool);
    
    function transferFrom(
        address sender, 
        address recipient, 
        uint256 amount
        ) external returns (bool);
    
    function balanceOf(
        address account
        ) external view returns (uint256);
    
    function transfer(
        address recipient, 
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
        address[] calldata path, 
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
    address public owner;
    address sbUSDAddress;
    address usdcAddress;
    address stableSwapAddress;
    address uniRouterAddress;
    bool public strategy;

    event highSlippage(string failure);

    constructor() {
        owner = msg.sender;
        sbUSDAddress = 0xf9F73c4a9c45EA93d49F5f0A7447716699ffAC9b;
        usdcAddress = 0x1D54C9F7ce7eb6Ef50eAeA43Ea644b7BB786B106;
        stableSwapAddress = 0x4989E2a01280A5FE125AC9b7FfC6d1cD8030c2F5;
        uniRouterAddress = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
        strategy = true;
    }

    function _intDiv(uint256 a, uint256 b) internal pure returns (uint256){
        //returns the integer part of a/b 
        return a/b; 
    }

    modifier onlyOwner {
        require(msg.sender == owner, "Not owner");
        _;
    }

    function setStrategy(bool _strategy) external onlyOwner{
        /** Switch between our strategy and UniswapV2 strategy
         * @param _strategy true for strategy, false for Uniswap
         */ 
        require(_strategy != strategy, "Strategy already selected");
        strategy = _strategy;
    }

    function _swapStrategy(uint256 _dx, uint256 _min_dy) internal returns(uint256) {
        /** We split the swap between StableSwap and UniswapV2
         * @param _dx amount of sBUSD to echange
         * @param _min_dy minimum amount of USDC to receive
         */ 
        uint256 dy1 = IStableSwapSbUSD(stableSwapAddress).exchange_underlying(0, 2, _intDiv(_dx, 2),_intDiv(_min_dy,10)); //to make it work
        uint256 dy2 = _uniswap(_dx - _intDiv(_dx, 2), _intDiv(_min_dy, 2));
        return dy1 + dy2;
    }

    function _uniswap(uint256 _dx, uint256 _min_dy)  internal returns(uint256){
        /** UniswapV2 exchange
         * @param _dx amount of sBUSD to echange
         * @param _min_dy minimum amount of USDC to receive
         */ 
        uint256 deadline = block.timestamp + 600;
        address[] memory path = new address[](2);
        path[0] = sbUSDAddress;
        path[1] = usdcAddress;
        uint256 usdcAmount = IUniswapV2Router(uniRouterAddress).swapExactTokensForTokens(_dx, _min_dy, path, address(this), deadline)[1];
        return usdcAmount;
        
    }

    function exchange(uint256 _dx, uint256 _max_slippage) external {
        /**
         * @dev it performs an exchange of sbUSD for USDC using the predefined strategy
         * @param _dx amount of sbUSD to exchange
         * @param _max_slippage maximal slippage allowed in units/100000 (0.5% <--> 500)
         */
         
        //assert (_max_slippage < 100000);

        // estimate the dy to obtain in the swap and setting the minimal amount after slippage
        uint256 dy_estimated = IStableSwapSbUSD(stableSwapAddress).get_dy_underlying(0, 2, _dx);
        uint256 min_dy = _intDiv(dy_estimated * (100000 -_max_slippage), 100000); // amount will be rounded

        // transfer the sbUSD amount to this contract before transfering it to the swap
        IStableCoin(sbUSDAddress).transferFrom(msg.sender, address(this), _dx);

        IStableCoin(sbUSDAddress).approve(stableSwapAddress, _dx);

        // @dev Make a big transaction now in order to generate big slippage.
        uint256 dy;
        // try to swap with the determined amount
        try IStableSwapSbUSD(stableSwapAddress).exchange_underlying(0, 2, _dx, min_dy) returns (uint256 _dy) {
            dy = _dy;
        }
        catch Error(string memory _err) {
            emit highSlippage(_err);

            IStableCoin(sbUSDAddress).approve(stableSwapAddress, 0); // Avoid double ERC20 approve attack

            if (strategy) {
                // Reroute to my strategy 
                IStableCoin(sbUSDAddress).approve(stableSwapAddress, _intDiv(_dx, 2));
                IStableCoin(sbUSDAddress).approve(uniRouterAddress, _dx - _intDiv(_dx, 2));
                
                dy = _swapStrategy(_dx, _intDiv(min_dy,1));
            }
            else {
                // Reroute to UniswapV2
                IStableCoin(sbUSDAddress).approve(uniRouterAddress, _dx);

                dy = _uniswap(_dx, _intDiv(min_dy,1));
            }
        } 

        // send back all the USDC obtained to msg.sender
        IStableCoin(usdcAddress).transfer(msg.sender, dy);
    }
    
}