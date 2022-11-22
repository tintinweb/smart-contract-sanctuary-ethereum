// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title  Claim necessary tokens for testing Furion
 * @notice We will mint sender specific amount of FurionToken, MockUSD, and NFTs
 */

contract TestClaim {
    address constant BAYC = 0x5A6732E790E812Ce990454A0e81b701dcFc19918;
    address constant MAYC = 0x62D6275A4BDf7Fe9Af9745D943637Ec96F92c619;
    address constant OTHERSIDE = 0x91070bC59Be024B6A41Dc163DcCD7F2F351db80e;
    address constant BAKC = 0xDdc7dE934A83d039929D31f8b6Af8c0614fab92C;
    address constant PUNKS = 0x90bD8a7d20534a896d057a1F4eA1B574f15F16d5;
    address constant AZUKI = 0xcf42Cc957bf3A68082d34b3F9DCf96f92C5b14a3;
    address constant DOODLES = 0x12d804cB8d051C6162B67eE52eB449290e7F4eaf;
    address constant MEEBITS = 0x0061Da8C3a94FC40D7D12f3180996E7D5C2B586a;
    address constant GHOST = 0xcB9Eb2Ec8FD2cD94337Dfd6a98eA515B949341A5;
    address constant CATDDLE = 0x611acdb027e6DC31ead00C63310b24ABDa8a6e38;
    address constant SHHANS = 0x868B41A59Bb5A80d62b0153fBE53c7be2BEC798A;
    address[] nfts = [MAYC, OTHERSIDE, BAKC, PUNKS, AZUKI, DOODLES, MEEBITS, GHOST, CATDDLE, SHHANS];
    // Furion has a total supply of 1 billion
    mapping(address => bool) public claimed;

    uint256 private randNum = 192785;

    /**
     * @notice Claim testing tokens
     */
    function claimTest() external {
        // every account can only claim once
        require(!claimed[msg.sender], "Already claimed");

        bytes memory data;
        bool success;
        bytes memory returnData;

        data = abi.encodeWithSignature(
                "mint(address,uint256)",
                msg.sender,
                1
            );

        (success, returnData) = BAYC.call(data);
        require(success, string(returnData));

        uint256 random = _getRandom();
        (success, returnData) = nfts[random].call(data);
        require(success, string(returnData));        

        claimed[msg.sender] = true;
    }

    function _getRandom() private view returns (uint256) {
        return uint256(keccak256(abi.encodePacked(block.timestamp, msg.sender, randNum))) % 9;
    }
}