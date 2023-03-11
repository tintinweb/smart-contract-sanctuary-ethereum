/**
 *Submitted for verification at Etherscan.io on 2023-03-11
*/

pragma solidity ^0.8.0;

contract SignatureContract {
    bytes32 private constant m = 0x6cb4c6c0484f1e85e4d89b57db2a2f847c14d75d187af979fc7f3fc69e7159c3; // static value of m

    event SignatureCreated(bytes32 indexed messageHash, bytes32 r, bytes32 s, uint8 v);

    function signMessage() external returns (bytes32 r, uint8 v) {
        bytes32 messageHash = getMessageHash();

        (r, v) = ecdsaSign(messageHash);
        bytes32 s = getRecoveryParam(r, v, messageHash);

        emit SignatureCreated(messageHash, r, s, v);
    }

    function ecdsaSign(bytes32 messageHash) internal view returns (bytes32 r, uint8 v) {
        bytes32 hash = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", messageHash));
        (r, v) = ecdsaRawSign(hash);
        v += 27;
    }

    function ecdsaRawSign(bytes32 messageHash) internal view returns (bytes32 r, uint8 v) {
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, messageHash)
            let success := staticcall(gas(), 0x01, ptr, 32, ptr, 64)
            if eq(success, 0) {
                revert(0, 0)
            }
            r := mload(ptr)
            v := byte(0, mload(add(ptr, 32)))
        }
    }

    function getRecoveryParam(bytes32 r, uint8 v, bytes32 messageHash) internal view returns (bytes32) {
        address signer = ecrecover(messageHash, v, r, bytes32(0));
        require(signer == address(this), "Invalid signer");
        bytes32 s = bytes32(uint256(0xfffffffffffffffffffffffffffffffebaaedce6af48a03bbfd25e8cd0364141) - uint256(r));
        return s;
    }

    function getMessageHash() internal view returns (bytes32) {
        bytes32 messageHash = keccak256(abi.encodePacked(address(this), m, block.timestamp));
        return messageHash;
    }
}