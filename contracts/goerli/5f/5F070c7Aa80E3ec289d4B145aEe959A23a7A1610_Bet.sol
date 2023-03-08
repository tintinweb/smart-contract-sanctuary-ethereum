/**
 *Submitted for verification at Etherscan.io on 2023-03-08
*/

// SPDX-License-Identifier: MIT

pragma solidity^0.8.0;

contract Bet{
    struct BetData{
        uint256 id;
        uint256 limitTime;
        uint256 aTotalAmount;
        uint256 bTotalAmount;
        uint256 winner; //0 -> undefined, 1 -> win a, -> 2 win b
    }
    BetData[] public bets;
    // bet id -> address -> choice -> amount betted
    mapping (uint256 => mapping (address => mapping (uint256 => uint256))) public userBet;
    address owner;
    uint256 public contractBalance;

    modifier isOwner(){
        require(msg.sender == owner, "You are not the owner");
        _;
    }

    event sendPrize(address indexed _to, uint _value, uint _fees);

    constructor(){
        owner = msg.sender;
    }

    function setBet(uint256 _limitTime) public isOwner{
        bets.push(BetData(bets.length, block.timestamp + _limitTime, 0, 0, 0));
    }

    function setWinner (uint256 id, uint256 _winner) public isOwner{
        require(block.timestamp > bets[id].limitTime, "bet is not closed yet");
        //0 -> undefined, 1 -> win a, -> 2 win b
        bets[id].winner = _winner;
    }


    function bet(uint256 id, uint256 choice, uint256 amount) public payable {
        require(block.timestamp <= bets[id].limitTime, "closed bet");
        //update userBet
        userBet[bets[id].id][msg.sender][choice] += amount;
        //update BetData
        (choice == 1) ? bets[id].aTotalAmount += amount : bets[id].bTotalAmount += amount;
    }

    function claimPrize(uint256 id) public {
        //valor = cantidad apostada por el usuario al equipo ganador * total apostado en ese partido / total apostado al equipo ganador
        emit sendPrize(
            msg.sender,
            bets[id].winner == 1 ? userBet[bets[id].id][msg.sender][1] += userBet[bets[id].id][msg.sender][1] * (bets[id].aTotalAmount + bets[id].bTotalAmount) * 9 / bets[id].aTotalAmount / 10 : userBet[bets[id].id][msg.sender][2] += userBet[bets[id].id][msg.sender][2] * (bets[id].aTotalAmount + bets[id].bTotalAmount) * 9 / bets[id].bTotalAmount / 10,
            //fees
            bets[id].winner == 1 ? contractBalance += userBet[bets[id].id][msg.sender][1] * (bets[id].aTotalAmount + bets[id].bTotalAmount) / bets[id].aTotalAmount / 10 : contractBalance += userBet[bets[id].id][msg.sender][1] * (bets[id].aTotalAmount + bets[id].bTotalAmount) / bets[id].bTotalAmount / 10
        );
        userBet[bets[id].id][msg.sender][bets[id].winner] = 0;
    }

    receive() external payable{}
}