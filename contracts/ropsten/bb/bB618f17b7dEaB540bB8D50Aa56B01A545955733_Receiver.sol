/**
 *Submitted for verification at Etherscan.io on 2022-04-06
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.5.0 <0.9.0;

contract Receiver {
    event Received(address caller, uint amount, string message);

    fallback() external payable {
        emit Received(msg.sender, msg.value, "Fallback was called");
    }

    // 0x24ccab8f
    function foo(string memory _message, uint _x) public payable returns (uint) {
        emit Received(msg.sender, msg.value, _message);

        return _x + 1;
    }
    
    // 0xde85c19e
    function foo2(bytes4 lol) public returns (bool){
        //emit Received(msg.sender, msg.value, "ahhhhhhhhh");
        uint a = 3;
        a++;
    }
}