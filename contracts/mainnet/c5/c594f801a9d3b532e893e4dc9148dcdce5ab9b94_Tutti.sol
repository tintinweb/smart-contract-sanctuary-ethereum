// SPDX-License-Identifier: MIT
/*

███████╗██████╗ ██╗   ██╗████████╗██╗███████╗   
██╔════╝██╔══██╗██║   ██║╚══██╔══╝██║╚══███╔╝
█████╗  ██████╔╝██║   ██║   ██║   ██║  ███╔╝ 
██╔══╝  ██╔══██╗██║   ██║   ██║   ██║ ███╔╝  
██║     ██║  ██║╚██████╔╝   ██║   ██║███████╗
╚═╝     ╚═╝  ╚═╝ ╚═════╝    ╚═╝   ╚═╝╚══════╝   
⠀⠀⠀⠀⠀⢀⡀⠀⠀⠀⠀⠀⡄⠀⠀⠀⠀⢀⠀⠀
⠀⠀⠀⠀⠀⠀⣏⠓⠒⠤⣰⠋⠹⡄⠀⣠⠞⣿⠀⠀
⠀⠀⠀⢀⠄⠂⠙⢦⡀⠐⠨⣆⠁⣷⣮⠖⠋⠉⠁⠀
⠀⠀⡰⠁⠀⠮⠇⠀⣩⠶⠒⠾⣿⡯⡋⠩⡓⢦⣀⡀
⠀⡰⢰⡹⠀⠀⠲⣾⣁⣀⣤⠞⢧⡈⢊⢲⠶⠶⠛⠁
⢀⠃⠀⠀⠀⣌⡅⠀⢀⡀⠀⠀⣈⠻⠦⣤⣿⡀⠀⠀
⠸⣎⠇⠀⠀⡠⡄⠀⠷⠎⠀⠐⡶⠁⠀⠀⣟⡇⠀⠀
⡇⠀⡠⣄⠀⠷⠃⠀⠀⡤⠄⠀⠀⣔⡰⠀⢩⠇⠀⠀
⡇⠀⠻⠋⠀⢀⠤⠀⠈⠛⠁⠀⢀⠉⠁⣠⠏⠀⠀⠀
⣷⢰⢢⠀⠀⠘⠚⠀⢰⣂⠆⠰⢥⡡⠞⠁⠀⠀⠀⠀
⠸⣎⠋⢠⢢⠀⢠⢀⠀⠀⣠⠴⠋⠀⠀⠀⠀⠀⠀⠀
⠀⠘⠷⣬⣅⣀⣬⡷⠖⠋⠁⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠈⠁⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀                                                                                  
*/
pragma solidity >= 0.8 .9 < 0.9 .0;

import './ERC721AQueryable.sol';
import './Ownable.sol';
import './ReentrancyGuard.sol';
import './SignedTokenVerifier.sol';
import './Pausable.sol';

contract Tutti is ERC721AQueryable, Ownable, ReentrancyGuard, SignedTokenVerifier, Pausable {
  using Strings for uint256;

  string public uriPrefix = '';
  uint256 public cost = 0.2 ether;
  uint256 public maxSupply = 111;

  uint256 public maxMintAmountPerTx = 1;
  bool public revealed = false;
  string public hiddenMetadataUri = "https://ipfs.io/ipfs/QmUm8NCYFfwxXX8r7YuFEGGZyrxNQarJ2zRKikfXoA1aW5";
  mapping(string => bool) public minted;

  string private uriSuffix = '.json';
  uint256 private orders = 111;
  event Minted(address owner, string email);

  constructor(address _signer) ERC721A("Tutti", "TF") {
    _setSigner(_signer);
  }

  modifier mintCompliance(uint256 _mintAmount) {
    require(_mintAmount > 0 && _mintAmount <= maxMintAmountPerTx, 'Invalid mint amount!');
    require(totalSupply() + _mintAmount <= maxSupply - orders, 'Max supply exceeded!');
    _;
  }

  modifier mintPriceCompliance(uint256 _mintAmount) {
    require(msg.value >= cost * _mintAmount, 'Insufficient funds!');
    _;
  }

  function mint(uint256 _mintAmount, string memory _email) public payable mintCompliance(_mintAmount) mintPriceCompliance(_mintAmount) whenNotPaused {
    _safeMint(_msgSender(), _mintAmount);
    emit Minted(_msgSender(), _email);
  }

  function freeMint(uint256 _amount, bytes calldata _token, string calldata _email, string calldata _salt) public nonReentrant {
    require(totalSupply() + _amount <= maxSupply, 'Max supply exceeded!');
    require(verifyTokenForAddress(_salt, _email, _amount, _token, msg.sender), "Unauthorized");
    require(!minted[_email], "Token already minted!");
    _safeMint(msg.sender, _amount);
    minted[_email] = true;
  }

  function teamMint(uint256 _teamAmount) external onlyOwner {
    require(totalSupply() + _teamAmount <= maxSupply - orders, 'Max supply exceeded!');
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

    if (revealed == false) {
      return hiddenMetadataUri;
    }

    string memory currentBaseURI = _baseURI();
    return bytes(currentBaseURI).length > 0 ?
      string(abi.encodePacked(currentBaseURI, _tokenId.toString(), uriSuffix)) :
      '';
  }

  function setRevealed(bool _state) public onlyOwner {
    revealed = _state;
  }

  function setCost(uint256 _cost) public onlyOwner {
    cost = _cost;
  }

  function setMaxMintAmountPerTx(uint256 _maxMintAmountPerTx) public onlyOwner {
    maxMintAmountPerTx = _maxMintAmountPerTx;
  }

  function setOrders(uint256 _orders) public onlyOwner {
    orders = _orders;
  }

  function setMaxSupply(uint256 _maxSupply) public onlyOwner {
    maxSupply = _maxSupply;
  }

  function setHiddenMetadataUri(string memory _hiddenMetadataUri) public onlyOwner {
    hiddenMetadataUri = _hiddenMetadataUri;
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