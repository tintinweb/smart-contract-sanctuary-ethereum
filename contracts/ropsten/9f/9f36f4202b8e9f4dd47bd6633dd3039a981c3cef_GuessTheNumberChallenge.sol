/**
 *Submitted for verification at Etherscan.io on 2022-08-18
*/

pragma solidity >= 0.4.21;

contract GuessTheNumberChallenge {
    uint8 answer = 42;

    function isComplete() public view returns (bool) {
        return address(this).balance == 0;
    }

    function guess(uint8 n) public payable {
        require(msg.value == 1 ether);

        if (n == answer) {
            payable(msg.sender).transfer(2 ether);
        }
    }
}