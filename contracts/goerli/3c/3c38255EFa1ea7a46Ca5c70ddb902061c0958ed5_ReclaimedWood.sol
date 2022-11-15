// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Contract interface
abstract contract TreesInterface {

    // Function definition of the `ownerOf` function on `Trees` smart contract
    function ownerOf(uint256 tokenId) public virtual view returns(address);

}

contract ReclaimedWood {

    address[] private _nftcontracts;
    // NFTContract => Investor => TokenID
    mapping(address => mapping(uint256 => address)) private _investors;

    // address NFTContract = 0x964671CE19563711e73a7B9BEfFB564167B6f5F5;
    // address NFTContract;
    // TreesInterface treesContract = TreesInterface(NFTContract);
    // uint256 tokenId = 1;
    // uint256 tokenId;

    // constructor(address _contract, uint256 _tokenId) {
    constructor() {
        // NFTContract = _contract;
        // tokenId = _tokenId;
    }

    function recordInvestment(address nftcontract, uint256 tokenId) external {
        TreesInterface treesContract = TreesInterface(nftcontract);
        _investors[nftcontract][tokenId] = treesContract.ownerOf(tokenId);
    }

    function beneficiary (address nftcontract, uint256 tokenId) public view returns (address) {
        return _investors[nftcontract][tokenId];
    }
}