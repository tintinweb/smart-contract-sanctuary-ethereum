/**
 *Submitted for verification at Etherscan.io on 2022-04-16
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.0 <0.7.0;

contract Vault {

    address public owner;

    constructor() public {
        owner = msg.sender;
    }

    function transferOwnership(address newOwner) public {
        require(
            msg.sender == owner,
            "Only owner can call this function."
        );
        
        owner = newOwner;
    }

    function withdraw() public {
        require(
            msg.sender == owner,
            "Only owner can call this function."
        );

        require(
            block.timestamp > 1650106500,
            "Not yet."
        );

        msg.sender.transfer(address(this).balance);
    }

    receive() external payable {}
}