/**
 *Submitted for verification at Etherscan.io on 2022-02-25
*/

pragma solidity ^0.8.0;
 contract hashChecker{

    function checkHashWithPrefix(address recipient, uint amount, uint256 experation) public pure  returns (bytes32) {
    bytes32 message = prefixed(keccak256(abi.encodePacked(
     recipient,
     amount,
     experation
   )));
   return (message);
 }

 function checkHashNoPrefix(address recipient, uint amount, uint256 experation) public pure returns (bytes32) {
    bytes32 message = keccak256(abi.encodePacked(
     recipient,
     amount,
     experation
   ));
   return (message);
 }
  function prefixed(bytes32 hash) internal pure returns (bytes32) {
    return keccak256(abi.encodePacked(
      '\x19Ethereum Signed Message:\n32', 
      hash
    ));
  }


//original function used in test 1
    function showRSV_Values(bytes memory sig) public pure returns (uint8, bytes32, bytes32) {
    require(sig.length == 65);
  
    bytes32 r;
    bytes32 s;
    uint8 v;
  
    assembly {
        // first 32 bytes, after the length prefix
        r := mload(add(sig, 32))
        // second 32 bytes
        s := mload(add(sig, 64))
        // final byte (first byte of the next 32 bytes)
        v := byte(0, mload(add(sig, 96)))
    }
  
    return (v, r, s);
  }

  //the open zepplin this is used in test2 
      function tryRecover(bytes memory signature) public pure returns (uint8, bytes32, bytes32) {
        // Check the signature length
        // - case 65: r,s,v signature (standard)
        // - case 64: r,vs signature (cf https://eips.ethereum.org/EIPS/eip-2098) _Available since v4.1._
        if (signature.length == 65) {
            bytes32 r;
            bytes32 s;
            uint8 v;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
            return (v, r, s);
        } else if (signature.length == 64) {
            bytes32 r;
            bytes32 vs;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            assembly {
                r := mload(add(signature, 0x20))
                vs := mload(add(signature, 0x40))
            }
            return (0,r,vs);
        } 
    }

  //three seperate functions to test three seperate ways to recover signer
    function recoverSignerRSVtest1(bytes32 message, bytes memory sig)public pure returns (address) {
    uint8 v;
    bytes32 r;
    bytes32 s;
  
    (v, r, s) = showRSV_Values(sig);
  
    return ecrecover(message, v, r, s);
  }
    function recoverSignerRSVtest2(bytes32 message, bytes memory sig)public pure returns (address) {
    uint8 v;
    bytes32 r;
    bytes32 s;
  
    (v, r, s) = tryRecover(sig);
  
    return ecrecover(message, v, r, s);
  }

  

 }