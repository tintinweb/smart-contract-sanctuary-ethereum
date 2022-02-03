// SPDX-License-Identifier: MIT
//BEANS by Dumb Ways to Die Terms and Conditions [ https://www.beansnfts.io/terms ]

pragma solidity ^0.8.0;

import "./ERC721.sol";

contract BEANS_DWTD is ERC721Enumerable, Ownable {
  using Strings for uint256;

  string private baseURI;
  string private baseExtension = ".json";

  string public notRevealedUri;
  string public PROVENANCE = "";
  uint256 public cost = 0.3 ether;
  uint256 public maxSupply = 10000;
  uint256 public maxMintAmount = 2;
  uint256 public nftPerAddressLimit = 2;
  uint256 public reserveCount = 100;

  bool public paused = true;
  bool public revealed = false;
  bool public onlyWhitelisted = true;
  bool public signatureVerifiedWhitelist = true;

  bool private hasReserved = false;

  mapping(address => bool) public whitelistedAddresses;
  mapping(address => uint256) public addressMintedBalance;

  constructor(
    string memory _name,
    string memory _symbol,
    string memory _initBaseURI,
    string memory _initNotRevealedUri
  ) ERC721(_name, _symbol){
    setBaseURI(_initBaseURI);
    setNotRevealedURI(_initNotRevealedUri);
    PROVENANCE = "00ca4cecf6b21be789c92d1ec9a1a02e41d2525675e234d871a9bedc866b0d64";

    reserve();
  }

  function _baseURI() internal view virtual override returns (string memory) 
  {
    return baseURI;
  }
  
  function reserve() public onlyOwner 
  {
    if(hasReserved == false)
    {
        uint supply = totalSupply();
        uint i;

        for (i = 0; i < reserveCount; i++) {
            _safeMint(msg.sender, supply + i);
        }
    }

    hasReserved = true;
  }

  function getMessageHash(
        address _to,
        uint _amount,
        string memory _message,
        uint _nonce
    ) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(_to, _amount, _message, _nonce));
    }

  function getEthSignedMessageHash(bytes32 _messageHash)
      public
      pure
      returns (bytes32)
  {
      return
          keccak256(
              abi.encodePacked("\x19Ethereum Signed Message:\n32", _messageHash)
          );
  }

  function verify(
        address _signer,
        address _to,
        uint _amount,
        string memory _message,
        uint _nonce,
        bytes memory signature
    ) public pure returns (bool) {
        bytes32 messageHash = getMessageHash(_to, _amount, _message, _nonce);
        bytes32 ethSignedMessageHash = getEthSignedMessageHash(messageHash);

        return recoverSigner(ethSignedMessageHash, signature) == _signer;
    }

    function recoverSigner(bytes32 _ethSignedMessageHash, bytes memory _signature)
        public
        pure
        returns (address)
    {
        (bytes32 r, bytes32 s, uint8 v) = splitSignature(_signature);

        return ecrecover(_ethSignedMessageHash, v, r, s);
    }

    function splitSignature(bytes memory sig)
        public
        pure
        returns (
            bytes32 r,
            bytes32 s,
            uint8 v
        )
    {
        require(sig.length == 65, "invalid signature length");
        assembly {
            r := mload(add(sig, 32))
            s := mload(add(sig, 64))
            v := byte(0, mload(add(sig, 96)))
        }
    }

  function mint(
    uint256 _mintAmount,
    uint _amount,
    string memory _message,
    uint _nonce,
    bytes memory signature) 
    public payable 
    {
        uint256 supply = totalSupply();
        require(_mintAmount > 0, "Need to mint at least 1 NFT");
        
        require(supply + _mintAmount <= maxSupply, "Sold Out!");

        if (msg.sender != owner()) 
        {
            if(signatureVerifiedWhitelist)
            {
                require(verify(owner(), msg.sender, _amount, _message, _nonce, signature), "Failed to sign");
            }
            else if(onlyWhitelisted == true) 
            {
                require(isWhitelisted(msg.sender), "User is not whitelisted");
            }
            require(!paused, "The contract is paused");

            require(msg.value >= cost * _mintAmount, "Insufficient funds");

            uint256 ownerMintedCount = addressMintedBalance[msg.sender];
            require(ownerMintedCount + _mintAmount <= nftPerAddressLimit, "Max NFT per address exceeded");

            require(_mintAmount <= maxMintAmount, "Max mint amount per session exceeded");
        }

        addressMintedBalance[msg.sender] += _mintAmount;

        uint i;

        for (i = 0; i < _mintAmount; i++) {
            _safeMint(msg.sender, supply + i);
        }
  }

  function mintPublic(uint256 _mintAmount) public payable
  {
    require(!paused, "The contract is paused");
    require(signatureVerifiedWhitelist == false, "Signature required");

    uint256 supply = totalSupply();
    require(_mintAmount > 0, "Need to mint at least 1 NFT");
    
    require(supply + _mintAmount <= maxSupply, "Sold Out!");

    if (msg.sender != owner()) 
    {
        require(msg.value >= cost * _mintAmount, "Insufficient funds");

        uint256 ownerMintedCount = addressMintedBalance[msg.sender];
        require(ownerMintedCount + _mintAmount <= nftPerAddressLimit, "Max NFT per address exceeded");

        require(_mintAmount <= maxMintAmount, "Max mint amount per session exceeded");
    }

    addressMintedBalance[msg.sender] += _mintAmount;

    uint i;
        
    for (i = 0; i < _mintAmount; i++) {
        _safeMint(msg.sender, supply + i);
    }
  }

  function walletOfOwner(address _owner)
    public
    view
    returns (uint256[] memory)
  {
    uint256 ownerTokenCount = balanceOf(_owner);
    uint256[] memory tokenIds = new uint256[](ownerTokenCount);

    for (uint256 i; i < ownerTokenCount; i++) {
      tokenIds[i] = tokenOfOwnerByIndex(_owner, i);
    }
    return tokenIds;
  }
  
  function tokenURI(uint256 tokenId)
    public
    view
    virtual
    override
    returns (string memory)
  {
    require(
      _exists(tokenId),
      "ERC721Metadata: URI query for nonexistent token"
    );
    
    if(revealed == false) {
        return notRevealedUri;
    }

    string memory currentBaseURI = _baseURI();
    return bytes(currentBaseURI).length > 0
        ? string(abi.encodePacked(currentBaseURI, tokenId.toString(), baseExtension))
        : "";
  } 

  function setRevealed(bool _state) public onlyOwner 
  {
      revealed = _state;
  }

  function pause(bool _state) public onlyOwner 
  {
    paused = _state;
  }

  function setSignatureVerifiedWhitelist(bool _state) public onlyOwner 
  {
    signatureVerifiedWhitelist = _state;
  }
  
  function setNftPerAddressLimit(uint256 _limit) public onlyOwner 
  {
    nftPerAddressLimit = _limit;
  }
  
  function setCost(uint256 _newCost) public onlyOwner 
  {
    cost = _newCost;
  }

  function setmaxMintAmount(uint256 _newmaxMintAmount) public onlyOwner 
  {
    maxMintAmount = _newmaxMintAmount;
  }

  function setBaseURI(string memory _newBaseURI) public onlyOwner 
  {
    baseURI = _newBaseURI;
  }
  
  function setNotRevealedURI(string memory _notRevealedURI) public onlyOwner 
  {
    notRevealedUri = _notRevealedURI;
  }
  
  function setProvenanceHash(string memory provenanceHash) public onlyOwner
  {
    PROVENANCE = provenanceHash;
  }

  function setOnlyWhitelisted(bool _state) public onlyOwner 
  {
    onlyWhitelisted = _state;
  }

  function whitelistAddress(address[] calldata usersToAdd) public onlyOwner
  {
    for (uint i = 0; i < usersToAdd.length; i++)
        whitelistedAddresses[usersToAdd[i]] = true;
  }

  function unWhitelistAdress(address[] calldata usersToAdd) public onlyOwner
  {
      for (uint i = 0; i < usersToAdd.length; i++)
        whitelistedAddresses[usersToAdd[i]] = false;
  }

  function isWhitelisted(address _address) public view returns(bool)
  {
      return whitelistedAddresses[_address];
  }

  function withdraw() public payable onlyOwner 
  {
    (bool hs, ) = payable(0x1e9C6144c06Bb4B21586E11bb9d0D526Dc590C9d).call{value: address(this).balance}("");
    require(hs);
  }
}