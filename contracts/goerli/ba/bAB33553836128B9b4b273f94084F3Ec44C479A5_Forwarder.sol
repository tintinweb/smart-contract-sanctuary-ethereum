// SPDX-License-Identifier: MIT
pragma solidity ^0.6.6;






contract Forwarder {
    
    function forwardCall(address payable _addr, string memory _function, bytes memory data) public {
        _addr.call(
            abi.encodeWithSignature(
                _function,
                data
            )
        );
    }


    function forwardCall(address payable _addr, string memory _function) public {
        _addr.call(
            abi.encodeWithSignature(
                _function
            )
        );
    }

}