/**
 *Submitted for verification at Etherscan.io on 2022-05-25
*/

library ECDSA {

    ///// Signer Address Recovery /////
    
    // In its pure form, address recovery requires the following parameters
    // params: hash, v, r ,s

    // First, we define some standard checks
    function checkValidityOf_s(bytes32 s) public pure returns (bool) {
        if (uint256(s) > 
            0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            revert("recoverAddressFrom_hash_v_r_s: Invalid s value");
        }
        return true;
    }
    function checkValidityOf_v(uint8 v) public pure returns (bool) {
        if (v != 27 && v != 28) {
            revert("recoverAddressFrom_hash_v_r_s: Invalid v value");
        }
        return true;
    }

    // Then, we first define the pure form of recovery.
    function recoverAddressFrom_hash_v_r_s(bytes32 hash, uint8 v, bytes32 r,
    bytes32 s) public pure returns (address) {
        // First, we need to make sure that s and v are in correct ranges
        require(checkValidityOf_s(s) && checkValidityOf_v(v));

        // call recovery using solidity's built-in ecrecover method
        address _signer = ecrecover(hash, v, r, s);
        
        require(_signer != address(0),
            "_signer == address(0)");

        return _signer;
    }

    // There are also other ways to receive input without v, r, s values which
    // you will need to parse the unsupported data to find v, r, s and then
    // use those to call ecrecover.

    // For these, there are 2 other methods:
    // 1. params: hash, r, vs
    // 2. params: hash, signature

    // These then return the v, r, s values required to use recoverAddressFrom_hash_v_r_s

    // So, we will parse the first method to get v, r, s
    function get_v_r_s_from_r_vs(bytes32 r, bytes32 vs) public pure 
    returns (uint8, bytes32, bytes32) {
        bytes32 s = vs & 
            bytes32(0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff);
        
        uint8 v = uint8((uint256(vs) >> 255) + 27);

        return (v, r, s);
    }

    function get_v_r_s_from_signature(bytes memory signature) public pure 
    returns (uint8, bytes32, bytes32) {
        // signature.length can be 64 and 65. this depends on the method
        // the standard is 65 bytes1, eip-2098 is 64 bytes1.
        // so, we need to account for these differences

        // in the case that it is a standard 65 bytes1 signature
        if (signature.length == 65) {
            uint8 v;
            bytes32 r;
            bytes32 s;

            // assembly magic
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }

            // return the v, r, s 
            return (v, r, s);
        }

        // in the case that it is eip-2098 64 bytes1 signature
        else if (signature.length == 64) {
            bytes32 r;
            bytes32 vs;

            // assembly magic 
            assembly {
                r := mload(add(signature, 0x20))
                vs := mload(add(signature, 0x40))
            }

            return get_v_r_s_from_r_vs(r, vs);
        }

        else {
            revert("Invalid signature length");
        }
    }

    // ///// Embedded toString /////

    // // We need this in one of the methods of returning a signed message below.

    // function _toString(uint256 value_) internal pure returns (string memory) {
    //     if (value_ == 0) { return "0"; }
    //     uint256 _iterate = value_; uint256 _digits;
    //     while (_iterate != 0) { _digits++; _iterate /= 10; } // get digits in value_
    //     bytes memory _buffer = new bytes(_digits);
    //     while (value_ != 0) { _digits--; _buffer[_digits] = bytes1(uint8(
    //         48 + uint256(value_ % 10 ))); value_ /= 10; } // create bytes of value_
    //     return string(_buffer); // return string converted bytes of value_
    // }

    // ///// Generation of Hashes /////
    
    // // We need these methods because these methods are used to compare
    // // hash generated off-chain to hash generated on-chain to cross-check the
    // // validity of the signatures

    // // 1. A bytes32 hash to generate a bytes32 hash embedded with prefix
    // // 2. A bytes memory s to generate a bytes32 hash embedded with prefix
    // // 3. A bytes32 domain seperator and bytes32 structhash to generate 
    // //      a bytes32 hash embedded with prefix

    // // See: EIP-191
    // function toEthSignedMessageHashBytes32(bytes32 hash) public pure 
    // returns (bytes32) {
    //     return keccak256(abi.encodePacked(
    //         // Magic prefix determined by the devs
    //         "\x19Ethereum Signed Message:\n32",
    //         hash
    //     ));
    // }

    // // See: EIP-191
    // function toEthSignedMessageHashBytes(bytes memory s) public pure
    // returns (bytes32) {
    //     return keccak256(abi.encodePacked(
    //         // Another magic prefix determined by the devs
    //         "\x19Ethereum Signed Message:\n", 
    //         // The bytes length of s
    //         _toString(s.length),
    //         // s itself
    //         s
    //     ));
    // }

    // // See: EIP-712
    // function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash) public
    // pure returns (bytes32) {
    //     return keccak256(abi.encodePacked(
    //         // Yet another magic prefix determined by the devs
    //         "\x19\x01",
    //         // The domain seperator (EIP-712)
    //         domainSeparator,
    //         // struct hash
    //         structHash
    //     ));
    // }
}