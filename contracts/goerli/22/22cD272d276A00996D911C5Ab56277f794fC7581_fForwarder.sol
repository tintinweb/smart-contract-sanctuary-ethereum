/**
 *Submitted for verification at Etherscan.io on 2023-01-18
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.6;






contract fForwarder {
        receive() external payable {}

        
    function forwardCall(address payable _addr,  bytes memory data) public payable  {
        _addr.call(
 
             
                data
            );
  
    }


    function forwardCall(address payable _addr, string memory _function) public payable  {
        _addr.call(
            abi.encodeWithSignature(
                _function
            )
        );
    }

}