/**
 *Submitted for verification at Etherscan.io on 2022-08-15
*/

pragma solidity ^0.8.7;

// SPDX-License-Identifier: MIT

contract bookie{

    struct Bet{
        address creator;
        uint256 for_amnt;
        uint256 against_amnt;
        string descHash;
        mapping(address =>uint256) for_bets;
        mapping(address =>uint256) against_bets;
        address payable[] for_list;
        address payable[] against_list;
    }

    mapping(uint8 => Bet) public ongoingBets;
    uint8  public numBets;
    address public owner;

    constructor(){
        owner  = msg.sender;
        numBets = 0;
    }

    function startBet (string memory desc) public  payable returns(uint8){
        Bet storage bet = ongoingBets[numBets];
        bet.descHash = desc;
        bet.creator = msg.sender;
        numBets++;
        return numBets-1;
    }


    function for_bet(uint8 bet_id) public payable{
        require(!(ongoingBets[bet_id].against_bets[msg.sender]>0));
        require(!(ongoingBets[bet_id].for_bets[msg.sender]>0));
        ongoingBets[bet_id].for_amnt += msg.value;
        ongoingBets[bet_id].for_bets[msg.sender] = msg.value; 
        ongoingBets[bet_id].for_list.push(payable(msg.sender));
    }

    function against_bet(uint8 bet_id) public payable{
        require(!(ongoingBets[bet_id].against_bets[msg.sender]>0));
        require(!(ongoingBets[bet_id].for_bets[msg.sender]>0));
        ongoingBets[bet_id].against_amnt += msg.value;
        ongoingBets[bet_id].against_bets[msg.sender] = msg.value; 
        ongoingBets[bet_id].against_list.push(payable(msg.sender));
    }

    function declareWinner(uint8 bet_id, bool result) public payable{
        require(msg.sender==ongoingBets[bet_id].creator);
        if(result){
            for(uint i=0; i<ongoingBets[bet_id].for_list.length; i++){
                address payable winner = ongoingBets[bet_id].for_list[i];
                winner.transfer( ongoingBets[bet_id].for_bets[winner]*(1+(ongoingBets[bet_id].against_amnt/ongoingBets[bet_id].for_amnt)));
            }
        }else{
            for(uint i=0; i<ongoingBets[bet_id].against_list.length; i++){
                address payable winner = ongoingBets[bet_id].against_list[i];
                winner.transfer( ongoingBets[bet_id].against_bets[winner]*(1+(ongoingBets[bet_id].for_amnt/ongoingBets[bet_id].against_amnt)));
            }
        }
        delete ongoingBets[bet_id];
    }
}