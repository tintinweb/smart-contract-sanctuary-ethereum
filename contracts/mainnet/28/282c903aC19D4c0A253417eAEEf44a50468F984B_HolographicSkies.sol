//Contract based on https://docs.openzeppelin.com/contracts/3.x/erc721
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./Counters.sol";
import "./Address.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
import "./ECDSA.sol";

contract HolographicSkies is ERC721, Ownable {
    using Strings for uint256;
    using SafeMath for uint256;
    using Counters for Counters.Counter;
    
    Counters.Counter private _tokenIdTracker;
    mapping (uint256 => string) private _tokenURIs;
    mapping (string => address) private _tokenIDs;

    address private constant KoalaMintDevAddress = 0xD17237307b93b104c50d6F83CF1e2dB99f7a348a;
    address private constant CreatorAddress = 0x9c3ACbBAFE6b7fEeb2d05D200cB8215daD0CCCb1;
    address private constant SignerAddress = 0x4AeA7b69ABb482e34BDd1D8C7A6B8dcA44F65775;

    string private baseURIextended;
    uint256 private constant min_price = 0 ether;
    uint256 private maxSupply = 3500;

    bool private pause = false;

    event KoalaMintMinted(uint256 indexed tokenId, address owner, address to, string tokenURI);
    event KoalaMintTransfered(address to, uint value);

    constructor(string memory _baseURIextended) ERC721("HOLOGRAPHIC SKIES", "HSAA"){
        baseURIextended = _baseURIextended;
    }
    
    function _setTokenURI(uint256 tokenId, string memory _tokenURI) internal virtual {
        require(_exists(tokenId), "URI set of nonexistent token");
        _tokenURIs[tokenId] = _tokenURI;
    }
    
    function revealCollection(string memory _baseURIextended) public onlyOwner {
        require(keccak256(bytes(baseURIextended)) != keccak256(bytes(_baseURIextended)), "Collection already revealed");
        setBaseURI(_baseURIextended);
    }

    function setBaseURI(string memory _baseURIextended) private onlyOwner {
        baseURIextended = _baseURIextended;
    }

    function setMaxSupply(uint256 _maxSupply) public onlyOwner {
        maxSupply = _maxSupply;
    }
    
    function setPause(bool _pause) public onlyOwner {
        pause = _pause;
    }

    function getPause() public view virtual returns (bool) {
        return pause;
    }
    
    function _baseURI() internal view virtual override returns (string memory) {
        return baseURIextended;
    }

    function burn(uint256 tokenId) public onlyOwner {
        require(_exists(tokenId), "URI query for nonexistent token");
        _tokenIDs[_tokenURIs[tokenId]] = address(0);
        _tokenURIs[tokenId] = "";
        _burn(tokenId);
    }
    
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "URI query for nonexistent token");

        string memory _tokenURI = _tokenURIs[tokenId];
        string memory base = _baseURI();

        return string(abi.encodePacked(base, _tokenURI));
    }

    function signatureSignerMint(address _to, string[] memory _tokensURI, uint256 _timestamp, uint value, uint8 v, bytes32 r, bytes32 s) public view virtual returns (address){
        return ECDSA.recover(keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", keccak256(abi.encode(_to, _tokensURI[0], _timestamp, value, _tokensURI.length)))), v, r, s);
    }

    function mint(address _to, string[] memory _tokensURI, uint256 _timestamp, uint8 v, bytes32 r, bytes32 s) public payable {
        require(!pause, "Sales paused");
        require(msg.value >= min_price.mul(_tokensURI.length), "Value below price");
        require(maxSupply >= _tokenIdTracker.current() + _tokensURI.length, "SoldOut");
        require(_tokensURI.length > 0, "Minimum count");

        address signerMint = signatureSignerMint(_to, _tokensURI, _timestamp, msg.value, v, r, s);
        require(signerMint == SignerAddress, "Not authorized to mint");

        require(_timestamp >= block.timestamp - 300, "Out of time");

        for (uint8 i = 0; i < _tokensURI.length; i++){
            require(_tokenIDs[_tokensURI[i]] == address(0), "Token already minted");
            _mintAnElement(_to, _tokensURI[i]);
        }
        
        uint256 _feeCreator = msg.value.mul(5).div(100);

        transfer(KoalaMintDevAddress, _feeCreator);
        transfer(CreatorAddress, msg.value - _feeCreator);
    }

    function _mintAnElement(address _to, string memory _tokenURI) private {
        uint256 _tokenId = _tokenIdTracker.current();
        
        _tokenIdTracker.increment();
        _tokenId = _tokenId + 1;
        _mint(_to, _tokenId);
        _setTokenURI(_tokenId, _tokenURI);
        _tokenIDs[_tokenURI] = _to;

        emit KoalaMintMinted(_tokenId, CreatorAddress, _to, _tokenURI);
    }

    function transfer(address to, uint256 value) private {
        (bool success, ) = to.call{value: value}("");
        require(success, "Transfer failed.");
        emit KoalaMintTransfered(to, value);
    }
}