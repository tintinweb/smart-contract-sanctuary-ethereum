// SPDX-License-Identifier: MIT

/*
Average Creatures PFPs.
*/

pragma solidity >=0.8.9 <0.9.0;

import "./ERC721.sol";
import "./Counters.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";

abstract contract CollectionContract {
   function balanceOf(address owner) external virtual view returns (uint256 balance);
   function walletOfOwner(address _owner) public virtual view returns (uint256[] memory);
   function ownerOf(uint256 tokenId) public virtual view returns (address tokenOwner);
}

contract AveragePFPs is ERC721, Ownable, ReentrancyGuard {

  using Strings for uint256;
  using Counters for Counters.Counter;
  Counters.Counter private supply;

  string public uriPrefix = "";
  string public uriSuffix = ".json";
  uint256 public maxSupply;
  uint256[40] claimedBitMap;
  bool public claimActive;

  address t1 = 0xdF0bb728394E96F202E4D3607D19fC7b826eB272;

  // Average Creatures Contract
  CollectionContract private _avgcreatures = CollectionContract(0xbB00B6B675b9a8Db9aA3b68Bf0aAc5e25f901656);

  constructor(
    string memory _tokenName,
    string memory _tokenSymbol,
    uint256 _maxSupply
  ) ERC721(_tokenName, _tokenSymbol) {
    maxSupply = _maxSupply;
  }

    function totalSupply() public view returns (uint256) {
        return supply.current();
    }

    // Open the doors
    function setClaimActive(bool claimActive_) public onlyOwner {
        claimActive = claimActive_;
    }

    // Check Claimed List
    function isClaimed(uint256 tokenId) public view returns (bool) {
        uint256 claimedWordIndex = tokenId / 256;
        uint256 claimedBitIndex = tokenId % 256;
        uint256 claimedWord = claimedBitMap[claimedWordIndex];
        uint256 mask = (1 << claimedBitIndex);
        return claimedWord & mask == mask;
    }

    // Claimed list
    function _setClaimed(uint256 tokenId) internal {
        uint256 claimedWordIndex = tokenId / 256;
        uint256 claimedBitIndex = tokenId % 256;
        claimedBitMap[claimedWordIndex] = claimedBitMap[claimedWordIndex] | (1 << claimedBitIndex);
    }

    function readAvgTokens(address _target) public view returns (uint256[] memory) {
      return _avgcreatures.walletOfOwner(_target);
    }

    // Claim a single PFP by sending a TokenID, only owner can call it
    function claimSingle(uint256 tokenid) external nonReentrant {
      require(_avgcreatures.balanceOf(msg.sender) > 0, "No Creatures found on this wallet.");
      require(_avgcreatures.ownerOf(tokenid) == msg.sender, "Token doesn't belong to wallet.");
      require(claimActive, "PFP Claim is paused.");
      if (!isClaimed(tokenid)) {
          supply.increment();
          _safeMint(msg.sender, tokenid);
          _setClaimed(tokenid);
        } 
    }

    // Claim many PFPs with a Token array (1,2,3...), only owner can call it
    function claimMany(uint256[] memory _mintArray) external nonReentrant {
      require(_avgcreatures.balanceOf(msg.sender) > 0, "No Creatures found on this wallet.");
      require(claimActive, "PFP Claim is paused.");
      for (uint256 i = 0; i <_mintArray.length; i++) {
        if (!isClaimed(_mintArray[i]) && _avgcreatures.ownerOf(_mintArray[i]) == msg.sender) {
          supply.increment();
          _safeMint(msg.sender, _mintArray[i]);
          _setClaimed(_mintArray[i]);
        } 
      }
    }

    // Our 7th District Judge will help
    function smallClaimsCourt(address _receiver, uint256 avgid) public onlyOwner {
        require(_avgcreatures.ownerOf(avgid) == _receiver, "Token doesn't belong to wallet.");
        if (!isClaimed(avgid)) {
          supply.increment();
          _safeMint(_receiver, avgid);
          _setClaimed(avgid);
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

    // Pre
    function setUriPrefix(string memory _uriPrefix) public onlyOwner {
      uriPrefix = _uriPrefix;
    }
    // Not Pre
    function setUriSuffix(string memory _uriSuffix) public onlyOwner {
      uriSuffix = _uriSuffix;
    }

    // Read URI
    function _baseURI() internal view virtual override returns (string memory) {
      return uriPrefix;
    }

    // To avoid happy accidents in Average Town
    function withdraw() public onlyOwner nonReentrant {
    require(payable(t1).send(address(this).balance));
  }
}