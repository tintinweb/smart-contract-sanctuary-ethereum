/**
 *Submitted for verification at Etherscan.io on 2022-10-08
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

    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);

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
        address pair;
        address token0;
        address token1;
        address router;
    }
}

contract honeyChecker is param{

    function testLp(swap_info calldata infos, address lpBorrow, address tokenBorrow, address payable router) external returns(string memory code) {
        try sachaFlashSwapMultiDex(router).tryFlashSwap(infos,lpBorrow,tokenBorrow) {
            
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

    function tryFlashSwap(swap_info calldata infos, address pairBorrow, address tokenBorrow) external{
        require(msg.sender==owner || (msg.sender == simulate_contract && simulate_contract!=address(0)),"Il serait temps d'arreter d'essayer de voler mon argent");
        
        // chemin : on emprunte token 0
        //on veux donc 5 % des reserves totales de la lp required ayant le moins d'assets
        bytes memory data = abi.encode(infos,tokenBorrow);
        (uint reserves0B,uint reserves1B,) = UniswapV2(pairBorrow).getReserves();
        (uint reserves0S,uint reserves1S,) = UniswapV2(infos.pair).getReserves();

        uint sumToBorrow = 0;
        if(UniswapV2(pairBorrow).token0()==UniswapV2(infos.pair).token0()){
            sumToBorrow = (reserves0B * 5)/100;
            if(reserves0B>reserves0S){sumToBorrow = (reserves0S*5)/100;}
        }
        else if(UniswapV2(pairBorrow).token0()==UniswapV2(infos.pair).token1()){
            sumToBorrow = (reserves0B * 5)/100;
            if(reserves0B>reserves1S){sumToBorrow = (reserves1S*5)/100;}
        }
        else if(UniswapV2(pairBorrow).token1()==UniswapV2(infos.pair).token1()){
            sumToBorrow = (reserves1B * 5)/100;
            if(reserves1B>reserves1S){sumToBorrow = (reserves1S*5)/100;}
        }
        else if(UniswapV2(pairBorrow).token1()==UniswapV2(infos.pair).token0()){
            sumToBorrow = (reserves1B * 5)/100;
            if(reserves1B>reserves0S){sumToBorrow = (reserves0S*5)/100;}
        }

        address token0 = UniswapV2(pairBorrow).token0();
        address token1 = UniswapV2(pairBorrow).token1();
        
        
        
        uint amount0 = token0 == tokenBorrow ? sumToBorrow : 0;
        uint amount1 =  tokenBorrow == token1 ? sumToBorrow/100 : 0;
        require(amount0 >0|| amount1>0,"Mon gars arrete de boire quand tu choisi les lps");
        UniswapV2(pairBorrow).swap(amount0,amount1,address(this),data);
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
        (swap_info memory infos,address tokenBorrow )= abi.decode(_data,(swap_info,address));
        
        address otherToken = tokenBorrow == UniswapV2(infos.pair).token0() ? UniswapV2(infos.pair).token1() : UniswapV2(infos.pair).token0();

        //swap borroweb
        (uint sTax0,uint rTax0, uint fLp0) = swapAndCalculate(infos.pair, tokenBorrow, infos.router);
        //swap other
        (uint sTax1,uint rTax1, uint fLp1) = swapAndCalculate(infos.pair, otherToken, infos.router);

        //Maintenant on envois le revert avec les infos 
        string memory motif = string(abi.encodePacked(uint2str(sTax0),",",uint2str(rTax0),",",uint2str(fLp0),",",uint2str(sTax1),",",uint2str(rTax1),",",uint2str(fLp1)));
        require(1<0,motif);
    }

    function swapAndCalculate(address lp, address tokenToStart, address router) internal  returns(uint taxTokenSent, uint taxTokenRecieve, uint feesOfTheLp) {
        // so swap borrow for the other
        //begginning by sending borrow
        address otherToken = tokenToStart == UniswapV2(lp).token0() ? UniswapV2(lp).token1() : UniswapV2(lp).token0();
        uint amountSent = IERC20(tokenToStart).balanceOf(address(this));
        require(amountSent>0,"Not enought money to send in swap 1");
        require(IERC20(tokenToStart).transfer(lp, amountSent)==true,"le transfer 1 marche pas");
        (uint reserve0, uint reserve1,) = UniswapV2(lp).getReserves();
        
        //la j'ai mon amount In dans la pair
        uint amountIn=0;
        //uint amountOutWithoutAnyFees = 0;
        if(tokenToStart==UniswapV2(lp).token1()) {
            amountIn = IERC20(tokenToStart).balanceOf(lp).sub(reserve1);
            //amountOutWithoutAnyFees = UniswapV2Library.getAmountOut(amountIn,reserve1,reserve0,10000);
            }
        else if (tokenToStart==UniswapV2(lp).token0()) {
            amountIn = IERC20(tokenToStart).balanceOf(lp).sub(reserve0);
            //amountOutWithoutAnyFees = UniswapV2Library.getAmountOut(amountIn,reserve0,reserve1,10000);
            }
        else {require(1<0,"le token to start n'existe pas apparement");}
        //get l'amount Out 
        uint[] memory amountOut = UniswapV2(router).getAmountsOut(amountIn,createPath(tokenToStart, otherToken));
        require(amountOut[1]>0,"L'amount out est plus petit que 0 ");
        //maintenant je doit assigner les amount 0/1 au bon endroit
        (uint amount0,uint amount1) = tokenToStart == UniswapV2(lp).token0() ? (uint(0),amountOut[1]) : (amountOut[1],uint(0));
        
        UniswapV2(lp).swap(amount0,amount1,address(this),bytes(''));


        
        uint amountReceived = IERC20(otherToken).balanceOf(address(this));//combien on reçoit de token 1 au final après toutes tax
        //calculate
        //require(1<0,"On passe le amount receiveed");
        //calculate the fees of the lp 
        feesOfTheLp = calculateLpFees(int(reserve0),int(reserve1),int(amountOut[1]),int(amountIn));
        if(tokenToStart == UniswapV2(lp).token1()){
            feesOfTheLp = calculateLpFees(int(reserve1),int(reserve0),int(amountOut[1]),int(amountIn));

        }
        
        if(amountSent>amountIn){
            //ça veux dire qu'il y a eu tax donc go check cb
            taxTokenSent = ((amountSent-amountIn)*100000)/amountSent;
        }
       
        if(amountOut[1]>amountReceived){
            //ça veux dire qu'il y a eu tax donc go check cb
            taxTokenRecieve = ((amountOut[1]-amountReceived)*100000)/amountOut[1];
        }


        

       
    }

    function calculateLpFees(int reserveIn, int reserveOut,int Aout, int Ain) internal pure returns(uint lpFees){
        int numei = Aout*reserveIn;
        int numerator = numei*-10000;
        int deo = Aout*Ain;
        int dei = reserveOut*Ain;
        int denominator = deo-dei;

        int temp = numerator/denominator+1;
        lpFees = uint(temp);
    }

    function createPath(address token0, address token1) internal  pure returns(address[] memory){
        address[] memory path = new address[](2);
        path[0] = token0;
        path[1] = token1;
        return path;
    }
    
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