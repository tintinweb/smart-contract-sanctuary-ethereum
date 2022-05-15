/**
 *Submitted for verification at Etherscan.io on 2022-05-14
*/

pragma solidity ^0.4.24;
contract DistributeTokens {

    constructor() public {
    }

    event investInfo(address, uint);
    event distributeInfo(uint, uint, uint);

    function invest(uint randomNumber) public payable {
        // investor should invest between 0.01 ~ 0.1 ether
        require(msg.value >= 10000000000000000 wei); 
        require(msg.value <= 100000000000000000 wei); 
        emit investInfo(msg.sender, msg.value);
        distributeToInvestorRamdomly(randomNumber);
    }

    function distributeToInvestorRamdomly(uint randomNumber) public payable { 
        // backend brign random number between 1-11
        require(randomNumber >= 1);
        require(randomNumber <= 11);

        uint investResult = msg.value*randomNumber/10;
        uint contractBalanceBeforeTransfer = address(this).balance;
        if (contractBalanceBeforeTransfer+msg.value < investResult) {
            revert();
        } else {
            msg.sender.transfer(investResult);
            uint contractBalanceAfterTransfer = address(this).balance;
            emit distributeInfo(contractBalanceBeforeTransfer, contractBalanceAfterTransfer, investResult);
        }
    }
}