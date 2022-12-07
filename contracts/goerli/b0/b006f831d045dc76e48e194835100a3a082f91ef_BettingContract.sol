/**
 *Submitted for verification at Etherscan.io on 2022-12-07
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract BettingContract {
    address public admin;
    address payable public bettor1;
    address payable public bettor2;
    bool public bettor1Payed;
    bool public bettor2Payed;
    uint256 public minCoinsBet; // min 
    uint256 public creationOfContract;
    uint256 public bettingTimeLimit; // limit time to place the bets since the creation
    uint256 public bettingTimeToPay; // limit time to pay to winner of the bet

   constructor(address _bettor1, address _bettor2, uint256 _minCoinsBet, uint256 _bettingTimeLimit, uint256 _bettingTimeToPay){ // only exectured once
        require(_bettingTimeLimit < _bettingTimeToPay);
        admin = msg.sender;
        bettor1 = payable(_bettor1);
        bettor2 = payable(_bettor2);
        bettor1Payed = false;
        bettor2Payed = false;
        minCoinsBet = _minCoinsBet;
        creationOfContract = block.timestamp;
        bettingTimeLimit = _bettingTimeLimit;
        bettingTimeToPay =  _bettingTimeToPay;
    }

    modifier isAdmin() { //decorator function
        //only the owner can do this
        require(msg.sender == admin);
        _; // required for modifiers. is the logic of the modified function
    }

    modifier isBettor() {
        require(msg.sender == bettor1 || msg.sender == bettor2);
        _;
    }

    function enterBet() isBettor payable public{
        require( (msg.value > minCoinsBet) && (creationOfContract + bettingTimeLimit > block.timestamp));
        if( msg.sender == bettor1 ) {
            bettor1Payed = true;
        }
        if( msg.sender == bettor2 ) {
            bettor2Payed = true;
        }
    }

    function balance() private view returns (uint256) {
        return address(this).balance;
    }

    function payToWinner(address bettor) isAdmin public{
        require( (bettor == bettor1 || bettor == bettor2) &&  bettor1Payed && bettor2Payed);
        if(bettor == bettor1){
            bettor1.transfer(balance());
        }
        if(bettor == bettor2){
            bettor2.transfer(balance());
        }
    }

    function cancelBetBecauseNoOtherBettorOnTime() isBettor public{
        require( (creationOfContract + bettingTimeLimit < block.timestamp) && 
        ( (bettor1Payed && !bettor2Payed) || (!bettor1Payed && bettor2Payed) )
        );
        if(bettor1Payed){
            bettor1.transfer(balance());
        }
        if(bettor2Payed){
            bettor2.transfer(balance());
        }
    }

    function cancelBetBecauseAdminNotPayedToWinnerOnTime() isBettor public{
        require( (creationOfContract + bettingTimeToPay < block.timestamp) && bettor1Payed &&  bettor2Payed );
        bettor1.transfer(balance()/2);
        bettor2.transfer(balance()/2);
    }
}