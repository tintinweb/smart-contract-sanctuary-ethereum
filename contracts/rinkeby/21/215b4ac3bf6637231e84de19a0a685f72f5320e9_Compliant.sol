/**
 *Submitted for verification at Etherscan.io on 2022-03-26
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Compliant {

    function _makeCompliantBio(string memory bio_) 
    public pure returns (string memory) {
        string memory _compliantBio;
        bytes memory _strBytes = bytes(bio_);
        uint256 _strLen = _strBytes.length;
        bytes1 _bottomBytes = 0x21;

        // Create Compliant Bio
        for (uint256 i = 0; i < _strLen; i++) {
            bytes1 _letterBytes1 = _strBytes[i];
            if (_letterBytes1 < _bottomBytes ||
                _letterBytes1 > 0x7A ||
                _letterBytes1 == 0x22 ) {
                // It is invalid
            } else {
                // It is valid
                _compliantBio = string(abi.encodePacked(
                    _compliantBio,
                    _letterBytes1
                ));
            }
        }

        return _compliantBio;
    }
}