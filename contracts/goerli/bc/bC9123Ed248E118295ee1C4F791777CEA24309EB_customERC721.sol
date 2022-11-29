// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "./ERC_721A.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./MerkleProof.sol";
import "./ERC2981.sol";
import "./Pausable.sol";
import "./Blacklist.sol";

interface OpenSea {
    function proxies(address) external view returns (address);
}

contract customERC721 is ERC721, Ownable, ERC2981, ReentrancyGuard, Pausable, Blacklistable {
    using Strings for uint256;

    bool public revealed = false;
    string public notRevealedMetadataFolderIpfsLink;
    string public metadataFolderIpfsLink;
    string constant baseExtension = ".json";

    uint256 public constant MAX_SUPPLY = 10000;
    uint256 public constant PRE_SALE_SUPPLY = 4230;
    uint256 public MAX_PUBLIC_MINT = 5;
    uint256 public PRICE_PER_TOKEN = 0.123 * 1e18;
    uint256 public NFTS_FOR_OWNER = 555;
    uint256 public PUBLIC_MINT_ACTIVE_TIME = 1655427600;

    constructor() ERC721("Doodles", "DOODLE"){
        _setDefaultRoyalty(msg.sender, 1000); // 10.00 %
    }

    // public
    function purchaseTokens(uint256 _mintAmount) public payable nonReentrant {
        require(block.timestamp > PUBLIC_MINT_ACTIVE_TIME, "customERC721: the contract is paused");
        uint256 supply = totalSupply();
        require(_mintAmount > 0, "customERC721: need to mint at least 1 NFT");
        require(_mintAmount <= MAX_PUBLIC_MINT, "customERC721: max mint amount per session exceeded");
        require(supply + _mintAmount + NFTS_FOR_OWNER <= MAX_SUPPLY, "customERC721: max NFT limit exceeded");
        require(msg.value >= PRICE_PER_TOKEN * _mintAmount, "customERC721: insufficient funds");

        _safeMint(msg.sender, _mintAmount);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721, ERC2981) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function _startTokenId() internal pure override returns (uint256) {
        return 1;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return metadataFolderIpfsLink;
    }

    function tokenURI(uint256 tokenId) public view virtual override(ERC721) returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        if (revealed == false) return notRevealedMetadataFolderIpfsLink;

        string memory currentBaseURI = _baseURI();
        return bytes(currentBaseURI).length > 0 ? string(abi.encodePacked(currentBaseURI, tokenId.toString(), baseExtension)) : "";
    }

    function withdraw() public payable onlyOwner nonReentrant {
        (bool success, ) = payable(msg.sender).call{value: address(this).balance}("");
        require(success);
    }

    function giftNft(address[] calldata _sendNftsTo, uint256 _howMany) external onlyOwner {
        NFTS_FOR_OWNER -= _sendNftsTo.length * _howMany;

        for (uint256 i = 0; i < _sendNftsTo.length; i++) _safeMint(_sendNftsTo[i], _howMany);
    }

    function setnftsForOwner(uint256 _newnftsForOwner) public onlyOwner {
        NFTS_FOR_OWNER = _newnftsForOwner;
    }

    function setDefaultRoyalty(address _receiver, uint96 _feeNumerator) public onlyOwner {
        _setDefaultRoyalty(_receiver, _feeNumerator);
    }

    function revealFlip() public onlyOwner {
        revealed = !revealed;
    }

    function setCostPerNft(uint256 _newCostPerNft) public onlyOwner {
        PRICE_PER_TOKEN = _newCostPerNft;
    }

    function setMaxMintAmount(uint256 _newmaxMintAmount) public onlyOwner {
        MAX_PUBLIC_MINT = _newmaxMintAmount;
    }

    function setMetadataFolderIpfsLink(string memory _newMetadataFolderIpfsLink) public onlyOwner {
        metadataFolderIpfsLink = _newMetadataFolderIpfsLink;
    }

    function setNotRevealedMetadataFolderIpfsLink(string memory _notRevealedMetadataFolderIpfsLink) public onlyOwner {
        notRevealedMetadataFolderIpfsLink = _notRevealedMetadataFolderIpfsLink;
    }

    function setSaleActiveTime(uint256 _publicmintActiveTime) public onlyOwner {
        PUBLIC_MINT_ACTIVE_TIME = _publicmintActiveTime;
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function pause() public onlyOwner {
        _pause();
    }

    function giveAway(address winner, uint256 _tokenIdToGiveaway) public onlyOwner {
      safeTransferFrom(msg.sender, winner, _tokenIdToGiveaway);
    }

    function _beforeTokenTransfer(address from, address to, uint256 firstTokenId) internal whenNotPaused override {
        require(!isBlackListed(to), "Token transfer refused. Receiver is on blacklist");
        super._beforeTokenTransfer(from, to, firstTokenId);
    }
}

