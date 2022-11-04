/**
 *Submitted for verification at Etherscan.io on 2022-11-03
*/

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.7;
pragma abicoder v2;
interface IQuoter {
    function quoteExactOutput(bytes memory path, uint256 amountOut)
        external
        returns (uint256 amountIn);

    function quoteExactOutputSingle(
        address tokenIn,
        address tokenOut,
        uint24 fee,
        uint256 amountOut,
        uint160 sqrtPriceLimitX96
    ) external returns (uint256 amountIn);
}
 contract Swap2 {
    address public middleTokenAddr;
    address WETH = 0xB4FBF271143F4FBf7B91A5ded31805e42b2208d6;
    function getPath(address token, uint24 poolFee) internal view returns(address[] memory path, bytes memory bytepath, address[] memory sellPath , bytes memory byteSellPath ){
      
         if (middleTokenAddr == address(0)) {
            path = new address[](2);
            path[0] = WETH;
            path[1] = token;
            bytepath = abi.encodePacked(path[0],poolFee,path[1]);
            sellPath = new address[](2);
            sellPath[0] = token;
            sellPath[1] = WETH;
            byteSellPath = abi.encodePacked(sellPath[0],poolFee,sellPath[1]);
            
        } else {
            path = new address[](3);
            path[0] = WETH;
            path[1] = middleTokenAddr;
            path[2] = token;
            bytepath = abi.encodePacked(path[0], poolFee, path[1], poolFee, path[2]);
            sellPath = new address[](3);
            sellPath[0] = token;
            sellPath[1] = middleTokenAddr;
            sellPath[2] = WETH;
            byteSellPath = abi.encodePacked(sellPath[0],poolFee,sellPath[1],poolFee,sellPath[2]);
        }
        

    }
    event PathLog(address[] path, bytes bytepath);
    event WethTosend(uint256 amount);
    event ErrorLog(string err);
    function test(address token, uint256 amount) external {
       
   
        address[] memory path;
        bytes memory bytePath;
        uint24 poolFee = 3000;
        (path, bytePath,,) = getPath(token, poolFee);
        emit PathLog(path, bytePath);
        address quoterContract = 0xb27308f9F90D607463bb33eA1BeBb41C27CE5AB6;
        uint256 wethToSend = IQuoter(quoterContract).quoteExactOutput(bytePath, amount);
      
            emit WethTosend(wethToSend);
       
       
     
    }
}