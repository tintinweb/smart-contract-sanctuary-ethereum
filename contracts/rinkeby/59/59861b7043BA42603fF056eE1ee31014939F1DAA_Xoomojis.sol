// SPDX-License-Identifier: GPL-3.0

// Amended by HashLips

pragma solidity >=0.7.0 <0.9.0;

import "../ERC721A.sol";
import "../Ownable.sol";
import "../ReentrancyGuard.sol";

contract Xoomojis is ERC721A, Ownable, ReentrancyGuard {
  using Strings for uint256;

  string public baseURI;
  string public baseExtension = ".json";
  string public notRevealedUri;
  uint256 internal cost = 0.04 ether;
  uint256 public maxSupply = 12500;
  uint256 public maxMintAmount = 10;
  uint256 public NftPerAddressLimit = 10;
  bool public paused = true;
  bool public revealed = false;
  bool public onlyWhitelisted = true;
  address[] public whitelistedAddresses;

  constructor() ERC721A("XMTest", "XM") {
    setNotRevealedURI("https://bafybeiblv4um2tcr4pxekf4qwkb3nfjwju4s4qhgr5bivazwyocy3ht6ha.ipfs.nftstorage.link/hidden_metadata/hidden.json");
  }

  // internal
  function _baseURI() internal view virtual override returns (string memory) {
    return baseURI;
  }

  function _startTokenId() internal pure override returns (uint256) {
        return 1;
    }

  function updateCost(uint256 _supply) internal pure returns (uint256 _cost){
      if(_supply < 1000) {
          return 0.04 ether;
      }
      if(_supply < 2000) {
          return 0.06 ether;
      }
      if(_supply < 3000) {
          return 0.08 ether;
      }
      if(_supply < 4000) {
          return 0.10 ether;
      }
      if(_supply < 5000) {
          return 0.12 ether;
      }
      if(_supply < 6000) {
          return 0.14 ether;
      }
      if(_supply < 7000) {
          return 0.16 ether;
      }
      if(_supply < 8000) {
          return 0.18 ether;
      }
      if(_supply < 9000) {
          return 0.20 ether;
      }
      if(_supply < 10000) {
          return 0.22 ether;
      }
      if(_supply < 11000) {
          return 0.24 ether;
      }
      else {
          return 0.26 ether;
      }
  }

  modifier mintCompliance(uint256 _mintAmount) {
    require(_mintAmount > 0 && _mintAmount <= maxMintAmount, 'Invalid mint amount!');
    require(totalSupply() + _mintAmount <= maxSupply, 'Max supply exceeded!');
    _;
  }

  // public
  function mint(uint256 _mintAmount) external payable mintCompliance(_mintAmount) {
    require(!paused, "All sales are on pause");
    uint256 supply = totalSupply();

    if (msg.sender != owner()) {
        if(onlyWhitelisted == true) {
            require(isWhitelisted(msg.sender), "User is not whitelisted");
            uint256 ownerTokenCount = balanceOf(msg.sender);
            require(ownerTokenCount < NftPerAddressLimit, "Whitelisted mint limit reached");
        }
          require(msg.value >= updateCost(supply) * _mintAmount, "Insufficient funds");
    }

    _safeMint(_msgSender(), _mintAmount);
  }

    function isWhitelisted(address _user) public view returns (bool) {
        for(uint256 i = 0; i < whitelistedAddresses.length; i++) {
            if (whitelistedAddresses[i] == _user) {
                return true;
            }
        }
        return false;
    }

  function mintForAddress(uint256 _mintAmount, address _receiver) external mintCompliance(_mintAmount) onlyOwner {
    _safeMint(_receiver, _mintAmount);
  }

    function walletOfOwner(address _owner) public view returns (uint256[] memory) {
        uint256 ownerTokenCount = balanceOf(_owner);
        uint256[] memory ownedTokenIds = new uint256[](ownerTokenCount);
        uint256 currentTokenId = 1;
        uint256 ownedTokenIndex = 0;

        while (ownedTokenIndex < ownerTokenCount && currentTokenId <= maxSupply) {
            address currentTokenOwner = ownerOf(currentTokenId);

            if (currentTokenOwner == _owner) {
                ownedTokenIds[ownedTokenIndex] = currentTokenId;

                ownedTokenIndex++;
            }

            currentTokenId++;
        }

        return ownedTokenIds;
    }

  function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
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

  //only owner
  function reveal() public onlyOwner {
      revealed = true;
  }
  
  function setNftPerAddressLimit(uint256 _limit) external onlyOwner {
    NftPerAddressLimit = _limit;
  }

  function setCost(uint256 _newCost) external onlyOwner {
    cost = _newCost;
  }

  function setmaxMintAmount(uint256 _newmaxMintAmount) external onlyOwner {
    maxMintAmount = _newmaxMintAmount;
  }
  
  function setNotRevealedURI(string memory _notRevealedURI) public onlyOwner {
    notRevealedUri = _notRevealedURI;
  }

  function setBaseURI(string memory _newBaseURI) public onlyOwner {
    baseURI = _newBaseURI;
  }

  function setBaseExtension(string memory _newBaseExtension) public onlyOwner {
    baseExtension = _newBaseExtension;
  }

  function setOnlyWhitelisted(bool _state) external onlyOwner {
    onlyWhitelisted = _state;
  }
 
  function pause(bool _state) external onlyOwner {
    paused = _state;
  }
 
 function whitelistUsers(address [] calldata _users) external onlyOwner {
     delete whitelistedAddresses;
     whitelistedAddresses = _users;
  }

  function withdraw() external onlyOwner nonReentrant {
    (bool os, ) = payable(owner()).call{value: address(this).balance}('');
    require(os);
  }

}