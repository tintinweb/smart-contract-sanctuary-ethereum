// SPDX-License-Identifier: MIT
/**
  _____       _   _____                     
 |  __ \     | | |  __ \                    
 | |__) |_  _| | | |__) |__ _ __   ___  ___ 
 |  ___/\ \/ / | |  ___/ _ \ '_ \ / _ \/ __|
 | |     >  <| | | |  |  __/ |_) |  __/\__ \
 |_|    /_/\_\_| |_|   \___| .__/ \___||___/
                           | |              
                           |_|              
*/

pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./Ownable.sol";
import "./Strings.sol";

contract PxlPepes is ERC721, Ownable {
  using Strings for uint256;
 
  bool public paused = false;
  string public baseURI;
  string public baseExtension = ".json";
  uint256 public maxSupply = 4200;
  uint256 public totalSupply = 0;
  ERC721 public moonpepes;

  constructor(
    string memory _initBaseURI,
    address _moonpepes
  ) ERC721("Pxl Pepes", "PP") {
      setBaseURI(_initBaseURI);
      setMoonPepesContract(_moonpepes);
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return baseURI;
  }

  function exists(uint256 tokenId) external view returns (bool) {
      return _exists(tokenId);
  }

  function mint(address _to, uint256[] calldata ids) external {
    require(!paused, "Paused");
    require(totalSupply + ids.length <= maxSupply, "Exceeds max supply");
    for(uint256 i; i < ids.length; i++) {
        require(moonpepes.ownerOf(ids[i]) == msg.sender, string(abi.encodePacked("Not owner of ID #", ids[i])));
        _mint(_to, ids[i]);
    }

    totalSupply += ids.length;
  }

  function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
      require(_exists(tokenId), "URI query for nonexistent token");

      string memory currentBaseURI = _baseURI();
      return bytes(currentBaseURI).length > 0 
        ? string(abi.encodePacked(currentBaseURI, tokenId.toString(), baseExtension))
        : "";
  }

  function setBaseURI(string memory _newBaseURI) public onlyOwner {
    baseURI = _newBaseURI;
  }

  function setMoonPepesContract(address _moonpepes) public onlyOwner {
      moonpepes = ERC721(_moonpepes);
  }

  function setPaused(bool _paused) public onlyOwner {
      paused = _paused;
  }
}