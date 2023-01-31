/**
 *Submitted for verification at Etherscan.io on 2023-01-31
*/

//SPDX-License-Identifier: MIT
pragma solidity ~0.8.17;

contract StaticMetadataService {
    string private _uri;

    constructor(string memory _metaDataUri) {
        _uri = _metaDataUri;
    }

    function uri(uint256) public view returns (string memory) {
        return _uri;
    }
}