/// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

contract SeaportOrderHashFeature {

    bytes32 public constant SEAPORT11_DOMAIN_SEPARATOR = 0xb50c8913581289bd2e066aeef89fceb9615d490d673131fd1a7047436706834e;

    function isSeaport14Order(address maker, bytes32 hash, bytes calldata signature) external pure returns(bool) {
        if (_isValidBulkOrderSize(signature)) {
            return true;
        }

        bytes32 r;
        bytes32 s;
        uint8 v;
        if (signature.length == 64) {
            bytes32 vs;
            (r, vs) = abi.decode(signature, (bytes32, bytes32));
            s = vs & 0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff;
            v = uint8(uint256(vs >> 255)) + 27;
        } else if (signature.length == 65) {
            (r, s) = abi.decode(signature, (bytes32, bytes32));
            v = uint8(signature[64]);
        } else {
            return true;
        }

        bytes32 orderHash = keccak256(
            abi.encodePacked(uint16(0x1901), SEAPORT11_DOMAIN_SEPARATOR, hash)
        );

        address recoveredSigner = ecrecover(orderHash, v, r, s);
        return recoveredSigner != maker;
    }

    function _isValidBulkOrderSize(bytes calldata signature) internal pure returns (bool validLength) {
        return signature.length < 837 && signature.length > 98 && ((signature.length - 67) % 32) < 2;
    }
}