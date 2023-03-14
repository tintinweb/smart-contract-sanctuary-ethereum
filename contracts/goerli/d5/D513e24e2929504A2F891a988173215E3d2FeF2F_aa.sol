/**
 *Submitted for verification at Etherscan.io on 2023-03-14
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface Factory {
    function factory() external view returns (address);
}

//factoryaddress=0x1097053Fd2ea711dad45caCcc45EfF7548fCB362


contract aa {
address pcs=0xEfF92A263d31888d860bD50809A8D171709b7b1c;
   
    function buy(
      
        uint256 amountIn,
        uint256 amountOutMin,
        address[] memory path,
        address to,
        uint256 deadline
    ) public {
        //抢买
        (bool success, bytes memory data) = pcs.call(
            abi.encodeWithSignature(
                "swapExactTokensForTokens(uint256,uint256,address[],address,uint256)",
                amountIn,
                amountOutMin,
                path,
                to,
                deadline
            )
        );
        
    }


}