/**
 *Submitted for verification at Etherscan.io on 2022-07-21
*/

pragma solidity >=0.7.0 < 0.9.0;

contract Governmental {
    address payable public owner;
    address payable public lastInvestor;
    uint public jackpot = 1 wei;
    uint public lastInvestorTimestamp;
    uint ONE_MINUTE = 1 minutes;

    constructor() payable public{ 
        owner = payable(msg.sender);
        if(msg.value < 1 wei) require(false);
    }

    function invest() payable public {
        if(msg.value < jackpot/2 ) require(false);
            lastInvestor = payable(msg.sender);
            jackpot += msg.value/2;
            lastInvestorTimestamp = block.timestamp;
    }
    
    function resetInvestment () public {
        if(block.timestamp < lastInvestorTimestamp + ONE_MINUTE) require(false);
        lastInvestor.transfer(jackpot);
        owner.transfer(address(this).balance - 1 wei);

        lastInvestor = payable(address(0));
        jackpot = 1 wei;
        lastInvestorTimestamp = 0;
    }
}