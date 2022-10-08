// SPDX-License-Identifier: MIT
// 20-04-2022

pragma solidity ^0.8.0;

contract VestedAuctionUtils {
    address public owner;

    uint private randNonce = 0;
 
    constructor() {
        owner = msg.sender;
    }
  
    /// @param senderAddress the new value to store
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
    
    function validateEligibilityKey(address accountAddress, string memory prefix, bytes memory eligibilityKey, address validaterAddress) external pure returns (bool) {
        (uint8 v, bytes32 r, bytes32 s) = splitSignature(eligibilityKey);
        bytes32 messageHash = keccak256(abi.encodePacked(prefix, accountAddress));
        bytes32 msgHash = getPrefixedHash(messageHash); 
        return ecrecover(msgHash, v, r, s) == validaterAddress;
    }
}