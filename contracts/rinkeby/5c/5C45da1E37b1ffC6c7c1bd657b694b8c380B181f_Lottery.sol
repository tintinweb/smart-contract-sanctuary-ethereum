/**
 *Submitted for verification at Etherscan.io on 2022-07-05
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

/**
 * @title Lottery
 */
contract Lottery {

    uint randNonce = 0;
    uint256 winProbability = 45;
    string resultOfLastSpin = "";

    function randNumber() internal returns(uint256) {
        randNonce++;
        return uint(keccak256(abi.encodePacked(block.timestamp, msg.sender, randNonce))) % 100;
    }

    function checkLastSpin() external view returns(string memory) {
        return resultOfLastSpin;
    }

    function donate() external payable {
        resultOfLastSpin = "thanks for donate :D";
    }

    function play() external payable {
        require(msg.value >= 0.001 ether && msg.value <= 0.01 ether);
        if (randNumber() <= winProbability) {
            resultOfLastSpin = "success";
            payable(msg.sender).transfer(msg.value * 9 / 5);
        } else {
            resultOfLastSpin = "failed";
        }
    }
}