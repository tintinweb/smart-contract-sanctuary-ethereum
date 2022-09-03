/**
 *Submitted for verification at Etherscan.io on 2022-09-03
*/

// SPDX-License-Identifier: MIT
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
    function swap(
        uint256 amount0Out,
        uint256 amount1Out,
        address to,
        bytes calldata data
    ) external;

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function getReserves()
        external
        view
        returns (
            uint112 reserve0,
            uint112 reserve1,
            uint32 blockTimestampLast
        );
}

interface param{
    struct swap_info{
        uint fees_rate;
        address pair;
        address token0;
        address token1;
    }
}

contract honeyChecker is param{

    function testLp(swap_info calldata infos, address payable router) external returns(string memory code) {
        try sachaFlashSwapMultiDex(router).tryFlashSwap(infos) {
            
        }
        catch Error(string memory reason){
            code = reason;
        }
    }
}

contract sachaFlashSwapMultiDex is param{
     using SafeMath for uint;
    

    address payable public owner;
    address payable public simulate_contract;
    
    constructor() {
        owner = payable(msg.sender);
    }

    function setSimulateContractAddress(address payable newAddress) external{
        require(msg.sender==owner,"T as tout tente frero arrete un peu");
        simulate_contract = newAddress;
    } 

    event Log(string message, uint val);

    
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

    /*function _swap_fees(address[] memory path, address _to,swap_info[] memory infos, uint startI) internal virtual {
        for (uint i=startI; i < path.length - 1; i++) {
            //(address input, address output) = (path[i], path[i + 1]);
            UniswapV2 pair = UniswapV2(infos[i].pair);
            uint amountInput;
            uint amountOutput;
            { // scope to avoid stack too deep errors
            (uint reserve0, uint reserve1,) = pair.getReserves();
            (uint reserveInput, uint reserveOutput) = path[i] == infos[i].token0 ? (reserve0, reserve1) : (reserve1, reserve0);
            amountInput = IERC20(path[i]).balanceOf(address(pair)).sub(reserveInput);
            amountOutput = UniswapV2Library.getAmountOut(amountInput, reserveInput, reserveOutput,infos[i].fees_rate);
            }
            (uint amount0Out, uint amount1Out) = path[i] == infos[i].token0 ? (uint(0), amountOutput) : (amountOutput, uint(0));
            address to = i < infos.length-1 ? infos[i+1].pair : _to;
            pair.swap(amount0Out, amount1Out, to, new bytes(0));
        }
    }
    function swapExactTokensWithFees(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        swap_info[] calldata infos
    ) external virtual {
        require(msg.sender == owner,"Filou tu t'es cru ou");
        IERC20(path[0]).transfer(
            infos[0].pair, amountIn
        );
        uint balanceBefore = IERC20(path[path.length - 1]).balanceOf(address(this));
        _swap_fees(path, address(this),infos,0);
        require(
            IERC20(path[path.length - 1]).balanceOf(address(this)).sub(balanceBefore) >= amountOutMin,
            'UniswapV2Router: INSUFFICIENT_OUTPUT_AMOUNT'
        );
    }*/

    function tryFlashSwap(swap_info calldata infos) external{
        require(msg.sender==owner || (msg.sender == simulate_contract && simulate_contract!=address(0)),"Il serait temps d'arreter d'essayer de voler mon argent");
        
        // chemin : on emprunte token 0
        //on veux donc 1 % des reserves totales 
        (uint reserve0,,) = UniswapV2(infos.pair).getReserves();
        uint borrowed = (reserve0*5)/100;

        // on swap token 0 pour token 1 
        // on swap token 1 pour token 0

        bytes memory data = abi.encode(infos);

        UniswapV2(infos.pair).swap(borrowed,0,address(this),data);
    }
    //all the callback functions needed : //
    //uniswapV2 for testpurpose
    function uniswapV2Call(address _sender,uint amount0,uint amount1,bytes calldata _data)external {
        callBackAfterFlashLoan(_sender,amount0,amount1,_data,msg.sender);
    }
    //pancakeCall & apeswap are the same
    function pancakeCall(address _sender,uint amount0,uint amount1,bytes calldata _data)external {
        callBackAfterFlashLoan(_sender,amount0,amount1,_data,msg.sender);
    }
    //Versa 
    function versaCall(address _sender,uint amount0,uint amount1,bytes calldata _data)external {
        callBackAfterFlashLoan(_sender,amount0,amount1,_data,msg.sender);
    }
    //Fun Beast
    function beastCall(address _sender,uint amount0,uint amount1,bytes calldata _data)external {
        callBackAfterFlashLoan(_sender,amount0,amount1,_data,msg.sender);
    }

    function callBackAfterFlashLoan(
        address _sender,
        uint amount0,
        uint amount1,
        bytes calldata _data,
        address caller
    )internal {
        swap_info memory infos = abi.decode(_data,(swap_info));
        
        address pair = infos.pair;
        require(pair==caller,"!pair");
        require(_sender == address(this), "tu crois voler qui fripon ? ");
        
        

        // so swap 0 for 1 
        //begginning by sending 
        uint amountSent = IERC20(infos.token0).balanceOf(address(this));
        require(amountSent>0,"Not enought money to send in swap 1");
        IERC20(infos.token0).transfer(infos.pair, amountSent);

        (uint reserve0, uint reserve1,) = UniswapV2(infos.pair).getReserves();
        uint amountIn = IERC20(infos.token0).balanceOf(infos.pair).sub(reserve0);//on check la balance après notre envois sur la pair afin de determiner combien il est arrivé
        uint amountOut = UniswapV2Library.getAmountOut(amountIn,reserve0,reserve1,infos.fees_rate);
        UniswapV2(infos.pair).swap(0,amountOut,address(this),bytes(''));
        uint amountReceived = IERC20(infos.token1).balanceOf(address(this));//combien on reçoit de token 1 au final après toutes tax
        //calculate
        
        uint taxToken0Sent = 0;//base 100 000
        if(amountSent>amountIn){
            //ça veux dire qu'il y a eu tax donc go check cb
            taxToken0Sent = ((amountSent-amountIn)*100000)/amountSent;
        }
        uint taxToken1Recieve = 0;// base 100 000
        if(amountOut>amountReceived){
            //ça veux dire qu'il y a eu tax donc go check cb
            taxToken1Recieve = ((amountOut-amountReceived)*100000)/amountSent;
        }

        // and now swap 1 for 0 
        amountSent = IERC20(infos.token1).balanceOf(address(this));
        require(amountSent>0,"Not enought money to send in swap 2");
        IERC20(infos.token1).transfer(infos.pair, amountSent);

        (reserve0, reserve1,) = UniswapV2(infos.pair).getReserves();
        amountIn = IERC20(infos.token1).balanceOf(infos.pair).sub(reserve1);//on check la balance après notre envois sur la pair afin de determiner combien il est arrivé
        amountOut = UniswapV2Library.getAmountOut(amountIn,reserve1,reserve0,infos.fees_rate);
        UniswapV2(infos.pair).swap(amountOut,0,address(this),bytes(''));
        amountReceived = IERC20(infos.token0).balanceOf(address(this));//combien on reçoit de token 1 au final après toutes tax
        
        //calculate
        
        uint taxToken1Sent = 0;//base 100 000
        if(amountSent>amountIn){
            //ça veux dire qu'il y a eu tax donc go check cb
            taxToken1Sent = ((amountSent-amountIn)*100000)/amountSent;
        }
        uint taxToken0Recieve = 0;// base 100 000
        if(amountOut>amountReceived){
            //ça veux dire qu'il y a eu tax donc go check cb
            taxToken0Recieve = ((amountOut-amountReceived)*100000)/amountSent;
        }

        //Maintenant on envois le revert avec les infos 
        string memory motif = string(abi.encodePacked(uint2str(taxToken0Sent),uint2str(taxToken0Recieve),uint2str(taxToken1Sent),uint2str(taxToken1Recieve)));
        require(1<0,motif);
    }
    ///i've put it here so i don't get the struct limitation
    /*function getAmountsOut(uint amountIn, swap_info[] memory infos) internal view returns (uint[] memory amounts) {
        require(path.length >= 2, 'UniswapV2Library: INVALID_PATH');
        
        amounts[0] = amountIn;
        (uint reserveIn, uint reserveOut) = UniswapV2Library.getReserves(infos[i].pair, path[i], infos[i].token0);
        amounts[i + 1] = UniswapV2Library.getAmountOut(amounts[i], reserveIn, reserveOut, infos[i].fees_rate);
    }*/
    function uint2str(uint256 _i)internal pure returns (string memory str){
        if (_i == 0)
        {
            return "0";
        }
        uint256 j = _i;
        uint256 length;
        while (j != 0)
        {
            length++;
            j /= 10;
        }
        bytes memory bstr = new bytes(length);
        uint256 k = length;
        j = _i;
        while (j != 0)
        {
            bstr[--k] = bytes1(uint8(48 + j % 10));
            j /= 10;
        }
        str = string(bstr);
        }

    
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

    /*struct swap_info{
        uint fees_rate;
        address factory;
        bytes hexx;
    }*/
    /*// returns sorted token addresses, used to handle return values from pairs sorted in this order
    function sortTokens(address tokenA, address tokenB) internal pure returns (address token0, address token1) {
        require(tokenA != tokenB, 'UniswapV2Library: IDENTICAL_ADDRESSES');
        (token0, token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0), 'UniswapV2Library: ZERO_ADDRESS');
    }

    // calculates the CREATE2 address for a pair without making any external calls
    function pairFor(address factory, bytes memory hexxxx, address tokenA, address tokenB) internal pure returns (address pair) {
        (address token0, address token1) = sortTokens(tokenA, tokenB);
        pair = address(uint160(uint256(keccak256(abi.encodePacked(
                hex'ff',
                factory,
                keccak256(abi.encodePacked(token0, token1)),
                hexxxx
                 // init code hash
            )))));
    }*/

    // fetches and sorts the reserves for a pair
    function getReserves(address pair, address tokenA, address token0) internal view returns (uint reserveA, uint reserveB) {
        (uint reserve0, uint reserve1,) = UniswapV2(pair).getReserves();
        (reserveA, reserveB) = tokenA == token0 ? (reserve0, reserve1) : (reserve1, reserve0);
    }

    // given some amount of an asset and pair reserves, returns an equivalent amount of the other asset
    /*function quote(uint amountA, uint reserveA, uint reserveB) internal pure returns (uint amountB) {
        require(amountA > 0, 'UniswapV2Library: INSUFFICIENT_AMOUNT');
        require(reserveA > 0 && reserveB > 0, 'UniswapV2Library: INSUFFICIENT_LIQUIDITY');
        amountB = amountA.mul(reserveB) / reserveA;
    }*/

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
    /*function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut,uint afterFees) internal pure returns (uint amountIn) {
        require(amountOut > 0, 'UniswapV2Library: INSUFFICIENT_OUTPUT_AMOUNT');
        require(reserveIn > 0 && reserveOut > 0, 'UniswapV2Library: INSUFFICIENT_LIQUIDITY');
        uint numerator = reserveIn.mul(amountOut).mul(10000);//1000 for uniswap(reserve in got no fees)
        uint denominator = reserveOut.sub(amountOut).mul(afterFees);//997 for uniswap (0.3%fee)
        amountIn = (numerator / denominator).add(1);
    }*/

    // performs chained getAmountOut calculations on any number of pairs
    

    // performs chained getAmountIn calculations on any number of pairs
    /*function getAmountsIn(uint amountOut, address[] memory path,swap_info[] memory infos) internal view returns (uint[] memory amounts) {
        require(path.length >= 2, 'UniswapV2Library: INVALID_PATH');
        amounts = new uint[](path.length);
        amounts[amounts.length - 1] = amountOut;
        for (uint i = path.length - 1; i > 0; i--) {
            (uint reserveIn, uint reserveOut) = getReserves(infos[i].factory, infos[i].hexx, path[i - 1], path[i]);
            amounts[i - 1] = getAmountIn(amounts[i], reserveIn, reserveOut, infos[i].fees_rate);
        }
    }*/
}