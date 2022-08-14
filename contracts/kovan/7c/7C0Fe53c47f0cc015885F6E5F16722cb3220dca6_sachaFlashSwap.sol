/**
 *Submitted for verification at Etherscan.io on 2022-08-14
*/

// SPDX-Licence-Identifier: MIT
pragma solidity ^0.8.0;


interface IERC20 {
    
    function balanceOf(address account) external view returns (uint256);

    function transfer(address to, uint256 amount) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

interface UniswapV2{
    function token0() external view returns (address);
    function token1() external view returns (address);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
}



interface IUniswapV2Callee{
    function uniswapV2Call(
        address sender,
        uint amount0,
        uint amount1,
        bytes calldata data
    )external;
}

contract sachaFlashSwap {//is IUniswapV2Callee

    /*event Log(string message, uint val);

    function tryFlashSwap(address _tokenBorrow, uint _amount, address factory, address token_reimburse) external{
        address pair = UniswapV2(factory).getPair(_tokenBorrow,token_reimburse);
        require(pair != address(0), "!pair");

        address token0 = UniswapV2(pair).token0();
        address token1 = UniswapV2(pair).token1();
        uint amount0Out = token0 == _tokenBorrow ? _amount : 0;
        uint amount1Out = token1 == _tokenBorrow ? _amount : 0;

        bytes memory data = abi.encode(_tokenBorrow,_amount,factory);

        UniswapV2(pair).swap(amount0Out,amount0Out,address(this),data);
    }

    function uniswapV2Call(
        address _sender,
        uint amount0,
        uint amount1,
        bytes calldata _data
    )external override{
        (address tokenBorrow, uint amount, address factory) = abi.decode(_data,(address,uint,address));
        address token0 = UniswapV2(msg.sender).token0();
        address token1 = UniswapV2(msg.sender).token1();
        address pair = UniswapV2(factory).getPair(token0,token1);
        require(pair==msg.sender,"!pair");
        require(_sender == address(this), "!sender");

        

        //about 0.3%
        uint fee = ((amount *3)/997)+1;
        uint amountToRepay = amount + fee;

        //doing other swap for exemple

        IERC20(tokenBorrow).transfer(pair,amountToRepay);
    }*/
    struct swap_info{
        uint fees_rate;
        address factory;
    }
    /*function simple_swap(uint amountIn, uint amountOut, address[] calldata path, swap_info[] calldata infos) external {
        for(uint i =0; i<path.length-1; i++){
            #on check si lamount est acceptable 

        }
    }*/

    function get_amounts_out(address[] calldata path, swap_info[] calldata infos, uint amountIn) external view returns(uint[] memory){
        uint[] memory amountOuts = new uint[](infos.length);
        uint actualAmount = amountIn;
        for(uint i = 0; i<amountOuts.length; i++){
            //get pair
            address pair = UniswapV2(infos[i].factory).getPair(path[i],path[i+1]);
            (uint reserveIn, uint reserveOut,) = UniswapV2(pair).getReserves();
            if(UniswapV2(pair).token0() == path[i+1]){
                //ça veux dire qu'on est dans le mauvais sens go inverser les reserves
                uint reserveTemp = reserveIn;//variable uniquement utile afin de 
                reserveIn = reserveOut;
                reserveOut = reserveTemp;
            }
    
            //call the calculation function 
            amountOuts[i] = get_amount_out(actualAmount,reserveIn,reserveOut,infos[i].fees_rate);

        }
        return amountOuts;
    }

    function get_amount_out(uint amountIn,uint reserveIn,uint reserveOut,uint feesBase10000) internal pure returns(uint amount_out)
    {
        return reserveOut-(reserveIn*reserveOut)/(reserveIn+(amountIn*feesBase10000)/10000);
    }

    /*struct sacha{
        uint nombreP;
        string nom;
    }

    function afficheMesStruct(sacha[] calldata structTest) public pure returns(uint[] memory, string[] memory){
        uint[] memory nb = new uint[](structTest.length);
        string[] memory str = new string[](structTest.length);
        for(uint i = 0; i < structTest.length; i++){
            nb[i] = structTest[i].nombreP;
            str[i] = structTest[i].nom;
        }
        return(nb,str);
    }*/

    
}