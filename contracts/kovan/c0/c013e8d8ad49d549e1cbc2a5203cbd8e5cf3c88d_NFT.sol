// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./Counters.sol";
import "./SafeMath.sol";
import "./ERC721.sol";
import "./ERC721Enumerable.sol";

contract NFT is
    ERC721,
    ERC721Enumerable,
    Ownable
{
    using SafeMath for uint256;
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdTracker;

    string private _baseTokenURI;
    uint256 public _maxSupply;

    constructor() ERC721("IAN NFT", "IAN") {
        _baseTokenURI = "https://www.facebook.com/";
        _maxSupply = 100;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function mint(address to) public payable {
        require(_tokenIdTracker.current() < _maxSupply, "Exceed the number of releases");
        _safeMint(to, _tokenIdTracker.current());
        _tokenIdTracker.increment();
    }

    function mintMore(address _to, uint256 _mintAmount) public payable {
        require(_mintAmount > 0, "Abnormal quantity");
        require(_tokenIdTracker.current().add(_mintAmount) <= _maxSupply, "Exceed the number of releases");
        uint256 startNumber = _tokenIdTracker.current();
        uint256 endNumber = startNumber.add(_mintAmount);
        for(uint256 i = startNumber; i < endNumber; i++) {
            _safeMint(_to, i);
            _tokenIdTracker.increment();
        }
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId) public view override(ERC721, ERC721Enumerable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}