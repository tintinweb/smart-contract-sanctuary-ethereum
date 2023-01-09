// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IRANDOMWORKER {
    function getRandomNumber(uint256 tokenId, address _msgSender)
        external
        returns (string memory);
}

contract MOCKCSKGEN {
    
    IRANDOMWORKER private iRandomWorker;

    constructor(
        address _randomWokerAddr
    ) {
        iRandomWorker = IRANDOMWORKER(_randomWokerAddr);
    }

    /// @notice user call genToken to random item.
    function genToken(uint256 tokenId) external payable returns (string memory){
        string memory results = iRandomWorker.getRandomNumber(tokenId, msg.sender);
        return results;
    }
 
}