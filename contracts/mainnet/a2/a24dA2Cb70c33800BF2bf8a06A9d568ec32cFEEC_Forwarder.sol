// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


contract Forwarder  {
    event Forwarded(address indexed destination, uint256 value, bytes data);

    constructor() {}

    // receive eth

    receive() external payable {}
 

    function ForwardCall(address payable _addr, bytes memory data)
        public
        payable
    {
        (bool success, bytes memory returnData) = _addr.call{value: msg.value}(
            data
        );

        emit Forwarded(_addr, msg.value, data);

        require(success, string(returnData));
    }
}