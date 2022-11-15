// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Contract interface
abstract contract TreesInterface {

    // Function definition of the `ownerOf` function on `Trees` smart contract
    function ownerOf(uint256 tokenId) public virtual view returns(address);

}

contract ReclaimedWood {

    address NFTContract;
    TreesInterface treesContract = TreesInterface(NFTContract);
    uint256 tokenId;

    constructor(address _contract, uint256 _tokenId) {
        NFTContract = _contract;
        tokenId = _tokenId;
    }

    function beneficiary () public view returns (address) {
        // Call `ownerOf` from `Trees` contract via `TreesInterface`
        address _beneficiary = treesContract.ownerOf(tokenId);
        return _beneficiary;
    }
}