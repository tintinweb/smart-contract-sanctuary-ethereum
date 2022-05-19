/**
 *Submitted for verification at Etherscan.io on 2022-05-19
*/

// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 < 0.8.0;

contract decentralizedChat{
    
    string message;

    function sendMessage( string calldata _message ) public {
        message = _message;
    }

    function readMessage() public view returns( string memory ) {
        return( message );
    }
}