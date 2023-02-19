// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "./ERC_721A.sol";
import "./Ownable.sol";
import "./ERC2981.sol";

interface OpenSea {
    function proxies(address) external view returns (address);
}

contract SBDynasty is ERC721A("SOLIDBLOCK DYNASTY", "SBDY"), Ownable, ERC2981 {
    using Strings for uint256;

    bool public publicmintActive = false;
    uint256 public maxMintAmount = 5;
    uint256 public maxSupply = 1000;
    uint256 public costPerNft = 0.4 * 1e18;
    uint256 public nftsForOwner = 15;
    string public metadataFolderIpfsLink;
    string constant baseExtension = ".json";

    constructor() {
        _setDefaultRoyalty(0x34c5eEa7E72E35a8ee9106CcD499d73FB9E6E34a, 1000); // 10.00 %
    }

    ///////////////////
    //  Public Mint  //
    ///////////////////

    modifier mintCompliance(uint256 _mintAmount) {
        uint256 supply = totalSupply();
        require(publicmintActive, "The minting is paused");
        require(_mintAmount <= maxMintAmount, "Max mint amount per session exceeded");
        require(supply + _mintAmount <= maxSupply, "Max supply exceeded!");
        require(_mintAmount > 0, "need to mint at least 1 NFT");
        _;
    }

    function mint(uint256 _mintAmount) public payable mintCompliance(_mintAmount){
        require(msg.value >= costPerNft * _mintAmount, "insufficient funds");
        _safeMint(msg.sender, _mintAmount);
    }

    function minter(address _user, uint256 _amount) private mintCompliance(_amount) {
        _safeMint(_user, _amount);
    }

    function airdrop(address[] calldata _users, uint256[] calldata _mintAmounts) public onlyOwner {
        for (uint256 i = 0; i < _users.length; i++) {
            minter(_users[i], _mintAmounts[i]);
        }
    }

    ///////////////////////////////////
    //       OVERRIDE CODE STARTS    //
    ///////////////////////////////////

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721A, ERC2981) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function _startTokenId() internal pure override returns (uint256) {
        return 1;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return metadataFolderIpfsLink;
    }

    function tokenURI(uint256 tokenId) public view virtual override(ERC721A) returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        string memory currentBaseURI = _baseURI();
        return bytes(currentBaseURI).length > 0 ? string(abi.encodePacked(currentBaseURI, tokenId.toString(), baseExtension)) : "";
    }

    //////////////////
    //  ONLY OWNER  //
    //////////////////

    function withdraw() public payable onlyOwner {
        (bool success, ) = payable(msg.sender).call{value: address(this).balance}("");
        require(success);
    }

    function giftNft(address[] calldata _sendNftsTo, uint256 _howMany) external onlyOwner {
        nftsForOwner -= _sendNftsTo.length * _howMany;

        for (uint256 i = 0; i < _sendNftsTo.length; i++) _safeMint(_sendNftsTo[i], _howMany);
    }

    function setnftsForOwner(uint256 _newnftsForOwner) public onlyOwner {
        nftsForOwner = _newnftsForOwner;
    }

    function setDefaultRoyalty(address _receiver, uint96 _feeNumerator) public onlyOwner {
        _setDefaultRoyalty(_receiver, _feeNumerator);
    }

    function setCostPerNft(uint256 _newCostPerNft) public onlyOwner {
        costPerNft = _newCostPerNft;
    }

    function setMaxMintAmount(uint256 _newmaxMintAmount) public onlyOwner {
        maxMintAmount = _newmaxMintAmount;
    }

    function setMetadataFolderIpfsLink(string memory _newMetadataFolderIpfsLink) public onlyOwner {
        metadataFolderIpfsLink = _newMetadataFolderIpfsLink;
    }

    function setSaleActive(bool _publicmintActive) public onlyOwner {
        publicmintActive = _publicmintActive;
    }

}

contract NftAutoApproveMarketPlaces is SBDynasty {
    ////////////////////////////////
    // AUTO APPROVE MARKETPLACES  //
    ////////////////////////////////

    mapping(address => bool) public projectProxy;

    function flipProxyState(address proxyAddress) public onlyOwner {
        projectProxy[proxyAddress] = !projectProxy[proxyAddress];
    }

    function isApprovedForAll(address _owner, address _operator) public view override(ERC721A) returns (bool) {
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

contract SBDynastyContract is NftAutoApproveMarketPlaces {}