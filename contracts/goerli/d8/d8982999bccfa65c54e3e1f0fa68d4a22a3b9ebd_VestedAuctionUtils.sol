/**
 *Submitted for verification at Etherscan.io on 2022-11-03
*/

// SPDX-License-Identifier: GPL-3.0
// 20-04-2022

pragma solidity ^0.8.0;

contract VestedAuctionUtils {
    address public owner;

    uint private randNonce = 0;

    function getMax() public pure returns(uint256){
        return 2**256 - 1;
    }

    function getMax2() external pure returns(uint256){
        return  uint256(getMax() + 2);
    }
 
    constructor() {
        owner = msg.sender;
    }

    function claimPack(uint256 packId, uint256[] memory cardIds, bytes memory eligibilityKey) external pure returns(bool) {
        bytes memory validationString = abi.encodePacked(packId, "-", "msg.sender");
        for (uint256 i = 0; i < 9; i = i + 1) {
            validationString = abi.encodePacked(
                validationString,
                ",",
                cardIds[i]
            );
        }

        bytes32 messageHash = keccak256(validationString);
        
        address keyValidatorAddress = 0x20Ff11c0383C3E84D2D251Ab77eBBaD667c2964C;

        bool eligibilityKeyValid = validateSignature(
                messageHash,
                eligibilityKey,
                keyValidatorAddress
            );

        return eligibilityKeyValid;
        // require(eligibilityKeyValid, "Entered eligibility key is not valid");

        // suppliedPacksInPreMint[packId] = suppliedPacksInPreMint[packId] + count;

        // _packMint(msg.sender, packId, count);
    }
  
    function getRandomNumber(address senderAddress, uint _modulus) external returns (uint) {
        randNonce++;
        return uint(keccak256(abi.encodePacked(block.timestamp, senderAddress, randNonce))) % _modulus;
    }

    function resetRandomNonce() external {
        require(msg.sender == owner, "you can't call this function");
        require(randNonce != 0, "No need to reset nonce");
        randNonce = 0;
    }

    function getPrefixedHash(bytes32 messageHash) internal pure returns (bytes32) {
        bytes memory hashPrefix = "\x19Ethereum Signed Message:\n32";
        return keccak256(abi.encodePacked(hashPrefix, messageHash));
    }

    function splitSignature(bytes memory sig) pure internal returns (uint8 v, bytes32 r, bytes32 s) {
        require(sig.length == 65 , "invalid length");
        assembly {
            r := mload(add(sig, 32))
            s := mload(add(sig, 64))
            v := byte(0, mload(add(sig, 96)))
        }
        if (v < 27) {
            v += 27;
        }
        require(v == 27 || v == 28 , "value of v ");
        return (v, r, s);
    }
    
    function validateSignature(bytes32 messageHash, bytes memory eligibilityKey, address signerAddress) public pure returns (bool) {
        (uint8 v, bytes32 r, bytes32 s) = splitSignature(eligibilityKey);
        bytes32 msgHash = getPrefixedHash(messageHash); 
        return ecrecover(msgHash, v, r, s) == signerAddress;
    }
}