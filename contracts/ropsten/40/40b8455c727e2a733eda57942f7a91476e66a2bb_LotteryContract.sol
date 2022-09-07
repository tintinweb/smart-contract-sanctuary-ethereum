/**
 *Submitted for verification at Etherscan.io on 2022-09-07
*/

// SPDX-License-Identifier: Unlisenced

/*

 __                  __      __                                           ______                        __                                     __      __ 
|  \                |  \    |  \                                         /      \                      |  \                                   |  \    |  \
| $$       ______  _| $$_  _| $$_     ______    ______   __    __       |  $$$$$$\  ______   _______  _| $$_     ______   ______    _______  _| $$_   | $$
| $$      /      \|   $$ \|   $$ \   /      \  /      \ |  \  |  \      | $$   \$$ /      \ |       \|   $$ \   /      \ |      \  /       \|   $$ \  | $$
| $$     |  $$$$$$\\$$$$$$ \$$$$$$  |  $$$$$$\|  $$$$$$\| $$  | $$      | $$      |  $$$$$$\| $$$$$$$\\$$$$$$  |  $$$$$$\ \$$$$$$\|  $$$$$$$ \$$$$$$  | $$
| $$     | $$  | $$ | $$ __ | $$ __ | $$    $$| $$   \$$| $$  | $$      | $$   __ | $$  | $$| $$  | $$ | $$ __ | $$   \$$/      $$| $$        | $$ __  \$$
| $$_____| $$__/ $$ | $$|  \| $$|  \| $$$$$$$$| $$      | $$__/ $$      | $$__/  \| $$__/ $$| $$  | $$ | $$|  \| $$     |  $$$$$$$| $$_____   | $$|  \ __ 
| $$     \\$$    $$  \$$  $$ \$$  $$ \$$     \| $$       \$$    $$       \$$    $$ \$$    $$| $$  | $$  \$$  $$| $$      \$$    $$ \$$     \   \$$  $$|  \
 \$$$$$$$$ \$$$$$$    \$$$$   \$$$$   \$$$$$$$ \$$       _\$$$$$$$        \$$$$$$   \$$$$$$  \$$   \$$   \$$$$  \$$       \$$$$$$$  \$$$$$$$    \$$$$  \$$
                                                        |  \__| $$                                                                                        
                                                         \$$    $$       Created by: Zain Ul Abideen AKA The Dragon Emperor.                                                                                
                                                          \$$$$$$   

*/

pragma solidity 0.8.7;

contract LotteryContract {
    address payable public OwnerOfTheContract;
    address payable[] public ListOfParticipantsByIndex;

    // sets the deployer of the contract as owner.
    constructor() {
        OwnerOfTheContract = payable(msg.sender);
    }

    modifier RootAccess {
        if (msg.sender == OwnerOfTheContract) {
            _;
        }
    }

    function DepositEther() public payable {
        // lotter ticket is set to a fixed amount.
        // a single address can join multiple times to increase the probability of winning.
        require(msg.value == 1 ether);
        // since we are pushing msg.sender into a payable array, we need to make it payable as well.
        ListOfParticipantsByIndex.push(payable(msg.sender));
    }

    // generated a randomized index position for the winner of the lottery.
    function GenerateWinnerIndex() internal view returns (uint) {
        return (uint(keccak256(abi.encodePacked(block.timestamp, block.difficulty, ListOfParticipantsByIndex.length)))) % ListOfParticipantsByIndex.length;
    }
    
    // functions that require root access can only be executed by the owner of the contract.
    function PickWinnerOnlyForAdmin() RootAccess public {
        address payable Winner = ListOfParticipantsByIndex[GenerateWinnerIndex()];
        // 5% of the total amount of lottery goes to the owner, rest is transfered to the randomly selected winner.
        OwnerOfTheContract.transfer((address(this).balance)/20);
        Winner.transfer(address(this).balance);
        // resets the array for new participants.
        ListOfParticipantsByIndex = new address payable[](0);
    }
}