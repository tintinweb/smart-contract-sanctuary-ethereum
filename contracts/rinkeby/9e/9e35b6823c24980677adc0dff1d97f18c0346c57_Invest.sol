/**
 *Submitted for verification at Etherscan.io on 2022-05-28
*/

pragma solidity ^0.4.26;

contract Invest {
    
    constructor() public payable {}
    
    event randomNumberForGame(uint8 randomNumber);
    event investInfo(uint256 fundBack, uint256 contractBalanceBeforeTransfer, uint256 contractBalanceAfterTransfer);

    function invest() payable public{
        // investor should invest less than 0.1 ether every time
        require(msg.value == 0.1 ether, "fund is not 0.1 ether");    

        // get random number betweeen 8 ~ 12      
        uint8 randomNumber = getRandomNumber();   
        emit randomNumberForGame(randomNumber);
              
        // player get 80% ~ 120% fund back
        uint256 fundBackAmount = getFundBackAmount(randomNumber);

        uint256 contractBalanceBeforeTransfer = address(this).balance;

        if (contractBalanceBeforeTransfer + msg.value < fundBackAmount) {
            revert();
        } else {
            msg.sender.transfer(fundBackAmount);
            uint256 contractBalanceAfterTransfer = address(this).balance;
            emit investInfo(fundBackAmount, contractBalanceBeforeTransfer, contractBalanceAfterTransfer);
        }
    }

    function getRandomNumber() private view returns (uint8) {
        uint8 originalRandomNumber = uint8(uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty)))%5);
        return originalRandomNumber + 8;
    }

    function getFundBackAmount(uint8 randomNumber) private view returns (uint256) {
        require(randomNumber <= 12, "random number more than 12");
        require(randomNumber >= 8, "random number less than 8");
        return msg.value * randomNumber / 10;
    }
}