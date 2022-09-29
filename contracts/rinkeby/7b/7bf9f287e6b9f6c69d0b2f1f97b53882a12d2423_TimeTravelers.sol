// SPDX-License-Identifier: MIT
/*
.___________. __  .___  ___.  _______                                                                
|           ||  | |   \/   | |   ____|                                                               
`---|  |----`|  | |  \  /  | |  |__                                                                  
    |  |     |  | |  |\/|  | |   __|                                                                 
    |  |     |  | |  |  |  | |  |____                                                                
    |__|     |__| |__|  |__| |_______|                                                               
                                                                                                     
.___________..______          ___   ____    ____  _______  __       _______ .______          _______.
|           ||   _  \        /   \  \   \  /   / |   ____||  |     |   ____||   _  \        /       |
`---|  |----`|  |_)  |      /  ^  \  \   \/   /  |  |__   |  |     |  |__   |  |_)  |      |   (----`
    |  |     |      /      /  /_\  \  \      /   |   __|  |  |     |   __|  |      /        \   \    
    |  |     |  |\  \----./  _____  \  \    /    |  |____ |  `----.|  |____ |  |\  \----.----)   |   
    |__|     | _| `._____/__/     \__\  \__/     |_______||_______||_______|| _| `._____|_______/    ⠀⠀⠀⠀⠀⠀                                                                                  
*/
pragma solidity >= 0.8 .9 < 0.9 .0;

import './ERC721AQueryable.sol';
import './Ownable.sol';
import './ReentrancyGuard.sol';
import './SignedTokenVerifier.sol';
import './Pausable.sol';

contract TimeTravelers is ERC721AQueryable, Ownable, ReentrancyGuard, SignedTokenVerifier, Pausable {
  using Strings for uint256;

  string public uriPrefix = '';
  uint256 public cost = 0.06 ether;
  uint256 public maxSupply = 222;

  mapping(address => bool) public minted;
  string private uriSuffix = '.json';

  constructor(address _signer) ERC721A("TimeTravelers", "TT") {
    _setSigner(_signer);
  }

  modifier mintCompliance(uint256 _mintAmount) {
    require(totalSupply() + _mintAmount <= maxSupply, 'Max supply exceeded!');
    _;
  }

  modifier mintPriceCompliance(uint256 _mintAmount) {
    require(msg.value >= cost * _mintAmount, 'Insufficient funds!');
    _;
  }

  function mint() public payable mintCompliance(1) mintPriceCompliance(1) whenNotPaused {
    _safeMint(_msgSender(), 1);
  }

  function whitelistMint(bytes calldata _token, string calldata _salt) public payable mintCompliance(1) mintPriceCompliance(1) nonReentrant {
    require(verifyTokenForAddress(_salt, _token, msg.sender), "Unauthorized");
    require(!minted[msg.sender], "Token already minted!");
    _safeMint(msg.sender, 1);
    minted[msg.sender] = true;
  }

  function teamMint(uint256 _teamAmount) external onlyOwner {
    require(totalSupply() + _teamAmount <= maxSupply, 'Max supply exceeded!');
    _safeMint(_msgSender(), _teamAmount);
  }

  function airdrop(uint256 _mintAmount, address _receiver) public mintCompliance(_mintAmount) onlyOwner {
    _safeMint(_receiver, _mintAmount);
  }

  function airdrops(address[] memory _addresses) public onlyOwner {
    for (uint i = 0; i < _addresses.length; i++) {
      airdrop(1, _addresses[i]);
    }
  }

  function tokenURI(uint256 _tokenId) public view virtual override returns(string memory) {
    require(_exists(_tokenId), 'ERC721Metadata: URI query for nonexistent token');

    string memory currentBaseURI = _baseURI();
    return bytes(currentBaseURI).length > 0 ?
      string(abi.encodePacked(currentBaseURI, _tokenId.toString(), uriSuffix)) :
      '';
  }

  function setCost(uint256 _cost) public onlyOwner {
    cost = _cost;
  }

  function setMaxSupply(uint256 _maxSupply) public onlyOwner {
    maxSupply = _maxSupply;
  }

  function setUriSuffix(string memory _uriSuffix) public onlyOwner {
    uriSuffix = _uriSuffix;
  }

  function setUriPrefix(string memory _uriPrefix) public onlyOwner {
    uriPrefix = _uriPrefix;
  }

  function withdraw() public onlyOwner nonReentrant {
    (bool os, ) = payable(owner()).call {value: address(this).balance}('');
    require(os);
  }

  function _baseURI() internal view virtual override returns(string memory) {
    return uriPrefix;
  }

  function _startTokenId() internal view virtual override returns(uint256) {
    return 1;
  }
}