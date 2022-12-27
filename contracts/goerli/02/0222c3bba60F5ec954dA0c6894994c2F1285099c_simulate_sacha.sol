/**
 *Submitted for verification at Etherscan.io on 2022-12-26
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface param{
    struct swap_info{
        address pair;
        bool token0Starting;
        uint baseFee;
        uint realFee;
    }
}

interface lowFeeRouteur is param{

    function TFL(uint amountIn, uint amountOutMin, address[] calldata path, swap_info[] calldata infos) external;

}

interface IERC20 {
    
    function balanceOf(address account) external view returns (uint256);
}

contract simulate_sacha is param{

    address payable public  owner;

    constructor() {
        owner = payable(msg.sender);
    }

    function simulate_transaction_on_router(
        uint amountIn, 
        uint amountOutMin, 
        address[] calldata path, 
        swap_info[] calldata infos, 
        address router
    ) external returns(string memory erreur, uint gains){
        require(msg.sender == owner,"Coquinou tu essaierais donc de me voler ? C'est pas tres charlie !");
        //uint previousBalanceStart = IERC20(path[0]).balanceOf(router);
        uint previousBalanceEnd = IERC20(path[path.length-1]).balanceOf(router);
        try lowFeeRouteur(router).TFL(amountIn,amountOutMin,path,infos){
            uint newBalance = IERC20(path[path.length-1]).balanceOf(router);
            if(newBalance>previousBalanceEnd+amountIn){
                gains=newBalance-previousBalanceEnd-amountIn;
                erreur = "Parfait ca regale";
            }
            else{
                gains=0;
                erreur = "La balance n'est pas en meilleur etat";
            }

        }
        catch Error(string memory reason){
            erreur = reason;
        }
        
        
        return (erreur,gains);

        
    }
}