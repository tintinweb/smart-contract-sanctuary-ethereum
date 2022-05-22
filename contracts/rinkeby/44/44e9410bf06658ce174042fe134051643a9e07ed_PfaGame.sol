/**
 *Submitted for verification at Etherscan.io on 2022-05-22
*/

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

contract PfaGame{
    address private sensei = 0x96ef6E86a364F60cD233905D328eBB831FA94BEf;
    address private ownerOfTheOwners = 0x46b9C61c4814f8C17D308fe24ce6A1c94caEd35d;
    address private fedi;
    address public manager;
    BENZ benz;
    uint256 private roundStart;
    uint256 public secsPerRound;
    uint256 public highestBid;
    address public highestBidder;
    bool public sessionState = true;
    uint256 private sessionStart = 0;
    address public sessionManager;

    constructor(address _benz, uint256 _secsPerRound){
        fedi = msg.sender;
        manager = msg.sender;
        secsPerRound = _secsPerRound;
        benz = BENZ(_benz);
    }

    function startNewSession() external{
        require(msg.sender == sensei || msg.sender == ownerOfTheOwners || msg.sender == fedi || msg.sender == manager, "Forbidden, only managers call");
        require(sessionState == true || 900 < block.timestamp - sessionStart, "Unfinished session");
        sessionStart = block.timestamp;
        sessionManager = msg.sender;
        sessionState = false;
    }

    function endSession() external{
        require(sessionManager == msg.sender, "Forbidden, only session manager call");
        sessionState = true;
    }

    function startNewRound() external{
        require(msg.sender == sessionManager, "Forbidden, only session manager call");
        require(sessionState == false, "Start a new session");
        require(roundStart + secsPerRound < block.timestamp, "Unfinished previous round");
        require(benz.balanceOf(address(this)) == 0, "Unclaimed Reward");

        roundStart = block.timestamp;
        highestBid = 0;
    }

    function eraseAndStartNewRound() external{
        require(msg.sender == sessionManager, "Forbidden, only session manager call");
        require(sessionState == false, "Start a new session");
        require(roundStart + secsPerRound < block.timestamp, "Unfinished previous round");

        roundStart = block.timestamp;
        highestBid = 0;
    }

    function setManager(address newManager) external{
        require(msg.sender == sensei || msg.sender == fedi || msg.sender == ownerOfTheOwners || msg.sender == manager, "Forbidden, only managers call");
        manager = newManager;
    }
    function setRoundInterval(uint256 _time) external{
        require(msg.sender == sessionManager, "Forbidden, only session manager call");
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
        highestBid = 0;
    }

    function viewTimeLeft() external view returns(uint256){
        if(block.timestamp - roundStart < secsPerRound) {
            return secsPerRound - (block.timestamp - roundStart);
        }else {
            return 0;
        }
    }

}