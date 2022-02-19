/**
 *Submitted for verification at Etherscan.io on 2022-02-18
*/

pragma solidity 0.6.6;

contract Voting{

int alpha;
int beta;

constructor() public {
   alpha  = 0;
    beta = 0;
}

function getTotalVotesAlpha() view public returns(int) {
    return alpha;
}

function getTotalVotesBeta() view public returns(int){
    return beta;
}

function voteAlpha () public{
    alpha = alpha+1;
}

function voteBeta () public{
    beta = beta+1;
}
}