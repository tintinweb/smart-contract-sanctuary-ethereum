// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Forwarder {

    function forwardCall(address payable _addr, bytes memory data) public {
        (bool success, bytes memory returnData) = _addr.call(data);
        require(success, string(returnData));
    }
}