/**
 *Submitted for verification at Etherscan.io on 2022-08-03
*/

//SPDX-License-Identifier: UNLICENSED
pragma solidity =0.6.6;
interface IERC20 {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);
}
interface UniswapV2{

    function token0() external view returns (address);
    function token1() external view returns (address);

    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
}

interface IUniswapV2Pair {
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
}

interface ERC20 { 
    //function transfer(address receiver, uint amount) public; 
    function balanceOf(address tokenOwner) external view returns (uint balance);
}

contract trades{
    using SafeMath for uint;
    address payable public owner;
    constructor() public {
        owner = payable(msg.sender);
    }
    // **** ADD and withdraw funds ****
    receive() external payable {
        //assert(msg.sender == WETH); // only accept ETH via fallback from the WETH contract
    }

    function withdraw(uint _amount) external {
        require(msg.sender==owner,"Petit malin tu crois que tu peux récup mon flouz ?");
        payable(msg.sender).transfer(_amount);
    }

    function transferERC20(address token, address to, uint amount) public{
        require(msg.sender==owner,"Crois pas tu peux partir avec mes ERC20 sans pression bonhomme");
        TransferHelper.safeTransfer(token,to,amount);
    }
    /*
    function _swap(uint[] memory amounts, address[] memory path, address _to, address[] memory factory) internal virtual {
        for (uint i; i < path.length - 1; i++) {
            (address input, address output) = (path[i], path[i + 1]);
            (address token0,) = UniswapV2Library.sortTokens(input, output);
            uint amountOut = amounts[i + 1];
            (uint amount0Out, uint amount1Out) = input == token0 ? (uint(0), amountOut) : (amountOut, uint(0));
            address to = i < path.length - 2 ? UniswapV2Library.pairFor(factory[i], output, path[i + 2]) : _to;
            IUniswapV2Pair(UniswapV2Library.pairFor(factory[i], input, output)).swap(
                amount0Out, amount1Out, to, new bytes(0)
            );
        }
    }

    function sETFT(//swapExactTokenForToken
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        address[] calldata factorys,
        uint[] calldata afterFees
        
    ) external virtual returns (uint[] memory amounts) {
        
        uint[] memory baseAr = new uint[](1);
        baseAr[0] = 10000;
        //try buy 
        
        //start pour go inside
        //use la balance de token 
        amounts = UniswapV2Library.getAmountsOut(factorys, amountIn, path,afterFees,baseAr);
        require(amounts[amounts.length - 1] >= amountOutMin, 'UniswapV2Router: INSUFFICIENT_OUTPUT_AMOUNT');
        TransferHelper.safeTransferFrom(
            path[0], address(this), UniswapV2Library.pairFor(factorys[0], path[0], path[1]), amountIn
        );
        _swap(amounts, path, to,factorys);
    }*/

    //I need to have 0.0000001 WBNB
    //I need to have 0.0000001 BUSD
    //I need to have 0.0000001 USDT
    //I need to have 0.0000001 USDC
    // **** SWAP (supporting fee-on-transfer tokens) ****
    // requires the initial amount to have already been sent to the first pair
    function _swapSupportingFeeOnTransferTokens(address[] memory path, address _to,address[] memory factory) internal virtual {
        for (uint i; i < path.length - 1; i++) {
            (address input, address output) = (path[i], path[i + 1]);
            (address token0,) = UniswapV2Library.sortTokens(input, output);
            IUniswapV2Pair pair = IUniswapV2Pair(UniswapV2Library.pairFor(factory[i], input, output));
            uint amountInput;
            uint amountOutput;
            { // scope to avoid stack too deep errors
            (uint reserve0, uint reserve1,) = pair.getReserves();
            (uint reserveInput, uint reserveOutput) = input == token0 ? (reserve0, reserve1) : (reserve1, reserve0);
            amountInput = IERC20(input).balanceOf(address(pair)).sub(reserveInput);
            amountOutput = UniswapV2Library.getAmountOut(amountInput, reserveInput, reserveOutput,997,1000);
            }
            (uint amount0Out, uint amount1Out) = input == token0 ? (uint(0), amountOutput) : (amountOutput, uint(0));
            address to = i < path.length - 2 ? UniswapV2Library.pairFor(factory[i], output, path[i + 2]) : _to;
            pair.swap(amount0Out, amount1Out, to, new bytes(0));
        }
    }
    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address[] calldata factorys
    ) external virtual {
        TransferHelper.safeTransferFrom(
            path[0], msg.sender, UniswapV2Library.pairFor(factorys[0], path[0], path[1]), amountIn
        );
        uint balanceBefore = IERC20(path[path.length - 1]).balanceOf(address(this));
        _swapSupportingFeeOnTransferTokens(path, address(this),factorys);
        require(
            IERC20(path[path.length - 1]).balanceOf(address(this)).sub(balanceBefore) >= amountOutMin,
            'UniswapV2Router: INSUFFICIENT_OUTPUT_AMOUNT'
        );
    }
}


contract honeyPotChecker{
    // **** ADD and withdraw funds ****
    //receive() external payable {
        //assert(msg.sender == WETH); // only accept ETH via fallback from the WETH contract
    //}
    function honeyTest(address[] calldata path,address[] calldata factory,address payable router) external virtual returns(uint,string memory){
        uint isSafe = 0;
        string memory raison = "";
            //sETFT(amountIn,0,path,address(this),factory[i]);
            isSafe = 1;
            try trades(router).swapExactTokensForTokensSupportingFeeOnTransferTokens(ERC20(path[0]).balanceOf(router),0,path,factory){
                isSafe = 2;
                //si notre balance est supérieur a 0 ça veux dire que le swap a marché et donc on tente maintenant un sell
                if(ERC20(path[1]).balanceOf(router)>0){
                    isSafe = 3;
                    try trades(router).swapExactTokensForTokensSupportingFeeOnTransferTokens(ERC20(path[1]).balanceOf(router),0,path,factory){
                        isSafe = 4;
                        if(ERC20(path[0]).balanceOf(router) > 0 ){
                            isSafe = 5;
                            //yes tout marche 

                        }
                    }
                    catch Error(string memory reason){ 
                        raison = reason;
                    }
                }

            }
            catch Error(string memory reason){
                raison = reason;
            }
        return (isSafe, raison);
    }

    
    

        
}

