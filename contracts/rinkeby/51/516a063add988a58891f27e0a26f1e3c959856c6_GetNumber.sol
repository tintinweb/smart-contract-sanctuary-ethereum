/**
 *Submitted for verification at Etherscan.io on 2022-07-01
*/

//SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

contract GetNumber {
    function getNumber() public pure returns (uint256){
        return 4;
    }

    function selfDestruct() external {
        selfdestruct(payable(msg.sender));
    }
}