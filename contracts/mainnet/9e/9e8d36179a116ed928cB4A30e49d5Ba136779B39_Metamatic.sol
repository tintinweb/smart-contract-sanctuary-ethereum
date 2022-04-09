//Contract based on https://docs.openzeppelin.com/contracts/3.x/erc721
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

import "./ERC721.sol";
import "./ERC721URIStorage.sol";
import "./ERC721Enumerable.sol";
import "./Counters.sol";
import "./Ownable.sol";

import './ERC2981Royalties.sol';


contract Metamatic is ERC721, ERC721URIStorage, ERC2981Royalties, ERC721Enumerable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    using Strings for uint256;

    mapping (uint256 => string) private _tokenURIs;

    event SketchSelled(uint256 tokenId);

    string private _baseURIextended;

    Sketch[] public sketches;

    struct Sketch {
        uint256 price;
        uint256 royalty;
        bool onSale;
        uint date;
        string tokenURI;
        address owner;
    }

    constructor() public ERC721("meta-matic", "METAMATIC") {}

    function contractURI() public view returns (string memory) {
        return "https://meta-matic.mypinata.cloud/ipfs/QmSuiFuEWACWc7zQRn9CRxJZanzTP3BpWhNS9p8JTMeAPv";
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721, ERC2981Base, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function mintNFT(address recipient, string memory tokenURI)
        public
        returns (uint256)
    {
        Sketch memory _sketch = Sketch({
            price: 0,
            royalty: 0,
            onSale: false,
            date: block.timestamp,
            tokenURI: tokenURI,
            owner: msg.sender
        });

        sketches.push(_sketch);

        uint256 newItemId = _tokenIds.current();
        _mint(recipient, newItemId);
        _setTokenURI(newItemId, tokenURI);

        _tokenIds.increment();

        return newItemId;
    }

    function burn(uint256 tokenId) public {
        require(_isApprovedOrOwner(msg.sender, tokenId));
        _burn(tokenId);

        if (tokenId >= sketches.length) return;

        for (uint i=tokenId; i<sketches.length-1; i++){
            sketches[i] = sketches[i+1];
        }
        sketches.pop();
    }

    function transactionNFT(address to, uint256 tokenId) external payable {
        address owner = address(uint160(ownerOf(tokenId)));
        require(owner != msg.sender);
        require(owner != address(0));

        Sketch storage _sketch = sketches[tokenId];
        require(msg.value >= _sketch.price);
        require(_sketch.onSale == true);

        approve(to, tokenId);
        payable(owner).transfer(_sketch.price);

        safeTransferFrom(owner, to, tokenId);
        _sketch.price = 0;
        _sketch.onSale = false;
        _sketch.owner = to;
    }

    function sellNFT(address marketContract, uint256 tokenId, uint256 price) external {
        require(ownerOf(tokenId) == msg.sender);
        Sketch storage _sketch = sketches[tokenId];
        _sketch.price = price;
        _sketch.onSale = true;

        setApprovalForAll(marketContract, true);

        emit SketchSelled(tokenId);
    }

    function unlistNFT(uint256 tokenId) external {
        require(ownerOf(tokenId) == msg.sender);
        Sketch storage _sketch = sketches[tokenId];
        _sketch.price = 0;
        _sketch.onSale = false;
    }

    function changeOwner(address to, uint256 tokenId) external {
        require(ownerOf(tokenId) == msg.sender);
        Sketch storage _sketch = sketches[tokenId];
        _sketch.owner = to;
    }

    function setRoyalties(address to, uint256 tokenId, uint256 value) public {
        require(ownerOf(tokenId) == msg.sender);
        Sketch storage _sketch = sketches[tokenId];
        _sketch.royalty = value;
        _setRoyalties(to, value);
    }

    function getSketch(uint256 tokenId)
        public
        view
        returns (
            Sketch memory _sketch
        ) {
            Sketch memory sketch = sketches[tokenId];
            return sketch;
        }
}