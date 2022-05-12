/**
 *Submitted for verification at Etherscan.io on 2022-05-12
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

contract Counter {
    uint public count;

    // Function to get the current count
    function get() public view returns (uint) {
        return count;
    }

    // Function to increment count by 1
    function inc() public {
        count += 1;
    }

    // Function to decrement count by 1
    function dec() public {
        // This function will fail if count = 0
        count -= 1;
    }

    function power90() public {
        count = count ** 90;
    }

    function inc_arg(uint num) public {
        count += num;
    }
    
    function dec_arg(uint num) public {
        count -= num;
    }

    string public message = "Hello world!!!!!!";

    function AppendString(string memory msg) public returns (string memory) {
        message = string.concat(message,"\n",msg);
    }
}