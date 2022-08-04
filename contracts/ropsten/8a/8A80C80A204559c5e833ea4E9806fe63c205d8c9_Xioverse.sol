// SPDX-License-Identifier: GPL-3.0
// *Edited and Writed* By Mahmoud Al Homsi https://github.com/codingforwhile

pragma solidity ^0.8.0;

import "./ERC721Enumerable.sol";
import "./Ownable.sol";

contract Xioverse is ERC721Enumerable, Ownable {
    using Strings for uint256;

    string public baseURI;
    string public baseExtension = ".json?alt=media";

    uint256 public mintingCost = 0.1 ether;
    uint256 public silverMintingQuota = 0.0015 ether;
    uint256 public goldMintingQuota = 0.001 ether;

    uint256 public maxSupply = 1000;
    uint256 public maxInvestmentSupply = 250;
    uint256 public minInvMintAmount = 5;
    bool public paused = false;
    bool public isInvestmentMode = true;

    address payable ownerAddress;

    address payable public silverKeyPrehistory = payable(0x0CfcD7E2Ad76aC82ECc608fF0b632D6F1062CaD7);
    address payable public silverKeyEgyptianMythology = payable(0x7C230D92D445015ceCdB3CE4422a7497C6BddA3F);
    address payable public silverKeyGreekMythology = payable(0x7A6acbe4E8bFB327d22aC8742A25ab3aEfA9b478);
    address payable public silverKeyNorseMythology = payable(0xa8277a706522E45bC8774363f0E9cAC25D578e11);
    address payable public silverKeyMedievalAge = payable(0x50B4613734270C02762AD633c0CA56D308b1F9f3);
    address payable public silverKeyRenaissance = payable(0xF6B6d4f5EBf381a4dF6D02b105a6bE4472Ea2F14);
    address payable public silverKeyIndustrialRevolution = payable(0x5252F9c7E15A5390F2c7d5C1d0C4a4a43fAcA1f0);
    address payable public silverKeySteamPunk = payable(0xA9D42b05FCf41D89f22026101253a01495877307);
    address payable public silverKeyCyberPunk = payable(0xe41484bF0287138bc77B68B5924C8a0dB6850736);
    address payable public silverKeyCosmos = payable(0xeB016636C40eBc265b98d68367AA56f4B298cA5a);
    address payable public goldKey = payable(0x9E58d05fa3BE2956C477b0b1Af3f0c869E2e2150);

    constructor(
        string memory _name,
        string memory _symbol,
        string memory _initBaseURI
    ) ERC721(_name, _symbol) {
        setBaseURI(_initBaseURI);
        ownerAddress = payable(owner());
    }

    // internal
    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function internalKeysWithdraw(uint256 _firstTokenID, uint256 _lastTokenID, uint256 paidEther) internal {
        for (uint256 i = _firstTokenID; i <= _lastTokenID; i++) {
            if (i % 10 == 1) {silverKeyPrehistory.transfer(silverMintingQuota);}
            if (i % 10 == 2) {silverKeyEgyptianMythology.transfer(silverMintingQuota);}
            if (i % 10 == 3) {silverKeyGreekMythology.transfer(silverMintingQuota);}
            if (i % 10 == 4) {silverKeyNorseMythology.transfer(silverMintingQuota);}
            if (i % 10 == 5) {silverKeyMedievalAge.transfer(silverMintingQuota);}
            if (i % 10 == 6) {silverKeyRenaissance.transfer(silverMintingQuota);}
            if (i % 10 == 7) {silverKeyIndustrialRevolution.transfer(silverMintingQuota);}
            if (i % 10 == 8) {silverKeySteamPunk.transfer(silverMintingQuota);}
            if (i % 10 == 9) {silverKeyCyberPunk.transfer(silverMintingQuota);}
            if (i % 10 == 0) {silverKeyCosmos.transfer(silverMintingQuota);}
        }
        uint256 totalGoldQuota = ((_lastTokenID - _firstTokenID)+1)*goldMintingQuota;
        uint256 totalSilverQuota = ((_lastTokenID - _firstTokenID)+1)*silverMintingQuota;
        uint256 restForOwner = paidEther - (totalSilverQuota + totalGoldQuota);
        goldKey.transfer(totalGoldQuota);
        ownerAddress.transfer(restForOwner);
    }

    // public
    function mint(uint256 _mintAmount) public payable {
        uint256 supply = totalSupply();
        require(!paused);
        require(msg.value >= mintingCost * _mintAmount);
        if (isInvestmentMode) {
            require(_mintAmount >= minInvMintAmount);
            require(supply + _mintAmount <= maxInvestmentSupply);
        }
        if (!isInvestmentMode) {
            require(_mintAmount > 0);
            require(supply + _mintAmount <= maxSupply);
        }
        for(uint256 i = 1; i <= _mintAmount; i++) {
            _safeMint(msg.sender, supply + i); 
        }
        internalKeysWithdraw(supply+1, supply+_mintAmount, msg.value);
    }

    function walletOfOwner(address _owner) public view returns (uint256[] memory) {
        uint256 ownerTokenCount = balanceOf(_owner);
        uint256[] memory tokenIds = new uint256[](ownerTokenCount);
        for (uint256 i; i < ownerTokenCount; i++) {
            tokenIds[i] = tokenOfOwnerByIndex(_owner, i);
        }
        return tokenIds;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        string memory currentBaseURI = _baseURI();
        return bytes(currentBaseURI).length > 0 ? string(abi.encodePacked(currentBaseURI, tokenId.toString(), baseExtension)) : "";
    }

    // only owner
    function setMaxInvestmentSupply(uint256 _newMaxInvestmentSupply) public onlyOwner () {
        if (_newMaxInvestmentSupply <= maxInvestmentSupply) {
            maxInvestmentSupply = _newMaxInvestmentSupply;
        }
    }

    function setMinInvMintAmount(uint256 _newMinInvMintAmount) public onlyOwner (){
        minInvMintAmount = _newMinInvMintAmount;
    }

    function setCosts(uint256 _newMintingCost, uint256 _newSilverMintingQuota, uint256 _newGoldMintingQuota) public onlyOwner() {
        require ( _newMintingCost > _newSilverMintingQuota + _newGoldMintingQuota);
        mintingCost = _newMintingCost;
        silverMintingQuota = _newSilverMintingQuota;
        goldMintingQuota = _newGoldMintingQuota;
    }

    function setSilverKeyPrehistory(address payable _newAddrressKey) public onlyOwner() {silverKeyPrehistory = payable(_newAddrressKey);}
    function setSilverKeyEgyptianMythology(address payable _newAddrressKey) public onlyOwner() {silverKeyEgyptianMythology = payable(_newAddrressKey);}
    function setSilverKeyGreekMythology(address payable _newAddrressKey) public onlyOwner() {silverKeyGreekMythology = payable(_newAddrressKey);}
    function setSilverKeyNorseMythology(address payable _newAddrressKey) public onlyOwner() {silverKeyNorseMythology = payable(_newAddrressKey);}
    function setSilverKeyMedievalAge(address payable _newAddrressKey) public onlyOwner() {silverKeyMedievalAge = payable(_newAddrressKey);}
    function setSilverKeyRenaissance(address payable _newAddrressKey) public onlyOwner() {silverKeyRenaissance = payable(_newAddrressKey);}
    function setSilverKeyIndustrialRevolution(address payable _newAddrressKey) public onlyOwner() {silverKeyIndustrialRevolution = payable(_newAddrressKey);}
    function setSilverKeySteamPunk(address payable _newAddrressKey) public onlyOwner() {silverKeySteamPunk = payable(_newAddrressKey);}
    function setSilverKeyCyberPunk(address payable _newAddrressKey) public onlyOwner() {silverKeyCyberPunk = payable(_newAddrressKey);}
    function setSilverKeyCosmos(address payable _newAddrressKey) public onlyOwner() {silverKeyCosmos = payable(_newAddrressKey);}
    function setGoldKey(address payable _newAddrressKey) public onlyOwner() {goldKey = payable(_newAddrressKey);}

    function setBaseURI(string memory _newBaseURI) public onlyOwner() {
        baseURI = _newBaseURI;
    }

    function setBaseExtention(string memory _newBaseExtention) public onlyOwner() {
        baseExtension = _newBaseExtention;
    }

    function pause(bool _state) public onlyOwner {
        paused = _state;
    }

    function removeInvestmentMode() public onlyOwner {
        isInvestmentMode = false;
    }
}