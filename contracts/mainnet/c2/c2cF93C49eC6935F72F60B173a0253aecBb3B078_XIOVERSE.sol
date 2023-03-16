// SPDX-License-Identifier: MIT
// XIOVERSE Smart Contract

pragma solidity ^0.8.0;

import "./IERC2981.sol";
import "./ERC721Enumerable.sol";
import "./Ownable.sol";

contract XIOVERSE is ERC721Enumerable, Ownable, IERC2981 {
    using Strings for uint256;
    string public baseURI;
    string public baseExtension = ".json";
    uint256 public mintingCost = 1.3 ether;
    uint256 public silverMintingQuota = 0.0195 ether;
    uint256 public goldMintingQuota = 0.013 ether;
    uint256 public maximumMaxSupply = 1000;
    uint256 internal maxSupply = 100;
    uint256 public ownerQuota = 11;
    uint256 public usedOwnerQuota = ownerQuota;
    bool public paused = false;
    address payable ownerAddress;
    address payable public silverKeySteamPunk;
    address payable public silverKeyGreekMythology;
    address payable public silverKeyCyberPunk;
    address payable public silverKeyMedievalAge;
    address payable public silverKeyNorseMythology;
    address payable public silverKeyRenaissance;
    address payable public silverKeyPrehistory;
    address payable public silverKeyEgyptianMythology;
    address payable public silverKeyIndustrialRevolution;
    address payable public silverKeyCosmos;
    address payable public goldKey;
    address payable public paymentSplitterSteamPunk;
    address payable public paymentSplitterGreekMythology;
    address payable public paymentSplitterCyberPunk;
    address payable public paymentSplitterMedievalAge;
    address payable public paymentSplitterNorseMythology;
    address payable public paymentSplitterRenaissance;
    address payable public paymentSplitterPrehistory;
    address payable public paymentSplitterEgyptianMythology;
    address payable public paymentSplitterIndustrialRevolution;
    address payable public paymentSplitterCosmos;
    address payable public currentMintSilverKey;

    uint256 public royaltyPercentage;

    constructor(
        string memory _name,
        string memory _symbol,
        string memory _initBaseURI,
        address[] memory _tenSilverKeysStGrCyMeNoRePrEgInCo,
        address[] memory _oneGoldKey,
        address[] memory _tenPaymentSplittersStGrCyMeNoRePrEgInCo
    ) ERC721(_name, _symbol) {
        setBaseURI(_initBaseURI);
        ownerAddress = payable(owner());
        silverKeySteamPunk = payable (_tenSilverKeysStGrCyMeNoRePrEgInCo[0]);
        silverKeyGreekMythology = payable (_tenSilverKeysStGrCyMeNoRePrEgInCo[1]);
        silverKeyCyberPunk = payable (_tenSilverKeysStGrCyMeNoRePrEgInCo[2]);
        silverKeyMedievalAge = payable (_tenSilverKeysStGrCyMeNoRePrEgInCo[3]);
        silverKeyNorseMythology = payable (_tenSilverKeysStGrCyMeNoRePrEgInCo[4]);
        silverKeyRenaissance = payable (_tenSilverKeysStGrCyMeNoRePrEgInCo[5]);
        silverKeyPrehistory = payable (_tenSilverKeysStGrCyMeNoRePrEgInCo[6]);
        silverKeyEgyptianMythology = payable (_tenSilverKeysStGrCyMeNoRePrEgInCo[7]);
        silverKeyIndustrialRevolution = payable (_tenSilverKeysStGrCyMeNoRePrEgInCo[8]);
        silverKeyCosmos = payable (_tenSilverKeysStGrCyMeNoRePrEgInCo[9]);
        goldKey = payable (_oneGoldKey[0]);
        paymentSplitterSteamPunk = payable (_tenPaymentSplittersStGrCyMeNoRePrEgInCo[0]);
        paymentSplitterGreekMythology = payable (_tenPaymentSplittersStGrCyMeNoRePrEgInCo[1]);
        paymentSplitterCyberPunk = payable (_tenPaymentSplittersStGrCyMeNoRePrEgInCo[2]);
        paymentSplitterMedievalAge = payable (_tenPaymentSplittersStGrCyMeNoRePrEgInCo[3]);
        paymentSplitterNorseMythology = payable (_tenPaymentSplittersStGrCyMeNoRePrEgInCo[4]);
        paymentSplitterRenaissance = payable (_tenPaymentSplittersStGrCyMeNoRePrEgInCo[5]);
        paymentSplitterPrehistory = payable (_tenPaymentSplittersStGrCyMeNoRePrEgInCo[6]);
        paymentSplitterEgyptianMythology = payable (_tenPaymentSplittersStGrCyMeNoRePrEgInCo[7]);
        paymentSplitterIndustrialRevolution = payable (_tenPaymentSplittersStGrCyMeNoRePrEgInCo[8]);
        paymentSplitterCosmos = payable (_tenPaymentSplittersStGrCyMeNoRePrEgInCo[9]);
        currentMintSilverKey = silverKeySteamPunk;
    }
    
    // internal
    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function internalKeysWithdrawAfterMint(uint256 _firstTokenID, uint256 _lastTokenID, uint256 paidEther) internal {
        uint256 totalGoldQuota = ((_lastTokenID - _firstTokenID)+1)*goldMintingQuota;
        uint256 totalSilverQuota = ((_lastTokenID - _firstTokenID)+1)*silverMintingQuota;
        uint256 restForOwner = paidEther - (totalSilverQuota + totalGoldQuota);
        currentMintSilverKey.transfer(totalSilverQuota);
        goldKey.transfer(totalGoldQuota);
        ownerAddress.transfer(restForOwner);
    }

    // public
    function mint(uint256 _mintAmount) public payable {
        uint256 supply = totalSupply();
        require(!paused);
        require(msg.value >= mintingCost * _mintAmount);
        require(_mintAmount > 0);
        require(supply + _mintAmount <= maxSupply - usedOwnerQuota);
        for(uint256 i = 1; i <= _mintAmount; i++) {
            _safeMint(msg.sender, supply + i); 
        }
        internalKeysWithdrawAfterMint(supply+1, supply+_mintAmount, msg.value);
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

    function _maxSupply() public view returns (uint256) {
        uint256 maxUserSupply = maxSupply - usedOwnerQuota;
        return maxUserSupply;
    }

    // onlyOwner
    function setCosts(uint256 _newMintingCost, uint256 _newSilverMintingQuota, uint256 _newGoldMintingQuota) public onlyOwner() {
        require ( _newMintingCost > _newSilverMintingQuota + _newGoldMintingQuota);
        mintingCost = _newMintingCost*1000000000;
        silverMintingQuota = _newSilverMintingQuota*1000000000;
        goldMintingQuota = _newGoldMintingQuota*1000000000;
    }

    function setBaseURI(string memory _newBaseURI) public onlyOwner() {
        baseURI = _newBaseURI;
    }

    function setTemporaryUpgrade(address payable _newAddrressKey, uint256 _newQuota, uint256 _newMintingCost, uint256 _newSilverMintingQuota, uint256 _newGoldMintingQuota) public onlyOwner() {
        uint256 supply = totalSupply();
        require (supply % 100 == 0, "Operation not alowed");
        require (maxSupply <= maximumMaxSupply-100, "you will exceed the limit of maximumMaxSupply");
        require ( _newMintingCost > _newSilverMintingQuota + _newGoldMintingQuota);
        maxSupply += 100;
        currentMintSilverKey = payable(_newAddrressKey);
        ownerQuota = _newQuota;
        usedOwnerQuota = ownerQuota;
        mintingCost = _newMintingCost*1000000000;
        silverMintingQuota = _newSilverMintingQuota*1000000000;
        goldMintingQuota = _newGoldMintingQuota*1000000000;
    }

    function setBaseExtention(string memory _newBaseExtention) public onlyOwner() {
        baseExtension = _newBaseExtention;
    }

    function pause(bool _state) public onlyOwner {
        paused = _state;
    }

    function adminMint(address _to, uint256 _mintAmount) public payable onlyOwner{
        uint256 supply = totalSupply();
        require(!paused);
        require(msg.value >= mintingCost * _mintAmount);
        require(_mintAmount > 0);
        require(supply + _mintAmount <= maxSupply);
        for(uint256 i = 1; i <= _mintAmount; i++) {
            _safeMint(_to, supply + i);
            if (usedOwnerQuota > 0) {
                usedOwnerQuota--;
            }
        }
        internalKeysWithdrawAfterMint(supply+1, supply+_mintAmount, msg.value);
    }

    function setCurrentMintSilverKey(address payable _newAddrressKey) public onlyOwner() {currentMintSilverKey = payable(_newAddrressKey);}
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
    function setPaymentSplitterPrehistory (address payable _newAddrressKey) public onlyOwner() {paymentSplitterPrehistory = payable(_newAddrressKey);}
    function setPaymentSplitterEgyptianMythology (address payable _newAddrressKey) public onlyOwner() {paymentSplitterEgyptianMythology = payable(_newAddrressKey);}
    function setPaymentSplitterGreekMythology (address payable _newAddrressKey) public onlyOwner() {paymentSplitterGreekMythology = payable(_newAddrressKey);}
    function setPaymentSplitterNorseMythology (address payable _newAddrressKey) public onlyOwner() {paymentSplitterNorseMythology = payable(_newAddrressKey);}
    function setPaymentSplitterMedievalAge (address payable _newAddrressKey) public onlyOwner() {paymentSplitterMedievalAge = payable(_newAddrressKey);}
    function setPaymentSplitterRenaissance (address payable _newAddrressKey) public onlyOwner() {paymentSplitterRenaissance = payable(_newAddrressKey);}
    function setPaymentSplitterIndustrialRevolution (address payable _newAddrressKey) public onlyOwner() {paymentSplitterIndustrialRevolution = payable(_newAddrressKey);}
    function setPaymentSplitterSteamPunk (address payable _newAddrressKey) public onlyOwner() {paymentSplitterSteamPunk = payable(_newAddrressKey);}
    function setPaymentSplitterCyberPunk (address payable _newAddrressKey) public onlyOwner() {paymentSplitterCyberPunk = payable(_newAddrressKey);}
    function setPaymentSplitterCosmos (address payable _newAddrressKey) public onlyOwner() {paymentSplitterCosmos = payable(_newAddrressKey);}

    function setRoyalty(uint256 _percentage) public onlyOwner {
        royaltyPercentage = _percentage;
    }

    function setOwnerQuota(uint256 _ownerQuota) public onlyOwner {
        ownerQuota = _ownerQuota;
    }

    /**
    The following function is a provision compliant with the ERC2981 standard, which requires royalties to be split as follows:
        7.5% to the project address
        1.5% to the silver key address
        1% to the gold key address
    */

    function royaltyInfo(uint256 _tokenId, uint256 _salePrice) external view override returns (address receiver, uint256 royaltyAmount) {
        require(_exists(_tokenId), "Token does not exist");
        if (royaltyPercentage > 0) {
            uint256 royalty = (_salePrice * royaltyPercentage) / 100;
            address payable royaltyRecipient;
            if (_tokenId <= 100) {
                royaltyRecipient = paymentSplitterSteamPunk;
            } else if (_tokenId <= 200) {
                royaltyRecipient = paymentSplitterGreekMythology;
            } else if (_tokenId <= 300) {
                royaltyRecipient = paymentSplitterCyberPunk;
            } else if (_tokenId <= 400) {
                royaltyRecipient = paymentSplitterMedievalAge;
            } else if (_tokenId <= 500) {
                royaltyRecipient = paymentSplitterNorseMythology;
            } else if (_tokenId <= 600) {
                royaltyRecipient = paymentSplitterRenaissance;
            } else if (_tokenId <= 700) {
                royaltyRecipient = paymentSplitterPrehistory;
            } else if (_tokenId <= 800) {
                royaltyRecipient = paymentSplitterEgyptianMythology;
            } else if (_tokenId <= 900) {
                royaltyRecipient = paymentSplitterIndustrialRevolution;
            } else if (_tokenId <= 1000) {
                royaltyRecipient = paymentSplitterCosmos;
            }
            return (royaltyRecipient, royalty);
        } else {
            return (address(0), 0);
        }
    }
    
    function supportsInterface(bytes4 interfaceId) public view override(ERC721Enumerable, IERC165) returns (bool) {
        return super.supportsInterface(interfaceId) || interfaceId == type(IERC2981).interfaceId;
    }

}