// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.15;

/// @title Future Real Estate by AjmanRE
/// @notice Government of Ajman - Department of Land and Real Estate Regulation

import "./ERC721A.sol";
import "./Ownable.sol";
import "./Strings.sol";
import "./ERC2981.sol";
import "./OperatorFilterer.sol";

contract FutureRealEstateAjmanRE is ERC721A, ERC2981, OperatorFilterer, Ownable {
    using Strings for uint256;
    bool public operatorFilteringEnabled = true;

    uint256 public maxTokens = 100;
    string public baseUri;

    /// Contructor that will initialize the contract with the owner address
    constructor() ERC721A("Future Real Estate AjmanRE", "AJMANRE3") {
      _registerForOperatorFiltering(address(0), false);
      _setDefaultRoyalty(msg.sender, 500);
    }

    /// @notice Set's the BaseUri for the NFTs.
    /// @dev the BaseUri is the IPFS base that stores the metadata and images
    /// @param _newBaseUri new uri to be set as the baseUri
    function setBaseUri(string memory _newBaseUri) public onlyOwner {
        baseUri = _newBaseUri;
    }

    /// @notice updates the number of max tokens that can be minted
    /// @dev set's maxTokens to the new provided maxToken number
    /// @param _maxTokens new max token number
    function setMaxTokens(uint256 _maxTokens) public onlyOwner {
        maxTokens = _maxTokens;
    }

    // Override ERC721A baseURI
    function _baseURI() internal view virtual override returns (string memory) {
        return baseUri;
    }

    function tokenURI(uint256 _tokenId) public view virtual override returns (string memory){
        require(_exists(_tokenId), "ERC721Metadata: URI query for nonexistent token");

        return bytes(baseUri).length > 0
            ? string(abi.encodePacked(baseUri, _tokenId.toString(), ".json"))
            : "";
    }

    // Override ERC721A to start token from 1 (instead of 0)
    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    modifier mintCheck(uint256 _qty) {
        require(_qty > 0, "Must airdrop atleast 1 NFT.");
        require(_qty + _totalMinted() <=  maxTokens, "Exceeded the maximum available NFTs.");
        _;
    }

    /// @notice Air Drops a single NFT
    /// @dev Mints and transfers an NFT to a wallet
    /// @param _address The wallet for whome to mint the NFTs
    /// @param _qty The number of NFTs to be minted
    function airDrop(address _address, uint256 _qty) public onlyOwner mintCheck(_qty) {
        mint(_address, _qty);
    }

    /// @notice Air Drops NFTs to multiple wallets
    /// @dev Mints and transfers NFTs to many wallets
    /// @param _address[] The wallets to whome the NFTs will be airdropped
    function airDropMany(address[] memory _address) public onlyOwner mintCheck(_address.length) {
        for(uint i = 0; i < _address.length; i++) {
          mint(_address[i], 1);
        }
    }

    /// Function that mints the NFT
    /// @dev this is a dumb function that simply mints a number of NFTs for a given address.
    function mint(address _address, uint256 _qty) internal {
        _mint(_address, _qty);
    }

    /// Basic withdraw functionality
    /// @dev Withdraws all balance from the contract to the owner's address
    function withdraw() public payable onlyOwner {
        (bool success, ) = payable(owner()).call{value: address(this).balance}("");
        require(success);
    }
  
    // OperatorFilterer
    function setApprovalForAll(address operator, bool approved) public override onlyAllowedOperatorApproval(operator) {
      super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId) public payable override onlyAllowedOperatorApproval(operator) {
      super.approve(operator, tokenId);
    }

    function transferFrom(address from, address to, uint256 tokenId) public payable override onlyAllowedOperator(from) {
      super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
      address from,
      address to,
      uint256 tokenId
    ) public payable override onlyAllowedOperator(from) {
      super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
      address from,
      address to,
      uint256 tokenId,
      bytes memory data
    ) public payable override onlyAllowedOperator(from) {
      super.safeTransferFrom(from, to, tokenId, data);
    }

    function setOperatorFilteringEnabled(bool value) public onlyOwner {
      operatorFilteringEnabled = value;
    }

    function _operatorFilteringEnabled() internal view virtual override returns (bool) {
      return operatorFilteringEnabled;
    }

    // IERC2981
    function setRoyaltyInfo(address payable receiver, uint96 numerator) public onlyOwner {
        _setDefaultRoyalty(receiver, numerator);
    }

    // ERC165
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721A, ERC2981) returns (bool) {
        return ERC721A.supportsInterface(interfaceId) || ERC2981.supportsInterface(interfaceId);
    }
}

// This SmartContract has been created by TMT Labs
/// @author TMT Labs - https://tmtlabs.xyz - tmtlab.eth
/// @author TJ - Co-Founder of TMT Labs
// The project has been executed by FaisalFinTech