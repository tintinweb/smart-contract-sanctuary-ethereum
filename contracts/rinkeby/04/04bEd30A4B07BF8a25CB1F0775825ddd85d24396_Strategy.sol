// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

contract  Strategy {
    // Return value for harvest, tend and balanceOfRewards
    struct TokenAmount {
        address token;
        uint256 amount;
    }

    function balanceOf() external view returns (uint256 balance){
        return 0;
    } 

    function balanceOfPool() external view returns (uint256 balance)
    {
        return 0;
    } 


    function balanceOfWant() external view returns (uint256 balance){
        return 0;
    } 

    function withdraw(uint256 amount) external {}


 
}