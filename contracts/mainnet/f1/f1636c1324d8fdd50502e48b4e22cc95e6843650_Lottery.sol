/**
 *Submitted for verification at Etherscan.io on 2022-11-25
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

contract Lottery {
    
    address public owner;
    uint public pot;
    uint public winningsLimit = 0.01 ether; // limit to 0.1 ether so that the payout is not too big that it attract the attacker
    address payable[] public participants;

    // This is enter function
    //TODO: check if this address already participate 
    receive() external payable {
        require(msg.value == .005 ether);

        participants.push(payable(msg.sender));
        pot += msg.value;
        
        if (pot >= winningsLimit) {
            pickWinner();
        }    
    }

    function getPlayers() public view returns (address payable[] memory) {
        return participants;
    }

    function getBalance() public view returns (uint) {
        return address(this).balance;
    }
    
    //Not a real random function but the reward is small enough that this is ok
    function getRandomNumber() private view returns (uint) {
        return uint(keccak256(abi.encodePacked(msg.sender, block.timestamp)));
    }

    function pickWinner() private {
        uint index = getRandomNumber() % participants.length;
        participants[index].transfer(address(this).balance);

        // reset the state of the contract
        participants = new address payable[](0);
        pot = 0;
    }
}