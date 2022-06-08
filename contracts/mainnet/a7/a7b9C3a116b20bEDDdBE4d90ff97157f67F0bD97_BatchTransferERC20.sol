/**
 *Submitted for verification at Etherscan.io on 2022-06-08
*/

// SPDX-License-Identifier: Apache-2.0

pragma solidity 0.6.9;
pragma experimental ABIEncoderV2;

interface IERC20 {
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external;
} 

contract BatchTransferERC20 {
    
    function batchTransfer(
        address tokenAddress,
        address[] memory tos,
        uint256[] memory amounts
    ) public {
        require(tos.length == amounts.length, "PARAM_LENGTH_INVALID");
        for (uint i = 0; i < tos.length; i++) {
            IERC20(tokenAddress).transferFrom(msg.sender,tos[i],amounts[i]);
        }
    }
}