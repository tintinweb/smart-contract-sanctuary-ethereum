/**
 *Submitted for verification at Etherscan.io on 2022-05-10
*/

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

interface BENZ{
    function transferFrom(address from, address to, uint256 amount) external returns(bool);
    function transfer(address to, uint256 amount) external returns(bool);
    function balanceOf(address _account) external view returns(uint256);
}

contract BenzGame{
    address public manager;
    BENZ benz;
    uint256 public roundStart;
    uint256 public secsPerRound;
    uint256 public highestBid;
    address public highestBidder;

    constructor(address _benz, uint256 _secsPerRound){
        manager = msg.sender;
        secsPerRound = _secsPerRound;
        benz = BENZ(_benz);
    }

    function startNewRound() external{
        require(msg.sender == manager, "Forbidden, only manager call");
        require(roundStart + secsPerRound < block.timestamp, "Unfinished previous round");
        require(benz.balanceOf(address(this)) == 0, "Unclaimed Reward");

        roundStart = block.timestamp;
        highestBid = 0;
    }

    function eraseAndStartNewRound() external{
        require(msg.sender == manager, "Forbidden, only manager call");
        require(roundStart + secsPerRound < block.timestamp, "Unfinished previous round");

        roundStart = block.timestamp;
        highestBid = 0;
    }

    function setManager(address newManager) external{
        require(msg.sender == manager, "Forbidden, only manager call");
        manager = newManager;
    }
    function setRoundInterval(uint256 _time) external{
        require(msg.sender == manager, "Forbidden, only manager call");
        secsPerRound = _time;
    }

    function participate(uint amount) external{
        require(roundStart + secsPerRound >= block.timestamp, "Wait for the next round");
        benz.transferFrom(msg.sender, address(this), amount);
        if(amount > highestBid){
            highestBid = amount;
            highestBidder = msg.sender;
        }
    }


    function claimReward() external{
        require(roundStart + secsPerRound < block.timestamp, "Unfinished previous round");
        require(msg.sender == highestBidder, "Reward only for winner");
        
        benz.transfer(msg.sender, benz.balanceOf(address(this)));
    }


}