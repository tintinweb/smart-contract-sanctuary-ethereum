/**
 *Submitted for verification at Etherscan.io on 2022-08-10
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

error Error2(string msg);
error Error3(bytes32 msg);

contract Test {

    function test1() external {
        revert("ERROR1");
    }

    function test2() external {
        revert Error2("ERROR2");
    }

    function test3() external {
        bytes32 result;
        assembly {
            result := mload(add("ERROR3", 32))
        }
        revert Error3(result);
    }
}