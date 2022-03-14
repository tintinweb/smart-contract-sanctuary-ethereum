// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.11 <0.9.0;

import "./Ownable.sol";
import "./ERC721.sol";
import "./Counters.sol";

contract CircleDudes is ERC721, Ownable {

    using Counters for Counters.Counter;
    using Strings for uint256;

    Counters.Counter private supply;

    string hiddenMetadataUri;
    string uriPrefix = "";
    string uriSuffix = ".json";

    bool paused = true;
    bool revealed = false;
    bool whitelistOpen = true; 

    address[]  whitelistedAddresses;

    uint256  maxSupply = 10000;
    uint256 public cost = 0.1 ether;

    constructor() ERC721("Circle Dudes", "CDT") {
    }

    modifier mintCompliance() {
        require(supply.current() + 1 <= maxSupply, "Max supply exceeded!");
        _;
    }


    function totalSupply() public view returns (uint256) {
        return supply.current();
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return uriPrefix;
    }

    function tokenURI(uint256 _tokenId) public view virtual override returns (string memory){
        require(_exists(_tokenId), "ERC721Metadata: URI query for nonexistent token");
        if (revealed == false) {
            return hiddenMetadataUri;
        }
        string memory currentBaseURI = _baseURI();
        return bytes(currentBaseURI).length > 0 ? string(abi.encodePacked(currentBaseURI, _tokenId.toString(), uriSuffix)) : "";
    }

    function walletOfOwner(address _owner) public view returns (uint256[] memory){
        uint256 ownerTokenCount = balanceOf(_owner);
        uint256[] memory ownedTokenIds = new uint256[](ownerTokenCount);
        uint256 currentTokenId = 1;
        uint256 ownedTokenIndex = 0;
        while (ownedTokenIndex < ownerTokenCount && currentTokenId <= maxSupply) {
            address currentTokenOwner = ownerOf(currentTokenId);
            if (currentTokenOwner == _owner){
                ownedTokenIds[ownedTokenIndex] = currentTokenId;
                ownedTokenIndex++;
            }
            currentTokenId++;
        }
        return ownedTokenIds;
    }
    
    function withdraw() public onlyOwner {
        (bool os, ) = payable(owner()).call{value: address(this).balance}("");
        require(os);
    }
    
    function mint() public payable mintCompliance() {
        require(!paused, "The contract is paused!");
        require(msg.value >= cost, "Insufficient funds!");
        if(whitelistOpen){
            require(isWhiteListed(msg.sender), "Its not on whitelist");
        }
        _mintGo(msg.sender);
    }

    function mintForAddress(address _receiver) public mintCompliance() onlyOwner {
        _mintGo(_receiver);
    }

    function _mintGo(address _receiver) internal {
        supply.increment();
        _safeMint(_receiver, supply.current());
        if(whitelistOpen){
            removeFromWhitelist(_receiver);
        }
    }
    
    function isWhiteListed(address _address) public view returns(bool){
        for(uint256 i = 0; i<whitelistedAddresses.length; i++){
            if ( whitelistedAddresses[i] == _address){
                return true;
            }
        }
        return false;
    }

    function removeFromWhitelist(address _address) internal{
        for(uint256 i = 0; i < whitelistedAddresses.length; i++){
            if ( whitelistedAddresses[i] == _address){
                whitelistedAddresses[i] = whitelistedAddresses[whitelistedAddresses.length -1];
                whitelistedAddresses.pop();
                return;
            }
        }
    }

    function getWhiteList() public view onlyOwner returns(address[] memory ) {
        return(whitelistedAddresses);
    }

    function setPaused(bool _state) public onlyOwner {
        paused = _state;
    }

    function setRevealed(bool _state) public onlyOwner {
        revealed = _state;
    }

    function setWhitelistOpen(bool _state) public onlyOwner {
        whitelistOpen = _state;
    }

    function setWhitelistUsers(address[] calldata _users) public onlyOwner{
        delete whitelistedAddresses;
        whitelistedAddresses = _users;
    }

    function setHiddenMetadataUri(string memory _hiddenMetadataUri) public onlyOwner {
        hiddenMetadataUri = _hiddenMetadataUri;
    }
 
    function setUriPrefix(string memory _uriPrefix) public onlyOwner {
        uriPrefix = _uriPrefix;
    }

    function setUriSuffix(string memory _uriSuffix) public onlyOwner {
        uriSuffix = _uriSuffix;
    }

    function setCost(uint256 _cost) public onlyOwner {
        cost = _cost;
    }
}