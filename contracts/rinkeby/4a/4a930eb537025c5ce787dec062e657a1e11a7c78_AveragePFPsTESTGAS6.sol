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

contract AveragePFPsTESTGAS6 is ERC721, Ownable, ReentrancyGuard {

  using Strings for uint256;
  using Counters for Counters.Counter;
  Counters.Counter private supply;

  string public uriPrefix = "";
  string public uriSuffix = ".json";
  uint256 public maxSupply;
  uint256[40] claimedBitMap;
  bool public claimActive;

  address t1 = 0x4C3fF79be13C8974A3c2FB2d410Ad61f13a2A5D5;

  // Average Creatures Contract
  CollectionContract private _avgcreatures = CollectionContract(0xbFEdBb9c6DFaD7Ebd105287A8286ce36001b2B27);

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

    // Get PFPs
    function claimDrop() external nonReentrant {
        require(_avgcreatures.balanceOf(msg.sender) > 0, "No Creatures found on this wallet.");
        // require(claimActive, "PFP Claim is paused.");
        _mintLoop(msg.sender, _avgcreatures.walletOfOwner(msg.sender));
    }

    // Froot Loops
    function _mintLoop(address _receiver, uint256[] memory _mintArray) internal {
      for (uint256 i; i < _mintArray.length; i++) {
        if (!isClaimed(_mintArray[i])) {
          _setClaimed(_mintArray[i]);
          supply.increment();
          _safeMint(_receiver, supply.current());
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