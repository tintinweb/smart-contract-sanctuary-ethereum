// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

/// @title Padel Square Club Ajman
/// @notice Event NFTs for the Padel Square Club Ajman. Mint Gold or Platinum NFTs.
/// @author TMT Labs - https://tmtlabs.xyz - tmtlab.eth

import "./ERC721.sol";
import "./Ownable.sol";
import "./Strings.sol";
import "./ERC2981.sol";
import "./OperatorFilterer.sol";

contract PadelSquareEvent23 is ERC721, ERC2981, OperatorFilterer, Ownable {
    using Strings for uint256;
    bool public operatorFilteringEnabled = true;

    bool public paused = true;
    // Test Values:
    uint256 public salePricePlatinum = 11200000000000000; // 0.0112ETH
    uint256 public salePriceGold = 4500000000000000; // 0.0045ETH
    // Live Values
    // uint256 public salePricePlatinum = 1120000000000000000; // 1.12ETH ~ AED 5,000
    // uint256 public salePriceGold = 450000000000000000; // 0.45ETH ~ AED 2,000
    uint256 public maxVipNFTs = 20;
    uint256 public maxPlatinumNFTs = 14;
    uint256 public maxGoldNFTs = 100;
    uint256 public mintedVip = 0;
    uint256 public mintedPlatinum = 0;
    uint256 public mintedGold = 0;
    // Token IDs
    // VIP: 1 to 20
    // Platinum: 21 to 34
    // Gold: 35 to 134
    uint256 startVIPTokenID = 1;
    uint256 startPlatinumTokenID = 21;
    uint256 startGoldTokenID = 35;
    string public baseUri;

    constructor() ERC721("Padel Square Club Ajman Event 23", "PSCAE23") {
      _registerForOperatorFiltering(address(0), false);
      _setDefaultRoyalty(msg.sender, 0);
    }

    /// @notice Set's the BaseUri for the NFTs.
    /// @dev the BaseUri is the IPFS base that stores the metadata and images
    /// @param _baseUri the new base uri
    function setBaseUri(string memory _baseUri) public onlyOwner {
        baseUri = _baseUri;
    }

    /// @notice Toggle the state of the contract
    function togglePaused() public onlyOwner {
        paused = !paused;
    }

    /// @notice Updates the pricing for the NFTs.
    /// @dev Put 0 if the value should not be updated.
    /// @param _gold New price for the gold NFT
    /// @param _platinum New price for the platinum NFT
    function updatePrices(uint256 _gold, uint256 _platinum) public onlyOwner {
        if (_gold > 0){
          salePriceGold = _gold;
        }
        if (_platinum > 0){
          salePricePlatinum = _platinum;
        }
    }

    /// @notice Returns a token's metadata uri
    /// @dev Override existing erc721 function to include not revealed uri
    /// @param _tokenId TokenId for which the URI is to be returned
    function tokenURI(uint256 _tokenId) public view virtual override returns (string memory){
        require(_exists(_tokenId), "ERC721Metadata: URI query for nonexistent token");

        return bytes(baseUri).length > 0
            ? string(abi.encodePacked(baseUri, _tokenId.toString(), ".json"))
            : "";
    }

    /// @notice Public Mint of Platinum and Gold NFTs
    /// @dev ensured all the mint criteria has been met and then mints the NFTs
    /// @param _qtyPlatinum The number of Platinum NFTs to be minted
    /// @param _qtyGold The number of Gold NFTs to be minted
    function padelMint(uint256 _qtyPlatinum, uint256 _qtyGold) public payable {
        require(!paused, "The contract is paused.");
        require(_qtyPlatinum + _qtyGold >  0, "Must Mint at least 1 NFT.");
        require(_qtyPlatinum + mintedPlatinum <=  maxPlatinumNFTs, "Exceeded the maximum available Platinum NFTs.");
        require(_qtyGold + mintedGold <=  maxGoldNFTs, "Exceeded the maximum gold NFTs.");
        require(msg.value >= (_qtyPlatinum * salePricePlatinum) + (_qtyGold * salePriceGold), "Not enough funds to mint.");

        for(uint p = 0; p < _qtyPlatinum ; p++) {
            mintToken(msg.sender, 1);
        }
        for(uint g = 0; g < _qtyGold ; g++) {
            mintToken(msg.sender, 2);
        }
    }

    /// @notice Mint a VIP NFT for Owner
    /// @dev Allows the owner to mint NFTs for partners, promotions and giveaways
    function ownerMintVip() public onlyOwner{
        require(1 + mintedVip <=  maxVipNFTs, "Exceeded the maximum available VIP NFTs.");
        mintToken(msg.sender, 0);
    }

    /// @notice Mint a Platinum NFT for Owner
    /// @dev Allows the owner to mint NFTs for partners, promotions and giveaways
    function ownerMintPlatinum() public onlyOwner{
        require(1 + mintedPlatinum <=  maxPlatinumNFTs, "Exceeded the maximum available Platinum NFTs.");
        mintToken(msg.sender, 1);
    }

    /// @notice Mint Gold NFTs for Owner
    /// @dev Allows the owner to mint NFTs for partners, promotions and giveaways
    /// @param _qty The number of NFTs to be minted
    function ownerMintGold(uint256 _qty) public onlyOwner{
        require(_qty > 0, "Must Mint at least 1 NFT.");
        require(_qty + mintedGold <=  maxGoldNFTs, "Exceeded the maximum available Gold NFTs.");
        for(uint g = 0; g < _qty ; g++) {
            mintToken(msg.sender, 2);
        }
    }

    /// @notice Function that Air Drops NFTs
    /// @dev Mints and transfers an NFT to a wallet
    /// @param _address The wallet for whome to mint the NFTs
    /// @param _qty The number of NFTs to be minted
    function airDropVip(address _address, uint256 _qty) public onlyOwner {
        require(_qty > 0, "Must AriDrop at least 1 NFT.");
        require(_qty + mintedVip <=  maxVipNFTs, "Exceeded the maximum available VIP NFTs.");
        mintToken(_address, 0);
    }

    /// @notice Internal Minting function for all the NFT type
    /// @dev Checks which NFT to mint and mints the next one of that to the wallet
    /// @param _address The wallet for whome to mint the NFTs
    /// @param _type The type of NFT to mint. 0 = VIP, 1 = Platinum, 2 = Gold
    function mintToken(address _address, uint256 _type) internal {
      require(_type <=  2, "This token type doesn't exist");
      uint tokenId;
      if (_type == 2) {
        // Minting a Gold NFT
        tokenId = mintedGold + startGoldTokenID;
        mintedGold++;
      } else if (_type == 1) {
        // Minting a Platinum NFT
        tokenId = mintedPlatinum + startPlatinumTokenID;
        mintedPlatinum++;
      } else if (_type == 0) {
        // Minting a VIP NFT
        tokenId = mintedVip + startVIPTokenID;
        mintedVip++;
      }
      _mint(_address, tokenId);
    }

    /// @notice Withdraws contract balance
    /// @dev withdraws 90% of balance to PadelSquare and remaining to onwer(FaisalFintech)
    function withdraw() public payable onlyOwner {
      address padelSquareWallet = 0x0Ed554c3189E8309C8D1D910F9C8aE94F2C7CEE6;
        
        // Transfer 90% to PadelSquare
        (bool psc, ) = payable(padelSquareWallet).call{value: address(this).balance * 90 / 100}("");
        require(psc);
        
        // Transfers remaining balance to owner.
        (bool fft, ) = payable(owner()).call{value: address(this).balance}("");
        require(fft);
    }

    // OperatorFilterer
    function setApprovalForAll(address operator, bool approved) public override onlyAllowedOperatorApproval(operator) {
      super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId) public override onlyAllowedOperatorApproval(operator) {
      super.approve(operator, tokenId);
    }

    function transferFrom(address from, address to, uint256 tokenId) public override onlyAllowedOperator(from) {
      super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public override onlyAllowedOperator(from) {
      super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    function setOperatorFilteringEnabled(bool value) public onlyOwner {
        operatorFilteringEnabled = value;
    }

    function _operatorFilteringEnabled() internal view override returns (bool) {
        return operatorFilteringEnabled;
    }

    function setRoyaltyInfo(address payable receiver, uint96 numerator) public onlyOwner {
        _setDefaultRoyalty(receiver, numerator);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721, ERC2981) returns (bool) {
        return ERC721.supportsInterface(interfaceId) || ERC2981.supportsInterface(interfaceId);
    }
}