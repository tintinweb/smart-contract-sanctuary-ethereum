/*
SPDX-License-Identifier: GPL-3.0
*/

pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./ERC721A.sol";

contract projectP22Token is Ownable, ERC721A, ReentrancyGuard {
    string public provenance = "";

    bool public saleIsActive = false;

    uint256 public maxProjectP22 = 8888; 

    address packContractAddress;

    string private _baseTokenURI;

    // ############################# constructor #############################
    constructor() ERC721A("projectP22Token", "projectP22Token", 200, 8888) { }
    
    // ############################# function section #############################

    // ***************************** onlyOwner : Start *****************************

    function withdraw() public onlyOwner {
      (bool success, ) = msg.sender.call{value: address(this).balance}("");
      require(success, "Transfer failed.");
    }

    function setProvenanceHash(string memory provenanceHash) public onlyOwner {
        provenance = provenanceHash;
    }

    function startSale() external onlyOwner {
        require(!saleIsActive, "Public sale has already begun");
        saleIsActive = true;
    }

    function pauseSale() external onlyOwner {
        saleIsActive = false;
    }

    // ***************************** onlyOwner : End *****************************

    // ***************************** public view : Start *************************

    function tokensOfOwner(address _owner) public view returns(uint256[] memory ) {
        uint256 tokenCount = balanceOf(_owner);
        if (tokenCount == 0) {
            return new uint256[](0);
        } else {
            uint256[] memory result = new uint256[](tokenCount);
            uint256 index;
            for (index = 0; index < tokenCount; index++) {
                result[index] = tokenOfOwnerByIndex(_owner, index);
            }
            return result;
        }
    }

    function Mint(uint numberOfTokens, address toAddress, uint tokenStartIndex) external {
        uint256 currentTotalSupply = totalSupply();
        require(packContractAddress == msg.sender, "Invalid pack address");
        require(saleIsActive, "Sale must be active to mint ProjectP22");
        require(numberOfTokens < 21, "Can only mint 20 tokens at a time");
        require(currentTotalSupply + numberOfTokens < 8889, "Purchase would exceed max supply of ProjectP22s");

        _safeMint(toAddress, numberOfTokens, tokenStartIndex);
    }

    function setPackContractAddress(address _packContractAddress) external onlyOwner {
        packContractAddress = _packContractAddress;
    }

    function _baseURI() internal view virtual override returns (string memory) {
      return _baseTokenURI;
    }

    function setBaseURI(string calldata baseURI) external onlyOwner {
      _baseTokenURI = baseURI;
    }

    function setOwnersExplicit(uint256 quantity) external onlyOwner nonReentrant {
      _setOwnersExplicit(quantity);
    }

    function numberMinted(address owner) public view returns (uint256) {
      return _numberMinted(owner);
    }

    function getOwnershipData(uint256 tokenId)
      external
      view
      returns (TokenOwnership memory)
    {
      return ownershipOf(tokenId);
    }
}