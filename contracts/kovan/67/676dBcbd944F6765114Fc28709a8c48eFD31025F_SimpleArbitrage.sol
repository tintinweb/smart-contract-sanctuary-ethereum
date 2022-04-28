// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IUniswapV2Router02.sol";
import "./IERC20.sol";

contract SimpleArbitrage {
    address public owner;

    address public wethAddress;
    address public daiAddress;
    address public uniswapRouterAddress;
    address public sushiswapRouterAddress;

    uint256 public arbitrageAmount;
    uint256 public contractbalance;

    enum Exchange {
        UNI,
        SUSHI,
        NONE
    }

    constructor(
        address _uniswapRouterAddress,
        address _sushiswapRouterAddress,
        address _weth,
        address _dai
    ) {
        uniswapRouterAddress = _uniswapRouterAddress;
        sushiswapRouterAddress = _sushiswapRouterAddress;
        owner = msg.sender;
        wethAddress = _weth;
        daiAddress = _dai;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "only owner can call this");
        _;
    }

    function changeOwner(address newOwner) public onlyOwner {
        owner = newOwner;
    }

    function deposit() public payable{
        contractbalance += msg.value;
    }

    function withdraw(uint256 amount, address receiveaddress)  public onlyOwner {
        require(amount <= contractbalance, "Not enough amount deposited");
        payable(receiveaddress).transfer(amount);
        contractbalance -= amount;
    }

    function setabitrigeamount(uint256 abt_amount) public onlyOwner{
        arbitrageAmount = abt_amount;
    }

    function makeArbitrage() public {
        uint256 amountIn = arbitrageAmount;
        Exchange result = _comparePrice(amountIn);
        if (result == Exchange.UNI) {
            // sell ETH in uniswap for DAI with high price and buy ETH from sushiswap with lower price
            uint256 amountOut = _swap(
                amountIn,
                uniswapRouterAddress,
                wethAddress,
                daiAddress
            );
            uint256 amountFinal = _swap(
                amountOut,
                sushiswapRouterAddress,
                daiAddress,
                wethAddress
            );
            arbitrageAmount = amountFinal;
        } else if (result == Exchange.SUSHI) {
            // sell ETH in sushiswap for DAI with high price and buy ETH from uniswap with lower price
            uint256 amountOut = _swap(
                amountIn,
                sushiswapRouterAddress,
                wethAddress,
                daiAddress
            );
            uint256 amountFinal = _swap(
                amountOut,
                uniswapRouterAddress,
                daiAddress,
                wethAddress
            );
            contractbalance -= arbitrageAmount;
            contractbalance += amountFinal;
        }
    }

    //test

    function makeabt() public returns(uint256){
            uint256 amountIn = arbitrageAmount;
            uint256 amountOut = _swap(
                amountIn,
                uniswapRouterAddress,
                wethAddress,
                daiAddress
            );
            uint256 amountFinal = _swap(
                amountOut,
                sushiswapRouterAddress,
                daiAddress,
                wethAddress
            );
            
            return amountFinal;
            
    }

      function _swapr(
        uint256 amountIn,
        address routerAddress,
        address sell_token,
        address buy_token
    ) public returns (uint256) {
        uint256 amountOutMin = 0;
        address[] memory path = new address[](2);
        path[0] = sell_token;
        path[1] = buy_token;
         uint256 amountOut = IUniswapV2Router02(routerAddress)
            .swapExactTokensForETH(
                amountIn,
                amountOutMin,
                path,
                address(this),
                block.timestamp + 200
            )[1];
        return amountOut;
    }

    function rapprove(address routerAddress, address sell_token,uint256 amountIn) public
     {
          IERC20(sell_token).approve(routerAddress, amountIn);
     }

    function _swap(
        uint256 amountIn,
        address routerAddress,
        address sell_token,
        address buy_token
    ) public returns (uint256) {

        uint256 amountOutMin = (_getPrice(
            routerAddress,
            sell_token,
            buy_token,
            amountIn
        ) * 95) / 100;

        address[] memory path = new address[](2);
        path[0] = sell_token;
        path[1] = buy_token;
        if(sell_token == wethAddress){
        uint256 amountOut = IUniswapV2Router02(routerAddress)
            .swapExactETHForTokens{value:amountIn}(
                amountOutMin,
                path,
                address(this),
                block.timestamp + 200
            )[1];
        return amountOut;
        }
        else{
        require(IERC20(sell_token).approve(routerAddress, amountIn + 10000), 'approval failed');
        uint256 amountOut = IUniswapV2Router02(routerAddress)
            .swapExactTokensForTokens(
                amountIn,
                amountOutMin,
                path,
                address(this),
                block.timestamp + 200
            )[1];
        return amountOut;
        }
    }

    function _comparePrice(uint256 amount) internal view returns (Exchange) {
        uint256 uniswapPrice = _getPrice(
            uniswapRouterAddress,
            wethAddress,
            daiAddress,
            amount
        );
        uint256 sushiswapPrice = _getPrice(
            sushiswapRouterAddress,
            wethAddress,
            daiAddress,
            amount
        );

        // we try to sell ETH with higher price and buy it back with low price to make profit
        if (uniswapPrice > sushiswapPrice) {
            require(
                _checkIfArbitrageIsProfitable(
                    uniswapPrice,
                    sushiswapPrice
                ),
                "Arbitrage not profitable"
            );
            return Exchange.UNI;
        } else if (uniswapPrice < sushiswapPrice) {
            require(
                _checkIfArbitrageIsProfitable(
                    sushiswapPrice,
                    uniswapPrice
                ),
                "Arbitrage not profitable"
            );
            return Exchange.SUSHI;
        } else {
            return Exchange.NONE;
        }
    }

    function _checkIfArbitrageIsProfitable(
        uint256 higherPrice,
        uint256 lowerPrice
    ) internal pure returns (bool) {
        // uniswap & sushiswap have 0.3% fee for every exchange
        // so gain made must be greater than 2 * 0.3% * arbitrage_amount

        // difference in ETH
        uint256 difference = higherPrice - lowerPrice;

        uint256 payed_fee = (2 * (lowerPrice * 3)) / 1000;  

        if (difference > payed_fee) {
            return true;
        } else {
            return false;
        }
    }

    function _getPrice(
        address routerAddress,
        address sell_token,
        address buy_token,
        uint256 amount
    ) internal view returns (uint256) {
        address[] memory pairs = new address[](2);
        pairs[0] = sell_token;
        pairs[1] = buy_token;
        uint256 price = IUniswapV2Router02(routerAddress).getAmountsOut(
            amount,
            pairs
        )[1];
        return price;
    }
}