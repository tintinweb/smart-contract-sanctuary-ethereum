/**
 *Submitted for verification at Etherscan.io on 2022-08-15
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface param{
    struct swap_info{
        uint fees_rate;
        address factory;
    }
}

interface flashSwapRouter is param{

    function tryFlashSwap(uint amountIn, uint amountOutMin, address[] calldata path, swap_info[] calldata infos) external;

}

interface IERC20 {
    
    function balanceOf(address account) external view returns (uint256);
}

contract simulate_sacha is param{
    
    function simulate_transaction_on_router(
        uint amountIn, 
        uint amountOutMin, 
        address[] calldata path, 
        swap_info[] calldata infos, 
        address router
    ) external returns(bool IsProfitable){
        uint previousBalance = IERC20(path[0]).balanceOf(router);

        flashSwapRouter(router).tryFlashSwap(amountIn,amountOutMin,path,infos);

        if(IERC20(path[0]).balanceOf(router)>previousBalance){
            IsProfitable=true;
        }
        else{
            IsProfitable=false;
        }
    }
}