/**
 *Submitted for verification at Etherscan.io on 2022-08-24
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.14;

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

interface IERC20 {
    function totalSupply() external view returns (uint);

    function balanceOf(address account) external view returns (uint);

    function transfer(address recipient, uint amount) external returns (bool);

    function approve(address spender, uint amount) external returns (bool);

    function transferFrom(address sender, address recipient, uint amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
}

interface IUniswapV2Pair {
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
}



contract SwapTradeExecution {
    using SafeMath for uint;
    address owner;

    constructor(){
        // Set the owner to the account that deployes the contract
        owner = msg.sender;
    }

    modifier onlyOwner() {
        // Only owner can execute some functions
        require(msg.sender == owner, "Only the owner is allowed to execute");
        _;
    }

    
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut,uint fee) internal pure returns (uint amountOut) {
        uint fee_multiplier = 10000 - fee;
        uint amountInWithFee = amountIn.mul(fee_multiplier);
        uint numerator = amountInWithFee.mul(reserveOut);
        uint denominator = reserveIn.mul(10000).add(amountInWithFee);
        amountOut = numerator / denominator;
    }

    function getInputOutputReserves(address pair,address input) public view returns (uint,uint){
        (uint reserve0, uint reserve1,) = IUniswapV2Pair(pair).getReserves();
        (uint reserveInput, uint reserveOutput) = input == IUniswapV2Pair(pair).token0() ? (reserve0, reserve1) : (reserve1, reserve0);
        return (reserveInput,reserveOutput);
    }

    function getOutNumbers(address pair, address input, uint fee) public view returns (uint[] memory amounts) {
        uint amountInput;
        uint amountOutput;
        uint[] memory amountsOut;
        amountsOut = new uint[](2);
        (uint reserveInput, uint reserveOutput) = getInputOutputReserves(pair,input);
        amountInput = IERC20(input).balanceOf(address(pair)).sub(reserveInput);
        amountOutput = getAmountOut(amountInput, reserveInput, reserveOutput,fee);
        require(amountOutput<reserveOutput,'No enough reserve to swap the pair out');
        (uint amount0Out, uint amount1Out) = input == IUniswapV2Pair(pair).token0() ? (uint(0), amountOutput) : (amountOutput, uint(0));
        amountsOut[0] = amount0Out;
        amountsOut[1] = amount1Out;
        return amountsOut;
    }


    function CustomizedSwap(address pair,uint256 amountIn, address input, address _to, uint fee) external onlyOwner{
       IERC20(input).approve(pair, type(uint256).max);
       IERC20(input).transfer(pair, amountIn);
       uint[] memory amountsOut;
       amountsOut = getOutNumbers(pair,input,fee);
       IUniswapV2Pair(pair).swap(amountsOut[0], amountsOut[1], _to, new bytes(0));
    }

    function swap(address pair,uint256 amountIn, address input, address _to, uint fee) private{
       IERC20(input).approve(pair, type(uint256).max);
       IERC20(input).transfer(pair, amountIn);
       uint[] memory amountsOut;
       amountsOut = getOutNumbers(pair,input,fee);
       IUniswapV2Pair(pair).swap(amountsOut[0], amountsOut[1], _to, new bytes(0));
    }

    function DualSwap(address pair_from,address pair_to,uint256 amountIn, address input, uint fee_from,uint fee_to) external onlyOwner{
         address output;
         uint[] memory amountsOut_first;
         uint amountInTo;
         uint start_balance = IERC20(input).balanceOf(address(this));
         address token0 = IUniswapV2Pair(pair_from).token0();
         address token1 = IUniswapV2Pair(pair_from).token1();
         output = input == token0 ? token1 : token0;
         IERC20(input).approve(pair_from, type(uint256).max);
         IERC20(input).transfer(pair_from, amountIn);
         amountsOut_first = getOutNumbers(pair_from,input,fee_from);
         
         IUniswapV2Pair(pair_from).swap(amountsOut_first[0], amountsOut_first[1], pair_to, new bytes(0));
         
         amountInTo = amountsOut_first[0]<amountsOut_first[1] ? amountsOut_first[1]:amountsOut_first[0];
         IERC20(output).approve(pair_to, type(uint256).max);
         uint[] memory amountsOut_second;
         amountsOut_second = getOutNumbers(pair_to,output,fee_to);
         IUniswapV2Pair(pair_to).swap(amountsOut_second[0], amountsOut_second[1], address(this), new bytes(0));
         require(IERC20(input).balanceOf(address(this))-start_balance>0,"Zero profit trade checked out!");
    }


    function GasEstimation(address pair_from,address pair_to,uint256 amountIn, address input, uint fee_from,uint fee_to) external onlyOwner{
       address output;
         uint[] memory amountsOut_first;
         uint amountInTo;
         address token0 = IUniswapV2Pair(pair_from).token0();
         address token1 = IUniswapV2Pair(pair_from).token1();
         output = input == token0 ? token1 : token0;
         IERC20(input).approve(pair_from, type(uint256).max);
         IERC20(input).transfer(pair_from, amountIn);
         amountsOut_first = getOutNumbers(pair_from,input,fee_from);
         
         IUniswapV2Pair(pair_from).swap(amountsOut_first[0], amountsOut_first[1], pair_to, new bytes(0));
         
         amountInTo = amountsOut_first[0]<amountsOut_first[1] ? amountsOut_first[1]:amountsOut_first[0];
         IERC20(output).approve(pair_to, type(uint256).max);
         uint[] memory amountsOut_second;
         amountsOut_second = getOutNumbers(pair_to,output,fee_to);
         IUniswapV2Pair(pair_to).swap(amountsOut_second[0], amountsOut_second[1], address(this), new bytes(0));
    }



    function tokenBalance(address token) public view returns (uint256) {
        return IERC20(token).balanceOf(address(this));
    }

    function withdrawFunds(address token) external onlyOwner {
        IERC20 Token = IERC20(token);
        uint balance = Token.balanceOf(address(this));
        require(balance > 0, "No avaliable fund to withdraw");
        Token.transfer(msg.sender, balance);
    }


    function get_reserve_in_batch(address[] memory _addresses) public view returns (uint256[] memory,uint256[] memory) {
        uint256[] memory reserves_0;
        uint256[] memory reserves_1;
        reserves_0 = new uint256[](_addresses.length);
        reserves_1 = new uint256[](_addresses.length);
        for (uint i=0; i<_addresses.length; i++) {
             address pair_address = _addresses[i];
             (uint _reserve_0, uint _reserve_1,) = IUniswapV2Pair(pair_address).getReserves();
             reserves_0[i] = _reserve_0;
             reserves_1[i] = _reserve_1;
        }
        return (reserves_0,reserves_1);
    }

}