/**
 *Submitted for verification at Etherscan.io on 2022-06-13
*/

pragma solidity ^0.4.24;

//     _   _   _     _      _       _   _                
//    / \ | |_| |__ | | ___| |_ ___| | | | ___ _ __ ___  
//   / _ \| __| '_ \| |/ _ \ __/ _ \ |_| |/ _ \ '__/ _ \ 
//  / ___ \ |_| | | | |  __/ ||  __/  _  |  __/ | | (_) |
// /_/   \_\__|_| |_|_|\___|\__\___|_| |_|\___|_|  \___/ 
//                                                       

contract Verification {

 function recover(bytes32 hash, bytes signature) public pure returns (address)
 {
   bytes32 r;
   bytes32 s;
   uint8 v;

   if (signature.length != 65) {
     return (address(0));
   }

   assembly {
     r := mload(add(signature, 0x20))
     s := mload(add(signature, 0x40))
     v := byte(0, mload(add(signature, 0x60)))
   }

   if (v < 27) { v += 27; }

   if (v != 27 && v != 28) {
     return (address(0));
    } else {
     return ecrecover(hash, v, r, s);
    }
  }

}