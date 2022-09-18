/**
 *Submitted for verification at Etherscan.io on 2022-09-18
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

contract Test{
     struct RaffleStage {
        uint256 stageId;
        uint256 ticketsAvailable;
        uint256 ticketPrice;
    }

    RaffleStage[] stages;

    function addStage(RaffleStage[] memory _stages) public {
        for(uint i=0;i<_stages.length;i++){
            RaffleStage memory stage = _stages[i];
            stages.push(stage);
            
        }
    }

    function getStages() public view returns (RaffleStage[] memory){
        return stages;
    }
}