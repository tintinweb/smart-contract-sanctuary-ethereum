// SPDX-License-Identifier: WTF
pragma solidity ^0.8.13;

import { ERC721A } from "./ERC721A.sol";
import { Ownable } from "./Ownable.sol";
import { ReentrancyGuard } from "./ReentrancyGuard.sol";
import { Strings } from "./Strings.sol";

contract DKTW is ERC721A("DoTweets", "DKTW"), Ownable, ReentrancyGuard {
  uint256 private constant MAX = 150;

  uint256 public startBlock;
  uint256 public endBlock;
  uint256 public startingIndex;

  string public tokenBaseURI;

  event SetBaseUri(string prevTokenBaseURI, string tokenBaseURI);

  constructor(
    uint256 _startBlock,
    uint256 _endBlock,
    string memory _tokenBaseUri
  ) {
    require(_endBlock > _startBlock, "B");

    startBlock = _startBlock;
    endBlock = _endBlock;
    tokenBaseURI = _tokenBaseUri;

    _mint(msg.sender, 5);
  }

  modifier onlyEoa() {
    require(tx.origin == msg.sender, "E");
    _;
  }

  function setTokenBaseURI(string memory _tokenBaseURI) public onlyOwner {
    string memory prevTokenBaseURI = tokenBaseURI;
    tokenBaseURI = _tokenBaseURI;
    emit SetBaseUri(prevTokenBaseURI, tokenBaseURI);
  }

  function mint() external onlyEoa nonReentrant {
    require(block.number >= startBlock, "!T");
    require(totalSupply() + 1 <= MAX, "M");
    _mint(msg.sender, 1);
  }

  function reveal() external {
    require(startingIndex == 0, "R");
    if (totalSupply() < MAX) require(block.number > endBlock, "T");

    startingIndex = uint256(blockhash(block.number - 1)) % MAX;
    if (startingIndex == 0) startingIndex = startingIndex + 1;
  }

  function tokenURI(uint256 _tokenId)
    public
    view
    override
    returns (string memory)
  {
    require(_tokenId < totalSupply(), "T");
    require(startingIndex != 0, "!R");

    string memory index = Strings.toString((_tokenId + startingIndex) % MAX);

    return string(abi.encodePacked(tokenBaseURI, index, ".json"));
  }
}