library TransferHelper {
    function safeApprove(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: APPROVE_FAILED');
    }

    function safeTransfer(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FAILED');
    }

    function safeTransferFrom(address token, address from, address to, uint value) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FROM_FAILED');
    }

    function safeTransferETH(address to, uint value) internal {
        (bool success,) = to.call{value:value}(new bytes(0));
        require(success, 'TransferHelper: ETH_TRANSFER_FAILED');
    }
}

library UniswapV2Library {
    using SafeMath for uint;

    // returns sorted token addresses, used to handle return values from pairs sorted in this order
    function sortTokens(address tokenA, address tokenB) internal pure returns (address token0, address token1) {
        require(tokenA != tokenB, 'UniswapV2Library: IDENTICAL_ADDRESSES');
        (token0, token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0), 'UniswapV2Library: ZERO_ADDRESS');
    }

    // calculates the CREATE2 address for a pair without making any external calls
    function pairFor(address factory, address tokenA, address tokenB) internal pure returns (address pair) {
        (address token0, address token1) = sortTokens(tokenA, tokenB);
        pair = address(uint(keccak256(abi.encodePacked(
                hex'ff',
                factory,
                keccak256(abi.encodePacked(token0, token1)),
                hex'96e8ac4277198ff8b6f785478aa9a39f403cb768dd02cbee326c3e7da348845f' // init code hash
            ))));
    }

    // fetches and sorts the reserves for a pair
    function getReserves(address factory, address tokenA, address tokenB) internal view returns (uint reserveA, uint reserveB) {
        (address token0,) = sortTokens(tokenA, tokenB);
        (uint reserve0, uint reserve1,) = IUniswapV2Pair(pairFor(factory, tokenA, tokenB)).getReserves();
        (reserveA, reserveB) = tokenA == token0 ? (reserve0, reserve1) : (reserve1, reserve0);
    }

    // given some amount of an asset and pair reserves, returns an equivalent amount of the other asset
    function quote(uint amountA, uint reserveA, uint reserveB) internal pure returns (uint amountB) {
        require(amountA > 0, 'UniswapV2Library: INSUFFICIENT_AMOUNT');
        require(reserveA > 0 && reserveB > 0, 'UniswapV2Library: INSUFFICIENT_LIQUIDITY');
        amountB = amountA.mul(reserveB) / reserveA;
    }

    // given an input amount of an asset and pair reserves, returns the maximum output amount of the other asset
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut,uint afterFees, uint base) internal pure returns (uint amountOut) {
        require(amountIn > 0, 'UniswapV2Library: INSUFFICIENT_INPUT_AMOUNT');
        require(reserveIn > 0 && reserveOut > 0, 'UniswapV2Library: INSUFFICIENT_LIQUIDITY');
        uint amountInWithFee = amountIn.mul(afterFees);//with fee 997
        uint numerator = amountInWithFee.mul(reserveOut);
        uint denominator = reserveIn.mul(base).add(amountInWithFee);//without fees 1000
        //It can also be 999935 and 1000000 withtout any problem cause then we are dividing the whole 
        amountOut = numerator / denominator;//here 
    }

    // given an output amount of an asset and pair reserves, returns a required input amount of the other asset
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut,uint afterFees, uint base) internal pure returns (uint amountIn) {
        require(amountOut > 0, 'UniswapV2Library: INSUFFICIENT_OUTPUT_AMOUNT');
        require(reserveIn > 0 && reserveOut > 0, 'UniswapV2Library: INSUFFICIENT_LIQUIDITY');
        uint numerator = reserveIn.mul(amountOut).mul(base);//1000 for uniswap(reserve in got no fees)
        uint denominator = reserveOut.sub(amountOut).mul(afterFees);//997 for uniswap (0.3%fee)
        amountIn = (numerator / denominator).add(1);
    }

    // performs chained getAmountOut calculations on any number of pairs
    function getAmountsOut(address[] memory factory, uint amountIn, address[] memory path, uint[] memory afterFees, uint[] memory base) internal view returns (uint[] memory amounts) {
        require(path.length >= 2, 'UniswapV2Library: INVALID_PATH');
        amounts = new uint[](path.length);
        amounts[0] = amountIn;
        for (uint i; i < path.length - 1; i++) {
            (uint reserveIn, uint reserveOut) = getReserves(factory[i], path[i], path[i + 1]);
            amounts[i + 1] = getAmountOut(amounts[i], reserveIn, reserveOut, afterFees[i], base[i]);
        }
    }

    // performs chained getAmountIn calculations on any number of pairs
    function getAmountsIn(address[] memory factory, uint amountOut, address[] memory path,uint[] memory afterFees, uint[] memory base) internal view returns (uint[] memory amounts) {
        require(path.length >= 2, 'UniswapV2Library: INVALID_PATH');
        amounts = new uint[](path.length);
        amounts[amounts.length - 1] = amountOut;
        for (uint i = path.length - 1; i > 0; i--) {
            (uint reserveIn, uint reserveOut) = getReserves(factory[i], path[i - 1], path[i]);
            amounts[i - 1] = getAmountIn(amounts[i], reserveIn, reserveOut, afterFees[i], base[i]);
        }
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