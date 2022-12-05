/**
 *Submitted for verification at Etherscan.io on 2022-12-05
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.8;

contract FortuneWheel {

    address[] private funders;
    mapping (address => bool) private playersList;
    uint256 capacity;

    constructor() {
        capacity = random();
    }

    function random() internal view returns (uint256) {
        return uint256(keccak256(abi.encodePacked(block.timestamp, msg.sender, block.number))) % (99);
    } 

    function deposit() external payable {
        uint256 depositValue = 1e16;
        require(addressPlayerDoesExist() == false, "You have already deposited 0.01 ETH. You can only once deposit.");
        require(msg.value == depositValue, "You can deposit only 0.01 ETH.");
        funders.push(msg.sender);
        playersList[msg.sender] = true;

        if (funders.length == capacity) {
            pickWinner();
        }

    }

    function addressPlayerDoesExist() private view returns (bool){
        return playersList[msg.sender];
    }


    function pickWinner() internal {
        payable (funders[funders.length-1]).transfer(address(this).balance);
        
        for (uint i = 0; i < funders.length; i++) {
            playersList[funders[i]] = false;
        }
 
        funders = new address[](0);
    }

}