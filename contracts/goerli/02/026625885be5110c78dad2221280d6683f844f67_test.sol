/**
 *Submitted for verification at Etherscan.io on 2022-12-18
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

contract test{
    
    uint256 public id;
    mapping(uint256 => string) public messages;
    event wrtitten(string, uint256, address) ;

    function write(string memory _msg) public {
        messages[id] = _msg;
        emit wrtitten(_msg, id, msg.sender);
        id++;
    }

}