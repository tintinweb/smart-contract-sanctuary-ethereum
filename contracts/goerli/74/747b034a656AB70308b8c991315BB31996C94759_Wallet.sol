// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;


contract Wallet {
    address public owner;

    constructor(address _owner){
        owner = _owner;
    } 

    function isValidSignature(
        bytes32 _hash,
        bytes calldata _signature
    ) external  view returns (bytes4) {
        // Validate signatures
        if (recoverSigner(_hash, _signature) == owner) {
        return 0x1626ba7e;
        } else {
        return 0xffffffff;
        }
    }


   
    /**
    * @notice Recover the signer of hash, assuming it's an EOA account
    * @dev Only for EthSign signatures
    * @param _hash       Hash of message that was signed
    * @param _signature  Signature encoded as (bytes32 r, bytes32 s, uint8 v)
    */
    function recoverSigner(
        bytes32 _hash,
        bytes memory _signature
    ) public  pure returns (address signer) {
        require(_signature.length == 65, "SignatureValidator#recoverSigner: invalid signature length");


        (bytes32 r, bytes32 s, uint8 v) = splitSignature(_signature);
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (281): 0 < s < secp256k1n ÷ 2 + 1, and for v in (282): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        //
        // Source OpenZeppelin
        // https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/cryptography/ECDSA.sol

        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
        revert("SignatureValidator#recoverSigner: invalid signature 's' value");
        }

        if (v != 27 && v != 28) {
        revert("SignatureValidator#recoverSigner: invalid signature 'v' value");
        }

        // Recover ECDSA signer
        signer = ecrecover(
        keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", _hash)),
        v,
        r,
        s
        );
        
        // Prevent signer from being 0x0
        require(
        signer != address(0x0),
        "SignatureValidator#recoverSigner: INVALID_SIGNER"
        );

        return signer;
    }

     function splitSignature(bytes memory sig)
        private 
        pure
        returns (
            bytes32 r,
            bytes32 s,
            uint8 v
        )
    {
        require(sig.length == 65, "invalid signature length");

        assembly {
            /*
            First 32 bytes stores the length of the signature

            add(sig, 32) = pointer of sig + 32
            effectively, skips first 32 bytes of signature

            mload(p) loads next 32 bytes starting at the memory address p into memory
            */

            // first 32 bytes, after the length prefix
            r := mload(add(sig, 32))
            // second 32 bytes
            s := mload(add(sig, 64))
            // final byte (first byte of the next 32 bytes)
            v := byte(0, mload(add(sig, 96)))
        }

        // implicitly return (r, s, v)
    }
}