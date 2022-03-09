/**
 *Submitted for verification at Etherscan.io on 2022-03-09
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;
contract TestContract{
    string testString;
      function setString(string memory new_s) public {
        testString = new_s;
    }
        function getString() public view  returns (string memory) {
        return testString;
    }
    

}