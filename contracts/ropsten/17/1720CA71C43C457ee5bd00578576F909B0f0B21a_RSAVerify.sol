pragma solidity ^0.8.0;
//
// Solidity wrapper for the `rsaverify` precompiled contract.
//
// (C) 2016 Alex Beregszaszi
//
// MIT License
//

contract RSAVerify {
    // This copies call data (everything, except the method signature) to the precompiled contract.
    function rsaverify(bytes calldata S, bytes calldata e, bytes calldata  N) external returns (uint) {
        uint eoffset = 0x60+S.length;
        uint moffset = 0x60+S.length+e.length;
        uint len = 0x60+S.length+e.length+N.length;
        // uint soffset = S.offset;

        // bytes memory concatBytes = bytes.concat(S,e,N);
        // uint concatBytesLength= slen+elen+mlen;
        // assembly {
        //     len := calldatasize()
        // }

        // bytes memory req = new bytes(len - 4);
        // uint reslen = N.length;
        bytes memory res;


        uint status;

        assembly {
            let pointer := mload(0x40)
            mstore(pointer, S.length)
            mstore(add(pointer, 0x20), e.length)
            mstore(add(pointer, 0x40), N.length)
            calldatacopy(add(pointer, 0x60), S.offset, S.length)
            calldatacopy(add(pointer, eoffset), e.offset, e.length)
            calldatacopy(add(pointer, moffset), N.offset, N.length)
            pop(call(sub(gas(), 2000), 0x05, 0, pointer, len, 0, 0))
            returndatacopy(res, 0, returndatasize())
            status := res
            
        }

        return status;

        
     }
}