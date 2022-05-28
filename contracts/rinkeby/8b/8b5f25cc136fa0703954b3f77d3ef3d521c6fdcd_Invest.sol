/**
 *Submitted for verification at Etherscan.io on 2022-05-28
*/

pragma solidity ^0.4.26;

contract Invest {
    
    constructor() public payable {}

    function getRandomNumber() private view returns (uint8) {
        return uint8(uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty)))%5);
    }
    
    // Game Logic
    event randomNumberForGame(uint8);
    event investInfo(uint256);

    function invest() payable public{
        // investor should invest less than 0.1 ether every time
        require(msg.value == 0.1 ether, "fund is not 0.1 ether");          
        uint8 randomNumber = getRandomNumber() + 8;   
        emit randomNumberForGame(randomNumber);
              
        // player get 0.8~1.2 fund back
        uint256 investResult = msg.value * randomNumber / 10;

        uint256 contractBalanceBeforeTransfer = address(this).balance;

        if (contractBalanceBeforeTransfer + msg.value < investResult) {
            revert();
        } else {
            emit investInfo(investResult);
            msg.sender.transfer(investResult);
        }
    }
}