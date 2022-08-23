/**
 *Submitted for verification at Etherscan.io on 2022-08-23
*/

//SPDX-License-Identifier: NOLICENSE
pragma solidity 0.8.14;

interface IVaultMetaProvider {
    function getTokenURI(address vault_address, uint256 tokenId) external view returns (string memory);
    function getBaseURI() external view returns (string memory);
}

pragma solidity 0.8.14;

contract VaultMetaProvider {

    string public _tokenURI;

    constructor (string memory tokenURI) {
        _tokenURI = tokenURI;
    }

    function getTokenURI(address vault_address, uint256 tokenId) public view returns (string memory) {
        vault_address;
        tokenId;
        return _tokenURI;
    }
}