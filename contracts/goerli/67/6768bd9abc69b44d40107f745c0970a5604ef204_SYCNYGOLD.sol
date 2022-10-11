// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./Ownable.sol";
import "./IERC20.sol";

contract SYCNYGOLD is ERC721, Ownable {
  using Strings for uint256;

  string public baseURI;
  string public baseExtension = ".json";
  uint256 public totalSupply = 0;
  uint256 public maxSupply = 50;
  uint256 public price = 4500 ether;
  bool public paused = false;
  bool public burnable = false;
  uint256 public constant endStakeTimestamp = 1733011200;
  uint256 public constant endClaimTimestamp = 1764547200;
  IERC20 public USDC = IERC20(0xdAC17F958D2ee523a2206206994597C13D831ec7);

  constructor(
    string memory _initBaseURI,
    address USDTcontract
    ) ERC721("ScorpionYachtClub", "SYC") {
    setBaseURI(_initBaseURI);
    USDC = IERC20(USDTcontract);
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return baseURI;
  }

  function mint(address _to) public {
    require(totalSupply + 1 <= maxSupply);

    if(msg.sender != owner()) {
      require(!paused);
      require(msg.sender == _to);
      USDC.transferFrom(msg.sender, address(this), price);
    }

    _mint(_to, totalSupply+1);
    totalSupply++;
  }

  function burn(uint256 tokenId) public virtual {
    require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner nor approved");
    // require(block.timestamp >= endStakeTimestamp && block.timestamp <= endClaimTimestamp);
    _burn(tokenId);
    USDC.transferFrom(address(this), msg.sender, price);
    totalSupply--;
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
    require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

    string memory currentBaseURI = _baseURI();
    return bytes(currentBaseURI).length > 0
        ? string(abi.encodePacked(currentBaseURI, tokenId.toString(), baseExtension))
        : "";
  }

  function pause(bool _state) public onlyOwner {
    paused = _state;
  }

  function setprice(uint256 _price) public onlyOwner {
    price = _price;
  }

  function setmaxSupply(uint256 _maxSupply) public onlyOwner {
    maxSupply = _maxSupply;
  }

  function setPrice(uint256 _newPrice) public onlyOwner {
    price = _newPrice;
  }

  function setBurnable(bool _state) public onlyOwner {
    burnable = _state;
  }

  function setBaseURI(string memory _newBaseURI) public onlyOwner {
    baseURI = _newBaseURI;
  }

  function withdrawalTokens() public onlyOwner {
        USDC.transferFrom(address(this), msg.sender, USDC.balanceOf(address(this)));
  }
}