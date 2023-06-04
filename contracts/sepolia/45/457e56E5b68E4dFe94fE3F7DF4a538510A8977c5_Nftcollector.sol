/**
 *Submitted for verification at Etherscan.io on 2023-06-04
*/

// created by cryptodo.app
//   _____                      _          _____         
//  / ____|                    | |        |  __ \        
// | |      _ __  _   _  _ __  | |_  ___  | |  | |  ___  
// | |     | '__|| | | || '_ \ | __|/ _ \ | |  | | / _ \ 
// | |____ | |   | |_| || |_) || |_| (_) || |__| || (_) |
//  \_____||_|    \__, || .__/  \__|\___/ |_____/  \___/ 
//                 __/ || |                              
//                |___/ |_|      

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract Nftcollector {
    address public owner;
    uint256 public totalDistributedBNB;

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Not an owner");
        _;
    }

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    event MultisendBNBEvent(
        address indexed sender,
        address indexed recipient,
        uint256 value
    );

    receive() external payable {}

    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "New owner is the zero address");
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }

    function multisendBNB(
        address[] memory recipients,
        uint256[] memory values
    ) external payable onlyOwner {
        require(
            recipients.length == values.length,
            "Array lengths do not match"
        );
        uint256 sumValue;
        for (uint256 i = 0; i < recipients.length; i++) {
            sumValue += values[i];
            totalDistributedBNB += values[i];
        }
        require(msg.value >= sumValue, "Insufficient msg value");
        for (uint256 i = 0; i < recipients.length; i++) {
            payable(recipients[i]).transfer(values[i]);
            emit MultisendBNBEvent(msg.sender, recipients[i], values[i]);
        }
    }

    function withdraw() external onlyOwner {
        (bool success, ) = owner.call{value: address(this).balance}("");
        require(success, "Withdraw failed");
    }
}