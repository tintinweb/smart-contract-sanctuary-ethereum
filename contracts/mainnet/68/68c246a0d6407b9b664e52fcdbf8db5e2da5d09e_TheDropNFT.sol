// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./CreatorRole.sol";
import "./SafeMath.sol";
import "./ITheDropNFT.sol";

contract TheDropNFT is ITheDropNFT, ERC721Enumerable, Ownable, CreatorRole {

    using SafeMath for uint256;

    uint256 private totalTokens;

    struct TokenDetail {
        string uri;
        address creator;
        uint256 resellRate;
    }

    mapping(uint256 => TokenDetail) private tokenDetails;

    mapping(string => uint256) private uniqueUriToken;

    constructor() ERC721("Neo Preemo", "NEOP") {
    }

    modifier uniqueURI(string memory _uri) {
        require(uniqueUriToken[_uri] == 0, "TheDropNFT: Url already used");
        _;
    }

    function mint(address to, uint256 tokenId) public onlyOwner {
        _mint(to, tokenId);
    }

    function safeMint(address to, uint256 tokenId) public onlyOwner{
        _safeMint(to, tokenId);
    }

    function safeMint(address to, uint256 tokenId, bytes memory _data) public onlyOwner{
        _safeMint(to, tokenId, _data);
    }

    function baseURI() public override view returns (string memory) {
        return _baseURI();
    }

    function exists(uint256 tokenId) public override view returns (bool) {
        return _exists(tokenId);
    }

    function burn(uint256 tokenId) public override{
        require(creatorOf(tokenId) == _msgSender(), "TheDropNFT: caller is not the creator.");
        require(ownerOf(tokenId) == _msgSender(), "TheDropNFT: caller is not the token owner.");
        _burn(tokenId);
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        return tokenDetails[tokenId].uri;
    }

    function tokenSellRate(uint256 tokenId) public override view virtual returns (uint256) {
        require(_exists(tokenId), "ERC721Metadata: Sell rate query for nonexistent token");
        return tokenDetails[tokenId].resellRate;
    }

    function uriOriginalToken(string memory _uri) public override view returns (uint256) {
        require(uniqueUriToken[_uri] != 0, "ERC721Metadata: Uri original token query for nonexistent token");
        return uniqueUriToken[_uri];
    }

    // Artist wallet address of token
    function creatorOf(uint256 _tokenId) public override view returns (address) {
        require(tokenDetails[_tokenId].creator != address(0), "ERC721Metadata: Token creator query for nonexistent token");
        return tokenDetails[_tokenId].creator;
    }

    function _mintToken(uint256 _id, string memory _uri, address _creator, uint256 _sellRate) private  returns (uint256){
        require(_sellRate <= 50, "TheDropNFT: Cannot set royalties greater than 50%");
        totalTokens = totalTokens.add(1);
        _mint(_creator, _id);
        TokenDetail storage tokenDetail = tokenDetails[_id];
        tokenDetail.creator = _creator;
        tokenDetail.uri = _uri;
        tokenDetail.resellRate = _sellRate;
        emit TokenCreated(_id, _uri, _msgSender());
        return _id;
    }

    function createToken(uint256 _id, string memory _uri, uint256 _sellRate) public override uniqueURI(_uri) onlyCreator returns (uint256) {
        _mintToken(_id, _uri, _msgSender(), _sellRate);
        uniqueUriToken[_uri] = _id;
        return _id;
    }

    // Create token and transfer to the buyer
    function createTokenFor(uint256 _id, string memory _uri, address _creator, address _buyer, uint256 _sellRate) public override uniqueURI(_uri) onlyCreator {
        require(_creator != _buyer, "TheDropNFT: Buyer is the same as creator");
        uint256 newId = _mintToken(_id, _uri, _creator, _sellRate);
        uniqueUriToken[_uri] = newId;
        _transfer(_creator, _buyer, newId);
    }

    function createTokenForEdition(uint256 _id, string memory _uri, address _creator, address _buyer, bool _isOriginal, uint256 _sellRate) public override onlyCreator {
        require(_creator != _buyer, "TheDropNFT: Buyer is the same as creator");
        uint256 newId = _mintToken(_id, _uri, _creator, _sellRate);
        if(_isOriginal){
            require(uniqueUriToken[_uri] == 0, "TheDropNFT: Url already used");
            uniqueUriToken[_uri] = newId;
        }
        _transfer(_creator, _buyer, newId);
    }
    
}