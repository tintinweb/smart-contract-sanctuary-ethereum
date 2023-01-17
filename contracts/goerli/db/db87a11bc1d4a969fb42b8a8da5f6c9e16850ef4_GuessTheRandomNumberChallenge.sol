/**
 *Submitted for verification at Etherscan.io on 2023-01-17
*/

pragma solidity ^0.4.21;

contract GuessTheRandomNumberChallenge {
    uint8 answer;

    function GuessTheRandomNumberChallenge() public payable {
        require(msg.value == 0.02 ether);
        answer = uint8(keccak256(block.blockhash(block.number - 1), now));
    }

    function isComplete() public view returns (bool) {
        return address(this).balance == 0;
    }

    function guess(uint8 n) public { // payable
        //require(msg.value == 1 ether);

        if (n == answer) {
            msg.sender.transfer(0.02 ether);
        }
    }

    function guess2(uint8 n) public payable {
        require(msg.value == 0.01 ether);

        if (n == answer) {
            msg.sender.transfer(0.02 ether);
        }
    }

    function withdraw() public {
        //GuessTheRandomNumberChallenge(1);  //s = 
        uint8 s = uint8(keccak256(block.blockhash(block.number - 1), now));
        guess(s);
        //guess(uint8(keccak256(block.blockhash(block.number - 1), now)));
    }



}