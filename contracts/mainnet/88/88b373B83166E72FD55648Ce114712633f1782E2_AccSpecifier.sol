// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.12;

contract AccSpecifier {
    function isContract(address[] calldata _addresses) 
        external 
        view 
        returns (bool[] memory) 
    { 
        uint32 size;
        address tmpAd;
        bool[] memory contractFlags = new bool[](_addresses.length);
        for(uint i = 0; i < _addresses.length; i++) {
            tmpAd = _addresses[i];
            assembly {
                size := extcodesize(tmpAd)
            }
            contractFlags[i] = (size > 0);           
        }
        return contractFlags;
    }
}