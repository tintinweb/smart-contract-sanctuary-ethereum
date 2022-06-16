/**
 *Submitted for verification at Etherscan.io on 2022-06-16
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
contract demo
{
    uint public hello=6;
    function check() public payable {
    if(hello ==msg.value)
    {
        revert("hello");
    }
    else
    {
        revert("bye");
    }

}
}