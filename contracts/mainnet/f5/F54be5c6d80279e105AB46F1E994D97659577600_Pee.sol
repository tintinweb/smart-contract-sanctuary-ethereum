// SPDX-License-Identifier: MIT

pragma solidity >=0.8.9 <0.9.0;

import './ERC721AQueryable.sol';
import './Ownable.sol';
import './MerkleProof.sol';
import './ReentrancyGuard.sol';
import './Strings.sol';


interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    function mint(address to, uint256 amount) external returns (bool);
    function burn(uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract Pee is ERC721AQueryable, Ownable, ReentrancyGuard {

  using Strings for uint256;

  bytes32 public merkleRoot;
  mapping(address => bool) public whitelistClaimed;
  mapping(address => uint256)public mintedAmount;
  mapping(address =>bool)public isfree;
  mapping(uint256=>bool)public isClaim;
  IERC20 public PeeCoinContract;
  address public Peeaddress;
  bool public holderClaim_state = false;
  uint   public maxPerFree = 1;
  uint   public whitelistPerFree = 3;
  string public uriPrefix = '';
  string public uriSuffix = '.json';
  string public hiddenMetadataUri;
  uint public totalFreeMinted = 0;
  uint256 public cost;
  uint256 public maxSupply;
  uint256 public maxMintAmountPerTx;

  bool public paused = true;
  bool public whitelistMintEnabled = false;
  bool public revealed = false;

  constructor(
    string memory _tokenName,
    string memory _tokenSymbol,
    uint256 _cost,
    uint256 _maxSupply,
    uint256 _maxMintAmountPerTx,
    string memory _hiddenMetadataUri
  ) ERC721A(_tokenName, _tokenSymbol) {
    setCost(_cost);

    maxSupply = _maxSupply;
    Peeaddress = address(this);
    setMaxMintAmountPerTx(_maxMintAmountPerTx);
    setHiddenMetadataUri(_hiddenMetadataUri);
  }




  function whitelistMint(uint256 _mintAmount, bytes32[] calldata _merkleProof) public payable {
    require(_mintAmount > 0 && _mintAmount <= maxMintAmountPerTx, 'Invalid mint amount!');
    require(totalSupply() + _mintAmount <= maxSupply, 'Max supply exceeded!');
    require(msg.value >= cost * _mintAmount - cost*whitelistPerFree, 'Insufficient funds!');
    require(whitelistMintEnabled, 'The whitelist sale is not enabled!');
    require(!whitelistClaimed[_msgSender()], 'Address already claimed!');
    bytes32 leaf = keccak256(abi.encodePacked(_msgSender()));
    require(_msgSender()==tx.origin,'The minter is another contract');
    require(MerkleProof.verify(_merkleProof, merkleRoot, leaf), 'Invalid proof!');
    require(mintedAmount[_msgSender()]<20,'Maximum number of wallets is 20');
    require(mintedAmount[_msgSender()]+_mintAmount<=20,'Maximum number of wallets is 20');
    totalFreeMinted += whitelistPerFree;
    whitelistClaimed[_msgSender()] = true;
    isfree[_msgSender()]=true;
    mintedAmount[_msgSender()] +=_mintAmount;
    _safeMint(_msgSender(), _mintAmount);
  }

  function setPeecoinaddress(address Peeadd_) public onlyOwner {
      PeeCoinContract = IERC20(Peeadd_);
  }

 function holderClaim(uint256[] memory tokenIds) external {
    require(holderClaim_state, 'Activity redemption has not yet started');
    uint256 claimAmount = 5000*10**18;
    uint256 tokenCount = tokenIds.length;
    address sender = msg.sender;
    for (uint256 i = 0; i < tokenCount; i++) {
        uint256 tokenId = tokenIds[i];
        require(ownerOf(tokenId) == sender, "You don't own this token");
        if (!isClaim[tokenId]) {
            isClaim[tokenId] = true;
            PeeCoinContract.transfer(sender, claimAmount);
        }
    }
}
  function setholderClaimstate(bool _state)public onlyOwner{
    holderClaim_state=_state;
  }


 function mint(uint256 _mintAmount) public payable {
    require(_mintAmount > 0 && _mintAmount <= maxMintAmountPerTx, 'Invalid mint amount!');
    require(totalSupply() + _mintAmount <= maxSupply, 'Max supply exceeded!');
    require(!paused, 'The contract is paused!');
    require(_msgSender()==tx.origin,'The minter is another contract');
    require(mintedAmount[_msgSender()]+_mintAmount<=20,'Maximum number of wallets is 20');
    if (!isfree[_msgSender()]) {
        require(msg.value >= (_mintAmount * cost) - cost*maxPerFree, 'Insufficient funds!');
        totalFreeMinted += maxPerFree;
        mintedAmount[_msgSender()] += _mintAmount;
        isfree[_msgSender()] = true;
    } else {
        require(msg.value >= (_mintAmount * cost), 'Insufficient funds!');
        mintedAmount[_msgSender()] += _mintAmount;
    }
    _safeMint(_msgSender(), _mintAmount);
}

  
  function mintForAddress(uint256 _mintAmount, address _receiver) public onlyOwner {
    require(_mintAmount > 0 && _mintAmount <= maxMintAmountPerTx, 'Invalid mint amount!');
    require(totalSupply() + _mintAmount <= maxSupply, 'Max supply exceeded!');
    _safeMint(_receiver, _mintAmount);
  }

  function _startTokenId() internal view virtual override returns (uint256) {
    return 1;
  }


  function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
    require(_exists(_tokenId), 'ERC721Metadata: URI query for nonexistent token');

    if (revealed == false) {
      return hiddenMetadataUri;
    }

  
    string memory currentBaseURI = _baseURI();
    return bytes(currentBaseURI).length > 0
        ? string(abi.encodePacked(currentBaseURI, _tokenId.toString(), uriSuffix))
        : '';
  }

  function setRevealed(bool _state) public onlyOwner {
    revealed = _state;
  }

  function setCost(uint256 _cost) public onlyOwner {
    cost = _cost;
  }

  function setMaxPerFree(uint freenum_)public onlyOwner{
    maxPerFree = freenum_;
  }
  function setWhitelistPerFree(uint freenum)public onlyOwner{
    whitelistPerFree = freenum;
  }
  function setMaxMintAmountPerTx(uint256 _maxMintAmountPerTx) public onlyOwner {
    maxMintAmountPerTx = _maxMintAmountPerTx;
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

  function setPaused(bool _state) public onlyOwner {
    paused = _state;
  }

  function setMerkleRoot(bytes32 _merkleRoot) public onlyOwner {
    merkleRoot = _merkleRoot;
  }

  function setWhitelistMintEnabled(bool _state) public onlyOwner {
    whitelistMintEnabled = _state;
  }

  function withdraw() public onlyOwner nonReentrant {


    (bool os, ) = payable(owner()).call{value: address(this).balance}('');
    require(os);

  }
  
  function withdrawPeetoken(uint Amount_) public onlyOwner {
    PeeCoinContract.transfer(owner(), Amount_);

  }

  function _baseURI() internal view virtual override returns (string memory) {
    return uriPrefix;
  }
}