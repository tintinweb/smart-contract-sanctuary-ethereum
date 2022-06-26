// SPDX-License-Identifier: MIT

/*
Average Creatures - AD1
*/

pragma solidity >=0.8.9 <0.9.0;

import "./ERC721.sol";
import "./Counters.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";

abstract contract CollectionContract {
   function balanceOf(address owner) external virtual view returns (uint256 balance);
   function walletOfOwner(address owner) public virtual view returns (uint256[] memory);
}

contract AverageAirDrop is ERC721, Ownable, ReentrancyGuard {

  using Strings for uint256;
  using Counters for Counters.Counter;

  Counters.Counter private supply;
  mapping(address => bool) public walletClaimed;

  string public uriPrefix = "";
  string public uriSuffix = ".json";
  uint256 public cost;
  uint256 public maxSupply;
  uint256[40] claimedBitMap;
  bool public claimActive;

  CollectionContract private _avgcreatures = CollectionContract(0xbFEdBb9c6DFaD7Ebd105287A8286ce36001b2B27);

  constructor(
    string memory _tokenName,
    string memory _tokenSymbol,
    uint256 _cost,
    uint256 _maxSupply
  ) ERC721(_tokenName, _tokenSymbol) {
    cost = _cost;
    maxSupply = _maxSupply;
  }

    function totalSupply() public view returns (uint256) {
        return supply.current();
    }

    function setClaimActive(bool claimActive_) public onlyOwner {
        claimActive = claimActive_;
    }

    function isClaimed(uint256 tokenId) public view returns (bool) {
        uint256 claimedWordIndex = tokenId / 256;
        uint256 claimedBitIndex = tokenId % 256;
        uint256 claimedWord = claimedBitMap[claimedWordIndex];
        uint256 mask = (1 << claimedBitIndex);
        return claimedWord & mask == mask;
    }

    function _setClaimed(uint256 tokenId) internal {
        uint256 claimedWordIndex = tokenId / 256;
        uint256 claimedBitIndex = tokenId % 256;
        claimedBitMap[claimedWordIndex] = claimedBitMap[claimedWordIndex] | (1 << claimedBitIndex);
    }

    function claimPFPs() external nonReentrant {
        require(_avgcreatures.balanceOf(msg.sender) > 0, "No Creatures found on this wallet.");
        // require(claimActive, "Average AirDrop is paused.");
        
        // for (uint256 i; i < _avgcreatures.balanceOf(msg.sender); i++) {
        //   uint256 currentToken = _avgcreatures.walletOfOwner(msg.sender)[i];
        //   if (!isClaimed(currentToken)) {
        //     _safeMint(msg.sender, currentToken);
        //     _setClaimed(currentToken);
        //   }
        // }
        _mintLoop(msg.sender, _avgcreatures.walletOfOwner(msg.sender));
    }

  function _mintLoop(address _receiver, uint256[] memory _mintArray) internal {
    for (uint256 i = 0; i < _mintArray.length; i++) {
      if (!isClaimed(_mintArray[i])) {
        supply.increment();
        _safeMint(_receiver, _mintArray[i]);
        _setClaimed(_mintArray[i]);  
      }
    }
  }

  function walletOfOwner(address _owner)
    public
    view
    returns (uint256[] memory)
  {
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

  function tokenURI(uint256 _tokenId)
    public
    view
    virtual
    override
    returns (string memory)
  {
    require(
      _exists(_tokenId),
      "ERC721Metadata: URI query for nonexistent token"
    );

    string memory currentBaseURI = _baseURI();
    return bytes(currentBaseURI).length > 0
        ? string(abi.encodePacked(currentBaseURI, _tokenId.toString(), uriSuffix))
        : "";
  }

  function setCost(uint256 _cost) public onlyOwner {
    cost = _cost;
  }

  function setUriPrefix(string memory _uriPrefix) public onlyOwner {
    uriPrefix = _uriPrefix;
  }

  function setUriSuffix(string memory _uriSuffix) public onlyOwner {
    uriSuffix = _uriSuffix;
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return uriPrefix;
  }
}