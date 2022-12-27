/**
 *Submitted for verification at Etherscan.io on 2022-12-26
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface UniswapV2{

    function swap(
        uint256 amount0Out,
        uint256 amount1Out,
        address to,
        bytes calldata data
    ) external;
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getReserves()
        external
        view
        returns (
            uint112 reserve0,
            uint112 reserve1,
            uint32 blockTimestampLast
        );
}

interface IERC20 {

    function transfer(address to, uint256 amount) external returns (bool);

    /*function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);*/
}

contract LowFeeTrader{
    using SafeMath for uint;
    address payable public owner;
    address payable public simulate_contract;
    
    constructor() {
        owner = payable(msg.sender);
    }

    // **** ADD and withdraw funds ****
    receive() external payable {

    }

    function setSimulateContractAddress(address payable newAddress) external{
        require(msg.sender==owner,"T as tout tente frero arrete un peu");
        simulate_contract = newAddress;
    } 

    function transferIERC20(address token, address to, uint amount) public{
        require(msg.sender==owner,"Crois pas tu peux partir avec mes ERC20 sans pression bonhomme");
        IERC20(token).transfer(to,amount);
    }

    struct swap_info{
        //address factory;
        address pair;
        //address token0;
        bool token0Starting;
        //address token1;
        //address router;
        uint baseFee;
        uint realFee;
    }

    function TLF(
        //Trade Low Fee without token support fees
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        swap_info[] calldata infos
    ) external {
        //get amount out
        require(msg.sender==owner || (msg.sender == simulate_contract && simulate_contract!=address(0)),"Il serait temps d'arreter d'essayer de voler mon argent");
        uint[] memory amounts = new uint[](path.length);
        amounts = getAmountsOut(amountIn, path, infos);
        require(amounts[amounts.length-1]>amountOutMin,"Malheureusement la simulation montre qu'on va perdre de l'argent");
        //On send a la première lp
        IERC20(path[0]).transfer(infos[0].pair,amountIn);
        //loop through the the path for the 2 first trades 
        for(uint i=0; i<infos.length-1; i++ ){
            //if we start with token 0 we do this 
            if(infos[i].token0Starting){
                UniswapV2(infos[i].pair).swap(0,amounts[i+1],infos[i+1].pair,new bytes(0));
            }
            else{
                //either we do this 
                UniswapV2(infos[i].pair).swap(amounts[i+1],0,infos[i+1].pair,new bytes(0));
            }
        }
        //do the last trade that come back to this address 
        if(infos[infos.length-1].token0Starting){
            UniswapV2(infos[infos.length-1].pair).swap(0,amounts[amounts.length-1],address(this),new bytes(0));
        }
        else{
            //either we do this 
            UniswapV2(infos[infos.length-1].pair).swap(amounts[amounts.length-1],0,address(this),new bytes(0));
        }
    }
    //get amounts Out 
    function getAmountsOut(uint amountIn, address[] memory path, swap_info[] memory infos) internal view returns (uint[] memory amounts){
        //require(path.length >= 2, 'PancakeLibrary: INVALID_PATH');
        amounts = new uint[](path.length);
        amounts[0] = amountIn;
        uint reserveIn;
        uint reserveOut;
        for (uint i; i < path.length - 1; i++) {

            if(infos[i].token0Starting){
                (reserveIn, reserveOut,) = UniswapV2(infos[i].pair).getReserves();
            }
            else{
                (reserveOut, reserveIn,) = UniswapV2(infos[i].pair).getReserves();
            }
            amounts[i + 1] = getAmountOut(amounts[i], reserveIn, reserveOut,infos[i]);
        }
    }

    //get amount Out 
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut, swap_info memory infos) internal pure returns (uint amountOut) {
        require(amountIn > 0, 'UniswapV2Library: INSUFFICIENT_INPUT_AMOUNT');
        require(reserveIn > 0 && reserveOut > 0, 'UniswapV2Library: INSUFFICIENT_LIQUIDITY');
        uint amountInWithFee = amountIn.mul(infos.realFee);
        uint numerator = amountInWithFee.mul(reserveOut);
        uint denominator = reserveIn.mul(infos.baseFee).add(amountInWithFee);
        amountOut = numerator / denominator;
    }

}

library SafeMath {
    function add(uint x, uint y) internal pure returns (uint z) {
        require((z = x + y) >= x, 'ds-math-add-overflow');
    }

    function sub(uint x, uint y) internal pure returns (uint z) {
        require((z = x - y) <= x, 'ds-math-sub-underflow');
    }

    function mul(uint x, uint y) internal pure returns (uint z) {
        require(y == 0 || (z = x * y) / y == x, 'ds-math-mul-overflow');
    }
}