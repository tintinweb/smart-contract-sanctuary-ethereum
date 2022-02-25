/**
 *Submitted for verification at Etherscan.io on 2022-02-24
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.5;

contract TestContract {
     function deposistETH() external payable{

     }

     function withdrawETH(address userAddress) external{
         payable(userAddress).transfer(address(this).balance);
     }
     function checkContractBalance() external view returns(uint256){
         return (address(this).balance);
     }
}