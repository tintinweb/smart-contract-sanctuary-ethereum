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

contract sachaFlashSwap is IUniswapV2Callee{
     using SafeMath for uint;
    event Log(string message, uint val);

    struct swap_info{
        uint fees_rate;
        address factory;
    }

    address payable public owner;

    constructor() public {
        owner = payable(msg.sender);
    }
    // **** ADD and withdraw funds ****
    receive() external payable {
        //assert(msg.sender == WETH); // only accept ETH via fallback from the WETH contract
    }

    function withdraw(uint _amount) external {
        require(msg.sender==owner,"Petit malin tu crois que tu peux recup mon flouz ?");
        payable(msg.sender).transfer(_amount);
    }

    function transferIERC20(address token, address to, uint amount) public{
        require(msg.sender==owner,"Crois pas tu peux partir avec mes ERC20 sans pression bonhomme");
        IERC20(token).transfer(to,amount);
    }

    function _swap_fees(address[] memory path, address _to,swap_info[] memory infos, uint startI) internal virtual {
        for (uint i=startI; i < path.length - 1; i++) {
            //(address input, address output) = (path[i], path[i + 1]);
            (address token0,) = UniswapV2Library.sortTokens(path[i], path[i + 1]);
            UniswapV2 pair = UniswapV2(UniswapV2Library.pairFor(infos[i].factory, path[i], path[i + 1]));
            uint amountInput;
            uint amountOutput;
            { // scope to avoid stack too deep errors
            (uint reserve0, uint reserve1,) = pair.getReserves();
            (uint reserveInput, uint reserveOutput) = path[i] == token0 ? (reserve0, reserve1) : (reserve1, reserve0);
            amountInput = IERC20(path[i]).balanceOf(address(pair)).sub(reserveInput);
            amountOutput = UniswapV2Library.getAmountOut(amountInput, reserveInput, reserveOutput,infos[i].fees_rate);
            }
            (uint amount0Out, uint amount1Out) = path[i] == token0 ? (uint(0), amountOutput) : (amountOutput, uint(0));
            address to = i < path.length - 2 ? UniswapV2Library.pairFor(infos[i+1].factory, path[i + 1], path[i + 2]) : _to;
            pair.swap(amount0Out, amount1Out, to, new bytes(0));
        }
    }
    function swapExactTokensWithFees(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        swap_info[] calldata infos
    ) external virtual {
        IERC20(path[0]).transfer(
            UniswapV2Library.pairFor(infos[0].factory, path[0], path[1]), amountIn
        );
        uint balanceBefore = IERC20(path[path.length - 1]).balanceOf(address(this));
        _swap_fees(path, address(this),infos,0);
        require(
            IERC20(path[path.length - 1]).balanceOf(address(this)).sub(balanceBefore) >= amountOutMin,
            'UniswapV2Router: INSUFFICIENT_OUTPUT_AMOUNT'
        );
    }

    function tryFlashSwap(uint amountIn, uint amountOutMin, address[] calldata path, swap_info[] calldata infos) external{
        address pair = UniswapV2(infos[0].factory).getPair(path[0],path[1]);
        require(pair != address(0), "Pair doesn't exist");
        uint[] memory amountsOut = getAmountsOutNoFeesFirst(amountIn, path, infos);
        require(amountsOut[amountsOut.length-1]>=amountOutMin,"La transaction n'est pas rentable au moment T");//on verif que a ce moment T ça passe 
        (address token0,) = UniswapV2Library.sortTokens(path[0], path[1]);
        uint amount0Out = 0;
        uint amount1Out = amountsOut[1];
        if(token0 == path[1]){
            amount0Out = amountsOut[1];
            amount1Out = 0;
        }

        bytes memory data = abi.encode(amountIn,amountOutMin,path,infos);

        UniswapV2(pair).swap(amount0Out,amount1Out,address(this),data);
    }

    function uniswapV2Call(
        address _sender,
        uint amount0,
        uint amount1,
        bytes calldata _data
    )external override{
        (uint amountIn,uint amountOutMin, address[] memory path, swap_info[] memory infos) = abi.decode(_data,(uint,uint,address[],swap_info[]));
        address token0 = UniswapV2(msg.sender).token0();
        address token1 = UniswapV2(msg.sender).token1();
        address pair = UniswapV2(infos[0].factory).getPair(token0,token1);
        require(pair==msg.sender,"!pair");
        require(_sender == address(this), "tu crois voler qui fripon ? ");
        //do all the other swap
        //changing path and infos
        /*uint fees_borrow = infos[0].fees_rate;
        delete path[0];
        delete infos[0];
        for (uint i = path.length-2; i>=0; i--){
            path[i] = path[i+1];
            if(infos.length-2<= i){infos[i] = infos[i-1];}
        }
        path.length--;
        infos.length--;//the problem here is that's fucking expenssive to do
        */
        //now do the trades
        IERC20(path[0]).transfer(
            UniswapV2Library.pairFor(infos[0].factory, path[0], path[1]), amountIn
        );
        _swap_fees(path, address(this),infos,1);

        require(
            IERC20(path[path.length - 1]).balanceOf(address(this)).sub(amountIn) >= amountOutMin,
            'sachaRouter: INSUFFICIENT_OUTPUT_AMOUNT'
        );

        

        //about 0.3%
        //DAIReservePre - DAIWithdrawn + (DAIReturned * .997) >= DAIReservePre
        uint amountToRepay = (amountIn/infos[0].fees_rate)*10000+1;//le + 1 est la juste si on arrondi a 
        //l'unité du dessous histoire que ça nous nique pas

        //doing other swap for exemple

        IERC20(path[path.length-1]).transfer(pair,amountToRepay);
    }
    ///i've put it here so i don't get the struct limitation
    function getAmountsOut(uint amountIn, address[] memory path, swap_info[] memory infos) internal view returns (uint[] memory amounts) {
        require(path.length >= 2, 'UniswapV2Library: INVALID_PATH');
        amounts = new uint[](path.length);
        amounts[0] = amountIn;
        for (uint i; i < path.length - 1; i++) {
            (uint reserveIn, uint reserveOut) = UniswapV2Library.getReserves(infos[i].factory, path[i], path[i + 1]);
            amounts[i + 1] = UniswapV2Library.getAmountOut(amounts[i], reserveIn, reserveOut, infos[i].fees_rate);
        }
    }
    function getAmountsOutNoFeesFirst(uint amountIn, address[] memory path, swap_info[] memory infos) internal view returns (uint[] memory amounts) {
        require(path.length >= 2, 'UniswapV2Library: INVALID_PATH');
        amounts = new uint[](path.length);
        amounts[0] = amountIn;
        for (uint i; i < 2; i++) {
            (uint reserveIn, uint reserveOut) = UniswapV2Library.getReserves(infos[i].factory, path[i], path[i + 1]);
            amounts[i + 1] = UniswapV2Library.getAmountOut(amounts[i], reserveIn, reserveOut, 10000);
        }
    }
    
    /*function pairFor(address factory, address token0, address token1) external view returns(address pair){
        pair = UniswapV2Library.pairFor(factory, token0, token1);
    }

    function get_amounts_out(address[] calldata path, swap_info[] calldata infos, uint amountIn) external view returns(uint[] memory){
        uint[] memory amountOuts = new uint[](path.length);
        uint amountOuts[0] = amountIn;
        for(uint i = 0; i<amountOuts.length-1; i++){
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
            amountOuts[i+1] = get_amount_out(amountOuts[i],reserveIn,reserveOut,infos[i].fees_rate);

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

// a library for performing overflow-safe math, courtesy of DappHub (https://github.com/dapphub/ds-math)

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

library UniswapV2Library {
    using SafeMath for uint;

    struct swap_info{
        uint fees_rate;
        address factory;
    }
    // returns sorted token addresses, used to handle return values from pairs sorted in this order
    function sortTokens(address tokenA, address tokenB) internal pure returns (address token0, address token1) {
        require(tokenA != tokenB, 'UniswapV2Library: IDENTICAL_ADDRESSES');
        (token0, token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0), 'UniswapV2Library: ZERO_ADDRESS');
    }

    // calculates the CREATE2 address for a pair without making any external calls
    function pairFor(address factory, address tokenA, address tokenB) internal pure returns (address pair) {
        (address token0, address token1) = sortTokens(tokenA, tokenB);
        pair = address(uint160(uint256(keccak256(abi.encodePacked(
                hex'ff',
                factory,
                keccak256(abi.encodePacked(token0, token1)),
                hex'96e8ac4277198ff8b6f785478aa9a39f403cb768dd02cbee326c3e7da348845f' // init code hash
            )))));
    }

    // fetches and sorts the reserves for a pair
    function getReserves(address factory, address tokenA, address tokenB) internal view returns (uint reserveA, uint reserveB) {
        (address token0,) = sortTokens(tokenA, tokenB);
        (uint reserve0, uint reserve1,) = UniswapV2(pairFor(factory, tokenA, tokenB)).getReserves();
        (reserveA, reserveB) = tokenA == token0 ? (reserve0, reserve1) : (reserve1, reserve0);
    }

    // given some amount of an asset and pair reserves, returns an equivalent amount of the other asset
    function quote(uint amountA, uint reserveA, uint reserveB) internal pure returns (uint amountB) {
        require(amountA > 0, 'UniswapV2Library: INSUFFICIENT_AMOUNT');
        require(reserveA > 0 && reserveB > 0, 'UniswapV2Library: INSUFFICIENT_LIQUIDITY');
        amountB = amountA.mul(reserveB) / reserveA;
    }

    // given an input amount of an asset and pair reserves, returns the maximum output amount of the other asset
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut,uint afterFees) internal pure returns (uint amountOut) {
        require(amountIn > 0, 'UniswapV2Library: INSUFFICIENT_INPUT_AMOUNT');
        require(reserveIn > 0 && reserveOut > 0, 'UniswapV2Library: INSUFFICIENT_LIQUIDITY');
        uint amountInWithFee = amountIn.mul(afterFees);//with fee 997
        uint numerator = amountInWithFee.mul(reserveOut);
        uint denominator = reserveIn.mul(10000).add(amountInWithFee);//without fees 1000
        //It can also be 999935 and 1000000 withtout any problem cause then we are dividing the whole 
        amountOut = numerator / denominator;//here 
    }

    // given an output amount of an asset and pair reserves, returns a required input amount of the other asset
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut,uint afterFees) internal pure returns (uint amountIn) {
        require(amountOut > 0, 'UniswapV2Library: INSUFFICIENT_OUTPUT_AMOUNT');
        require(reserveIn > 0 && reserveOut > 0, 'UniswapV2Library: INSUFFICIENT_LIQUIDITY');
        uint numerator = reserveIn.mul(amountOut).mul(10000);//1000 for uniswap(reserve in got no fees)
        uint denominator = reserveOut.sub(amountOut).mul(afterFees);//997 for uniswap (0.3%fee)
        amountIn = (numerator / denominator).add(1);
    }

    // performs chained getAmountOut calculations on any number of pairs
    

    // performs chained getAmountIn calculations on any number of pairs
    function getAmountsIn(uint amountOut, address[] memory path,swap_info[] memory infos) internal view returns (uint[] memory amounts) {
        require(path.length >= 2, 'UniswapV2Library: INVALID_PATH');
        amounts = new uint[](path.length);
        amounts[amounts.length - 1] = amountOut;
        for (uint i = path.length - 1; i > 0; i--) {
            (uint reserveIn, uint reserveOut) = getReserves(infos[i].factory, path[i - 1], path[i]);
            amounts[i - 1] = getAmountIn(amounts[i], reserveIn, reserveOut, infos[i].fees_rate);
        }
    }
}