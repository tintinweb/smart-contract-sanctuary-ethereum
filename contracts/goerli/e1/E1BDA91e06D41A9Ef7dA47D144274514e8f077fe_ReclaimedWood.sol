// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Contract interface
abstract contract TreesInterface {

    // Function definition of the `ownerOf` function on `Trees` smart contract
    function ownerOf(uint256 tokenId) public virtual view returns(address);

}

contract ReclaimedWood {

    // address NFTContract = 0x964671CE19563711e73a7B9BEfFB564167B6f5F5;
    address NFTContract;
    TreesInterface treesContract = TreesInterface(NFTContract);
    // uint256 tokenId = 1;
    uint256 tokenId;

    // constructor(address _contract, uint256 _tokenId) {
    constructor() {
        // NFTContract = _contract;
        // tokenId = _tokenId;
    }

    function setTrees(address addr) public {
        NFTContract = addr;
    }

    function setTokenId(uint256 id) public {
        tokenId = id;
    }

    function trees () public view returns (address) {
        return NFTContract;
    }

    function token () public view returns (uint256) {
        return tokenId;
    }

    function beneficiary () public view returns (address) {
        // Call `ownerOf` from `Trees` contract via `TreesInterface`
        address _beneficiary;
        _beneficiary = treesContract.ownerOf(tokenId);
        return _beneficiary;
    }
}