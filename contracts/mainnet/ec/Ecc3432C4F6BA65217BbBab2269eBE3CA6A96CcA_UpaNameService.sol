// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

interface ERC721 {
    function ownerOf(uint256 tokenId) external view returns (address owner);
}

contract UpaNameService {
    event Named(uint256 upaTokenId, address indexed owner, string name);

    mapping(uint256 => string) public nameOf; // upaTokenId => Name
    ERC721 public upa;

    modifier onlyEOA() {
        require(msg.sender == tx.origin, "UPA!!");
        _;
    }

    constructor(ERC721 upa_) {
        upa = upa_;
    }

    function batchSetName(uint256[] memory upaTokenIds, string[] memory name) external onlyEOA {
        require(upaTokenIds.length == name.length, "Invalid Arguments");

        for (uint256 i = 0; i < upaTokenIds.length; i++) {
            uint256 upaTokenId = upaTokenIds[i];

            require(bytes(nameOf[upaTokenId]).length == 0, "Already Named");
            require(upa.ownerOf(upaTokenId) == msg.sender, "Invalid Owner");

            nameOf[upaTokenId] = name[i];
            emit Named(upaTokenId, msg.sender, name[i]);
        }
    }

    function nameOfBatch(uint256[] memory upaTokenIds) external view returns (string[] memory) {
        string[] memory names = new string[](upaTokenIds.length);

        for (uint256 i = 0; i < upaTokenIds.length; i++) {
            names[i] = nameOf[upaTokenIds[i]];
        }

        return names;
    }
}