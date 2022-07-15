/**
 *Submitted for verification at Etherscan.io on 2022-07-15
*/

pragma solidity ^0.8.0;
//SPDX-License-Identifier: UNLICENSED

interface IGuessTheRandomNumberChallenge {
    function guess(uint8) external payable;
}

contract FindTheHash {
    bytes32 public previousBlockHash = 0xdb81b4d58595fbbbb592d3661a34cdca14d7ab379441400cbfa1b78bc447c365;
    uint256 public blockTimestamp = 1657877136;
    IGuessTheRandomNumberChallenge _interface;

    constructor(address _contractAddress) {
        require(_contractAddress != address(0), "you must provide a valid address");
        _interface = IGuessTheRandomNumberChallenge(_contractAddress);
    }

    function solve() public payable {
        uint8 answer = uint8(uint256(keccak256(abi.encodePacked(previousBlockHash, blockTimestamp))));
        _interface.guess{value: 1 ether}(answer);
    }

    function withdraw() public {
        payable(msg.sender).transfer(address(this).balance);
    }

    function getBalance() public view returns (uint) {
        return address(this).balance;
    }

    receive() external payable{}
}