// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

// mapping: NFT tokenId => StakeInfo (used in tokenURI generation + other contracts)
// StakeInfo encoded as:
//      term (uint16)
//      | maturityTs (uint64)
//      | amount (uint128) TODO: storing here vs. separately as full uint256 ???
//      | apy (uint16)
//      | rarityScore (uint16)
//      | rarityBits (uint16):
//          [15] tokenIdIsPrime
//          [14] tokenIdIsFib
//          [14] blockIdIsPrime
//          [13] blockIdIsFib
//          [0-13] ...
library StakeInfo {
    /**
        @dev helper to convert Bool to U256 type and make compiler happy
     */
    // TODO: remove if not needed ???
    function toU256(bool x) internal pure returns (uint256 r) {
        assembly {
            r := x
        }
    }

    /**
        @dev encodes StakeInfo record from its props
     */
    function encodeStakeInfo(
        uint256 term,
        uint256 maturityTs,
        uint256 amount,
        uint256 apy,
        uint256 rarityScore,
        uint256 rarityBits
    ) public pure returns (uint256 info) {
        info = info | (rarityBits & 0xFFFF);
        info = info | ((rarityScore & 0xFFFF) << 16);
        info = info | ((apy & 0xFFFF) << 32);
        info = info | ((amount & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF) << 48);
        info = info | ((maturityTs & 0xFFFFFFFFFFFFFFFF) << 176);
        info = info | ((term & 0xFFFF) << 240);
    }

    /**
        @dev decodes StakeInfo record and extracts all of its props
     */
    function decodeStakeInfo(
        uint256 info
    )
        public
        pure
        returns (uint256 term, uint256 maturityTs, uint256 amount, uint256 apy, uint256 rarityScore, uint256 rarityBits)
    {
        term = uint16(info >> 240);
        maturityTs = uint64(info >> 176);
        amount = uint128(info >> 48);
        apy = uint16(info >> 32);
        rarityScore = uint16(info >> 16);
        rarityBits = uint16(info);
    }

    /**
        @dev extracts `term` prop from encoded StakeInfo
     */
    function getTerm(uint256 info) public pure returns (uint256 term) {
        (term, , , , , ) = decodeStakeInfo(info);
    }

    /**
        @dev extracts `maturityTs` prop from encoded StakeInfo
     */
    function getMaturityTs(uint256 info) public pure returns (uint256 maturityTs) {
        (, maturityTs, , , , ) = decodeStakeInfo(info);
    }

    /**
        @dev extracts `amount` prop from encoded StakeInfo
     */
    function getAmount(uint256 info) public pure returns (uint256 amount) {
        (, , amount, , , ) = decodeStakeInfo(info);
    }

    /**
        @dev extracts `APY` prop from encoded StakeInfo
     */
    function getAPY(uint256 info) public pure returns (uint256 apy) {
        (, , , apy, , ) = decodeStakeInfo(info);
    }

    /**
        @dev extracts `rarityScore` prop from encoded StakeInfo
     */
    function getRarityScore(uint256 info) public pure returns (uint256 rarityScore) {
        (, , , , rarityScore, ) = decodeStakeInfo(info);
    }

    /**
        @dev extracts `rarityBits` prop from encoded StakeInfo
     */
    function getRarityBits(uint256 info) public pure returns (uint256 rarityBits) {
        (, , , , , rarityBits) = decodeStakeInfo(info);
    }

    /**
        @dev decodes boolean flags from `rarityBits` prop
     */
    function decodeRarityBits(
        uint256 rarityBits
    ) public pure returns (bool isPrime, bool isFib, bool blockIsPrime, bool blockIsFib) {
        isPrime = rarityBits & 0x0008 > 0;
        isFib = rarityBits & 0x0004 > 0;
        blockIsPrime = rarityBits & 0x0002 > 0;
        blockIsFib = rarityBits & 0x0001 > 0;
    }

    /**
        @dev encodes boolean flags to `rarityBits` prop
     */
    function encodeRarityBits(
        bool isPrime,
        bool isFib,
        bool blockIsPrime,
        bool blockIsFib
    ) public pure returns (uint256 rarityBits) {
        rarityBits = rarityBits | ((toU256(isPrime) << 3) & 0xFFFF);
        rarityBits = rarityBits | ((toU256(isFib) << 2) & 0xFFFF);
        rarityBits = rarityBits | ((toU256(blockIsPrime) << 1) & 0xFFFF);
        rarityBits = rarityBits | ((toU256(blockIsFib)) & 0xFFFF);
    }

    /**
        @dev extracts `rarityBits` prop from encoded StakeInfo
     */
    function getRarityBitsDecoded(
        uint256 info
    ) public pure returns (bool isPrime, bool isFib, bool blockIsPrime, bool blockIsFib) {
        (, , , , , uint256 rarityBits) = decodeStakeInfo(info);
        (isPrime, isFib, blockIsPrime, blockIsFib) = decodeRarityBits(rarityBits);
    }
}