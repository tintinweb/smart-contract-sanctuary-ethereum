//SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

contract Verify{

    // this function will compute the hash and produce & return signer address
    function verify 
      (
        address _signer, 
        bytes memory _signature,
        bytes32 signedMessageHash
      ) public pure returns (bool)
    {
         return recoverSigner(signedMessageHash, _signature) == _signer;
    }

    function recoverSigner (bytes32 _signedMessageHash, bytes memory _signature) 
        internal pure returns (address){
        bytes32 r;
        bytes32 s;
        uint8 v;
        require(_signature.length == 65, "invalid signature length"); // 65 bytes = 32 bytes for r + 32 bytes for s + 1 byte for v

            // add(x, y)        -> x + y
            // add(_sig, 32)    -> skips firt 32 bytes
            // mload(p) loads next 32 bytes starting at the memory address p

            assembly {
                r:= mload(add(_signature, 32))    //signature
                s:= mload(add(_signature, 64))    //value
                v:=byte(0, mload(add(_signature, 96)))
 

            }
        return ecrecover(_signedMessageHash, v, r, s);
    }

}