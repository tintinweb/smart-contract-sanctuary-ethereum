/**
 *Submitted for verification at Etherscan.io on 2022-03-21
*/

// File: btc_ec.sol

pragma solidity ^0.5.0;

library ECDSA {

    function recover(bytes32 hash, bytes memory signature) public view returns (bytes memory) {
        // Check the signature length
        if (signature.length != 65) {
            return new bytes(0x0);
        }
        // Divide the signature in r, s and v variables
        bytes32 r;
        bytes32 s;
        uint8 v;

        assembly {
            v := byte(0, mload(add(signature, 0x20)))
            r := mload(add(signature, 0x21))
            s := mload(add(signature, 0x41))
        }

        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0){
            return new bytes(0x0);
        }
        // Support both compressed or uncompressed
        if (v != 27 && v != 28 && v != 31 && v != 32) {
            return new bytes(0x0);
        }
        // If the signature is valid (and not malleable), 
        // return the signer address
        return btc_ecrecover(hash, v, r, s);
    }
    
    function btc_ecrecover(bytes32 msgh, uint8 v, bytes32 r, bytes32 s) public view returns(bytes memory) {
        uint256[4] memory input;
        input[0] = uint256(msgh);
        input[1] = v;
        input[2] = uint256(r);
        input[3] = uint256(s);
        uint256[1] memory retval;
        uint256 success;
        assembly {
            success := staticcall(not(0),0x85,input,0x80,retval, 32)
        }
        if (success != 1) {
            return new bytes(0x0);
        }
        return new bytes(retval[0]);
    }
}