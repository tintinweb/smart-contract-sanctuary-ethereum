// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./ERC721A.sol";
import "./Strings.sol";
import "./MerkleProof.sol";

contract Main is Ownable, ERC721A, ReentrancyGuard {

  using MerkleProof for bytes32[];

  uint256 public  maxPerAddressDuringMint;

  bytes32 private _merkleRoot;

  constructor(
    string memory _name,
    string memory _symbol,
    uint256 maxBatchSize_,
    uint256 collectionSize_,
    bytes32 merkleRoot,
    string memory _initBaseURI,
    string memory _notRevealedUri
  ) ERC721A(_name, _symbol, maxBatchSize_, collectionSize_,_initBaseURI,_notRevealedUri) {
    maxPerAddressDuringMint = maxBatchSize_;
    _merkleRoot = merkleRoot;
  }

  modifier callerIsUser() {
    require(tx.origin == msg.sender, "The caller is another contract");
    _;
  }

  modifier isNotPaused() {
    require(!isPaused,"Sorry minting is paused");
    _;
  }

  function mint(uint256 quantity, bytes32[] memory _proof)
    external
    payable
    callerIsUser
    isNotPaused
  {
    require(quantity > 0, "Mint amount should be greater than zero");
    require(quantity <= maxBatchSize, "ERC721A: quantity to mint too high");
    require(totalSupply() + quantity <= collectionSize, "reached max supply");
    require(
      numberMinted(msg.sender) + quantity <= maxPerAddressDuringMint,
      "can not mint this many"
    );
    require(msg.value == _cost * quantity, "Must send more ETH");
    if(onlyWhitelisted == true){
      isAllowedToMint(_proof);
    }
    _safeMint(msg.sender, quantity);
  }

  // For marketing etc.
  function adminMint(uint256 quantity) external onlyOwner {
    require(totalSupply() + quantity <= collectionSize, "reached max supply");
    require(
      quantity % maxBatchSize == 0,
      "can only mint a multiple of the maxBatchSize"
    );
    uint256 numChunks = quantity / maxBatchSize;
    for (uint256 i = 0; i < numChunks; i++) {
      _safeMint(msg.sender, maxBatchSize);
    }
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return _baseTokenURI;
  }

  function setBaseURI(string calldata baseURI) external onlyOwner {
    _baseTokenURI = baseURI;
  }

  function changeMerkleRoot(bytes32 merkleRoot)
        public
        onlyOwner
    {
      require(_merkleRoot != merkleRoot,"Save gas , U are using the current Root");
        _merkleRoot = merkleRoot;
    }



  function isAllowedToMint(bytes32[] memory _proof) internal view returns (bool) {
        require(
            MerkleProof.verify(_proof, _merkleRoot, keccak256(abi.encodePacked(msg.sender))),
            "Caller is not whitelisted for Presale"
               );
        return true;
    }

  
  function setOnlyWhitelisted(bool _state) public onlyOwner {
    require(onlyWhitelisted != _state,"Save gas , whitelist cannot have the same value");
    onlyWhitelisted = _state;
  }

  function withdrawMoney() external onlyOwner nonReentrant {
    (bool success, ) = msg.sender.call{value: address(this).balance}("");
    require(success, "Transfer failed.");
  }

  function setOwnersExplicit(uint256 quantity) external onlyOwner nonReentrant {
    _setOwnersExplicit(quantity);
  }

  function numberMinted(address owner) public view returns (uint256) {
    return _numberMinted(owner);
  }

   function setCost(uint256 _newCost) public onlyOwner {
     require(_cost != _newCost,"Save gas , Change cost from current value");
    _cost = _newCost;
  }

  function reveal() public onlyOwner {
      revealed = true;
  }

  function setNotRevealedURI(string memory _notRevealedURI) public onlyOwner {
    notRevealedUri = _notRevealedURI;
  }

  function setPause(bool status) external onlyOwner {
    require(isPaused != status,"Cannot change to the same status");
    isPaused = status;
  }

  function getOwnershipData(uint256 tokenId)
    external
    view
    returns (TokenOwnership memory)
  {
    return ownershipOf(tokenId);
  }
}