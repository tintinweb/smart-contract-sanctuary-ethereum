// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Forwarder {
// forward the msg.value to call the function in the contract
// the function will be called with the data in the bytes array
    
    function ForwardCall(address payable _addr, bytes memory data) public payable {
        (bool success, bytes memory returnData) = _addr.call{value: msg.value}(data);
        require(success, string(returnData));

    }
}