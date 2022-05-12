/**
 *Submitted for verification at Etherscan.io on 2022-05-12
*/

// SPDX-License-Identifier: MIT
// 20-04-2022

pragma solidity ^0.8.0;

contract VestedAuctionUtils {
    address public owner;

    uint private randNonce = 0;
 
    constructor() {
        owner = msg.sender;
    }

    function getNumOfDropPoints(uint256 maxPrice) external pure returns (uint256) {
        if (maxPrice > 1000000000000000000)
            return (32 +
                ((maxPrice - 1000000000000000000) / 250000000000000000));
        else if (maxPrice > 50000000000000000)
            return (13 + ((maxPrice - 50000000000000000) / 50000000000000000));
        else if (maxPrice > 10000000000000000)
            return (9 + ((maxPrice - 10000000000000000) / 10000000000000000));
        else if (maxPrice > 1000000000000000)
            return ((maxPrice - 1000000000000000) / 1000000000000000);
        else return 0;
    }

    function getDroppedPrice(uint256 droppedPoint) external pure returns (uint256) {
        if (droppedPoint < 1)
            // 0
            return 1000000000000000;
        else if (droppedPoint < 10)
            // 1 ~ 9
            return ((droppedPoint + 1) * 1000000000000000);
        else if (droppedPoint < 14)
            // 10 ~ 13
            return ((droppedPoint - 8) * 10000000000000000);
        else if (droppedPoint < 33)
            // 14 ~ 32
            return ((droppedPoint - 12) * 50000000000000000);
        else if (droppedPoint > 32)
            // 33 ~ ...
            return ((droppedPoint - 28) * 250000000000000000);
        return 1000000000000000;
    }
    
    function getRandomNumber(address senderAddress, uint _modulus) external returns (uint) {
        randNonce++;
        return uint(keccak256(abi.encodePacked(block.timestamp, senderAddress, randNonce))) % _modulus;
    }

    function resetNonce() external {
        require(msg.sender == owner, "you can't call this function");
        require(randNonce != 0, "No need to reset nonce");
        randNonce = 0;
    }
}