contract NftWhitelistSaleMerkle is customERC721 {
    ///////////////////////////////
    //    PRESALE CODE STARTS    //
    ///////////////////////////////

    bytes32 public whitelistMerkleRoot;
    uint256 public PRESALE_MINT_ACTIVE_TIME = 1655341200;
    uint256 public MAX_PRESALE_MINT = 3;
    uint256 public ITEM_PRICE_PRESALE = 0.19 * 1e18;

    mapping(address => uint256) public presaleClaimedBy;

    function setWhitelist(bytes32 _whitelistMerkleRoot) external onlyOwner {
        whitelistMerkleRoot = _whitelistMerkleRoot;
    }

    function inWhitelist(bytes32[] memory _proof, address _owner) public view returns (bool) {
        return MerkleProof.verify(_proof, whitelistMerkleRoot, keccak256(abi.encodePacked(_owner)));
    }

    function purchaseTokensPresale(uint256 _howMany, bytes32[] calldata _proof) external payable nonReentrant {
        uint256 supply = totalSupply();
        require(supply + _howMany + NFTS_FOR_OWNER <= MAX_SUPPLY, "customERC721: max NFT limit exceeded");

        require(inWhitelist(_proof, msg.sender), "You are not in presale");
        require(block.timestamp > PRESALE_MINT_ACTIVE_TIME, "Presale is not active");
        require(msg.value >= _howMany * ITEM_PRICE_PRESALE, "Try to send more ETH");

        presaleClaimedBy[msg.sender] += _howMany;

        require(presaleClaimedBy[msg.sender] <= MAX_PRESALE_MINT, "Purchase exceeds max allowed");

        _safeMint(msg.sender, _howMany);
    }

    // set limit of presale
    function setPresaleMaxMint(uint256 _presaleMaxMint) external onlyOwner {
        MAX_PRESALE_MINT = _presaleMaxMint;
    }

    // Change presale price in case of ETH price changes too much
    function setPricePresale(uint256 _itemPricePresale) external onlyOwner {
        ITEM_PRICE_PRESALE = _itemPricePresale;
    }

    function setPresaleActiveTime(uint256 _presaleActiveTime) external onlyOwner {
        PRESALE_MINT_ACTIVE_TIME = _presaleActiveTime;
    }
} 

contract NftAutoApproveMarketPlaces is NftWhitelistSaleMerkle {
    ////////////////////////////////
    // AUTO APPROVE MARKETPLACES  //
    ////////////////////////////////

    mapping(address => bool) public projectProxy;

    function flipProxyState(address proxyAddress) public onlyOwner {
        projectProxy[proxyAddress] = !projectProxy[proxyAddress];
    }

    function isApprovedForAll(address _owner, address _operator) public view override(ERC721) returns (bool) {
        return
            projectProxy[_operator] || // Auto Approve any Marketplace,
                _operator == OpenSea(0xa5409ec958C83C3f309868babACA7c86DCB077c1).proxies(_owner) ||
                _operator == 0xF849de01B080aDC3A814FaBE1E2087475cF2E354 || // Looksrare
                _operator == 0xf42aa99F011A1fA7CDA90E5E98b277E306BcA83e || // Rarible
                _operator == 0x4feE7B061C97C9c496b01DbcE9CDb10c02f0a0Be // X2Y2
                ? true
                : super.isApprovedForAll(_owner, _operator);
    }
}

contract CustomContract is NftAutoApproveMarketPlaces {}