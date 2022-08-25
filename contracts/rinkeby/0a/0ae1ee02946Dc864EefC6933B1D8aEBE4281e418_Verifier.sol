// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
contract Verifier {
    mapping (bytes32 => bool) public usedHash;

    function recoverAddr(bytes32 msgHash, uint8 v, bytes32 r, bytes32 s) public pure returns (address) {
        return ecrecover(msgHash, v, r, s);
    }

    function isSigned(address _addr, bytes32 msgHash, uint8 v, bytes32 r, bytes32 s) public  returns (bool) {
        if(usedHash[msgHash])
        {
            return false;
        }
        else
        {
           if(ecrecover(msgHash, v, r, s) == _addr)  
           {
                usedHash[msgHash] = true;
                return true ;
           } 
           else
           {
                return false;
           }  
        }
    }
}