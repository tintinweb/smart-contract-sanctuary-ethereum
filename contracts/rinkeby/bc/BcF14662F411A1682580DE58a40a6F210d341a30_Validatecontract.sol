//Contract based on https://docs.openzeppelin.com/contracts/3.x/erc721
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./Counters.sol";
import "./Address.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
import "./ECDSA.sol";

contract Validatecontract is ERC721, Ownable {
    using Strings for uint256;
    using SafeMath for uint256;
    using Counters for Counters.Counter;
    
    Counters.Counter private _tokenIdTracker;
    mapping (uint256 => string) private _tokenURIs;

    address private KoalaMintDevAddress = 0x28ce592CcA596E3030b9697420917470833231FF;
    address private CreatorAddress = 0xb2cd6BEdc7279dee2805631093B95C1efcdc8917;
    address private SignerAddress = 0x28ce592CcA596E3030b9697420917470833231FF;

    string private baseURIextended;
    uint256 private min_price = 0.03 ether;
    uint256 private feeUser = 0;
    uint256 private feeCreator = 5;
    uint256 private maxSupply = 10;

    bool private pause = false;

    event KoalaMintMinted(uint256 indexed tokenId, address owner, address to, string tokenURI);
    event KoalaMintTransfered(address to, uint value);

    constructor(string memory _baseURIextended) ERC721("VALIDATECONTRACT", "VALIDCONTRACT"){
        baseURIextended = _baseURIextended;
    }
    
    function _setTokenURI(uint256 tokenId, string memory _tokenURI) internal virtual {
        require(_exists(tokenId), "URI set of nonexistent token");
        _tokenURIs[tokenId] = _tokenURI;
    }

    function _setSignerAddress(address _signerAddress) public onlyOwner {
        SignerAddress = _signerAddress;
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
    
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "URI query for nonexistent token");

        string memory _tokenURI = _tokenURIs[tokenId];
        string memory base = _baseURI();

        return string(abi.encodePacked(base, _tokenURI));
    }

    function signatureSignerMint(address _to, string memory _tokenURI, uint256 _timestamp, uint8 v, bytes32 r, bytes32 s) public view virtual returns (address){
        return ECDSA.recover(keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", keccak256(abi.encode(_to, _tokenURI, _timestamp)))), v, r, s);
    }

    function mint(address _to, string[] memory _tokensURI, uint256 _timestamp, uint8 v, bytes32 r, bytes32 s) public payable {
        require(!pause, "Sales paused");
        require(msg.value >= min_price.mul(_tokensURI.length), "Value below price");
        require(maxSupply >= _tokenIdTracker.current() + _tokensURI.length, "SoldOut");
        require(_tokensURI.length > 0, "Minimum count");

        address signerMint = signatureSignerMint(_to, _tokensURI[0], _timestamp, v, r, s);
        require(signerMint == SignerAddress, "Not authorized to mint");

        require(_timestamp >= block.timestamp - 300, "Out of time");

        for (uint8 i = 0; i < _tokensURI.length; i++){
            _mintAnElement(_to, _tokensURI[i]);
        }
        
        uint256 _total = msg.value;

        if (feeUser > 0){
            uint256 _feeUser = _total.div(1 + (100 / feeUser));
            _total = _total - _feeUser;
            transfer(KoalaMintDevAddress, _feeUser);
        }

        if (feeCreator > 0){
            uint256 _feeCreator = _total.mul(feeCreator).div(100);
            _total = _total - _feeCreator;
            transfer(KoalaMintDevAddress, _feeCreator);
        }
        
        transfer(CreatorAddress, _total);
    }

    function _mintAnElement(address _to, string memory _tokenURI) private {
        uint256 _tokenId = _tokenIdTracker.current();
        
        _tokenIdTracker.increment();
        _tokenId = _tokenId + 1;
        _safeMint(_to, _tokenId);
        _setTokenURI(_tokenId, _tokenURI);

        emit KoalaMintMinted(_tokenId, CreatorAddress, _to, _tokenURI);
    }

    function transfer(address to, uint256 value) private {
        (bool success, ) = to.call{value: value}("");
        require(success, "Transfer failed.");
        emit KoalaMintTransfered(to, value);
    }
}