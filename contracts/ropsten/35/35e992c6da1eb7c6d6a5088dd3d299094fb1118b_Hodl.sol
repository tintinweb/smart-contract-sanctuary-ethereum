/**
 *Submitted for verification at Etherscan.io on 2022-06-24
*/

// SPDX-License-Identifier: GPL-3.0
// Complier 8.0
// BSON356107

pragma solidity >=0.7.0 <0.9.0;

contract Hodl{
    string public my_name;
    address payable public my_address;
    uint256 start;
    
    constructor(string memory name){
        my_name = name;
        my_address = payable(msg.sender);
        start = block.timestamp;
    }
    
    fallback() external payable {}
    
    receive() external payable {}
    
    function getMyBalance() public view returns (uint256) {
        return address(this).balance;
    }

    // block.timestamp >= start + 365 * 1 days
    // block.timestamp >= start + 1 * 1 minutes
    function Withdraw() external{
        if (block.timestamp >= start + 365 * 1 days) {
            selfdestruct(my_address);
        }
    }

}