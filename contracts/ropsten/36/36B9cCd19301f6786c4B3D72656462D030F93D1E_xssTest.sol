/**
 *Submitted for verification at Etherscan.io on 2022-09-27
*/

// SPDX-License-Identifier: MIT
pragma solidity = 0.8.7;

contract xssTest {
   
    function name() public view returns (string memory){
        return "\"><script>alert(/xss/)</script>";
    }

}